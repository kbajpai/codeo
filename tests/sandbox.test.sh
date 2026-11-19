#!/usr/bin/env bash
# Guards .sbx/codeo-sandbox.sh, the host-side script that starts, opens and ends one Docker Sandboxes
# (sbx) sandbox per GitHub issue on a Linux or WSL2 host. Each case is a function named in the final
# cases=( ... ) array; add a case by writing a function and listing it. The script runs with PATH
# holding only stub sbx, sbx.exe, git, git.exe and code (plus /usr/bin and /bin), against a scratch
# directory whose calls file logs every stub call and whose sandboxes file is what the stub `sbx ls`
# prints. It checks the usage errors, that a bad argument exits 2 before any call, the one-line
# error when no sbx is installed, the choice of program (sbx, sbx.exe, CODEO_SBX), the reading of
# `sbx ls` rows by sandbox_state, that the script is committed executable with a bash shebang, and
# that the config suite covers .sbx/.
#
#   bash tests/sandbox.test.sh
#
# Exits 0 and prints "all cases passed" when every case holds; prints one "FAIL <case>: <detail>"
# line per problem and exits 1 otherwise.
set -euo pipefail

repo_root() { cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd; }
repo=$(repo_root)
script="$repo/.sbx/codeo-sandbox.sh"
bash_abs=$(command -v bash)

failures=0
current=""

# fail <message>: record one failure against the running case.
fail() {
    printf 'FAIL %s: %s\n' "$current" "$1"
    failures=$((failures + 1))
}

scratch=$(mktemp -d)
trap 'rm -rf "$scratch"' EXIT

# sb_setup <name>: a scratch directory sb_dir with stubs in bin/ that log "<name> <args>" to calls.
# The stub sbx and sbx.exe answer `ls` with the contents of the sandboxes file.
sb_setup() {
    sb_dir="$scratch/$1"
    mkdir -p "$sb_dir/bin"
    : >"$sb_dir/calls"
    : >"$sb_dir/sandboxes"
    mkdir -p "$sb_dir/work"
    echo 'fix/x' >"$sb_dir/branch"
    echo 'codeo-113' >"$sb_dir/lockname"
    : >"$sb_dir/trusted"
    cp "$(dirname "$script")/claude-image" "$sb_dir/default_pin"
    local n
    for n in sbx sbx.exe git git.exe code ssh ssh.exe cmd.exe; do
        cat >"$sb_dir/bin/$n" <<'STUB'
#!/bin/bash
d=${0%/bin/*}
echo "${0##*/} $*" >>"$d/calls"
case "${0##*/} $1" in
    "sbx ls" | "sbx.exe ls") cat "$d/sandboxes" ;;
    "sbx create" | "sbx.exe create") pwd >"$d/create_cwd" ;;
    "sbx run" | "sbx.exe run") [[ ! -e "$d/runfail" ]] || exit 1 ;;
    "sbx exec" | "sbx.exe exec")
        case "$*" in
            *container-name.sh*) cat "$d/lockname" ;;
            *devcontainer-start.sh*)
                echo "start-output"
                [[ ! -e "$d/startfail" ]] || exit 1 ;;
            *"git status --porcelain --branch")
                [[ ! -e "$d/statusfail" ]] || exit 1
                if [[ -f "$d/status" ]]; then cat "$d/status"; else echo "## fix/x"; fi ;;
            *"codeo-113 true") [[ ! -e "$d/truefail" ]] || exit 1 ;;
            *"git stash list") [[ ! -f "$d/stashes" ]] || cat "$d/stashes" ;;
            *" pwd") if [[ -f "$d/sbxpwd" ]]; then cat "$d/sbxpwd"; else echo "/sandbox/clone"; fi ;;
        esac ;;
    "ssh "* | "ssh.exe "*) [[ ! -e "$d/sshfail" ]] || exit 1 ;;
    "cmd.exe "*) pwd >"$d/cmd_cwd" ;;
    "git config") [[ -z "${SB_REAL_GIT:-}" ]] || exec "$SB_REAL_GIT" "$@" ;;
    "git clone") mkdir -p "${@: -1}/.git" ;;
    "git -C")
        case "$*" in *"show origin/HEAD:.sbx/claude-image"*) [[ ! -f "$d/default_pin" ]] || cat "$d/default_pin" ;; esac ;;
    "git.exe config")
        case "$*" in *--get-all*) cat "$d/trusted" ;; esac ;;
esac
if [[ "${0##*/}" == git && "$*" == *"branch --show-current"* ]]; then cat "$d/branch"; fi
exit 0
STUB
        chmod +x "$sb_dir/bin/$n"
    done
}

# The Windows trust path carries the distro name; a case that needs it absent sets SB_NODISTRO.
export WSL_DISTRO_NAME=${WSL_DISTRO_NAME:-Ubuntu}

# sb_run <args...>: run the script with the stubs on PATH; sets sb_rc, sb_out, sb_err.
sb_run() {
    sb_rc=0
    # shellcheck disable=SC2016
    env -u CODEO_SBX ${SB_NODISTRO:+-u WSL_DISTRO_NAME} PATH="$sb_dir/bin:/usr/bin:/bin" ${SB_SBX:+CODEO_SBX="$SB_SBX"} \
        "$bash_abs" -c 'cd "$1" && shift && exec "$@"' _ "$sb_dir/work" "$bash_abs" "$script" "$@" >"$sb_dir/out" 2>"$sb_dir/err" || sb_rc=$?
    sb_out=$(<"$sb_dir/out")
    sb_err=$(<"$sb_dir/err")
}

usage_line='usage: codeo-sandbox.sh issue <N> <branch> | open <N> | shell <N> | end <N> [--force]'

usage_without_arguments_exits_2() {
    sb_setup usage
    sb_run
    ((sb_rc == 2)) || fail "exited $sb_rc, not 2"
    [[ "$sb_err" == "$usage_line" ]] || fail "stderr was: $sb_err"
    [[ -z "$sb_out" ]] || fail "stdout was: $sb_out"
}

bad_numbers_and_branches_exit_2_before_any_call() {
    sb_setup bad
    local n b
    for n in 0 07 -1 1a ''; do
        sb_run open "$n"
        ((sb_rc == 2)) || fail "open '$n' exited $sb_rc"
        sb_run issue "$n" main
        ((sb_rc == 2)) || fail "issue '$n' exited $sb_rc"
    done
    # shellcheck disable=SC2016
    for b in -x a..b 'a b' 'a;b' '$(x)'; do
        sb_run issue 1 "$b"
        ((sb_rc == 2)) || fail "issue 1 '$b' exited $sb_rc"
    done
    sb_run end 1 --nope
    ((sb_rc == 2)) || fail "end 1 --nope exited $sb_rc"
    sb_run open 1 2
    ((sb_rc == 2)) || fail "open 1 2 exited $sb_rc"
    sb_run bogus
    ((sb_rc == 2)) || fail "bogus exited $sb_rc"
    [[ ! -s "$sb_dir/calls" ]] || fail "calls were logged: $(<"$sb_dir/calls")"
}

no_sbx_is_one_line() {
    sb_setup nosbx
    rm "$sb_dir/bin/sbx" "$sb_dir/bin/sbx.exe"
    sb_run open 1
    ((sb_rc == 1)) || fail "exited $sb_rc, not 1"
    [[ "$sb_err" == "codeo-sandbox: sbx is not installed"* ]] || fail "stderr was: $sb_err"
    [[ "$sb_err" != *$'\n'* ]] || fail "stderr is more than one line"
}

# sb_pick: source the script and print the program pick_sbx chose and the windows flag.
sb_pick() {
    # shellcheck disable=SC2016
    local probe='source "$1"; pick_sbx; echo "$sbx $windows"'
    env -u CODEO_SBX PATH="$sb_dir/bin:/usr/bin:/bin" ${SB_SBX:+CODEO_SBX="$SB_SBX"} "$bash_abs" -c "$probe" _ "$script"
}

sbx_is_preferred_over_sbx_exe() {
    sb_setup prefer
    [[ "$(sb_pick)" == "sbx 0" ]] || fail "with both, picked: $(sb_pick)"
    rm "$sb_dir/bin/sbx"
    [[ "$(sb_pick)" == "sbx.exe 1" ]] || fail "with only sbx.exe, picked: $(sb_pick)"
}

codeo_sbx_overrides_both() {
    sb_setup override
    [[ "$(SB_SBX=/x/mysbx sb_pick)" == "/x/mysbx 0" ]] || fail "override picked: $(SB_SBX=/x/mysbx sb_pick)"
    [[ "$(SB_SBX=/x/my.exe sb_pick)" == "/x/my.exe 1" ]] || fail "exe override picked: $(SB_SBX=/x/my.exe sb_pick)"
}

sandbox_state_ignores_a_row_with_fewer_than_three_columns() {
    sb_setup shortrow
    # shellcheck disable=SC2016
    local probe='source "$1"; sbx=sbx; sandbox_state codeo-113' out
    # A row with no status column reads as stopped, the same as an empty status: it is not treated as missing.
    echo 'codeo-113 claude' >"$sb_dir/sandboxes"
    out=$(PATH="$sb_dir/bin:/usr/bin:/bin" "$bash_abs" -c "$probe" _ "$script")
    [[ "$out" == stopped ]] || fail "a two-column row read as: $out"
}

