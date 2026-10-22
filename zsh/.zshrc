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

# Local overlay — machine-specific or personal config, kept out of this public file. Absent on a
# machine that only has the public tier, so this is a clean no-op there.
[ -f ~/.zshrc.local ] && source ~/.zshrc.local
