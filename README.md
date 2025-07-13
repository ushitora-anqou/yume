# Yume

Yet another Web framework based on Eio, inspired by Dream.
Yume is originally written for [Waq](https://github.com/ushitora-anqou/waq).

## Usage

```ocaml
Eio_main.run @@ fun env ->
let handler =
  let open Yume.Server in
  Router.(use [ get "/" (fun _ _ -> respond "Hello") ]) default_handler
in
let listen =
  Eio.Net.getaddrinfo_stream ~service:"38471" env#net "localhost" |> List.hd
in
Eio.Switch.run @@ fun sw ->
Yume.Server.start_server env ~sw ~listen handler (fun _ -> ())
```

See the tests for details.

## External repository

Yume isn't included in OPAM's official repository (please file an issue if you wish!), but you can use [waq-external-repo](https://github.com/ushitora-anqou/waq-external-repo) to use the latest version of Yume.

## License

MIT.