sandbox_state_reads_the_ls_rows() {
    sb_setup state
    # shellcheck disable=SC2016
    local probe='source "$1"; sbx=sbx; for n in codeo-a codeo-b codeo-c codeo-x SANDBOX; do echo "$n=$(sandbox_state $n)"; done'
    local want=$'codeo-a=detached\ncodeo-b=stopped\ncodeo-c=running\ncodeo-x=missing\nSANDBOX=missing' out
    cat >"$sb_dir/sandboxes" <<'ROWS'
  SANDBOX     AGENT    STATUS                 PORTS                        WORKSPACE      CREATED
  codeo-a     claude   ● running (detached)   127.0.0.1:60030->9418/tcp4   D:\w\codeo-a   6m
  codeo-b     claude   ○ stopped                                           D:\w\codeo-b   1m
  codeo-c     claude   ● running              127.0.0.1:60031->9418/tcp4   D:\w\codeo-c   1m
ROWS
    out=$(PATH="$sb_dir/bin:/usr/bin:/bin" "$bash_abs" -c "$probe" _ "$script")
    [[ "$out" == "$want" ]] || fail "states with markers were: $out"
    out=$(LC_ALL=C PATH="$sb_dir/bin:/usr/bin:/bin" "$bash_abs" -c "$probe" _ "$script")
    [[ "$out" == "$want" ]] || fail "states with markers under LC_ALL=C were: $out"
    cat >"$sb_dir/sandboxes" <<'ROWS'
codeo-a claude running (detached)
codeo-b claude stopped
codeo-c claude running
ROWS
    out=$(PATH="$sb_dir/bin:/usr/bin:/bin" "$bash_abs" -c "$probe" _ "$script")
    [[ "$out" == "$want" ]] || fail "states without markers were: $out"
    out=$(LC_ALL=C PATH="$sb_dir/bin:/usr/bin:/bin" "$bash_abs" -c "$probe" _ "$script")
    [[ "$out" == "$want" ]] || fail "states without markers under LC_ALL=C were: $out"
}

a_failed_ls_stops_issue_with_one_line() {
    sb_setup lsfail
    cat >"$sb_dir/bin/sbx" <<'STUB'
#!/bin/bash
echo "sbx $*" >>"${0%/bin/*}/calls"
[[ "$1" != ls ]] || exit 1
exit 0
STUB
    chmod +x "$sb_dir/bin/sbx"
    sb_run issue 113 fix/x
    ((sb_rc == 1)) || fail "exited $sb_rc"
    [[ "$sb_err" == "codeo-sandbox: could not list sandboxes with sbx" ]] || fail "stderr was: $sb_err"
    [[ "$(sb_calls)" != *"sbx create"* && "$(sb_calls)" != *"sbx exec"* ]] || fail "calls: $(sb_calls)"
}

the_script_is_committed_executable_with_a_bash_shebang() {
    local mode
    mode=$(git -C "$repo" ls-files -s -- .sbx/codeo-sandbox.sh | cut -d' ' -f1)
    if [[ -n "$mode" ]]; then
        [[ "$mode" == 100755 ]] || fail "index mode is $mode, not 100755"
    else
        [[ -x "$script" ]] || fail "the script is missing or not executable"
    fi
    [[ -r "$script" && "$(head -n 1 "$script")" == '#!/usr/bin/env bash' ]] || fail "first line is not #!/usr/bin/env bash"
}

config_suite_covers_the_sandbox_folder() {
    jq -e '.suites[0].paths | index(".sbx/**")' "$repo/.codeo/config.json" >/dev/null || fail ".sbx/** is not in suites[0].paths"
}

# sb_calls: the calls file as one string.
sb_calls() { cat "$sb_dir/calls"; }

issue_clones_the_branch_on_the_host() {
    sb_setup clone
    sb_run issue 113 fix/x
    ((sb_rc == 0)) || fail "exited $sb_rc: $sb_err"
    [[ "$(sb_calls)" == *$'git clone --branch fix/x https://github.com/kbajpai/codeo.git codeo-113\n'* ]] || fail "calls: $(sb_calls)"
    sb_setup clone2
    CODEO_REPO_URL=https://example.test/r.git sb_run issue 113 fix/x
    [[ "$(sb_calls)" == *'git clone --branch fix/x https://example.test/r.git codeo-113'* ]] || fail "override calls: $(sb_calls)"
}

issue_refuses_a_host_clone_on_another_branch() {
    sb_setup otherbranch
    mkdir -p "$sb_dir/work/codeo-113/.git"
    echo other >"$sb_dir/branch"
    sb_run issue 113 fix/x
    ((sb_rc == 1)) || fail "exited $sb_rc"
    [[ "$sb_err" == *"'other'"*fix/x* && "$sb_err" != *$'\n'* ]] || fail "stderr was: $sb_err"
    [[ "$(sb_calls)" != *create* ]] || fail "create was called"
}

issue_refuses_a_folder_that_is_not_a_clone() {
    sb_setup notclone
    mkdir -p "$sb_dir/work/codeo-113"
    sb_run issue 113 fix/x
    ((sb_rc == 1)) || fail "exited $sb_rc"
    [[ "$sb_err" == *codeo-113* && "$sb_err" != *$'\n'* ]] || fail "stderr was: $sb_err"
    [[ "$(sb_calls)" != *create* ]] || fail "create was called"
}

issue_adds_the_windows_trust_line_once() {
    sb_setup trust
    rm "$sb_dir/bin/sbx"
    local want got
    sb_run issue 113 fix/x
    got=$(grep -c '^git.exe config --global --add safe.directory ' "$sb_dir/calls" || true)
    ((got == 1)) || fail "add called $got times"
    want="git.exe config --global --add safe.directory %(prefix)///wsl.localhost/${WSL_DISTRO_NAME:-}$(cd "$sb_dir/work/codeo-113" && pwd -P)"
    [[ "$(sb_calls)" == *"$want"* ]] || fail "want '$want' in: $(sb_calls)"
    sb_setup trust2
    rm "$sb_dir/bin/sbx"
    mkdir -p "$sb_dir/work/codeo-113/.git"
    echo "%(prefix)///wsl.localhost/${WSL_DISTRO_NAME:-}$(cd "$sb_dir/work/codeo-113" && pwd -P)" >"$sb_dir/trusted"
    sb_run issue 113 fix/x
    [[ "$(sb_calls)" != *"--add"* ]] || fail "added though trusted: $(sb_calls)"
}

issue_skips_the_windows_trust_with_linux_sbx() {
    sb_setup notrust
    sb_run issue 113 fix/x
    [[ "$(sb_calls)" != *git.exe* ]] || fail "git.exe called: $(sb_calls)"
}

issue_without_git_exe_prints_the_trust_command() {
    sb_setup nogitexe
    rm "$sb_dir/bin/sbx" "$sb_dir/bin/git.exe"
    sb_run issue 113 fix/x
    ((sb_rc == 0)) || fail "exited $sb_rc: $sb_err"
    local n
    n=$(grep -c '^todo:.*git.exe config --global --add safe.directory %(prefix)///wsl.localhost/' <<<"$sb_out" || true)
    ((n == 1)) || fail "todo lines: $n in: $sb_out"
    [[ "$(sb_calls)" == *"sbx.exe create"* ]] || fail "create not called"
}

issue_without_wsl_distro_name_prints_the_trust_todo() {
    sb_setup nodistro
    rm "$sb_dir/bin/sbx"
    SB_NODISTRO=1 sb_run issue 113 fix/x
    ((sb_rc == 0)) || fail "exited $sb_rc: $sb_err"
    local n
    n=$(grep -c '^todo: WSL_DISTRO_NAME is not set.*safe.directory' <<<"$sb_out" || true)
    ((n == 1)) || fail "todo lines: $n in: $sb_out"
    [[ "$(sb_calls)" != *"git.exe config --global --add"* ]] || fail "git.exe add called: $(sb_calls)"
}

issue_creates_with_the_limits() {
    sb_setup create
    sb_run issue 113 fix/x
    [[ "$(sb_calls)" == *$'sbx create --clone --name codeo-113 --cpus 2 --memory 4g docker.io/sbx/claude@sha256:'* ]] || fail "calls: $(sb_calls)"
    [[ "$(<"$sb_dir/create_cwd")" == "$(cd "$sb_dir/work/codeo-113" && pwd -P)" ]] || fail "create ran in: $(<"$sb_dir/create_cwd")"
}

issue_creates_at_the_pinned_image() {
    sb_setup pin
    local ref
    ref=$(<"$(dirname "$script")/claude-image")
    sb_run issue 113 fix/x
    [[ "$(sb_calls)" == *$'sbx create --clone --name codeo-113 --cpus 2 --memory 4g '"$ref"$' .\n'* ]] || fail "calls: $(sb_calls)"
    sb_setup pin2
    printf '%s\n' 'docker.io/sbx/claude@sha256:0000000000000000000000000000000000000000000000000000000000000000' >"$sb_dir/image"
    CODEO_SBX_IMAGE="$sb_dir/image" sb_run issue 113 fix/x
    [[ "$(sb_calls)" == *' 4g docker.io/sbx/claude@sha256:0000'*' .'* ]] || fail "override calls: $(sb_calls)"
}

