#SingleInstance Force
#Requires AutoHotkey v2.0-

#Include Class_NvAPI.ahk

GameVibranceLevel    := 80
WindowsVibranceLevel := 50

PrimaryMonitor := GetNvPrimaryID()

global AffinityTimerSet := false

; Optional. Win key disable (delete /* and  */)
/*
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

ApplyAffinityOnce() {
    global AffinityTimerSet
    if (AffinityTimerSet)
        return
    SetTimer(ApplyAffinity, -20000)  ; Wait 20s workaround affinity not applied, maybe cs2 applies it's own after lauch.
    AffinityTimerSet := true
}

ApplyAffinity() {
    Run('PowerShell.exe -NoProfile -ExecutionPolicy Bypass -Command "(Get-Process cs2).ProcessorAffinity = [Convert]::ToInt64(`'1`' * $env:NUMBER_OF_PROCESSORS, 2) - 1"',, "Hide")
}

Loop {
    if !ProcessExist("cs2.exe") {
        SetVibrance(WindowsVibranceLevel)
        SetTimer(ApplyAffinity, 0)
        AffinityTimerSet := false
        ProcessWait("cs2.exe")
    }

    ApplyAffinityOnce()

    if WinActive("ahk_exe cs2.exe") {
        SetVibrance(GameVibranceLevel)
        WinWaitNotActive("ahk_exe cs2.exe")
    } else {
        SetVibrance(WindowsVibranceLevel)
    }

    Sleep(500)
}
