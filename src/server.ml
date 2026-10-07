type formdata_t = {
  filename : string option;
  content_type : Multipart_form.Content_type.t;
  content : string;
}
[@@deriving make]

type request_body =
  | JSON of Yojson.Safe.t
  | Form of (string * string list) list
  | MultipartFormdata of { loaded : (string * formdata_t) list }

type request =
  | Request of {
      bare_req : Bare_server.Request.t;
      bare_body : Bare_server.Body.t;
      meth : Method.t;
      uri : Uri.t;
      path : string;
      query : (string * string) list;
      param : (string * string) list;
      body : (string option * request_body option) Lazy.t;
      headers : Headers.t;
    }

type response =
  | BareResponse of Bare_server.Response.t
  | Response of {
      status : Status.t;
      headers : Headers.t;
      body : string;
      tags : string list;
    }

type handler = Eio_unix.Stdenv.base -> request -> response
type middleware = handler -> handler

exception ErrorResponse of { status : Status.t; body : string }

let raise_error_response ?(body = "") status =
  raise (ErrorResponse { status; body })

let respond ?(status = `OK) ?(headers = []) ?(tags = []) (body : string) =
  Response { status; headers; body; tags }

let respond_html ?status ?(headers = []) ?tags s =
  respond ?status ?tags
    ~headers:((`Content_type, "text/html; charset=utf-8") :: headers)
    s

