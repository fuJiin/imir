# Fish completions for imir

# Disable file completions by default
complete -c imir -f

# Helper: list box names (strips imir- prefix and header)
function __imir_boxes
    hcloud server list -l managed-by=imir -o noheader -o columns=name 2>/dev/null \
        | sed 's/^imir-//'
end

# Subcommands (only when no subcommand yet)
complete -c imir -n "not __fish_seen_subcommand_from init create connect ssh ip sessions list destroy help" \
    -a "init create connect ssh ip sessions list destroy help"

# Box name completions for commands that take <name>
for cmd in connect ssh ip sessions destroy
    complete -c imir -n "__fish_seen_subcommand_from $cmd; and not __fish_seen_subcommand_from (__imir_boxes)" \
        -a "(__imir_boxes)"
end
