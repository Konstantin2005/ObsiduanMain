Set shell = CreateObject("WScript.Shell")
shell.Run "powershell.exe -NoProfile -ExecutionPolicy Bypass -File ""C:\obsidian\Main\Scripts\Git\daily-push.ps1""", 0, False