let respond_yojson ?status ?(headers = []) ?tags y =
  Yojson.Safe.to_string y
  |> respond ?status ?tags
       ~headers:((`Content_type, "application/json; charset=utf-8") :: headers)

(* Respond with a chunked transfer-encoding stream. The handler writes
   chunks via [Chunked.write]; when it returns normally, the final
   zero-length chunk is sent automatically. Handlers that stream
   indefinitely never return and are cancelled on connection reset. *)
let respond_chunked ?(headers = []) ?(keep_alive_timeout = 5) ~content_type
    (handler : Eio.Buf_read.t -> Eio.Buf_write.t -> unit) : response =
  let headers = headers |> Headers.to_list |> Http.Header.of_list in
  (* Chunked framing replaces any length framing: a Content-Length
     header must not coexist with Transfer-Encoding (RFC 9112 6.1). *)
  let headers = Http.Header.remove headers "content-length" in
  let headers =
    Http.Header.replace headers "transfer-encoding" "chunked"
  in
  let headers =
    Http.Header.replace headers "keep-alive"
      (Printf.sprintf "timeout=%d" keep_alive_timeout)
  in
  let headers = Http.Header.replace headers "connection" "keep-alive" in
  let headers = Http.Header.replace headers "content-type" content_type in
  let handler ic oc =
    handler ic oc;
    Chunked.write_finish oc
  in
  BareResponse (`Expert (Http.Response.make ~headers (), handler))

(* Respond with a fixed-length body held in a [Cstruct.t]. The body is
   enqueued with [Eio.Buf_write.schedule_cstruct], i.e. without any
   user-space copy, which makes this by far the fastest way to serve
   large bodies: reuse the same Cstruct across requests (e.g. a
   pre-encoded asset) and each request costs a single writev. *)
let respond_cstruct ?(headers = []) ~content_type (body : Cstruct.t) :
    response =
  let headers = headers |> Headers.to_list |> Http.Header.of_list in
  let headers =
    Http.Header.replace headers "content-length"
      (string_of_int (Cstruct.length body))
  in
  let headers = Http.Header.replace headers "content-type" content_type in
  let handler _ic oc =
    Eio.Buf_write.schedule_cstruct oc body;
    Eio.Buf_write.flush oc
  in
  BareResponse (`Expert (Http.Response.make ~headers (), handler))

let body = function
  | Request { body; _ } -> (
      match Lazy.force body with
      | Some raw_body, _ -> raw_body
      | _ -> failwith "body: none")

(* Strict decimal integer parsing. [int_of_string] accepts non-decimal
   formats such as "0x10" and "1_0", which is undesirable for HTTP
   parameters. *)
let parse_strict_int (s : string) : int =
  if s = "" then failwith "parse_strict_int: empty string"
  else
    String.fold_left
      (fun acc ch ->
        let i = Char.code ch - Char.code '0' in
        if not (0 <= i && i <= 9) then
          failwith "parse_strict_int: invalid digit"
        else if acc > (max_int - i) / 10 then
          failwith "parse_strict_int: overflow"
        else (acc * 10) + i)
      0 s

let param name = function
  | Request { param; _ } -> (
      match List.assoc_opt name param with
      | Some v -> v
      | None ->
          invalid_arg (Printf.sprintf "Yume.Server.param: %S not found" name))

let param_opt name = function
  | Request { param; _ } -> List.assoc_opt name param

let parse_strict_int_opt (s : string) : int option =
  match parse_strict_int s with
  | i -> Some i
  | exception Failure _ -> None

let strict_int_or_bad_request v =
  match parse_strict_int v with
  | i -> i
  | exception Failure _ -> raise_error_response `Bad_request

let param_int name (req : request) : int =
  match param_opt name req with
  | Some v -> strict_int_or_bad_request v
  | None -> raise_error_response `Bad_request

let string_of_yojson_atom = function
  | `Bool b -> string_of_bool b
  | `Int i -> string_of_int i
  | `String s -> s
  | _ -> failwith "string_of_yojson_atom"

let list_assoc_many k1 l =
  l |> List.filter_map (fun (k, v) -> if k = k1 then Some v else None)

let query_many name : request -> string list = function
  | Request { body; query; _ } -> (
      match query |> list_assoc_many (name ^ "[]") with
      | _ :: _ as res -> res
      | [] -> (
          match Lazy.force body with
          | _, Some (JSON (`Assoc l)) -> (
              match List.assoc_opt name l with
              | Some (`List l) -> l |> List.map string_of_yojson_atom
              | _ -> [])
          | _ -> failwith "query many"))

let formdata name = function
  | Request { body; _ } -> (
      match Lazy.force body with
      | _, Some (MultipartFormdata { loaded; _ }) -> (
          match List.assoc_opt name loaded with
          | Some s -> Ok s
          | None -> Error ("The name " ^ name ^ " was not found"))
      | _ -> Error "formdata: not MultipartFormdata"
      | exception _ -> Error "Couldn't read body")

let formdata_exn name r =
  match formdata name r with
  | Ok s -> s
  | Error _ -> raise_error_response `Bad_request

let query ?default name req =
  match req with
  | Request { body; query; _ } -> (
      try
        match Lazy.force body |> snd with
        | None -> failwith "query: body none"
        | Some x -> (
            match x with
            | JSON (`Assoc l) -> List.assoc name l |> string_of_yojson_atom
            | JSON _ -> failwith "json"
            | Form body -> (
                match query |> List.assoc_opt name with
                | Some x -> x
                | None -> body |> List.assoc name |> List.hd)
            | MultipartFormdata _ ->
                let f = formdata_exn name req in
                f.content)
      with
      | Not_found | Failure _ | ErrorResponse _ when default <> None ->
          Option.get default
      | Not_found | Failure _ -> raise_error_response `Bad_request)

let query_opt name r = try Some (query name r) with _ -> None

let query_int ?default name (req : request) : int =
  match query_opt name req with
  | Some v -> strict_int_or_bad_request v
  | None -> (
      match default with
      | Some d -> d
      | None -> raise_error_response `Bad_request)

let query_int_opt name (req : request) : int option =
  query_opt name req |> Option.map strict_int_or_bad_request

(* [header_opt] returns the first value of [name]. Headers may appear
   multiple times (e.g. Set-Cookie); use [header_all] to collect
   every value. *)
let header_opt name : request -> string option = function
  | Request { headers; _ } -> headers |> List.assoc_opt name

let header_all name : request -> string list = function
  | Request { headers; _ } -> list_assoc_many name headers

let header name (r : request) : string =
  match header_opt name r with None -> failwith "header: none" | Some v -> v

let headers = function Request { headers; _ } -> headers
let path = function Request { path; _ } -> path
let meth = function Request { meth; _ } -> meth

