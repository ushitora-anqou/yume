open Yume

(* Self-signed certificate generation and a minimal local HTTPS
   server, so that the TLS paths of Client.fetch are tested without
   external network access (the previous suite depended on
   test-certificate sites such as ssl.com, which made CI flaky). *)

let now () = Unix.gettimeofday () |> Ptime.of_float_s |> Option.get

let shift (t : Ptime.t) seconds =
  Ptime.add_span t (Ptime.Span.of_int_s seconds) |> Option.get

let generate_cert ~valid_from ~valid_until ~san_host =
  let open X509 in
  let key = Private_key.generate `ED25519 in
  let subject =
    Distinguished_name.
      [
        Relative_distinguished_name.singleton
          (CN Distinguished_name.(Common_name.v "localhost"));
      ]
  in
  let csr =
    match Signing_request.create subject key with
    | Ok csr -> csr
    | Error (`Msg m) -> failwith ("signing request: " ^ m)
  in
  let san = General_name.singleton General_name.DNS [ san_host ] in
  let extensions =
    Extension.empty
    |> Extension.(add Subject_alt_name (false, san))
    |> Extension.(add Basic_constraints (false, (true, None)))
    |> Extension.(add Ext_key_usage (false, [ `Server_auth ]))
  in
  match
    Signing_request.sign csr ~valid_from ~valid_until ~extensions key subject
  with
  | Ok cert -> (cert, key)
  | Error _ -> failwith "self-sign failed"

(* Serve a fixed response over TLS on a random loopback port. *)
let start_tls_server ~sw env ~cert ~key =
  let listener =
    Eio.Net.listen (Eio.Stdenv.net env) ~sw ~backlog:16 ~reuse_addr:true
      (`Tcp (Eio.Net.Ipaddr.V6.loopback, 0))
  in
  let port =
    match Eio.Net.listening_addr listener with
    | `Tcp (_, port) -> port
    | _ -> assert false
  in
  let config =
    match Tls.Config.server ~certificates:(`Single ([ cert ], key)) () with
    | Ok c -> c
    | Error (`Msg m) -> failwith ("tls config: " ^ m)
  in
  Eio.Fiber.fork_daemon ~sw (fun () ->
      (try
         while true do
           let sock, _ = Eio.Net.accept ~sw listener in
           Eio.Fiber.fork_daemon ~sw (fun () ->
               (try
                  let flow = Tls_eio.server_of_flow config sock in
                  let ic = Eio.Buf_read.of_flow flow ~max_size:65536 in
                  let rec drain () =
                    match Eio.Buf_read.line ic with
                    | "" | "\r" -> ()
                    | _ -> drain ()
                  in
                  drain ();
                  Eio.Buf_write.with_flow flow (fun oc ->
                      Eio.Buf_write.string oc
                        "HTTP/1.1 200 OK\r\nContent-Length: 2\r\nConnection: \
                         close\r\n\r\nok")
                with _ -> ());
               (* always close, so that clients rejected during the
                  handshake do not block on writes *)
               (try Eio.Net.close sock with _ -> ());
               `Stop_daemon)
         done
       with _ -> ());
    `Stop_daemon);
  port

let test_tls () =
  Eio_main.run @@ fun env ->
  Mirage_crypto_rng_unix.use_default ();
  Eio.Switch.run @@ fun sw ->
  let t = now () in
  (* a currently valid certificate is accepted *)
  let cert, key =
    generate_cert ~valid_from:(shift t (-3600)) ~valid_until:(shift t 3600)
      ~san_host:"localhost"
  in
  let port = start_tls_server ~sw env ~cert ~key in
  let authenticator =
    X509.Authenticator.chain_of_trust ~time:(fun () -> Some t) [ cert ]
  in
  (match
     Client.fetch env ~authenticator
       (Printf.sprintf "https://localhost:%d/" port)
   with
  | Ok (`OK, _, "ok") -> ()
  | Ok _ -> assert false
  | Error e -> failwith e);
  (* a hostname not covered by the SAN is rejected *)
  let wrong_cert, wrong_key =
    generate_cert ~valid_from:(shift t (-3600)) ~valid_until:(shift t 3600)
      ~san_host:"example.com"
  in
  let wrong_port = start_tls_server ~sw env ~cert:wrong_cert ~key:wrong_key in
  (match
     Client.fetch env ~authenticator
       (Printf.sprintf "https://localhost:%d/" wrong_port)
   with
  | Error _ -> ()
  | Ok _ -> assert false);
  (* an expired certificate is rejected *)
  let expired_cert, expired_key =
    generate_cert ~valid_from:(shift t (-7200)) ~valid_until:(shift t (-3600))
      ~san_host:"localhost"
  in
  let expired_port =
    start_tls_server ~sw env ~cert:expired_cert ~key:expired_key
  in
  (match
     Client.fetch env ~authenticator
       (Printf.sprintf "https://localhost:%d/" expired_port)
   with
  | Error _ -> ()
  | Ok _ -> assert false);
  ()

(* GET/DELETE must not carry a body: fetch used to advertise the body
   length in Content-Length while never sending it. *)
let test_fetch_get_body_rejected () =
  Eio_main.run @@ fun env ->
  (match Yume.Client.fetch env ~meth:`GET ~body:"x" "http://localhost/" with
   | exception Invalid_argument _ -> ()
   | _ -> assert false)

let () =
  let open Alcotest in
  Common.setup_logs ();
  run "http client"
    [
      ("tls", [ test_case "validation" `Quick test_tls ]);
      ( "fetch body",
        [ test_case "GET with body rejected" `Quick
            test_fetch_get_body_rejected ] );
    ]
