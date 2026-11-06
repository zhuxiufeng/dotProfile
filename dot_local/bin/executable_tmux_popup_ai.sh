#!/usr/bin/env bash
# /home/zxf/.local/bin/tmux_popup_ai.sh
# 极速拉起或隐退常驻的 Antigravity AI 伴写浮窗
# 保持与主终端一致的原生鼠标体验（支持 Windows Terminal 原生鼠标划选与右键直接复制）

SOCKET="popup_ai"
SESSION="ai"
TARGET_DIR="${1:-$PWD}"

if ! tmux -L "$SOCKET" has-session -t "$SESSION" 2>/dev/null; then
    tmux -L "$SOCKET" new-session -d -s "$SESSION" -c "$TARGET_DIR" "/home/zxf/.local/bin/agy"
    tmux -L "$SOCKET" set-option -g status off
    
    # 默认关闭 tmux 内部鼠标拦截，让 Windows Terminal 原生接管鼠标（划选后右键秒进剪贴板）
    tmux -L "$SOCKET" set-option -g mouse off
    tmux -L "$SOCKET" set-option -s set-clipboard on
    
    # 绑定 copy-mode 下的右键与划选直接导入 Windows 剪贴板
    tmux -L "$SOCKET" bind-key -T copy-mode MouseUp3Pane send-keys -X copy-pipe-and-cancel "/mnt/c/WINDOWS/system32/clip.exe"
    tmux -L "$SOCKET" bind-key -T copy-mode-vi MouseUp3Pane send-keys -X copy-pipe-and-cancel "/mnt/c/WINDOWS/system32/clip.exe"
    tmux -L "$SOCKET" bind-key -T copy-mode MouseDragEnd1Pane send-keys -X copy-pipe "/mnt/c/WINDOWS/system32/clip.exe"
    tmux -L "$SOCKET" bind-key -T copy-mode-vi MouseDragEnd1Pane send-keys -X copy-pipe "/mnt/c/WINDOWS/system32/clip.exe"

    tmux -L "$SOCKET" bind-key -n M-a detach-client
    tmux -L "$SOCKET" bind-key -n M-q detach-client
fi

exec tmux -L "$SOCKET" attach-session -t "$SESSION"
