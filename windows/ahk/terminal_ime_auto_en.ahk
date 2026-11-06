#Requires AutoHotkey v2.0+
#SingleInstance Force

TraySetIcon("shell32.dll", 44)
A_IconTip := "终端回车智能切英文 (运行中)"

; 监听包含终端、IDE在内的所有命令行与代码编辑窗口
#HotIf WinActive("ahk_exe WindowsTerminal.exe") or WinActive("ahk_exe Antigravity IDE.exe") or WinActive("ahk_exe Code.exe") or WinActive("ahk_exe cmd.exe") or WinActive("ahk_exe powershell.exe")

~Enter::
~NumpadEnter:: {
    ; 等待松开回车键，避免 Enter+Shift 组合键冲突
    KeyWait("Enter")
    KeyWait("NumpadEnter")
    Sleep 40
    
    try {
        hWnd := WinGetID("A")
        hIME := DllCall("imm32\ImmGetDefaultIMEWnd", "Ptr", hWnd, "Ptr")
        if (!hIME)
            return
            
        ; 获取打开状态 (1=开启, 0=关闭)
        openStatus := DllCall("user32\SendMessage", "Ptr", hIME, "UInt", 0x0283, "UPtr", 0x005, "Int", 0, "Int")
        ; 获取转换模式 (中文模式 bit 8 为 0，如 1；英文模式 bit 8 为 1 即 0x0100，如 257)
        convMode := DllCall("user32\SendMessage", "Ptr", hIME, "UInt", 0x0283, "UPtr", 0x001, "Int", 0, "Int")
        
        ; 如果当前处于开启状态且为中文模式 ((convMode & 0x0100) == 0)
        if (openStatus == 1 && (convMode & 0x0100) == 0) {
            ; 模拟按下标准的全局 VK_SHIFT (0x10)，保持 40ms 物理时延，使微软拼音平滑切换为英文模式
            DllCall("user32\keybd_event", "UChar", 0x10, "UChar", 0x2A, "UInt", 0, "UPtr", 0)
            Sleep 40
            DllCall("user32\keybd_event", "UChar", 0x10, "UChar", 0x2A, "UInt", 2, "UPtr", 0)
        }
    }
}
