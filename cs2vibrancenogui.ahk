#SingleInstance Force
#Include Class_NvAPI.ahk

VibranceLevel := 80    ; change to desired vibrance
DefaultVibranceLevel := 50    ; default windows vibrance

PrimaryMonitor := MonitorGetPrimary()

Loop {
if WinActive("ahk_exe cs2.exe") {

  /*
  ; Optional. Disable win key while cs2 is active. Remove "/*" and "*/"
  #HotIf WinActive("ahk_exe cs2.exe")
    LWin::Return
  #HotIf
  */
  
  NvAPI.SetDVCLevelEx(VibranceLevel, PrimaryMonitor - 1)
  }
else {
  NvAPI.SetDVCLevelEx(DefaultVibranceLevel, PrimaryMonitor - 1)
}
Sleep 5000
}
