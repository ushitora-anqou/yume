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

## Follow-up: where the large-response gap comes from

Additional measurements isolate how much of the 8.5x gap each layer
contributes (same 32MiB body, `-t4 -c8`, single runs after warmup):

| server | body path | throughput |
|---|---|---|
| yume `respond` | cohttp `flow_to_writer`: Buf_read copy + `take` string + `Buf_write.string` (3 user-space copies/byte) | 1.36 GB/s |
| yume `/large-expert` (Expert handler + `Buf_write.schedule_cstruct`) | zero user-space copies, single writev | **5.81 GB/s** |
| raw eio server (`bench/raw_server.ml`, no cohttp at all) | same as above | 6.37 GB/s |
| nginx, 1 worker (sendfile) | kernel zero-copy | 11.81 GB/s |
| nginx, 2 workers (sendfile) | kernel zero-copy | ~11.6–11.9 GB/s |

Findings:

1. **~4.3x of the gap is recoverable within yume today.** The
   bottleneck is cohttp's body pipeline (`Utils.flow_to_writer`
   routes the body through an `Eio.Buf_read` buffer and re-creates
   strings before writing them into the `Buf_write`), not eio and not
   OCaml. Serving large bodies through an Expert handler with
   `Eio.Buf_write.schedule_cstruct` (a Cstruct built once, then
   enqueued without copying) reaches 5.81 GB/s — 91% of the raw-eio
   ceiling. A convenience API around this pattern (e.g.
   `respond_cstruct`) would make the fast path ergonomic.
2. **The remaining ~2x vs nginx is structural.** nginx's sendfile
   moves data page-cache-to-socket inside the kernel; an application
   server holding the body in OCaml strings must cross the kernel
   boundary per writev. Closing it would require mmap-backed bodies +
   sendfile or vmsplice/splice plumbing, which is beyond a web
   framework layer.
3. The single-worker nginx number matches the two-worker one, so the
   wrk client (4 threads) is itself near saturation at ~12 GB/s; the
   nginx ceiling may be even higher.

## Reproducing

```console
$ nix develop -c dune build bench/yume_server.exe bench/raw_server.exe
$ nix shell nixpkgs#wrk nixpkgs#nginx --command bench/run.sh
```

The extra `/large-expert` route and `raw_server.exe` (used in the
follow-up section above) can be measured manually:

```console
$ nix develop -c ./_build/default/bench/yume_server.exe 8080 &
$ wrk -t4 -c8 -d10s http://127.0.0.1:8080/large-expert
$ nix develop -c ./_build/default/bench/raw_server.exe 8082 &
$ wrk -t4 -c8 -d10s http://127.0.0.1:8082/large
```

Tunables: `DURATION` (default `10s`), `SMALL_PARAMS` (default
`4 128`), `LARGE_PARAMS` (default `4 8`), `PORT_YUME`, `PORT_NGINX`.
