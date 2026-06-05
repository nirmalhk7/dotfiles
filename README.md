# Dotfiles

Portable shell, Git, and helper configuration for my machines.

## What It Does

- Installs and refreshes the local shell setup from `setup.sh`
- Keeps Zsh aliases, environment exports, functions, and the custom prompt theme in `zsh/`
- Stores the shared Git config in `git/.gitconfig`
- Collects reusable hooks and helper scripts for day-to-day workflow

## Install

From the repo root:

```bash
./setup.sh
```

The installer backs up existing `~/.zshrc` and `~/.gitconfig` files, links the tracked config into place, and cleans up old bridge files.

## Layout

- `zsh/` for Zsh config, aliases, functions, and theme files
- `git/` for the global Git configuration
- `hooks/` for shared Git hooks
- `scripts/` for supporting utilities
