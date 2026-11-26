#!/usr/bin/env bash
# Proves the csharp-angular example end to end on a host that has Docker: the neutral template image builds,
# codeo's wizard adopts the containers into a fresh clone of a throwaway repository seeded with the example,
# and an issue container started from that repository runs the example's three suites (api, web, k8s).
# Runs on macOS, Linux or WSL2 under bash 3.2 or newer. Run it from a checkout of codeo:
#
#   bash examples/csharp-angular/scripts/host-run.sh <owner>/<repo>
#
# Prerequisites
#   - Docker, running (docker info answers), plus git, gh (logged in: gh auth status) and jq on PATH.
#   - <owner>/<repo> is an existing, PUBLIC, otherwise empty throwaway GitHub repository you can push to. It must
#     be public because the container route builds the image from, and clones, the repository's GitHub URL
#     without credentials.
#   - web/ was generated beforehand with examples/csharp-angular/scripts/generate-web.sh (needs Node); without
#     examples/csharp-angular/web/angular.json the web suite cannot run and this script stops.
#   - This script itself runs under bash 3.2, but doctor (which the wizard runs here) needs bash 4.3 for its deps check,
#     so a bash 3.2 host sees "fail deps", which this script accepts and prints. For a clean doctor run it with a newer
#     bash, e.g. Homebrew's: /opt/homebrew/bin/bash examples/...
#   - Doctor runs on THIS host, and these of its failures are accepted as expected: ruleset (a fresh repository has
#     no branch ruleset), suites "not installed or unset" (dotnet, npm or kubectl not on this host; the container
#     run proves them), deps and superpowers (not installed on this host). Any other fail stops the run; the ones
#     that occurred are printed as "host-run: note: expected doctor failures: ...".
#   - A re-run needs a fresh empty repository, and the container shopdemo-1 removed first (the removal commands this
#     script prints at the end), because codeo-container.sh refuses an existing container.
#
# The script ignores CODEO_CONTEXT, CODEO_REPO_URL, CODEO_RAW_URL, CODEO_TRACK and CODEO_HOME: it unsets them,
# printing which were set, because they would redirect the throwaway run to another repository or directory.
#
# Steps (each prints "host-run: ok <step>" or "host-run: FAIL <step>"; the first FAIL stops the run with exit 1)
#   neutral image builds       docker build of templates/containers/.devcontainer (tag codeo-host-run-neutral)
#   work clone                 gh repo clone into a temporary directory; an empty repository gets a README.md on
#                              main, pushed, and origin/HEAD set (the wizard reads the base branch from it)
#   example copied             .devcontainer/Dockerfile (before the wizard, so the seed is kept), api/, k8s/,
#                              scripts/run-suites.sh and web/
#   wizard                     this checkout's scripts/codeo-init.sh --yes --skip-install --env containers
#                              --codename shopdemo, one --suite per entry of codeo-suites.json. Exit 1 is accepted
#                              only when its fail lines are among the expected host-dependent ones listed above
#                              (any other fail stops the run)
#   committed and pushed       git add -A, commit, push main, push the branch host-run/1
#   issue container ...        .devcontainer/codeo-container.sh issue 1 host-run/1 --yes (from the work clone), then a
#                              toolchain check (dotnet, node, kubectl) in the container, then
#                              docker exec shopdemo-1 bash scripts/run-suites.sh; ok only when it exits 0 and
#                              printed "suite: api ok", "suite: web ok" and "suite: k8s ok"
# It ends with doctor's output for the work clone (expected fails: those listed above), then prints the
# commands that remove what it created and the work directory's path. Nothing is
# removed by this script.
set -euo pipefail

usage() {
    echo 'usage: bash examples/csharp-angular/scripts/host-run.sh <owner>/<repo>' >&2
    echo '  <owner>/<repo> is an existing, public, otherwise empty throwaway GitHub repository' >&2
    exit 2
}

