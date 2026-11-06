#!/usr/bin/env bash
# /home/zxf/.local/bin/tmux_popup_runner.sh
# 彻底使用用户默认的 Zsh + Oh-My-Zsh + zsh-autosuggestions 极速环境
# 保持与主终端一致的原生鼠标体验（支持 Windows Terminal 原生鼠标划选与右键直接复制）

SOCKET="popup_runner"
SESSION="runner"
TARGET_DIR="${1:-$PWD}"
USER_SHELL="${SHELL:-/usr/bin/zsh}"

# 如果后台浮窗会话未启动，初始化会话与键位
if ! tmux -L "$SOCKET" has-session -t "$SESSION" 2>/dev/null; then
    tmux -L "$SOCKET" new-session -d -s "$SESSION" -c "$TARGET_DIR" "$USER_SHELL -l"
    tmux -L "$SOCKET" set-option -g status off
    
    # 默认关闭 tmux 内部鼠标拦截，让 Windows Terminal 原生接管鼠标（划选后右键秒进剪贴板）
    tmux -L "$SOCKET" set-option -g mouse off
    tmux -L "$SOCKET" set-option -s set-clipboard on
    
    # 绑定 copy-mode 下的右键与划选直接导入 Windows 剪贴板
    tmux -L "$SOCKET" bind-key -T copy-mode MouseUp3Pane send-keys -X copy-pipe-and-cancel "/mnt/c/WINDOWS/system32/clip.exe"
    tmux -L "$SOCKET" bind-key -T copy-mode-vi MouseUp3Pane send-keys -X copy-pipe-and-cancel "/mnt/c/WINDOWS/system32/clip.exe"
    tmux -L "$SOCKET" bind-key -T copy-mode MouseDragEnd1Pane send-keys -X copy-pipe "/mnt/c/WINDOWS/system32/clip.exe"
    tmux -L "$SOCKET" bind-key -T copy-mode-vi MouseDragEnd1Pane send-keys -X copy-pipe "/mnt/c/WINDOWS/system32/clip.exe"

    # 绑定 Alt+r 与 Alt+q 单键秒收起
    tmux -L "$SOCKET" bind-key -n M-r detach-client
    tmux -L "$SOCKET" bind-key -n M-q detach-client
else
    # 会话已存在时，平滑切到当前窗格所在路径
    tmux -L "$SOCKET" send-keys -t "$SESSION" " cd '$TARGET_DIR' && clear" Enter
fi

# 接入浮窗会话
exec tmux -L "$SOCKET" attach-session -t "$SESSION"
