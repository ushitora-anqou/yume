let test_image =
  {|
iVBORw0KGgoAAAANSUhEUgAAADIAAAAyAQAAAAA2RLUcAAAABGdBTUEAALGPC/xhBQAAACBjSFJN
AAB6JgAAgIQAAPoAAACA6AAAdTAAAOpgAAA6mAAAF3CculE8AAAAAmJLR0QAAd2KE6QAAAAHdElN
RQfnAxYCJTrYPC4yAAAADklEQVQY02NgGAWDCQAAAZAAAcWb20kAAAAldEVYdGRhdGU6Y3JlYXRl
ADIwMjMtMDMtMjJUMDI6Mzc6NTgrMDA6MDClQ3CPAAAAJXRFWHRkYXRlOm1vZGlmeQAyMDIzLTAz
LTIyVDAyOjM3OjU4KzAwOjAw1B7IMwAAAABJRU5ErkJggg==|}
  |> String.trim |> String.split_on_char '\n' |> String.concat ""
  |> Base64.decode_exn

let test_image_large =
  {|
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
AAIBAwADAAAAhgAAABIBAwABAAAAAQAAABoBBQABAAAAjAAAABsBBQABAAAAlAAAACgBAwABAAAA
AgAAADEBAgANAAAAnAAAADIBAgAUAAAAqgAAAGmHBAABAAAAvgAAAAAAAAAIAAgACABIAAAAAQAA
AEgAAAABAAAAR0lNUCAyLjEwLjM0AAAyMDIzOjA1OjE1IDE4OjA5OjE0AAEAAaADAAEAAAABAAAA
AAAAAEf4jE8AAAAldEVYdGRhdGU6Y3JlYXRlADIwMjQtMDYtMDJUMDk6MTM6MzArMDA6MDBp4rJK
AAAAJXRFWHRkYXRlOm1vZGlmeQAyMDI0LTA2LTAyVDA5OjEzOjMwKzAwOjAwGL8K9gAAABp0RVh0
ZXhpZjpCaXRzUGVyU2FtcGxlADgsIDgsIDgS7T4nAAAAEXRFWHRleGlmOkNvbG9yU3BhY2UAMQ+b
AkkAAAAhdEVYdGV4aWY6RGF0ZVRpbWUAMjAyMzowNToxNSAxODowOToxNBJwRVYAAAATdEVYdGV4
aWY6RXhpZk9mZnNldAAxOTBMjvPCAAAAFHRFWHRleGlmOkltYWdlTGVuZ3RoADI0MvW9M3QAAAAT
dEVYdGV4aWY6SW1hZ2VXaWR0aAAyNDImwSP5AAAAGnRFWHRleGlmOlNvZnR3YXJlAEdJTVAgMi4x
MC4zNBhmc5oAAAAbdEVYdGljYzpjb3B5cmlnaHQAUHVibGljIERvbWFpbraRMVsAAAAidEVYdGlj
YzpkZXNjcmlwdGlvbgBHSU1QIGJ1aWx0LWluIHNSR0JMZ0ETAAAAFXRFWHRpY2M6bWFudWZhY3R1
cmVyAEdJTVBMnpDKAAAADnRFWHRpY2M6bW9kZWwAc1JHQltgSUMAAAAASUVORK5CYII=|}
  |> String.trim |> String.split_on_char '\n' |> String.concat ""
  |> Base64.decode_exn

let error_handler ~req:_ ~status:_ ~headers:_ ~body:_ = assert false

exception Exit_normally