let load_formdata_from_stream out_stream =
  let open Multipart_form in
  let rec save_part loaded raw =
    match Eio.Stream.take out_stream with
    | None -> loaded
    | Some (_, hdr, contents) ->
        let loaded =
          let ( let* ) v f = v |> Option.fold ~none:loaded ~some:f in
          let* cd = Header.content_disposition hdr in
          let* name = Content_disposition.name cd in
          let filename = Content_disposition.filename cd in
          let buf = Buffer.create 0 in
          let rec loop () =
            match Eio.Stream.take contents with
            | None -> ()
            | Some s ->
                Buffer.add_string buf s;
                loop ()
          in
          loop ();
          ( name,
            make_formdata_t ?filename ~content_type:(Header.content_type hdr)
              ~content:(Buffer.contents buf) () )
          :: loaded
        in
        save_part loaded raw
  in
  save_part [] []

let parse_body' ~max_size body headers =
  let content_type = List.assoc_opt `Content_type headers in
  match
    content_type
    |> Option.map (fun s ->
        (* MIME types are case-insensitive *)
        s |> String.split_on_char ';' |> List.hd |> String.trim
        |> String.lowercase_ascii)
  with
  | Some "multipart/form-data" ->
      (* FIXME: Currenty all contents are stored on memory.
         This is not the best choice from perspective of space efficiency.
         We should utilize files on disk *)
      let load_body () =
        let open Multipart_form in
        let content_type =
          match Content_type.of_string (Option.get content_type ^ "\r\n") with
          | Ok s -> s
          | Error (`Msg _msg) -> raise_error_response `Bad_request
        in

        Eio.Switch.run @@ fun sw ->
        let _, out_stream =
          Multipart_form_eio.stream ~bounds:max_size ~sw ~identify:Fun.id body
            content_type
        in
        load_formdata_from_stream out_stream
      in
      (None, MultipartFormdata { loaded = load_body () })
  | Some "application/json" -> (
      let raw_body = Bare_server.Body.to_string max_size body in
      ( Some raw_body,
        try JSON (Yojson.Safe.from_string raw_body) with _ -> Form [] ))
  | Some "application/x-www-form-urlencoded" | _ ->
      let raw_body = Bare_server.Body.to_string max_size body in
      (Some raw_body, Form (Uri.query_of_encoded raw_body))

(* Parse the request body, reading at most [max_body_size] bytes into
   memory. The body is only read for requests that carry one
   ([Http.Request.has_body]); in particular requests with a
   Transfer-Encoding header (e.g. chunked) are read too. A request
   with neither Content-Length nor Transfer-Encoding ([`Unknown]) has
   a zero-length body per RFC 9112 6.3; reading it would block until
   the client closes a keep-alive connection, because the underlying
   body reader for [`Unknown] reads until EOF. *)
let parse_body ~max_body_size ~bare_req ~body ~headers =
  match Http.Request.has_body bare_req with
  | `No | `Unknown -> (Some "", Form [])
  | `Yes -> (
      match List.assoc_opt `Content_length headers with
      | Some v -> (
          match parse_strict_int_opt v with
          | Some _ -> parse_body' ~max_size:max_body_size body headers
          | None -> raise_error_response `Bad_request)
      | None -> parse_body' ~max_size:max_body_size body headers)

let default_handler : handler =
 fun _env -> function
  | Request _ ->
      (* Method mismatches are handled by Router.use with 405 + Allow;
         reaching the default handler means the path does not exist. *)
      respond ~status:`Not_found ""

(* Run [handler], converting exceptions into error responses:
   [ErrorResponse] carries its own status, and any other exception
   becomes a 500. Cancellation is re-raised: converting it into a
   response would break eio's cancellation propagation when the server
   shuts down mid-handler. *)
let run_handler (handler : handler) env (req : request) : response =
  try handler env req with
  | (Eio.Cancel.Cancelled _) as e -> raise e
  | ErrorResponse { status; body } ->
      Logs.debug (fun m ->
          m "Error response raised: %s\n%s" (Status.to_string status)
            (Printexc.get_backtrace ()));
      respond ~status ~tags:[ "log" ] body
  | e ->
      Logs.err (fun m ->
          m "Exception raised: %s\n%s" (Printexc.to_string e)
            (Printexc.get_backtrace ()));
      respond ~status:`Internal_server_error ""

(* Validate the Content-Length header before invoking the handler: it
   must be a strict decimal within [max_body_size]. Rejecting early
   keeps oversized or malformed requests from ever being buffered. *)
let check_request_body ~max_body_size (req : request) : unit =
  match req with
  | Request { headers; _ } -> (
      match List.assoc_opt `Content_length headers with
      | None -> ()
      | Some v -> (
          match parse_strict_int_opt v with
          | Some cl when cl > max_body_size ->
              raise_error_response `Request_entity_too_large
          | Some _ -> ()
          | None -> raise_error_response `Bad_request))

type ws_conn = Bare_server.ws_conn

(* Expose [Chunked] as [Server.Chunked] for use alongside
   [respond_chunked]. *)
module Chunked = Chunked

module Ws_conn_man = struct
  type t = {
    chan : (request * (ws_conn -> unit) * response Eio.Stream.t) Eio.Stream.t;
  }

  let global_runner = { chan = Eio.Stream.create 0 }

  let start_global_runner env ~sw =
    Eio.Fiber.fork ~sw (fun () ->
        let rec loop () =
          let req, callback, recv_stream = Eio.Stream.take global_runner.chan in
          let callback conn =
            try callback conn
            with e ->
              Logs.err (fun m ->
                  m "websocket handler raised: %s: %s" (Printexc.to_string e)
                    (Printexc.get_backtrace ()))
          in
          (* Setting up the connection must not kill the runner: a
             failure is answered with a 500 so the caller unblocks,
             and the loop keeps serving later requests. Cancellation
             (when [sw] closes) still propagates, via the stream
             operations outside this match. *)
          let resp =
            match req with
            | Request { bare_req; _ } -> (
                match Bare_server.websocket env ~sw bare_req callback with
                | r -> BareResponse r
                | exception e ->
                    Logs.err (fun m ->
                        m "websocket setup failed: %s: %s"
                          (Printexc.to_string e)
                          (Printexc.get_backtrace ()));
                    respond ~status:`Internal_server_error "")
          in
          Eio.Stream.add recv_stream resp;
          loop ()
        in
        loop ())

  let start_ws_conn req callback =
    let recv_chan = Eio.Stream.create 0 in
    Eio.Stream.add global_runner.chan (req, callback, recv_chan);
    Eio.Stream.take recv_chan