# 0. Preflight. The argument first (builtins only), then the tools, one "fail" line on the first missing.
[[ $# -eq 1 ]] || usage
[[ $1 =~ ^[A-Za-z0-9][A-Za-z0-9_.-]*/[A-Za-z0-9_.-]+$ ]] || usage
slug=$1

# The CODEO_* overrides would point the clone, the image build or the container at another repository or directory.
ignored=
# ${ignored:+ } adds the separating space only once the list is non-empty.
for v in CODEO_CONTEXT CODEO_REPO_URL CODEO_RAW_URL CODEO_TRACK CODEO_HOME; do
    if [[ -n ${!v+x} ]]; then ignored="$ignored${ignored:+ }$v"; fi
    unset "$v"
done
[[ -z $ignored ]] || echo "host-run: note: ignoring $ignored"

preflight_fail() {
    echo "host-run: fail $1: $2"
    exit 1
}
command -v docker >/dev/null 2>&1 || preflight_fail docker 'not found on PATH'
docker info >/dev/null 2>&1 || preflight_fail docker 'docker info failed; start Docker and run this again'
command -v git >/dev/null 2>&1 || preflight_fail git 'not found on PATH'
command -v gh >/dev/null 2>&1 || preflight_fail gh 'not found on PATH'
gh auth status >/dev/null 2>&1 || preflight_fail gh 'not logged in; run gh auth login'
command -v jq >/dev/null 2>&1 || preflight_fail jq 'not found on PATH'

here=${BASH_SOURCE[0]%/*}
[[ $here != "${BASH_SOURCE[0]}" ]] || here=.
ex=$(cd "$here/.." && pwd)
root=$(cd "$ex/../.." && pwd)
name=shopdemo
branch=host-run/1

ok() { echo "host-run: ok $1"; }
fail() {
    echo "host-run: FAIL $1"
    exit 1
}
# step <name> <command...>: run the command; its failure is the step's FAIL.
step() {
    local label=$1
    shift
    "$@" || fail "$label"
}

# 1. The neutral image.
step 'neutral image builds' docker build -t codeo-host-run-neutral "$root/templates/containers/.devcontainer"
ok 'neutral image builds'

# 2. The work clone.
work=$(mktemp -d) || fail 'work directory'
repo=$work/$name
step 'work clone' gh repo clone "$slug" "$repo"
cd "$repo"
if ! git rev-parse --verify -q HEAD >/dev/null 2>&1; then
    printf '# %s\n' "$name" >README.md
    step 'work clone: first commit' git checkout -q -B main
    step 'work clone: first commit' git add README.md
    step 'work clone: first commit' git commit -q -m 'chore: first commit'
    step 'work clone: push main' git push -q -u origin main
    step 'work clone: origin/HEAD' git remote set-head origin main
fi
[[ $(git symbolic-ref --short HEAD 2>/dev/null) == main ]] || { echo "host-run: note: $slug's checked-out branch is not main; use an empty repository"; fail 'work clone'; }
ok "work clone $repo"

# copy_clean <dir>: copy the example's <dir> into the work clone without bin/, obj/ or node_modules/ (a tar pipe:
# rsync is not guaranteed, and this works with GNU and BSD tar on bash 3.2).
copy_clean() {
    (cd "$ex" && tar -cf - --exclude=bin --exclude=obj --exclude=node_modules "$1") | tar -xf -
}

# 3. The example, before the wizard so its Dockerfile seed is kept.
if [[ ! -f $ex/web/angular.json ]]; then
    echo 'host-run: note: web/ not generated; run examples/csharp-angular/scripts/generate-web.sh first'
    fail 'example copied'
fi
mkdir -p .devcontainer scripts
step 'example copied' cp "$ex/.devcontainer/Dockerfile" .devcontainer/Dockerfile
step 'example copied' copy_clean api
step 'example copied' cp -R "$ex/k8s" k8s
step 'example copied' cp "$ex/scripts/run-suites.sh" scripts/run-suites.sh
step 'example copied' copy_clean web
ok 'example copied'

# 4. The wizard. A suite is name:paths:build:test; name, paths and build are one colon-separated
#    field each (the build command cannot contain a colon; only the test command may), and the example's
#    commands hold none. Built with set -- so a command's spaces survive.
set -- --yes --skip-install --env containers --codename "$name"
suites=$(jq -r '.[] | [.name, (.paths | join(",")), .build, .test] | join(":")' "$ex/codeo-suites.json") || fail 'wizard: read codeo-suites.json'
[[ -n $suites ]] || fail 'wizard: codeo-suites.json has no suites'
while IFS= read -r line; do
    set -- "$@" --suite "$line"
done <<<"$suites"
log=$work/wizard.log
rc=0
bash "$root/scripts/codeo-init.sh" "$@" >"$log" 2>&1 || rc=$?
cat "$log"
# Doctor runs on THIS host, so these doctor fails are host-dependent and expected on a fresh adoption: ruleset (a
# new repository has none), suites "not installed or unset" naming commands (no dotnet, npm or kubectl here; an
# entry ending ":(no command)" is a real fault and is not accepted), deps (bash older than 4.3) and superpowers
# (not installed on this host). Every other fail, and any "init: fail", stops the run.
fails=$(grep -E '^(init: )?fail' "$log" || true)
others=$(printf '%s\n' "$fails" | grep -Ev '^$|^fail (ruleset|deps|superpowers)(:|$)|^fail suites: not installed or unset: ([^ ():]+:[^ ():]+ ?)+$' || true)
if [[ -n $others ]]; then
    echo 'host-run: note: only these doctor failures are accepted here: ruleset, suites (not installed or unset), deps, superpowers'
    fail 'wizard'
fi
case $rc in
    0) ;;
    1) [[ -n $fails ]] || fail 'wizard' ;;
    *) fail 'wizard' ;;
esac
[[ -z $fails ]] || printf 'host-run: note: expected doctor failures: %s\n' "$(printf '%s' "$fails" | cut -d: -f1 | sed 's/^fail //' | tr '\n' ' ')"
ok 'wizard adopted the containers'

# 5. Commit, push the base branch, push the issue branch.
step 'committed and pushed' git add -A
step 'committed and pushed' git commit -q -m 'chore: adopt codeo and the csharp-angular example'
step 'committed and pushed' git push -q origin main
step 'committed and pushed' git branch "$branch"
step 'committed and pushed' git push -q origin "$branch"
ok 'committed and pushed main and host-run/1'

# 6. The issue container builds from the repository on GitHub, then runs the suites.
step 'issue container' bash .devcontainer/codeo-container.sh issue 1 "$branch" --yes
if ! docker exec "$name-1" bash -c 'dotnet --version && node --version && kubectl version --client' >"$work/toolchain.log" 2>&1; then
    cat "$work/toolchain.log"
    echo 'host-run: FAIL issue container toolchain'
    echo "host-run: note: the image lacks the example's toolchain; it should have been built from the build context https://github.com/$slug.git#$branch:.devcontainer, but an image of this name that already existed is reused, not rebuilt; image id $(docker image inspect --format '{{.Id}}' "$name-dev:$name-1" 2>/dev/null || echo unknown), compare with: docker history $name-dev:$name-1; a CODEO_CONTEXT in the environment or a stale image is the usual cause (this script ignores CODEO_* itself, so a stale image is the more likely one)"
    exit 1
fi
ok 'issue container toolchain'
rc=0
docker exec -w "/workspaces/$name-1" "$name-1" bash scripts/run-suites.sh >"$work/suites.log" 2>&1 || rc=$?
cat "$work/suites.log"
[[ $rc -eq 0 ]] || fail 'issue container suites'
for s in api web k8s; do
    grep -qx "suite: $s ok" "$work/suites.log" || fail "issue container suites: no 'suite: $s ok'"
done
ok "issue container $name-1 ran the suites api web k8s"

# 7. Doctor, then what to remove. Nothing is removed here.
bash "$root/scripts/doctor.sh" || true
echo
echo "host-run: nothing was removed. To remove what this run created, first cd to the work clone, then run:"
echo "  cd $repo"
echo "  docker rm -f $name-1"
echo "  docker volume rm $name-1 $name-gh $name-git"
echo "  docker image rm $name-dev:$name-1 codeo-host-run-neutral"
echo "  rm -rf $work"
echo "host-run: work directory $work"
