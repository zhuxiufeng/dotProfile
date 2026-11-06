#Requires AutoHotkey v2.0+
#SingleInstance Force

TraySetIcon("shell32.dll", 278)
A_IconTip := "工作区多虚拟桌面自动快照守护 (运行中)"

; 创建右键托盘菜单
A_TrayMenu.Delete()
A_TrayMenu.Add("📸 立即保存工作区快照 (Alt+F12)", (*) => ManualSnapshot())
A_TrayMenu.Add("🔄 一键恢复工作区布局 (Alt+F11)", (*) => ManualRestore())
A_TrayMenu.Add()
A_TrayMenu.Add("📁 打开快照配置文件", (*) => Run("notepad.exe `"" . A_ScriptDir . "\workspace_layout.json`""))
A_TrayMenu.Add()
A_TrayMenu.Add("退出守护程序", (*) => ExitApp())

; 每 1 小时自动执行一次智能静默快照（未改变则 0 磁盘写入，无任何弹窗和窗口闪烁）
SetTimer(AutoSnapshot, 60 * 60 * 1000)

; 快捷键绑定
!F12::ManualSnapshot() ; Alt + F12 立即快照
!F11::ManualRestore()  ; Alt + F11 立即恢复

ManualSnapshot() {
    RunPS("Snapshot")
}

ManualRestore() {
    RunPS("Restore")
}

AutoSnapshot() {
    RunPS("Snapshot")
}

RunPS(action) {
    psScript := A_ScriptDir . "\workspace_manager.ps1"
    cmd := 'powershell.exe -NoProfile -WindowStyle Hidden -ExecutionPolicy Bypass -File "' . psScript . '" -Action ' . action
    ; 使用 AHK 原生 "Hide" 模式静默执行，彻底杜绝黑框闪烁与弹窗提示
    RunWait(cmd, , "Hide")
}
