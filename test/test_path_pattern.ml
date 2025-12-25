open Yume

let test_parse_path () =
  let open Path_pattern in
  assert (of_string "" = []);
  assert (of_string "/foo/bar/2000" = [ L "foo"; L "bar"; L "2000" ]);
  assert (
    of_string "/foo/:bar/2000"
    = [ L "foo"; P { pattern = ":bar"; suffix = "" }; L "2000" ]);
  assert (of_string "/foo/*" = [ L "foo"; S ]);
  assert (
    of_string "/foo/:bar" = [ L "foo"; P { pattern = ":bar"; suffix = "" } ]);
  assert (
    of_string "/foo/:bar:baz"
    = [ L "foo"; P { pattern = ":bar"; suffix = ":baz" } ]);
  assert (
    of_string "/foo/:bar:baz/hoge"
    = [ L "foo"; P { pattern = ":bar"; suffix = ":baz" }; L "hoge" ]);
  assert (perform ~pat:(of_string "/foo/:bar") "/foo/1" = Some [ (":bar", "1") ]);
  assert (perform ~pat:(of_string "/foo/:bar") "/foo" = None);
  assert (perform ~pat:(of_string "/foo/:bar") "/foo/" = None);
  assert (perform ~pat:(of_string "/foo/*") "/foo/1/2" = Some []);
  assert (perform ~pat:(of_string "/foo/bar") "/foo/bar/" = Some []);
  assert (perform ~pat:(of_string "/foo/bar") "/foo/bar//" = Some []);
  assert (perform ~pat:(of_string "/foo/bar") "/foo//bar//" = Some []);
  assert (
    perform ~pat:(of_string "/foo/:bar:baz") "/foo/1:baz"
    = Some [ (":bar", "1") ]);
  assert (perform ~pat:(of_string "/foo/:bar:baz") "/foo/" = None);
  assert (perform ~pat:(of_string "/foo/:bar:baz") "/foo/:baz" = None);
  ()

let () =
  let open Alcotest in
  run "path_pattern"
    [ ("parse_path", [ test_case "case1" `Quick test_parse_path ]) ]
