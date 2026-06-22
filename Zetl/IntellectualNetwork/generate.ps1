# Intellectual Network Generator
# Creates a network of thinkers and their ideas

$ErrorActionPreference = "SilentlyContinue"
$baseDir = "C:\obsidian\Main\IntellectualNetwork"
$rand = [System.Random]::new(54321)

# ============ THINKERS ============
$thinkers = @{
    "Нассим Талеб" = @{
        Ideas = @("Чёрный лебедь", "Антихрупкость", "Skin in the Game", "Барелл", "Муравьи vs Термиты", "Эргодичность", "Лудофорс", "Бесконечная игра", "Antifragile", "Randomness", "Via Negativa", "Инверсия", "Столкновения", "Mediocristan vs Extremistan")
        Books = @("Чёрный лебедь", "Антихрупкость", "Сыграя в ящики", "Кожа в игре", "Бесконечное терпение", "Симметрия", "Рискованные инвестиции", "Обман случайности", "Математика неискажённого")
        Concepts = @("Антихрупкость", "Хрупкость", "Устойчивость", "Антиэнтропия", "Медиокристан", "Экстремистан", "Эргодичность", "Лудофорс", "Парадокс Талеба", "Via Negativa")
        Criticism = @("Интеллектуальная нечестность", "Ретроспективное предсказание", "Интеллектуальная гордыня", "Игнорирование оппонентов")
    }
    "Чарли Мангер" = @{
        Ideas = @("Ментальные модели", "Чеклист Чарли", "Инверсия", "Решётка ментальных моделей", "Lollapalooza эффект", "Психология человеческой оценки", "Округление до ближайшего.", "Эффект Лоллапалузы", "Суперкомпетентность", "Закон низких оснований")
        Books = @("Самый богатый человек в Вавилоне", "Вуди Аллен для инвесторов", "Простая математика богатства", "Психология человеческой оценки", "Сила рациональности", "Принципы Чарли Мангера")
        Concepts = @("Ментальные модели", "Инверсия", "Lollapalooza эффект", "Двадцать пять основных когнитивных искажений", "Решётка ментальных моделей", "Сверхкомпетентность", "Круг компетентности", "Эффект масштаба", "Социальное доказательство")
        Criticism = @("Упрощение сложных концепций", "Влияние на инвесторов", "Эффект толпы", "Интеллектуальная зависимость от Бэттера")
    }
    "Даниэль Канеман" = @{
        Ideas = @("Система 1 и Система 2", "Когнитивные искажения", "Prospect theory", "Эффект якоря", "Подтверждающее искажение", "Эффект толпы", "Эффект ореола", "Эффект подавления", "Эффект номинала", "Эффект привязки")
        Books = @("Думай медленно... решай быстро", "Шум", "Эмоциональная разумность", "Предиктивная аналитика", "Когнитивные искажения", "Поведенческая экономика", "Краткая история времени", "Теория игр")
        Concepts = @("Система 1", "Система 2", "Prospect theory", "Когнитивные искажения", "Эффект якоря", "Подтверждающее искажение", "Эффект толпы", "Эффект ореола", "Эффект подавления", "Эффект номинала")
        Criticism = @("Упрощение психологии", "Влияние на экономику", "Интеллектуальная мода", "Эффект навязчивости")
    }
    "Питер Тиль" = @{
        Ideas = @("Ноль к одному", "Конкуренция — это для неудачников", "Секретное знание", "Мыслительный эксперимент", "Длинные ставки", "Структурный оптимизм", "Паранойя", "Компетентность", "Эффект номинала", "Долгосрочное мышление")
        Books = @("Ноль к одному", "От нуля к единице", "Конкуренция — это для неудачников", "Секретное знание", "Длинные ставки", "Структурный оптимизм", "Паранойя", "Компетентность", "Эффект номинала", "Долгосрочное мышление")
        Concepts = @("Ноль к единице", "Конкуренция — это для неудачников", "Секретное знание", "Длинные ставки", "Структурный оптимизм", "Паранойя", "Компетентность", "Эффект номинала", "Долгосрочное мышление", "Вертикальный прогресс")
        Criticism = @("Упрощение конкуренции", "Влияние на стартапы", "Интеллектуальная гордыня", "Эффект толпы")
    }
    "Карл Поппер" = @{
        Ideas = @("Фалсификация", "Открытое общество", "Критический рационализм", "Проблема индукции", "Три мира", "Прогресс", "Научная революция", "Демаркация", "Рост научного знания", "Традиция рациональной критики")
        Books = @("Открытое общество и его враги", "Логика научного исследования", "Нищета историцизма", "Предположения и опровержения", "Объективность", "Знание и человека", "Парадоксы оптимизма", "Анти-историцизм", "Политика и личность", "Письма")
        Concepts = @("Фалсификация", "Открытое общество", "Критический рационализм", "Проблема индукции", "Три мира", "Прогресс", "Научная революция", "Демаркация", "Рост научного знания", "Традиция рациональной критики")
        Criticism = @("Идеализм", "Игнорирование социального контекста", "Интеллектуальная непоследовательность", "Влияние на философию")
    }
    "Аристотель" = @{
        Ideas = @("Логика", "Категории", "Силлогизм", "Этика добродетели", "Политическая философия", "Метафизика", "Физика", "Биология", "Поэтика", "Риторика")
        Books = @("Никомахова этика", "Политика", "Метафизика", "Физика", "О душе", "О pièces", "Категории", "Об истолковании", "Первая аналитика", "Вторая аналитика")
        Concepts = @("Логика", "Категории", "Силлогизм", "Этика добродетели", "Политическая философия", "Метафизика", "Физика", "Биология", "Поэтика", "Риторика")
        Criticism = @("Средневековая схоластика", "Игнорирование эксперимента", "Интеллектуальная традиция", "Влияние на христианство")
    }
    "Фридрих Ницше" = @{
        Ideas = @("Воля к власти", "Сверхчеловек", "Вечное возвращение", "Мораль господ и рабов", "Дионисийское начало", "Аполлоническое начало", "Умирание Бога", "Ресентимент", "Аскетический идеал", "Трагическое мироощущение")
        Books = @("Так говорил Заратустра", "Генеалогия морали", "По ту сторону добра и зла", "Весёлая наука", "О пользе и вреде истории для жизни", "Рождение трагедии", "Антихрист", "Человеческое, слишком человеческое", "Да будет так", "Этический кодекс")
        Concepts = @("Воля к власти", "Сверхчеловек", "Вечное возвращение", "Мораль господ и рабов", "Дионисийское начало", "Аполлоническое начало", "Умирание Бога", "Ресентимент", "Аскетический идеал", "Трагическое мироощущение")
        Criticism = @("Нацизм", "Интеллектуальная аморальность", "Интеллектуальная decadence", "Интеллектуальная decadence", "Влияние на экзистенциализм")
    }
}

