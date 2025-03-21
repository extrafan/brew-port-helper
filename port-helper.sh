#!/bin/bash

PID_FILE="./port_forward_pids.txt"
SSH_KEY=""
AUTO_STOP_MIN=0

# 彩色
RED=$(tput setaf 1)
GREEN=$(tput setaf 2)
YELLOW=$(tput setaf 3)
BLUE=$(tput setaf 4)
MAGENTA=$(tput setaf 5)
CYAN=$(tput setaf 6)
RESET=$(tput sgr0)
BOLD=$(tput bold)

# 预设端口列表
declare -A PORT_OPTIONS
PORT_OPTIONS=(
  ["1"]="8050:127.0.0.1:8050"
  ["2"]="9050:127.0.0.1:9050"
  ["3"]="9999:127.0.0.1:9999"
  ["4"]="15000:127.0.0.1:15000"
)

function box() {
  echo "${MAGENTA}======================================${RESET}"
  echo "${CYAN}$1${RESET}"
  echo "${MAGENTA}======================================${RESET}"
}

function start_forward() {
  box "🚀 开启端口转发"

  echo "${BOLD}请输入远程主机用户名:${RESET}"
  read REMOTE_USER

  echo "${BOLD}请输入远程主机地址 (IP 或域名):${RESET}"
  read REMOTE_HOST

  echo "${BOLD}是否使用 SSH 私钥认证？(y/n)${RESET}"
  read use_key
  if [[ "$use_key" == "y" ]]; then
    echo "${BOLD}请输入 SSH 私钥路径（例如 ~/.ssh/id_rsa）:${RESET}"
    read SSH_KEY
  fi

  echo "${BOLD}是否设置自动断开时间？(单位: 分钟，输入0表示不自动断开)${RESET}"
  read AUTO_STOP_MIN

  echo "${BOLD}请选择要转发的端口（空格分隔多个，例如: 1 3 4），输入 c 进入自定义模式:${RESET}"
  for key in "${!PORT_OPTIONS[@]}"; do
    echo "${YELLOW}$key) ${PORT_OPTIONS[$key]}${RESET}"
  done
  read -a SELECTED

  CUSTOM_PORTS=()
  if [[ " ${SELECTED[*]} " =~ " c " ]]; then
    echo "${BOLD}🎯 自定义端口模式，输入格式: 本地端口:远程地址:远程端口${RESET}"
    while true; do
      read -p "👉 请输入一个转发规则（输入 done 完成）: " custom
      if [[ "$custom" == "done" ]]; then
        break
      fi
      CUSTOM_PORTS+=("$custom")
    done
  fi

  > $PID_FILE
  echo "${GREEN}✅ 开始建立端口转发...${RESET}"

  for sel in "${SELECTED[@]}"
  do
    if [[ -n "${PORT_OPTIONS[$sel]}" ]]; then
      PORT_MAP="${PORT_OPTIONS[$sel]}"
      start_ssh_forward "$PORT_MAP"
    fi
  done

  for item in "${CUSTOM_PORTS[@]}"
  do
    start_ssh_forward "$item"
  done

  if [[ "$AUTO_STOP_MIN" -gt 0 ]]; then
    echo "${YELLOW}⏲️ 将在 $AUTO_STOP_MIN 分钟后自动断开转发...${RESET}"
    ( sleep $(($AUTO_STOP_MIN * 60)) && stop_forward ) &
  fi

  echo "${GREEN}✅ 端口转发已启动，PID 已记录到 $PID_FILE${RESET}"
}

function start_ssh_forward() {
  PORT_MAP=$1
  LOCAL_PORT=$(echo $PORT_MAP | cut -d':' -f1)
  REMOTE_ADDR=$(echo $PORT_MAP | cut -d':' -f2)
  REMOTE_PORT=$(echo $PORT_MAP | cut -d':' -f3)

  # 检查是否有 autossh
  if command -v autossh >/dev/null 2>&1; then
    if [[ -n "$SSH_KEY" ]]; then
      autossh -M 0 -f -N -i "$SSH_KEY" -L ${LOCAL_PORT}:${REMOTE_ADDR}:${REMOTE_PORT} ${REMOTE_USER}@${REMOTE_HOST}
    else
      autossh -M 0 -f -N -L ${LOCAL_PORT}:${REMOTE_ADDR}:${REMOTE_PORT} ${REMOTE_USER}@${REMOTE_HOST}
    fi
    PID=$!
  else
    if [[ -n "$SSH_KEY" ]]; then
      ssh -f -N -i "$SSH_KEY" -L ${LOCAL_PORT}:${REMOTE_ADDR}:${REMOTE_PORT} ${REMOTE_USER}@${REMOTE_HOST}
    else
      ssh -f -N -L ${LOCAL_PORT}:${REMOTE_ADDR}:${REMOTE_PORT} ${REMOTE_USER}@${REMOTE_HOST}
    fi
    # 等 ssh fork 后真正的 ssh 进程起来
    sleep 1
    PID=$(ps aux | grep "[s]sh.*-L ${LOCAL_PORT}:${REMOTE_ADDR}:${REMOTE_PORT}" | awk '{print $2}')
  fi

  echo "$PID - $LOCAL_PORT --> $REMOTE_ADDR:$REMOTE_PORT" >> $PID_FILE
  echo "${BLUE}👉 http://localhost:${LOCAL_PORT} ${RESET}${YELLOW}--> ${REMOTE_ADDR}:${REMOTE_PORT}${RESET}"
}

function show_status() {
  box "📋 当前端口转发状态"
  if [[ ! -f $PID_FILE ]] || [[ ! -s $PID_FILE ]]; then
    echo "${RED}❌ 当前没有正在运行的转发。${RESET}"
    return
  fi
  cat $PID_FILE | while read line; do
    echo "${CYAN}$line${RESET}"
  done
}

function stop_forward() {
  box "🛑 停止所有端口转发"
  if [[ ! -f $PID_FILE ]] || [[ ! -s $PID_FILE ]]; then
    echo "${RED}❌ 没有找到正在运行的转发。${RESET}"
    return
  fi
  while read line; do
    PID=$(echo $line | awk '{print $1}')
    kill "$PID" 2>/dev/null || kill -9 "$PID" 2>/dev/null
    echo "${MAGENTA}🛑 已关闭进程 PID: $PID${RESET}"
  done < $PID_FILE
  rm -f $PID_FILE
  echo "${GREEN}✅ 所有端口转发已停止。${RESET}"
}

# 菜单
while true; do
  box "🎯 ${BOLD}端口转发管理工具${RESET}"
  echo "${GREEN}1) 开启端口转发${RESET}"
  echo "${YELLOW}2) 查看转发状态${RESET}"
  echo "${RED}3) 关闭所有转发${RESET}"
  echo "${BLUE}4) 退出${RESET}"
  echo "${MAGENTA}======================================${RESET}"
  read -p "请选择操作: " choice

  case $choice in
    1) start_forward ;;
    2) show_status ;;
    3) stop_forward ;;
    4) echo "${CYAN}👋 Bye~${RESET}"; exit 0 ;;
    *) echo "${RED}无效选择，请重新输入。${RESET}";;
  esac
done

