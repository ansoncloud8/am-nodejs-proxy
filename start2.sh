#!/bin/bash

function cleanup() {
    echo "Script interrupted."
    exit 1
}

trap cleanup INT
trap '' SIGTERM

base_dir="$( cd "$( dirname "${BASH_SOURCE[0]}" )" && pwd )"

function setup_services() {
    local action="${1:-xray}"
    init
    run_app $action
}

function show_services() {
    local action="${1:-xray}"
    case $action in
        all)
            extract_vars '^VLESS_'
            ;;
        xray)
            extract_vars '^VLESS_XRAY'
            ;;
        node)
            extract_vars '^VLESS_NODE'
            ;;
    esac
}

function check_services() {
    local action="${1:-xray}"
    local cf_session=$(tmux list-sessions | grep -q "cf" && echo "1" || echo "0")
    local action_session=$(tmux list-sessions | grep -q "$action" && echo "1" || echo "0")
    if [ "$cf_session" -eq 0 ]; then
        setup_services $action
        exit 1
    fi
    if [ "$action_session" -eq 0 ]; then
        run_app $action
        exit 1
    fi
}

function reset_services() {
    local action="${1:-xray}"
    reset
}

function init() {
    devil binexec on
    reset
    prepare_cloudflared
    prepare_node
    prepare_xray
}

function run_cloudflared() {
    local uuid=$(uuidgen)
    local port=$(reserve_port)
    local id=$(echo $uuid | tr -d '-')
    local session="cf"
    tmux kill-session -t $session
    tmux new-session -s $session -d "cd $base_dir/cloudflared && ./cloudflared tunnel --url localhost:$port --edge-ip-version auto --no-autoupdate -protocol http2 2>&1 | tee $base_dir/cloudflared/session_$session.log"
    sleep 10
    local log=$(<"$base_dir/cloudflared/session_$session.log")
    local cloudflared_address=$(echo "$log" | pcregrep -o1 'https://([^ ]+\.trycloudflare\.com)' | sed 's/https:\/\///')
    generate_configs $port $uuid $id $cloudflared_address
}

function run_node() {
    local session="node"
    tmux kill-session -t $session
    tmux new-session -s $session -d "cd $base_dir/node && node index.js 2>&1 | tee $base_dir/node/session_$session.log"
    set_cronjob $session
}

function run_xray() {
    local session="xray"
    tmux kill-session -t $session
    tmux new-session -s $session -d "cd $base_dir/xray && ./xray 2>&1 | tee $base_dir/xray/session_$session.log"
    set_cronjob $session
}

function reset() {
    tmux kill-session -a
    local ports=$(devil port list | awk '/[0-9]+/ {print $1}' | sort -u)
    for port in $ports; do
        devil port del tcp $port
        devil port del udp $port
    done
}

function prepare_cloudflared() {
    mkdir -p $base_dir/cloudflared
    cd $base_dir/cloudflared
    curl -Lo cloudflared.7z https://cloudflared.bowring.uk/binaries/cloudflared-freebsd-latest.7z
    7z x cloudflared.7z
    rm cloudflared.7z
    mv $(find . -name 'cloudflared*') cloudflared
    rm -rf temp
    chmod +x cloudflared
}

function prepare_node() {
    mkdir -p $base_dir/node
    cd $base_dir/node
    npm install
}

function prepare_xray() {
    mkdir -p $base_dir/xray
    cd $base_dir/xray
    curl -Lo xray.zip https://github.com/xtls/xray-core/releases/latest/download/xray-freebsd-64.zip
    unzip -o xray.zip
    rm xray.zip
    chmod +x xray
}

function reserve_port() {
    local port
    while true; do
        port=$(jot -r 1 1024 64000)
        tcp_output=$(devil port add tcp $port 2>&1)
        udp_output=$(devil port add udp $port 2>&1)
        if ! echo "$tcp_output" | grep -q "\[Error\]" && ! echo "$udp_output" | grep -q "\[Error\]"; then
            echo $port
            break
        else
            devil port del tcp $port
            devil port del udp $port
        fi
    done
}

function generate_configs() {
    local port="$1"
    local uuid="$2"
    local id="$3"
    local cloudflared_address="$4"
    local vless_node="vless://${id}@icook.tw:443?security=tls&sni=${cloudflared_address}&alpn=h2,http/1.1&fp=chrome&type=ws&path=/&host=${cloudflared_address}&encryption=none#[pl]%20[vl-tl-ws]%20[at-ar-no]"
    local vless_xray="vless://${uuid}@visa.com:443?security=tls&sni=${cloudflared_address}&alpn=h2,http/1.1&fp=chrome&type=ws&path=/ws?ed%3D2048&host=${cloudflared_address}&encryption=none#[pl]%20[vl-tl-ws]%20[at-ar]"

    cat > $base_dir/node/.env << EOF
PORT=$port
UUID=$uuid
ID=$id
VLESS_NODE=$vless_node
VLESS_XRAY=$vless_xray
EOF

    cat > $base_dir/../public_html/sub.txt << EOF
$vless_node
$vless_xray
EOF

    cat > $base_dir/xray/config.json << EOF
{
  "log": {
    "loglevel": "none"
  },
  "inbounds": [
    {
      "port": ${port},
      "listen": "127.0.0.1",
      "protocol": "vless",
      "settings": {
        "clients": [
          {
            "id": "${uuid}",
            "level": 0,
            "email": "ansoncloud8@gmail.com"
          }
        ],
        "decryption": "none"
      },
      "streamSettings": {
        "network": "ws",
        "security": "none",
        "wsSettings": {
          "path": "/ws?ed=2048"
        }
      }
    }
  ],
  "outbounds": [
    {
      "protocol": "freedom"
    }
  ]
}
EOF
}

function run_app() {
    local action="$1"
    case $action in
        xray)
            run_xray
            ;;
        node)
            run_node
            ;;
        cf)
            run_cloudflared
            ;;		
        reset)
            reset
            ;;					
    esac
}

function set_cronjob() {
    local action=$1
    local cron_job="*/1 * * * *    $base_dir/start.sh check $action"
    crontab -rf
    echo "$cron_job" > temp_crontab
    crontab temp_crontab
    rm temp_crontab
}

function extract_vars() {
    local pattern="$1"
    local env_file="$base_dir/node/.env"

    if [ -f "$env_file" ]; then
        grep "$pattern" "$env_file" | sed 's/^[^=]*=//'
    else
        echo "Error: .env file not found in $base_dir/node/"
        return 1
    fi
}

function main() {
    local action="$1"
    local sub_action="$2"
    case $action in
        setup)
            setup_services $sub_action >/dev/null 2>&1
            ;;
        check)
            check_services $sub_action >/dev/null 2>&1
            ;;
        show)
            show_services $sub_action
            ;;
        reset)
            reset_services 
            ;;
        *)
            echo "Usage: $0 {setup|check|show}"
            exit 1
            ;;
    esac
}

main "$@"
