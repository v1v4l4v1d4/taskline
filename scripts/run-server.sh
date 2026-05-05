#!/usr/bin/env bash
# scripts/run-server.sh — convenience wrapper to (re)build then run the
# server. Reads .env from the project root by default.
set -euo pipefail

cd "$(dirname "$0")/.."

if [[ ! -x ./dist/taskline-server ]]; then
    echo "[run-server] no binary at dist/taskline-server, building…" >&2
    ./scripts/build.sh
fi

if [[ ! -f .env ]]; then
    echo "[run-server] no .env, copying .env.example" >&2
    cp .env.example .env
fi

exec ./dist/taskline-server
