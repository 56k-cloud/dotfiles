# Generic zsh config (public tier). Standalone and safe on any machine — machine-specific or
# personal tweaks layer in via ~/.zshrc.local at the end (supplied by a private tier, if any).

export PATH="$HOME/bin:$HOME/.local/bin:/usr/local/bin:$PATH"

# --- Oh My Zsh (optional) --------------------------------------------------------------------
# Sourced only if installed — the prompt below does NOT depend on it, so this file stays snappy on
# a minimal machine (OMZ adds real startup cost). When present, OMZ still supplies its plugins
# (git, etc.); its theme is left empty because the lean prompt below replaces it.
export ZSH="$HOME/.oh-my-zsh"
ZSH_THEME=""
plugins=(git)
[ -d "$ZSH" ] && source "$ZSH/oh-my-zsh.sh"

# --- Prompt: lean, no OMZ dependency, adapts to width ----------------------------------------
# venv name (when a virtualenv is active) + path + caret, e.g. `~> ` or `(.venv) ~/src/demo> `.
# Below 100 columns (a handheld console, a phone SSH session, a narrow split) it shows only the
# current directory (`(.venv) demo> `). Re-checked before every prompt, so resizing or a font
# change takes effect immediately.
# VIRTUAL_ENV_DISABLE_PROMPT stops Python's venv `activate` from prepending its own `(.venv)`
# on top of ours. Set after the OMZ source so it wins over any theme.
setopt prompt_subst
VIRTUAL_ENV_DISABLE_PROMPT=1
_lean_prompt() {
  local where='%~'
  (( COLUMNS < 100 )) && where='%1~'
  PROMPT='%F{cyan}${VIRTUAL_ENV:+(${VIRTUAL_ENV:t}) }%f%F{blue}'"$where"'%f> '
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

# direnv — per-directory environment via an .envrc, auto-loaded/unloaded on cd. Guarded: only
# hooks if direnv is installed, so this is a no-op (not an error) on a machine without it.
command -v direnv >/dev/null 2>&1 && eval "$(direnv hook zsh)"

# Local overlay — machine-specific or personal config, kept out of this public file. Absent on a
# machine that only has the public tier, so this is a clean no-op there.
[ -f ~/.zshrc.local ] && source ~/.zshrc.local
