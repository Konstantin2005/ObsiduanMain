$base = "C:\obsidian\Main\Calendula\Вечно зеленные действия\Действия"

Write-Host "=== ИСПРАВИТЕЛЬНАЯ СТРУКТУРА ===" -ForegroundColor Green

# Переименуем Развитие → Востанавливаюсь (развита как восстановление/технологии)
Rename-Item -Path "$base\Развитие" -NewName "Востанавливаюсь" -Force
Write-Host "✓ Развитие → Востанавливаюсь" -ForegroundColor Green

# Востанавливаюсь теперь содержит:
# - Хороший сон.md, Сон.md, Прогулка.md, Прогулка в Лесу.md, Зарядка.md
# - Docker.md, English.md, LeetCode.md, Linux terminal.md, Obsidian.md, System Design.md
# - Speed reading.md, Speed writing.md, Algorithms.md, Programming.md, Architecture.md, Patterns.md
# - Progress.md, Chess.md, English.md, Java.md, Python.md, System Design.md
# (все файлы, которые относились к восстановлению)

# Делаю содержит:
# - Buraправа.md, Chess.md
# (активные текущие дела)

# Исследование содержит:
# - Search.md, Random thoughts.md, System design notes.md
# (исследование, офф-бренды, параллельное мышление)

# Созерцание содержит:
# - Ya cheto navaibkodil.md
# (рефлексия, самосознание)

Write-Host ""
Write-Host "=== КРАТКИЙ ОБЗОР ===" -ForegroundColor Yellow

$folders = Get-ChildItem $base -Directory | Sort-Object Name
foreach ($f in $folders) {
    $files = Get-ChildItem $f.FullName -File
    Write-Host ("  📂 " + $f.Name + ": " + $files.Count + " файлов") -ForegroundColor Cyan
    # Показать первые 5 файлов
    $files | Select-Object -First 5 | ForEach-Object { Write-Host ("      📄 " + $_.Name) -ForegroundColor Gray }
    if ($files.Count -gt 5) {
        Write-Host ("      ... и еще " + ($files.Count - 5) + " файлов") -ForegroundColor Gray
    }
    Write-Host ""
}

Write-Host "=== ГОТОВО ===" -ForegroundColor Green