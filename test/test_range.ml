open Yume

let test_of_string () =
  assert (Range.of_string "bytes=0-100" = [ `Both (0, 100) ]);
  assert (Range.of_string "bytes=100-" = [ `Start 100 ]);
  assert (Range.of_string "bytes=-100" = [ `End 100 ]);
  (* the unit is case-insensitive *)
  assert (Range.of_string "Bytes=0-100" = [ `Both (0, 100) ]);
  assert (Range.of_string "BYTES=-100" = [ `End 100 ]);
  assert (
    Range.of_string "bytes=0-100, 200-300"
    = [ `Both (0, 100); `Both (200, 300) ]);
  (match Range.of_string "items=0-100" with
  | exception Range.Invalid _ -> ()
  | _ -> assert false);
  (match Range.of_string "bytes=" with
  | exception Range.Invalid _ -> ()
  | _ -> assert false);
  (match Range.of_string "bytes=-" with
  | exception Range.Invalid _ -> ()
  | _ -> assert false);
  (match Range.of_string "bytes=0x1-2" with
  | exception Range.Invalid _ -> ()
  | _ -> assert false);
  (match Range.of_string "bytes=1-2-3" with
  | exception Range.Invalid _ -> ()
  | _ -> assert false);
  ()

let test_is_valid () =
  let valid ~file_size r expected =
    assert (Range.is_valid ~file_size r = expected)
  in
  valid ~file_size:1000 [ `Both (0, 100) ] true;
  (* a last-byte-pos at or beyond the end denotes the remainder *)
  valid ~file_size:1000 [ `Both (0, 1000) ] true;
  valid ~file_size:1000 [ `Both (0, 5000) ] true;
  valid ~file_size:1000 [ `End 1000 ] true;
  valid ~file_size:1000 [ `Start 999 ] true;
  (* an unsatisfiable first-byte-pos is invalid *)
  valid ~file_size:1000 [ `Start 1000 ] false;
  valid ~file_size:1000 [ `Both (1000, 2000) ] false;
  valid ~file_size:1000 [ `End 0 ] false;
  valid ~file_size:1000 [ `End 1 ] true;
  valid ~file_size:1000 [ `Both (5, 3) ] false;
  valid ~file_size:1000 [ `Both (0, 100); `Both (200, 300) ] true;
  valid ~file_size:1000 [ `Both (0, 100); `Both (0, 1000) ] true;
  (* a suffix range on an empty representation is unsatisfiable *)
  valid ~file_size:0 [ `End 5 ] false;
  valid ~file_size:0 [] true;
  valid ~file_size:0 [ `Both (0, 5) ] false;
  ()

let test_response_values () =
  assert (
    Range.content_range ~file_size:1000 (`Both (0, 100)) = "bytes 0-100/1000");
  assert (
    Range.content_range ~file_size:1000 (`Start 900) = "bytes 900-999/1000");
  assert (Range.content_range ~file_size:1000 (`End 100) = "bytes 900-999/1000");
  (* clamped to the end of the representation *)
  assert (
    Range.content_range ~file_size:1000 (`Both (0, 1000)) = "bytes 0-999/1000");
  assert (
    Range.content_range ~file_size:1000 (`End 1000) = "bytes 0-999/1000");
  assert (Range.content_length ~file_size:1000 (`Both (0, 100)) = 101);
  assert (Range.content_length ~file_size:1000 (`Start 900) = 100);
  assert (Range.content_length ~file_size:1000 (`End 100) = 100);
  assert (Range.content_length ~file_size:1000 (`End 1000) = 1000);
  assert (Range.content_length ~file_size:1000 (`Both (0, 1000)) = 1000);
  assert (Range.offset_length ~file_size:1000 (`Both (0, 100)) = (0, 101));
  assert (Range.offset_length ~file_size:1000 (`Start 900) = (900, 100));
  assert (Range.offset_length ~file_size:1000 (`End 100) = (900, 100));
  assert (Range.offset_length ~file_size:1000 (`End 1000) = (0, 1000));
  assert (Range.offset_length ~file_size:1000 (`Both (0, 1000)) = (0, 1000));
  ()

let () =
  let open Alcotest in
  run "range"
    [
      ("of_string", [ test_case "parse" `Quick test_of_string ]);
      ("is_valid", [ test_case "validity" `Quick test_is_valid ]);
      ( "response_values",
        [ test_case "content range" `Quick test_response_values ] );
    ]
