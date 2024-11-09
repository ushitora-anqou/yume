let test_get () =
  Eio_main.run @@ fun env ->
  Mirage_crypto_rng_eio.run (module Mirage_crypto_rng.Fortuna) env @@ fun () ->
  [
    "https://test-ev-rsa.ssl.com/";
    "https://test-dv-rsa.ssl.com/";
    "https://test-ev-ecc.ssl.com/";
    "https://test-dv-ecc.ssl.com/";
  ]
  |> List.map (fun url () ->
         Yume.Client.fetch env url |> Result.get_ok |> ignore)
  |> Eio.Fiber.all;

  [
    "https://expired-rsa-dv.ssl.com/";
    "https://expired-rsa-ev.ssl.com/";
    "https://expired-ecc-dv.ssl.com/";
    "https://expired-ecc-ev.ssl.com/";
  ]
  |> List.map (fun url () ->
         Yume.Client.fetch env url |> Result.get_error |> ignore)
  |> Eio.Fiber.all;

  (*
     FIXME: Do OCSP stuff
  ([
     "https://revoked-rsa-dv.ssl.com/";
     "https://revoked-rsa-ev.ssl.com/";
     "https://revoked-ecc-dv.ssl.com/";
     "https://revoked-ecc-ev.ssl.com/";
   ]
  |> List.iter @@ fun url ->
     Yume.Client.fetch env url |> Result.get_error |> ignore);
     *)
  ()

let test_get_with_custom_cert () =
  let ic =
    open_in_bin
      "../../../test/data/SSL.com_Root_Certification_Authority_RSA.pem"
  in
  Fun.protect ~finally:(fun () -> close_in ic) @@ fun () ->
  let cert =
    ic |> In_channel.input_all |> X509.Certificate.decode_pem |> Result.get_ok
  in
  let t, _, _ = Ptime.of_rfc3339 "2016-08-01T21:00:00Z" |> Result.get_ok in
  let authenticator =
    X509.Authenticator.chain_of_trust ~time:(fun () -> Some t) [ cert ]
  in
  Eio_main.run @@ fun env ->
  Mirage_crypto_rng_eio.run (module Mirage_crypto_rng.Fortuna) env @@ fun () ->
  Yume.Client.fetch ~authenticator env "https://expired-rsa-dv.ssl.com/"
  |> Result.get_ok |> ignore

let () =
  let open Alcotest in
  Common.setup_logs ();
  run "http client"
    [
      ("get", [ test_case "case1" `Quick test_get ]);
      ( "get with custom cert",
        [ test_case "case1" `Quick test_get_with_custom_cert ] );
    ]
