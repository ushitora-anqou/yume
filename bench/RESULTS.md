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
| yume `/large-expert` (`Server.respond_cstruct`, i.e. `Buf_write.schedule_cstruct`) | zero user-space copies, single writev | **6.02 GB/s** |
| raw eio server (`bench/raw_server.ml`, no cohttp at all) | same as above | 6.37 GB/s |
| nginx, 1 worker (sendfile) | kernel zero-copy | 11.81 GB/s |
| nginx, 2 workers (sendfile) | kernel zero-copy | ~11.6–11.9 GB/s |

Findings:

1. **~4.3x of the gap is recoverable within yume today.** The
   bottleneck is cohttp's body pipeline (`Utils.flow_to_writer`
   routes the body through an `Eio.Buf_read` buffer and re-creates
   strings before writing them into the `Buf_write`), not eio and not
   OCaml. Serving large bodies through `Server.respond_cstruct`
   (a Cstruct built once, then enqueued without copying) reaches
   ~6 GB/s — ~94% of the raw-eio ceiling.
2. **The remaining ~2x vs nginx is structural.** nginx's sendfile
   moves data page-cache-to-socket inside the kernel; an application
   server holding the body in OCaml strings must cross the kernel
   boundary per writev. Closing it would require mmap-backed bodies +
   sendfile or vmsplice/splice plumbing, which is beyond a web
   framework layer.
3. The single-worker nginx number matches the two-worker one, so the
   wrk client (4 threads) is itself near saturation at ~12 GB/s; the
   nginx ceiling may be even higher.

### Speeding up plain respond (string API)

`Server.respond` (the string API) was also moved onto the single-copy
path: the final `Response`-to-wire conversion (`respond_expert` in
`src/server.ml`) now builds an expert response that copies the string
into a Cstruct once and issues a single writev, instead of the cohttp
pipeline. Measured with `/size/:kb` vs `/size-cs/:kb` on the bench
server (`-t4 -c8`, 8s after warmup; `/size-cs` reuses a cached
Cstruct):

| body size | respond, cohttp pipeline (3 copies) | respond, fast path (1 copy) | respond_cstruct, reused (0 copies) |
|---|---|---|---|
| 1 MiB | 1.25 GB/s | 3.03 GB/s (2.4x) | 6.28 GB/s |
| 4 MiB | 1.18 GB/s | 2.60 GB/s (2.2x) | 7.42 GB/s |
| 16 MiB | 1.02 GB/s | 2.96 GB/s (2.9x) | 6.98 GB/s |
| 32 MiB | 1.36 GB/s | 1.38 GB/s (1.0x) | 6.02 GB/s |

- Plain `respond` gets **2.2–2.9x faster** for bodies up to ~16 MiB;
  at 32 MiB the per-request 32MiB Cstruct allocation itself dominates
  and cancels the win.
- A string API cannot go below one copy per request: OCaml strings
  live on the OCaml heap and cannot back a writev iovec, so the bytes
  must be copied into a Bigarray (which is exactly what
  `Cstruct.of_string` does). Reaching the 6–7 GB/s tier requires
  reusing a pre-built Cstruct, i.e. `respond_cstruct`.

### Speeding up expert-handler streaming

Chunked streaming through `respond_chunked` + `Expert` handlers gets
the same treatment via `Chunked.write_cstruct`: the chunk framing
(`%x\r\n` / `\r\n`) stays buffered while the data itself is enqueued
with `Eio.Buf_write.schedule_cstruct` (which flushes pending buffered
data first, so framing/data ordering is preserved). Measured sending
16MiB as sixteen 1MiB chunks (`/stream` vs `/stream-cs`, reusing one
chunk buffer, `-t4 -c8`, 8s after warmup):

| path | per-chunk copies | throughput |
|---|---|---|
| `/stream` (`Chunked.write`, string) | 1 | 3.15 GB/s |
| `/stream-cs` (`Chunked.write_cstruct`, reused Cstruct) | 0 | **5.95 GB/s (1.9x)** |

So streaming handlers that already hold their data in Cstructs (or
can reuse one) reach the same ~6 GB/s tier as `respond_cstruct`.

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
