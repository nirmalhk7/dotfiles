# Aliases
alias code="/Applications/Visual\ Studio\ Code.app/Contents/Resources/app/bin/code"
alias p="python"

# Git Aliases
unset gpc
unset gs
alias gia='git add'
alias gpsup='git push --set-upstream origin "$(git branch --show-current 2> /dev/null)"'
alias gcasm='gia . && git commit -asm'
alias gx='git cz -as'
alias gllm='python /Users/nirmalhk7/Documents/DevWorld/dotfiles/scripts/gllm.py'
alias gst='git status'
alias fst='git status'

# Utility Aliases
alias npmi='npm install --legacy-peer-deps'
alias HOMELAB_SHUTDOWN="ssh -t milano sudo shutdown now"
