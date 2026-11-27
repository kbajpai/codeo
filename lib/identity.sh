#!/usr/bin/env bash
# Who is acting. Source it; it defines functions only and prints nothing at source time.
#
# Functions:
#   codeo_is_web_session   exit 0 in a Claude Code on the web session (CLAUDE_CODE_REMOTE=true)
#   codeo_whoami           stdout "<login><TAB><type>" and exit 0 when GET /user answers with type
#                          User, or, in a web session only, when GET /user is refused and
#                          $CODEO_GITHUB_LOGIN is set (type "unverified"). Otherwise stdout is
#                          empty, one "codeo:" line goes to stderr, and the exit is 1.
#   codeo_owner_of_init F  prints the owner login recorded in dossier file F (last resume line, else Owner row)

codeo_is_web_session() { [[ ${CLAUDE_CODE_REMOTE:-} == true ]]; }

codeo_whoami() {
    local row login type
    if row=$(gh api user -q '[.login,.type]|@tsv' 2>/dev/null); then
        login=${row%%$'\t'*}
        type=${row#*$'\t'}
        if [[ $type != User ]]; then
            echo "codeo: $login is a ${type:-unknown} account, not a person: sign in with your own GitHub login" >&2
            return 1
        fi
        printf '%s\t%s\n' "$login" "$type"
    elif codeo_is_web_session && [[ -n ${CODEO_GITHUB_LOGIN:-} ]]; then
        printf '%s\tunverified\n' "$CODEO_GITHUB_LOGIN"
    else
        echo 'codeo: cannot tell who you are: GET /user was refused, and $CODEO_GITHUB_LOGIN counts only in a hosted web session' >&2
        return 1
    fi
}

# codeo_owner_of_init <init.md path>: prints the owner login of a dossier. The login on the LAST
# "- <date> — resumed: by <login> after " line wins, else the "| Owner | <login> |" row of the
# header table, else nothing. Always exits 0.
codeo_owner_of_init() {
    local file=$1 owner
    [[ -f $file ]] || return 0
    owner=$(sed -n 's/^- .* — resumed: by \([^ ]\{1,\}\) after .*/\1/p' "$file" | tail -n1)
    [[ -n $owner ]] || owner=$(sed -n 's/^| Owner | \([^ |]\{1,\}\) |.*/\1/p' "$file" | head -n1)
    [[ -z $owner ]] || printf '%s\n' "$owner"
    return 0
}