end

let websocket (r : request) f = Ws_conn_man.start_ws_conn r f
let ws_send = Bare_server.ws_send
let ws_recv = Bare_server.ws_recv

(* Fast final conversion from a [Response] to a bare response: builds
   a fixed-length expert response so that the body costs a single
   user-space copy (string -> Cstruct) followed by one writev,
   instead of the cohttp body pipeline, which routes string bodies
   through an Eio.Buf_read buffer and the Buf_write buffer (three
   copies per byte, in small chunks). *)
let respond_expert ~(bare_req : Bare_server.Request.t) ~(status : Status.t)
    ~(headers : Headers.t) ~(body : string) : Bare_server.Response.t =
  let keep_alive = Http.Request.is_keep_alive bare_req in
  (* RFC 9110 9.3.2: a HEAD response carries the same Content-Length
     as the corresponding GET, but no body. *)
  let is_head = Http.Request.meth bare_req = `HEAD in
  let headers = headers |> Headers.to_list |> Http.Header.of_list in
  let headers =
    match Http.Header.connection headers with
    | Some _ -> headers
    | None ->
        Http.Header.add headers "connection"
          (if keep_alive then "keep-alive" else "close")
  in
  (* RFC 9110 8.6: a Content-Length must not be sent on a 1xx or 204
     response. *)
  let headers =
    if Http.Status.body_allowed status then
      Http.Header.replace headers "content-length"
        (string_of_int (String.length body))
    else Http.Header.remove headers "content-length"
  in
  (* This response sends an unchunked body; a caller-supplied
     transfer-encoding would corrupt the framing (RFC 9112 6.1
     forbids Content-Length together with Transfer-Encoding). *)
  let headers = Http.Header.remove headers "transfer-encoding" in
  `Expert
    ( Http.Response.make ~status ~headers (),
      fun _ic oc ->
        (if not is_head then
           let cs = Cstruct.of_string body in
           if Cstruct.length cs > 0 then Eio.Buf_write.schedule_cstruct oc cs);
        Eio.Buf_write.flush oc )

let default_max_body_size = 16 * 1024 * 1024 (* 16 MiB *)

