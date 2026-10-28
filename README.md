# dotfiles

Generic, standalone shell dotfiles — `zsh` (Oh My Zsh) and `tmux` — installed with [GNU Stow](https://www.gnu.org/software/stow/).

This is the **public tier** of a layered setup. It is self-contained: it works on its own, with no
reference to any private configuration. Machine-specific or personal settings layer on top via
local-override files this repo never contains (see [Local overrides](#local-overrides)).

## Install

```sh
git clone https://github.com/jakes-homelab/dotfiles ~/dotfiles-public
cd ~/dotfiles-public
stow zsh tmux bin tealdeer    # any subset works
```

`stow <pkg>` symlinks the package's files into `$HOME` (see `.stowrc`). For the zsh theme you also
need [Oh My Zsh](https://github.com/ohmyzsh/ohmyzsh); without it the shell still works, just without
the theme. `tmux` is self-contained — the per-host status color ships as `~/.tmux/host_color.sh`.

| Package | What it links | Notes |
|---|---|---|
| `zsh` | `~/.zshrc` | lean prompt (path + git branch) that narrows below 100 columns; `LESS=-FRSX`; the `N` shortcut; `ssh host` auto-attaches tmux session `main`; inside tmux, `ssh host` labels the window `@host` in its colour and **reconnects after a dropped connection** (see below); `docker` runs podman on a machine that has podman but no docker |
| `tmux` | `~/.tmux.conf`, `~/.tmux/host_color.sh` | status bar compacts below 100 columns; nested-tmux toggle and keys below |
| `bin` | `~/.local/bin/narrow` | reflow text to fit a narrow terminal (needs `python3`) |
| `tealdeer` | `~/.config/tealdeer/config.toml` | `tldr` auto-fetches its pages on first use (install `tealdeer` yourself; on macOS tealdeer reads `~/Library/Application Support/tealdeer` instead, so this one is Linux-only in effect) |

### tmux keys (beyond the defaults)

| keys | does |
|---|---|
| `C-b v` / `C-b h` | split: **v**ertical divider (side by side) / **h**orizontal divider (stacked). `\` and `-` still work |
| `C-b C-b` | toggle this tmux **off** so every key, `C-b` included, reaches a nested (ssh) tmux; status moves to the top, shows `OFF`. While off, `C-b c`, `C-b n` … drive the remote. **`C-b C-b` again, both taps within 0.4 s** = back on (slower taps are two `C-b`s for the inner tmux) |

The hostname block (bottom left) turns **yellow** while `C-b` is waiting for its next key — with
nested tmux, that's how you see which one took it. `C-a` is the shell's beginning-of-line (the toggle
used to live there). Pane/window movement stays on the defaults (`C-b` + arrows, `C-b n` / `C-b p`) — they
behave the same on macOS and Linux with no terminal setup.

### ssh from inside tmux

`ssh host` (an interactive login, from inside tmux) renames the window to `@host` in that host's colour and
restores the old name when you leave. When the connection drops (closing the laptop lid, the VPN going
away), ssh notices within ~45 s (`ServerAliveInterval=15`, `CountMax=3`, passed by the wrapper so no
ssh_config is needed). After a real session it then **reconnects every 5 s** until the host answers again, or
until you press Ctrl-C. The remote end re-attaches its `main` tmux session, so you land back where you were.
The label stays while it retries and is restored on Ctrl-C too. Not touched: `ssh host cmd`, scp, git, ansible,
and anything outside tmux. A first attempt that fails within 10 s (typo, host off) is just an error.
Tunables: `SSH_RECONNECT_DELAY` (5), `SSH_RECONNECT_MIN` (10).

### Narrow terminals

On a small screen (a handheld console, a phone SSH session, a narrow split):

- `man <cmd>` reflows to your width by itself — prefer it over `--help`.
- `cmd --help N` (= `cmd --help | narrow`) restacks the usual two-column help — option on one
  line, description wrapped beneath — and word-wraps everything else. Lines that already fit are
  untouched.
- `less` chops long lines instead of wrapping (`LESS=-FRSX`); pan with ←/→.
- `tldr <cmd>` — short, example-first cheat sheets.

### Locale

`.zshrc` sets `en_US.UTF-8`, or falls back to `C.UTF-8` (still UTF-8, but not English
collation/formats) when the machine hasn't generated it — common on minimal Debian. To get the real
thing there: `sudo sed -i 's/^# *en_US.UTF-8/en_US.UTF-8/' /etc/locale.gen && sudo locale-gen`.
On macOS, `LANG` comes from the terminal app (iTerm2: Profiles → Terminal → "Set locale variables
automatically"; Terminal.app: Profiles → Advanced), which derives it from the Region setting — not
the keyboard layout.

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
