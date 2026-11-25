#!/usr/bin/env bash
# Exercises .claude/hooks/session-start.sh against a stub `claude` that prints a canned
# `claude plugin list --json` and a stub install.sh that records that it ran. The hook installs
# unless codeo@codeo and a superpowers@* plugin are both installed at user scope and enabled.
#
#   session-start-hook.test.sh
#       Exits non-zero and names the failing cases; prints "all cases passed" otherwise.
set -euo pipefail

plugin_root=$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)
hook="$plugin_root/.claude/hooks/session-start.sh"

scratch_root=$(mktemp -d)
trap 'rm -rf "$scratch_root"' EXIT
STUB="$scratch_root/stub"
proj="$scratch_root/project"
mkdir -p "$STUB" "$proj" "$scratch_root/bin"
export STUB
printf '#!/bin/sh\necho ran >> "$STUB/install-calls"\n' > "$proj/install.sh"
cat > "$scratch_root/bin/claude" <<'STUBEOF'
#!/bin/sh
echo "$*" >> "$STUB/claude-calls"
if [ "$1 $2" = "plugin list" ]; then
    [ -e "$STUB/list-fail" ] && exit 1
    [ -e "$STUB/list-pre" ] && cat "$STUB/list-pre"
    cat "$STUB/list.json"
    [ -e "$STUB/list-post" ] && cat "$STUB/list-post"
fi
exit 0
STUBEOF
chmod +x "$scratch_root/bin/claude"
export PATH="$scratch_root/bin:$PATH"
export CLAUDE_PROJECT_DIR="$proj"

failures=0
case_desc=
assert_eq() {
    if [[ $2 != "$3" ]]; then
        echo "FAIL: $case_desc — $1: want [$2] got [$3]"
        failures=$((failures + 1))
    fi
}

# run_hook <remote>: runs the hook with CLAUDE_CODE_REMOTE=<remote> (unset for "unset"); sets rc.
run_hook() {
    rm -f "$STUB/install-calls" "$STUB/claude-calls"
    rc=0
    if [[ $1 == unset ]]; then
        (cd "$plugin_root" && env -u CLAUDE_CODE_REMOTE bash .claude/hooks/session-start.sh) >/dev/null 2>&1 || rc=$?
    else
        (cd "$plugin_root" && CLAUDE_CODE_REMOTE=$1 bash .claude/hooks/session-start.sh) >/dev/null 2>&1 || rc=$?
    fi
}

# entry <id> <scope> <enabled>: one list entry.
entry() { printf '{"id":"%s","version":"1.0.0","scope":"%s","enabled":%s,"projectPath":"/x"}' "$@"; }
# list <entry>...: writes list.json and clears the other stub files.
list() {
    rm -f "$STUB/list-fail" "$STUB/list-pre" "$STUB/list-post"
    local IFS=,
    printf '[%s]\n' "$*" > "$STUB/list.json"
}
ran() { [[ -e $STUB/install-calls ]] && echo yes || echo no; }

# check <desc> <yes|no>: runs the hook as a hosted session and asserts exit 0 and install.sh's fate.
check() {
    case_desc=$1
    run_hook true
    assert_eq "exit" 0 "$rc"
    assert_eq "install ran" "$2" "$(ran)"
}

cx=$(entry codeo@codeo user true)
sp=$(entry superpowers@superpowers-marketplace user true)

list "$cx" "$sp"
case_desc=not_remote_does_nothing
run_hook unset
assert_eq "exit" 0 "$rc"
assert_eq "install ran" no "$(ran)"
[[ ! -e $STUB/claude-calls ]] && ok=yes || ok=no
assert_eq "claude not called" yes "$ok"

list "$cx" "$sp"
check both_enabled_skips no

list "$cx" "$(entry superpowers@elsewhere user true)"
check superpowers_from_another_marketplace_skips no

list "$cx" "$sp"
printf 'Checking for updates\n' > "$STUB/list-pre"
printf 'done\n' > "$STUB/list-post"
check notices_around_the_list_still_skip no

list "$(entry codeo@codeo user false)" "$sp"
check codeo_disabled_installs yes

list "$cx" "$(entry superpowers@superpowers-marketplace user false)"
check superpowers_disabled_installs yes

list "$sp"
check codeo_missing_installs yes

list "$cx"
check superpowers_missing_installs yes

list "$(entry codeo@codeo project true)" "$sp"
check project_scope_only_installs yes

list "$cx" "$(entry superpowers-extras@x user true)"
check a_look_alike_id_does_not_count yes

list "$cx" "$sp"
: > "$STUB/list-fail"
check list_failure_installs yes

list "$cx" "$sp"
printf 'not json\n' > "$STUB/list.json"
check unparsable_list_installs yes

if ((failures > 0)); then
    echo "$failures failure(s)"
    exit 1
fi
echo "all cases passed"
