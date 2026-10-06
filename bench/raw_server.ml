(* Raw eio HTTP server for the /large scenario: serves a 32MiB body
   through eio socket writes only (the body is converted to a
   Bigstringaf once at startup, then zero user-space copies per
   request via Buf_write.schedule_cstruct). Used to measure the
   throughput ceiling of eio itself, without the cohttp body
   pipeline. *)

let () =
  let port = if Array.length Sys.argv > 1 then Sys.argv.(1) else "8082" in
  Eio_main.run @@ fun env ->
  Eio.Switch.run @@ fun sw ->
  let large = String.make (32 * 1024 * 1024) 'A' in
  let large_cs =
    Cstruct.of_bigarray
      (Bigstringaf.of_string ~off:0 ~len:(String.length large) large)
  in
  let header =
    Printf.sprintf
      "HTTP/1.1 200 OK\r\nContent-Length: %d\r\nConnection: keep-alive\r\n\r\n"
      (Cstruct.length large_cs)
  in
  let listener =
    Eio.Net.listen (Eio.Stdenv.net env) ~sw ~backlog:128 ~reuse_addr:true
      (`Tcp (Eio.Net.Ipaddr.V4.loopback, int_of_string port))
  in
  Printf.printf "listening on port %s\n%!" port;
  let handle sock =
    let req = Eio.Buf_read.of_flow sock ~max_size:65536 in
    let rec drain_headers () =
      match Eio.Buf_read.line req with "" | "\r" -> () | _ -> drain_headers ()
    in
    let rec loop () =
      drain_headers ();
      Eio.Buf_write.with_flow sock (fun bw ->
          Eio.Buf_write.string bw header;
          Eio.Buf_write.schedule_cstruct bw large_cs;
          Eio.Buf_write.flush bw);
      loop ()
    in
    try loop () with
    | End_of_file -> `Stop_daemon
    | Eio.Io _ -> `Stop_daemon (* connection reset / closed by peer *)
    | Eio.Cancel.Cancelled _ -> `Stop_daemon
  in
  let rec accept () =
    let sock, _addr = Eio.Net.accept ~sw listener in
    Eio.Fiber.fork_daemon ~sw (fun () -> handle sock);
    accept ()
  in
  accept ()
