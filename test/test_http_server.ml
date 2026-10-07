let test_image =
  {|
iVBORw0KGgoAAAANSUhEUgAAADIAAAAyAQAAAAA2RLUcAAAABGdBTUEAALGPC/xhBQAAACBjSFJN
AAB6JgAAgIQAAPoAAACA6AAAdTAAAOpgAAA6mAAAF3CculE8AAAAAmJLR0QAAd2KE6QAAAAHdElN
RQfnAxYCJTrYPC4yAAAADklEQVQY02NgGAWDCQAAAZAAAcWb20kAAAAldEVYdGRhdGU6Y3JlYXRl
ADIwMjMtMDMtMjJUMDI6Mzc6NTgrMDA6MDClQ3CPAAAAJXRFWHRkYXRlOm1vZGlmeQAyMDIzLTAz
LTIyVDAyOjM3OjU4KzAwOjAw1B7IMwAAAABJRU5ErkJggg==|}
  |> String.trim |> String.split_on_char '\n' |> String.concat ""
  |> Base64.decode_exn

let test_image_large =
  {|
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
AAIBAwADAAAAhgAAABIBAwABAAAAAQAAABoBBQABAAAAjAAAABsBBQABAAAAlAAAACgBAwABAAAA
AgAAADEBAgANAAAAnAAAADIBAgAUAAAAqgAAAGmHBAABAAAAvgAAAAAAAAAIAAgACABIAAAAAQAA
AEgAAAABAAAAR0lNUCAyLjEwLjM0AAAyMDIzOjA1OjE1IDE4OjA5OjE0AAEAAaADAAEAAAABAAAA
AAAAAEf4jE8AAAAldEVYdGRhdGU6Y3JlYXRlADIwMjQtMDYtMDJUMDk6MTM6MzArMDA6MDBp4rJK
AAAAJXRFWHRkYXRlOm1vZGlmeQAyMDI0LTA2LTAyVDA5OjEzOjMwKzAwOjAwGL8K9gAAABp0RVh0
ZXhpZjpCaXRzUGVyU2FtcGxlADgsIDgsIDgS7T4nAAAAEXRFWHRleGlmOkNvbG9yU3BhY2UAMQ+b
AkkAAAAhdEVYdGV4aWY6RGF0ZVRpbWUAMjAyMzowNToxNSAxODowOToxNBJwRVYAAAATdEVYdGV4
aWY6RXhpZk9mZnNldAAxOTBMjvPCAAAAFHRFWHRleGlmOkltYWdlTGVuZ3RoADI0MvW9M3QAAAAT
dEVYdGV4aWY6SW1hZ2VXaWR0aAAyNDImwSP5AAAAGnRFWHRleGlmOlNvZnR3YXJlAEdJTVAgMi4x
MC4zNBhmc5oAAAAbdEVYdGljYzpjb3B5cmlnaHQAUHVibGljIERvbWFpbraRMVsAAAAidEVYdGlj
YzpkZXNjcmlwdGlvbgBHSU1QIGJ1aWx0LWluIHNSR0JMZ0ETAAAAFXRFWHRpY2M6bWFudWZhY3R1
cmVyAEdJTVBMnpDKAAAADnRFWHRpY2M6bW9kZWwAc1JHQltgSUMAAAAASUVORK5CYII=|}
  |> String.trim |> String.split_on_char '\n' |> String.concat ""
  |> Base64.decode_exn

let error_handler ~req:_ ~status:_ ~headers:_ ~body:_ = assert false



(* Send [payload] over a raw socket and read the whole response (the
   server must close the connection, e.g. via "Connection: close"). *)
let raw_request ~sw env listen_addr payload =
  let socket = Eio.Net.connect ~sw env#net listen_addr in
  Eio.Buf_write.with_flow socket (fun oc ->
      Eio.Buf_write.string oc payload);
  let ic = Eio.Buf_read.of_flow socket ~max_size:65536 in
  Eio.Buf_read.take_all ic

let split_headers_body (resp : string) : string * string =
  let sep = "\r\n\r\n" in
  let rec find i =
    if i + String.length sep > String.length resp then None
    else if String.sub resp i (String.length sep) = sep then Some i
    else find (i + 1)
  in
  match find 0 with
  | Some i ->
      ( String.sub resp 0 i,
        String.sub resp (i + 4) (String.length resp - i - 4) )
  | None -> (resp, "")

