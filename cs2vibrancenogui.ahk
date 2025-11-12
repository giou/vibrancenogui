#SingleInstance Force
#Include Class_NvAPI.ahk
#Requires AutoHotkey v2.0-

GameVibranceLevel    := 80
WindowsVibranceLevel := 50
PrimaryMonitor       := MonitorGetPrimary()

SetVibrance(level) {
    static last := -1
    if (level != last) {
        NvAPI.SetDVCLevelEx(level, PrimaryMonitor)
        last := level
    }
}

#HotIf WinActive("ahk_exe cs2.exe")
	LWin::Return
#HotIf

while true {
    if WinActive("ahk_exe cs2.exe") {
        SetVibrance(GameVibranceLevel)
        WinWaitNotActive("ahk_exe cs2.exe")
    } else {
        SetVibrance(WindowsVibranceLevel)
        WinWaitActive("ahk_exe cs2.exe")
    }
    Sleep(500)
}