# ============ SHARED IDEAS ============
$sharedIdeas = @{
    "Инверсия" = @("Нассим Талеб", "Чарли Мангер", "Карл Поппер")
    "Когнитивные искажения" = @("Даниэль Канеман", "Чарли Мангер", "Нассим Талеб")
    "Риск и неопределенность" = @("Нассим Талеб", "Даниэль Канеман", "Питер Тиль")
    "Долгосрочное мышление" = @("Питер Тиль", "Чарли Мангер", "Аристотель")
    "Критический рационализм" = @("Карл Поппер", "Даниэль Канеман", "Нассим Талеб")
    "Ментальные модели" = @("Чарли Мангер", "Даниэль Канеман", "Питер Тиль")
    "Конкуренция" = @("Питер Тиль", "Нассим Талеб", "Аристотель")
    "Свобода воли" = @("Ницше", "Аристотель", "Карл Поппер")
    "Эволюция идей" = @("Карл Поппер", "Ницше", "Даниэль Канеман")
    "Этические системы" = @("Аристотель", "Ницше", "Карл Поппер")
    "Принятие решений" = @("Даниэль Канеман", "Чарли Мангер", "Питер Тиль")
    "Технологический прогресс" = @("Питер Тиль", "Нассим Талеб", "Ницше")
    "Познание и знание" = @("Карл Поппер", "Аристотель", "Даниэль Канеман")
    "Индивидуализм" = @("Ницше", "Питер Тиль", "Нассим Талеб")
    "Системное мышление" = @("Чарли Мангер", "Нассим Талеб", "Даниэль Канеман")
    "Рациональность" = @("Карл Поппер", "Чарли Мангер", "Даниэль Канеман")
    "Пессимизм разума" = @("Нассим Талеб", "Даниэль Канеман", "Ницше")
    "Сверхчеловек" = @("Ницше", "Питер Тиль", "Нассим Талеб")
    "Открытое общество" = @("Карл Поппер", "Аристотель", "Ницше")
    "Эргодичность" = @("Нассим Талеб", "Даниэль Канеман", "Чарли Мангер")
    "Антихрупкость" = @("Нассим Талеб", "Питер Тиль", "Чарли Мангер")
    "Парадокс Талеба" = @("Нассим Талеб", "Даниэль Канеман", "Карл Поппер")
    "Мудрость толпы" = @("Даниэль Канеман", "Чарли Мангер", "Карл Поппер")
    "Интеллектуальная честность" = @("Карл Поппер", "Нассим Талеб", "Аристотель")
    "Философия технологий" = @("Питер Тиль", "Ницше", "Аристотель")
    "Прагматизм" = @("Чарли Мангер", "Даниэль Канеман", "Питер Тиль")
    "Экзистенциализм" = @("Ницше", "Аристотель", "Карл Поппер")
    "Эпистемология" = @("Карл Поппер", "Аристотель", "Даниэль Канеман")
    "Теория игр" = @("Даниэль Канеман", "Питер Тиль", "Чарли Мангер")
    "Эволюционная теория" = @("Ницше", "Карл Поппер", "Аристотель")
}

