type private_key = X509.Private_key.t
type public_key = X509.Public_key.t
type keypair = private_key * public_key

let encode_public_key (pub_key : public_key) : string =
  X509.Public_key.encode_pem pub_key

let encode_private_key (priv_key : private_key) : string =
  X509.Private_key.encode_pem priv_key

let decode_private_key (src : string) : private_key =
  src |> X509.Private_key.decode_pem |> Result.get_ok

let decode_public_key (src : string) : public_key =
  src |> X509.Public_key.decode_pem |> Result.get_ok

type signature_header = {
  key_id : string;
  signature : string;
  algorithm : string;
  headers : string list;
}
[@@deriving make]

(* Escape a string item value per RFC 8941: only DQUOTE and REVERSE
   SOLIDUS may be escaped. *)
let escape_string_item (s : string) : string =
  let buf = Buffer.create (String.length s) in
  String.iter
    (fun c ->
      (match c with '"' | '\\' -> Buffer.add_char buf '\\' | _ -> ());
      Buffer.add_char buf c)
    s;
  Buffer.contents buf

let string_of_signature_header (p : signature_header) : string =
  [
    ("keyId", p.key_id);
    ("algorithm", p.algorithm);
    ("headers", p.headers |> String.concat " ");
    ("signature", p.signature);
  ]
  |> List.map (fun (k, v) -> k ^ "=\"" ^ escape_string_item v ^ "\"")
  |> String.concat ","

let generate_keypair () : keypair =
  let priv = X509.Private_key.generate ~bits:2048 `RSA in
  let pub = X509.Private_key.public priv in
  (priv, pub)

let build_signing_string ~(signed_headers : string list) ~(headers : Headers.t)
    ~(meth : Method.t) ~(path : string) : string =
  let pseudo_headers =
    headers |> List.map (fun (k, v) -> (k |> Header.lower_string_of_name, v))
  in
  let meth = Method.to_string meth |> String.lowercase_ascii in
  signed_headers
  |> List.map (function
    | "(request-target)" -> "(request-target): " ^ meth ^ " " ^ path
    | "(created)" | "(expires)" -> failwith "Not implemented"
    | header ->
        let values =
          pseudo_headers
          |> List.filter_map (function
            | k, v when k = header -> Some v
            | _ -> None)
        in
        if List.length values = 0 then
          failwith ("Specified signed header not found: " ^ header)
        else
          let value = values |> String.concat ", " in
          header ^ ": " ^ value)
  |> String.concat "\n"

let may_cons_digest_header ?(prefix = "SHA-256") (headers : Headers.t)
    (body : string option) : Headers.t =
  body
  |> Option.fold ~none:headers ~some:(fun body ->
      let digest =
        body |> Digestif.SHA256.digest_string |> Digestif.SHA256.to_raw_string
        |> Base64.encode_exn
      in
      let digest = prefix ^ "=" ^ digest in
      match List.assoc_opt `Digest headers with
      | Some v when v <> digest -> failwith "Digest not match"
      | Some _ -> headers
      | _ -> headers |> List.cons (`Digest, digest))

let sign ~(priv_key : private_key) ~(key_id : string)
    ~(signed_headers : string list) ~(headers : Headers.t) ~(meth : Method.t)
    ~(path : string) ~(body : string option) : Headers.t =
  let algorithm = "rsa-sha256" in
  let headers = may_cons_digest_header headers body in
  let signing_string =
    build_signing_string ~signed_headers ~headers ~meth ~path
  in
  let signature =
    match
      X509.Private_key.sign `SHA256 priv_key ~scheme:`RSA_PKCS1
        (`Message signing_string)
    with
    | Ok s -> Base64.encode_exn s
    | Error (`Msg s) -> failwith ("Sign error: " ^ s)
  in
  let sig_header =
    make_signature_header ~key_id ~signature ~algorithm ~headers:signed_headers
      ()
    |> string_of_signature_header
  in
  headers |> List.cons (`Signature, sig_header)

(* Parse a Signature header value of the form k1=v1,k2=v2,... (with
   double-quoted values), returning [Error] instead of raising on
   malformed input: the header is attacker-controlled. Values may
   contain commas and escaped characters (escaped dquote and escaped
   backslash) per RFC 8941. *)
