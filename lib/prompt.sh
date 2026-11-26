#!/usr/bin/env bash
# Prompts for the setup wizard. Source it; it defines functions and does nothing else.
#
#   codeo_interactive          succeed when questions can be asked: stdin is a terminal, or
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

codeo_interactive() {
    [[ ${CODEO_ASSUME_YES:-0} != 1 ]] && { [[ -t 0 ]] || [[ ${CODEO_PROMPT_TTY:-0} == 1 ]]; }
}

codeo_ask() {
    local var=$1 question=$2 default=${3:-} answer
    [[ -z ${!var:-} ]] || return 0
    if codeo_interactive; then
        printf '%s%s: ' "$question" "${default:+ [$default]}" >&2
        IFS= read -r answer || answer=""
        printf -v "$var" '%s' "${answer:-$default}"
    else
        printf -v "$var" '%s' "$default"
    fi
}

codeo_confirm() {
    local question=$1 default=${2:-n} answer
    if codeo_interactive; then
        printf '%s [%s]: ' "$question" "$([[ $default == y ]] && echo Y/n || echo y/N)" >&2
        IFS= read -r answer || answer=""
        answer=${answer:-$default}
    else
        answer=$default
    fi
    [[ $answer == [yY]* ]]
}
