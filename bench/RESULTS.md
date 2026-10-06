# Yume vs nginx benchmark results

- Date: 2026-10-06
- Yume: `75af776` (OCaml 5.5.0, cohttp / cohttp-eio 6.3.0, eio 1.6)
- Server compared against: nginx 1.30.5 (2 workers, sendfile on, tcp_nopush on)
- Load generator: wrk over loopback (127.0.0.1)
- Machine: Linux 6.18.54, 8 cores, 7 GiB RAM

## Methodology

`bench/run.sh` starts each server in turn and measures with wrk
(2 s warmup, then 10 s measurement per scenario; two full runs on the
same day):

| scenario | wrk parameters | response |
|---|---|---|
| `/small` | `-t4 -c128` | 5-byte body, explicit Content-Length |
| `/large` | `-t4 -c8` | 32 MiB body, explicit Content-Length |
| `/small-chunked` (yume only, reference) | `-t4 -c128` | 5-byte body via the default `respond` path (chunked transfer encoding) |

The nginx counterpart serves static files of the same bytes with the
same URLs, which is its optimal path (sendfile). The yume counterpart
(`bench/yume_server.ml`) pre-allocates the large body once and serves
the same string on every request; `Cohttp_eio.Body.of_string` wraps it
without copying, so per-request user-space allocation is not a factor.

## Results

### Small requests (requests/sec)

| run | yume | nginx | yume is slower by |
|---|---|---|---|
| 1 | 69,222 | 78,066 | 1.13x |
| 2 | 67,765 | 80,239 | 1.18x |
| **mean** | **68,493** | **79,152** | **1.16x** |

Reference: the default chunked `respond` path scored 68,447 / 66,500
(mean 67,474) req/s — within ~1.5% of the explicit Content-Length
variant, so chunked framing is not a significant cost at this size.

### Large response throughput (MiB/sec)

| run | yume | nginx | yume is slower by |
|---|---|---|---|
| 1 | 1,382 | 11,889 | 8.60x |
| 2 | 1,393 | 11,612 | 8.34x |
| **mean** | **1,388** | **11,750** | **8.47x** |

(Per-run request counts: yume 43.0 / 43.4 req/s; nginx 371.5 / 363.0
req/s for the 32 MiB body.)

## Interpretation

- **Small requests: yume is within ~16% of nginx.** At roughly
  68k req/s on a single process, the framework adds little overhead
  for typical API-sized responses; nginx's edge here is its highly
  tuned event loop, written in C.
- **Large responses: yume is ~8.5x slower.** nginx serves static
  files through `sendfile`, which copies data from the page cache to
  the socket inside the kernel. yume writes every byte through
  user-space (cohttp reads the body source into socket writes), so it
  pays a full copy per byte plus the writev call path. This is the
  expected cost of a userspace application server and not specific to
  yume; applications that need to push multi-GiB/s static content
  should front yume with a reverse proxy, as is common practice.

## Reproducing

```console
$ nix develop -c dune build bench/yume_server.exe
$ nix shell nixpkgs#wrk nixpkgs#nginx --command bench/run.sh
```

Tunables: `DURATION` (default `10s`), `SMALL_PARAMS` (default
`4 128`), `LARGE_PARAMS` (default `4 8`), `PORT_YUME`, `PORT_NGINX`.
