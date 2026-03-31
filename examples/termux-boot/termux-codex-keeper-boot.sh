#!/data/data/com.termux/files/usr/bin/bash
set -eu

KEEPER_BIN="${KEEPER_BIN:-${PREFIX:-/data/data/com.termux/files/usr}/bin/termux-codex-keeper}"
CONFIG_FILE="${TERMUX_CODEX_KEEPER_CONFIG:-$HOME/.config/termux-codex-keeper/config.conf}"
STATE_DIR="${TERMUX_CODEX_KEEPER_STATE_DIR:-$HOME/.termux-codex-keeper}"

mkdir -p "$STATE_DIR"

if command -v termux-wake-lock >/dev/null 2>&1; then
  termux-wake-lock
fi

export TERMUX_CODEX_KEEPER_CONFIG="$CONFIG_FILE"
exec "$KEEPER_BIN" start >>"$STATE_DIR/boot.log" 2>&1
