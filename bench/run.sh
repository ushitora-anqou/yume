#!/usr/bin/env bash
# Benchmark Yume against nginx on two scenarios:
#
#   /small : 5-byte response       -> requests/second
#   /large : 32MiB response        -> throughput (bytes/second)
#
# Usage (wrk and nginx must be on PATH):
#
#   nix develop -c dune build bench/yume_server.exe
#   nix shell nixpkgs#wrk nixpkgs#nginx --command bench/run.sh
#
# Tunables via environment variables: DURATION (default 10s),
# PORT_YUME (8080), PORT_NGINX (8081).
set -euo pipefail
cd "$(dirname "$0")"

PORT_YUME=${PORT_YUME:-8080}
PORT_NGINX=${PORT_NGINX:-8081}
DURATION=${DURATION:-10s}
SMALL_PARAMS=${SMALL_PARAMS:-4 128}   # threads connections
LARGE_PARAMS=${LARGE_PARAMS:-4 8}     # threads connections
RUN=$(pwd)/.run
STATIC=$RUN/static
SERVER=$(pwd)/../_build/default/bench/yume_server.exe

[ -x "$SERVER" ] || {
  echo "error: $SERVER not found; run: nix develop -c dune build bench/yume_server.exe" >&2
  exit 1
}
command -v wrk >/dev/null || { echo "error: wrk not found" >&2; exit 1; }
command -v nginx >/dev/null || { echo "error: nginx not found" >&2; exit 1; }

mkdir -p "$STATIC"
printf 'hello' > "$STATIC/small"
head -c $((32 * 1024 * 1024)) /dev/zero | tr '\0' 'A' > "$STATIC/large"

YUME_PID=
NGINX_PID=
cleanup() {
  [ -n "$YUME_PID" ] && kill "$YUME_PID" 2>/dev/null || true
  if [ -n "$NGINX_PID" ]; then
    kill "$NGINX_PID" 2>/dev/null || true
  fi
}
trap cleanup EXIT

wait_port() {
  local port=$1
  for _ in $(seq 1 100); do
    if (exec 3<>"/dev/tcp/127.0.0.1/$port") 2>/dev/null; then
      exec 3>&- 3<&- 2>/dev/null || true
      return 0
    fi
    sleep 0.1
  done
  echo "error: timeout waiting for port $port" >&2
  exit 1
}

# measure <label> <url> <threads> <conns>
# Prints "<requests/sec> <bytes/sec>" on stdout; wrk output on stderr.
measure() {
  local label=$1 url=$2 threads=$3 conns=$4 out reqs bytes
  echo "--- $label ($url, t$threads c$conns, $DURATION)" >&2
  out=$(wrk -t"$threads" -c"$conns" -d"$DURATION" "$url" 2>/dev/null)
  echo "$out" | sed 's/^/    /' >&2
  reqs=$(echo "$out" | awk '/Requests\/sec/ {print $2}')
  bytes=$(echo "$out" | awk '/Transfer\/sec/ {print $2}' | awk '{
      s = $0
      n = length(s)
      u = substr(s, n - 1, 2)
      v = substr(s, 1, n - 2) + 0
      if (u == "GB") printf "%.0f", v * 1073741824
      else if (u == "MB") printf "%.0f", v * 1048576
      else if (u == "KB") printf "%.0f", v * 1024
      else printf "%.0f", v
    }')
  echo "$reqs $bytes"
}

# run_suite <label> <base-url> -> prints "<small reqs> <small bytes> <large reqs> <large bytes>"
run_suite() {
  local label=$1 base=$2 out1 out2
  # warmup
  wrk -t$(echo $SMALL_PARAMS | cut -d' ' -f1) -c$(echo $SMALL_PARAMS | cut -d' ' -f2) -d2s "$base/small" >/dev/null 2>&1 || true
  out1=$(measure "$label small" "$base/small" $(echo $SMALL_PARAMS))
  wrk -t$(echo $LARGE_PARAMS | cut -d' ' -f1) -c$(echo $LARGE_PARAMS | cut -d' ' -f2) -d2s "$base/large" >/dev/null 2>&1 || true
  out2=$(measure "$label large" "$base/large" $(echo $LARGE_PARAMS))
  echo "$out1 $out2"
}