let header_value (headers : string) (name : string) : string option =
  headers |> String.split_on_char '\n'
  |> List.map String.trim
  |> List.find_map (fun line ->
         match String.index_opt line ':' with
         | Some i
           when String.equal
                  (String.lowercase_ascii (String.sub line 0 i))
                  name ->
             Some
               (String.trim (String.sub line (i + 1) (String.length line - i - 1)))
         | _ -> None)

let header_values (headers : string) (name : string) : string list =
  headers |> String.split_on_char '\n'
  |> List.filter_map (fun line ->
         match String.index_opt line ':' with
         | Some i
           when String.equal
                  (String.lowercase_ascii (String.sub line 0 i))
                  name ->
             Some
               (String.trim (String.sub line (i + 1) (String.length line - i - 1)))
         | _ -> None)

(* Read the status line and headers of a raw response (up to the
   empty line), without waiting for the body. *)
let read_response_head (ic : Eio.Buf_read.t) : string =
  let rec loop acc =
    let line = Eio.Buf_read.line ic in
    if line = "" || line = "\r" then String.concat "\n" (List.rev acc)
    else loop (line :: acc)
  in
  loop []

let test_basics () =
  let expected_get_response = "response test text" in
  let expected_get_json_response = `Assoc [ ("hello", `String "world") ] in

  Eio_main.run @@ fun env ->
  Eio.Time.with_timeout_exn env#clock 3.0 @@ fun () ->
  let handler =
    let open Yume.Server in
    Router.(
      use
        [
          get "/" (fun _ _ -> respond_html expected_get_response);
          get "/json" (fun _ _ -> respond_yojson expected_get_json_response);
          post "/" (fun _ req -> (* echo *) query "msg" req |> respond);
          get "/chunked" (fun _ _ ->
              respond_chunked ~content_type:"text/plain" (fun _ic oc ->
                  Chunked.write oc "hello, ";
                  Chunked.write oc "world"));
          get "/chunked-cs" (fun _ _ ->
              respond_chunked ~content_type:"text/plain" (fun _ic oc ->
                  Chunked.write_cstruct oc (Cstruct.of_string "hello, ");
                  Chunked.write_cstruct oc (Cstruct.of_string "world")));
          get "/chunked-cs-empty" (fun _ _ ->
              (* an empty Cstruct terminates the body, same as [write ""] *)
              respond_chunked ~content_type:"text/plain" (fun _ic oc ->
                  Chunked.write_cstruct oc (Cstruct.of_string "hello");
                  Chunked.write_cstruct oc Cstruct.empty));
          get "/cstruct" (fun _ _ ->
              respond_cstruct ~content_type:"application/octet-stream"
                (Cstruct.of_string "hello cstruct"));
          get "/qm" (fun _ req ->
              respond_yojson
                (`List
                   (query_many "a" req |> List.map (fun s -> `String s))));
          get "/param/:id" (fun _ req ->
              let id = param_int ":id" req in
              let n = query_int "n" req in
              let m = Option.value (query_int_opt "m" req) ~default:0 in
              respond_yojson
                (`Assoc [ ("id", `Int id); ("n", `Int n); ("m", `Int m) ]));
        ])
      default_handler
  in
  let listen =
    Eio.Net.getaddrinfo_stream ~service:"0" env#net "localhost" |> List.hd
  in
  try
    Eio.Switch.run @@ fun sw ->
    Yume.Server.start_server env ~sw ~listen ~error_handler handler
      (fun socket ->
        let listening_port =
          match Eio.Net.listening_addr socket with
          | `Tcp (_, port) -> port
          | _ -> assert false
        in

        let resp =
          Yume.Client.head env ~sw
            (Printf.sprintf "http://localhost:%d/" listening_port)
        in
        assert (Yume.Client.Response.status resp = `OK);

        let resp =
          Yume.Client.get env ~sw
            (Printf.sprintf "http://localhost:%d/" listening_port)
        in
        assert (Yume.Client.Response.status resp = `OK);
        let body = Yume.Client.Response.drain resp in
        assert (body = expected_get_response);
        let hs = Yume.Client.Response.headers resp in
        assert (
          List.assoc `Content_length hs
          = string_of_int (String.length expected_get_response));

        let resp =
          Yume.Client.get env ~sw
            (Printf.sprintf "http://localhost:%d/json" listening_port)
        in
        assert (Yume.Client.Response.status resp = `OK);
        let body = Yume.Client.Response.drain resp |> Yojson.Safe.from_string in
        assert (body = expected_get_json_response);

        let resp =
          Yume.Client.post env ~sw
            (Printf.sprintf "http://localhost:%d/?msg=hello" listening_port)
        in
        assert (Yume.Client.Response.status resp = `OK);
        let body = Yume.Client.Response.drain resp in
        assert (body = "hello");

        let resp =
          Yume.Client.get env ~sw
            (Printf.sprintf "http://localhost:%d/chunked" listening_port)
        in
        assert (Yume.Client.Response.status resp = `OK);
        let body = Yume.Client.Response.drain resp in
        assert (body = "hello, world");
        let hs = Yume.Client.Response.headers resp in
        assert (List.assoc `Content_type hs = "text/plain");

        let resp =
          Yume.Client.get env ~sw
            (Printf.sprintf "http://localhost:%d/chunked-cs" listening_port)
        in
        assert (Yume.Client.Response.status resp = `OK);
        let body = Yume.Client.Response.drain resp in
        assert (body = "hello, world");

        let resp =
          Yume.Client.get env ~sw
            (Printf.sprintf "http://localhost:%d/chunked-cs-empty" listening_port)
        in
        assert (Yume.Client.Response.status resp = `OK);
        let body = Yume.Client.Response.drain resp in
        assert (body = "hello");

        let resp =
          Yume.Client.get env ~sw
            (Printf.sprintf "http://localhost:%d/cstruct" listening_port)
        in
        assert (Yume.Client.Response.status resp = `OK);
        let body = Yume.Client.Response.drain resp in
        assert (body = "hello cstruct");
        let hs = Yume.Client.Response.headers resp in
        assert (List.assoc `Content_type hs = "application/octet-stream");
        assert (List.assoc `Content_length hs = "13");

        (* repeated query parameters keep their individual values *)
        let resp =
          Yume.Client.get env ~sw
            (Printf.sprintf "http://localhost:%d/qm?a[]=1&a[]=2" listening_port)
        in
        assert (Yume.Client.Response.status resp = `OK);
        let body = Yume.Client.Response.drain resp |> Yojson.Safe.from_string in
        assert (body = `List [ `String "1"; `String "2" ]);

        let test_param url expected_status expected_body =
          let resp = Yume.Client.get env ~sw url in
          assert (Yume.Client.Response.status resp = expected_status);
          match expected_body with
          | None -> Yume.Client.Response.drain resp |> ignore
          | Some expected ->
              let body = Yume.Client.Response.drain resp in
              assert (body = expected)
        in
        let url = Printf.sprintf "http://localhost:%d/param" listening_port in
        test_param (url ^ "/12?n=34") `OK (Some {|{"id":12,"n":34,"m":0}|});
        (* optional query *)
        test_param (url ^ "/12?n=34&m=56") `OK
          (Some {|{"id":12,"n":34,"m":56}|});

        Eio.Switch.fail sw Common.Exit_normally)
  with Common.Exit_normally -> ()

let test_body_parsing () =
  Eio_main.run @@ fun env ->
  Eio.Time.with_timeout_exn env#clock 3.0 @@ fun () ->
  let handler =
    let open Yume.Server in
    Router.(
      use
        [
          post "/echo" (fun _ req -> query "msg" req |> respond);
          post "/raw" (fun _ req -> body req |> respond);
        ])
      default_handler
  in
  let listen =
    Eio.Net.getaddrinfo_stream ~service:"0" env#net "localhost" |> List.hd
  in
  try
    Eio.Switch.run @@ fun sw ->
    Yume.Server.start_server env ~sw ~listen ~max_body_size:64 handler
      (fun socket ->
        let listen_addr =
          match Eio.Net.listening_addr socket with
          | `Tcp (_, _) as addr -> addr
          | _ -> assert false
        in
        let raw payload = raw_request ~sw env listen_addr payload in

        (* chunked request bodies must be parsed *)
        let json = {|{"msg":"chunky"}|} in
        let resp =
          raw
            (Printf.sprintf
               "POST /echo HTTP/1.1\r\nHost: localhost\r\nContent-Type: \
                application/json\r\nTransfer-Encoding: chunked\r\nConnection: \
                close\r\n\r\n%x\r\n%s\r\n0\r\n\r\n"
               (String.length json) json)
        in
        assert (String.starts_with ~prefix:"HTTP/1.1 200" resp);
        assert (snd (split_headers_body resp) = "chunky");

        (* non-strict Content-Length is rejected *)
        let resp =
          raw
            "POST /raw HTTP/1.1\r\nHost: localhost\r\nContent-Length: \
             0x10\r\nConnection: close\r\n\r\n0123456789abcdef"
        in
        assert (String.starts_with ~prefix:"HTTP/1.1 400" resp);

        (* oversized Content-Length is rejected with 413 *)
        let resp =
          raw
            "POST /raw HTTP/1.1\r\nHost: localhost\r\nContent-Length: \
             65\r\nConnection: close\r\n\r\n01234567890123456789012345678901234567890123456789012345678901234"
        in
        assert (String.starts_with ~prefix:"HTTP/1.1 413" resp);

        (* a POST with neither Content-Length nor Transfer-Encoding has
           a zero-length body (RFC 9112 6.3) and must not block: the
           handler reads the body via query, which used to wait for EOF
           on the connection *)
        let resp =
          raw "POST /echo HTTP/1.1\r\nHost: localhost\r\nConnection: close\r\n\r\n"
        in
        assert (String.starts_with ~prefix:"HTTP/1.1 400" resp);

        Eio.Switch.fail sw Common.Exit_normally)
  with Common.Exit_normally -> ()

