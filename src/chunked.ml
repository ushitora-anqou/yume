(* Chunked transfer encoding (RFC 9112 section 7.1) writers for
   [Eio.Buf_write.t]. *)

(* Write [s] as a single chunk without flushing. Useful when batching
   chunks; call [Eio.Buf_write.flush] (or [write], which flushes) to
   actually send the buffered data. *)
let write_chunk oc s =
  Eio.Buf_write.string oc (Printf.sprintf "%x\r\n" (String.length s));
  Eio.Buf_write.string oc s;
  Eio.Buf_write.string oc "\r\n"

(* Write [s] as a single chunk and flush. Flushing on every chunk is
   necessary to actually send the data and to detect connection
   resets. *)
let write oc s =
  write_chunk oc s;
  Eio.Buf_write.flush oc

(* Send a keepalive chunk consisting of a single 0xff byte. For idle
   connections this is the only way to notice a client-side reset in
   a timely manner. *)
let write_keepalive oc = write oc "\xff"

(* Write the final zero-length chunk that terminates the chunked
   body. Necessary for finite streams: the underlying server does not
   send it automatically after the expert handler returns. *)
let write_finish oc = write oc ""

(* Cstruct version of [write]: the chunk framing is buffered while
   the data itself is enqueued without copying via
   [Eio.Buf_write.schedule_cstruct]. That function flushes any
   pending buffered data first, so the framing/data order is
   preserved. Reusing the same Cstruct across chunks makes each chunk
   cost a single writev. *)
let write_cstruct oc (cs : Cstruct.t) =
  Eio.Buf_write.string oc (Printf.sprintf "%x\r\n" (Cstruct.length cs));
  Eio.Buf_write.schedule_cstruct oc cs;
  Eio.Buf_write.string oc "\r\n";
  Eio.Buf_write.flush oc
