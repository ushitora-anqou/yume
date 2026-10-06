open Yume

(* Note: write/write_keepalive/write_finish include a flush, which
   requires a driver fiber to complete and therefore cannot be tested
   via [serialize_to_string]. Their encoding is covered here through
   write_chunk with the same payload, and their flushing behavior is
   exercised by the chunked route in test_http_server. *)
let test_write_chunk () =
  let serialize f =
    let oc = Eio.Buf_write.create 1024 in
    f oc;
    Eio.Buf_write.serialize_to_string oc
  in
  assert (
    serialize (fun oc -> Chunked.write_chunk oc "hello") = "5\r\nhello\r\n");
  assert (
    serialize (fun oc ->
        Chunked.write_chunk oc "hello, ";
        Chunked.write_chunk oc "world")
    = "7\r\nhello, \r\n5\r\nworld\r\n");
  (* a keepalive chunk carries a single 0xff byte *)
  assert (serialize (fun oc -> Chunked.write_chunk oc "\xff") = "1\r\n\xff\r\n");
  (* the final zero-length chunk terminates the body *)
  assert (serialize (fun oc -> Chunked.write_chunk oc "") = "0\r\n\r\n");
  ()

let () =
  let open Alcotest in
  run "chunked"
    [ ("write_chunk", [ test_case "chunk encoding" `Quick test_write_chunk ]) ]
