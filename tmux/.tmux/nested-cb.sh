#!/bin/sh
# nested-cb.sh: what C-b does while this tmux is toggled OFF (nested mode; see .tmux.conf).
#   one C-b                       -> forwarded to the inner tmux, which then acts on your next key
#   two C-b within 400 ms (C-b C-b) -> this tmux turns back ON, and the inner tmux's half-typed prefix
#                                    (the first C-b was already forwarded) is cancelled with an Escape.
# The Escape can't merge with your next key into an Alt-key: escape-time is 10 ms in .tmux.conf.
# A slow C-b ... C-b (over 400 ms apart) is two forwarded C-b's, i.e. the inner tmux's own send-prefix.
# Args: session id, pane id, client name (tmux expands them in the binding). NESTED_DOUBLE_TAP_MS overrides.
s=$1 p=$2 c=$3

now_ms() {   # macOS date has no milliseconds; perl (always on macOS) does. Fallbacks for a minimal Linux.
  perl -MTime::HiRes=time -e 'printf "%d\n", time*1000' 2>/dev/null && return
  d=$(date +%s%3N 2>/dev/null); case $d in *N|'') ;; *) echo "$d"; return ;; esac
  echo $(( $(date +%s) * 1000 ))   # last resort: second resolution (a double tap must fall in one second)
}

now=$(now_ms)
last=$(tmux show -qv -t "$s" @nested_cb_last)
if [ -n "$last" ] && [ $(( now - last )) -lt "${NESTED_DOUBLE_TAP_MS:-400}" ]; then
  tmux set -u -t "$s" @nested_cb_last \; \
       send-keys -t "$p" Escape \; \
       set -u -t "$s" prefix \; \
       set -u -t "$s" key-table \; \
       set -u -t "$s" status-position \; \
       set -u -t "$s" status-style \; \
       set -u -t "$s" window-status-current-style \; \
       set -u -t "$s" status-left-style \; \
       refresh-client -S -t "$c"
else
  tmux set -t "$s" @nested_cb_last "$now" \; send-keys -t "$p" C-b
fi
