# Generic zsh config (public tier). Standalone and safe on any machine — machine-specific or
# personal tweaks layer in via ~/.zshrc.local at the end (supplied by a private tier, if any).

export PATH="$HOME/bin:$HOME/.local/bin:/usr/local/bin:$PATH"

# --- Locale: English, UTF-8, everywhere --------------------------------------------------------
# Without a UTF-8 locale, tmux draws box/powerline glyphs as `_`, and zsh/less mangle non-ASCII.
# en_US.UTF-8 if the machine has it; otherwise C.UTF-8 (built into glibc, so always present —
# minimal Debian/containers often have NO en_US generated, and exporting a missing locale makes
# every program warn "cannot set locale" and fall back to ASCII: the exact bug this prevents).
# LC_ALL is cleared and LC_CTYPE pinned because ssh forwards the client's LC_* (macOS sends
# LC_CTYPE=UTF-8, which isn't a valid Linux locale). A default, not a lock: ~/.zshrc.local wins.
if locale -a 2>/dev/null | grep -qixE 'en_US\.utf-?8'; then
  export LANG=en_US.UTF-8
else
  export LANG=C.UTF-8
fi
export LC_CTYPE="$LANG"
unset LC_ALL

# --- Oh My Zsh (optional) --------------------------------------------------------------------
# Sourced only if installed — the prompt below does NOT depend on it, so this file stays snappy on
# a minimal machine (OMZ adds real startup cost). When present, OMZ still supplies its plugins
# (git, etc.); its theme is left empty because the lean prompt below replaces it.
export ZSH="$HOME/.oh-my-zsh"
ZSH_THEME=""
plugins=(git)
[ -d "$ZSH" ] && source "$ZSH/oh-my-zsh.sh"

