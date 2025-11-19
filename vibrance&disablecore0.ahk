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

GameTarget       := "ahk_exe " GameExe
PrimaryMonitor   := GetNvPrimaryID()
AffinityCallback := ApplyAffinity.Bind(GameExe) ; Create the bound function once

; Start the Watchdog
SetTimer(CheckGameState, 1000)

CheckGameState() {
    static IsGameRunning := false

    ; 1. Handle Game Closed
    if !ProcessExist(GameExe) {
        if IsGameRunning {
            IsGameRunning := false
            SetTimer(AffinityCallback, 0) ; Cancel affinity timer if game closed early
            SetVibrance(WindowsVibranceLevel)
        }
        return
    }

    ; 2. Handle Game Just Started
    if !IsGameRunning {
        IsGameRunning := true
        SetTimer(AffinityCallback, -20000) ; Run affinity ONCE in 20 seconds
    }

    ; 3. Handle Window Focus
    if WinActive(GameTarget)
        SetVibrance(GameVibranceLevel)
    else
        SetVibrance(WindowsVibranceLevel)
}

SetVibrance(level) {
    static lastLevel := -1
    if (level != lastLevel) {
        try NvAPI.SetDVCLevelEx(level, PrimaryMonitor)
        lastLevel := level
    }
}

ApplyAffinity(exeName) {
    if !PID := ProcessExist(exeName)
        return

    ; Open Process: Query (0x0400) + Set Info (0x0200)
    if hProc := DllCall("OpenProcess", "UInt", 0x0600, "Int", 0, "UInt", PID, "Ptr") {
        ; Get System Affinity (physically existing cores)
        if DllCall("GetProcessAffinityMask", "Ptr", hProc, "Ptr*", 0, "Ptr*", &SysMask:=0) {
            ; Remove Core 0 (first bit) from the system mask
            NewMask := SysMask & ~1 
            if (NewMask > 0)
                DllCall("SetProcessAffinityMask", "Ptr", hProc, "Ptr", NewMask)
        }
        DllCall("CloseHandle", "Ptr", hProc)
    }
}

GetNvPrimaryID() {
    ; Returns 0-based index of primary monitor (e.g., Display1 -> 0)
    return Integer(SubStr(MonitorGetName(MonitorGetPrimary()), 12)) - 1
}