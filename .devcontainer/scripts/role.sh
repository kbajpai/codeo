#!/usr/bin/env bash
# What role this dev container plays, and whether a codeo skill may run in it. The role comes from the
# clone folder (the container's Docker name, see folder-check.sh), the workflow lock and the branch,
# with the codename and the lock's issue number taken from container-name.sh. No container-engine
# command is run.
#
#   role.sh [dir]
#       Prints one line: unguarded | home | issue:<N> | stale:<N> | stale:? | mismatch:<N>:<folder>.
#         unguarded  not a guarded container: CLAUDE_CODE_REMOTE=true, no CODEO_DOCKERENV file
#                    (default /.dockerenv), or a folder that is neither '<codename>-home' nor
#                    '<codename>-<digits>'.
#         issue:<N>  locked for N, in the folder '<codename>-<N>'.
#         mismatch   locked for N, in any other folder.
#         home       no lock, on the base branch (baseBranch in .codeo/config.json, else main), in
#                    the folder '<codename>-home'.
#         stale      no lock otherwise: stale:<N> in the folder '<codename>-<N>', else stale:?.
#                    --check reads the clone's own dossier (.codeo) to say why: finished, stashed, abandoned, a lost
#                    lock, or unknown.
#   role.sh --check <skill> [dir]
#       Exits 0 printing nothing when the skill may run here, 1 printing one refusal line when it
#       may not. The home-only skills (issue init triage cleanup) run on unguarded and home; the lock
#       skills (plan implement qc close) run on unguarded, issue:<N> and home (their own step 0
#       refuses with no lock); every other role refuses.
#   dir is anywhere inside the clone (default: the current directory). Exits 2 with one "role: ..."
#   line on stderr for an unknown skill (doctor and setup are not guarded) or a non-repository.
set -euo pipefail

here=$(dirname "${BASH_SOURCE[0]}")

die() { echo "role: $*" >&2; exit 2; }

skill=
if [[ ${1:-} == --check ]]; then
    skill=${2:-}
    shift 2 || die "--check needs a skill"
    case $skill in
        issue|init|triage|cleanup|plan|implement|qc|close) ;;
        *) die "unknown skill '$skill'" ;;
    esac
fi
dir=${1:-.}

root=$(git -C "$dir" rev-parse --show-toplevel 2>/dev/null) || die "$dir is not inside a git repository"
folder=$(basename "$root")
codename=$(bash "$here/container-name.sh" --codename "$dir") || die "container-name.sh failed for '$dir'"
want=$(bash "$here/container-name.sh" --docker "$dir") || die "container-name.sh failed for '$dir'"
lock=${want#"$codename-"}
[[ $lock != home ]] || lock=
base=$(jq -r '.baseBranch // empty' "$root/.codeo/config.json" 2>/dev/null || true)
[[ -n $base ]] || base=main
suffix=${folder#"$codename-"}

if [[ ${CLAUDE_CODE_REMOTE:-} == true || ! -e ${CODEO_DOCKERENV:-/.dockerenv} ]] \
    || [[ $suffix == "$folder" || ( $suffix != home && ! $suffix =~ ^[0-9]+$ ) ]]; then
    role=unguarded
elif [[ -n $lock ]]; then
    if [[ $folder == "$codename-$lock" ]]; then role=issue:$lock; else role=mismatch:$lock:$folder; fi
elif [[ $suffix == home && $(git -C "$dir" branch --show-current 2>/dev/null || true) == "$base" ]]; then
    role=home
elif [[ $suffix =~ ^[0-9]+$ ]]; then
    role=stale:$suffix
else
    role='stale:?'
fi

if [[ -z $skill ]]; then
    echo "$role"
    exit 0
fi

case $skill in
    issue|init|triage|cleanup) kind=home ;;
    *) kind=lock ;;
esac
case $role in
    unguarded|home) exit 0 ;;
    issue:*) [[ $kind == lock ]] && exit 0 ;;
esac

number=
case $role in
    stale:\?) ;;
    stale:*|mismatch:*) number=${role#*:}; number=${number%%:*} ;;
    issue:*) number=${role#*:} ;;
esac
case $role in
    stale:*)
        # What happened to the workflow, from this clone's own dossier (the state directory is .codeo).
        state=unknown
        word=
        if [[ -n $number ]]; then
            if [[ -d $root/.codeo/done/$number ]]; then
                state=finished
            elif [[ -d $root/.codeo/$number ]]; then
                state=lost
                park_re='^### Round [0-9]+ — (.+ — )?(stashed|abandoned)([^[:alnum:]].*)?$'
                last=
                if [[ -f $root/.codeo/$number/close.md ]]; then
                    last=$(grep -E '^### Round [0-9]+ ' "$root/.codeo/$number/close.md" | tail -n 1 || true)
                fi
                if [[ $last =~ $park_re ]]; then
                    state=parked
                    word=${BASH_REMATCH[2]}
                fi
            fi
        fi
        head="/codeo:$skill can't run here:"
        case $state in
            finished)
                if [[ $kind == home ]]; then
                    echo "$head issue #$number is finished and this container is done (role $role); run it in the home container."
                else
                    echo "$head issue #$number is finished and this container is done (role $role); nothing more runs here, and /codeo:cleanup in the home container prints how to remove it."
                fi ;;
            parked)
                if [[ $kind == home ]]; then
                    echo "$head issue #$number's workflow was $word and this container holds no lock (role $role); run it in the home container."
                else
                    echo "$head issue #$number's workflow was $word and this container holds no lock (role $role); /codeo:init #$number in the home container is the way back, never the start script."
                fi ;;
            lost)
                if [[ $kind == home ]]; then
                    echo "$head this is issue #$number's container and it holds no lock (role $role); run it in the home container."
                else
                    echo "$head this is issue #$number's container, its workflow is live and it holds no lock (role $role); re-run bash .devcontainer/scripts/devcontainer-start.sh to take the lock."
                fi ;;
            *)
                if [[ $kind == home ]]; then
                    echo "$head this clone holds no lock and no dossier says why (role $role); run it in the home container."
                else
                    echo "$head this clone holds no lock and no dossier says why (role $role); the skill runs in the container of the issue it is for."
                fi ;;
        esac
        exit 1 ;;
esac
if [[ $kind == home ]]; then
    where="the home container"
elif [[ -n $number ]]; then
    where="issue #$number's container"
else
    where="an issue's container"
fi
about=
[[ -z $number ]] || about=" (issue #$number)"
echo "/codeo:$skill runs in $where, but this container's role is $role$about."
exit 1
