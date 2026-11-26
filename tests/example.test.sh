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
# STUB_<tool>_EXIT sets the exit status, STUB_<tool>_FAILON fails only when the tool's first argument matches
# (kubectl and dotnet take the phase second, npm names it in the arguments), STUB_<tool>_SWALLOW drains stdin.
printf '#!/usr/bin/env bash\nexit 1\n' >"$work/bin/gh"
for t in dotnet npm kubectl; do
    cat >"$work/bin/$t" <<STUB
#!/usr/bin/env bash
echo "$t \$*" >>"\${STUB_LOG:-/dev/null}"
[[ -z \${STUB_${t}_SWALLOW:-} ]] || cat >/dev/null
[[ -z \${STUB_${t}_FAILON:-} || " \$* " != *" \$STUB_${t}_FAILON "* ]] || exit 1
exit "\${STUB_${t}_EXIT:-0}"
STUB
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

api_directory_resolves_to_exactly_one_solution_that_lists_the_test_project() {
    local files p
    files=$(find "$ex/api" -maxdepth 1 -type f \( -name '*.sln' -o -name '*.slnx' -o -name '*.csproj' \))
    [[ $(wc -l <<<"$files") -eq 1 && $files == *.slnx ]] || fail "api/ must hold exactly one solution file, found: $files"
    for p in Api/Api.csproj Api.Tests/Api.Tests.csproj; do
        grep -q "Path=\"$p\"" "$files" || fail "solution does not list $p"
        [[ -f $ex/api/$p ]] || fail "$p does not exist"
    done
}

run_suites_does_not_let_a_suite_swallow_the_rest() {
    local d out
    d=$(new_project swallow)
    out=$(cd "$d" && STUB_dotnet_SWALLOW=1 bash "$ex/scripts/run-suites.sh" 2>&1) || fail "run failed: $out"
    grep -q 'suite: web ok' <<<"$out" && grep -q 'suite: k8s ok' <<<"$out" || fail "later suites skipped: $out"
}

run_suites_fails_when_a_test_phase_fails() {
    local d out
    d=$(new_project testfail)
    if out=$(cd "$d" && STUB_LOG="$work/log" STUB_dotnet_FAILON=test bash "$ex/scripts/run-suites.sh" 2>&1); then fail "failing test phase exited 0"; fi
    grep -q 'suite: api FAIL' <<<"$out" || fail "failure not named: $out"
    grep -q 'dotnet build api' "$work/log" || fail "build did not run first"
}

run_suites_passes_arguments_through_bash_c() {
    local d
    d=$(new_project args)
    : >"$work/log"
    (cd "$d" && STUB_LOG="$work/log" bash "$ex/scripts/run-suites.sh" >/dev/null 2>&1) || fail "run failed"
    grep -qx 'npm web test -- --watch=false --browsers=ChromeHeadless' <(sed 's/--prefix //' "$work/log") || fail "arguments not intact: $(cat "$work/log")"
}

run_suites_fails_on_invalid_config() {
    local d
    d=$(new_project bad)
    echo '{not json' >"$d/.codeo/config.json"
    if (cd "$d" && bash "$ex/scripts/run-suites.sh" >"$work/out" 2>&1); then fail "invalid JSON exited 0"; fi
    grep -q 'run-suites:' "$work/out" || fail "no reason given"
    echo '{"schema":1,"suites":[]}' >"$d/.codeo/config.json"
    if (cd "$d" && bash "$ex/scripts/run-suites.sh" >"$work/out" 2>&1); then fail "zero suites exited 0"; fi
}

the_manifests_name_no_codeo_project() {
    local hits
    hits=$(grep -rInE 'kbajpai|codeo-([0-9]|<N>)' "$ex" || true)
    [[ -z $hits ]] || fail "a codeo name remains: $hits"
}

