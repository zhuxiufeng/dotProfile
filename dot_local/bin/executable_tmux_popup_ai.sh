#!/usr/bin/env bash
# /home/zxf/.local/bin/tmux_popup_ai.sh
# 极速拉起或隐退常驻的 Antigravity AI 伴写浮窗

SOCKET="popup_ai"
SESSION="ai"
TARGET_DIR="${1:-$PWD}"

# 如果后台专属会话未启动，先初始化并配置纯净界面与单键脱离
if ! tmux -L "$SOCKET" has-session -t "$SESSION" 2>/dev/null; then
    tmux -L "$SOCKET" new-session -d -s "$SESSION" -c "$TARGET_DIR" "/home/zxf/.local/bin/agy"
    tmux -L "$SOCKET" set-option -g status off
    tmux -L "$SOCKET" set-option -g mouse on
    tmux -L "$SOCKET" bind-key -n M-a detach-client
    tmux -L "$SOCKET" bind-key -n M-q detach-client
fi

# 接入后台 AI 会话（脱离或关闭时，浮窗自动隐退）
exec tmux -L "$SOCKET" attach-session -t "$SESSION"
