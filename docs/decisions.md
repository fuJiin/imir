# Decisions

| Decision | Over | Rationale |
|---|---|---|
| Hetzner | AWS, DO | Hillsboro (`hil`) is ~15-30ms from SF. Comparable to AWS us-west-2 at ~1/3 the price. `cx23` at $4.35/mo is hard to beat for disposable boxes. |
| tmux | zellij | Termius has native tmux integration. zellij has no mobile client support. Consistent sessions across devices is the whole point. |
| chezmoi owns the toolchain | imir installs everything | imir installs only `git`, `tmux`, `curl`, `chezmoi`. Your shell, editor, agents, and language runtimes all live in your dotfiles repo. Change tools by editing dotfiles, not imir. |
| `--dotfiles` flag | one repo per imir install | One imir, many profiles: human dev box vs agent box (e.g. arbora-crew) just by pointing at a different chezmoi repo. |
| `dev` user | root | Claude Code and npm shouldn't run as root. `dev` has passwordless sudo for package management but runs tools in userspace. |
| One key per device | Shared key | Each device (laptop, phone) gets its own SSH key uploaded to Hetzner as `imir-*`. Revoke one without affecting others. No private keys copied between devices. |
| SSH agent forwarding | deploy keys | Boxes are transient — persistent credentials on a throwaway VM is a liability. Keys never leave your laptop. |
| hcloud CLI | Terraform | Overkill for single-VM lifecycle. If this grows to multi-VM setups with networking/firewalls, revisit. |
| Bare VM | Docker | Dev boxes need persistent tmux sessions, SSH access, and full OS tooling. Docker *inside* the box is fine. |

## Future work

- **Worktree helper**: fish function to create a worktree + tmux window in one command
- **Tailscale**: stable DNS names instead of IPs, survives VM recreation
- **Pin chezmoi version**: today the bake script grabs the latest from get.chezmoi.io. Pinning would make snapshots more reproducible.

## References

- **tmux**: [Getting Started](https://github.com/tmux/tmux/wiki/Getting-Started) · [Cheat Sheet](https://tmuxcheatsheet.com/)
- **chezmoi**: [Quick Start](https://www.chezmoi.io/quick-start/) · [Daily Operations](https://www.chezmoi.io/user-guide/daily-operations/)
- **hcloud CLI**: [GitHub](https://github.com/hetznercloud/cli)
