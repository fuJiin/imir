# Imir

Disposable dev boxes for AI-assisted coding from any device.

Imir spins up Hetzner Cloud VMs pre-configured with your dotfiles, Claude Code, and tmux. Connect from your laptop or phone, pick up where you left off. Destroy the box when you're done — nothing precious lives there.

Named after the planet in Adrian Tchaikovsky's *Children of Memory* — a world settled by colonists who had to make do with what they brought and adapt to what they found. IYKYK.

## Why

This is an intentionally opinionated setup. It solves specific problems I kept running into:

- **Code on the go** — SSH + tmux from a phone (via Termius) with full agent forwarding. Closer to the metal and more customizable than the Claude mobile app.
- **Right-size the machine** — local laptop chokes on ML training or large codebases. Spin up a beefier box for the job, destroy it when done.
- **Consistent environment** — chezmoi dotfiles, same tools, same shell, every time. New box in ~2 minutes.

Take it or leave it. Or fork it and rebuild it with your own AI.

## Getting started

### Prerequisites

- [Hetzner Cloud](https://console.hetzner.cloud) account with an API token
- [hcloud CLI](https://github.com/hetznercloud/cli) (`brew install hcloud`)
- SSH key at `~/.ssh/id_rsa` (or configure a different path)
- [chezmoi](https://www.chezmoi.io/) dotfiles repo on GitHub (optional, but this is how your dev environment gets configured)

### Install

```bash
curl -fsSL https://raw.githubusercontent.com/fuJiin/imir/main/install.sh | bash
```

Installs `imir` to `~/.local/bin` (or `/usr/local/bin`), fish completions, and creates a config at `~/.config/imir/config.env`.

### Configure and use

```bash
# 1. Edit config — set HCLOUD_TOKEN and CHEZMOI_REPO at minimum
${EDITOR:-vi} ~/.config/imir/config.env

# 2. Create a dev box (~2-3 min)
imir create myproject

# 3. Connect (drops into tmux)
imir connect myproject
```

## Commands

| Command | Description |
|---|---|
| `imir init` | Create config file at `~/.config/imir/config.env`. |
| `imir create <name> [type]` | Create and bootstrap a new dev box. |
| `imir connect <name> [session]` | SSH + tmux session (default: `default`). |
| `imir ssh <name> [cmd...]` | Plain SSH, no tmux. Runs a command if given. |
| `imir ip <name>` | Print a box's IP address. |
| `imir sessions <name>` | List tmux sessions on a box. |
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
| `CHEZMOI_REPO` | *(optional)* | GitHub shorthand for your chezmoi dotfiles (e.g. `youruser/dotfiles`) |
| `SSH_KEY_PATH` | `~/.ssh/id_rsa` | Path to your SSH private key |
| `DEFAULT_SERVER_TYPE` | `cpx21` | Hetzner server type (3 vCPU, 4GB RAM) |
| `DEFAULT_LOCATION` | `hil` | Hetzner datacenter (Hillsboro, OR) |
| `DEFAULT_IMAGE` | `ubuntu-24.04` | Base OS image |

### Server types

| Type | vCPU | RAM | Disk | ~Cost/hr |
|---|---|---|---|---|
| `cpx21` | 3 | 4 GB | 80 GB | ~$0.01 |
| `cpx31` | 4 | 8 GB | 160 GB | ~$0.02 |
| `cpx41` | 8 | 16 GB | 240 GB | ~$0.05 |

## What gets bootstrapped

The `create` command provisions a `dev` user with sudo and installs:

fish, emacs-nox + Doom Emacs, tmux, Claude Code, GitHub CLI, git, ripgrep, fd, jq, curl, build-essential — then applies your dotfiles via [chezmoi](https://www.chezmoi.io/). Your `CHEZMOI_REPO` should be a GitHub repo that `chezmoi init --apply` can consume (see [fuJiin/dotfiles](https://github.com/fuJiin/dotfiles) for an example).

## Further reading

- **[Usage guides](docs/guides.md)** — worktrees, multiple boxes, phone setup, git/GitHub auth
- **[Decisions](docs/decisions.md)** — why Hetzner, why tmux, architectural trade-offs
