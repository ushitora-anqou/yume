(* Strict decimal integer parsing for HTTP parameters.
   [int_of_string] accepts non-decimal formats such as "0x10" and
   "1_0", which is undesirable for HTTP parameters. *)
let parse_strict_int (s : string) : int =
  if s = "" then failwith "parse_strict_int: empty string"
  else
    String.fold_left
      (fun acc ch ->
        let i = Char.code ch - Char.code '0' in
        if not (0 <= i && i <= 9) then
          failwith "parse_strict_int: invalid digit"
        else if acc > (max_int - i) / 10 then
          failwith "parse_strict_int: overflow"
        else (acc * 10) + i)
      0 s

let parse_strict_int_opt (s : string) : int option =
  match parse_strict_int s with
  | i -> Some i
  | exception Failure _ -> None
