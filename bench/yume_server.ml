(* Benchmark server for Yume.

   Provides the same two responses as the nginx counterpart in
   bench/run.sh:

   - GET /small: a 5-byte text body with an explicit Content-Length,
     for requests/second measurement (parity with nginx static files)
   - GET /large: a 32MiB body with an explicit Content-Length, for
     throughput measurement

   /small-chunked additionally serves the same small body through the
     default respond path, which sends it with chunked transfer
     encoding; measured for reference only. *)

let small = "hello"

let () =
  let port = if Array.length Sys.argv > 1 then Sys.argv.(1) else "8080" in
  Eio_main.run @@ fun env ->
  Eio.Switch.run @@ fun sw ->
  let large = String.make (32 * 1024 * 1024) 'A' in
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
        ])
      default_handler
  in
  Yume.Server.start_server_on env ~sw ~addr:"127.0.0.1" ~port handler
    (fun socket ->
      Printf.printf "listening on %s\n%!"
        (Yume.Server.endpoint_of_socket socket))
