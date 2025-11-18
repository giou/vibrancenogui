#SingleInstance Force
#Requires AutoHotkey v2.0-

#Include Class_NvAPI.ahk

GameVibranceLevel    := 80
WindowsVibranceLevel := 50
PrimaryMonitor       := MonitorGetPrimary() ; if your primary display is not detected correctly add "- 1". No idea why.
; PrimaryMonitor       := MonitorGetPrimary() - 1

/*
; Optional. Win key disable (delete /* and  */)
#HotIf WinActive("ahk_exe cs2.exe")
    LWin::Return
#HotIf
 */

SetVibrance(level) {
    static last := -1
    if (level != last) {
        NvAPI.SetDVCLevelEx(level, PrimaryMonitor)
        last := level
    }
}

Loop {
    if WinActive("ahk_exe cs2.exe") {
        SetVibrance(GameVibranceLevel)
        WinWaitNotActive("ahk_exe cs2.exe")
    } else {
        SetVibrance(WindowsVibranceLevel)
        WinWaitActive("ahk_exe cs2.exe")
    }
}
