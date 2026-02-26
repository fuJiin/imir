# Imir

Transient dev boxes for AI-assisted coding from any device.

Named after the planet in Adrian Tchaikovsky's *Children of Memory* — a world settled by colonists who had to make do with what they brought and adapt to what they found.

## What it does

Imir spins up Hetzner Cloud VMs pre-configured with your dotfiles, Claude Code, and tmux. Connect from your laptop or phone, pick up where you left off. Destroy the box when you're done — nothing precious lives there.

## Prerequisites

- **Hetzner Cloud account** with an API token ([console.hetzner.cloud](https://console.hetzner.cloud) → project → Security → API tokens)
- **hcloud CLI** (`brew install hcloud`)
- **SSH key** at `~/.ssh/id_rsa` (or configure a different path)

## Getting started

```bash
# 1. Clone the repo
git clone <repo-url> ~/Code/projects/imir
cd ~/Code/projects/imir

# 2. Configure
cp config.env.example config.env
# Edit config.env — at minimum, set HCLOUD_TOKEN

# 3. Add bin/ to your PATH (fish example)
fish_add_path ~/Code/projects/imir/bin

# 4. Create a dev box (~2-3 min)
imir-create myproject

# 5. Connect
imir-connect myproject
```

## Commands

| Command | Description |
|---|---|
| `imir-create <name> [type]` | Create and bootstrap a new dev box. Optional server type (default: `cx22`). |
| `imir-connect <name>` | SSH into a box with agent forwarding and auto-attach to tmux. |
| `imir-list` | Show all running imir-managed dev boxes. |
| `imir-destroy <name>` | Destroy a dev box and clean up SSH known_hosts. |

## What gets installed

The bootstrap provisions a `dev` user with sudo and sets up:

- **Shell**: fish (default shell) with your chezmoi-managed dotfiles
- **Editor**: emacs-nox + Doom Emacs
- **Multiplexer**: tmux
- **Remote access**: mosh (for resilient mobile connections)
- **Node.js**: via fnm (LTS)
- **Claude Code**: latest, globally installed
- **Tools**: git, ripgrep, fd, jq, curl, build-essential

## Usage patterns

### Single box, multiple features (worktrees)

Most of the time, one box is enough. Use git worktrees + tmux windows for parallel work:

```bash
imir-connect work

# on the box:
git clone git@github.com:you/project.git && cd project
git worktree add ../project-auth feature/auth
git worktree add ../project-payments feature/payments

# each in its own tmux window
tmux new-window -n auth -c ../project-auth
tmux new-window -n payments -c ../project-payments
```

### Multiple boxes (isolation)

When you want full isolation — different repos, throwaway experiments, or dedicated resources:

```bash
imir-create frontend
imir-create backend cx32    # bigger box for heavy builds
imir-create experiment

imir-list                   # see all running boxes
imir-destroy experiment     # done with this one
```

### Connecting from your phone

Use [Termius](https://termius.com/) (or any SSH client):

1. Get the IP: `imir-list` from your laptop
2. In Termius: add host with IP, user `dev`, your SSH key
3. Enable SSH agent forwarding in the host settings (for git)
4. Connect — tmux picks up the same session you left on your laptop

### Git authentication

`imir-connect` uses SSH agent forwarding (`-A`), so git operations on the box use your local SSH key. No private keys on the box.

Make sure your key is in the agent:

```bash
ssh-add -l          # check
ssh-add ~/.ssh/id_rsa  # add if needed
```

## Configuration

`config.env` (gitignored — copy from `config.env.example`):

| Variable | Default | Description |
|---|---|---|
| `HCLOUD_TOKEN` | *(required)* | Hetzner Cloud API token |
| `SSH_KEY_PATH` | `~/.ssh/id_rsa` | Path to your SSH private key |
| `CHEZMOI_REPO` | `fuJiin/dotfiles` | GitHub shorthand for your dotfiles |
| `DEFAULT_SERVER_TYPE` | `cx22` | Hetzner server type (2 vCPU, 4GB RAM) |
| `DEFAULT_LOCATION` | `hil1` | Hetzner datacenter (Hillsboro, OR) |
| `DEFAULT_IMAGE` | `ubuntu-24.04` | Base OS image |

### Server types

| Type | vCPU | RAM | Disk | ~Cost/mo |
|---|---|---|---|---|
| `cx22` | 2 | 4 GB | 40 GB | $4.35 |
| `cx32` | 4 | 8 GB | 80 GB | $7.49 |
| `cx42` | 8 | 16 GB | 160 GB | $14.49 |

Boxes are billed hourly. A `cx22` running for a workday costs ~$0.02.

---

## Appendix

### Why Hetzner?

Hillsboro, OR (`hil1`) is ~15-30ms from San Francisco. Comparable latency to AWS us-west-2 at roughly 1/3 the price. The `cx22` at $4.35/mo is hard to beat for a disposable dev box.

### Why tmux (not zellij)?

tmux is the universal multiplexer. Termius has native tmux integration. zellij is nicer in some ways but has no mobile client support. Since the whole point is consistent sessions across laptop and phone, tmux wins.

### Why a `dev` user (not root)?

Claude Code and npm shouldn't run as root. The `dev` user has passwordless sudo for package management but runs tools in userspace. SSH keys are copied from root (Hetzner's default SSH target) during bootstrap.

### Why SSH agent forwarding (not deploy keys)?

Boxes are transient. Putting persistent credentials on a throwaway VM is a liability. Agent forwarding means your keys never leave your laptop — the box just asks your local agent to sign on its behalf. Downside: mosh doesn't support agent forwarding, so git operations need a plain SSH connection.

### Why not Terraform / Docker?

**Terraform**: overkill for single-VM lifecycle. `hcloud` CLI does create/destroy in one command. If this grows to manage networking, firewalls, or multi-VM setups, Terraform starts to make sense.

**Docker**: wrong abstraction. Dev boxes need persistent tmux sessions, SSH access, and full OS tooling. Containers are for isolated processes. Docker *inside* the box (for running services) is fine.

### Future work

- **tmux config via chezmoi**: status bar, mouse support (phone), keybindings, session naming
- **Worktree helper**: fish function to create a worktree + tmux window in one command
- **mosh support**: `imir-connect --mosh` for mobile-resilient connections (no agent forwarding though)
- **Tailscale**: stable DNS names (`mybox.tail1234.ts.net`) instead of IPs, survives VM recreation
- **Additional AI tools**: codex, opencode, or other CLI agents added to bootstrap
- **Snapshot/restore**: save a bootstrapped image to skip the ~2 min setup on new boxes
