Set shell = CreateObject("WScript.Shell")
shell.Run "powershell.exe -NoProfile -ExecutionPolicy Bypass -Command ""cd C:\obsidian\Main; git fetch --all --prune; git pull --rebase --autostash origin main""", 0, False
