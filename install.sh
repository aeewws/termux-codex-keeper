#!/usr/bin/env bash
set -Eeuo pipefail

ROOT_DIR="$(CDPATH='' cd -- "$(dirname -- "$0")" && pwd)"
FORCE=0
WITH_BOOT=0
SKIP_CONFIG=0
BIN_DIR="${INSTALL_BIN_DIR:-${PREFIX:-$HOME/.local}/bin}"
CONFIG_DIR="${INSTALL_CONFIG_DIR:-${XDG_CONFIG_HOME:-$HOME/.config}/termux-codex-keeper}"
BOOT_DIR="${INSTALL_BOOT_DIR:-$HOME/.termux/boot}"

usage() {
  cat <<EOF
Usage:
  ./install.sh [options]

Options:
  --bin-dir PATH       Override the install destination for the executable
  --config-dir PATH    Override the install destination for config.conf
  --boot-dir PATH      Override the install destination for the boot script
  --with-boot          Install a termux-boot wrapper script
  --skip-config        Do not install a config file
  --force              Overwrite existing config and boot files
  -h, --help           Show this help text
EOF
}

while [ "$#" -gt 0 ]; do
  case "$1" in
    --bin-dir)
      BIN_DIR="$2"
      shift 2
      ;;
    --config-dir)
      CONFIG_DIR="$2"
      shift 2
      ;;
    --boot-dir)
      BOOT_DIR="$2"
      shift 2
      ;;
    --with-boot)
      WITH_BOOT=1
      shift
      ;;
    --skip-config)
      SKIP_CONFIG=1
      shift
      ;;
    --force)
      FORCE=1
      shift
      ;;
    -h|--help)
      usage
      exit 0
      ;;
    *)
      printf 'Unknown option: %s\n' "$1" >&2
      usage >&2
      exit 1
      ;;
  esac
done

install -d "$BIN_DIR"
install -m 0755 "$ROOT_DIR/bin/termux-codex-keeper" "$BIN_DIR/termux-codex-keeper"
printf 'Installed executable to %s\n' "$BIN_DIR/termux-codex-keeper"

if [ "$SKIP_CONFIG" -ne 1 ]; then
  install -d "$CONFIG_DIR"
  if [ ! -f "$CONFIG_DIR/config.conf" ] || [ "$FORCE" -eq 1 ]; then
    install -m 0644 "$ROOT_DIR/config/termux-codex-keeper.conf.example" "$CONFIG_DIR/config.conf"
    printf 'Installed config to %s\n' "$CONFIG_DIR/config.conf"
  else
    printf 'Kept existing config at %s\n' "$CONFIG_DIR/config.conf"
  fi
fi

if [ "$WITH_BOOT" -eq 1 ]; then
  install -d "$BOOT_DIR"
  if [ ! -f "$BOOT_DIR/termux-codex-keeper" ] || [ "$FORCE" -eq 1 ]; then
    cat >"$BOOT_DIR/termux-codex-keeper" <<EOF
#!/data/data/com.termux/files/usr/bin/bash
set -eu

if command -v termux-wake-lock >/dev/null 2>&1; then
  termux-wake-lock
fi

export TERMUX_CODEX_KEEPER_CONFIG="${CONFIG_DIR}/config.conf"
exec "${BIN_DIR}/termux-codex-keeper" start
EOF
    chmod 0755 "$BOOT_DIR/termux-codex-keeper"
    printf 'Installed termux-boot script to %s\n' "$BOOT_DIR/termux-codex-keeper"
  else
    printf 'Kept existing boot script at %s\n' "$BOOT_DIR/termux-codex-keeper"
  fi
fi
