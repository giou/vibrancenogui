#SingleInstance Force
#Include Class_NvAPI.ahk
#Requires AutoHotkey v2.0-

GameVibranceLevel    := 80
WindowsVibranceLevel := 50
PrimaryMonitor       := MonitorGetPrimary() - 1

psAffinitySet := "
(
Get-Process cs2 -ErrorAction SilentlyContinue | ForEach-Object {
    `$mask = ([Convert]::ToInt64('1' * `$env:NUMBER_OF_PROCESSORS, 2)) - 1
    `$_.ProcessorAffinity = `$mask
}
)"

#HotIf WinActive("ahk_exe cs2.exe")
    LWin::Return
#HotIf

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
    SetTimer(ApplyAffinity, -20000)  ; Wait 20s workaround affinity not applied
}

ApplyAffinity() {
    static applied := false
    if (applied)
        return
    try {
        Run("PowerShell.exe -NoProfile -ExecutionPolicy Bypass -Command " psAffinitySet,, "Hide")
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
