Dim WinScriptHost
Set WinScriptHost = CreateObject("WScript.Shell")
WinScriptHost.Run Chr(34) & "C:\Scripts\ShadowCopy.bat" & Chr(34), 0
Set WinScriptHost = Nothing
