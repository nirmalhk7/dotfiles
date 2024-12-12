#!/bin/bash

alias code="/Applications/Visual\ Studio\ Code.app/Contents/Resources/app/bin/code"
alias p="python"
function hulksmash(){
    kill -9 $(lsof -t -i:$1)
}

unset gpc
unset gs
alias gpsup='git push --set-upstream origin "$(git-branch-current 2> /dev/null)"'
alias gcasm='git commit -asm'
alias gst='git status'

export PATH="/Users/nirmalhk7/Downloads/google-cloud-sdk/bin:$PATH"
export PATH="/usr/local/go/bin:$PATH"

function port_forward() {
    local service_name=$1
    local local_port=$2
    local remote_port=$2
    local namespace=${3:-default}

    kubectl port-forward svc/$service_name -n $namespace $local_port:$remote_port &
    local pid=$!

    sleep 5

    if ! ps -p $pid > /dev/null; then
        echo "Port forwarding for service $service_name failed, restarting..."
        kill -9 $pid
        kubectl port-forward svc/$service_name -n $namespace $local_port:$remote_port &
    else
        echo "Port forwarding for service $service_name setup successfully."
    fi
}