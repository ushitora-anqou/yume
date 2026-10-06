(* Benchmark server for Yume.

   Provides the same two responses as the nginx counterpart in
   bench/run.sh:

   - GET /small: a 5-byte text body with an explicit Content-Length,
     for requests/second measurement (parity with nginx static files)
   - GET /large: a 32MiB body with an explicit Content-Length, for
     throughput measurement

   /small-chunked additionally serves the same small body through the
     default respond path, which sends it with chunked transfer
     encoding; measured for reference only.

   /large-expert additionally serves the large body through an Expert
     handler using Buf_write.schedule_cstruct, bypassing the cohttp
     body pipeline (zero user-space copies per request); measured to
     isolate the cost of the default pipeline. *)

let small = "hello"

let () =
  let port = if Array.length Sys.argv > 1 then Sys.argv.(1) else "8080" in
  Eio_main.run @@ fun env ->
  Eio.Switch.run @@ fun sw ->
  let large = String.make (32 * 1024 * 1024) 'A' in
  let large_cs =
    Cstruct.of_bigarray
      (Bigstringaf.of_string ~off:0 ~len:(String.length large) large)
  in
  let handler =
    let open Yume.Server in
    Router.(
      use
        [
          get "/small" (fun _ _ ->
              respond ~headers:[ (`Content_length, "5") ] small);
          get "/small-chunked" (fun _ _ -> respond small);
          get "/large" (fun _ _ ->
              respond
                ~headers:
                  [ (`Content_length, string_of_int (String.length large)) ]
                large);
          (* expert handler + schedule_cstruct: bypasses the cohttp
             body pipeline (no per-byte user-space copies) *)
          get "/large-expert" (fun _ _ ->
              let headers =
                [ (`Content_length, string_of_int (Cstruct.length large_cs)) ]
                |> Yume.Headers.to_list |> Http.Header.of_list
              in
              let resp : Cohttp.Response.t = Http.Response.make ~headers () in
              let handler _ic oc =
                Eio.Buf_write.schedule_cstruct oc large_cs;
                Eio.Buf_write.flush oc
              in
              BareResponse (`Expert (resp, handler)));
        ])
      default_handler
  in
  Yume.Server.start_server_on env ~sw ~addr:"127.0.0.1" ~port handler
    (fun socket ->
      Printf.printf "listening on %s\n%!"
        (Yume.Server.endpoint_of_socket socket))
