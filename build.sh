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

ARGS=$(getopt -o a::cb::cdrptih -l clone::,debug,release,push,test,init,help -n "${cmd}" -- "$@")
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
            build_to_tar
            exit 0
            ;;
        -p | --push)
            echo "push mining_proxy.tar.gz to github.com"
            shift
            push_to_github
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
    echo "Usage:"${cmd}" options {-c,--clone | -d,--debug | -r,--release | -p,--push | -t,--test | -i,--init | -h}"
}

check_gh() {
  if [ -f "/usr/bin/gh" ]; then
    RESULT=$(gh --version)
    RESULT=${RESULT:11:5}
    #echo $RESULT
    RESULT=${RESULT%.*}
  else
    RESULT=""
  fi
  echo $RESULT
  if [ -z $RESULT ]; then
    # gh-source
    curl -fsSL https://cli.github.com/packages/githubcli-archive-keyring.gpg | sudo dd of=/etc/apt/trusted.gpg.d/githubcli-archive-keyring.gpg
    echo "deb [arch=$(dpkg --print-architecture) signed-by=/etc/apt/trusted.gpg.d/githubcli-archive-keyring.gpg] https://cli.github.com/packages stable main" | sudo tee /etc/apt/sources.list.d/github-cli.list > /dev/null
    sudo apt update
    
    # gh
    sudo apt install gh
    
    # check
    gh --version
  elif [ `expr $RESULT \> 2.4` -eq 0 ]; then
    echo "gh version must >= 2.4 "
    
    # gh
    sudo apt install gh
    
    # check
    gh --version
  fi
  echo " "
  gh_ver=1
  #return 1
}

build_to_tar(){
    # 打包
    cd ./target/release
    echo -e "\033[34m tar -zcvf ../../mining_proxy.tar.gz ./encrypt ./mining_proxy \033[0m"
    tar -zcvf ../../mining_proxy.tar.gz ./encrypt ./mining_proxy
    cd -
    echo "`ls -lrt ./mining_proxy.tar.gz`"
    ls -l ./mining_proxy.tar.gz
    echo ""
}

push_to_github(){
    check_gh
    if [ $gh_ver -eq 1 ]; then
      #获取tag标签
      __release_sha1=$(git rev-parse HEAD)
      echo $__release_sha1
      if [ $(gh release list |grep Draft |grep ${__release_sha1:0:16} |wc -l) -eq 1 ]; then
        #删除Draft
        gh release delete ${__release_sha1:0:16} -y
      fi
      if [ $(gh release list |grep ${__release_sha1:0:16} |wc -l) -eq 0 ]; then
        #打包
        if [ -f ./mining_proxy.tar.gz ]; then
          rm ./mining_proxy.tar.gz
        fi
        cd ./target/release
        echo -e "\033[34m tar -zcvf ../../mining_proxy.tar.gz ./encrypt ./mining_proxy \033[0m"
        tar -zcvf ../../mining_proxy.tar.gz ./encrypt ./mining_proxy
        cd -
        echo ""
        echo -e "\033[34m ls -lrt ./mining_proxy.tar.gz \033[0m"
        echo "`ls -lrt ./mining_proxy.tar.gz`"
        echo ""

        #推送tag
        gh release create ${__release_sha1:0:16} ./mining_proxy.tar.gz -t ${__release_sha1:0:16} --target ${__release_sha1} -n "mining_proxy add auto-tag ${__release_sha1:0:16}"
      fi
      echo ""
    fi
}

main   "$@"