a_pin_that_is_not_a_digest_is_refused() {
    sb_setup badpin
    printf '%s\n' 'docker.io/sbx/claude:latest' >"$sb_dir/image"
    CODEO_SBX_IMAGE="$sb_dir/image" sb_run issue 113 fix/x
    ((sb_rc == 1)) || fail "exited $sb_rc"
    [[ "$sb_err" == codeo-sandbox:*"$sb_dir/image"* && "$sb_err" != *$'\n'* ]] || fail "stderr was: $sb_err"
    [[ "$(sb_calls)" != *create* ]] || fail "calls: $(sb_calls)"
    sb_setup nopin
    CODEO_SBX_IMAGE="$sb_dir/missing" sb_run issue 113 fix/x
    ((sb_rc == 1)) || fail "missing exited $sb_rc"
    [[ "$sb_err" == codeo-sandbox:*"$sb_dir/missing"* && "$sb_err" != *$'\n'* ]] || fail "missing stderr: $sb_err"
    [[ "$(sb_calls)" != *create* ]] || fail "calls: $(sb_calls)"
}

# pin_line <hex digit>: a pin line whose digest is 64 copies of that digit.
pin_line() { printf 'docker.io/sbx/claude@sha256:%s\n' "$(printf '%64s' '' | tr ' ' "$1")"; }

# pin_setup <name> <branch pin digit or -> <main pin digit or ->: a real origin whose fix/x branch and
# main hold .sbx/claude-image with the given digest (- for no file), and a real clone codeo-113 on fix/x.
pin_setup() {
    sb_setup "$1"
    local w=$sb_dir/work g="$real_git -c user.name=t -c user.email=t@example.com"
    $real_git init -q -b main --bare "$sb_dir/origin.git"
    $real_git init -q -b main "$sb_dir/seed"
    $g -C "$sb_dir/seed" commit -q --allow-empty -m base
    if [[ "$3" != - ]]; then
        mkdir -p "$sb_dir/seed/.sbx"
        pin_line "$3" >"$sb_dir/seed/.sbx/claude-image"
        $real_git -C "$sb_dir/seed" add .sbx
        $g -C "$sb_dir/seed" commit -q -m "main pin"
    fi
    $real_git -C "$sb_dir/seed" push -q "$sb_dir/origin.git" main
    $g -C "$sb_dir/seed" checkout -q -b fix/x
    if [[ "$2" != - ]]; then
        mkdir -p "$sb_dir/seed/.sbx"
        pin_line "$2" >"$sb_dir/seed/.sbx/claude-image"
        $real_git -C "$sb_dir/seed" add .sbx
        $g -C "$sb_dir/seed" commit -q -m "branch pin"
    elif [[ "$3" != - ]]; then
        $real_git -C "$sb_dir/seed" rm -q -r .sbx
        $g -C "$sb_dir/seed" commit -q -m "no pin on the branch"
    fi
    $real_git -C "$sb_dir/seed" push -q "$sb_dir/origin.git" fix/x
    $real_git clone -q --branch fix/x "$sb_dir/origin.git" "$w/codeo-113"
    rm -f "$sb_dir/default_pin"
    cat >"$sb_dir/bin/git" <<STUB
#!/bin/bash
echo "\${0##*/} \$*" >>"$sb_dir/calls"
exec "$real_git" "\$@"
STUB
}

issue_reads_the_pin_from_the_clone() {
    pin_setup pinclone a b
    sb_run issue 113 fix/x
    ((sb_rc == 0)) || fail "exited $sb_rc: $sb_err"
    [[ "$(sb_calls)" == *"sbx create "*" $(pin_line a) ."* ]] || fail "calls: $(sb_calls)"
}

issue_reads_the_pin_from_the_default_branch_when_the_branch_has_none() {
    pin_setup pindefault - b
    sb_run issue 113 fix/x
    ((sb_rc == 0)) || fail "exited $sb_rc: $sb_err"
    [[ "$(sb_calls)" == *"sbx create "*" $(pin_line b) ."* ]] || fail "calls: $(sb_calls)"
}

issue_without_any_pin_is_one_line() {
    pin_setup pinnone - -
    sb_run issue 113 fix/x
    ((sb_rc == 1)) || fail "exited $sb_rc"
    [[ "$sb_err" == *CODEO_SBX_IMAGE*codeo-113/.sbx/claude-image*origin/HEAD:.sbx/claude-image* && "$sb_err" != *$'\n'* ]] || fail "stderr was: $sb_err"
    [[ "$(sb_calls)" != *"sbx create"* ]] || fail "create was called"
}

issue_pin_override_wins_over_the_clone() {
    pin_setup pinwins a b
    pin_line c >"$sb_dir/image"
    CODEO_SBX_IMAGE="$sb_dir/image" sb_run issue 113 fix/x
    ((sb_rc == 0)) || fail "exited $sb_rc: $sb_err"
    [[ "$(sb_calls)" == *"sbx create "*" $(pin_line c) ."* ]] || fail "calls: $(sb_calls)"
}

# advance_origin <name>: push one more commit to origin's fix/x from the seed; echoes nothing.
advance_origin() {
    $real_git -C "$sb_dir/seed" -c user.name=t -c user.email=t@example.com commit -q --allow-empty -m "$1"
    $real_git -C "$sb_dir/seed" push -q "$sb_dir/origin.git" fix/x
}

issue_fast_forwards_a_stale_clone_before_creating() {
    pin_setup stale a b
    advance_origin ahead
    sb_run issue 113 fix/x
    ((sb_rc == 0)) || fail "exited $sb_rc: $sb_err"
    [[ "$($real_git -C "$sb_dir/work/codeo-113" rev-parse HEAD)" == "$($real_git -C "$sb_dir/origin.git" rev-parse fix/x)" ]] ||
        fail "clone is not at origin/fix/x"
    [[ "$(sb_calls)" == *"sbx create "* ]] || fail "create did not run: $(sb_calls)"
}

issue_refuses_a_clone_that_cannot_fast_forward() {
    pin_setup diverged a b
    local c=$sb_dir/work/codeo-113 before
    $real_git -C "$c" -c user.name=t -c user.email=t@example.com commit -q --allow-empty -m local
    advance_origin remote
    before=$($real_git -C "$c" rev-parse HEAD)
    sb_run issue 113 fix/x
    ((sb_rc == 1)) || fail "exited $sb_rc"
    [[ "$sb_err" == "codeo-sandbox: codeo-113 cannot be brought up to origin/fix/x: settle it there, or remove codeo-113, then run this again" ]] ||
        fail "stderr was: $sb_err"
    [[ "$(sb_calls)" != *"sbx create"* ]] || fail "create was called"
    [[ "$($real_git -C "$c" rev-parse HEAD)" == "$before" ]] || fail "HEAD moved"
}

issue_refuses_when_origin_has_no_branch() {
    pin_setup nobranch a b
    $real_git -C "$sb_dir/origin.git" branch -q -D fix/x 2>/dev/null ||
        $real_git -C "$sb_dir/origin.git" update-ref -d refs/heads/fix/x
    sb_run issue 113 fix/x
    ((sb_rc == 1)) || fail "exited $sb_rc"
    [[ "$sb_err" == *origin/fix/x* && "$sb_err" != *$'\n'* ]] || fail "stderr was: $sb_err"
    [[ "$(sb_calls)" != *"sbx create"* ]] || fail "create was called"
}

issue_leaves_the_clone_alone_when_the_sandbox_exists() {
    pin_setup present a b
    advance_origin ahead
    printf 'NAME AGENT STATUS\ncodeo-113 claude running (detached)\n' >"$sb_dir/sandboxes"
    local before
    before=$($real_git -C "$sb_dir/work/codeo-113" rev-parse HEAD)
    sb_run issue 113 fix/x
    ((sb_rc == 0)) || fail "exited $sb_rc: $sb_err"
    [[ "$($real_git -C "$sb_dir/work/codeo-113" rev-parse HEAD)" == "$before" ]] || fail "HEAD moved"
    [[ "$(sb_calls)" != *fetch* ]] || fail "fetch ran: $(sb_calls)"
}

the_pin_file_is_a_digest() {
    local line
    line=$(<"$(dirname "$script")/claude-image")
    [[ "$line" =~ ^docker\.io/sbx/claude@sha256:[0-9a-f]{64}$ ]] || fail "pin was: $line"
}

issue_runs_the_start_script_with_the_identity() {
    sb_setup start
    unset GIT_AUTHOR_NAME GIT_AUTHOR_EMAIL
    GIT_AUTHOR_NAME='Ann Dev' GIT_AUTHOR_EMAIL=a@x.test sb_run issue 113 fix/x
    [[ "$(sb_calls)" == *'sbx exec codeo-113 env CODEO_CMD_MODE=1 GIT_AUTHOR_NAME=Ann Dev GIT_AUTHOR_EMAIL=a@x.test bash .devcontainer/scripts/devcontainer-start.sh'* ]] || fail "calls: $(sb_calls)"
    [[ "$sb_out" == *start-output* ]] || fail "stdout was: $sb_out"
    sb_setup start2
    unset GIT_AUTHOR_EMAIL
    GIT_AUTHOR_NAME=Ann sb_run issue 113 fix/x
    [[ "$(sb_calls)" == *'env CODEO_CMD_MODE=1 GIT_AUTHOR_NAME=Ann bash .devcontainer'* ]] || fail "no-email calls: $(sb_calls)"
}

