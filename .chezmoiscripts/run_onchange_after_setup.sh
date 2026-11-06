#!/bin/bash
set -e

# 1. 检查并安装 TPM (Tmux Plugin Manager)
if [ ! -d "$HOME/.tmux/plugins/tpm" ]; then
    echo "📦 正在安装 Tmux Plugin Manager (TPM)..."
    git clone https://github.com/tmux-plugins/tpm "$HOME/.tmux/plugins/tpm" || true
fi

# 2. 保证可执行权限
chmod +x "$HOME/.local/bin/sshr" 2>/dev/null || true
chmod +x "$HOME/.local/bin/tmux_popup_ai.sh" 2>/dev/null || true
chmod +x "$HOME/.local/bin/wsl_hotspot_proxy" 2>/dev/null || true

echo "✅ WSL 环境配置就绪"
