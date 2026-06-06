Set shell = CreateObject("WScript.Shell")
shell.Run "powershell.exe -NoProfile -ExecutionPolicy Bypass -WindowStyle Hidden -File ""C:\Users\Administrator\Desktop\test\fetch-all.ps1"" -OutputDir ""C:\Users\Administrator\Desktop\test"" -SkipSnapshot", 0, False
