type single_pattern =
  | L of string
  | P of { pattern : string; suffix : string }
  | S

type t = single_pattern list

let split_on_slash s =
  s |> String.split_on_char '/' |> List.tl |> List.filter (( <> ) "")

let of_string (src : string) : t =
  src |> split_on_slash
  |> List.map (function
       | "*" -> S
       | x when String.starts_with ~prefix:":" x -> (
           match String.index_from_opt x 1 ':' with
           | None -> P { pattern = x; suffix = "" }
           | Some i ->
               P
                 {
                   pattern = String.sub x 0 i;
                   suffix = String.sub x i (String.length x - i);
                 })
       | x -> L x)

let perform ~(pat : t) (src : string) : (string * string) list option =
  let rec aux param = function
    | [], [] | _, [ S ] -> Some param
    | x :: xs, L y :: ys when x = y -> aux param (xs, ys)
    | x :: xs, P { pattern; suffix } :: ys when String.ends_with ~suffix x ->
        let matched = String.sub x 0 (String.length x - String.length suffix) in
        if matched = "" then None else aux ((pattern, matched) :: param) (xs, ys)
    | _ -> None
  in
  aux [] (split_on_slash src, pat)
