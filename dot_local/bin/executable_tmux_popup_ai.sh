#!/usr/bin/env bash
# /home/zxf/.local/bin/tmux_popup_ai.sh
# 极速拉起或隐退常驻的 Antigravity AI 伴写浮窗

SOCKET="popup_ai"
SESSION="ai"
TARGET_DIR="${1:-$PWD}"

if ! tmux -L "$SOCKET" has-session -t "$SESSION" 2>/dev/null; then
    tmux -L "$SOCKET" new-session -d -s "$SESSION" -c "$TARGET_DIR" "/home/zxf/.local/bin/agy"
    tmux -L "$SOCKET" set-option -g status off
    
    tmux -L "$SOCKET" set-option -g mouse off
    tmux -L "$SOCKET" set-option -s set-clipboard on

    tmux -L "$SOCKET" bind-key -n M-a detach-client
    tmux -L "$SOCKET" bind-key -n M-q detach-client
fi

exec tmux -L "$SOCKET" attach-session -t "$SESSION"
