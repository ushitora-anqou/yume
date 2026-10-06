open Yume

let test_basic () =
  let recv_text = ref "" in
  let expected_string = "TEST TEXT" in
  Eio_main.run (fun env ->
      Mirage_crypto_rng_unix.use_default ();
      try
        Eio.Time.with_timeout_exn env#clock 3.0 @@ fun () ->
        let handler =
          let open Server in
          default_handler
          |> Router.(
               use
                 [
                   get "/ws" (fun _ req ->
                       websocket req (fun ws_conn ->
                           recv_text :=
                             ws_recv ws_conn |> Option.value ~default:!recv_text));
                 ])
        in
        let listen =
          Eio.Net.getaddrinfo_stream ~service:"0" env#net "localhost" |> List.hd
        in
        Eio.Switch.run @@ fun sw ->
        Server.start_server env ~listen ~sw handler (fun socket ->
            let listening_port =
              match Eio.Net.listening_addr socket with
              | `Tcp (_, port) -> port
              | _ -> assert false
            in
            let ws_conn =
              let rec loop () =
                Eio.Time.sleep env#clock 1.0;
                try
                  Ws.Client.connect ~sw env
                    (Printf.sprintf "http://localhost:%d/ws" listening_port)
                with _ -> loop ()
              in
              loop ()
            in
            Ws.Client.write ws_conn
              (Websocket.Frame.create ~opcode:Text ~content:expected_string ());
            ())
      with Eio.Time.Timeout -> ());
  assert (!recv_text = expected_string);
  ()

(* A websocket upgrade failure (e.g. a plain GET without upgrade
   headers hitting a websocket route) must answer with an error
   instead of hanging, and the ws runner must keep serving later
   requests. *)
let test_bad_upgrade_does_not_kill_runner () =
  Eio_main.run (fun env ->
      Mirage_crypto_rng_unix.use_default ();
      try
        Eio.Time.with_timeout_exn env#clock 3.0 @@ fun () ->
        let handler =
          let open Server in
          default_handler
          |> Router.(
               use
                 [
                   get "/ws" (fun _ req -> websocket req (fun _ -> ()));
                   get "/health" (fun _ _ -> respond "ok");
                 ])
        in
        let listen =
          Eio.Net.getaddrinfo_stream ~service:"0" env#net "localhost" |> List.hd
        in
        Eio.Switch.run @@ fun sw ->
        Server.start_server env ~listen ~sw handler (fun socket ->
            let port =
              match Eio.Net.listening_addr socket with
              | `Tcp (_, port) -> port
              | _ -> assert false
            in
            let base = Printf.sprintf "http://localhost:%d" port in
            (* plain GET without upgrade headers fails the upgrade *)
            let resp = Client.get env ~sw (base ^ "/ws") in
            let status = Client.Response.status resp in
            assert (Status.is_error status);
            ignore @@ Client.Response.drain resp;
            (* the runner still works: another websocket connects *)
            let ws_conn =
              let rec loop () =
                Eio.Time.sleep env#clock 0.1;
                try Ws.Client.connect ~sw env (base ^ "/ws") with _ -> loop ()
              in
              loop ()
            in
            Ws.Client.write ws_conn
              (Websocket.Frame.create ~opcode:Text ~content:"still alive" ());
            (* and plain routes are unaffected *)
            let resp = Client.get env ~sw (base ^ "/health") in
            assert (Client.Response.status resp = `OK);
            assert (Client.Response.drain resp = "ok");
            Eio.Switch.fail sw Common.Exit_normally)
      with Eio.Time.Timeout | Common.Exit_normally -> ())

let () =
  let open Alcotest in
  Common.setup_logs ();
  run "ws"
    [
      ("basic", [ test_case "case1" `Quick test_basic ]);
      ( "runner",
        [ test_case "survives bad upgrade" `Quick
            test_bad_upgrade_does_not_kill_runner ] );
    ]
