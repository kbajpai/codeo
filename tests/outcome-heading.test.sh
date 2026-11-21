#!/usr/bin/env bash
# Feeds one qc.md, whose `## Outcome` heading is varied, to every reader of it, each pinned apart —
# in qc-verdict.sh, dossier-check.sh and inflight.sh — and checks each reads the heading exactly
# (text `Outcome` alone, trailing whitespace and CR allowed), and that all agree.
# Touches no real git config and makes no network call; `gh` is stubbed and "origin" is a scratch repo.
#
#   outcome-heading.test.sh
#       Exits non-zero and names the failing cases; prints "all cases passed" otherwise.
set -euo pipefail

plugin_src=$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)
fixture="$plugin_src/tests/fixtures/dossiers/good-basic"

export GIT_AUTHOR_NAME="Test" GIT_AUTHOR_EMAIL="test@example.com"
export GIT_COMMITTER_NAME="Test" GIT_COMMITTER_EMAIL="test@example.com"

scratch=$(mktemp -d)
trap 'rm -rf "$scratch"' EXIT
export HOME="$scratch/home"
mkdir -p "$HOME"

# A stub `gh` that answers every call as Not Found, and a github.sh stub, as inflight.test.sh does.
stub_bin="$scratch/bin"
mkdir -p "$stub_bin"
printf '#!/usr/bin/env bash\necho '"'"'{"message":"Not Found"}'"'"'\nexit 1\n' > "$stub_bin/gh"
chmod +x "$stub_bin/gh"
plugin="$scratch/plugin"
mkdir -p "$plugin"
cp -R "$plugin_src/scripts" "$plugin/scripts"
cp -R "$plugin_src/lib" "$plugin/lib"
cat > "$plugin/scripts/github.sh" <<'GHSTUB'
#!/usr/bin/env bash
echo '{"number":7,"labels":[],"assignees":[]}'
GHSTUB

failures=0
case_desc=
assert_eq() {
    local label=$1 want=$2 got=$3
    if [[ $want != "$got" ]]; then
        echo "FAIL: $case_desc — $label: want [$want] got [$got]"
        failures=$((failures + 1))
    fi
}

# qc_with <heading> <file>: good-basic's qc.md with its `## Outcome` line replaced by <heading>;
# the CRLF variant is chosen by the caller through crlf=1.
crlf=
qc_with() {
    awk -v h="$1" '$0 == "## Outcome" { print h; next } { print }' "$fixture/qc.md" > "$2"
    if [[ -n $crlf ]]; then sed -i 's/$/\r/' "$2"; fi
}

new_repo() {
    local dir
    dir=$(mktemp -d -p "$scratch")
    git -C "$dir" -c init.defaultBranch=main init -q
    git -C "$dir" config gc.auto 0
    git -C "$dir" config maintenance.auto false
    echo placeholder > "$dir/README.md"
    git -C "$dir" add README.md
    git -C "$dir" commit -q -m init
    echo "$dir"
}

recognised_by_qc_verdict() {
    local dir base out
    dir=$(new_repo)
    base=$(git -C "$dir" rev-parse HEAD)
    mkdir -p "$dir/.codeo/done/7"
    qc_with "$1" "$dir/.codeo/done/7/qc.md"
    git -C "$dir" add .codeo
    git -C "$dir" commit -q -m head
    out=$(cd "$dir" && bash "$plugin/scripts/qc-verdict.sh" "$base" HEAD 2>&1) || true
    [[ $out != *"no ### Round in ## Outcome"* ]]
}

