#!/usr/bin/env bash
# What role this checkout plays, and whether a codeo skill may run in it. The role comes from the
# clone folder (the container's Docker name, see folder-check.sh), the workflow lock and the branch,
# with the codename and the lock's issue number taken from container-name.sh. No container-engine
# command is run. A container is told from the host by the marker files /.dockerenv and /run/.containerenv.
#
#   role.sh [dir]
#       Prints one line: unguarded | home | issue:<N> | stale:<N> | stale:? | mismatch:<N>:<folder> | stray.
#         unguarded  not guarded: CLAUDE_CODE_REMOTE=true, or a container (a marker file exists:
#                    CODEO_DOCKERENV, default /.dockerenv, or CODEO_CONTAINERENV, default
#                    /run/.containerenv, which Podman creates) in a folder that is neither
#                    '<codename>-home' nor '<codename>-<digits>'.
#         issue:<N>  locked for N. In a container: in the folder '<codename>-<N>'. On the host: in any folder.
#         mismatch   in a container, locked for N, in any other folder.
#         home       no lock, on the base branch (baseBranch in .codeo/config.json, else main), in
#                    the folder '<codename>-home' (the host clone, or the home container).
#         stale      no lock otherwise: stale:<N> in a container's folder '<codename>-<N>', else stale:?
#                    (a container off the base branch, or the host '<codename>-home' off it).
#                    --check reads the clone's own dossier (.codeo) to say why, as lock.sh and claim.sh read it:
#                    finished (the base branch carries .codeo/done/<N>), stashed or abandoned (more parks than
#                    resumes), a lost lock (the workflow is live, an archive the base lacks included), or unknown;
#                    stale:? is a home checkout off the base branch.
#         stray      a host checkout that is neither home nor an issue's (no lock, not '<codename>-home').
#   role.sh --check <skill> [dir]
#       Exits 0 printing nothing when the skill may run here, 1 printing one refusal line when it
#       may not. The home-only skills (issue init triage cleanup) run on unguarded and home; the lock
#       skills (plan implement qc close) run on unguarded and issue:<N>; every other role refuses.
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

in_container=0
if [[ -e ${CODEO_DOCKERENV:-/.dockerenv} || -e ${CODEO_CONTAINERENV:-/run/.containerenv} ]]; then
    in_container=1
fi
branch_now=$(git -C "$dir" branch --show-current 2>/dev/null || true)

if [[ ${CLAUDE_CODE_REMOTE:-} == true ]]; then
    role=unguarded
elif ((in_container)) && [[ $suffix == "$folder" || ( $suffix != home && ! $suffix =~ ^[0-9]+$ ) ]]; then
    role=unguarded
elif [[ -n $lock ]]; then
    if ((! in_container)) || [[ $folder == "$codename-$lock" ]]; then role=issue:$lock; else role=mismatch:$lock:$folder; fi
elif [[ $suffix == home && $branch_now == "$base" ]]; then
    role=home
elif [[ $suffix =~ ^[0-9]+$ ]] && ((in_container)); then
    role=stale:$suffix
elif ((in_container)) || [[ $suffix == home ]]; then
    role='stale:?'
