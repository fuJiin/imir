# Usage guides

## Single box, multiple features

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

# list sessions
imir sessions work
```

## Multiple boxes

When you want full isolation — different repos, throwaway experiments, or dedicated resources:

```bash
imir create frontend
imir create backend cx32    # bigger box for heavy builds
imir create experiment

imir list                   # see all running boxes
imir destroy experiment     # done with this one
```

## Connecting from your phone

Each device gets its own SSH key. Imir passes all `imir-*` SSH keys from Hetzner to new boxes automatically.

**One-time setup:**

1. In Termius: **Keychain** → **+** → **Key** → **Generate** a new key
2. Copy the **public** key (the `ssh-ed25519 AAAA...` line)
3. From your laptop, upload it to Hetzner:
   ```bash
   hcloud ssh-key create --name imir-phone --public-key-from-file phone.pub
   ```
4. New boxes will include the key automatically. For existing boxes:
   ```bash
   imir connect myproject
   # on the box:
   echo "ssh-ed25519 AAAA..." >> ~/.ssh/authorized_keys
   ```

**Per-box setup in Termius:**

1. Get the IP: `imir ip myproject`
2. **Hosts** → **+** → **Hostname**: the IP, **Username**: `dev`
3. Select your key (no password)
4. Enable **SSH agent forwarding**
5. Connect, then `tmux attach` or `tmux new-session -As main`

## Git authentication

`imir connect` uses SSH agent forwarding (`-A`), so git operations on the box use your local SSH key. No private keys on the box.

```bash
ssh-add -l             # check your agent has keys
ssh-add ~/.ssh/id_rsa  # add if needed
```

## GitHub CLI

SSH agent forwarding covers `git push`, but `gh` needs its own auth for the GitHub API.

**Per-box setup** (run once after connecting):

```bash
gh auth login
# Choose: GitHub.com → SSH → forwarded key → Login with a web browser
```

Tips:
- Pick **SSH** as the git protocol so `gh pr create` uses your forwarded key.
- If browser auth isn't practical (e.g. phone), use a [personal access token](https://github.com/settings/tokens) with `repo` scope.
- Auth state lives in `~/.config/gh/` on the box — gone when the box is destroyed.

**Adding your SSH key to GitHub** (one-time, per device):

If you generated a new key for a device, GitHub needs it too for `git push` without agent forwarding:

```bash
gh ssh-key add ~/.ssh/id_ed25519.pub --title "imir-phone"
```

Or add it at [github.com/settings/ssh/new](https://github.com/settings/ssh/new).
