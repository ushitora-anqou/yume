open Yume

let all_names : Header.name list =
  [
    `A_IM;
    `Accept;
    `Accept_charset;
    `Accept_datetime;
    `Accept_encoding;
    `Accept_language;
    `Accept_patch;
    `Accept_post;
    `Accept_query;
    `Accept_ranges;
    `Access_control_allow_credentials;
    `Access_control_allow_headers;
    `Access_control_allow_methods;
    `Access_control_allow_origin;
    `Access_control_expose_headers;
    `Access_control_max_age;
    `Access_control_request_headers;
    `Access_control_request_method;
    `Age;
    `Allow;
    `ALPN;
    `Alt_svc;
    `Alt_used;
    `Authorization;
    `Cache_control;
    `Connection;
    `Content_disposition;
    `Content_encoding;
    `Content_language;
    `Content_length;
    `Content_location;
    `Content_range;
    `Content_type;
    `Cookie;
    `Crypto_key;
    `Date;
    `Delta_base;
    `Digest;
    `Etag;
    `Expect;
    `Expires;
    `Forwarded;
    `From;
    `Host;
    `If_match;
    `If_modified_since;
    `If_none_match;
    `If_range;
    `If_unmodified_since;
    `IM;
    `Last_modified;
    `Link;
    `Location;
    `Max_forwards;
    `Origin;
    `Pragma;
    `Prefer;
    `Preference_applied;
    `Proxy_authenticate;
    `Proxy_authentication_info;
    `Proxy_authorization;
    `Range;
    `Referer;
    `Retry_after;
    `Sec_websocket_accept;
    `Sec_websocket_extensions;
    `Sec_websocket_key;
    `Sec_websocket_protocol;
    `Sec_websocket_version;
    `Server;
    `Set_cookie;
    `Signature;
    `Strict_transport_security;
    `TE;
    `Topic;
    `Trailer;
    `Transfer_encoding;
    `TTL;
    `Upgrade;
    `Urgency;
    `User_agent;
    `Vary;
    `Via;
    `Warning;
    `WWW_authenticate;
  ]

let test_roundtrip () =
  List.iter
    (fun n ->
      let s = Header.lower_string_of_name n in
      assert (s = String.lowercase_ascii s);
      assert (Header.name_of_string s = n))
    all_names;
  ()

let test_case_insensitive () =
  assert (Header.name_of_string "CONTENT-TYPE" = `Content_type);
  assert (Header.name_of_string "Content-Length" = `Content_length);
  assert (Header.name_of_string "WWW-Authenticate" = `WWW_authenticate);
  assert (
    Header.name_of_string "Sec-WebSocket-Protocol" = `Sec_websocket_protocol);
  assert (Header.name_of_string "TTL" = `TTL);
  ()

let test_raw () =
  assert (Header.name_of_string "x-anqou" = `Raw "x-anqou");
  assert (Header.name_of_string "X-Anqou" = `Raw "x-anqou");
  assert (Header.lower_string_of_name (`Raw "X-Anqou") = "X-Anqou");
  assert (Header.string_of_name (`Raw "x-anqou") = "x-anqou");
  ()

let test_tuple () =
  assert (
    Header.to_tuple (`Content_type, "text/html") = ("content-type", "text/html"));
  assert (
    Header.of_tuple ("CONTENT-TYPE", "text/html") = (`Content_type, "text/html"));
  assert (Header.of_tuple ("X-Anqou", "v") = (`Raw "x-anqou", "v"));
  ()

let () =
  let open Alcotest in
  run "header"
    [
      ("roundtrip", [ test_case "all fields" `Quick test_roundtrip ]);
      ( "case_insensitive",
        [ test_case "mixed case" `Quick test_case_insensitive ] );
      ("raw", [ test_case "unknown fields" `Quick test_raw ]);
      ("tuple", [ test_case "tuple conversion" `Quick test_tuple ]);
    ]