let start_server env ~sw ?(max_body_size = default_max_body_size)
    ?(listen = `Tcp (Eio.Net.Ipaddr.V4.loopback, 8080)) ?error_handler
    (handler : handler) k : unit =
  Ws_conn_man.start_global_runner env ~sw;
  Bare_server.start_server ~listen env ~sw k
  @@
  fun (req : Bare_server.Request.t)
    (body : Bare_server.Body.t)
    :
    Bare_server.Response.t
  ->
  (* Parse req *)
  let uri = Bare_server.Request.uri req in
  let meth = Bare_server.Request.meth req in
  let headers = Bare_server.Request.headers req |> Headers.of_list in
  let path = Uri.path uri in
  (* Flatten repeated query parameters into (name, value) pairs:
     concatenating the values with "," would conflate ?a=1&a=2 with
     ?a=1,2 and lose the individual values. *)
  let query =
    Uri.query uri
    |> List.concat_map (fun (k, xs) -> xs |> List.map (fun v -> (k, v)))
  in
  let lazy_parsed_body =
    lazy
      (match parse_body ~max_body_size ~bare_req:req ~body ~headers with
      | exception e ->
          Logs.debug (fun m -> m "parse_body failed: %s" (Printexc.to_string e));
          (None, None)
      | raw_body, parsed_body -> (raw_body, Some parsed_body))
  in
  let req =
    Request
      {
        bare_req = req;
        bare_body = body;
        meth;
        uri;
        path;
        query;
        param = [];
        body = lazy_parsed_body;
        headers;
      }
  in

  (* Invoke the handler *)
  let res =
    run_handler
      (fun env req ->
        check_request_body ~max_body_size req;
        handler env req)
      env req
  in

  (* Respond (after call error_handler if necessary *)
  let is_head = match meth with `HEAD -> true | _ -> false in
  let rec aux first = function
    | BareResponse (`Expert (resp, _handler)) when is_head ->
        (* RFC 9110 9.3.2: HEAD responses must not carry a body.
           respond_expert suppresses its own body; this also covers
           respond_cstruct, respond_chunked and user-provided
           experts. *)
        `Expert (resp, fun _ic _oc -> ())
    | BareResponse resp -> resp
    | Response { status; headers; body; _ }
      when (not first)
           || Option.is_none error_handler
           || not (Status.is_error status)
           (* - error_handler is already called;
              - error_handler is not specified; or
              - not erroneous response *)
      ->
        let (Request { bare_req; _ }) = req in
        respond_expert ~bare_req ~status ~headers ~body
    | Response { status; headers; body; _ } ->
        let error_handler = Option.get error_handler in
        error_handler ~req ~status ~headers ~body |> aux false
  in
  (* RFC 9110 9.5: a final response sent before the request body has
     been read must close the connection, because the unread body
     bytes would be parsed as a bogus next request on a keep-alive
     connection. Also honor a "Connection: close" request on expert
     responses that hardcode keep-alive (respond_chunked). Closing is
     done by raising [Bare_server.Close_connection] after the response
     handler ran: Cohttp_eio's keep-alive loop is driven by the
     request headers, so a "connection: close" response header alone
     would not stop it. An explicit [connection: close] request header
     is required for the first part: [is_keep_alive] is also false for
     upgrade requests ("Connection: Upgrade"), whose connection must
     of course stay open. *)
  let (Request { bare_req; body = req_body; _ }) = req in
  let body_unread () =
    Http.Request.has_body bare_req = `Yes && not (Lazy.is_val req_body)
  in
  let request_wants_close () =
    match Http.Header.connection (Http.Request.headers bare_req) with
    | Some `Close -> true
    | _ -> false
  in
  match aux true res with
  | ( `Expert (r, handler) ) as resp ->
      if
        request_wants_close ()
        || (Status.is_error (Http.Response.status r) && body_unread ())
      then
        let headers =
          Http.Header.replace r.headers "connection" "close"
        in
        let handler ic oc =
          handler ic oc;
          raise Bare_server.Close_connection
        in
        `Expert ({ r with Cohttp.Response.headers = headers }, handler)
      else resp
  | resp -> resp

(* The HTTP endpoint URL of a listening socket, e.g.
   "http://127.0.0.1:8080". *)
let endpoint_of_socket (socket : _ Eio.Net.listening_socket_ty Eio.Resource.t) :
    string =
  match Eio.Net.listening_addr socket with
  | `Tcp (addr, port) ->
      let addr = Fmt.to_to_string Eio.Net.Ipaddr.pp addr in
      (* IPv6 literals need enclosing brackets in URLs *)
      let addr = if String.contains addr ':' then "[" ^ addr ^ "]" else addr in
      Printf.sprintf "http://%s:%d" addr port
  | other ->
      invalid_arg
        (Printf.sprintf "Yume.Server.endpoint_of_socket: not a TCP socket: %s"
           (match other with `Unix _ -> "unix" | _ -> "unknown"))

(* Resolve [addr] and [port] into a listen address and start the
   server. *)
let start_server_on env ~sw ?max_body_size ?error_handler ~addr ~port handler
    k : unit =
  let listen =
    match Eio.Net.getaddrinfo_stream ~service:port env#net addr with
    | [] ->
        invalid_arg
          (Printf.sprintf
             "Yume.Server.start_server_on: cannot resolve %s:%s" addr port)
    | addr :: _ -> addr
  in
  start_server env ~sw ?max_body_size ?error_handler ~listen handler k

(* Middleware Router *)
module Router = struct
  type route = Method.t * string * handler

  type spec_entry = Route of route | Scope of (string * spec)
  and spec = spec_entry list

  let use (spec : spec) (inner_handler : handler) env (req : request) : response
      =
    let routes =
      let rec aux (spec : spec) : route list =
        spec
        |> List.map (function
          | Route r -> [ r ]
          | Scope (name, spec) ->
              aux spec |> List.map (fun (meth, uri, h) -> (meth, name ^ uri, h)))
        |> List.flatten
      in
      aux spec
      |> List.map (fun (meth, uri, h) -> (meth, Path_pattern.of_string uri, h))
    in

    match req with
    | Request req -> (
        (* Choose the handler from routes: the first route whose path
           matches and whose method matches (with `HEAD falling back
           to `GET). A path match with no method match is a 405 with
           an Allow header; no path match at all falls through to
           [inner_handler] (usually a 404). *)
        let path_matched =
          List.filter_map
            (fun (meth', pat, handler) ->
              Path_pattern.perform ~pat req.path
              |> Option.map (fun param -> (meth', param, handler)))
            routes
        in
        let exact =
          List.find_map
            (fun (meth', param, handler) ->
              let matched =
                req.meth = meth' || (req.meth = `HEAD && meth' = `GET)
              in
              if matched then Some (param, handler) else None)
            path_matched
        in
        let resp =
          match exact with
          | Some (param, handler) ->
              let req = Request { req with param } in
              run_handler handler env req
          | None -> (
              match path_matched with
              | (_, _, _) :: _ ->
                  let allow =
                    path_matched |> List.map (fun (m, _, _) -> m)
                    |> List.sort_uniq compare
                    |> List.map Method.to_string |> String.concat ", "
                  in
                  respond ~status:`Method_not_allowed
                    ~headers:[ (`Allow, allow) ] ""
              | [] -> inner_handler env (Request req))
        in
        match resp with
        | Response ({ status; tags; _ } as r) when Status.is_error status ->
            Response { r with tags = "log" :: tags }
        | r -> r)

  let get target f : spec_entry = Route (`GET, target, f)
  let post target f : spec_entry = Route (`POST, target, f)
  let patch target f : spec_entry = Route (`PATCH, target, f)
  let delete target f : spec_entry = Route (`DELETE, target, f)
  let options target f : spec_entry = Route (`OPTIONS, target, f)
  let scope (name : string) (spec : spec) : spec_entry = Scope (name, spec)
end

(* Middleware CORS *)
module Cors = struct
  type t = {
    target : string;
    target_pat : Path_pattern.t;
    methods : Method.t list;
    origin : string;
    expose : Header.name list;
    allow_headers : Header.name list;
  }

  let make target ?(origin = "*") ~methods ?(expose = [])
      ?(allow_headers = []) () =
    let target_pat = Path_pattern.of_string target in
    { target; target_pat; methods; origin; expose; allow_headers }

  let use (src : t list) (inner_handler : handler) env (req : request) :
      response =
    (* Preflight handler *)
    let preflight (r : t) (req : request) : response =
      let headers =
        [
          ( `Access_control_allow_methods,
            r.methods |> List.map Method.to_string |> String.concat ", " );
          (`Access_control_allow_origin, r.origin);
        ]
      in
      (* Only echo the requested headers when they are all allowed;
         without an allowlist this would grant arbitrary headers
         (e.g. Cookie). *)
      let headers =
        match req with
        | Request req -> (
            match
              req.headers |> List.assoc_opt `Access_control_request_headers
            with
            | None -> headers
            | Some v ->
                let requested =
                  v |> String.split_on_char ','
                  |> List.map (fun s ->
                         Header.name_of_string (String.trim s))
                in
                if List.for_all (fun h -> List.mem h r.allow_headers) requested
                then (`Access_control_allow_headers, v) :: headers
                else headers)
      in
      respond ~status:`No_content ~headers ""
    in

    let path_match path =
      src
      |> List.find_opt (fun { target_pat; _ } ->
          Path_pattern.perform ~pat:target_pat path |> Option.is_some)
    in

    let make_cors_headers { origin; expose; _ } headers =
      (`Access_control_allow_origin, origin)
      :: ( `Access_control_expose_headers,
           expose |> List.map Header.string_of_name |> String.concat ", " )
      :: headers
    in

    match req with
    | Request ({ meth = `OPTIONS; path; _ } as req) -> (
        (* Preflight requests are intercepted directly rather than
           routed, so that Router's method-mismatch handling (405)
           does not swallow them. *)
        match path_match path with
        | Some r -> preflight r (Request req)
        | None -> inner_handler env (Request req))
    | Request ({ path; _ } as req) -> (
        (* Apply inner_handler, and if path matches, append CORS
           headers *)
        let resp = inner_handler env (Request req) in
        match (resp, path_match path) with
        | _, None -> resp
        (* Note: plain `Response bare responses (which only originate
           from the server's own error handling) pass through without
           CORS headers; handler errors are converted to expert
           responses by run_handler before reaching here. *)
        | BareResponse (`Expert (expert_resp, handler)), Some path_match ->
            BareResponse
              (`Expert
                 ( {
                     expert_resp with
                     headers =
                       expert_resp.headers |> Http.Header.to_list
                       |> Headers.of_list
                       |> make_cors_headers path_match
                       |> Headers.to_list |> Http.Header.of_list;
                   },
                   handler ))
        | BareResponse _, _ -> resp
        | Response res, Some path_match ->
            Response
              {
                res with
                headers = make_cors_headers path_match res.headers;
              })
end

(* Middlware Logger *)
module Logger = struct
  let string_of_request_response req res =
    match (req, res) with
    | Request { bare_req; body; _ }, Response { status; _ } ->
        let open Buffer in
        let buf = create 0 in
        let fmt = Format.formatter_of_buffer buf in
        Bare_server.Request.pp_hum fmt bare_req;
        Format.pp_print_flush fmt ();
        add_string buf "\n";
        let raw_body =
          if Http.Request.has_body bare_req = `Yes then
            body |> Lazy.force |> fst
          else None
        in
        raw_body
        |> Option.iter (fun s ->
            add_string buf "\n";
            add_string buf s;
            add_string buf "\n");
        add_string buf "\n==============================\n";
        add_string buf ("Status: " ^ Status.to_string status);
        Buffer.contents buf
    | _ -> assert false

  let use ?dump_req_dir (inner_handler : handler) env (req : request) : response
      =
    let (Request { uri; meth; _ }) = req in
    let meth = Method.to_string meth in
    let uri = Uri.to_string uri in
    Logs.debug (fun m -> m "%s %s" meth uri);

    let resp = inner_handler env req in

    (match resp with
    | Response { status; _ } ->
        Logs.info (fun m -> m "%s %s %s" (Status.to_string status) meth uri)
    | BareResponse _ -> Logs.info (fun m -> m "[bare] %s %s" meth uri));

    (match resp with
    | Response { tags; _ } when List.mem "log" tags -> (
        match dump_req_dir with
        | None ->
            let s = string_of_request_response req resp in
            Logs.info (fun m -> m "Detail of request and response:\n%s" s)
        | Some _dir -> (* FIXME: implement here *) ())
    | _ -> ());

    resp
end
