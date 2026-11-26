#!/usr/bin/env bash
# Exercises examples/csharp-angular: its suites merge into a project's config and doctor resolves them
# (with stub dotnet, npm and kubectl), its Dockerfile equals the template outside the toolchain section,
# scripts/run-suites.sh stops at the first failing suite, and no manifest names a codeo project.
# Makes no network call.
#
#   example.test.sh
#       Exits non-zero and names the first failing case; prints "all cases passed" otherwise.
set -euo pipefail

plugin_root=$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)
ex="$plugin_root/examples/csharp-angular"
work=$(mktemp -d)
trap 'rm -rf "$work"' EXIT
export HOME="$work/home"
mkdir -p "$HOME" "$work/bin"

fail() { echo "FAIL: $1" >&2; exit 1; }

# Stubs: gh always fails (only the suites line is asserted); the toolchain binaries log their arguments.
printf '#!/usr/bin/env bash\nexit 1\n' >"$work/bin/gh"
for t in dotnet npm kubectl; do
    printf '#!/usr/bin/env bash\necho "%s $*" >>"${STUB_LOG:-/dev/null}"\nexit "${%s_EXIT:-0}"\n' "$t" "STUB_$t" >"$work/bin/$t"
done
chmod +x "$work/bin"/*
export PATH="$work/bin:$PATH"

# A scratch project whose config carries the example's suites.
new_project() {
    local d="$work/$1"
    git init -q "$d"
    mkdir "$d/.codeo"
    jq -n --slurpfile s "$ex/codeo-suites.json" \
        '{schema:1,codename:"shop",repo:{owner:"acme-co",name:"shop"},baseBranch:"main",suites:$s[0]}' >"$d/.codeo/config.json"
    echo "$d"
}

suites_merge_into_a_config_and_doctor_resolves_them() {
    local d out
    [[ $(jq length "$ex/codeo-suites.json") -eq 3 ]] || fail "not three suites"
    d=$(new_project merged)
    out=$(cd "$d" && bash "$plugin_root/scripts/doctor.sh" 2>/dev/null || true)
    grep -q '^ok suites: 3 suite(s)' <<<"$out" || fail "suites not resolved: $(grep suites <<<"$out")"
}

the_dockerfile_extends_the_template_only_inside_its_section() {
    local strip='/^# ---- Project toolchain/,/^# ---- End project toolchain/d'
    diff <(sed "$strip" "$plugin_root/templates/containers/.devcontainer/Dockerfile") <(sed "$strip" "$ex/.devcontainer/Dockerfile") >"$work/dfdiff" ||
        fail "the example's Dockerfile differs from the template outside the toolchain section: $(cat "$work/dfdiff")"
    grep -q '^# ---- Project toolchain' "$ex/.devcontainer/Dockerfile" || fail "toolchain marker missing"
}

run_suites_stops_at_the_first_failure() {
    local d out
    d=$(new_project runs)
    out=$(cd "$d" && bash "$ex/scripts/run-suites.sh" 2>&1) || fail "all-stubs-passing run failed: $out"
    grep -q 'suite: k8s ok' <<<"$out" || fail "no pass line for the last suite: $out"
    if out=$(cd "$d" && STUB_dotnet_EXIT=1 bash "$ex/scripts/run-suites.sh" 2>&1); then fail "a failing suite exited 0"; fi
    grep -q 'suite: api FAIL' <<<"$out" || fail "failure not named: $out"
    ! grep -q 'suite: web' <<<"$out" || fail "ran past the failure: $out"
}

the_manifests_name_no_codeo_project() {
    local hits
    hits=$(grep -rInE 'kbajpai|codeo-([0-9]|<N>)' "$ex" || true)
    [[ -z $hits ]] || fail "a codeo name remains: $hits"
}

for c in suites_merge_into_a_config_and_doctor_resolves_them the_dockerfile_extends_the_template_only_inside_its_section \
    run_suites_stops_at_the_first_failure the_manifests_name_no_codeo_project; do
    "$c"
done
echo "all cases passed"
