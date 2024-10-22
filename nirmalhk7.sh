#!/bin/bash

alias code="/Applications/Visual\ Studio\ Code.app/Contents/Resources/app/bin/code"
alias p="python3"
function hulksmash(){
    kill -9 $(lsof -t -i:$1)
}

unset gpc
unset gs
alias gpsup='git push --set-upstream origin "$(git-branch-current 2> /dev/null)"'
alias gcasm='git commit -asm'
alias gst='git status'

export PATH="/Users/nirmalhk7/Downloads/google-cloud-sdk/bin:$PATH"