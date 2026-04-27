# Functions

function hulksmash(){
    kill -9 $(lsof -t -i:$1)
}

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

function HOMELAB() {
    local jump_host=$HOMELAB_IP

    if [ "$1" = "vpn" ] || [ "$1" = "VPN" ]; then
        jump_host=$HOMELAB_VPN_IP
    fi

    if [ -z "$2" ]; then 
        # If destination server is not set
        echo "Directly SSHing jump server ..."
        ssh -A root@"$jump_host"
    else
        echo "SSHing a new server ..."
        ssh -A -J root@"$jump_host" root@"$2"
    fi
}
