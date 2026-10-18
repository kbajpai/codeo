#!/usr/bin/env bash
# The CLI over lib/env.sh for skills and doctor.sh.
#
#   config.sh get <jq-filter>   print the value; empty output and exit 1 if absent
#   config.sh validate          check the config is readable, its schema is supported, and the
#                               keys every flow needs exist
set -euo pipefail

source "$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)/lib/env.sh"

case "${1:-}" in
    get)
        [[ -n "${2:-}" ]] || codeo_die "usage: config.sh get <jq-filter>"
        codeo_cfg "$2"
        ;;
    validate)
        schema=$(codeo_cfg_required .schema)
        [[ "$schema" =~ ^[0-9]+$ ]] || codeo_die "config.json: schema must be an integer, got $schema"
        if [[ "$schema" -gt "$CODEO_SCHEMA" ]]; then
            codeo_die "config.json: schema $schema is newer than this plugin supports ($CODEO_SCHEMA); update the plugin"
        fi
        # setup.sh writes the TODO-set-me marker for what it could not resolve; it must not pass.
        for key in .repo.owner .repo.name .baseBranch; do
            value=$(codeo_cfg_required "$key")
            [[ "$value" != TODO-set-me ]] || codeo_die "config.json: ${key#.} is still TODO-set-me"
        done
        ;;
    *)
        codeo_die "usage: config.sh get <jq-filter> | validate"
        ;;
esac
