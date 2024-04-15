let error_handler ~req:_ ~status:_ ~headers:_ ~body:_ = assert false

exception Exit_normally

let test_basics () =
  let expected_get_response = "response test text" in

  Eio_main.run @@ fun env ->
  Eio.Time.with_timeout_exn env#clock 3.0 @@ fun () ->
  let handler =
    let open Yume.Server in
    Router.(
      use
        [
          get "/" (fun _ _ -> respond expected_get_response);
          post "/" (fun _ req -> (* echo *) query "msg" req |> respond);
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

        let resp =
          Yume.Client.post env ~sw
            (Printf.sprintf "http://localhost:%d/?msg=hello" listening_port)
        in
        assert (Yume.Client.Response.status resp = `OK);
        let body = Yume.Client.Response.drain resp in
        assert (body = "hello");

        Eio.Switch.fail sw Exit_normally)
  with Exit_normally -> ()

let () =
  let open Alcotest in
  Common.setup_logs ();
  run "http server" [ ("basics", [ test_case "case1" `Quick test_basics ]) ]