let parse_signature_header (src : string) : (signature_header, string) result
    =
  let length = String.length src in
  let error fmt = Printf.ksprintf (fun s -> Error s) fmt in
  let rec fields i acc =
    if i >= length then error "signature: unexpected end of input"
    else if src.[i] = ',' then
      error "signature: empty field at offset %d" i
    else field i acc
  and field i acc =
    let rec key_end j =
      if j < length && src.[j] <> '=' && src.[j] <> ',' then key_end (j + 1)
      else j
    in
    let kend = key_end i in
    if kend >= length || src.[kend] <> '=' then
      error "signature: missing '=' in field at offset %d" i
    else
      let key = String.trim (String.sub src i (kend - i)) in
      if key = "" then error "signature: empty field name at offset %d" i
      else if kend + 1 >= length || src.[kend + 1] <> '"' then
        error "signature: value of %S is not double-quoted" key
      else
        let buf = Buffer.create 16 in
        let rec value_end j =
          if j >= length then None
          else
            match src.[j] with
            | '"' -> Some (j + 1)
            | '\\' when j + 1 < length && (src.[j + 1] = '"' || src.[j + 1] = '\\') ->
                Buffer.add_char buf src.[j + 1];
                value_end (j + 2)
            | '\\' -> None
            | c ->
                Buffer.add_char buf c;
                value_end (j + 1)
        in
        (match value_end (kend + 2) with
        | None -> error "signature: unterminated value of %S" key
        | Some next -> (
            let acc = (key, Buffer.contents buf) :: acc in
            let rec skip_spaces j =
              if j < length && src.[j] = ' ' then skip_spaces (j + 1)
              else j
            in
            let next = skip_spaces next in
            if next >= length then Ok (List.rev acc)
            else if src.[next] <> ',' then
              error "signature: unexpected character %C at offset %d"
                src.[next] next
            else fields (skip_spaces (next + 1)) acc))
  in
  match fields 0 [] with
  | Error e -> Error e
  | Ok fields -> (
      let get k = List.assoc_opt k fields in
      match (get "keyId", get "signature", get "algorithm", get "headers")
      with
      | Some key_id, Some signature, Some algorithm, Some headers ->
          Ok
            (make_signature_header ~key_id ~signature ~algorithm
               ~headers:(String.split_on_char ' ' headers) ())
      | None, _, _, _ -> Error "signature: missing keyId"
      | _, None, _, _ -> Error "signature: missing signature"
      | _, _, None, _ -> Error "signature: missing algorithm"
      | _, _, _, None -> Error "signature: missing headers")

(* Check the Digest header against [body] when both are present. A
   mismatch means the body was tampered with, independently of the
   signature itself. *)
let digest_matches (headers : Headers.t) (body : string option) : bool =
  match (body, List.assoc_opt `Digest headers) with
  | Some body, Some declared ->
      let computed =
        body |> Digestif.SHA256.digest_string |> Digestif.SHA256.to_raw_string
        |> Base64.encode_exn
      in
      String.equal declared ("SHA-256=" ^ computed)
  | _ -> true

type verify_error = [
  | `AlgorithmNotImplemented
  | `DigestMismatch
  | `VerificationFailure of string
]

let verify ~(pub_key : public_key) ~(algorithm : string)
    ~(signed_headers : string list) ~(signature : string) ~(headers : Headers.t)
    ~(meth : Method.t) ~(path : string) ~(body : string option) :
    (unit, verify_error) result =
  if algorithm <> "rsa-sha256" then Error `AlgorithmNotImplemented
  else if not (digest_matches headers body) then Error `DigestMismatch
  else (
    (* Recompute the Digest header when absent, mirroring the signer,
       so that [signed_headers] may include "digest". *)
    let headers =
      match (body, List.assoc_opt `Digest headers) with
      | Some body, None -> may_cons_digest_header headers (Some body)
      | _ -> headers
    in
    match Base64.decode signature with
    | Error `Msg msg ->
        Error (`VerificationFailure ("bad signature encoding: " ^ msg))
    | Ok signature -> (
        match build_signing_string ~signed_headers ~headers ~meth ~path with
        | exception Failure msg ->
            Error
              (`VerificationFailure ("cannot build signing string: " ^ msg))
        | signing_string -> (
            match
              X509.Public_key.verify `SHA256 ~scheme:`RSA_PKCS1 ~signature
                pub_key (`Message signing_string)
            with
            | Ok () -> Ok ()
            | Error (`Msg msg) -> Error (`VerificationFailure msg))))
