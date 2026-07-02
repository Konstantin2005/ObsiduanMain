Set shell = CreateObject("WScript.Shell")
shell.Run "powershell.exe -NoProfile -ExecutionPolicy Bypass -File ""C:\obsidian\Main\Technical\Scripts\Git\daily-push.ps1"" -CommitIntervalSeconds 1 -PushIntervalMinutes 5", 0, False
