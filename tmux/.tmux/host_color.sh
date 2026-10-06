#!/bin/sh

# Generate a color from the hostname (deterministic hash). Optional arg overrides the hostname;
# default is this machine's short name. Prints a tmux colour code (e.g. `colour94`).

host="${1:-$(uname -n 2>/dev/null || hostname 2>/dev/null)}"
host="${host%%.*}"
sum=$(printf '%s' "$host" | cksum | cut -d' ' -f1)
set -- 24 30 22 94 88 60 54 130 23 100 18 52 58 17 28 90
n=$#
shift $(( sum % n ))
printf 'colour%s\n' "$1"
