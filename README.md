# termux-codex-keeper

`termux-codex-keeper` is a Bash-first watchdog for keeping the Codex `app-server` alive on Termux. It can probe a configurable health-check URL or command, restart the target when it becomes unhealthy, and send Termux notifications when recovery happens or fails.

## Highlights

- Bash-only runtime with a single executable entrypoint
- `doctor`, `status`, `check`, `ensure`, `start`, `restart`, `notify`, and `print-config` subcommands
- Health checks via HTTP URL or arbitrary shell command
- Configurable restart command with cooldown and post-restart verification
- Graceful notification fallback when `termux-notification` is not installed
- `termux-boot` integration example for auto-start on device boot
- GitHub Actions workflow for ShellCheck and a repo-local smoke test

## Repository Layout

```text
bin/                        Main executable
config/                     Example configuration
examples/termux-boot/       Boot integration example
tests/                      Smoke test
.github/workflows/          CI for ShellCheck and smoke coverage
install.sh                  Installer for Termux or other Bash environments
```

## Requirements

- Termux with `bash`
- `curl` if you use `HEALTHCHECK_MODE=url`
- `termux-api` if you want device notifications
- `termux-boot` if you want auto-start on boot

Suggested packages:

```bash
pkg update
pkg install bash curl termux-api termux-tools
```

## Install

Clone the repo and install the executable plus a starter config:

```bash
git clone https://github.com/aeewws/termux-codex-keeper.git
cd termux-codex-keeper
./install.sh
```

Useful installer flags:

```bash
./install.sh --with-boot
./install.sh --bin-dir "$HOME/.local/bin" --config-dir "$HOME/.config/termux-codex-keeper"
./install.sh --force
```

The installer copies:

- `bin/termux-codex-keeper` to `${PREFIX:-$HOME/.local}/bin`
- `config/termux-codex-keeper.conf.example` to `${XDG_CONFIG_HOME:-$HOME/.config}/termux-codex-keeper/config.conf`
- An optional `termux-boot` wrapper to `$HOME/.termux/boot/termux-codex-keeper`

## Quick Start

1. Install the repo with `./install.sh`.
2. Edit your config:

```bash
${EDITOR:-nano} "$HOME/.config/termux-codex-keeper/config.conf"
```

3. Validate the environment:

```bash
termux-codex-keeper doctor
```

4. Run a one-shot check and auto-recover if needed:

```bash
termux-codex-keeper ensure
```

5. Run the keeper loop:

```bash
termux-codex-keeper start
```

## Example Configuration

The starter config lives at [`config/termux-codex-keeper.conf.example`](config/termux-codex-keeper.conf.example). Core fields:

```bash
APP_NAME="Codex app-server"
HEALTHCHECK_MODE="url"
HEALTHCHECK_URL="http://127.0.0.1:3000/health"
HEALTHCHECK_COMMAND="curl -fsS http://127.0.0.1:3000/health >/dev/null"
RESTART_COMMAND="pkill -f 'codex app-server' >/dev/null 2>&1 || true; nohup codex app-server >>\"\$HOME/.termux-codex-keeper/app-server.log\" 2>&1 &"
CHECK_INTERVAL=30
FAILURE_THRESHOLD=1
COOLDOWN_SECONDS=20
POST_RESTART_WAIT_SECONDS=5
NOTIFY_ENABLED=1
```

Tips:

- Use `HEALTHCHECK_MODE=url` when the app-server exposes an HTTP health endpoint.
- Use `HEALTHCHECK_MODE=command` when you want a custom shell probe such as `pgrep`, `ss`, or `curl`.
- If `RESTART_COMMAND` is blank, `START_COMMAND` becomes the recovery command.
- State and logs default to `$HOME/.termux-codex-keeper`.

## Commands

- `doctor`: validate dependencies, config, and runtime settings
- `status`: show last check/restart details, keeper PID, and notification capability
- `check`: run a single health check without restarting
- `ensure`: run a health check and restart if the target is unhealthy
- `start`: keep running `ensure` in the foreground every `CHECK_INTERVAL` seconds
- `restart`: run the restart command immediately
- `notify [message]`: send a manual notification or log a fallback message
- `print-config`: print the fully resolved configuration

`TERMUX_CODEX_KEEPER_CONFIG` can point to a custom config file. `KEEPER_MAX_LOOPS` limits `start` to a fixed number of iterations, which is useful for tests.

## termux-boot Integration

`examples/termux-boot/termux-codex-keeper-boot.sh` shows the recommended shape for boot-time startup.

If you installed with `--with-boot`, review the generated script:

```bash
cat "$HOME/.termux/boot/termux-codex-keeper"
```

Manual setup:

```bash
mkdir -p "$HOME/.termux/boot"
cp examples/termux-boot/termux-codex-keeper-boot.sh "$HOME/.termux/boot/termux-codex-keeper"
chmod +x "$HOME/.termux/boot/termux-codex-keeper"
```

The boot script optionally acquires a wake lock and then launches `termux-codex-keeper start`.

## Development

Run the smoke test locally:

```bash
bash tests/smoke.sh
```

Run ShellCheck locally if it is installed:

```bash
shellcheck install.sh bin/termux-codex-keeper examples/termux-boot/termux-codex-keeper-boot.sh tests/smoke.sh
```

The GitHub Actions workflow in [`.github/workflows/shellcheck.yml`](.github/workflows/shellcheck.yml) runs both checks for every push and pull request.

## License

MIT. See [LICENSE](LICENSE).