(* RFC 9110 9.3.2: HEAD responses must carry the Content-Length of the
   corresponding GET but no body, whatever response constructor the
   handler used. *)
let test_head () =
  Eio_main.run @@ fun env ->
  Eio.Time.with_timeout_exn env#clock 3.0 @@ fun () ->
  let expected_body = "hello cstruct" in
  let handler =
    let open Yume.Server in
    Router.(
      use
        [
          get "/" (fun _ _ -> respond_html "hello, head");
          get "/cstruct" (fun _ _ ->
              respond_cstruct ~content_type:"application/octet-stream"
                (Cstruct.of_string expected_body));
        ])
      default_handler
  in
  let listen =
    Eio.Net.getaddrinfo_stream ~service:"0" env#net "localhost" |> List.hd
  in
  try
    Eio.Switch.run @@ fun sw ->
    Yume.Server.start_server env ~sw ~listen handler (fun socket ->
        let listen_addr =
          match Eio.Net.listening_addr socket with
          | `Tcp (_, _) as addr -> addr
          | _ -> assert false
        in
        let check path expected_content_length =
          let resp =
            raw_request ~sw env listen_addr
              (Printf.sprintf
                 "HEAD %s HTTP/1.1\r\nHost: localhost\r\nConnection: \
                  close\r\n\r\n"
                 path)
          in
          let headers, body = split_headers_body resp in
          assert (String.starts_with ~prefix:"HTTP/1.1 200" headers);
          assert (body = "");
          assert (
            header_value headers "content-length"
            = Some expected_content_length)
        in
        check "/" (string_of_int (String.length "hello, head"));
        check "/cstruct" (string_of_int (String.length expected_body));

        Eio.Switch.fail sw Common.Exit_normally)
  with Common.Exit_normally -> ()

(* User-supplied framing headers must be replaced, not duplicated. *)
let test_framing_headers () =
  Eio_main.run @@ fun env ->
  Eio.Time.with_timeout_exn env#clock 3.0 @@ fun () ->
  let handler =
    let open Yume.Server in
    Router.(
      use
        [
          get "/cstruct" (fun _ _ ->
              respond_cstruct
                ~headers:
                  [ (`Content_length, "999"); (`Content_type, "text/plain") ]
                ~content_type:"application/octet-stream"
                (Cstruct.of_string "hello cstruct"));
          get "/chunked" (fun _ _ ->
              respond_chunked
                ~headers:
                  [ (`Content_length, "999"); (`Content_type, "text/plain") ]
                ~content_type:"application/octet-stream"
                (fun _ic oc -> Chunked.write oc "data"));
          get "/empty" (fun _ _ ->
              respond ~status:`No_content
                ~headers:[ (`Content_length, "0") ] "");
          get "/te" (fun _ _ ->
              respond ~headers:[ (`Transfer_encoding, "chunked") ] "plain");
        ])
      default_handler
  in
  let listen =
    Eio.Net.getaddrinfo_stream ~service:"0" env#net "localhost" |> List.hd
  in
  try
    Eio.Switch.run @@ fun sw ->
    Yume.Server.start_server env ~sw ~listen handler (fun socket ->
        let listen_addr =
          match Eio.Net.listening_addr socket with
          | `Tcp (_, _) as addr -> addr
          | _ -> assert false
        in
        (* fixed-length framing: exactly one Content-Length, the right
           one *)
        let resp =
          raw_request ~sw env listen_addr
            "GET /cstruct HTTP/1.1\r\nHost: localhost\r\nConnection: \
             close\r\n\r\n"
        in
        let headers, body = split_headers_body resp in
        assert (String.starts_with ~prefix:"HTTP/1.1 200" headers);
        assert (body = "hello cstruct");
        assert (header_values headers "content-length" = [ "13" ]);
        assert (header_values headers "content-type" = [ "application/octet-stream" ]);

        (* chunked framing: no Content-Length at all *)
        let socket = Eio.Net.connect ~sw env#net listen_addr in
        Eio.Buf_write.with_flow socket (fun oc ->
            Eio.Buf_write.string oc
              "GET /chunked HTTP/1.1\r\nHost: localhost\r\n\r\n");
        let ic = Eio.Buf_read.of_flow socket ~max_size:65536 in
        let headers = read_response_head ic in
        assert (String.starts_with ~prefix:"HTTP/1.1 200" headers);
        assert (header_values headers "content-length" = []);
        assert (header_values headers "transfer-encoding" = [ "chunked" ]);
        assert (
          header_values headers "content-type" = [ "application/octet-stream" ]);

        (* RFC 9110 8.6: a 204 response carries no Content-Length,
           even one supplied (wrongly) by the handler *)
        let resp =
          raw_request ~sw env listen_addr
            "GET /empty HTTP/1.1\r\nHost: localhost\r\nConnection: close\r\n\r\n"
        in
        let headers, body = split_headers_body resp in
        assert (String.starts_with ~prefix:"HTTP/1.1 204" headers);
        assert (body = "");
        assert (header_values headers "content-length" = []);

        (* a caller-supplied transfer-encoding must not survive on a
           plain respond (the body is sent unchunked) *)
        let resp =
          raw_request ~sw env listen_addr
            "GET /te HTTP/1.1\r\nHost: localhost\r\nConnection: close\r\n\r\n"
        in
        let headers, body = split_headers_body resp in
        assert (String.starts_with ~prefix:"HTTP/1.1 200" headers);
        assert (body = "plain");
        assert (header_values headers "transfer-encoding" = []);
        assert (header_values headers "content-length" = [ "5" ]);

        Eio.Switch.fail sw Common.Exit_normally)
  with Common.Exit_normally -> ()

(* Unknown paths are 404 for every method; a known path with the
   wrong method is 405 with an Allow header. *)
let test_404_405 () =
  Eio_main.run @@ fun env ->
  Eio.Time.with_timeout_exn env#clock 3.0 @@ fun () ->
  let handler =
    let open Yume.Server in
    Router.(use [ post "/only" (fun _ _ -> respond "posted") ] default_handler)
  in
  let listen =
    Eio.Net.getaddrinfo_stream ~service:"0" env#net "localhost" |> List.hd
  in
  try
    Eio.Switch.run @@ fun sw ->
    Yume.Server.start_server env ~sw ~listen handler (fun socket ->
        let listen_addr =
          match Eio.Net.listening_addr socket with
          | `Tcp (_, _) as addr -> addr
          | _ -> assert false
        in
        let request meth path =
          raw_request ~sw env listen_addr
            (Printf.sprintf
               "%s %s HTTP/1.1\r\nHost: localhost\r\nConnection: close\r\n\r\n"
               meth path)
        in
        let status_and_headers resp =
          let headers, body = split_headers_body resp in
          ignore body;
          (String.sub headers 9 3, headers)
        in
        (* wrong method on an existing path: 405 + Allow *)
        let status, headers = request "GET" "/only" |> status_and_headers in
        assert (status = "405");
        assert (header_value headers "allow" = Some "POST");
        (* DELETE on an existing path: also 405 *)
        let status, _ = request "DELETE" "/only" |> status_and_headers in
        assert (status = "405");
        (* unknown path: 404 for GET and for POST *)
        let status, _ = request "GET" "/nonexistent" |> status_and_headers in
        assert (status = "404");
        let status, _ = request "POST" "/nonexistent" |> status_and_headers in
        assert (status = "404");

        Eio.Switch.fail sw Common.Exit_normally)
  with Common.Exit_normally -> ()

