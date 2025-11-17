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

ApplyAffinityOnce() {
    static applied := false
    static timerSet := false

    if (applied || timerSet)
        return

    timerSet := true
    SetTimer(ApplyAffinity, -20000)  ; Wait 20s workaround affinity not applied, maybe cs2 applies it's own after lauch.
}

ApplyAffinity() {
    static applied := false
    if (applied)
        return
    try {
        Run('PowerShell.exe -NoProfile -ExecutionPolicy Bypass -Command "(Get-Process cs2).ProcessorAffinity = [Convert]::ToInt64(`'1`' * $env:NUMBER_OF_PROCESSORS, 2) - 1"',, "Hide")
    }
    applied := true
}

while true {
    if !ProcessExist("cs2.exe") {
        SetVibrance(WindowsVibranceLevel)
        ApplyAffinityOnce.applied := false
        ApplyAffinityOnce.timerSet := false
        ProcessWait("cs2.exe")
        continue
    }

    ApplyAffinityOnce()

    if WinActive("ahk_exe cs2.exe") {
        SetVibrance(GameVibranceLevel)
        WinWaitNotActive("ahk_exe cs2.exe")
    } else {
        SetVibrance(WindowsVibranceLevel)
        WinWaitActive("ahk_exe cs2.exe")
    }

    Sleep(500)
}
