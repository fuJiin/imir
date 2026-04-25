# Imir

Disposable dev boxes for AI-assisted coding from any device.

Imir is a thin wrapper around Hetzner Cloud's API: it creates a VM, installs `chezmoi`, applies your dotfiles, and gets out of the way. Connect from your laptop or phone, pick up where you left off, destroy the box when you're done — nothing precious lives there.

Named after the planet in Adrian Tchaikovsky's *Children of Memory* — a world settled by colonists who had to make do with what they brought and adapt to what they found. IYKYK.

## Why

- **Code on the go** — SSH + tmux from a phone (via Termius) with full agent forwarding. Closer to the metal and more customizable than the Claude mobile app.
- **Right-size the machine** — local laptop chokes on ML training or large codebases. Spin up a beefier box for the job, destroy it when done.
- **Consistent environment** — chezmoi dotfiles, same tools, same shell, every time. New box in ~2 minutes (~30s with a baked snapshot).
- **Two profiles, one tool** — point `--dotfiles` at a different repo to spin up an agent-focused box (e.g. arbora-crew) or any other variant.

Take it or leave it. Or fork it and rebuild it with your own AI.

## Getting started

### Prerequisites

- [Hetzner Cloud](https://console.hetzner.cloud) account with an API token
- [hcloud CLI](https://github.com/hetznercloud/cli) (`brew install hcloud`)
- SSH key at `~/.ssh/id_rsa` (or configure a different path)
- A chezmoi-compatible dotfiles repo on GitHub (recommended; see [fuJiin/dotfiles](https://github.com/fuJiin/dotfiles))

### Install

```bash
curl -fsSL https://raw.githubusercontent.com/fuJiin/imir/main/install.sh | bash
```

Installs `imir` to `~/.local/bin` (or `/usr/local/bin`), fish completions, and creates a config at `~/.config/imir/config.env`.

### Configure and use

```bash
# 1. Edit config — set HCLOUD_TOKEN and (optionally) CHEZMOI_REPO
${EDITOR:-vi} ~/.config/imir/config.env

# 2. Create a dev box (~2 min, or ~30s with 'imir bake')
imir create myproject

# Override the dotfiles repo for a single box
imir create crew-run --dotfiles fuJiin/dotfiles-crew

# 3. Connect (drops into tmux)
imir connect myproject
```

## Commands

| Command | Description |
|---|---|
| `imir init` | Create config file at `~/.config/imir/config.env`. |
| `imir create [--dotfiles <owner/repo>] <name> [type]` | Create and bootstrap a new dev box. |
| `imir bake [--force]` | Bake a snapshot for faster box creation. |
| `imir connect <name> [session]` | SSH + tmux session (default: `default`). |
| `imir ssh <name> [cmd...]` | Plain SSH, no tmux. Runs a command if given. |
| `imir tunnel <name> <port>...` | Forward local ports (PORT or LOCAL:REMOTE). |
| `imir ip <name>` | Print a box's IP address. |
| `imir sessions <name>` | List tmux sessions on a box. |
| `imir kill-session <name> <session>` | Kill a tmux session on a box. |
| `imir list` | Show all running dev boxes. |
| `imir rename <old> <new>` | Rename a dev box. |
| `imir destroy <name>` | Destroy a dev box and clean up known_hosts. |
| `imir upgrade` | Upgrade imir to the latest version. |
| `imir uninstall` | Remove imir and all its files. |

## Configuration

`~/.config/imir/config.env` (created by `imir init`):

| Variable | Default | Description |
|---|---|---|
| `HCLOUD_TOKEN` | *(required)* | Hetzner Cloud API token |
| `CHEZMOI_REPO` | *(optional)* | Default chezmoi repo (GitHub shorthand). Override per-box with `--dotfiles`. |
| `SSH_KEY_PATH` | `~/.ssh/id_rsa` | Path to your SSH private key |
| `DEFAULT_SERVER_TYPE` | `cpx21` | Hetzner server type (3 vCPU, 4GB RAM) |
| `DEFAULT_LOCATION` | `hil` | Hetzner datacenter (Hillsboro, OR) |
| `DEFAULT_IMAGE` | `ubuntu-24.04` | Base OS image |
| `BAKE_HOOK` | *(optional)* | Local script to run as `root` during `imir bake` (after system packages) |
| `BAKE_USER_HOOK` | *(optional)* | Local script to run as `dev` during `imir bake` for user-local tools |

### Server types

| Type | vCPU | RAM | Disk | ~Cost/hr |
|---|---|---|---|---|
| `cpx21` | 3 | 4 GB | 80 GB | ~$0.01 |
| `cpx31` | 4 | 8 GB | 160 GB | ~$0.02 |
| `cpx41` | 8 | 16 GB | 240 GB | ~$0.05 |

## What gets bootstrapped

Imir's bootstrap is intentionally minimal. The baked image installs:

`git`, `tmux`, `curl`, `chezmoi` — and creates a `dev` user with passwordless sudo.

Per-box, imir copies SSH keys to the `dev` user, then (if a dotfiles repo is configured) runs `chezmoi init --apply <repo>`. **Everything else** — your shell, editor, language runtimes, AI agents like Claude Code, GitHub CLI — comes from your dotfiles repo. To change tools, edit your dotfiles, not imir.

## Snapshots

Bootstrap is split into two phases:

1. **Bake** (system layer) — apt update, install minimal packages, install chezmoi, create `dev` user. Slow but identical across boxes.
2. **Per-box** (user layer) — SSH keys, then `chezmoi init --apply`. Fast and unique to each box.

Run `imir bake` to snapshot the first phase into a Hetzner image. Subsequent `imir create` calls use that snapshot and skip straight to per-box setup.

Set `BAKE_HOOK` to a local script path to run additional root-level setup during bake. Set `BAKE_USER_HOOK` to run user-level setup as `dev` (e.g. preinstall language runtimes or agent CLIs into `~/.local`). Hook contents are included in staleness detection, so changing either hook triggers a rebuild warning.

The snapshot is tagged with a hash of the bake script and any configured hooks. If you update any of them (e.g. via `imir upgrade`), `create` will warn that the snapshot is stale. Run `imir bake` again to rebuild it.

### Hybrid tool installs

For tools you want everywhere your dotfiles apply *and* baked into snapshots for fast startup:

1. Put the real installer in your chezmoi repo and make it idempotent.
2. Keep shell/config wiring in chezmoi.
3. Set `BAKE_USER_HOOK` to a local wrapper that invokes the same installer during `imir bake`.

One source of truth for laptops and dev boxes; the snapshot just preinstalls the result.

## Further reading

- **[Usage guides](docs/guides.md)** — worktrees, multiple boxes, phone setup, git/GitHub auth
- **[Decisions](docs/decisions.md)** — why Hetzner, why tmux, architectural trade-offs