# The two readers in dossier-check.sh are pinned apart. section_range finds the `## Outcome` section
# (a `qc.md [sections] missing` finding names it when absent); last_round_clear reads qc's last round,
# and only a dossier whose close.md opened a pull request is held to it (`[finished-qc-clear]`).
recognised_by_dossier_check_sections() {
    local dir out
    dir=$(mktemp -d -p "$scratch")
    cp "$fixture"/*.md "$dir/"
    rm "$dir/close.md"
    qc_with "$1" "$dir/qc.md"
    out=$(bash "$plugin/scripts/dossier-check.sh" "$dir" 2>&1) || true
    ! grep -qE 'qc\.md \[sections\] missing:.*## Outcome' <<< "$out"
}

recognised_by_dossier_check_clear() {
    local dir out
    dir=$(mktemp -d -p "$scratch")
    cp "$fixture"/*.md "$dir/"
    qc_with "$1" "$dir/qc.md"
    out=$(bash "$plugin/scripts/dossier-check.sh" "$dir" 2>&1) || true
    ! grep -qF '[finished-qc-clear]' <<< "$out"
}

# inflight_clone <dir>: a clone of an origin whose branch holds the dossier in <dir>/.codeo/7.
inflight_clone() {
    local origin=$1 clone
    git -C "$origin" add .codeo
    git -C "$origin" commit -q -m dossier
    git -C "$origin" checkout -q main
    clone=$(mktemp -d -p "$scratch")
    git clone -q "$origin" "$clone"
    mkdir -p "$clone/.codeo"
    printf '{"schema":1,"repo":{"owner":"o","name":"n"},"baseBranch":"main"}\n' > "$clone/.codeo/config.json"
    echo "$clone"
}

# inflight_with <qc heading> <close heading>: inflight.sh's human block for #7, whose dossier holds init,
# plan, an implement with a pending Outcome that records the send-back from close.md round 2, a qc.md
# with rounds 1 and 2 (round 2 clear) and a close.md whose round 2 is a send-back made at qc round 1.
inflight_with() {
    local origin clone step
    origin=$(new_repo)
    git -C "$origin" checkout -q -b feat/x
    mkdir -p "$origin/.codeo/7"
    for step in init plan; do
        printf '# %s\n\n## Outcome\n\nDone.\n' "$step" > "$origin/.codeo/7/$step.md"
    done
    printf '# implement\n\n## Outcome\n\n_Pending._\n\n## Log\n\n(send-back from close.md round 2)\n' \
        > "$origin/.codeo/7/implement.md"
    printf '# qc\n\n%s\n\n### Round 1\n\n**Verdict: back to /codeo:implement**\n\n### Round 2\n\n**Verdict: clear**\n' \
        "$1" > "$origin/.codeo/7/qc.md"
    printf '# close\n\n%s\n\n### Round 1 — pull request opened\n\n### Round 2 — review feedback\n\nqc round at review: 1\n' \
        "$2" > "$origin/.codeo/7/close.md"
    if [[ -n $crlf ]]; then sed -i 's/$/\r/' "$origin/.codeo/7/qc.md" "$origin/.codeo/7/close.md"; fi
    clone=$(inflight_clone "$origin")
    (cd "$clone" && PATH="$stub_bin:$PATH" bash "$plugin/scripts/inflight.sh" 2>/dev/null) || true
}

# last_step: the step column of the --tsv listing.
recognised_by_inflight_step() {
    local origin clone step out
    origin=$(new_repo)
    git -C "$origin" checkout -q -b feat/x
    mkdir -p "$origin/.codeo/7"
    for step in init plan implement; do
        printf '# %s\n\n## Outcome\n\nDone.\n' "$step" > "$origin/.codeo/7/$step.md"
    done
    qc_with "$1" "$origin/.codeo/7/qc.md"
    clone=$(inflight_clone "$origin")
    out=$(cd "$clone" && PATH="$stub_bin:$PATH" bash "$plugin/scripts/inflight.sh" --tsv 2>/dev/null) || true
    [[ $(printf '%s\n' "$out" | awk -F'\t' '$1 == 7 { print $4 }') == qc ]]
}

# verdict_of: the `verdict:` line, present only when qc.md's Outcome is read.
recognised_by_inflight_verdict() {
    [[ $(inflight_with "$1" "## Outcome" | grep -c '^  verdict:   round 2 — clear$') == 1 ]]
}

# waits_is <block> <unread>: status 0 when the block waits on /codeo:close (the reader found its
# heading), 1 when it waits on <unread> (it did not), 2 on anything else, which no heading may give.
waits_is() {
    local waits
    waits=$(grep '^  waits:' <<< "$1" || true)
    case $waits in
        "  waits:     /codeo:close") return 0 ;;
        "  waits:     $2") return 1 ;;
        *) return 2 ;;
    esac
}

# close_send_back: both headings varied. Read, the send-back is answered by qc's round 2 and the
# verdict sends the workflow to /codeo:close; unread, the pending implement leaves /codeo:implement.
recognised_by_inflight_send_back() {
    waits_is "$(inflight_with "$1" "$1")" /codeo:implement
}

# last_qc_round: close.md's heading is exact, qc.md's varies. The send-back is answered only when
# qc.md's last round (2) is read; unread, the workflow waits on /codeo:qc.
recognised_by_inflight_qc_round() {
    waits_is "$(inflight_with "$1" "## Outcome")" /codeo:qc
}

readers=(qc_verdict dossier_check_sections dossier_check_clear inflight_step inflight_verdict inflight_send_back inflight_qc_round)

# variant name, heading line, CRLF?, expected
check_variant() {
    local label=$1 heading=$2 want=$3 reader got rc answers= want_all=
    crlf=$4
    for reader in "${readers[@]}"; do
        rc=0
        "recognised_by_$reader" "$heading" || rc=$?
        case $rc in 0) got=yes ;; 1) got=no ;; *) got=other ;; esac
        case_desc="heading $label"
        assert_eq "$reader" "$want" "$got"
        answers+="$got "
    done
    case_desc="heading $label"
    for reader in "${readers[@]}"; do want_all+="$want "; done
    assert_eq "the readers agree" "$want_all" "$answers"
}

check_variant '## Outcome' '## Outcome' yes ""
check_variant '## Outcome with trailing spaces' '## Outcome   ' yes ""
check_variant '## Outcome with CRLF line endings' '## Outcome' yes 1
check_variant '## Outcomes' '## Outcomes' no ""
check_variant '## Outcome notes' '## Outcome notes' no ""
check_variant '## Outcome:' '## Outcome:' no ""

if ((failures)); then
    echo "$failures case(s) failed"
    exit 1
fi
echo "all cases passed"
