#!/usr/bin/env bash
# Every GitHub call the pipeline's skills and scripts make, as plain REST through `gh api` —
# never gh issue/pr/run, which are GraphQL underneath and refused by a Claude Code on the web
# session's egress proxy regardless of token.
# A container's `gh` login and a web session's `GH_TOKEN` — required there, since `gh` makes no
# call at all without a token — both satisfy plain `gh api`, so this one script is the whole
# call surface in both hosts.
#
#   github.sh <verb> [args...]
#       Prints JSON (or plain text, one per line, for list verbs) on stdout and exits 0, or one
#       reason on stderr and exits non-zero. The repository is repo.owner/repo.name from the
#       project's .codeo/config.json.
#
#   Verbs: issue view|assignee-add|assignee-remove|search|list-all, issue-types (prints nothing
#   when the owner is a user, who has none), user login,
#   pr list-for-branch|view|reviews|comments|review-comments|checks|create|comment, run list,
#   workflow dispatch <workflow-file> <ref> (prints nothing on success; the ref must carry the
#   workflow file and the caller needs `actions: write`), label list.
set -euo pipefail

source "$(dirname "${BASH_SOURCE[0]}")/../lib/env.sh"
# Read in the calling shell (not inside $(...)) so an unusable config ends the script; the || exit
# covers a key that is merely absent, since codeo_cfg_required's exit would only end the subshell.
owner=$(codeo_cfg_required .repo.owner) || exit 1
name=$(codeo_cfg_required .repo.name) || exit 1
repo=$owner/$name
die() { echo "github: $*" >&2; exit 1; }

# GET /user, else $CODEO_GITHUB_LOGIN, else nothing — both `/user` and the org-level
# issue-types endpoint are refused on a web session's proxy credential regardless of token,
# because neither is scoped to this repository.
user_login() {
    local login
    if login=$(gh api user -q .login 2>/dev/null); then
        echo "$login"
    elif [[ -n ${CODEO_GITHUB_LOGIN:-} ]]; then
        echo "$CODEO_GITHUB_LOGIN"
    else
        echo "github: no login: GET /user was refused and \$CODEO_GITHUB_LOGIN is unset" >&2
        return 1
    fi
}

# REST's mergeable_state to the GraphQL-style token the close step's prose already names.
normalize_mergeable_state() {
    case $1 in
        behind) echo BEHIND ;;
        dirty) echo CONFLICTING ;;
        clean) echo CLEAN ;;
        blocked) echo BLOCKED ;;
        unstable) echo UNSTABLE ;;
        draft) echo DRAFT ;;
        *) echo UNKNOWN ;;
    esac
}

