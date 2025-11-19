#SingleInstance Force
#Requires AutoHotkey v2.0-

#Include Class_NvAPI.ahk

;--- config ---
GameVibranceLevel    := 80
WindowsVibranceLevel := 50
GameExe := "cs2.exe"

; Optional. Win key disable (delete /* and  */)
/*
#HotIf WinActive(GameTarget)
    LWin::Return
#HotIf
*/
;--- config end ---

GameTarget := "ahk_exe " GameExe
PrimaryMonitor := GetNvPrimaryID()

global AffinityTimerSet := false

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
    ProcName := StrReplace(GameExe, ".exe", "")
    Run(Format('PowerShell.exe -NoProfile -ExecutionPolicy Bypass -Command "(Get-Process {1}).ProcessorAffinity = [Convert]::ToInt64(`'1`' * $env:NUMBER_OF_PROCESSORS, 2) - 1"', ProcName),, "Hide")
}

Loop {
    if !ProcessExist(GameExe) {
        SetVibrance(WindowsVibranceLevel)
        SetTimer(ApplyAffinity, 0)
        AffinityTimerSet := false
        ProcessWait(GameExe)
    }

    ApplyAffinityOnce()

    if WinActive(GameTarget) {
        SetVibrance(GameVibranceLevel)
        WinWaitNotActive(GameTarget)
    } else {
        SetVibrance(WindowsVibranceLevel)
    }

    Sleep(500)
}