let test_param_int () =
  Eio_main.run @@ fun env ->
  Eio.Time.with_timeout_exn env#clock 3.0 @@ fun () ->
  let handler =
    let open Yume.Server in
    Router.(
      use
        [
          get "/param/:id" (fun _ req ->
              let id = param_int ":id" req in
              let n = query_int "n" req in
              let m = Option.value (query_int_opt "m" req) ~default:0 in
              respond_yojson
                (`Assoc [ ("id", `Int id); ("n", `Int n); ("m", `Int m) ]));
        ])
      default_handler
  in
  let listen =
    Eio.Net.getaddrinfo_stream ~service:"0" env#net "localhost" |> List.hd
  in
  try
    Eio.Switch.run @@ fun sw ->
    Yume.Server.start_server env ~sw ~listen handler (fun socket ->
        let listening_port =
          match Eio.Net.listening_addr socket with
          | `Tcp (_, port) -> port
          | _ -> assert false
        in

        let test_param url expected_status =
          let resp = Yume.Client.get env ~sw url in
          assert (Yume.Client.Response.status resp = expected_status)
        in
        let url = Printf.sprintf "http://localhost:%d/param" listening_port in
        (* non-strict formats must be rejected *)
        test_param (url ^ "/0x12?n=34") `Bad_request;
        test_param (url ^ "/1_2?n=34") `Bad_request;
        (* missing required query *)
        test_param (url ^ "/12") `Bad_request;

        Eio.Switch.fail sw Common.Exit_normally)
  with Common.Exit_normally -> ()

