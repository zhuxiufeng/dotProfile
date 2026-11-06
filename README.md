# Dotfiles & Workspace Environment

通过 **chezmoi** 管理的 WSL2 + Windows 自动化多桌面工作区、输入法智能切换与 tmux 远程运维环境。

## 目录结构说明

- `dot_tmux.conf`: tmux 高级配置（含鼠标智能切换、会话持久化、AI 浮窗 Alt+A、SSH 重连保护等）
- `dot_local/bin/`: 常用高频命令（`sshr` 自动重连、`tmux_popup_ai.sh` 独立浮窗、`wsl_hotspot_proxy` 热点直通代理）
- `private_dot_ssh/`: SSH 配置模板（动态适配当前用户的 home 目录）
- `.chezmoiscripts/`: 自动化部署钩子（自动克隆安装 TPM 插件管理器并赋权可执行文件）
- `windows/`: Windows 宿主机专属工具包（AHK 终端智能切英文、Win11 多虚拟桌面自动快照与一键恢复）

## 在新电脑上一键恢复指南

### 1. WSL2 / Linux 侧一键恢复

在新的 WSL2 实例中运行：

```bash
# 1. 安装 chezmoi (若未安装)
sh -c "$(curl -fsLS get.chezmoi.io)" -- -b ~/.local/bin

# 2. 从 GitHub / Gitee 拉取配置并自动生效 (替换为你自己的 repo 链接)
~/.local/bin/chezmoi init --apply <your-repo-url>
```

### 2. Windows 宿主机侧一键恢复

在 Windows PowerShell 中进入已挂载的 chezmoi 源码目录执行一键安装：

```powershell
# 运行安装脚本 (自动部署 AHK 脚本、自启动项并自动获取 24H2 兼容版 VirtualDesktop.exe)
powershell.exe -ExecutionPolicy Bypass -File \\wsl$\Ubuntu\home\<user>\.local\share\chezmoi\windows\install_windows_tools.ps1
```