generate_web_names_a_pinned_cli_and_refuses_an_existing_app() {
    local d="$work/gw" log="$work/gw.log" line
    mkdir -p "$d/examples" "$d/bin"
    cp -R "$ex" "$d/examples/csharp-angular"
    mkdir -p "$d/examples/csharp-angular/web"
    : >"$d/examples/csharp-angular/web/.gitkeep"
    printf '#!/usr/bin/env bash\necho "npx $*" >>"%s"\n' "$log" >"$d/bin/npx"
    chmod +x "$d/bin/npx"
    : >"$log"
    (cd "$work" && PATH="$d/bin:$PATH" bash "$d/examples/csharp-angular/scripts/generate-web.sh" >"$work/out" 2>&1) || fail "generate-web failed: $(cat "$work/out")"
    grep -qx 'generated: examples/csharp-angular/web' "$work/out" || fail "no generated line: $(cat "$work/out")"
    line=$(cat "$log")
    [[ $line =~ @angular/cli@[0-9]+ && $line == *' new web '* && $line == *--skip-install* && $line == *--directory* ]] || fail "unexpected npx call: $line"
    [[ $(wc -l <"$log") -eq 1 ]] || fail "npx ran more than once"
    # A second run with an app in place refuses and runs nothing.
    : >"$d/examples/csharp-angular/web/angular.json"
    : >"$log"
    if PATH="$d/bin:$PATH" bash "$d/examples/csharp-angular/scripts/generate-web.sh" >"$work/out" 2>&1; then fail "an existing app exited 0"; fi
    grep -qx 'generate-web: examples/csharp-angular/web/angular.json already exists; nothing was run' "$work/out" || fail "no refusal line: $(cat "$work/out")"
    [[ ! -s $log ]] || fail "npx ran despite the refusal: $(cat "$log")"
    # Without npx it stops with one line.
    rm "$d/examples/csharp-angular/web/angular.json"
    # PATH holds only the tools the script uses before its npx check (dirname), so npx is absent wherever a host installs it.
    mkdir -p "$work/tools"
    ln -sf "$(command -v dirname)" "$work/tools/dirname"
    if PATH="$work/tools" "$BASH" "$d/examples/csharp-angular/scripts/generate-web.sh" >"$work/out" 2>&1; then fail "missing npx exited 0"; fi
    grep -q '^generate-web: npx not found' "$work/out" || fail "no npx message: $(cat "$work/out")"
    # The same minimal PATH with a stub npx passes the npx check (here it then refuses on the existing app).
    : >"$d/examples/csharp-angular/web/angular.json"
    ln -sf "$d/bin/npx" "$work/tools/npx"
    if PATH="$work/tools" "$BASH" "$d/examples/csharp-angular/scripts/generate-web.sh" >"$work/out" 2>&1; then fail "an existing app exited 0 with npx present"; fi
    grep -q 'already exists; nothing was run' "$work/out" || fail "npx present but the script stopped elsewhere: $(cat "$work/out")"
}

the_dockerfile_points_chrome_bin_at_a_no_sandbox_wrapper() {
    local df="$ex/.devcontainer/Dockerfile" bin
    bin=$(sed -n 's/^ENV CHROME_BIN=//p' "$df")
    [[ -n $bin ]] || fail "no ENV CHROME_BIN"
    grep -q "$bin" <(grep -v '^ENV CHROME_BIN=' "$df") || fail "the Dockerfile never creates $bin"
    grep -E "$bin" "$df" | grep -v '^ENV' | grep -q -- '--no-sandbox' || fail "the wrapper $bin does not pass --no-sandbox"
}

host_run_refuses_without_docker_and_arguments() {
    local script="$ex/scripts/host-run.sh" tools="$work/host-run-tools" rc=0 bad
    # No argument: usage, exit 2 (checked before anything else).
    "$BASH" "$script" >"$work/out" 2>&1 || rc=$?
    [[ $rc -eq 2 ]] || fail "no argument exited $rc, not 2: $(cat "$work/out")"
    # PATH holds nothing: the script checks its argument and docker with builtins only, so docker is absent
    # wherever a host installs it.
    mkdir -p "$tools"
    rc=0
    PATH="$tools" "$BASH" "$script" owner/repo >"$work/out" 2>&1 || rc=$?
    [[ $rc -eq 1 ]] || fail "missing docker exited $rc, not 1: $(cat "$work/out")"
    [[ $(grep -c '^host-run: fail docker' "$work/out") -eq 1 ]] || fail "not exactly one docker line: $(cat "$work/out")"
    # An argument that is not owner/repo is refused before the tools are looked for.
    for bad in justarepo owner/repo/extra -owner/repo 'owner/re po' ''; do
        rc=0
        PATH="$tools" "$BASH" "$script" "$bad" >"$work/out" 2>&1 || rc=$?
        [[ $rc -eq 2 ]] || fail "argument '$bad' exited $rc, not 2: $(cat "$work/out")"
    done
    rc=0
    PATH="$tools" "$BASH" "$script" owner/repo extra >"$work/out" 2>&1 || rc=$?
    [[ $rc -eq 2 ]] || fail "two arguments exited $rc, not 2: $(cat "$work/out")"
}

for c in suites_merge_into_a_config_and_doctor_resolves_them the_dockerfile_extends_the_template_only_inside_its_section \
    run_suites_stops_at_the_first_failure api_directory_resolves_to_exactly_one_solution_that_lists_the_test_project \
    run_suites_does_not_let_a_suite_swallow_the_rest run_suites_fails_when_a_test_phase_fails run_suites_passes_arguments_through_bash_c \
    run_suites_fails_on_invalid_config the_manifests_name_no_codeo_project \
    generate_web_names_a_pinned_cli_and_refuses_an_existing_app the_dockerfile_points_chrome_bin_at_a_no_sandbox_wrapper \
    host_run_refuses_without_docker_and_arguments; do
    "$c"
done
echo "all cases passed"