issue_rerun_on_an_existing_sandbox_creates_nothing() {
    local state runs
    for state in 'running (detached)' running stopped; do
        sb_setup "rerun-${state%% *}"
        mkdir -p "$sb_dir/work/codeo-113/.git"
        printf 'NAME AGENT STATUS\ncodeo-113 claude %s\n' "$state" >"$sb_dir/sandboxes"
        sb_run issue 113 fix/x
        ((sb_rc == 0)) || fail "$state: exited $sb_rc: $sb_err"
        [[ "$(sb_calls)" != *"sbx create"* ]] || fail "$state: create: $(sb_calls)"
        [[ "$(sb_calls)" == *devcontainer-start.sh* ]] || fail "$state: no start exec"
        runs=$(sb_calls | grep -c '^sbx run' || true)
        if [[ $state == 'running (detached)' ]]; then
            ((runs == 0)) || fail "$state: run called: $(sb_calls)"
        else
            { ((runs == 1)) && [[ "$(sb_calls)" == *'sbx run -d --name codeo-113'* ]]; } || fail "$state: runs=$runs: $(sb_calls)"
        fi
    done
}

issue_leaves_the_sandbox_running_detached() {
    sb_setup issuedetached
    sb_run issue 113 fix/x
    ((sb_rc == 0)) || fail "exited $sb_rc: $sb_err"
    local calls before
    calls=$(sb_calls)
    [[ "$(printf '%s\n' "$calls" | tail -n 1)" == 'sbx run -d --name codeo-113' ]] || fail "last call: $calls"
    before=${calls%%sbx run -d*}
    [[ "$before" == *devcontainer-start.sh* && "$before" == *container-name.sh* ]] || fail "order: $calls"
}

issue_writes_the_sandbox_marker() {
    # shellcheck disable=SC2016
    local state mark='sbx exec codeo-113 bash -c printf "%s\n" "$1" > "$HOME/.codeo-sandbox" _ codeo-113' calls
    for state in missing 'running (detached)'; do
        sb_setup "mark-${state%% *}"
        mkdir -p "$sb_dir/work/codeo-113/.git"
        [[ $state == missing ]] || printf 'NAME AGENT STATUS\ncodeo-113 claude %s\n' "$state" >"$sb_dir/sandboxes"
        sb_run issue 113 fix/x
        calls=$(sb_calls)
        [[ "$calls" == *"$mark"* ]] || fail "$state: no marker exec: $calls"
        [[ "${calls%%"$mark"*}" != *devcontainer-start.sh* ]] || fail "$state: marker after the start script"
        [[ "${calls#*"$mark"}" == *devcontainer-start.sh* ]] || fail "$state: no start script after the marker"
    done
}

issue_names_the_next_step_when_the_start_script_fails() {
    sb_setup startfail
    : >"$sb_dir/startfail"
    sb_run issue 113 fix/x
    local want='codeo-sandbox: the start script failed in codeo-113: fix what it printed above, then run codeo-sandbox.sh issue 113 fix/x again, or codeo-sandbox.sh shell 113 to look inside'
    ((sb_rc == 1)) || fail "exited $sb_rc, not 1"
    [[ "$sb_err" == "$want" ]] || fail "stderr was: $sb_err"
    [[ "$(sb_calls)" != *container-name.sh* && "$(sb_calls)" != *"sbx run"* ]] || fail "calls: $(sb_calls)"
}

issue_rerun_needs_no_pin() {
    sb_setup norepin
    mkdir -p "$sb_dir/work/codeo-113/.git"
    printf 'NAME AGENT STATUS\ncodeo-113 claude running (detached)\n' >"$sb_dir/sandboxes"
    CODEO_SBX_IMAGE="$sb_dir/no-such-pin" sb_run issue 113 fix/x
    ((sb_rc == 0)) || fail "exited $sb_rc: $sb_err"
    [[ "$(sb_calls)" != *"sbx create"* ]] || fail "create: $(sb_calls)"
}

issue_name_that_disagrees_with_the_lock_is_one_todo() {
    sb_setup lock
    echo codeo-98 >"$sb_dir/lockname"
    sb_run issue 113 fix/x
    local want='todo: the sandbox is codeo-113 but its lock is for codeo-98: end it and run issue 98 <branch>'
    [[ "$sb_out" == *"$want"* ]] || fail "stdout was: $sb_out"
    [[ "$(grep -c '^todo:' <<<"$sb_out")" == 1 ]] || fail "not exactly one todo: $sb_out"
}

sandbox_path_prints_the_working_folder() {
    sb_setup path
    local out
    # shellcheck disable=SC2016
    out=$(PATH="$sb_dir/bin:/usr/bin:/bin" "$bash_abs" -c 'source "$1"; sbx=sbx; sandbox_path codeo-1' _ "$script")
    [[ "$out" == /sandbox/clone ]] || fail "path was: $out"
}

sb_err_lines() { wc -l <"$sb_dir/err" | tr -d ' '; }

# end_setup <name> [windows]: sb_setup, plus in work/ a real clone codeo-113 of a bare origin, a bare
# repository standing in for the sandbox's git remote (remote sandbox-codeo-113 mirrors its branches into
# refs/sandboxes/codeo-113/), and a git (or, with windows, git.exe) that logs, records its working
# directory, then runs the real git. Only sbx stays a stub.
real_git=$(command -v git)
end_setup() {
    sb_setup "$1"
    local w=$sb_dir/work g="$real_git -c user.name=t -c user.email=t@example.com" prog=git
    $real_git init -q -b main --bare "$sb_dir/origin.git"
    $real_git init -q "$sb_dir/seed"
    $g -C "$sb_dir/seed" commit -q --allow-empty -m base
    $g -C "$sb_dir/seed" branch -M main
    $real_git -C "$sb_dir/seed" push -q "$sb_dir/origin.git" main
    $real_git clone -q "$sb_dir/origin.git" "$w/codeo-113"
    $real_git clone -q --bare "$sb_dir/origin.git" "$sb_dir/sandbox.git"
    $real_git -C "$w/codeo-113" remote add sandbox-codeo-113 "$sb_dir/sandbox.git"
    $real_git -C "$w/codeo-113" config remote.sandbox-codeo-113.fetch '+refs/heads/*:refs/sandboxes/codeo-113/*'
    local progs=(git)
    if [[ "${2:-}" == windows ]]; then progs+=(git.exe); fi
    for prog in "${progs[@]}"; do
        cat >"$sb_dir/bin/$prog" <<STUB
#!/bin/bash
echo "\${0##*/} \$*" >>"$sb_dir/calls"
pwd >"$sb_dir/${prog}_cwd"
exec "$real_git" "\$@"
STUB
        chmod +x "$sb_dir/bin/$prog"
    done
    echo 'codeo-113 claude running' >"$sb_dir/sandboxes"
}

# end_commit <count>: add that many commits on branch work in the sandbox repo.
end_commit() {
    local i tmp=$sb_dir/wc
    [[ -d "$tmp" ]] || $real_git clone -q "$sb_dir/sandbox.git" "$tmp"
    for ((i = 1; i <= $1; i++)); do
        $real_git -c user.name=t -c user.email=t@example.com -C "$tmp" commit -q --allow-empty -m "unpushed $i"
    done
    $real_git -C "$tmp" push -q origin HEAD:refs/heads/work
}

end_with_nothing_to_lose_removes_the_sandbox() {
    end_setup endclean
    sb_run end 113
    ((sb_rc == 0)) || fail "exited $sb_rc: $sb_err"
    [[ "$sb_out" == "removed codeo-113" ]] || fail "stdout was: $sb_out"
    [[ "$(sb_calls)" == *$'\nsbx rm --force codeo-113'* ]] || fail "calls: $(sb_calls)"
}

end_with_an_unpushed_commit_removes_nothing() {
    end_setup endlose
    end_commit 1
    sb_run end 113
    ((sb_rc == 1)) || fail "exited $sb_rc"
    [[ "$sb_out" == *"unpushed 1"* ]] || fail "stdout was: $sb_out"
    [[ "$sb_out" == *"end 113 --force"* ]] || fail "no --force hint: $sb_out"
    [[ "$(sb_calls)" != *" rm "* ]] || fail "rm ran: $(sb_calls)"
}

end_force_removes_and_says_where_the_commits_are() {
    end_setup endforce
    end_commit 1
    sb_run end 113 --force
    ((sb_rc == 0)) || fail "exited $sb_rc: $sb_err"
    [[ "$sb_out" =~ refs/codeo/ended/codeo-113/[0-9]{8}T[0-9]{6}Z/\ in\ ./codeo-113 ]] || fail "stdout was: $sb_out"
    [[ "$(sb_calls)" == *$'\nsbx rm --force codeo-113'* ]] || fail "calls: $(sb_calls)"
}

end_with_uncommitted_changes_removes_nothing() {
    end_setup enddirty
    printf '## fix/x\n M a.txt\n?? b.txt\n' >"$sb_dir/status"
    sb_run end 113
    ((sb_rc == 1)) || fail "exited $sb_rc"
    [[ "$sb_out" == *"codeo-113 has uncommitted changes:"* && "$sb_out" == *" M a.txt"* && "$sb_out" == *"?? b.txt"* ]] || fail "stdout was: $sb_out"
    [[ "$(tail -n 1 <<<"$sb_out")" == "nothing removed: commit and push it from the sandbox, or run: codeo-sandbox.sh end 113 --force" ]] || fail "stdout was: $sb_out"
    [[ "$(sb_calls)" != *" rm "* ]] || fail "rm ran: $(sb_calls)"
}

