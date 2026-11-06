#!/usr/bin/env bash
# /home/zxf/.local/bin/tmux_popup_runner.sh
# 极致响应速度、全功能自动补全、无缝 Tab 体验的浮窗命令运行器

SOCKET="popup_runner"
SESSION="runner"
TARGET_DIR="${1:-$PWD}"

# 准备专用的极速 bash 初始化环境配置文件
RUNNER_RC="$HOME/.cache/tmux_runner_bashrc"
mkdir -p "$HOME/.cache"

cat << 'RCEOF' > "$RUNNER_RC"
# 1. 优先加载用户完整的 ~/.bashrc 环境（包含所有别名、函数与环境变量）
[ -f ~/.bashrc ] && source ~/.bashrc

# 2. 强制确保完整的 bash-completion 补全体系加载
if [ -f /usr/share/bash-completion/bash_completion ]; then
    source /usr/share/bash-completion/bash_completion
elif [ -f /etc/bash_completion ]; then
    source /etc/bash_completion
fi

# 3. Readline 补全极速优化配置（单次 Tab 即展示候选，忽略大小写，彩色高亮）
bind 'set show-all-if-ambiguous on'
bind 'set completion-ignore-case on'
bind 'set colored-stats on'
bind 'set mark-symlinked-directories on'
bind 'set menu-complete-display-prefix on'

# 4. 优化 PATH 顺序，确保 Linux 原生路径优先，杜绝 Windows 跨盘扫描卡顿
CLEAN_PATH="/home/zxf/.gemini/antigravity-cli/bin:/home/zxf/.local/bin:/usr/local/sbin:/usr/local/bin:/usr/sbin:/usr/bin:/sbin:/bin"
export PATH="$CLEAN_PATH:$PATH"

# 5. 醒目的提示符
export PS1="\[\033[1;36m\]⚡[Runner \W]\[\033[1;32m\]❯\[\033[0m\] "

# 6. 打印炫酷的极速运行台欢迎 Banner
clear
echo -e "\033[1;36m"
cat << 'ART'
  ██████╗ ██╗   ██╗███╗   ██╗███╗   ██╗███████╗██████╗ 
  ██╔══██╗██║   ██║████╗  ██║████╗  ██║██╔════╝██╔══██╗
  ██████╔╝██║   ██║██╔██╗ ██║██╔██╗ ██║█████╗  ██████╔╝
  ██╔══██╗██║   ██║██║╚██╗██║██║╚██╗██║██╔══╝  ██╔══██╗
  ██║  ██║╚██████╔╝██║ ╚████║██║ ╚████║███████╗██║  ██║
  ╚═╝  ╚═╝ ╚═════╝ ╚═╝  ╚═══╝╚═╝  ╚═══╝╚══════╝╚═╝  ╚═╝
ART
echo -e "\033[0m"
echo -e "\033[1;32m  ⚡ 极速浮窗命令运行台 (Tab秒级智能补全就绪)\033[0m"
echo -e "\033[1;34m  ──────────────────────────────────────────────────────────\033[0m"
echo -e "  📁 工作目录: \033[1;33m$PWD\033[0m"
echo -e "  💡 快捷操作: 按 \033[1;35mAlt+r\033[0m 秒级隐退/唤出 | 输入 \033[1;31mexit\033[0m 销毁重置"
echo -e "\033[1;34m  ──────────────────────────────────────────────────────────\033[0m"
echo ""
RCEOF

# 检查后台浮窗会话
if ! tmux -L "$SOCKET" has-session -t "$SESSION" 2>/dev/null; then
    # 直接以交互式模式加载专用 RC 启动
    tmux -L "$SOCKET" new-session -d -s "$SESSION" -c "$TARGET_DIR" "bash --rcfile '$RUNNER_RC' -i"
    tmux -L "$SOCKET" set-option -g status off
    tmux -L "$SOCKET" set-option -g mouse on
    # 绑定 Alt+r 与 Alt+q 单键秒收起
    tmux -L "$SOCKET" bind-key -n M-r detach-client
    tmux -L "$SOCKET" bind-key -n M-q detach-client
else
    # 会话已存在时，平滑切到当前窗格所在路径
    tmux -L "$SOCKET" send-keys -t "$SESSION" " cd '$TARGET_DIR' && clear" Enter
fi

# 接入浮窗会话
exec tmux -L "$SOCKET" attach-session -t "$SESSION"
