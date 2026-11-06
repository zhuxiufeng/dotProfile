#!/usr/bin/env bash
# /home/zxf/.local/bin/tmux_popup_runner.sh
# tmux 浮窗命令运行器：支持单次命令执行、交互式终端、完整环境变量与Tab补全

TARGET_DIR="${1:-$PWD}"
cd "$TARGET_DIR" || exit 1

GREEN="\033[1;32m"
BLUE="\033[1;34m"
YELLOW="\033[1;33m"
CYAN="\033[1;36m"
RED="\033[1;31m"
RESET="\033[0m"

# 如果传入了要执行的命令
if [ -n "$2" ]; then
    clear
    echo -e "${CYAN}╔══════════════════════════════════════════════════════════════╗${RESET}"
    echo -e "${CYAN}║${RESET}  ${GREEN}⚡ 浮窗命令执行 (tmux Popup Exec)${RESET}                        ${CYAN}║${RESET}"
    echo -e "${CYAN}║${RESET}  目录: ${BLUE}${TARGET_DIR}${RESET}"
    echo -e "${CYAN}║${RESET}  命令: ${YELLOW}${2}${RESET}"
    echo -e "${CYAN}╚══════════════════════════════════════════════════════════════╝${RESET}"
    echo ""
    
    START_TIME=$(date +%s)
    bash -c "$2"
    STATUS=$?
    END_TIME=$(date +%s)
    ELAPSED=$((END_TIME - START_TIME))
    
    echo ""
    echo -e "${CYAN}────────────────────────────────────────────────────────────${RESET}"
    if [ $STATUS -eq 0 ]; then
        echo -e "${GREEN}✔ 命令执行完毕 (耗时: ${ELAPSED}s, 退出码: 0)${RESET}"
    else
        echo -e "${RED}✘ 命令异常退出 (耗时: ${ELAPSED}s, 退出码: $STATUS)${RESET}"
    fi
    echo -e "${YELLOW}提示: 按任意键退出浮窗...${RESET}"
    read -n 1 -s -r
    exit $STATUS
fi

# 无参数时，进入交互式快速临时终端
clear
echo -e "${CYAN}╔══════════════════════════════════════════════════════════════╗${RESET}"
echo -e "${CYAN}║${RESET}  ${GREEN}⚡ 浮窗临时终端 (tmux Scratchpad Terminal)${RESET}              ${CYAN}║${RESET}"
echo -e "${CYAN}║${RESET}  目录: ${BLUE}${TARGET_DIR}${RESET}"
echo -e "${CYAN}║${RESET}  提示: 输入 ${YELLOW}exit${RESET} 或按 ${YELLOW}Ctrl+D${RESET} 退出并关闭浮窗               ${CYAN}║${RESET}"
echo -e "${CYAN}╚══════════════════════════════════════════════════════════════╝${RESET}"
echo ""

RC_INIT='[ -f ~/.bashrc ] && source ~/.bashrc; PS1="\[\033[1;32m\][⚡浮窗 \W]\[\033[0m\]$ "'
exec bash --rcfile <(echo "$RC_INIT") -i
