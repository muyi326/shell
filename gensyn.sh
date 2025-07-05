#!/bin/bash
set -euo pipefail

log_file="./deploy_rl_swarm_0.5.log"
max_retries=100
retry_count=0

info() {
    echo -e "[INFO] $*" | tee -a "$log_file"
}

error() {
    echo -e "[ERROR] $*" >&2 | tee -a "$log_file"
    if [ $retry_count -lt $max_retries ]; then
        retry_count=$((retry_count+1))
        info "自动重试 ($retry_count/$max_retries)..."
        exec "$0" "$@"
    else
        exit 1
    fi
}

# 新增函数：封装 docker-compose run 并捕获错误
run_docker_compose() {
    local attempt=1
    while [ $attempt -le $max_retries ]; do
        info "尝试运行容器 (第 $attempt 次)..."
        if docker-compose run --rm --build -Pit swarm-cpu; then
            return 0  # 成功则退出函数
        else
            info "Docker 构建失败，师爷正在用意念安装..."
            sleep 2
            ((attempt++))
        fi
    done
    error "Docker 构建超过最大重试次数 ($max_retries 次)"
}

# ... (前面的 Homebrew/Docker 检查代码保持不变) ...

cd rl-swarm-0.5 || error "进入 rl-swarm-0.5 目录失败"

info "🚀 运行 swarm-cpu 容器..."
run_docker_compose  # 替换原来的直接运行命令