let upload_media env ~filename ~data ~content_type ~url =
  let headers =
    [
      ( `Content_type,
        "multipart/form-data; \
         boundary=---------------------------91791948726096252761377705945" );
    ]
  in
  let body =
    [ {|-----------------------------91791948726096252761377705945--|}; {||} ]
  in
  let body =
    [
      {|-----------------------------91791948726096252761377705945|};
      {|Content-Disposition: form-data; name="file"; filename="|} ^ filename
      ^ {|"|};
      {|Content-Type: |} ^ content_type;
      {||};
      data;
    ]
    @ body
  in
  assert (List.length body <> 2);
  let body = String.concat "\r\n" body in
  Yume.Client.fetch_exn env ~headers ~meth:`POST ~body url

let test_formdata_image image_data () =
  Eio_main.run @@ fun env ->
  Eio.Time.with_timeout_exn env#clock 3.0 @@ fun () ->
  let handler =
    let open Yume.Server in
    Router.(
      use
        [
          post "/" (fun _ req ->
              let data = formdata_exn "file" req in
              respond data.content);
        ])
      default_handler
  in
  let listen =
    Eio.Net.getaddrinfo_stream ~service:"0" env#net "localhost" |> List.hd
  in
  try
    Eio.Switch.run @@ fun sw ->
    Yume.Server.start_server env ~sw ~listen ~error_handler handler
      (fun socket ->
        let listening_port =
          match Eio.Net.listening_addr socket with
          | `Tcp (_, port) -> port
          | _ -> assert false
        in

        let resp =
          upload_media env ~filename:"test.png" ~data:image_data
            ~content_type:"image/png"
            ~url:(Printf.sprintf "http://localhost:%d/" listening_port)
        in
        assert (resp = image_data);

        Eio.Switch.fail sw Common.Exit_normally)
  with Common.Exit_normally -> ()

let test_cors_allow_all () =
  Eio_main.run @@ fun env ->
  Eio.Time.with_timeout_exn env#clock 3.0 @@ fun () ->
  let handler =
    let open Yume.Server in
    Cors.(
      use
        [
          make "/*" ~methods:[ `POST; `PUT; `DELETE; `GET; `PATCH; `OPTIONS ] ();
        ])
    @@ Router.(
         use
           [
             get "/" (fun _ _ -> respond_html "hello");
             get "/expert" (fun _ _ ->
                 let resp = Http.Response.make () in
                 let handler _ oc = Eio.Buf_write.string oc "hello" in
                 BareResponse (`Expert (resp, handler)));
           ])
         default_handler
  in
  let listen =
    Eio.Net.getaddrinfo_stream ~service:"0" env#net "localhost" |> List.hd
  in
  try
    Eio.Switch.run @@ fun sw ->
    Yume.Server.start_server env ~sw ~listen ~error_handler handler
      (fun socket ->
        let listening_port =
          match Eio.Net.listening_addr socket with
          | `Tcp (_, port) -> port
          | _ -> assert false
        in

        let test_options path =
          let resp =
            Yume.Client.request ~meth:`OPTIONS env ~sw
              (Printf.sprintf "http://localhost:%d%s" listening_port path)
          in
          assert (Yume.Client.Response.status resp = `No_content);
          let hs = Yume.Client.Response.headers resp in
          assert (List.assoc `Access_control_allow_origin hs = "*");
          assert (
            List.assoc `Access_control_allow_methods hs
            = "POST, PUT, DELETE, GET, PATCH, OPTIONS");
          ()
        in
        test_options "/";
        test_options "/expert";

        let test_get path =
          let resp =
            Yume.Client.get env ~sw
              (Printf.sprintf "http://localhost:%d%s" listening_port path)
          in
          assert (Yume.Client.Response.status resp = `OK);
          let hs = Yume.Client.Response.headers resp in
          assert (List.assoc `Access_control_allow_origin hs = "*");
          assert (List.assoc `Access_control_expose_headers hs = "");
          ()
        in
        test_get "/";
        test_get "/expert";

        Eio.Switch.fail sw Common.Exit_normally)
  with Common.Exit_normally -> ()