# The PR for a branch plus its review decision. A function so the temp file has one owner.
pr_list_for_branch() {
    local branch=$1 n decision=null
    # Not local: the trap fires at exit, when a local is gone, so the path is expanded by the
    # trap itself (single quotes) rather than baked into it now — a quote in $TMPDIR would end a
    # baked-in path early and leave the file behind.
    tmp=$(mktemp)
    # EXIT, not RETURN: die calls exit, which never fires a RETURN trap, and nothing else in this
    # script sets an EXIT trap for this one to clobber.
    trap 'rm -f "$tmp"' EXIT
    gh api -X GET "repos/$repo/pulls" -f "head=$owner:$branch" -f state=all \
        -q '.[0] | {number,html_url,state,merged_at,merge_commit_sha,head_sha:.head.sha,base_ref:.base.ref}' \
        > "$tmp" || die "pr list-for-branch $branch: GET failed"
    n=$(jq -r '.number // empty' "$tmp")
    if [[ -n $n ]]; then
        # -q runs per page, which would break group_by across pages, so page first and merge with
        # jq -s. Like GitHub's reviewDecision, only APPROVED / CHANGES_REQUESTED / DISMISSED count:
        # a later COMMENTED (or PENDING) review must not erase an approval, and a reviewer whose
        # last counting review was DISMISSED has no decision.
        decision=$(gh api --paginate "repos/$repo/pulls/$n/reviews" \
            | jq -rs 'add // []
                | map(select(.state == "APPROVED" or .state == "CHANGES_REQUESTED" or .state == "DISMISSED"))
                | group_by(.user.login) | map(sort_by(.submitted_at) | last.state)
                | if any(. == "CHANGES_REQUESTED") then "CHANGES_REQUESTED"
                  elif any(. == "APPROVED") then "APPROVED" else "null" end') \
            || die "pr list-for-branch $branch: could not read reviews for PR $n"
    fi
    jq --arg d "$decision" '. + {review_decision: ($d | if . == "null" then null else . end)}' "$tmp"
}

group=${1:-}; shift || true
case $group in
    issue)
        sub=${1:?issue subcommand}; shift
        case $sub in
            view)
                n=${1:?issue number}
                # Captured, then printed: gh api writes a failed call's error body to stdout, and a
                # failure must leave stdout empty with one reason on stderr.
                out=$(gh api "repos/$repo/issues/$n" \
                    -q '{number,title,state,closed_at,html_url,body,labels:[.labels[].name],assignees:[.assignees[].login]}') \
                    || die "issue $n: GET failed"
                printf '%s\n' "$out"
                ;;
            assignee-add)
                n=${1:?issue number}; login=${2:-$(user_login)} || exit 1
                gh api -X POST "repos/$repo/issues/$n/assignees" -f "assignees[]=$login" >/dev/null \
                    || die "issue $n: could not add assignee $login"
                ;;
            assignee-remove)
                n=${1:?issue number}; login=${2:-$(user_login)} || exit 1
                gh api -X DELETE "repos/$repo/issues/$n/assignees" -f "assignees[]=$login" >/dev/null \
                    || die "issue $n: could not remove assignee $login"
                ;;
            search)
                q=${1:?query}
                # /search/* is refused by a web session's proxy as not repository-scoped, whatever
                # the query, so on any failure the check is redone locally over the repository's
                # own issue list, which is scoped. Every word must appear (GitHub search ANDs
                # terms too), case-insensitively, in the title or body. The primary call is
                # captured so a refused call's error body never reaches stdout.
                if out=$(gh api -X GET "search/issues" -f "q=repo:$repo is:issue $q" \
                        -q '.items[] | {number,title,state}' 2>/dev/null); then
                    [[ -z $out ]] || printf '%s\n' "$out"
                else
                    echo "github: search refused; matched locally against the repository's issues" >&2
                    # gh's -q takes no --arg, so the query reaches the filter through the environment.
                    out=$(Q="$q" gh api -X GET "repos/$repo/issues" -f state=all --paginate \
                        -q '.[] | select(.pull_request == null)
                            | ((.title + " " + (.body // "")) | ascii_downcase) as $text
                            | select(all((env.Q | ascii_downcase | split(" "))[] | select(length > 0); . as $w | $text | contains($w)))
                            | {number,title,state}') \
                        || die "search failed"
                    [[ -z $out ]] || printf '%s\n' "$out"
                fi
                ;;
            list-all)
                out=$(gh api -X GET "repos/$repo/issues" -f state=all --paginate \
                    -q '.[] | select(.pull_request == null) | {number,title,state,body}') \
                    || die "issue list failed"
                [[ -z $out ]] || printf '%s\n' "$out"
                ;;
            *) die "unknown issue subcommand: $sub" ;;
        esac
        ;;
    issue-types)
        # A user-owned repository has no issue types and no org endpoint to ask, so the answer is
        # nothing rather than the fixed list. A failed lookup is not proof of a user: carry on as
        # for an org, whose own fallback below covers a refusal.
        if [[ $(gh api "users/$owner" -q .type 2>/dev/null || true) == User ]]; then
            exit 0
        fi
        if out=$(gh api "orgs/$owner/issue-types" -q '.[].name' 2>/dev/null); then
            printf '%s\n' "$out"
        else
            echo "github: orgs/$owner/issue-types refused; falling back to the fixed list" >&2
            printf '%s\n' Bug Feature Task
        fi
        ;;
    user)
        sub=${1:?user subcommand}; shift
        [[ $sub == login ]] || die "unknown user subcommand: $sub"
        user_login
        ;;
    pr)
        sub=${1:?pr subcommand}; shift
        case $sub in
            list-for-branch) pr_list_for_branch "${1:?branch}" ;;
            view)
                n=${1:?pr number}
                # One fetch, so state and mergeable come from the same moment.
                pr=$(gh api "repos/$repo/pulls/$n") || die "pr view $n: GET failed"
                [[ -n $pr ]] || die "pr view $n: empty response"
                # mergeable is JSON null while GitHub computes it; jq passes it through as null.
                state=$(jq -r '.mergeable_state // ""' <<<"$pr") || die "pr view $n: unreadable response"
                jq -n --arg s "$(normalize_mergeable_state "$state")" \
                    --argjson m "$(jq -c '.mergeable' <<<"$pr")" \
                    '{mergeable: $m, mergeStateStatus: $s}'
                ;;
            reviews) n=${1:?pr number}; out=$(gh api "repos/$repo/pulls/$n/reviews") || die "pr reviews $n: GET failed"; printf '%s\n' "$out" ;;
            comments) n=${1:?pr number}; out=$(gh api "repos/$repo/issues/$n/comments") || die "pr comments $n: GET failed"; printf '%s\n' "$out" ;;
            review-comments) n=${1:?pr number}; out=$(gh api "repos/$repo/pulls/$n/comments") || die "pr review-comments $n: GET failed"; printf '%s\n' "$out" ;;
            checks)
                n=${1:?pr number}
                sha=$(gh api "repos/$repo/pulls/$n" -q '.head.sha') || die "pr checks $n: could not read head sha"
                # -q runs per page, so each page emits its runs one per line and jq -s folds them
                # into the single array a caller expects.
                out=$(gh api --paginate "repos/$repo/commits/$sha/check-runs" -q '.check_runs[]') \
                    || die "pr checks $n: GET failed"
                jq -s '.' <<<"$out"
                ;;
            create)
                title=${1:?title}; body_file=${2:?body file}; head=${3:?head}; base=${4:?base}
                # Captured, then printed, like every read verb: a failed POST's error body must
                # not reach stdout, which close reads {number,html_url} from.
                out=$(gh api -X POST "repos/$repo/pulls" -f "title=$title" -F "body=@$body_file" \
                    -f "head=$head" -f "base=$base" -q '{number,html_url}') \
                    || die "pr create: POST failed"
                printf '%s\n' "$out"
                ;;
            comment)
                n=${1:?pr number}; body_file=${2:?body file}
                gh api -X POST "repos/$repo/issues/$n/comments" -F "body=@$body_file" >/dev/null \
                    || die "pr comment $n: POST failed"
                ;;
            *) die "unknown pr subcommand: $sub" ;;
        esac
        ;;
    run)
        sub=${1:?run subcommand}; shift
        [[ $sub == list ]] || die "unknown run subcommand: $sub"
        workflow=${1:?workflow file}; sha=${2:?commit sha}
        out=$(gh api -X GET "repos/$repo/actions/workflows/$workflow/runs" -f "head_sha=$sha" \
            -q '.workflow_runs[] | {status,conclusion,html_url}') || die "run list: GET failed"
        [[ -z $out ]] || printf '%s\n' "$out"
        ;;
    workflow)
        sub=${1:?workflow subcommand}; shift
        [[ $sub == dispatch ]] || die "unknown workflow subcommand: $sub"
        file=${1:?workflow file}; ref=${2:?ref}
        # GitHub answers 204 with no body, so success prints nothing. The ref must carry the
        # workflow file (a workflow_dispatch trigger only exists on the ref it is defined on), and
        # the caller's token needs `actions: write`; either shortfall fails the POST.
        gh api -X POST "repos/$repo/actions/workflows/$file/dispatches" -f "ref=$ref" >/dev/null \
            || die "workflow dispatch $file $ref: POST failed"
        ;;
    label)
        sub=${1:?label subcommand}; shift
        [[ $sub == list ]] || die "unknown label subcommand: $sub"
        out=$(gh api --paginate "repos/$repo/labels" -q '.[].name') || die "label list: GET failed"
        [[ -z $out ]] || printf '%s\n' "$out"
        ;;
    *)
        die "usage: github.sh issue view|assignee-add|assignee-remove|search|list-all | issue-types | user login | pr list-for-branch|view|reviews|comments|review-comments|checks|create|comment | run list | workflow dispatch | label list"
        ;;
esac
