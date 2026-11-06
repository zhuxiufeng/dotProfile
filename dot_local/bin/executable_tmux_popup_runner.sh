#!/usr/bin/env bash
# /home/zxf/.local/bin/tmux_popup_runner.sh
# 像 Alt+a 一样极速呼出/隐退的醒目命令运行台

SOCKET="popup_runner"
SESSION="runner"
TARGET_DIR="${1:-$PWD}"

# 如果专属后台会话不存在，初始化一个带醒目欢迎界面的常驻终端
if ! tmux -L "$SOCKET" has-session -t "$SESSION" 2>/dev/null; then
    # 创建初始化欢迎脚本
    INIT_SCRIPT=$(mktemp /tmp/tmux_runner_init.XXXXXX.sh)
    cat << 'BANNER_EOF' > "$INIT_SCRIPT"
#!/usr/bin/env bash
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
echo -e "\033[1;32m  ⚡ 极速浮窗命令运行台 (Popup Command Runner)\033[0m"
echo -e "\033[1;34m  ──────────────────────────────────────────────────────────\033[0m"
echo -e "  📁 当前工作目录: \033[1;33m$PWD\033[0m"
echo -e "  💡 快捷操作: 按 \033[1;35mAlt+r\033[0m 秒级隐退/呼出 | 输入 \033[1;31mexit\033[0m 销毁重置"
echo -e "\033[1;34m  ──────────────────────────────────────────────────────────\033[0m"
echo ""

# 自定义醒目的提示符并进入交互式 bash
export PS1="\[\033[1;36m\]⚡[Runner \W]\[\033[1;32m\]❯\[\033[0m\] "
[ -f ~/.bashrc ] && source ~/.bashrc
export PS1="\[\033[1;36m\]⚡[Runner \W]\[\033[1;32m\]❯\[\033[0m\] "
exec bash -i
BANNER_EOF
    chmod +x "$INIT_SCRIPT"

    tmux -L "$SOCKET" new-session -d -s "$SESSION" -c "$TARGET_DIR" "bash '$INIT_SCRIPT'; rm -f '$INIT_SCRIPT'"
    tmux -L "$SOCKET" set-option -g status off
    tmux -L "$SOCKET" set-option -g mouse on
    # 绑定 Alt+r 和 Alt+q 直接脱离（一键秒收起）
    tmux -L "$SOCKET" bind-key -n M-r detach-client
    tmux -L "$SOCKET" bind-key -n M-q detach-client
else
    # 会话已存在时，平滑切换到当前目录
    tmux -L "$SOCKET" send-keys -t "$SESSION" "cd '$TARGET_DIR'" Enter
fi

# 接入专属会话（浮窗关闭或脱离时自动收起）
exec tmux -L "$SOCKET" attach-session -t "$SESSION"
