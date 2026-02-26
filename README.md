# Imir

Transient dev boxes for AI-assisted coding from any device.

Named after the planet in Adrian Tchaikovsky's *Children of Memory* — a world settled by colonists who had to make do with what they brought and adapt to what they found. IYKYK.

## What it does

Imir spins up Hetzner Cloud VMs pre-configured with your dotfiles, Claude Code, and tmux. Connect from your laptop or phone, pick up where you left off. Destroy the box when you're done — nothing precious lives there.

## Prerequisites

- **Hetzner Cloud account** with an API token ([console.hetzner.cloud](https://console.hetzner.cloud) → project → Security → API tokens)
- **hcloud CLI** (`brew install hcloud`)
- **SSH key** at `~/.ssh/id_rsa` (or configure a different path)

## Getting started

### Install

```bash
curl -fsSL https://raw.githubusercontent.com/fuJiin/imir/main/install.sh | bash
```

This installs `imir` to `~/.local/bin` (or `/usr/local/bin`), fish completions, and creates a config file at `~/.config/imir/config.env`.

<details>
<summary>Alternative: clone the repo</summary>

```bash
git clone https://github.com/fuJiin/imir.git ~/Code/projects/imir
fish_add_path ~/Code/projects/imir/bin
imir init
```

</details>

### Configure and use

```bash
# 1. Edit config — at minimum, set HCLOUD_TOKEN
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
| `imir uninstall` | Remove imir, completions, and config from your system. |
| `imir create <name> [type]` | Create and bootstrap a new dev box. Optional server type (default: `cpx21`). |
| `imir connect <name> [session]` | SSH into a box with agent forwarding and attach to a tmux session (default: `default`). |
| `imir ssh <name> [cmd...]` | Plain SSH (no tmux). Runs a command if given, otherwise opens a shell. |
| `imir ip <name>` | Print a box's IP address. |
| `imir sessions <name>` | List tmux sessions on a box. |
| `imir list` | Show all running imir-managed dev boxes. |
| `imir rename <old> <new>` | Rename a dev box. |
| `imir destroy <name>` | Destroy a dev box and clean up SSH known_hosts. |
| `imir help` | Show usage information. |

## What gets installed

The bootstrap provisions a `dev` user with sudo and sets up:

- **Shell**: fish (default shell) with your chezmoi-managed dotfiles
- **Editor**: emacs-nox + Doom Emacs
- **Multiplexer**: tmux
- **Claude Code**: latest, via native installer
- **GitHub CLI**: gh (for creating PRs, issues, etc.)
- **Tools**: git, ripgrep, fd, jq, curl, build-essential

## Usage patterns

### Single box, multiple features (worktrees)

Most of the time, one box is enough. Use named tmux sessions + git worktrees for parallel work:

```bash
# start a session for each feature
imir connect work auth
# on the box:
git clone git@github.com:you/project.git ~/auth && cd ~/auth
git checkout -b feature/auth

# from your laptop, start another session
imir connect work payments
# on the box:
git clone git@github.com:you/project.git ~/payments && cd ~/payments
git checkout -b feature/payments

# list sessions from a plain SSH connection
imir connect work
tmux list-sessions
```

### Multiple boxes (isolation)

When you want full isolation — different repos, throwaway experiments, or dedicated resources:

```bash
imir create frontend
imir create backend cx32    # bigger box for heavy builds
imir create experiment

imir list                   # see all running boxes
imir destroy experiment     # done with this one
```

### Connecting from your phone

Each device gets its own SSH key. Imir passes all `imir-*` SSH keys from Hetzner to new boxes automatically.

**One-time setup:**

1. In Termius: **Keychain** → **+** → **Key** → **Generate** a new key
2. Copy the **public** key (just the `ssh-ed25519 AAAA...` line, skip any comments)
3. From your laptop, upload it to Hetzner:
   ```bash
   # Save the public key to a file, then:
   hcloud ssh-key create --name imir-phone --public-key-from-file phone.pub
   ```
4. New boxes will include the key automatically. For existing boxes, add it manually:
   ```bash
   # From laptop:
   imir connect myproject
   # On the box:
   echo "ssh-ed25519 AAAA..." >> ~/.ssh/authorized_keys
   ```

**Per-box setup in Termius:**

1. Get the IP: `imir ip myproject` from your laptop
2. In Termius: **Hosts** → **+** → set **Hostname** to the IP, **Username** to `dev`
3. Under **Key**, select the key you generated above (no password)
4. Enable **SSH agent forwarding** in host settings (for git)
5. Connect — run `tmux attach` (or `tmux new-session -As main`) to pick up a session from your laptop

### Git authentication

`imir connect` uses SSH agent forwarding (`-A`), so git operations on the box use your local SSH key. No private keys on the box.

Make sure your key is in the agent:

```bash
ssh-add -l          # check
ssh-add ~/.ssh/id_rsa  # add if needed
```

### GitHub CLI (creating PRs)

SSH agent forwarding handles `git push`, but `gh` needs its own auth to talk to the GitHub API.

**Per-box setup** (run once after connecting):

```bash
gh auth login
```

Choose **GitHub.com** → **SSH** → select your forwarded key → **Login with a web browser** (or paste a token).

**Tips:**
- Pick **SSH** as the git protocol — this uses your forwarded key for pushes, so `gh pr create` just works.
- If browser auth isn't practical (e.g. from a phone), create a [personal access token](https://github.com/settings/tokens) with `repo` scope and paste it when prompted.
- Auth state lives in `~/.config/gh/` on the box. It's gone when the box is destroyed — no persistent credentials on throwaway VMs.

**Adding your SSH key to GitHub** (one-time, per device):

If you generated a new SSH key for a device (e.g. phone), GitHub also needs to know about it for `git push` to work without agent forwarding:

1. Copy the public key:
   ```bash
   cat ~/.ssh/id_ed25519.pub
   ```
2. Add it at [github.com/settings/ssh/new](https://github.com/settings/ssh/new) (or `gh ssh-key add ~/.ssh/id_ed25519.pub --title "imir-phone"` from an already-authed session).

## Configuration

`~/.config/imir/config.env` (created by `imir init`):

| Variable | Default | Description |
|---|---|---|
| `HCLOUD_TOKEN` | *(required)* | Hetzner Cloud API token |
| `SSH_KEY_PATH` | `~/.ssh/id_rsa` | Path to your SSH private key |
| `CHEZMOI_REPO` | `fuJiin/dotfiles` | GitHub shorthand for your dotfiles |
| `DEFAULT_SERVER_TYPE` | `cpx21` | Hetzner server type (3 vCPU, 4GB RAM) |
| `DEFAULT_LOCATION` | `hil` | Hetzner datacenter (Hillsboro, OR) |
| `DEFAULT_IMAGE` | `ubuntu-24.04` | Base OS image |

### Server types

| Type | vCPU | RAM | Disk | ~Cost/mo |
|---|---|---|---|---|
| `cpx21` | 3 | 4 GB | 80 GB | $9.99 |
| `cpx31` | 4 | 8 GB | 160 GB | $17.99 |
| `cpx41` | 8 | 16 GB | 240 GB | $33.49 |

Boxes are billed hourly. A `cpx21` running for a workday costs ~$0.05.

---

## Appendix

### Decisions

| Decision | Over | Rationale |
|---|---|---|
| Hetzner | AWS, DO | Hillsboro (`hil`) is ~15-30ms from SF. Comparable to AWS us-west-2 at ~1/3 the price. `cx23` at $4.35/mo is hard to beat for disposable boxes. |
| tmux | zellij | Termius has native tmux integration. zellij has no mobile client support. Consistent sessions across devices is the whole point. |
| `dev` user | root | Claude Code and npm shouldn't run as root. `dev` has passwordless sudo for package management but runs tools in userspace. |
| One key per device | Shared key | Each device (laptop, phone) gets its own SSH key uploaded to Hetzner as `imir-*`. Revoke one without affecting others. No private keys copied between devices. |
| SSH agent forwarding | deploy keys | Boxes are transient — persistent credentials on a throwaway VM is a liability. Keys never leave your laptop. |
| hcloud CLI | Terraform | Overkill for single-VM lifecycle. If this grows to multi-VM setups with networking/firewalls, revisit. |
| Bare VM | Docker | Dev boxes need persistent tmux sessions, SSH access, and full OS tooling. Docker *inside* the box is fine. |

### Future work

- **Worktree helper**: fish function to create a worktree + tmux window in one command
- **Tailscale**: stable DNS names (`mybox.tail1234.ts.net`) instead of IPs, survives VM recreation
- **Additional AI tools**: codex, opencode, or other CLI agents added to bootstrap
- **Snapshot/restore**: save a bootstrapped image to skip the ~2 min setup on new boxes

### Useful references

- **tmux**: [Getting Started](https://github.com/tmux/tmux/wiki/Getting-Started) · [Cheat Sheet](https://tmuxcheatsheet.com/)
