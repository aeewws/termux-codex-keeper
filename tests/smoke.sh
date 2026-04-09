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

BROKEN_CONFIG="$TMP_DIR/broken.conf"
cat >"$BROKEN_CONFIG" <<EOF
APP_NAME="Broken Config"
HEALTHCHECK_MODE="command"
HEALTHCHECK_COMMAND="printf 'healthy\n'"
CHECK_INTERVAL="abc"
STATE_DIR="$STATE_DIR"
LOG_TO_STDERR=0
EOF
TERMUX_CODEX_KEEPER_CONFIG="$BROKEN_CONFIG" bash "$BIN" doctor >"$TMP_DIR/doctor-broken.out" 2>&1 || true
grep -q "FAIL: One or more integer settings are invalid." "$TMP_DIR/doctor-broken.out"
grep -q "Config file: $BROKEN_CONFIG" "$TMP_DIR/doctor-broken.out"

SYNTAX_CONFIG="$TMP_DIR/syntax.conf"
cat >"$SYNTAX_CONFIG" <<'EOF'
APP_NAME="unterminated
EOF
TERMUX_CODEX_KEEPER_CONFIG="$SYNTAX_CONFIG" bash "$BIN" doctor >"$TMP_DIR/doctor-syntax.out" 2>&1 || true
grep -q "Failed to parse config file" "$TMP_DIR/doctor-syntax.out"

BROKEN_STATE_DIR="$TMP_DIR/broken-state"
mkdir -p "$BROKEN_STATE_DIR"
BROKEN_STATE_CONFIG="$TMP_DIR/broken-state.conf"
cat >"$BROKEN_STATE_CONFIG" <<EOF
APP_NAME="Broken State"
HEALTHCHECK_MODE="command"
HEALTHCHECK_COMMAND="printf 'healthy\n'"
CHECK_INTERVAL=1
FAILURE_THRESHOLD=1
COOLDOWN_SECONDS=0
POST_RESTART_WAIT_SECONDS=0
NOTIFY_ENABLED=0
STATE_DIR="$BROKEN_STATE_DIR"
LOG_TO_STDERR=0
EOF
printf 'LAST_CHECK_STATUS="broken\n' >"$BROKEN_STATE_DIR/state.env"
TERMUX_CODEX_KEEPER_CONFIG="$BROKEN_STATE_CONFIG" bash "$BIN" status >"$TMP_DIR/status-broken-state.out" 2>&1
grep -q "State load error:" "$TMP_DIR/status-broken-state.out"

printf 'smoke check passed\n'