end_with_a_stash_removes_nothing() {
    end_setup endstash
    echo 'stash@{0}: WIP on fix/x: abc work' >"$sb_dir/stashes"
    sb_run end 113
    ((sb_rc == 1)) || fail "exited $sb_rc"
    [[ "$sb_out" == *"has 1 stash(es):"* ]] || fail "stdout was: $sb_out"
    [[ "$(sb_calls)" != *" rm "* ]] || fail "rm ran: $(sb_calls)"
}

end_on_a_detached_head_removes_nothing() {
    end_setup enddetached
    echo '## HEAD (no branch)' >"$sb_dir/status"
    sb_run end 113
    ((sb_rc == 1)) || fail "exited $sb_rc"
    [[ "$sb_out" == *"is on a detached HEAD"* ]] || fail "stdout was: $sb_out"
    [[ "$(sb_calls)" != *" rm "* ]] || fail "rm ran: $(sb_calls)"
}

end_with_unpushed_and_uncommitted_lists_both() {
    end_setup endboth
    end_commit 1
    printf '## fix/x\n M a.txt\n' >"$sb_dir/status"
    sb_run end 113
    ((sb_rc == 1)) || fail "exited $sb_rc"
    [[ "$sb_out" == *"has 1 commit(s)"* && "$sb_out" == *"has uncommitted changes:"* ]] || fail "stdout was: $sb_out"
    [[ "$(tail -n 1 <<<"$sb_out")" == "nothing removed: commit and push it from the sandbox, or run: codeo-sandbox.sh end 113 --force" ]] || fail "stdout was: $sb_out"
}

end_force_with_uncommitted_work_says_it_is_not_kept() {
    end_setup endforcedirty
    printf '## fix/x\n M a.txt\n' >"$sb_dir/status"
    sb_run end 113 --force
    ((sb_rc == 0)) || fail "exited $sb_rc: $sb_err"
    [[ "$(sb_calls)" == *$'\nsbx rm --force codeo-113'* ]] || fail "calls: $(sb_calls)"
    [[ "$(tail -n 1 <<<"$sb_out")" == "its uncommitted work was not kept" ]] || fail "stdout was: $sb_out"
}

end_with_a_failed_status_check_removes_nothing() {
    end_setup endstatusfail
    : >"$sb_dir/statusfail"
    sb_run end 113
    ((sb_rc == 1)) || fail "exited $sb_rc"
    [[ "$(tail -n 1 <<<"$sb_err")" == "codeo-sandbox: could not check codeo-113 for uncommitted work, nothing removed" ]] || fail "stderr was: $sb_err"
    [[ "$(sb_calls)" != *" rm "* ]] || fail "rm ran: $(sb_calls)"
}

end_with_crlf_status_is_clean() {
    end_setup endcrlf
    printf '## fix/x\r\n' >"$sb_dir/status"
    sb_run end 113
    ((sb_rc == 0)) || fail "exited $sb_rc: $sb_err"
    [[ "$(sb_calls)" == *$'\nsbx rm --force codeo-113'* ]] || fail "calls: $(sb_calls)"
}

end_on_a_crlf_detached_head_removes_nothing() {
    end_setup endcrlfhead
    printf '## HEAD (no branch)\r\n' >"$sb_dir/status"
    sb_run end 113
    ((sb_rc == 1)) || fail "exited $sb_rc"
    [[ "$sb_out" == *"is on a detached HEAD"* ]] || fail "stdout was: $sb_out"
    [[ "$(sb_calls)" != *" rm "* ]] || fail "rm ran: $(sb_calls)"
}

end_with_crlf_status_and_stash_lines_prints_no_cr() {
    end_setup endcrlflines
    printf '## fix/x\r\n M a.txt\r\n' >"$sb_dir/status"
    printf 'stash@{0}: WIP on fix/x: abc work\r\n' >"$sb_dir/stashes"
    sb_run end 113
    ((sb_rc == 1)) || fail "exited $sb_rc"
    [[ "$sb_out" == *" M a.txt"* && "$sb_out" == *"has 1 stash(es):"* ]] || fail "stdout was: $sb_out"
    [[ "$sb_out" != *$'\r'* ]] || fail "stdout has a CR: $(printf %q "$sb_out")"
    [[ "$(sb_calls)" != *" rm "* ]] || fail "rm ran: $(sb_calls)"
}

end_with_nothing_to_lose_deletes_the_sandbox_refs() {
    end_setup endclear
    end_commit 1
    $real_git -C "$sb_dir/sandbox.git" push -q "$sb_dir/origin.git" refs/heads/work:refs/heads/work
    sb_run end 113
    ((sb_rc == 0)) || fail "exited $sb_rc: $sb_err"
    [[ -z "$($real_git -C "$sb_dir/work/codeo-113" for-each-ref refs/sandboxes/codeo-113/)" ]] || fail "refs remain"
}

end_force_sets_the_refs_aside() {
    end_setup endaside
    end_commit 1
    sb_run end 113 --force
    ((sb_rc == 0)) || fail "exited $sb_rc: $sb_err"
    local c=$sb_dir/work/codeo-113 ref
    [[ -z "$($real_git -C "$c" for-each-ref refs/sandboxes/codeo-113/)" ]] || fail "refs remain"
    ref=$($real_git -C "$c" for-each-ref --format='%(refname)' refs/codeo/ended/codeo-113/ | grep '/work$' || true)
    [[ "$ref" =~ ^refs/codeo/ended/codeo-113/[0-9]{8}T[0-9]{6}Z/work$ ]] || fail "ref was: $ref"
    [[ "$($real_git -C "$c" rev-parse "$ref")" == "$($real_git -C "$sb_dir/sandbox.git" rev-parse work)" ]] || fail "wrong tip"
    [[ "$sb_out" == *"${ref%work}"* ]] || fail "stdout was: $sb_out"
}

end_force_does_not_overwrite_refs_set_aside_earlier() {
    end_setup endclash
    end_commit 1
    printf '#!/bin/bash\necho 20260101T000000Z\n' >"$sb_dir/bin/date"
    chmod +x "$sb_dir/bin/date"
    local c=$sb_dir/work/codeo-113 early
    early=$($real_git -C "$c" rev-parse HEAD)
    $real_git -C "$c" update-ref refs/codeo/ended/codeo-113/20260101T000000Z/work "$early"
    sb_run end 113 --force
    ((sb_rc == 1)) || fail "exited $sb_rc"
    [[ "${sb_err##*$'\n'}" == "codeo-sandbox: removed codeo-113, but could not set aside its refs under refs/sandboxes/codeo-113/ in ./codeo-113" ]] || fail "stderr was: $sb_err"
    [[ "$($real_git -C "$c" rev-parse refs/codeo/ended/codeo-113/20260101T000000Z/work)" == "$early" ]] || fail "earlier ref changed"
    [[ -n "$($real_git -C "$c" for-each-ref refs/sandboxes/codeo-113/work)" ]] || fail "refs moved"
}

a_second_sandbox_for_the_number_starts_clean() {
    end_setup endsecond
    end_commit 1
    sb_run end 113 --force
    ((sb_rc == 0)) || fail "first exited $sb_rc: $sb_err"
    $real_git -C "$sb_dir/sandbox.git" branch -q -D work
    $real_git -C "$sb_dir/sandbox.git" branch -q second main
    $real_git -C "$sb_dir/sandbox.git" push -q "$sb_dir/origin.git" second
    : >"$sb_dir/calls"
    sb_run end 113
    ((sb_rc == 0)) || fail "second exited $sb_rc: $sb_err"
    [[ "$(sb_calls)" == *"sbx rm --force codeo-113"* ]] || fail "calls: $(sb_calls)"
    [[ "$sb_out" == "removed codeo-113" ]] || fail "stdout was: $sb_out"
}

# end_pull_head <k>: publish the sandbox's branch work as refs/pull/<k>/head on origin, as a pull request
# leaves it after a squash merge: no origin branch holds the commits.
end_pull_head() {
    $real_git -C "$sb_dir/sandbox.git" push -q "$sb_dir/origin.git" "refs/heads/work:refs/pull/$1/head"
}

end_after_a_squash_merge_removes_the_sandbox() {
    end_setup endsquash
    end_commit 2
    end_pull_head 7
    sb_run end 113
    ((sb_rc == 0)) || fail "exited $sb_rc: $sb_err"
    [[ "$sb_out" == "removed codeo-113" ]] || fail "stdout was: $sb_out"
    [[ "$(sb_calls)" == *$'\nsbx rm --force codeo-113'* ]] || fail "calls: $(sb_calls)"
}

end_lists_a_commit_made_after_the_pull_request_head() {
    end_setup endafterpr
    end_commit 1
    end_pull_head 7
    end_commit 1
    sb_run end 113
    ((sb_rc == 1)) || fail "exited $sb_rc"
    [[ "$sb_out" == *"has 1 commit(s)"* && "$sb_out" == *"unpushed 1"* ]] || fail "stdout was: $sb_out"
    [[ "$(sb_calls)" != *" rm "* ]] || fail "rm ran: $(sb_calls)"
}