# --- Prompt: lean, no OMZ dependency, adapts to width ----------------------------------------
# venv name (when a virtualenv is active) + path + git branch, no caret — the colours mark where
# the prompt ends. e.g. `~ ` or `(.venv) ~/src/demo (main) `.
# Below 100 columns (a handheld console, a phone SSH session, a narrow split) it shows only the
# current directory (`(.venv) demo `). Re-checked before every prompt, so resizing or a font
# change takes effect immediately.
# VIRTUAL_ENV_DISABLE_PROMPT stops Python's venv `activate` from prepending its own `(.venv)`
# on top of ours. Set after the OMZ source so it wins over any theme.
setopt prompt_subst
VIRTUAL_ENV_DISABLE_PROMPT=1
# Inside a git repo the branch follows the path — `~/src/demo (main) ` — or the short commit hash
# when HEAD is detached. The branch is referenced as ${_lean_branch}, never spliced into PROMPT:
# under prompt_subst a spliced branch named `$(…)` would EXECUTE when you cd into a hostile clone.
_lean_prompt() {
  local where='%~'
  (( COLUMNS < 100 )) && where='%1~'
  _lean_branch=$(git symbolic-ref --short -q HEAD 2>/dev/null || git rev-parse --short -q HEAD 2>/dev/null)
  _lean_branch=${_lean_branch//\%/%%}
  PROMPT='%F{cyan}${VIRTUAL_ENV:+(${VIRTUAL_ENV:t}) }%f%F{blue}'"$where"'%f${_lean_branch:+ %F{yellow\}(${_lean_branch})%f} '
}
autoload -Uz add-zsh-hook
add-zsh-hook precmd _lean_prompt
_lean_prompt

# Preferred editor — probe rather than hardcode a binary name, so the same file works whether the
# machine has nvim, vim, or only vi. Anything that shells out ($EDITOR/$VISUAL) then behaves.
for _ed in nvim vim vi; do
  if command -v "$_ed" >/dev/null 2>&1; then
    export EDITOR="$_ed" VISUAL="$_ed"
    break
  fi
done
unset _ed

# --- Narrow-terminal helpers ----------------------------------------------------------------
# less: chop long lines (pan with ←/→) instead of wrapping them into a mess; keep colours (R);
# quit if it fits one screen (F) and leave it on screen afterwards (X) — git's defaults, plus S.
export LESS="-FRSX"
# `cmd --help N` = `cmd --help | narrow` — reflow output to fit the terminal (narrow ships in
# this repo's `bin` package). Only defined when narrow is installed.
command -v narrow >/dev/null 2>&1 && alias -g N='| narrow'

# direnv — per-directory environment via an .envrc, auto-loaded/unloaded on cd. Guarded: only
# hooks if direnv is installed, so this is a no-op (not an error) on a machine without it.
command -v direnv >/dev/null 2>&1 && eval "$(direnv hook zsh)"

# `docker` works whether the machine has Docker or Podman (Jake, 2026-10-28): type `docker run …` and not
# care. Only when docker itself is ABSENT and podman is present, so a machine with real Docker keeps it.
# An alias reaches interactive shells only; scripts and programs that call `docker` need Debian's
# `podman-docker` package (a real /usr/bin/docker that runs podman) instead.
if ! command -v docker >/dev/null 2>&1 && command -v podman >/dev/null 2>&1; then
  alias docker=podman
fi

# Local overlay — machine-specific or personal config, kept out of this public file. Absent on a
# machine that only has the public tier, so this is a clean no-op there.
[ -f ~/.zshrc.local ] && source ~/.zshrc.local

# --- ssh from inside tmux: the window shows the host, and a dropped connection reconnects -------------
# Inside tmux, `ssh host` renames the window to `@host` in that host's colour (~/.tmux/host_color.sh, the
# colour its own status bar uses) and puts the old name back when the session ends.
# Closing the laptop lid kills the connection without telling ssh. Both fixes live here, not in ssh_config,
# so they work on every machine that has this file:
#   - ServerAliveInterval=15 x CountMax=3: a dead connection is noticed in ~45 s (not minutes).
#   - Reconnect: if ssh exits 255 (ssh's own failure, not your `exit`) after a real session, it retries every
#     SSH_RECONNECT_DELAY (5) s until the host answers again (VPN back up) or you press Ctrl-C. The remote
#     re-attaches its `main` tmux session (below), so you land back where you were, programs still running.
# Only for an interactive login (`ssh [opts] host`): `ssh host cmd`, scp, git and ansible are untouched. A first
# attempt that fails within SSH_RECONNECT_MIN (10) s (a typo, a host that's off) is an error, not a loop.
ssh() {
  if [[ -z $TMUX ]]; then command ssh "$@"; return; fi
  local a dest= expect=0 remote_cmd=0
  for a in "$@"; do
    if (( expect )); then expect=0; continue; fi
    if [[ -n $dest ]]; then remote_cmd=1; break; fi
    case $a in
      -[bcDEeFIiJLlmOopQRSWw]) expect=1 ;;   # options that take a separate value
      -*) ;;
      *) dest=$a ;;
    esac
  done
  if [[ -z $dest ]] || (( remote_cmd )); then command ssh "$@"; return; fi

  local host=${dest#*@}
  [[ $host == <->.<->.<->.<-> ]] || host=${host%%.*}   # an IP stays whole; a name keeps its first label
  local old auto color rc=0 started connected=0
  old=$(tmux display -p '#W')
  auto=$(tmux show -wv automatic-rename 2>/dev/null)   # "" = inherited from the global setting
  color=$(sh ~/.tmux/host_color.sh "$host" 2>/dev/null)
  tmux setw automatic-rename off \; rename-window "@$host"
  [[ -n $color ]] && tmux set -w @wcolor "$color"
  {
    while true; do
      started=$SECONDS
      command ssh -o ServerAliveInterval=15 -o ServerAliveCountMax=3 "$@"
      rc=$?
      (( SECONDS - started >= ${SSH_RECONNECT_MIN:-10} )) && connected=1
      (( rc == 255 && connected )) || break
      print -P "%F{yellow}[ssh $host] connection lost; reconnecting every ${SSH_RECONNECT_DELAY:-5}s (Ctrl-C stops)%f"
      sleep ${SSH_RECONNECT_DELAY:-5}
    done
  } always {
    # Runs on normal exit AND on Ctrl-C, so the label never sticks to a window that left the host.
    # The window's own automatic-rename setting comes back as it was, so a name you gave it isn't overwritten.
    tmux set -uw @wcolor 2>/dev/null
    tmux rename-window "$old" 2>/dev/null
    if [[ -n $auto ]]; then tmux setw automatic-rename "$auto" 2>/dev/null; else tmux setw -u automatic-rename 2>/dev/null; fi
  }
  return $rc
}

# --- Auto-attach tmux on SSH login -------------------------------------------------------------
# `ssh host` lands you in the host's `main` tmux session — created if missing, re-attached if it
# survived a dropped connection. Last in the file so ~/.zshrc.local can opt a machine out.
# Only fires for an interactive SSH login on a real terminal, not already inside tmux:
#   - `ssh host cmd`, scp, rsync, git-over-ssh, ansible → non-interactive / no tty → skipped.
#   - local terminals (no $SSH_CONNECTION) → skipped; the Mac never auto-starts tmux.
#   - VS Code's remote terminal → skipped; it has its own panes.
# Nesting is deliberate: from a local tmux you get tmux-in-tmux — C-a toggles the outer one off.
# Escape hatches: `C-b d` detaches to a plain shell on the host (no `exec`, so the ssh stays up);
# `TMUX_AUTO=0` in ~/.zshrc.local turns it off for that machine.
if [[ -o interactive && -t 0 && -t 1 && -n $SSH_CONNECTION && -z $TMUX \
      && $TERM_PROGRAM != vscode && ${TMUX_AUTO:-1} != 0 ]] && command -v tmux >/dev/null 2>&1; then
  tmux new-session -A -s main
fi
