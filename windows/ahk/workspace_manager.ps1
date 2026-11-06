# Windows 11 Multi-VirtualDesktop Workspace Manager
param(
    [Parameter(Mandatory=$false)]
    [ValidateSet('Snapshot', 'Restore', 'Status')]
    [string]$Action = 'Snapshot'
)

$ErrorActionPreference = 'SilentlyContinue'
$ScriptDir = Split-Path -Parent $MyInvocation.MyCommand.Definition
$VDExe = Join-Path $ScriptDir "VirtualDesktop.exe"
$JsonPath = Join-Path $ScriptDir "workspace_layout.json"

Add-Type @"
using System;
using System.Text;
using System.Runtime.InteropServices;

public class WinHelper {
    [DllImport("user32.dll")]
    public static extern int GetWindowText(IntPtr hWnd, StringBuilder text, int count);
    [DllImport("user32.dll")]
    public static extern uint GetWindowThreadProcessId(IntPtr hWnd, out uint processId);
    [DllImport("user32.dll")]
    public static extern bool GetWindowPlacement(IntPtr hWnd, ref WINDOWPLACEMENT lpwndpl);
    [DllImport("user32.dll")]
    public static extern bool SetWindowPlacement(IntPtr hWnd, ref WINDOWPLACEMENT lpwndpl);
    [DllImport("user32.dll")]
    public static extern bool SetWindowPos(IntPtr hWnd, IntPtr hWndInsertAfter, int X, int Y, int cx, int cy, uint uFlags);
    [DllImport("user32.dll")]
    public static extern bool ShowWindow(IntPtr hWnd, int nCmdShow);

    public struct POINT { public int x; public int y; }
    public struct RECT { public int Left, Top, Right, Bottom; }
    public struct WINDOWPLACEMENT {
        public int length;
        public int flags;
        public int showCmd;
        public POINT ptMinPosition;
        public POINT ptMaxPosition;
        public RECT rcNormalPosition;
    }
}
"@

function Get-WorkspaceSnapshot {
    if (-not (Test-Path $VDExe)) {
        Write-Error "VirtualDesktop.exe not found at $VDExe"
        return
    }

    $cntOut = (& $VDExe /Count 2>$null) -join "`n"
    $desktopCount = 1
    if ($cntOut -match '(\d+)') {
        $desktopCount = [int]$matches[1]
    }

    $apps = @()
    for ($d = 0; $d -lt $desktopCount; $d++) {
        $winList = (& $VDExe "/ListWindowsOnDesktop:$d" 2>$null) -join "`n"
        foreach ($line in ($winList -split "`n")) {
            $line = $line.Trim()
            if ($line -match '^\d+$') {
                $hwndInt = [int64]$line
                $hwnd = [IntPtr]$hwndInt

                $sb = New-Object System.Text.StringBuilder 256
                [WinHelper]::GetWindowText($hwnd, $sb, 256) | Out-Null
                $title = $sb.ToString().Trim()
                if ([string]::IsNullOrEmpty($title)) { continue }

                $wPid = 0
                [WinHelper]::GetWindowThreadProcessId($hwnd, [ref]$wPid) | Out-Null
                if ($wPid -le 4) { continue }

                $procName = ""
                $procPath = ""
                try {
                    $proc = Get-Process -Id $wPid -ErrorAction Stop
                    $procName = $proc.ProcessName
                    $procPath = $proc.Path
                    if (-not $procPath) {
                        $procPath = $proc.MainModule.FileName
                    }
                } catch {
                    continue
                }

                # Filter system / invisible utilities
                if ($procName -match '^(ShellExperienceHost|StartMenuExperienceHost|SearchHost|TextInputHost|ApplicationFrameHost|SystemSettings)$') { continue }
                if ($procName -eq 'explorer' -and $title -match '^(Program Manager|任务切换)$') { continue }

                $wp = New-Object WinHelper+WINDOWPLACEMENT
                $wp.length = [System.Runtime.InteropServices.Marshal]::SizeOf($wp)
                [WinHelper]::GetWindowPlacement($hwnd, [ref]$wp) | Out-Null

                $norm = $wp.rcNormalPosition
                $rectW = $norm.Right - $norm.Left
                $rectH = $norm.Bottom - $norm.Top

                # showCmd: 1 = normal, 2 = minimized, 3 = maximized
                $apps += [PSCustomObject]@{
                    Desktop  = $d
                    Process  = $procName
                    Path     = $procPath
                    Title    = $title
                    ShowCmd  = $wp.showCmd
                    X        = $norm.Left
                    Y        = $norm.Top
                    W        = $rectW
                    H        = $rectH
                }
            }
        }
    }

    $result = [PSCustomObject]@{
        Timestamp    = (Get-Date).ToString("yyyy-MM-dd HH:mm:ss")
        DesktopCount = $desktopCount
        Windows      = $apps
    }

    $json = $result | ConvertTo-Json -Depth 5
    
    # Check if changed to avoid unnecessary disk I/O
    if (Test-Path $JsonPath) {
        $oldJson = Get-Content $JsonPath -Raw -Encoding UTF8
        $oldObj = $oldJson | ConvertFrom-Json
        $oldWinJson = $oldObj.Windows | ConvertTo-Json -Depth 4
        $newWinJson = $apps | ConvertTo-Json -Depth 4
        if ($oldWinJson -eq $newWinJson) {
            Write-Output "UNCHANGED: $($apps.Count) windows across $desktopCount desktops."
            return
        }
    }

    # Atomic write
    $tmpPath = "$JsonPath.tmp"
    [System.IO.File]::WriteAllText($tmpPath, $json, [System.Text.Encoding]::UTF8)
    Move-Item -Path $tmpPath -Destination $JsonPath -Force
    Write-Output "SAVED: $($apps.Count) windows across $desktopCount desktops."
}

