#!/usr/bin/env bash
# Generates the example's Angular app into examples/csharp-angular/web. Run it once, on a host with Node;
# commit the result. Works from any directory: paths are resolved from this script's own location.
# Refuses (exit 1, nothing run) when web/angular.json already exists or web holds anything but .gitkeep.
#
#   generate-web.sh
set -euo pipefail

# The Angular major to generate. 20 is the newest major I know generates a Karma + Jasmine project by
# default, which is what the web suite (ng test --watch=false --browsers=ChromeHeadless) runs. Later
# majors may default to another runner; check `ng new` before raising this.
ANGULAR_CLI_MAJOR=20

repo=$(cd "$(dirname "${BASH_SOURCE[0]}")/../../.." && pwd)
rel=examples/csharp-angular/web
web="$repo/$rel"

command -v npx >/dev/null 2>&1 || { echo "generate-web: npx not found; install Node.js and run again" >&2; exit 1; }

if [[ -f $web/angular.json ]]; then
    echo "generate-web: $rel/angular.json already exists; nothing was run" >&2
    exit 1
fi
if [[ -d $web ]]; then
    for f in "$web"/* "$web"/.[!.]* "$web"/..?*; do
        [[ -e $f || -L $f ]] || continue
        [[ ${f##*/} == .gitkeep ]] && continue
        echo "generate-web: $rel is not empty; nothing was run" >&2
        exit 1
    done
fi

# ng new wants an empty directory; .gitkeep only held the place in git.
keep=
[[ -f $web/.gitkeep ]] && { rm "$web/.gitkeep"; keep=1; }
cd "$repo"
if ! npx --yes "@angular/cli@$ANGULAR_CLI_MAJOR" new web --defaults --skip-git --skip-install --directory "$rel"; then
    [[ -z $keep ]] || { mkdir -p "$web"; : >"$web/.gitkeep"; }
    echo "generate-web: ng new failed; partial output may remain in $rel and must be deleted before running again" >&2
    exit 1
fi

echo "generated: $rel"