(* Preflight only allows headers from the configured allowlist. *)
let test_cors_allow_headers () =
  Eio_main.run @@ fun env ->
  Eio.Time.with_timeout_exn env#clock 3.0 @@ fun () ->
  let handler =
    let open Yume.Server in
    Cors.(
      use
        [
          make "/*" ~methods:[ `GET; `POST ] ~origin:"https://example.com"
            ~expose:[ `Etag ]
            ~allow_headers:[ `Content_type; `Authorization ]
            ();
        ])
      @@ Router.(use [ get "/" (fun _ _ -> respond_html "hello") ] default_handler)
  in
  let listen =
    Eio.Net.getaddrinfo_stream ~service:"0" env#net "localhost" |> List.hd
  in
  try
    Eio.Switch.run @@ fun sw ->
    Yume.Server.start_server env ~sw ~listen handler (fun socket ->
        let port =
          match Eio.Net.listening_addr socket with
          | `Tcp (_, port) -> port
          | _ -> assert false
        in
        let base = Printf.sprintf "http://localhost:%d" port in
        let preflight request_headers =
          let resp =
            Yume.Client.request ~meth:`OPTIONS ~headers:request_headers env
              ~sw (base ^ "/")
          in
          assert (Yume.Client.Response.status resp = `No_content);
          Yume.Client.Response.headers resp
        in
        (* allowed headers are echoed back *)
        let hs =
          preflight
            [
              ("access-control-request-method", "POST");
              ("access-control-request-headers", "content-type, authorization");
            ]
        in
        assert (
          List.assoc `Access_control_allow_headers hs
          = "content-type, authorization");
        (* a header outside the allowlist is not granted *)
        let hs =
          preflight
            [
              ("access-control-request-method", "POST");
              ("access-control-request-headers", "x-evil");
            ]
        in
        assert (
          List.assoc_opt `Access_control_allow_headers hs = None
          || List.assoc `Access_control_allow_headers hs = "");
        (* regular responses carry origin and expose headers *)
        let resp = Yume.Client.get env ~sw (base ^ "/") in
        let hs = Yume.Client.Response.headers resp in
        assert (List.assoc `Access_control_allow_origin hs = "https://example.com");
        assert (List.assoc `Access_control_expose_headers hs = "etag");

        Eio.Switch.fail sw Common.Exit_normally)
  with Common.Exit_normally -> ()

(* Handler errors (500 from run_handler) must still receive CORS
   headers, and the Logger middleware must not alter responses. *)
let test_cors_error_and_logger () =
  Eio_main.run @@ fun env ->
  Eio.Time.with_timeout_exn env#clock 3.0 @@ fun () ->
  let handler =
    let open Yume.Server in
    Logger.use
    @@ Cors.(
         use
           [
             make "/*" ~methods:[ `GET; `POST ]
               ~origin:"https://example.com" ();
           ])
    @@ Router.(
         use
           [
             get "/" (fun _ _ -> respond_html "hello");
             get "/error" (fun _ _ -> failwith "boom");
           ])
         default_handler
  in
  let listen =
    Eio.Net.getaddrinfo_stream ~service:"0" env#net "localhost" |> List.hd
  in
  try
    Eio.Switch.run @@ fun sw ->
    Yume.Server.start_server env ~sw ~listen handler (fun socket ->
        let port =
          match Eio.Net.listening_addr socket with
          | `Tcp (_, port) -> port
          | _ -> assert false
        in
        let base = Printf.sprintf "http://localhost:%d" port in
        (* Logger middleware is transparent for successful responses *)
        let resp = Yume.Client.get env ~sw (base ^ "/") in
        assert (Yume.Client.Response.status resp = `OK);
        assert (Yume.Client.Response.drain resp = "hello");
        (* a failing handler yields a 500 that still carries CORS
           headers *)
        let resp = Yume.Client.get env ~sw (base ^ "/error") in
        assert (
          Yume.Client.Response.status resp = `Internal_server_error);
        let hs = Yume.Client.Response.headers resp in
        assert (
          List.assoc `Access_control_allow_origin hs = "https://example.com");

        Eio.Switch.fail sw Common.Exit_normally)
  with Common.Exit_normally -> ()

let test_start_server_on () =
  Eio_main.run @@ fun env ->
  Eio.Time.with_timeout_exn env#clock 3.0 @@ fun () ->
  let handler =
    let open Yume.Server in
    Router.(use [ get "/" (fun _ _ -> respond_html "hello") ] default_handler)
  in
  try
    Eio.Switch.run @@ fun sw ->
    Yume.Server.start_server_on env ~sw ~addr:"localhost" ~port:"0" handler
      (fun socket ->
        let endpoint = Yume.Server.endpoint_of_socket socket in
        assert (String.starts_with ~prefix:"http://" endpoint);

        let resp = Yume.Client.get env ~sw (endpoint ^ "/") in
        assert (Yume.Client.Response.status resp = `OK);
        let body = Yume.Client.Response.drain resp in
        assert (body = "hello");

        Eio.Switch.fail sw Common.Exit_normally)
  with Common.Exit_normally -> ()

let () =
  let open Alcotest in
  Common.setup_logs ();
  run "http server"
    [
      ("basics", [ test_case "case1" `Quick test_basics ]);
      ("body", [ test_case "parsing" `Quick test_body_parsing ]);
      ("head", [ test_case "no body" `Quick test_head ]);
      ( "framing",
        [ test_case "header replacement" `Quick test_framing_headers ]);
      ("404_405", [ test_case "status and allow" `Quick test_404_405 ]);
      ("param", [ test_case "typed accessors" `Quick test_param_int ]);
      ( "formdata",
        [
          test_case "small image" `Quick (test_formdata_image test_image);
          test_case "large image" `Quick (test_formdata_image test_image_large);
        ] );
      ( "cors",
        [
          test_case "allow all" `Quick test_cors_allow_all;
          test_case "allow headers" `Quick test_cors_allow_headers;
          test_case "error response" `Quick test_cors_error_and_logger;
        ] );
      ("start_server_on", [ test_case "endpoint" `Quick test_start_server_on ]);
    ]
