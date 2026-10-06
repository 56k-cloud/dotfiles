# dotfiles

Generic, standalone shell dotfiles — `zsh` (Oh My Zsh) and `tmux` — installed with [GNU Stow](https://www.gnu.org/software/stow/).

This is the **public tier** of a layered setup. It is self-contained: it works on its own, with no
reference to any private configuration. Machine-specific or personal settings layer on top via
local-override files this repo never contains (see [Local overrides](#local-overrides)).

## Install

```sh
git clone https://github.com/jakes-homelab/dotfiles ~/dotfiles-public
cd ~/dotfiles-public
stow zsh tmux
```

`stow <pkg>` symlinks the package's files into `$HOME` (see `.stowrc`). For the zsh theme you also
need [Oh My Zsh](https://github.com/ohmyzsh/ohmyzsh); without it the shell still works, just without
the theme. `tmux` is self-contained — the per-host status color ships as `~/.tmux/host_color.sh`.

## Local overrides

The last line of each config sources a local file, so you never fork this repo to add private bits:

| Public file | Sources at the end |
|---|---|
| `.zshrc` | `~/.zshrc.local` |
| `.tmux.conf` | `~/.tmux.conf.local` |

Put machine-specific or personal config (host lists, work helpers, identity) in those `.local`
files. A machine that only has this public tier has no `.local` files, and both configs no-op
cleanly there — that is the property this repo guarantees.

## What belongs in here — the promotion test

A file or package may live in this public repo only when **all three** hold:

1. **No** domain, hostname, IP address, username, or key name in any tracked file — or in history.
2. Nothing in it is useful **only** to one specific environment.
3. Nothing in it references a private tier (no `source ~/private-dotfiles/...`).

Something that fails (1) but passes (2) can still be promoted by **parameterising** it — a
local-override hook, a `.example` file, or an environment variable — never by committing the
specific value. Anything that fails (2) stays private. The rule is written here so it travels with
the thing it governs.