else
    role=stray
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
    unguarded) exit 0 ;;
    home) [[ $kind == home ]] && exit 0 ;;
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
        [[ $role != stale:\? ]] || state=offbase
        word=
        last=
        ref=
        if [[ -n $number ]]; then
            # The base branch's ref, as lock.sh find_issue picks it, without its fetch.
            ref=$base
            if git -C "$root" rev-parse -q --verify "refs/remotes/origin/$base" >/dev/null 2>&1; then
                ref=origin/$base
            fi
            if [[ -d $root/.codeo/done/$number ]] \
                && git -C "$root" cat-file -e "$ref:.codeo/done/$number" 2>/dev/null; then
                state=finished
            elif [[ -d $root/.codeo/done/$number || -d $root/.codeo/$number ]]; then
                # Archived with the pull request still open, or no archive at all: the workflow is live
                # unless the parks outnumber the resumes, counted as claim.sh --stash-live counts them.
                state=lost
                park_re='^### Round [0-9]+ — (.+ — )?(stashed|abandoned)([^[:alnum:]].*)?$'
                resume_re='^- .* — resumed: by .* after the (stash|abandon) of '
                parks=0
                resumes=0
                if [[ -f $root/.codeo/$number/close.md ]]; then
                    parks=$(sed 's/[[:space:]]*$//' "$root/.codeo/$number/close.md" | grep -cE "$park_re" || true)
                    last=$(sed 's/[[:space:]]*$//' "$root/.codeo/$number/close.md" | grep -E "$park_re" | tail -n 1 || true)
                fi
                if [[ -f $root/.codeo/$number/init.md ]]; then
                    resumes=$(sed 's/[[:space:]]*$//' "$root/.codeo/$number/init.md" | grep -cE "$resume_re" || true)
                fi
                if [[ ! -d $root/.codeo/done/$number ]] && ((parks > resumes)) && [[ $last =~ $park_re ]]; then
                    state=parked
                    word=${BASH_REMATCH[2]}
                fi
            fi
        fi
        head="/codeo:$skill can't run here:"
        case $state in
            finished)
                if [[ $kind == home ]]; then
                    echo "$head issue #$number is finished and this checkout is done (role $role); run it in a home checkout."
                else
                    echo "$head issue #$number is finished and this container is done (role $role); nothing more runs here, and /codeo:cleanup in a home checkout prints how to remove it."
                fi ;;
            parked)
                if [[ $kind == home ]]; then
                    echo "$head issue #$number's workflow was $word and this checkout holds no lock (role $role); run it in a home checkout."
                elif [[ $word == stashed ]]; then
                    echo "$head issue #$number's workflow was stashed and this container holds no lock (role $role); /codeo:init #$number in a home checkout is the way back, never the start script, and it opens a new container with this one's name, so remove this one on the host first, once git status here shows nothing unpushed (.devcontainer/README.md says how)."
                else
                    echo "$head issue #$number's workflow was abandoned and this container holds no lock (role $role); nothing more runs here, and it may hold the only copy of the work, so check that the branch is still on origin before removing it."
                fi ;;
            lost)
                if [[ $kind == home ]]; then
                    echo "$head this is issue #$number's checkout and it holds no lock (role $role); run it in a home checkout."
                else
                    echo "$head this is issue #$number's container, its workflow is live and it holds no lock (role $role); re-run bash .devcontainer/scripts/devcontainer-start.sh to take the lock."
                fi ;;
            offbase)
                if [[ $kind == home ]]; then
                    echo "$head this is a home checkout, but it is not on the base branch $base (role $role); switch back to $base and run it again."
                else
                    echo "$head this is a home checkout, off the base branch $base (role $role); the skill runs in the container of the issue it is for."
                fi ;;
            *)
                if [[ $kind == home ]]; then
                    echo "$head this clone holds no lock and no dossier says why (role $role); run it in a home checkout."
                else
                    echo "$head this clone holds no lock and no dossier says why (role $role); the skill runs in the container of the issue it is for."
                fi ;;
        esac
        exit 1 ;;
esac
if [[ $role == stray ]]; then
    echo "/codeo:$skill can't run here: this host checkout is neither the home clone (a folder named $codename-home on $base, holding no lock) nor an issue's (it holds no lock) (role stray); $([[ $kind == home ]] && echo "run it in a home checkout (the host clone named $codename-home, or the home container)" || echo "it runs in an issue's checkout")."
    exit 1
fi
if [[ $kind == home ]]; then
    where="a home checkout (the host clone named $codename-home, or the home container)"
elif [[ -n $number ]]; then
    where="issue #$number's container"
else
    where="an issue's checkout"
fi
about=
[[ -z $number ]] || about=" (issue #$number)"
echo "/codeo:$skill runs in $where, but this checkout's role is $role$about."
exit 1
