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

GameTarget     := "ahk_exe " GameExe
PrimaryMonitor := GetNvPrimaryID()

; Start the Watchdog
SetTimer(WindowFocus, 1000)

GetNvPrimaryID() {
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