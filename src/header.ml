type name =
  [ `A_IM
  | `Accept
  | `Accept_charset
  | `Accept_datetime
  | `Accept_encoding
  | `Accept_language
  | `Accept_patch
  | `Accept_post
  | `Accept_query
  | `Accept_ranges
  | `Access_control_allow_credentials
  | `Access_control_allow_headers
  | `Access_control_allow_methods
  | `Access_control_allow_origin
  | `Access_control_expose_headers
  | `Access_control_max_age
  | `Access_control_request_headers
  | `Access_control_request_method
  | `Age
  | `Allow
  | `ALPN
  | `Alt_svc
  | `Alt_used
  | `Authorization
  | `Cache_control
  | `Connection
  | `Content_disposition
  | `Content_encoding
  | `Content_language
  | `Content_length
  | `Content_location
  | `Content_range
  | `Content_type
  | `Cookie
  | `Crypto_key
  | `Date
  | `Delta_base
  | `Digest
  | `Etag
  | `Expect
  | `Expires
  | `Forwarded
  | `From
  | `Host
  | `If_match
  | `If_modified_since
  | `If_none_match
  | `If_range
  | `If_unmodified_since
  | `IM
  | `Last_modified
  | `Link
  | `Location
  | `Max_forwards
  | `Origin
  | `Pragma
  | `Prefer
  | `Preference_applied
  | `Proxy_authenticate
  | `Proxy_authentication_info
  | `Proxy_authorization
  | `Range
  | `Raw of string
  | `Referer
  | `Retry_after
  | `Sec_websocket_accept
  | `Sec_websocket_extensions
  | `Sec_websocket_key
  | `Sec_websocket_protocol
  | `Sec_websocket_version
  | `Server
  | `Set_cookie
  | `Signature
  | `Strict_transport_security
  | `TE
  | `Topic
  | `Trailer
  | `Transfer_encoding
  | `TTL
  | `Upgrade
  | `Urgency
  | `User_agent
  | `Vary
  | `Via
  | `Warning
  | `WWW_authenticate ]

let lower_string_of_name : name -> string = function
  | `A_IM -> "a-im"
  | `Accept -> "accept"
  | `Accept_charset -> "accept-charset"
  | `Accept_datetime -> "accept-datetime"
  | `Accept_encoding -> "accept-encoding"
  | `Accept_language -> "accept-language"
  | `Accept_patch -> "accept-patch"
  | `Accept_post -> "accept-post"
  | `Accept_query -> "accept-query"
  | `Accept_ranges -> "accept-ranges"
  | `Access_control_allow_credentials -> "access-control-allow-credentials"
  | `Access_control_allow_headers -> "access-control-allow-headers"
  | `Access_control_allow_methods -> "access-control-allow-methods"
  | `Access_control_allow_origin -> "access-control-allow-origin"
  | `Access_control_expose_headers -> "access-control-expose-headers"
  | `Access_control_max_age -> "access-control-max-age"
  | `Access_control_request_headers -> "access-control-request-headers"
  | `Access_control_request_method -> "access-control-request-method"
  | `Age -> "age"
  | `Allow -> "allow"
  | `ALPN -> "alpn"
  | `Alt_svc -> "alt-svc"
  | `Alt_used -> "alt-used"
  | `Authorization -> "authorization"
  | `Cache_control -> "cache-control"
  | `Connection -> "connection"
  | `Content_disposition -> "content-disposition"
  | `Content_encoding -> "content-encoding"
  | `Content_language -> "content-language"
  | `Content_length -> "content-length"
  | `Content_location -> "content-location"
  | `Content_range -> "content-range"
  | `Content_type -> "content-type"
  | `Cookie -> "cookie"
  | `Crypto_key -> "crypto-key"
  | `Date -> "date"
  | `Delta_base -> "delta-base"
  | `Digest -> "digest"
  | `Etag -> "etag"
  | `Expect -> "expect"
  | `Expires -> "expires"
  | `Forwarded -> "forwarded"
  | `From -> "from"
  | `Host -> "host"
  | `If_match -> "if-match"
  | `If_modified_since -> "if-modified-since"
  | `If_none_match -> "if-none-match"
  | `If_range -> "if-range"
  | `If_unmodified_since -> "if-unmodified-since"
  | `IM -> "im"
  | `Last_modified -> "last-modified"
  | `Link -> "link"
  | `Location -> "location"
  | `Max_forwards -> "max-forwards"
  | `Origin -> "origin"
  | `Pragma -> "pragma"
  | `Prefer -> "prefer"
  | `Preference_applied -> "preference-applied"
  | `Proxy_authenticate -> "proxy-authenticate"
  | `Proxy_authentication_info -> "proxy-authentication-info"
  | `Proxy_authorization -> "proxy-authorization"
  | `Range -> "range"
  | `Raw s -> s
  | `Referer -> "referer"
  | `Retry_after -> "retry-after"
  | `Sec_websocket_accept -> "sec-websocket-accept"
  | `Sec_websocket_extensions -> "sec-websocket-extensions"
  | `Sec_websocket_key -> "sec-websocket-key"
  | `Sec_websocket_protocol -> "sec-websocket-protocol"
  | `Sec_websocket_version -> "sec-websocket-version"
  | `Server -> "server"
  | `Set_cookie -> "set-cookie"
  | `Signature -> "signature"
  | `Strict_transport_security -> "strict-transport-security"
  | `TE -> "te"
  | `Topic -> "topic"
  | `Trailer -> "trailer"
  | `Transfer_encoding -> "transfer-encoding"
  | `TTL -> "ttl"
  | `Upgrade -> "upgrade"
  | `Urgency -> "urgency"
  | `User_agent -> "user-agent"
  | `Vary -> "vary"
  | `Via -> "via"
  | `Warning -> "warning"
  | `WWW_authenticate -> "www-authenticate"