end_with_a_failed_pull_request_fetch_removes_nothing() {
    end_setup endprfetch
    end_commit 1
    end_pull_head 7
    cat >"$sb_dir/bin/git" <<STUB
#!/bin/bash
echo "git \$*" >>"$sb_dir/calls"
[[ "\$*" == *refs/pull/* ]] && exit 1
exec "$real_git" "\$@"
STUB
    sb_run end 113
    ((sb_rc == 1)) || fail "exited $sb_rc"
    [[ "$(tail -n 1 "$sb_dir/err")" == *"nothing removed"* ]] || fail "stderr was: $sb_err"
    [[ "$(sb_calls)" != *" rm "* ]] || fail "rm ran: $(sb_calls)"
}

end_without_origin_removes_nothing() {
    end_setup endorigin
    $real_git -C "$sb_dir/work/codeo-113" remote set-url origin "$sb_dir/nowhere.git"
    sb_run end 113
    ((sb_rc == 1)) || fail "exited $sb_rc"
    [[ "$sb_err" == *origin* ]] || fail "stderr was: $sb_err"
    [[ "$(sb_calls)" != *" rm "* ]] || fail "rm ran: $(sb_calls)"
}

end_with_a_failed_sandbox_fetch_removes_nothing() {
    end_setup endfetch
    $real_git -C "$sb_dir/work/codeo-113" remote set-url sandbox-codeo-113 "$sb_dir/nowhere.git"
    local form
    for form in "" --force; do
        sb_run end 113 $form
        ((sb_rc == 1)) || fail "[$form] exited $sb_rc"
        [[ "$(sb_calls)" != *" rm "* ]] || fail "[$form] rm ran: $(sb_calls)"
        [[ "$sb_err" == *"could not fetch sandbox-codeo-113 into codeo-113"* ]] || fail "[$form] stderr was: $sb_err"
        [[ "$sb_err" == *"nothing in it could be read, so nothing can be proved or kept; to remove it anyway run: sbx rm --force codeo-113"* ]] || fail "[$form] stderr was: $sb_err"
        if [[ -n "$form" ]]; then
            [[ "$sb_err" == *"(--force cannot keep commits it could not fetch), nothing removed"* ]] || fail "[$form] stderr was: $sb_err"
        else
            [[ "$sb_err" != *"--force cannot keep"* && "$sb_err" == *"nothing removed"* ]] || fail "[$form] stderr was: $sb_err"
        fi
    done
}

end_names_a_way_out_when_a_stopped_sandbox_cannot_start() {
    end_setup endnostart
    echo 'codeo-113 claude stopped' >"$sb_dir/sandboxes"
    : >"$sb_dir/truefail"
    local form
    for form in "" --force; do
        sb_run end 113 $form
        ((sb_rc == 1)) || fail "[$form] exited $sb_rc"
        [[ "$(sb_calls)" != *" rm "* ]] || fail "[$form] rm ran: $(sb_calls)"
        [[ "$sb_err" == *"could not start codeo-113"* && "$sb_err" == *"to remove it anyway run: sbx rm --force codeo-113"* ]] || fail "[$form] stderr was: $sb_err"
        if [[ -n "$form" ]]; then
            [[ "$sb_err" == *"(--force cannot keep commits it could not fetch), nothing removed"* ]] || fail "[$form] stderr was: $sb_err"
        else
            [[ "$sb_err" == *"nothing removed"* && "$sb_err" != *"--force cannot keep"* ]] || fail "[$form] stderr was: $sb_err"
        fi
    done
}

end_starts_a_stopped_sandbox_first() {
    end_setup endstopped
    echo 'codeo-113 claude stopped' >"$sb_dir/sandboxes"
    sb_run end 113
    ((sb_rc == 0)) || fail "exited $sb_rc: $sb_err"
    local want
    want=$'sbx ls\nsbx exec codeo-113 true\ngit -C codeo-113 fetch sandbox-codeo-113'
    [[ "$(sb_calls)" == "$want"* ]] || fail "calls: $(sb_calls)"
    [[ "$(sb_calls)" == *$'\nsbx rm --force codeo-113'* ]] || fail "no rm: $(sb_calls)"
}

end_on_a_missing_sandbox_is_one_line() {
    end_setup endmissing
    : >"$sb_dir/sandboxes"
    sb_run end 113
    ((sb_rc == 1)) || fail "exited $sb_rc"
    [[ "$sb_err" == "codeo-sandbox: no sandbox codeo-113" ]] || fail "stderr was: $sb_err"
    [[ "$(sb_calls)" == "sbx ls" ]] || fail "calls: $(sb_calls)"
}

end_without_the_clone_is_one_line() {
    end_setup endnoclone
    rm -rf "$sb_dir/work/codeo-113"
    sb_run end 113
    ((sb_rc == 1)) || fail "exited $sb_rc"
    [[ "$(sb_err_lines)" == 1 ]] || fail "stderr was: $sb_err"
    [[ "$(sb_calls)" != *" rm "* ]] || fail "rm ran: $(sb_calls)"
}

end_with_no_sandbox_refs_removes_nothing() {
    end_setup endnorefs
    $real_git -C "$sb_dir/work/codeo-113" config remote.sandbox-codeo-113.fetch '+refs/heads/*:refs/remotes/sandbox-codeo-113/*'
    sb_run end 113
    ((sb_rc == 1)) || fail "exited $sb_rc"
    [[ "${sb_err##*$'\n'}" == "codeo-sandbox: no branches of codeo-113 were found under refs/sandboxes/codeo-113/ after the fetch, so nothing can be proved and nothing is removed: end 113 --force removes it anyway" ]] || fail "stderr was: $sb_err"
    [[ "$(sb_calls)" != *" rm "* ]] || fail "rm ran: $(sb_calls)"
}

end_force_with_no_sandbox_refs_removes() {
    end_setup endnorefsforce
    $real_git -C "$sb_dir/work/codeo-113" config remote.sandbox-codeo-113.fetch '+refs/heads/*:refs/remotes/sandbox-codeo-113/*'
    sb_run end 113 --force
    ((sb_rc == 0)) || fail "exited $sb_rc: $sb_err"
    [[ "$(sb_calls)" == *$'\nsbx rm --force codeo-113'* ]] || fail "calls: $(sb_calls)"
}

end_lists_at_most_ten_commits() {
    end_setup endten
    end_commit 12
    sb_run end 113
    ((sb_rc == 1)) || fail "exited $sb_rc"
    [[ "$(grep -c 'unpushed' <<<"$sb_out")" == 10 ]] || fail "stdout was: $sb_out"
    [[ "$sb_out" == *"and 2 more"* ]] || fail "no 'and 2 more': $sb_out"
}

end_with_sbx_exe_fetches_with_git_exe_from_the_clone() {
    end_setup endwin windows
    rm "$sb_dir/bin/sbx"
    sb_run end 113
    ((sb_rc == 0)) || fail "exited $sb_rc: $sb_err"
    [[ "$(<"$sb_dir/git.exe_cwd")" == "$sb_dir/work/codeo-113" ]] || fail "git.exe ran in: $(<"$sb_dir/git.exe_cwd")"
    [[ "$(sb_calls)" == *$'\ngit.exe fetch sandbox-codeo-113\n'* ]] || fail "calls: $(sb_calls)"
    [[ "$(sb_calls)" == *$'\nsbx.exe rm --force codeo-113'* ]] || fail "calls: $(sb_calls)"
}

open_writes_the_title_and_opens_the_clone_folder() {
    sb_setup open
    echo 'codeo-113 claude running (detached)' >"$sb_dir/sandboxes"
    sb_run open 113
    ((sb_rc == 0)) || fail "exited $sb_rc: $sb_err"
    local want
    want=$'sbx ls\nsbx exec codeo-113 bash .devcontainer/scripts/window-title.sh\nsbx exec codeo-113 pwd\nssh -o BatchMode=yes -o ConnectTimeout=10 codeo-113.sbx -- true\ncode --folder-uri vscode-remote://ssh-remote+codeo-113.sbx/sandbox/clone'
    [[ "$(sb_calls)" == "$want" ]] || fail "calls: $(sb_calls)"
    # CODEO_CODE replaces code
    printf '#!/bin/bash\necho "mycode $*" >>"%s/calls"\n' "$sb_dir" >"$sb_dir/bin/mycode"
    chmod +x "$sb_dir/bin/mycode"
    : >"$sb_dir/calls"
    CODEO_CODE=mycode sb_run open 113
    ((sb_rc == 0)) || fail "CODEO_CODE exited $sb_rc: $sb_err"
    [[ "$(sb_calls)" == *$'\nmycode --folder-uri vscode-remote://ssh-remote+codeo-113.sbx/sandbox/clone' ]] || fail "CODEO_CODE calls: $(sb_calls)"
    [[ "$(sb_calls)" != *$'\ncode '* ]] || fail "code also ran"
}

open_starts_a_stopped_sandbox_detached() {
    sb_setup openstopped
    echo 'codeo-113 claude stopped' >"$sb_dir/sandboxes"
    sb_run open 113
    ((sb_rc == 0)) || fail "exited $sb_rc: $sb_err"
    [[ "$(sb_calls | sed -n 2p)" == "sbx run -d --name codeo-113" ]] || fail "calls: $(sb_calls)"
    [[ "$(sb_calls | sed -n 3p)" == "sbx exec codeo-113 bash .devcontainer/scripts/window-title.sh" ]] || fail "calls: $(sb_calls)"
}

open_on_a_detached_sandbox_runs_nothing_more() {
    sb_setup opendetached
    echo 'codeo-113 claude running (detached)' >"$sb_dir/sandboxes"
    sb_run open 113
    ((sb_rc == 0)) || fail "exited $sb_rc: $sb_err"
    [[ "$(sb_calls)" != *"sbx run"* ]] || fail "calls: $(sb_calls)"
}

a_failed_run_d_is_one_line() {
    sb_setup runfail
    echo 'codeo-113 claude stopped' >"$sb_dir/sandboxes"
    : >"$sb_dir/runfail"
    sb_run open 113
    ((sb_rc == 1)) || fail "exited $sb_rc"
    [[ "$sb_err" == *"run -d --name codeo-113"* ]] || fail "stderr was: $sb_err"
    [[ "$(sb_err_lines)" == 1 ]] || fail "stderr not one line: $sb_err"
    [[ "$(sb_calls)" != *$'\ncode '* ]] || fail "code ran: $(sb_calls)"
}

issue_with_a_failed_run_d_is_one_line() {
    sb_setup issuerunfail
    mkdir -p "$sb_dir/work/codeo-113/.git"
    echo 'codeo-113 claude stopped' >"$sb_dir/sandboxes"
    : >"$sb_dir/runfail"
    sb_run issue 113 fix/x
    ((sb_rc == 1)) || fail "exited $sb_rc"
    [[ "$sb_err" == *"run -d --name codeo-113"* ]] || fail "stderr was: $sb_err"
    [[ "$(sb_err_lines)" == 1 ]] || fail "stderr not one line: $sb_err"
}

open_on_a_missing_sandbox_names_the_command_that_creates_it() {
    sb_setup openmissing
    sb_run open 113
    ((sb_rc == 1)) || fail "exited $sb_rc"
    [[ "$sb_err" == *"codeo-sandbox.sh issue 113 <branch>"* ]] || fail "stderr was: $sb_err"
    [[ "$(sb_err_lines)" == 1 ]] || fail "stderr not one line: $sb_err"
    [[ "$(sb_calls)" != *exec* ]] || fail "calls: $(sb_calls)"
    sb_run shell 113
    ((sb_rc == 1)) || fail "shell exited $sb_rc"
    [[ "$sb_err" == *"codeo-sandbox.sh issue 113 <branch>"* ]] || fail "shell stderr was: $sb_err"
}

open_without_ssh_setup_says_to_run_setup_ssh() {
    sb_setup opennossh
    echo 'codeo-113 claude running' >"$sb_dir/sandboxes"
    : >"$sb_dir/sshfail"
    sb_run open 113
    ((sb_rc == 1)) || fail "exited $sb_rc"
    [[ "$sb_err" == "codeo-sandbox: codeo-113.sbx does not resolve over SSH: run sbx setup ssh, then open again" ]] || fail "stderr was: $sb_err"
    [[ "$(sb_calls)" != *$'\ncode '* ]] || fail "code ran: $(sb_calls)"
    SB_SBX=sbx.exe sb_run open 113
    ((sb_rc == 1)) || fail "sbx.exe exited $sb_rc"
    [[ "$sb_err" == *"run sbx.exe setup ssh"* ]] || fail "sbx.exe stderr was: $sb_err"
    [[ "$(sb_calls)" == *"ssh.exe -o BatchMode=yes -o ConnectTimeout=10 codeo-113.sbx -- true"* && "$(sb_calls)" != *cmd.exe* ]] || fail "sbx.exe calls: $(sb_calls)"
}

open_with_sbx_exe_launches_through_cmd_exe() {
    sb_setup opencmd
    echo 'codeo-113 claude running' >"$sb_dir/sandboxes"
    SB_SBX=sbx.exe sb_run open 113
    ((sb_rc == 0)) || fail "exited $sb_rc: $sb_err"
    [[ "$(sb_calls)" == *$'\nssh.exe -o BatchMode=yes -o ConnectTimeout=10 codeo-113.sbx -- true\ncmd.exe /c code --folder-uri vscode-remote://ssh-remote+codeo-113.sbx/sandbox/clone' ]] || fail "calls: $(sb_calls)"
    [[ "$(sb_calls)" != *$'\ncode '* ]] || fail "code ran directly: $(sb_calls)"
    if [[ -d /mnt/c ]]; then
        [[ "$(<"$sb_dir/cmd_cwd")" == /mnt/c ]] || fail "cmd.exe ran in $(<"$sb_dir/cmd_cwd")"
    fi
}

open_checks_ssh_without_prompting() {
    sb_setup openbatch
    echo 'codeo-113 claude running' >"$sb_dir/sandboxes"
    sb_run open 113
    ((sb_rc == 0)) || fail "exited $sb_rc: $sb_err"
    [[ "$(sb_calls)" == *$'\nssh -o BatchMode=yes -o ConnectTimeout=10 codeo-113.sbx'* ]] || fail "calls: $(sb_calls)"
}

open_percent_encodes_the_folder_path() {
    sb_setup openenc
    echo 'codeo-113 claude running' >"$sb_dir/sandboxes"
    echo '/wsl.localhost/U/home/a b/codeo-113' >"$sb_dir/sbxpwd"
    sb_run open 113
    ((sb_rc == 0)) || fail "exited $sb_rc: $sb_err"
    [[ "$(sb_calls)" == *$'\ncode --folder-uri vscode-remote://ssh-remote+codeo-113.sbx/wsl.localhost/U/home/a%20b/codeo-113' ]] || fail "calls: $(sb_calls)"
}

issue_with_no_lock_says_to_start_the_workflow() {
    sb_setup nolock
    echo codeo-home >"$sb_dir/lockname"
    sb_run issue 113 fix/x
    local want='todo: the sandbox is codeo-113 but its clone holds no workflow lock: run /codeo:init #113 on its branch, then issue 113 <branch> again'
    [[ "$sb_out" == *"$want"* ]] || fail "stdout was: $sb_out"
    [[ "$(grep -c '^todo:' <<<"$sb_out")" == 1 ]] || fail "not exactly one todo: $sb_out"
}

issue_takes_the_identity_from_the_host_gitconfig() {
    sb_setup gitcfg
    mkdir -p "$sb_dir/home" "$sb_dir/work/codeo-113/.git"
    printf '[user]\n\tname = Cfg Dev\n\temail = cfg@x.test\n' >"$sb_dir/home/.gitconfig"
    unset GIT_AUTHOR_NAME GIT_AUTHOR_EMAIL
    HOME="$sb_dir/home" GIT_CONFIG_GLOBAL="$sb_dir/home/.gitconfig" SB_REAL_GIT="$real_git" sb_run issue 113 fix/x
    [[ "$(sb_calls)" == *'env CODEO_CMD_MODE=1 GIT_AUTHOR_NAME=Cfg Dev GIT_AUTHOR_EMAIL=cfg@x.test bash .devcontainer'* ]] || fail "calls: $(sb_calls)"
}

shell_execs_bash_in_the_clone() {
    sb_setup shell
    echo 'codeo-113 claude running' >"$sb_dir/sandboxes"
    sb_run shell 113 </dev/null
    ((sb_rc == 0)) || fail "exited $sb_rc: $sb_err"
    [[ "$(sb_calls | tail -n 1)" == "sbx exec -i codeo-113 bash -l" ]] || fail "calls: $(sb_calls)"
    if command -v script >/dev/null 2>&1; then
        : >"$sb_dir/calls"
        echo 'codeo-113 claude running' >"$sb_dir/sandboxes"
        script -qec "env -u CODEO_SBX PATH='$sb_dir/bin:/usr/bin:/bin' '$bash_abs' '$script' shell 113" /dev/null >/dev/null 2>&1 || true
        [[ "$(sb_calls | tail -n 1)" == "sbx exec -it codeo-113 bash -l" ]] || fail "tty calls: $(sb_calls)"
    fi
}

docs_readme_documents_each_sub_command() {
    local readme="$repo/.sbx/README.md" sub
    [[ -f "$readme" ]] || { fail "no .sbx/README.md"; return 0; }
    for sub in issue open shell end; do
        grep -Eq "^\|.*codeo-sandbox\.sh $sub\b" "$readme" || fail "no table row for $sub"
    done
}

docs_readme_says_issue_and_open_run_detached() {
    local sec
    sec=$(sed -n '/^## Stopped sandboxes/,/^## /p' "$repo/.sbx/README.md")
    [[ "$sec" == *'run -d'* && "$sec" == *'`issue`'* && "$sec" == *'`open`'* ]] || fail "section was: $sec"
}

docs_readme_gives_the_download_line() {
    grep -Fq 'curl -fsSL -o codeo-sandbox.sh https://raw.githubusercontent.com/kbajpai/codeo/main/.sbx/codeo-sandbox.sh' \
        "$repo/.sbx/README.md" 2>/dev/null || fail "the download line is missing"
}

docs_readme_gives_the_extension_route() {
    local readme="$repo/.sbx/README.md" s
    for s in 'sbx policy allow network "*.gallery.vsassets.io,*.gallerycdn.vsassets.io"' \
        '"remote.SSH.defaultExtensions": ["anthropic.claude-code", "timonwong.shellcheck", "bierner.markdown-mermaid"]' \
        'sbx policy rm network --resource' 'balanced'; do
        grep -Fq -- "$s" "$readme" 2>/dev/null || fail "the README does not hold: $s"
    done
    # Anchor: the bullets that name .sbx/codeo-sandbox.sh and the sbx policy allow network rule, found by content, not by line.
    local bullets
    bullets=$(grep -E '^- .*\.sbx/codeo-sandbox\.sh' "$repo/CHANGELOG.md" | grep -F 'sbx policy allow network')
    [[ -n "$bullets" ]] || fail "no CHANGELOG bullet names .sbx/codeo-sandbox.sh and the sbx policy allow network rule"
    [[ "$bullets" != *'with the extensions from the user setting `remote.SSH.defaultExtensions`;'* ]] ||
        fail "the CHANGELOG bullet still says the extensions come from remote.SSH.defaultExtensions alone"
    [[ "$bullets" == *'which needs a one-time `sbx policy allow network` rule'* ]] ||
        fail "the CHANGELOG bullet does not say the extension route needs a one-time sbx policy allow network rule"
}

docs_readme_says_end_replaces_the_docker_rm_line() {
    grep -Eq 'end <N>.*replaces the `docker rm' "$repo/.sbx/README.md" 2>/dev/null ||
        fail "the README does not say end replaces the docker rm line"
}

docs_readme_states_the_stops() {
    grep -Fxq '## Stopped sandboxes' "$repo/.sbx/README.md" 2>/dev/null || fail "no Stopped sandboxes section"
}

docs_readme_says_how_to_move_the_pin() {
    grep -Eq '\.sbx/claude-image.*CHANGELOG|CHANGELOG.*\.sbx/claude-image' "$repo/.sbx/README.md" 2>/dev/null ||
        fail "no README line has both .sbx/claude-image and CHANGELOG"
}

docs_readme_says_where_the_pin_is_read() {
    local readme="$repo/.sbx/README.md" s
    for s in 'CODEO_SBX_IMAGE' 'codeo-<N>/.sbx/claude-image' 'origin/HEAD'; do
        grep -Fq -- "$s" "$readme" 2>/dev/null || fail "the README does not name $s"
    done
}

docs_readme_says_where_forced_refs_go() {
    grep -Fq 'refs/codeo/ended/codeo-<N>/' "$repo/.sbx/README.md" 2>/dev/null || fail "the README does not name refs/codeo/ended/codeo-<N>/"
}

docs_readme_says_how_a_unreadable_sandbox_is_removed() {
    grep -Fq 'sbx rm --force codeo-<N>' "$repo/.sbx/README.md" 2>/dev/null ||
        fail "the README does not name sbx rm --force codeo-<N> for a sandbox end cannot read"
}

docs_readme_says_the_marker_names_the_sandbox() {
    grep -Fq 'sandbox: codeo-<N>' "$repo/.sbx/README.md" 2>/dev/null ||
        fail "the README does not say the lock takes sandbox: codeo-<N>"
}

docs_readme_names_codeo_code() {
    grep -Fq 'CODEO_CODE' "$repo/.sbx/README.md" 2>/dev/null || fail "the README does not name CODEO_CODE"
}

docs_the_hand_off_says_whichever_route() {
    local f="$repo/.codeo/overlays/init.md"
    grep -Fq 'Whichever route' "$f" || fail "init overlay lacks 'Whichever route'"
    ! grep -Fq 'Either way' "$f" || fail "init overlay still says 'Either way'"
}

docs_evaluation_page_names_the_script_as_it_is() {
    ! grep -Fq 'does not exist yet' "$repo/docs/dev-environment-sbx-evaluation.md" || fail "the evaluation page says the script does not exist yet"
}

docs_changelog_names_the_sandbox_route() {
    grep -Eq '^- .*\.sbx/codeo-sandbox\.sh.*\(#99' "$repo/CHANGELOG.md" || fail "no CHANGELOG bullet for the sandbox route"
}

docs_the_hand_off_names_the_third_route() {
    grep -Fq 'bash codeo-sandbox.sh issue <N> <branch>' "$repo/.codeo/overlays/init.md" || fail "init overlay lacks the sandbox route"
    grep -Fq '.sbx/README.md' "$repo/.devcontainer/README.md" || fail "the dev container README does not point at .sbx/README.md"
}

cases=(
    usage_without_arguments_exits_2
    bad_numbers_and_branches_exit_2_before_any_call
    no_sbx_is_one_line
    sbx_is_preferred_over_sbx_exe
    codeo_sbx_overrides_both
    sandbox_state_reads_the_ls_rows
    sandbox_state_ignores_a_row_with_fewer_than_three_columns
    a_failed_ls_stops_issue_with_one_line
    the_script_is_committed_executable_with_a_bash_shebang
    config_suite_covers_the_sandbox_folder
    issue_clones_the_branch_on_the_host
    issue_refuses_a_host_clone_on_another_branch
    issue_refuses_a_folder_that_is_not_a_clone
    issue_adds_the_windows_trust_line_once
    issue_skips_the_windows_trust_with_linux_sbx
    issue_without_git_exe_prints_the_trust_command
    issue_without_wsl_distro_name_prints_the_trust_todo
    issue_creates_with_the_limits
    issue_creates_at_the_pinned_image
    a_pin_that_is_not_a_digest_is_refused
    the_pin_file_is_a_digest
    issue_reads_the_pin_from_the_clone
    issue_reads_the_pin_from_the_default_branch_when_the_branch_has_none
    issue_without_any_pin_is_one_line
    issue_pin_override_wins_over_the_clone
    issue_fast_forwards_a_stale_clone_before_creating
    issue_refuses_a_clone_that_cannot_fast_forward
    issue_refuses_when_origin_has_no_branch
    issue_leaves_the_clone_alone_when_the_sandbox_exists
    issue_runs_the_start_script_with_the_identity
    issue_rerun_on_an_existing_sandbox_creates_nothing
    issue_leaves_the_sandbox_running_detached
    issue_writes_the_sandbox_marker
    issue_names_the_next_step_when_the_start_script_fails
    issue_rerun_needs_no_pin
    issue_name_that_disagrees_with_the_lock_is_one_todo
    sandbox_path_prints_the_working_folder
    open_writes_the_title_and_opens_the_clone_folder
    open_starts_a_stopped_sandbox_detached
    open_on_a_detached_sandbox_runs_nothing_more
    a_failed_run_d_is_one_line
    issue_with_a_failed_run_d_is_one_line
    open_on_a_missing_sandbox_names_the_command_that_creates_it
    open_without_ssh_setup_says_to_run_setup_ssh
    open_with_sbx_exe_launches_through_cmd_exe
    open_checks_ssh_without_prompting
    open_percent_encodes_the_folder_path
    issue_with_no_lock_says_to_start_the_workflow
    issue_takes_the_identity_from_the_host_gitconfig
    shell_execs_bash_in_the_clone
    end_with_nothing_to_lose_removes_the_sandbox
    end_with_an_unpushed_commit_removes_nothing
    end_force_removes_and_says_where_the_commits_are
    end_with_uncommitted_changes_removes_nothing
    end_with_a_stash_removes_nothing
    end_on_a_detached_head_removes_nothing
    end_with_unpushed_and_uncommitted_lists_both
    end_force_with_uncommitted_work_says_it_is_not_kept
    end_with_a_failed_status_check_removes_nothing
    end_with_crlf_status_is_clean
    end_on_a_crlf_detached_head_removes_nothing
    end_with_crlf_status_and_stash_lines_prints_no_cr
    end_with_nothing_to_lose_deletes_the_sandbox_refs
    end_force_sets_the_refs_aside
    end_force_does_not_overwrite_refs_set_aside_earlier
    a_second_sandbox_for_the_number_starts_clean
    end_after_a_squash_merge_removes_the_sandbox
    end_lists_a_commit_made_after_the_pull_request_head
    end_with_a_failed_pull_request_fetch_removes_nothing
    end_without_origin_removes_nothing
    end_with_a_failed_sandbox_fetch_removes_nothing
    end_starts_a_stopped_sandbox_first
    end_names_a_way_out_when_a_stopped_sandbox_cannot_start
    end_on_a_missing_sandbox_is_one_line
    end_without_the_clone_is_one_line
    end_with_no_sandbox_refs_removes_nothing
    end_force_with_no_sandbox_refs_removes
    end_lists_at_most_ten_commits
    end_with_sbx_exe_fetches_with_git_exe_from_the_clone
    docs_readme_documents_each_sub_command
    docs_readme_says_issue_and_open_run_detached
    docs_readme_gives_the_download_line
    docs_readme_gives_the_extension_route
    docs_readme_says_end_replaces_the_docker_rm_line
    docs_readme_states_the_stops
    docs_readme_says_how_to_move_the_pin
    docs_readme_says_where_the_pin_is_read
    docs_readme_says_where_forced_refs_go
    docs_readme_says_how_a_unreadable_sandbox_is_removed
    docs_readme_says_the_marker_names_the_sandbox
    docs_readme_names_codeo_code
    docs_the_hand_off_says_whichever_route
    docs_evaluation_page_names_the_script_as_it_is
    docs_changelog_names_the_sandbox_route
    docs_the_hand_off_names_the_third_route
)

for current in "${cases[@]}"; do
    "$current"
done

if ((failures > 0)); then
    exit 1
fi
echo "all cases passed"
