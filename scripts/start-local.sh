#!/usr/bin/env bash
# scripts/start-local.sh — build the server and (re)start it in the background.
#
# Behaviour:
#   1. Seeds .env from .env.example on first run if .env is missing.
#   2. Builds release artifacts via scripts/build.sh (skip with SKIP_BUILD=1).
#   3. Ensures .log/ exists.
#   4. If the configured port is held by a LISTEN-ing process, kills *only*
#      that process (TERM, then KILL after a short wait). Other processes
#      with the same binary name are left alone.
#   5. Launches ./dist/taskline-server with nohup, redirects stdout+stderr
#      to .log/server.log, writes the PID to .log/server.pid.
#
# Knobs:
#   PORT             — port to bind / check (default 8787). Exported to the
#                      server as TASKLINE_LISTEN=":$PORT" if TASKLINE_LISTEN
#                      is not already set, so port-in-use detection and the
#                      actual listen socket stay in sync.
#   TASKLINE_LISTEN  — full listen addr (e.g. "127.0.0.1:8787"); if set,
#                      takes precedence over PORT for the server, and PORT
#                      is parsed from it for the kill check.
#   SKIP_BUILD       — if set to a non-empty value, skip ./scripts/build.sh
#                      and require ./dist/taskline-server to already exist.
#                      Useful for fast iteration when only restarting after
#                      a Go-only edit and you ran `go build` yourself.
set -euo pipefail

cd "$(dirname "$0")/.."

# Resolve port. Prefer parsing TASKLINE_LISTEN if the user set it, so the
# port-occupancy check matches the address the server will actually bind.
if [[ -n "${TASKLINE_LISTEN:-}" ]]; then
    PORT="${TASKLINE_LISTEN##*:}"
else
    PORT="${PORT:-8787}"
    export TASKLINE_LISTEN=":$PORT"
fi

if ! [[ "$PORT" =~ ^[0-9]+$ ]] || (( PORT < 1 || PORT > 65535 )); then
    echo "[start-local] invalid port: '$PORT'" >&2
    exit 2
fi

# Warn (don't fail) if lsof is missing — without it we can't detect / kill
# a stale listener and the server will hit "address already in use".
if ! command -v lsof >/dev/null 2>&1; then
    echo "[start-local] warning: lsof not found — cannot free port $PORT if held" >&2
fi

# Seed .env from .env.example on first run, matching the old run-server.sh.
if [[ ! -f .env && -f .env.example ]]; then
    echo "[start-local] no .env, copying .env.example" >&2
    cp .env.example .env
fi

if [[ -n "${SKIP_BUILD:-}" ]]; then
    if [[ ! -x ./dist/taskline-server ]]; then
        echo "[start-local] SKIP_BUILD set but ./dist/taskline-server is missing" >&2
        exit 2
    fi
    echo "[start-local] SKIP_BUILD=1 — using existing ./dist/taskline-server" >&2
else
    echo "[start-local] building…" >&2
    ./scripts/build.sh
fi

mkdir -p .log

LOG_FILE=".log/server.log"
PID_FILE=".log/server.pid"

# Find the PID that is currently listening on $PORT. lsof's -sTCP:LISTEN
# filter ensures we don't kill a *client* connected to the port (which
# would otherwise also match `lsof -ti :$PORT`). -t prints PIDs only.
listen_pid() {
    if command -v lsof >/dev/null 2>&1; then
        lsof -ti ":$PORT" -sTCP:LISTEN 2>/dev/null || true
    fi
}

OLD_PIDS="$(listen_pid)"
if [[ -n "$OLD_PIDS" ]]; then
    echo "[start-local] port $PORT is in use by pid(s): $OLD_PIDS — killing" >&2
    # SIGTERM first.
    # shellcheck disable=SC2086
    kill $OLD_PIDS 2>/dev/null || true
    # Wait up to ~5s for graceful exit, then SIGKILL anything still listening.
    for _ in 1 2 3 4 5 6 7 8 9 10; do
        sleep 0.5
        [[ -z "$(listen_pid)" ]] && break
    done
    REMAINING="$(listen_pid)"
    if [[ -n "$REMAINING" ]]; then
        echo "[start-local] pid(s) $REMAINING still listening — SIGKILL" >&2
        # shellcheck disable=SC2086
        kill -9 $REMAINING 2>/dev/null || true
        sleep 0.2
    fi
fi

# Truncate log on each start so it doesn't grow unbounded across restarts.
: > "$LOG_FILE"

# Launch detached.
#
# We deliberately use plain `nohup … &` (NOT `setsid nohup … &`). When you
# run `setsid cmd &` from a non-interactive shell, setsid forks a grandchild
# and exits almost immediately — so `$!` would capture setsid's short-lived
# PID, not the daemon's, and the PID file would point at a dead process.
# `nohup` plus `disown` already makes the server survive this shell exiting.
nohup ./dist/taskline-server >"$LOG_FILE" 2>&1 < /dev/null &
SERVER_PID=$!

# Disown so this shell exiting doesn't kill the server.
disown "$SERVER_PID" 2>/dev/null || true

# Quick liveness check: if the server died immediately (e.g. port still
# bound, bad config), `kill -0` will fail and we surface the log tail
# instead of writing a stale PID file.
sleep 0.3
if ! kill -0 "$SERVER_PID" 2>/dev/null; then
    echo "[start-local] server (pid $SERVER_PID) exited immediately — see $LOG_FILE:" >&2
    tail -n 20 "$LOG_FILE" >&2 || true
    exit 1
fi

echo "$SERVER_PID" > "$PID_FILE"

echo "started: pid=$SERVER_PID port=$PORT log=$LOG_FILE"