# ============ GENERATE THINKER NOTES ============
Write-Host "=== Generating Thinker Notes ==="

foreach ($thinker in $thinkers.Keys) {
    $data = $thinkers[$thinker]
    $safeName = $thinker -replace '[\\/:*?"<>|]', '_'
    $filePath = Join-Path $baseDir "Thinkers\$safeName.md"
    
    $ideasLinks = ($data.Ideas | ForEach-Object { "- [[Idea: $_]]" }) -join "`n"
    $booksLinks = ($data.Books | ForEach-Object { "- [[Book: $_]]" }) -join "`n"
    $conceptsLinks = ($data.Concepts | ForEach-Object { "- [[Concept: $_]]" }) -join "`n"
    $criticismLinks = ($data.Criticism | ForEach-Object { "- [[Criticism: $_]]" }) -join "`n"
    
    # Find related thinkers through shared ideas
    $relatedThinkers = @()
    foreach ($sharedIdea in $sharedIdeas.Keys) {
        if ($thinker -in $sharedIdeas[$sharedIdea]) {
            $others = $sharedIdeas[$sharedIdea] | Where-Object { $_ -ne $thinker }
            $relatedThinkers += $others
        }
    }
    $relatedThinkers = $relatedThinkers | Select-Object -Unique
    $relatedLinks = ($relatedThinkers | ForEach-Object { "- [[Thinker: $_]]" }) -join "`n"
    
    # Find shared ideas
    $thinkerSharedIdeas = @()
    foreach ($sharedIdea in $sharedIdeas.Keys) {
        if ($thinker -in $sharedIdeas[$sharedIdea]) {
            $thinkerSharedIdeas += $sharedIdea
        }
    }
    $sharedIdeasLinks = ($thinkerSharedIdeas | ForEach-Object { "- [[Shared Idea: $_]]" }) -join "`n"
    
    $content = @"
---
type: Thinker
cluster: Intellectual Network
tags: [thinker, intellectual, $($safeName.ToLower() -replace ' ', '_')]
---

# $thinker

## Ключевые идеи
$ideasLinks

## Книги
$booksLinks

## Концепции
$conceptsLinks

## Критика
$criticismLinks

## Связанные мыслители
$relatedLinks

## Общие идеи
$sharedIdeasLinks
"@
    
    $content | Out-File -FilePath $filePath -Encoding UTF8
    Write-Host "Created: $thinker"
}

