$path = "C:/obsidian/Main/Calendula/Calendula/2026/Июль"
Get-ChildItem -Path $path -File | ForEach-Object {
    $date = $_.Name -replace '\.md$', ''
    $dayOfWeek = Get-Date "20$date" -Format "dddd"
    Move-Item -Path $_.FullName -Destination "$path\..\$dayOfWeek\$_.Name"
}