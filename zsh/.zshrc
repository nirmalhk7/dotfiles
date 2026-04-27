# Source Prezto if it exists
if [[ -s "${ZDOTDIR:-$HOME}/.zprezto/init.zsh" ]]; then
  source "${ZDOTDIR:-$HOME}/.zprezto/init.zsh"
fi

# NVM Setup
export NVM_DIR="$([ -z "${XDG_CONFIG_HOME-}" ] && printf %s "${HOME}/.nvm" || printf %s "${XDG_CONFIG_HOME}/nvm")"
[ -s "$NVM_DIR/nvm.sh" ] && \. "$NVM_DIR/nvm.sh" # This loads nvm
[ -s "$NVM_DIR/bash_completion" ] && \. "$NVM_DIR/bash_completion"  # This loads nvm bash_completion

# Source modular configurations
DOTFILES_DIR="$HOME/Documents/DevWorld/dotfiles"

if [ -d "$DOTFILES_DIR/zsh" ]; then
    source "$DOTFILES_DIR/zsh/env.zsh"
    source "$DOTFILES_DIR/zsh/aliases.zsh"
    source "$DOTFILES_DIR/zsh/functions.zsh"
fi

# >>> conda initialize >>>
# !! Contents within this block are managed by 'conda init' !!
__conda_setup="$('/opt/anaconda3/bin/conda' 'shell.zsh' 'hook' 2> /dev/null)"
if [ $? -eq 0 ]; then
    eval "$__conda_setup"
else
    if [ -f "/opt/anaconda3/etc/profile.d/conda.sh" ]; then
        . "/opt/anaconda3/etc/profile.d/conda.sh"
    else
        export PATH="/opt/anaconda3/bin:$PATH"
    fi
fi
unset __conda_setup
# <<< conda initialize <<<

export PATH="$HOME/texlive/bin/universal-darwin:$PATH"

# Added by Antigravity
export PATH="/Users/nirmalhk7/.antigravity/antigravity/bin:$PATH"
export PATH="$HOME/.local/bin:$PATH"