# ============ GENERATE IDEA NOTES ============
Write-Host "`n=== Generating Idea Notes ==="

$allIdeas = @()
foreach ($thinker in $thinkers.Keys) {
    $allIdeas += $thinkers[$thinker].Ideas
}
$allIdeas = $allIdeas | Select-Object -Unique

foreach ($idea in $allIdeas) {
    $safeName = $idea -replace '[\\/:*?"<>|]', '_'
    $filePath = Join-Path $baseDir "Ideas\Idea - $safeName.md"
    
    # Find which thinkers have this idea
    $thinkersWithIdea = @()
    foreach ($thinker in $thinkers.Keys) {
        if ($idea -in $thinkers[$thinker].Ideas) {
            $thinkersWithIdea += $thinker
        }
    }
    $thinkerLinks = ($thinkersWithIdea | ForEach-Object { "- [[Thinker: $_]]" }) -join "`n"
    
    # Find related ideas
    $relatedIdeas = @()
    foreach ($t in $thinkersWithIdea) {
        $relatedIdeas += $thinkers[$t].Ideas | Where-Object { $_ -ne $idea }
    }
    $relatedIdeas = $relatedIdeas | Select-Object -Unique | Select-Object -First 5
    $relatedIdeasLinks = ($relatedIdeas | ForEach-Object { "- [[Idea: $_]]" }) -join "`n"
    
    # Find related concepts
    $relatedConcepts = @()
    foreach ($t in $thinkersWithIdea) {
        $relatedConcepts += $thinkers[$t].Concepts | Where-Object { $_ -ne $idea }
    }
    $relatedConcepts = $relatedConcepts | Select-Object -Unique | Select-Object -First 3
    $conceptLinks = ($relatedConcepts | ForEach-Object { "- [[Concept: $_]]" }) -join "`n"
    
    $content = @"
---
type: Idea
cluster: Intellectual Network
tags: [idea, intellectual]
---

# $idea

## Мыслители
$thinkerLinks

## Связанные идеи
$relatedIdeasLinks

## Связанные концепции
$conceptLinks
"@
    
    $content | Out-File -FilePath $filePath -Encoding UTF8
}

# ============ GENERATE BOOK NOTES ============
Write-Host "`n=== Generating Book Notes ==="

$allBooks = @()
foreach ($thinker in $thinkers.Keys) {
    foreach ($book in $thinkers[$thinker].Books) {
        $allBooks += [PSCustomObject]@{ Title = $book; Author = $thinker }
    }
}

foreach ($book in $allBooks) {
    $safeName = $book.Title -replace '[\\/:*?"<>|]', '_'
    $filePath = Join-Path $baseDir "Books\Book - $safeName.md"
    
    $content = @"
---
type: Book
author: $($book.Author)
cluster: Intellectual Network
tags: [book, intellectual, $($book.Author.ToLower() -replace ' ', '_')]
---

# $($book.Title)

## Автор
- [[Thinker: $($book.Author)]]

## Основные идеи
- [[Idea: $($book.Title)]]

## Связанные концепции
- [[Concept: $($book.Title)]]
"@
    
    $content | Out-File -FilePath $filePath -Encoding UTF8
}

# ============ GENERATE CONCEPT NOTES ============
Write-Host "`n=== Generating Concept Notes ==="

$allConcepts = @()
foreach ($thinker in $thinkers.Keys) {
    $allConcepts += $thinkers[$thinker].Concepts
}
$allConcepts = $allConcepts | Select-Object -Unique

