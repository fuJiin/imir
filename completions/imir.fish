# Fish completions for imir

# Disable file completions by default
complete -c imir -f

# Helper: list box names (strips imir- prefix and header)
function __imir_boxes
    hcloud server list -l managed-by=imir -o noheader -o columns=name 2>/dev/null \
        | sed 's/^imir-//'
end

# Helper: list active background tunnel names
function __imir_tunnel_names
    set -l dir (set -q XDG_CONFIG_HOME; and echo $XDG_CONFIG_HOME; or echo $HOME/.config)/imir/tunnels
    test -d $dir; or return
    for f in $dir/*.tunnel
        test -f $f; or continue
        grep -m1 '^NAME=' $f | string replace -r '^NAME=' ''
    end | sort -u
end

# Subcommands (only when no subcommand yet)
complete -c imir -n "not __fish_seen_subcommand_from init uninstall upgrade create bake connect ssh tunnel tunnels kill-tunnel ip sessions kill-session list rename destroy help" \
    -a "init uninstall upgrade create bake connect ssh tunnel tunnels kill-tunnel ip sessions kill-session list rename destroy help"

# Box name completions for commands that take <name>
for cmd in connect ssh tunnel ip sessions kill-session rename destroy
    complete -c imir -n "__fish_seen_subcommand_from $cmd; and not __fish_seen_subcommand_from (__imir_boxes)" \
        -a "(__imir_boxes)"
end

# Tunnel name completions for kill-tunnel
complete -c imir -n "__fish_seen_subcommand_from kill-tunnel" \
    -a "(__imir_tunnel_names)"

# Flags for bake
complete -c imir -n "__fish_seen_subcommand_from bake" -l force -d "Rebuild snapshot even if hash matches"

# Flags for tunnel
complete -c imir -n "__fish_seen_subcommand_from tunnel" -s d -l daemon -d "Run tunnel in background"
