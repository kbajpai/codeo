#!/usr/bin/env bash
# Prompts for the setup wizard. Source it; it defines functions and does nothing else.
#
#   codeo_interactive          succeed when questions can be asked: stdin is a terminal, /dev/tty opens while stdin is a
#                              pipe (curl | bash; answers are then read from /dev/tty), or
#                              CODEO_PROMPT_TTY=1 (the tests' stand-in for a terminal) and --yes was not given
#   codeo_ask <var> <question> [default]
#                              set <var> to the answer. Not interactive: <var> keeps a value it already holds
#                              (a flag), else takes the default. Interactive: a value already held is not asked
#                              again; an empty answer takes the default
#   codeo_confirm <question> [default y|n]
#                              succeed on yes. Not interactive: the default answer (n when none)
#
# CODEO_ASSUME_YES=1 (the wizard's --yes) turns every question into its default.
# Prompts go to stderr so stdout stays for results.

codeo_tty_answers() { # succeed when answers come from /dev/tty: stdin is not a terminal, nothing stands in for one, and /dev/tty opens
    [[ ${CODEO_ASSUME_YES:-0} != 1 && ${CODEO_PROMPT_TTY:-0} != 1 && ! -t 0 ]] && { : </dev/tty; } 2>/dev/null
}

codeo_interactive() {
    [[ ${CODEO_ASSUME_YES:-0} != 1 ]] && { [[ -t 0 ]] || [[ ${CODEO_PROMPT_TTY:-0} == 1 ]] || codeo_tty_answers; }
}

codeo_read_answer() { # <var>: read one line into <var> from /dev/tty when stdin is a pipe, else from stdin
    local line=""
    if codeo_tty_answers; then IFS= read -r line </dev/tty || line=""; else IFS= read -r line || line=""; fi
    printf -v "$1" '%s' "$line"
}

codeo_ask() {
    local var=$1 question=$2 default=${3:-} answer
    [[ -z ${!var:-} ]] || return 0
    if codeo_interactive; then
        printf '%s%s: ' "$question" "${default:+ [$default]}" >&2
        codeo_read_answer answer
        printf -v "$var" '%s' "${answer:-$default}"
    else
        printf -v "$var" '%s' "$default"
    fi
}

codeo_confirm() {
    local question=$1 default=${2:-n} answer
    if codeo_interactive; then
        printf '%s [%s]: ' "$question" "$([[ $default == y ]] && echo Y/n || echo y/N)" >&2
        codeo_read_answer answer
        answer=${answer:-$default}
    else
        answer=$default
    fi
    [[ $answer == [yY]* ]]
}