let test_basics () =
  let expected_get_response = "response test text" in
  let expected_get_json_response = `Assoc [ ("hello", `String "world") ] in

  Eio_main.run @@ fun env ->
  Eio.Time.with_timeout_exn env#clock 3.0 @@ fun () ->
  let handler =
    let open Yume.Server in
    Router.(
      use
        [
          get "/" (fun _ _ -> respond_html expected_get_response);
          get "/json" (fun _ _ -> respond_yojson expected_get_json_response);
          post "/" (fun _ req -> (* echo *) query "msg" req |> respond);
        ])
      default_handler
  in
  let listen =
    Eio.Net.getaddrinfo_stream ~service:"0" env#net "localhost" |> List.hd
  in
  try
    Eio.Switch.run @@ fun sw ->
    Yume.Server.start_server env ~sw ~listen ~error_handler handler
      (fun socket ->
        let listening_port =
          match Eio.Net.listening_addr socket with
          | `Tcp (_, port) -> port
          | _ -> assert false
        in

        let resp =
          Yume.Client.head env ~sw
            (Printf.sprintf "http://localhost:%d/" listening_port)
        in
        assert (Yume.Client.Response.status resp = `OK);

        let resp =
          Yume.Client.get env ~sw
            (Printf.sprintf "http://localhost:%d/" listening_port)
        in
        assert (Yume.Client.Response.status resp = `OK);
        let body = Yume.Client.Response.drain resp in
        assert (body = expected_get_response);

        let resp =
          Yume.Client.get env ~sw
            (Printf.sprintf "http://localhost:%d/json" listening_port)
        in
        assert (Yume.Client.Response.status resp = `OK);
        let body = Yume.Client.Response.drain resp |> Yojson.Safe.from_string in
        assert (body = expected_get_json_response);

        let resp =
          Yume.Client.post env ~sw
            (Printf.sprintf "http://localhost:%d/?msg=hello" listening_port)
        in
        assert (Yume.Client.Response.status resp = `OK);
        let body = Yume.Client.Response.drain resp in
        assert (body = "hello");

        Eio.Switch.fail sw Exit_normally)
  with Exit_normally -> ()

let upload_media env ~filename ~data ~content_type ~url =
  let headers =
    [
      ( `Content_type,
        "multipart/form-data; \
         boundary=---------------------------91791948726096252761377705945" );
    ]
  in
  let body =
    [ {|-----------------------------91791948726096252761377705945--|}; {||} ]
  in
  let body =
    [
      {|-----------------------------91791948726096252761377705945|};
      {|Content-Disposition: form-data; name="file"; filename="|} ^ filename
      ^ {|"|};
      {|Content-Type: |} ^ content_type;
      {||};
      data;
    ]
    @ body
  in
  assert (List.length body <> 2);
  let body = String.concat "\r\n" body in
  Yume.Client.fetch_exn env ~headers ~meth:`POST ~body url

let test_formdata_image image_data () =
  Eio_main.run @@ fun env ->
  Eio.Time.with_timeout_exn env#clock 3.0 @@ fun () ->
  let handler =
    let open Yume.Server in
    Router.(
      use
        [
          post "/" (fun _ req ->
              let data = formdata_exn "file" req in
              respond data.content);
        ])
      default_handler
  in
  let listen =
    Eio.Net.getaddrinfo_stream ~service:"0" env#net "localhost" |> List.hd
  in
  try
    Eio.Switch.run @@ fun sw ->
    Yume.Server.start_server env ~sw ~listen ~error_handler handler
      (fun socket ->
        let listening_port =
          match Eio.Net.listening_addr socket with
          | `Tcp (_, port) -> port
          | _ -> assert false
        in

        let resp =
          upload_media env ~filename:"test.png" ~data:image_data
            ~content_type:"image/png"
            ~url:(Printf.sprintf "http://localhost:%d/" listening_port)
        in
        assert (resp = image_data);

        Eio.Switch.fail sw Exit_normally)
  with Exit_normally -> ()

let () =
  let open Alcotest in
  Common.setup_logs ();
  run "http server"
    [
      ("basics", [ test_case "case1" `Quick test_basics ]);
      ( "formdata",
        [
          test_case "small image" `Quick (test_formdata_image test_image);
          test_case "large image" `Quick (test_formdata_image test_image_large);
        ] );
    ]
