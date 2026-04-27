# Aliases
alias code="/Applications/Visual\ Studio\ Code.app/Contents/Resources/app/bin/code"
alias p="python"

# Git Aliases
unset gpc
unset gs
alias gpsup='git push --set-upstream origin "$(git-branch-current 2> /dev/null)"'
alias gcasm='gia . && git commit -asm'
alias gx='git cz -as'
alias gst='git status'

# Utility Aliases
alias npmi='npm install --legacy-peer-deps'
alias HOMELAB_SHUTDOWN="ssh -t milano sudo shutdown now"