foreach ($concept in $allConcepts) {
    $safeName = $concept -replace '[\\/:*?"<>|]', '_'
    $filePath = Join-Path $baseDir "Concepts\Concept - $safeName.md"
    
    # Find which thinkers use this concept
    $thinkersWithConcept = @()
    foreach ($thinker in $thinkers.Keys) {
        if ($concept -in $thinkers[$thinker].Concepts) {
            $thinkersWithConcept += $thinker
        }
    }
    $thinkerLinks = ($thinkersWithConcept | ForEach-Object { "- [[Thinker: $_]]" }) -join "`n"
    
    # Find related concepts
    $relatedConcepts = @()
    foreach ($t in $thinkersWithConcept) {
        $relatedConcepts += $thinkers[$t].Concepts | Where-Object { $_ -ne $concept }
    }
    $relatedConcepts = $relatedConcepts | Select-Object -Unique | Select-Object -First 5
    $relatedConceptsLinks = ($relatedConcepts | ForEach-Object { "- [[Concept: $_]]" }) -join "`n"
    
    # Find shared ideas
    $sharedIdeasForConcept = @()
    foreach ($sharedIdea in $sharedIdeas.Keys) {
        if ($concept -eq $sharedIdea) {
            $sharedIdeasForConcept += $sharedIdea
        }
    }
    $sharedIdeasLinks = ($sharedIdeasForConcept | ForEach-Object { "- [[Shared Idea: $_]]" }) -join "`n"
    
    $content = @"
---
type: Concept
cluster: Intellectual Network
tags: [concept, intellectual]
---

# $concept

## Мыслители
$thinkerLinks

## Связанные концепции
$relatedConceptsLinks

## Общие идеи
$sharedIdeasLinks
"@
    
    $content | Out-File -FilePath $filePath -Encoding UTF8
}

# ============ GENERATE SHARED IDEA NOTES ============
Write-Host "`n=== Generating Shared Idea Notes ==="

foreach ($sharedIdea in $sharedIdeas.Keys) {
    $safeName = $sharedIdea -replace '[\\/:*?"<>|]', '_'
    $filePath = Join-Path $baseDir "Ideas\Shared Idea - $safeName.md"
    
    $thinkerLinks = ($sharedIdeas[$sharedIdea] | ForEach-Object { "- [[Thinker: $_]]" }) -join "`n"
    
    $content = @"
---
type: Shared Idea
cluster: Intellectual Network
tags: [shared-idea, intellectual]
---

# $sharedIdea

## Мыслители
$thinkerLinks

## Описание
Общая идея, связывающая нескольких мыслителей.
"@
    
    $content | Out-File -FilePath $filePath -Encoding UTF8
}

# ============ GENERATE CRITICISM NOTES ============
Write-Host "`n=== Generating Criticism Notes ==="

$allCriticisms = @()
foreach ($thinker in $thinkers.Keys) {
    foreach ($criticism in $thinkers[$thinker].Criticism) {
        $allCriticisms += [PSCustomObject]@{ Title = $criticism; Target = $thinker }
    }
}

foreach ($criticism in $allCriticisms) {
    $safeName = $criticism.Title -replace '[\\/:*?"<>|]', '_'
    $filePath = Join-Path $baseDir "Concepts\Criticism - $safeName.md"
    
    $content = @"
---
type: Criticism
cluster: Intellectual Network
tags: [criticism, intellectual]
---

# $($criticism.Title)

## Объект критики
- [[Thinker: $($criticism.Target)]]

## Связанные концепции
- [[Concept: $($criticism.Title)]]
"@
    
    $content | Out-File -FilePath $filePath -Encoding UTF8
}

Write-Host "`n=== Generation Complete ==="

# Count files
$thinkersCount = (Get-ChildItem -Path "$baseDir\Thinkers" -Filter "*.md" -ErrorAction SilentlyContinue).Count
$ideasCount = (Get-ChildItem -Path "$baseDir\Ideas" -Filter "*.md" -ErrorAction SilentlyContinue).Count
$booksCount = (Get-ChildItem -Path "$baseDir\Books" -Filter "*.md" -ErrorAction SilentlyContinue).Count
$conceptsCount = (Get-ChildItem -Path "$baseDir\Concepts" -Filter "*.md" -ErrorAction SilentlyContinue).Count

Write-Host "Thinkers: $thinkersCount"
Write-Host "Ideas: $ideasCount"
Write-Host "Books: $booksCount"
Write-Host "Concepts: $conceptsCount"
Write-Host "Total: $($thinkersCount + $ideasCount + $booksCount + $conceptsCount)"
