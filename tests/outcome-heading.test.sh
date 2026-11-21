#!/usr/bin/env bash
# Feeds one qc.md, whose `## Outcome` heading is varied, to the three scripts that read it —
# qc-verdict.sh, dossier-check.sh and inflight.sh — and checks each reads the heading exactly
# (text `Outcome` alone, trailing whitespace and CR allowed), and that all three agree.
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

recognised_by_dossier_check() {
    local dir out
    dir=$(mktemp -d -p "$scratch")
    cp "$fixture"/*.md "$dir/"
    qc_with "$1" "$dir/qc.md"
    out=$(bash "$plugin/scripts/dossier-check.sh" "$dir" 2>&1) || true
    ! grep -qE 'qc\.md \[sections\] missing:.*## Outcome|\[finished-qc-clear\]' <<< "$out"
}

recognised_by_inflight() {
    local origin clone step out
    origin=$(new_repo)
    git -C "$origin" checkout -q -b feat/x
    mkdir -p "$origin/.codeo/7"
    for step in init plan implement; do
        printf '# %s\n\n## Outcome\n\nDone.\n' "$step" > "$origin/.codeo/7/$step.md"
    done
    qc_with "$1" "$origin/.codeo/7/qc.md"
    git -C "$origin" add .codeo
    git -C "$origin" commit -q -m dossier
    git -C "$origin" checkout -q main
    clone=$(mktemp -d -p "$scratch")
    git clone -q "$origin" "$clone"
    mkdir -p "$clone/.codeo"
    printf '{"schema":1,"repo":{"owner":"o","name":"n"},"baseBranch":"main"}\n' > "$clone/.codeo/config.json"
    out=$(cd "$clone" && PATH="$stub_bin:$PATH" bash "$plugin/scripts/inflight.sh" --tsv 2>/dev/null) || true
    [[ $(printf '%s\n' "$out" | awk -F'\t' '$1 == 7 { print $4 }') == qc ]]
}

# variant name, heading line, CRLF?, expected
check_variant() {
    local label=$1 heading=$2 want=$3 reader got answers=
    crlf=$4
    for reader in qc_verdict dossier_check inflight; do
        if "recognised_by_$reader" "$heading"; then got=yes; else got=no; fi
        case_desc="heading $label"
        assert_eq "$reader" "$want" "$got"
        answers+="$got "
    done
    case_desc="heading $label"
    assert_eq "the three readers agree" "$want $want $want " "$answers"
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
