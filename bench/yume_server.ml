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

(* Cache of pre-built Cstructs for the /size-cs route, so that the
   fast path reuses the same buffer across requests. *)
let cs_cache : (int, Cstruct.t) Hashtbl.t = Hashtbl.create 16

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
          (* zero-copy path via Server.respond_cstruct: bypasses the
             cohttp body pipeline (no per-byte user-space copies) *)
          get "/large-expert" (fun _ _ ->
              respond_cstruct ~content_type:"application/octet-stream" large_cs);
          (* sized variants for copy-cost analysis: /size builds a
             fresh string per request (respond path), /size-cs reuses
             a cached Cstruct (respond_cstruct path) *)
          get "/size/:kb" (fun _ req ->
              let kb = param_int ":kb" req in
              respond
                ~headers:[ (`Content_type, "application/octet-stream") ]
                (String.make (kb * 1024) 'A'));
          get "/size-cs/:kb" (fun _ req ->
              let kb = param_int ":kb" req in
              let cs =
                match Hashtbl.find_opt cs_cache kb with
                | Some cs -> cs
                | None ->
                    let cs = Cstruct.of_string (String.make (kb * 1024) 'A') in
                    Hashtbl.replace cs_cache kb cs;
                    cs
              in
              respond_cstruct ~content_type:"application/octet-stream" cs);
          (* chunked streaming variants: /stream writes 1MiB string
             chunks (one copy per chunk), /stream-cs writes a reused
             1MiB Cstruct chunk (zero copies) *)
          get "/stream/:kb" (fun _ req ->
              let kb = param_int ":kb" req in
              let total = kb * 1024 in
              let chunk = String.make (1024 * 1024) 'A' in
              respond_chunked ~content_type:"application/octet-stream"
                (fun _ic oc ->
                  let rec loop sent =
                    if sent < total then (
                      let n = min (String.length chunk) (total - sent) in
                      Chunked.write oc
                        (if n = String.length chunk then chunk
                         else String.sub chunk 0 n);
                      loop (sent + n))
                  in
                  loop 0));
          get "/stream-cs/:kb" (fun _ req ->
              let kb = param_int ":kb" req in
              let total = kb * 1024 in
              let chunk =
                match Hashtbl.find_opt cs_cache 1024 with
                | Some cs -> cs
                | None ->
                    let cs =
                      Cstruct.of_string (String.make (1024 * 1024) 'A')
                    in
                    Hashtbl.replace cs_cache 1024 cs;
                    cs
              in
              respond_chunked ~content_type:"application/octet-stream"
                (fun _ic oc ->
                  let rec loop sent =
                    if sent < total then (
                      let n = min (Cstruct.length chunk) (total - sent) in
                      Chunked.write_cstruct oc
                        (if n = Cstruct.length chunk then chunk
                         else Cstruct.sub chunk 0 n);
                      loop (sent + n))
                  in
                  loop 0));
        ])
      default_handler
  in
  Yume.Server.start_server_on env ~sw ~addr:"127.0.0.1" ~port handler
    (fun socket ->
      Printf.printf "listening on %s\n%!"
        (Yume.Server.endpoint_of_socket socket))