let string_of_name = lower_string_of_name

let name_of_string (k : string) : name =
  match String.lowercase_ascii k with
  | "a-im" -> `A_IM
  | "accept" -> `Accept
  | "accept-charset" -> `Accept_charset
  | "accept-datetime" -> `Accept_datetime
  | "accept-encoding" -> `Accept_encoding
  | "accept-language" -> `Accept_language
  | "accept-patch" -> `Accept_patch
  | "accept-post" -> `Accept_post
  | "accept-query" -> `Accept_query
  | "accept-ranges" -> `Accept_ranges
  | "access-control-allow-credentials" -> `Access_control_allow_credentials
  | "access-control-allow-headers" -> `Access_control_allow_headers
  | "access-control-allow-methods" -> `Access_control_allow_methods
  | "access-control-allow-origin" -> `Access_control_allow_origin
  | "access-control-expose-headers" -> `Access_control_expose_headers
  | "access-control-max-age" -> `Access_control_max_age
  | "access-control-request-headers" -> `Access_control_request_headers
  | "access-control-request-method" -> `Access_control_request_method
  | "age" -> `Age
  | "allow" -> `Allow
  | "alpn" -> `ALPN
  | "alt-svc" -> `Alt_svc
  | "alt-used" -> `Alt_used
  | "authorization" -> `Authorization
  | "cache-control" -> `Cache_control
  | "connection" -> `Connection
  | "content-disposition" -> `Content_disposition
  | "content-encoding" -> `Content_encoding
  | "content-language" -> `Content_language
  | "content-length" -> `Content_length
  | "content-location" -> `Content_location
  | "content-range" -> `Content_range
  | "content-type" -> `Content_type
  | "cookie" -> `Cookie
  | "crypto-key" -> `Crypto_key
  | "date" -> `Date
  | "delta-base" -> `Delta_base
  | "digest" -> `Digest
  | "etag" -> `Etag
  | "expect" -> `Expect
  | "expires" -> `Expires
  | "forwarded" -> `Forwarded
  | "from" -> `From
  | "host" -> `Host
  | "if-match" -> `If_match
  | "if-modified-since" -> `If_modified_since
  | "if-none-match" -> `If_none_match
  | "if-range" -> `If_range
  | "if-unmodified-since" -> `If_unmodified_since
  | "im" -> `IM
  | "last-modified" -> `Last_modified
  | "link" -> `Link
  | "location" -> `Location
  | "max-forwards" -> `Max_forwards
  | "origin" -> `Origin
  | "pragma" -> `Pragma
  | "prefer" -> `Prefer
  | "preference-applied" -> `Preference_applied
  | "proxy-authenticate" -> `Proxy_authenticate
  | "proxy-authentication-info" -> `Proxy_authentication_info
  | "proxy-authorization" -> `Proxy_authorization
  | "range" -> `Range
  | "referer" -> `Referer
  | "retry-after" -> `Retry_after
  | "sec-websocket-accept" -> `Sec_websocket_accept
  | "sec-websocket-extensions" -> `Sec_websocket_extensions
  | "sec-websocket-key" -> `Sec_websocket_key
  | "sec-websocket-protocol" -> `Sec_websocket_protocol
  | "sec-websocket-version" -> `Sec_websocket_version
  | "server" -> `Server
  | "set-cookie" -> `Set_cookie
  | "signature" -> `Signature
  | "strict-transport-security" -> `Strict_transport_security
  | "te" -> `TE
  | "topic" -> `Topic
  | "trailer" -> `Trailer
  | "transfer-encoding" -> `Transfer_encoding
  | "ttl" -> `TTL
  | "upgrade" -> `Upgrade
  | "urgency" -> `Urgency
  | "user-agent" -> `User_agent
  | "vary" -> `Vary
  | "via" -> `Via
  | "warning" -> `Warning
  | "www-authenticate" -> `WWW_authenticate
  | s -> `Raw s

type t = name * string

let to_tuple ((n, v) : t) : string * string = (string_of_name n, v)
let of_tuple (n, v) : t = (name_of_string n, v)
