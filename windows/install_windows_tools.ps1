# Windows 宿主机一键安装/部署脚本 (以 PowerShell 运行)
$ahkTarget = "$env:LOCALAPPDATA\Programs\AutoHotkey"
$startupTarget = "$env:APPDATA\Microsoft\Windows\Start Menu\Programs\Startup"

New-Item -ItemType Directory -Force -Path $ahkTarget | Out-Null
New-Item -ItemType Directory -Force -Path $startupTarget | Out-Null

$scriptDir = Split-Path -Parent $MyInvocation.MyCommand.Path

Copy-Item "$scriptDir\ahk\*" $ahkTarget -Recurse -Force
Copy-Item "$scriptDir\startup\*" $startupTarget -Recurse -Force

Write-Host "✅ 已将 AHK 守护脚本与工作区管理器安装至: $ahkTarget" -ForegroundColor Green
Write-Host "✅ 已将开机自启快捷方式安装至: $startupTarget" -ForegroundColor Green

# 检查 VirtualDesktop.exe
$vdPath = "$ahkTarget\VirtualDesktop.exe"
if (-not (Test-Path $vdPath)) {
    Write-Host "⚠️ 未检测到 VirtualDesktop.exe，正在从 GitHub 下载 MScholtes/VirtualDesktop (24H2)..." -ForegroundColor Yellow
    Invoke-WebRequest -Uri "https://github.com/MScholtes/VirtualDesktop/releases/latest/download/VirtualDesktop11-24H2.exe" -OutFile $vdPath
    Write-Host "✅ VirtualDesktop.exe 下载完成" -ForegroundColor Green
}
