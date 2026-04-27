# Paths and Environment Variables
export PATH="/Users/nirmalhk7/Downloads/google-cloud-sdk/bin:$PATH"
export PATH="/usr/local/go/bin:$PATH"
export PATH="~/.linkerd2/bin:$PATH"
export PATH="~/opt/homebrew/bin:$PATH"
export PATH="$HOME/Library/Android/sdk/platform-tools:$PATH"
export KUBECONFIG="$HOME/Documents/DevWorld/dotfiles/config.yaml"
export python="/opt/anaconda3/bin/python"

export CPATH=/opt/homebrew/include
export LIBRARY_PATH=/opt/homebrew/lib

# Ensure Homebrew's shell completion scripts are sourced for zsh
if type brew &>/dev/null; then
    FPATH="$(brew --prefix)/share/zsh/site-functions:${FPATH}"
    autoload -Uz compinit
    compinit;
fi

# Load local environment variables if they exist
if [ -f "$HOME/Documents/DevWorld/dotfiles/.env" ]; then
    set -a
    source "$HOME/Documents/DevWorld/dotfiles/.env"
    set +a
fi
