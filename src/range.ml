(* Range requests (RFC 9110 section 14). *)

type t = [ `Start of int | `End of int | `Both of int * int ]

exception Invalid of string

let fail msg = raise (Invalid msg)

let strict_int s =
  match Strict_int.parse_strict_int s with
  | i -> i
  | exception Failure msg -> fail msg

(* Parse a Range header value, e.g. "bytes=0-100". Raise [Invalid] on
   malformed values. The unit is matched case-insensitively. *)
let of_string (s : string) : t list =
  let s = String.lowercase_ascii s in
  let range =
    if String.starts_with ~prefix:"bytes=" s then
      String.sub s 6 (String.length s - 6)
    else fail "no bytes= prefix"
  in
  range |> String.split_on_char ',' |> List.map String.trim
  |> List.map (fun s ->
      match String.split_on_char '-' s with
      | [ ""; "" ] -> fail "start and end not found"
      | [ start; "" ] -> `Start (strict_int start)
      | [ ""; end_ ] -> `End (strict_int end_)
      | [ start; end_ ] -> `Both (strict_int start, strict_int end_)
      | _ -> fail "invalid format")

(* Clamp a suffix length or a last-byte-pos against the end of the
   file, following RFC 9110 14.1.1: a last-byte-pos at or beyond the
   end of the representation denotes the remainder of the
   representation. *)
let clamp ~file_size n = min n file_size
let clamp_last ~file_size n = min n (file_size - 1)

(* Check whether all ranges are satisfiable against a file of
   [file_size] bytes. A last-byte-pos beyond the end is satisfiable
   (clamped); an unsatisfiable first-byte-pos is not. *)
let is_valid ~file_size (ranges : t list) : bool =
  let rec loop = function
    | [] -> true
    | `Start start :: _ when start < 0 || start >= file_size -> false
    | `End end_ :: _ when end_ <= 0 -> false
    | `Both (start, end_) :: _
      when start < 0 || end_ < 0 || start >= file_size || start > end_ ->
        false
    | _ :: xs -> loop xs
  in
  loop ranges

(* The value for the Content-Range response header. *)
let content_range ~file_size (r : t) : string =
  let fmt = Printf.sprintf "bytes %d-%d/%d" in
  match r with
  | `Start start -> fmt start (file_size - 1) file_size
  | `End end_ ->
      fmt (file_size - clamp ~file_size end_) (file_size - 1) file_size
  | `Both (start, end_) -> fmt start (clamp_last ~file_size end_) file_size

(* The value for the Content-Length response header. *)
let content_length ~file_size (r : t) : int =
  match r with
  | `Start start -> file_size - start
  | `End end_ -> clamp ~file_size end_
  | `Both (start, end_) -> clamp_last ~file_size end_ - start + 1

(* The corresponding (offset, length) in the file. *)
let offset_length ~file_size (r : t) : int * int =
  match r with
  | `Start start -> (start, file_size - start)
  | `End end_ ->
      let len = clamp ~file_size end_ in
      (file_size - len, len)
  | `Both (start, end_) -> (start, clamp_last ~file_size end_ - start + 1)
