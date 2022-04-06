#!/bin/bash

# http_proxy https_proxy
ENV_LOG_DIR=$(cd `dirname $0`; pwd)
if [ -f $ENV_LOG_DIR/.env_proxy ]; then
  source $ENV_LOG_DIR/.env_proxy
else
  while [ ! -f $ENV_LOG_DIR/.env_proxy ]
  do
    #lotus_proxy
    read -e -p '  please input https_proxy:' lotus_proxy
    #echo ' '
    echo "
# PROXY
export http_proxy=$lotus_proxy
export https_proxy=$lotus_proxy
# TMP
export TMPDIR=\$(cd \`dirname $0\`; pwd)/tmp
# RUST
export RUSTUP_DIST_SERVER=https://mirrors.sjtug.sjtu.edu.cn/rust-static
export RUSTUP_UPDATE_ROOT=https://mirrors.sjtug.sjtu.edu.cn/rust-static/rustup
" > $ENV_LOG_DIR/.env_proxy
    
  done
  echo " "
fi
# tips
if [ -f $ENV_LOG_DIR/.env_proxy ]; then
  source $ENV_LOG_DIR/.env_proxy
fi
echo -e "\033[34m http_proxy=$http_proxy \033[0m"
echo -e "\033[34m https_proxy=$https_proxy \033[0m"

# # env
# sudo apt install npm -y
# # release
# env RUST_BACKTRACE=full RUST_LOG=debug cargo build --release
# # debug
# env RUST_BACKTRACE=full RUST_LOG=debug cargo build --debug
# # test
# env RUST_BACKTRACE=full RUST_LOG=debug cargo test
set -e
set -o pipefail

cmd=$(basename $0)

ARGS=$(getopt -o a::cb::cdrtih -l clone::,debug,release,test,init,help -n "${cmd}" -- "$@")
eval set -- "${ARGS}"

ROOT_PATH=$(
    cd "$(dirname "$0")"
    pwd
)

main() {
    while true; do
        case "${1}" in
        -c | --clone)
            echo "git clone https://github.com/etpool/mining_proxy_web web"
            shift
            # rm web -rf
            # git clone https://github.com/etpool/mining_proxy_web web
            exit 0
            ;;
        -d | --debug)
            echo "cargo build --debug"
            shift
            env RUST_BACKTRACE=full cargo build
            exit 0
            ;;
        -r | --release)
            echo "cargo build --release"
            shift
            env RUST_BACKTRACE=full cargo build --release
            exit 0
            ;;
        -t | --test)
            echo "cargo test"
            shift
            env RUST_BACKTRACE=full cargo test
            exit 0
            ;;
        -i | --init)
            echo "apt install npm"
            shift
            sudo apt install npm -y
            exit 0
            ;;
        --)
            echo "cargo build"
            shift
            env RUST_BACKTRACE=full cargo build
            exit 0
            ;;
        --)
            shift
            break
            ;;
        *)
            Usage
            exit 0
            ;;
        esac
    done

    Usage
    exit 0
}

Usage() {
    echo "Usage:"${cmd}" options {-c,--clone | -d,--debug | -r,--release | -t,--test | -i,--init | -h}"
}

main   "$@"