function Restore-Workspace {
    if (-not (Test-Path $JsonPath)) {
        Write-Warning "Snapshot not found at $JsonPath"
        return
    }

    $data = Get-Content $JsonPath -Raw -Encoding UTF8 | ConvertFrom-Json
    $targetDesktops = [int]$data.DesktopCount

    # Ensure desktop count matches
    $curOut = (& $VDExe /Count 2>$null) -join "`n"
    $curCount = 1
    if ($curOut -match '(\d+)') { $curCount = [int]$matches[1] }
    while ($curCount -lt $targetDesktops) {
        & $VDExe /NewDesktop 2>$null | Out-Null
        $curCount++
    }

    # Launch any missing apps
    foreach ($win in $data.Windows) {
        if (-not (Get-Process -Name $win.Process -ErrorAction SilentlyContinue)) {
            if ($win.Path -and (Test-Path $win.Path)) {
                Write-Output "Launching missing: $($win.Process)"
                Start-Process -FilePath $win.Path -ErrorAction SilentlyContinue
                Start-Sleep -Milliseconds 600
            }
        }
    }

    Start-Sleep -Seconds 1

    # Reposition and migrate to target desktops
    foreach ($win in $data.Windows) {
        $procs = Get-Process -Name $win.Process -ErrorAction SilentlyContinue
        foreach ($p in $procs) {
            $hwnd = $p.MainWindowHandle
            if ($hwnd -ne [IntPtr]::Zero) {
                # Move to virtual desktop
                & $VDExe "/MoveWindowHandle:$($hwnd.ToInt64())" "/ToDesktop:$($win.Desktop)" 2>$null | Out-Null

                # Position window
                $wp = New-Object WinHelper+WINDOWPLACEMENT
                $wp.length = [System.Runtime.InteropServices.Marshal]::SizeOf($wp)
                [WinHelper]::GetWindowPlacement($hwnd, [ref]$wp) | Out-Null

                $wp.showCmd = $win.ShowCmd
                $wp.rcNormalPosition.Left = $win.X
                $wp.rcNormalPosition.Top = $win.Y
                $wp.rcNormalPosition.Right = $win.X + $win.W
                $wp.rcNormalPosition.Bottom = $win.Y + $win.H

                [WinHelper]::SetWindowPlacement($hwnd, [ref]$wp) | Out-Null
            }
        }
    }
    Write-Output "RESTORED: $($data.Windows.Count) windows across $targetDesktops desktops."
}

if ($Action -eq 'Snapshot') {
    Get-WorkspaceSnapshot
} elseif ($Action -eq 'Restore') {
    Restore-Workspace
} elseif ($Action -eq 'Status') {
    if (Test-Path $JsonPath) {
        Get-Content $JsonPath -Raw -Encoding UTF8
    } else {
        Write-Output "No snapshot found."
    }
}
