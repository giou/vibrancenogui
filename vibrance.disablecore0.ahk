#SingleInstance Force
#Requires AutoHotkey v2.0-

; --- Configuration ---
GameVibranceLevel    := 80          ; Vibrance level when game is active (0-100)
WindowsVibranceLevel := 50          ; Vibrance level for desktop/other apps (usually 50)
GameExe              := "cs2.exe"   ; Process name to watch

; Optional. Win key disable (delete /* and  */)
/*
#HotIf WinActive(GameTarget)
    LWin::Return
#HotIf
*/
; ---------------------

GameTarget       := "ahk_exe " GameExe
PrimaryMonitor   := GetNvPrimaryID()
AffinityCallback := ApplyAffinity.Bind(GameExe)

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
        NvAPI.SetDVCLevelEx(level, PrimaryMonitor)
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
    return Integer(SubStr(MonitorGetName(MonitorGetPrimary()), 12)) - 1
}


; ========================================================================================
;   MINIMAL NvAPI CLASS (Stripped for Vibrance Only)
; ========================================================================================

class NvAPI
{
	static NvDLL := (A_PtrSize = 8) ? "nvapi64.dll" : "nvapi.dll"
	static _Init := NvAPI.__Initialize()

	static __Initialize()
	{
		if !(this.hModule := DllCall("LoadLibrary", "Str", this.NvDLL, "Ptr"))
		{
			MsgBox("NvAPI could not be started!`n`nThe program will exit!", A_ThisFunc)
			ExitApp
		}
		if (NvStatus := DllCall(DllCall(this.NvDLL "\nvapi_QueryInterface", "UInt", 0x0150E828, "CDecl UPtr"), "CDecl") != 0)
		{
			MsgBox("NvAPI initialization failed: [ " NvStatus " ]`n`nThe program will exit!", A_ThisFunc)
			ExitApp
		}
	}

	static __Delete()
	{
		DllCall(DllCall(this.NvDLL "\nvapi_QueryInterface", "UInt", 0xD22BDD7E, "CDecl UPtr"), "CDecl")
		if (this.hModule)
			DllCall("FreeLibrary", "Ptr", this.hModule)
	}

	static QueryInterface(NvID)
	{
		return DllCall(this.NvDLL "\nvapi_QueryInterface", "UInt", NvID, "CDecl UPtr")
	}

	static EnumNvidiaDisplayHandle(thisEnum := 0)
	{
		if !(NvStatus := DllCall(this.QueryInterface(0x9ABDD40D), "UInt", thisEnum, "Ptr*", &NvDisplayHandle := 0, "CDecl"))
			return NvDisplayHandle
		return this.GetErrorMessage(NvStatus)
	}

	static GetDVCInfoEx(thisEnum := 0)
	{
		static NV_DISPLAY_DVC_INFO_EX := (5 * 4)

		hNvDisplay := this.EnumNvidiaDisplayHandle(thisEnum)
		DVCInfo := Buffer(NV_DISPLAY_DVC_INFO_EX, 0)
		NumPut("UInt", NV_DISPLAY_DVC_INFO_EX | 0x10000, DVCInfo, 0)
		if !(NvStatus := DllCall(this.QueryInterface(0x0E45002D), "Ptr", hNvDisplay, "UInt", outputId := 0, "Ptr", DVCInfo, "CDecl"))
		{
			DVC_INFO_EX := Map()
			DVC_INFO_EX["currentLevel"] := NumGet(DVCInfo,  4, "Int")
			DVC_INFO_EX["minLevel"]     := NumGet(DVCInfo,  8, "Int")
			DVC_INFO_EX["maxLevel"]     := NumGet(DVCInfo, 12, "Int")
			DVC_INFO_EX["defaultLevel"] := NumGet(DVCInfo, 16, "Int")
			return DVC_INFO_EX
		}
		return this.GetErrorMessage(NvStatus)
	}

	static SetDVCLevelEx(currentLevel, thisEnum := 0)
	{
		static NV_DISPLAY_DVC_INFO_EX := (5 * 4) 

		DVC := this.GetDVCInfoEx(thisEnum)
		if !IsObject(DVC)
			return 0
			
		if (currentLevel < DVC["minLevel"]) || (currentLevel > DVC["maxLevel"])
		{
			return 0
		}

		hNvDisplay := this.EnumNvidiaDisplayHandle(thisEnum)
		DVCInfo := Buffer(NV_DISPLAY_DVC_INFO_EX, 0)
		NumPut("UInt", NV_DISPLAY_DVC_INFO_EX | 0x10000, DVCInfo, 0)
		NumPut("Int", currentLevel, DVCInfo, 4)
		if !(NvStatus := DllCall(this.QueryInterface(0x4A82C2B1), "Ptr", hNvDisplay, "UInt", outputId := 0, "Ptr", DVCInfo, "CDECL"))
		{
			return currentLevel
		}

		return NvAPI.GetErrorMessage(NvStatus)
	}

	static GetErrorMessage(ErrorCode)
	{
		Desc := Buffer(64, 0)
		DllCall(this.QueryInterface(0x6C2D048C), "Ptr", ErrorCode, "Ptr", Desc, "CDecl")
		return "Error: " StrGet(Desc, "CP0")
	}
}
