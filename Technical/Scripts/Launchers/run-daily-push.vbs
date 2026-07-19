' Obsidian Multi-Repo Git Auto-Push Monitor Launcher
' Запускает монитор, который автообнаруживает все репозитории Obsidian
' и запускает daily-push для каждого из них

Set shell = CreateObject("WScript.Shell")
shell.Run "powershell.exe -NoProfile -ExecutionPolicy Bypass -File ""C:\obsidian\Main\Technical\Scripts\Git\monitor-daily-push.ps1"" -DurationMinutes 1440", 0, False