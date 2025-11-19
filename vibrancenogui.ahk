#SingleInstance Force
#Requires AutoHotkey v2.0-

#Include Class_NvAPI.ahk

; --- Configuration ---
GameVibranceLevel    := 80
WindowsVibranceLevel := 50
GameExe              := "cs2.exe"

; Optional. Win key disable (delete /* and  */)
/*
#HotIf WinActive(GameTarget)
    LWin::Return
#HotIf
*/
; ---------------------

GameTarget     := "ahk_exe " GameExe
PrimaryMonitor := GetNvPrimaryID()

; Start the Watchdog
SetTimer(WindowFocus, 1000)

GetNvPrimaryID() {
    ; Returns 0-based index of primary monitor (e.g., Display1 -> 0)
    return Integer(SubStr(MonitorGetName(MonitorGetPrimary()), 12)) - 1
}

SetVibrance(level) {
    static last := -1
    if (level != last) {
        NvAPI.SetDVCLevelEx(level, PrimaryMonitor)
        last := level
    }
}

WindowFocus() {
    if WinActive(GameTarget)
        SetVibrance(GameVibranceLevel)
    else
        SetVibrance(WindowsVibranceLevel)
}
