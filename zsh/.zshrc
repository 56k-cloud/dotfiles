# Generic zsh config (public tier). Standalone and safe on any machine — machine-specific or
# personal tweaks layer in via ~/.zshrc.local at the end (supplied by a private tier, if any).

export PATH="$HOME/bin:$HOME/.local/bin:/usr/local/bin:$PATH"

# --- Oh My Zsh -------------------------------------------------------------------------------
export ZSH="$HOME/.oh-my-zsh"
ZSH_THEME="robbyrussell"            # swap freely; see https://github.com/ohmyzsh/ohmyzsh/wiki/Themes
plugins=(git)
# Guarded so this file is portable to a machine where Oh My Zsh isn't installed (no error, no theme).
[ -d "$ZSH" ] && source "$ZSH/oh-my-zsh.sh"

# Show the short hostname in the prompt over SSH, so you always know which box you're on.
# Local shells stay clean — this only fires under ssh. Prepends to the theme's PROMPT.
if [[ -n "$SSH_CONNECTION" ]]; then
  PROMPT="%{$fg_bold[yellow]%}%m%{$reset_color%} $PROMPT"
fi

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
