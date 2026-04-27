# Nirmal's Dotfiles

Modular and portable configuration files for Zsh and Git.

## 🚀 Quick Start (Installation)

To set up or refresh your configuration on any machine, run this single command:

```bash
cd ~/Documents/DevWorld/dotfiles && ./setup.sh
```

### What this script does:
1.  **Backs up** your existing `~/.zshrc` and `~/.gitconfig` to a timestamped folder in your home directory.
2.  **Symlinks** the configuration files from this repository to your home directory.
3.  **Links your custom theme** into the Prezto theme directory.
4.  **Cleans up** any legacy "bridge" files in the root of this repo.

---

## 📂 Project Structure

- **`zsh/`**: 
    - `.zshrc`: The main entry point for Zsh.
    - `aliases.zsh`: All custom shell aliases.
    - `env.zsh`: Path exports and environment variables.
    - `functions.zsh`: Custom shell functions (e.g., `hulksmash`).
    - `nirmalhk7.zsh-theme`: Your custom prompt theme.
- **`git/`**:
    - `.gitconfig`: Your global git configuration.
- **`hooks/`**: Git hooks used across projects.
- **`setup.sh`**: The master installation script.

## 🛠 Adding New Configurations

Don't edit your `~/.zshrc` directly (since it's now a link to this repo). Instead:
1.  Open the relevant file in `~/Documents/DevWorld/dotfiles/zsh/`.
2.  Add your change.
3.  Run `source ~/.zshrc` or open a new terminal.