# yume-only reference: the default respond path (chunked transfer encoding)
measure_yume_chunked() {
  local base=$1 out
  wrk -t$(echo $SMALL_PARAMS | cut -d' ' -f1) -c$(echo $SMALL_PARAMS | cut -d' ' -f2) -d2s "$base/small-chunked" >/dev/null 2>&1 || true
  out=$(measure "yume small-chunked" "$base/small-chunked" $(echo $SMALL_PARAMS))
  echo "$out"
}

echo "== building nginx config =="
cat > "$RUN/nginx.conf" <<EOF
worker_processes 2;
error_log /dev/null crit;
pid $RUN/nginx.pid;
events { worker_connections 4096; }
http {
  access_log off;
  sendfile on;
  tcp_nopush on;
  server {
    listen 127.0.0.1:$PORT_NGINX;
    location = /small { alias $STATIC/small; }
    location = /large { alias $STATIC/large; }
  }
}
EOF

echo "== starting yume on :$PORT_YUME =="
"$SERVER" "$PORT_YUME" &
YUME_PID=$!
wait_port "$PORT_YUME"
YUME_RESULT=$(run_suite yume "http://127.0.0.1:$PORT_YUME")
YUME_CHUNKED_RESULT=$(measure_yume_chunked "http://127.0.0.1:$PORT_YUME")
echo "$YUME_RESULT $YUME_CHUNKED_RESULT"

kill "$YUME_PID" && wait "$YUME_PID" 2>/dev/null || true
YUME_PID=

echo "== starting nginx on :$PORT_NGINX =="
nginx -c "$RUN/nginx.conf" -p "$RUN"
NGINX_PID=$(cat "$RUN/nginx.pid")
wait_port "$PORT_NGINX"
NGINX_RESULT=$(run_suite nginx "http://127.0.0.1:$PORT_NGINX")
echo "$NGINX_RESULT"

kill "$NGINX_PID" 2>/dev/null || true
NGINX_PID=

YUME_SMALL_REQS=$(echo "$YUME_RESULT" | cut -d' ' -f1)
YUME_SMALL_BYTES=$(echo "$YUME_RESULT" | cut -d' ' -f2)
YUME_LARGE_REQS=$(echo "$YUME_RESULT" | cut -d' ' -f3)
YUME_LARGE_BYTES=$(echo "$YUME_RESULT" | cut -d' ' -f4)
NGINX_SMALL_REQS=$(echo "$NGINX_RESULT" | cut -d' ' -f1)
NGINX_SMALL_BYTES=$(echo "$NGINX_RESULT" | cut -d' ' -f2)
NGINX_LARGE_REQS=$(echo "$NGINX_RESULT" | cut -d' ' -f3)
NGINX_LARGE_BYTES=$(echo "$NGINX_RESULT" | cut -d' ' -f4)

YUME_CHUNKED_REQS=$(echo "$YUME_CHUNKED_RESULT" | cut -d' ' -f1)

echo
echo "===================== Summary (duration $DURATION per run) ====================="
printf "%-28s %14s %14s %14s\n" "scenario" "yume" "nginx" "slower by"
awk -v yr="$YUME_SMALL_REQS" -v nr="$NGINX_SMALL_REQS" \
    -v yb="$YUME_LARGE_BYTES" -v nb="$NGINX_LARGE_BYTES" 'BEGIN {
  printf "%-28s %14.2f %14.2f %13.2fx\n", "/small  requests/sec", yr, nr, nr / yr
  printf "%-28s %14.2f %14.2f %13.2fx\n", "/large  MiB/sec", yb / 1048576, nb / 1048576, nb / yb
}'
printf "%-28s %14.2f\n" \
  "/small-chunked req/s (ref)" "$YUME_CHUNKED_REQS"

printf "%s\n%s\n%s %s %s %s\n%s %s %s %s\n" \
  "$YUME_SMALL_REQS" "$NGINX_SMALL_REQS" "$YUME_LARGE_REQS" "$NGINX_LARGE_REQS" \
  "$YUME_SMALL_BYTES" "$NGINX_SMALL_BYTES" "$YUME_LARGE_BYTES" "$NGINX_LARGE_BYTES" \
  > "$RUN/summary.txt"
