#SingleInstance Force
#Include Class_NvAPI.ahk
#Requires AutoHotkey v2.0-

GameVibranceLevel := 80    ; game vibrance
WindowsVibranceLevel := 50    ; windows vibrance

PrimaryMonitor := MonitorGetPrimary()

Loop {
if not ProcessExist("cs2.exe"){
  NvAPI.SetDVCLevelEx(WindowsVibranceLevel, PrimaryMonitor - 1)
  ProcessWait("cs2.exe")
}
else if WinActive("ahk_exe cs2.exe") {
  /*
  ; Optional. Disable win key while cs2 is active. Remove "/*" and "*/"
  #HotIf WinActive("ahk_exe cs2.exe")
    LWin::Return
  #HotIf
  */
  NvAPI.SetDVCLevelEx(GameVibranceLevel, PrimaryMonitor - 1)
  WinWaitNotActive()
}
else {
  NvAPI.SetDVCLevelEx(WindowsVibranceLevel, PrimaryMonitor - 1)
  WinWaitActive("ahk_exe cs2.exe")
}
Sleep(1000)
}
