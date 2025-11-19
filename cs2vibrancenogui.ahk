#SingleInstance Force
#Requires AutoHotkey v2.0-

#Include Class_NvAPI.ahk

GameVibranceLevel    := 80
WindowsVibranceLevel := 50
GameExe := "ahk_exe cs2.exe"

PrimaryMonitor := GetNvPrimaryID()

/*
; Optional. Win key disable (delete /* and  */)
#HotIf WinActive("ahk_exe cs2.exe")
    LWin::Return
#HotIf
 */

GetNvPrimaryID() {
    primaryIdx := MonitorGetPrimary()      ; Get AHK's index for the primary monitor
    name := MonitorGetName(primaryIdx)     ; Get the system name (e.g., \\.\DISPLAY1)
    if RegExMatch(name, "\d+$", &match)    ; Extract the number at the end
        return Integer(match[0]) - 1       ; Convert to 0-based index (Display1 -> 0)
}

SetVibrance(level) {
    static last := -1
    if (level != last) {
        NvAPI.SetDVCLevelEx(level, PrimaryMonitor)
        last := level
    }
}

Loop {
    if WinActive(GameExe) {
        SetVibrance(GameVibranceLevel)
        WinWaitNotActive(GameExe)
    } else {
        SetVibrance(WindowsVibranceLevel)
        WinWaitActive(GameExe)
    }
}
