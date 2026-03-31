#!/usr/bin/env bash
set -Eeuo pipefail

ROOT_DIR="$(CDPATH='' cd -- "$(dirname -- "$0")/.." && pwd)"
BIN="$ROOT_DIR/bin/termux-codex-keeper"
TMP_DIR="$(mktemp -d)"
STATE_DIR="$TMP_DIR/state"
CONFIG_FILE="$TMP_DIR/config.conf"
RESTART_MARKER="$TMP_DIR/restarted"
HEALTH_MARKER="$TMP_DIR/healthy"

cleanup() {
  rm -rf "$TMP_DIR"
}

trap cleanup EXIT

cat >"$CONFIG_FILE" <<EOF
APP_NAME="Smoke Test"
HEALTHCHECK_MODE="command"
HEALTHCHECK_COMMAND="test -f '$HEALTH_MARKER'"
RESTART_COMMAND="touch '$RESTART_MARKER'; touch '$HEALTH_MARKER'"
CHECK_INTERVAL=1
FAILURE_THRESHOLD=1
COOLDOWN_SECONDS=0
POST_RESTART_WAIT_SECONDS=0
NOTIFY_ENABLED=0
STATE_DIR="$STATE_DIR"
LOG_TO_STDERR=0
EOF

export TERMUX_CODEX_KEEPER_CONFIG="$CONFIG_FILE"

bash "$BIN" help >/dev/null
bash "$BIN" version >/dev/null
bash "$BIN" doctor >/dev/null
bash "$BIN" print-config | grep -q "APP_NAME=Smoke Test"

if bash "$BIN" check >/dev/null 2>&1; then
  printf 'expected the first health check to fail\n' >&2
  exit 1
fi

bash "$BIN" ensure >/dev/null
test -f "$RESTART_MARKER"
test -f "$HEALTH_MARKER"
bash "$BIN" check >/dev/null
bash "$BIN" status | grep -q "Last restart status: recovered"

rm -f "$RESTART_MARKER" "$HEALTH_MARKER"
KEEPER_MAX_LOOPS=1 bash "$BIN" start >/dev/null
test -f "$RESTART_MARKER"

bash "$BIN" notify "smoke notification fallback" >/dev/null

printf 'smoke check passed\n'
