# Decision Making Graph Generator
# Creates a graph of Values → Principles → Rules → Decisions → Outcomes

$ErrorActionPreference = "SilentlyContinue"
$baseDir = "C:\obsidian\Main\DecisionMakingGraph"
$rand = [System.Random]::new(99999)

# ============ VALUES (100) ============
Write-Host "=== Defining Values ==="
$values = @(
    # Core Values (20)
    "Честность", "Справедливость", "Свобода", "Равенство", "Достоинство",
    "Ответственность", "Уважение", "Лояльность", "Надежность", "Искренность",
    "Доброта", "Милосердие", "Благодарность", "Смирение", "Терпение",
    "Мужество", "Решительность", "Настойчивость", "Дисциплина", "Трудолюбие",
    
    # Social Values (20)
    "Солидарность", "Коллективизм", "Индивидуализм", "Сообщество", "Семья",
    "Дружба", "Любовь", "Близость", "Доверие", "Сотрудничество",
    "Конкуренция", "Справедливость распределения", "Справедливость процедур",
    "Эгалитаризм", "Меритократия", "Аристократия", "Демократия", "Автономия",
    "Власть", "Влияние",
    
    # Intellectual Values (20)
    "Знание", "Истина", "Мудрость", "Понимание", "Критическое мышление",
    "Логика", "Рациональность", "Эмпиризм", "Рационализм", "Скептицизм",
    "Открытость", "Любознательность", "Инновации", "Традиции", "Прогресс",
    "Эволюция", "Революция", "Реформа", "Консерватизм", "Модернизм",
    
    # Personal Values (20)
    "Здоровье", "Красота", "Гармония", "Баланс", "Комфорт",
    "Безопасность", "Стабильность", "Рост", "Развитие", "Самореализация",
    "Самоуважение", "Самопознание", "Автономия", "Независимость", "Свобода времени",
    "Финансовая свобода", "Творчество", "Вдохновение", "Смысл", "Целеустремлённость",
    
    # Moral Values (20)
    "Добро", "Зло", "Невинность", "Вина", "Стыд",
    "Гордость", "Сострадание", "Эмпатия", "Альтруизм", "Эгоизм",
    "Жертвенность", "Бескорыстие", "Честность", "Правдивость", "Ложь",
    "Обман", "Доверие", "Предательство", "Верность", "Преданность"
)

# ============ PRINCIPLES (300) ============
Write-Host "=== Defining Principles ==="
$principles = @(
    # Ethical Principles (60)
    "Принцип ненасилия", "Принцип справедливости", "Принцип автономии",
    "Принцип благодеяния", "Принцип непричинения вреда", "Принцип верности",
    "Принцип честности", "Принцип доброты", "Принцип уважения",
    "Принцип достоинства", "Принцип равенства", "Принцип братства",
    "Принцип солидарности", "Принцип ответственности", "Принцип долга",
    "Принцип совести", "Принцип справедливого возмездия", "Принцип пропорциональности",
    "Принцип необходимой обороны", "Принцип крайней необходимости",
    "Принцип гуманизма", "Принцип человеколюбия", "Принцип милосердия",
    "Принцип сострадания", "Принцип альтруизма", "Принцип эгоизма",
    "Принцип утилитаризма", "Принцип деонтологии", "Принцип конsequentialизма",
    "Принцип virtue ethics", "Принцип кардеологии", "Принцип добродетели",
    "Принцип мудрости", "Принцип мужества", "Принцип умеренности",
    "Принцип справедливости распределения", "Принцип справедливости процедур",
    "Принцип справедливости возмездия", "Принцип справедливости восстановления",
    "Принцип консенсуса", "Принцип большинства", "Принцип меньшинства",
    "Принцип компетентности", "Принцип заслуг", "Принцип потребности",
    "Принцип вклада", "Принцип равных возможностей", "Принцип позитивной дискриминации",
    "Принцип недискриминации", "Принцип толерантности", "Принцип плюрализма",
    "Принцип секуляризма", "Принцип свободы совести", "Принцип свободы вероисповедания",
    "Принцип свободы слова", "Принцип свободы собраний", "Принцип свободы ассоциаций",
    "Принцип права на жизнь", "Принцип права на свободу", "Принцип права на справедливый суд",
    
    # Decision Principles (60)
    "Принцип рациональности", "Принцип эмпиризма", "Принцип прагматизма",
    "Принцип оптимизации", "Принцип максимизации", "Принцип минимизации",
    "Принцип баланса", "Принцип гармонии", "Принцип пропорции",
    "Принцип симметрии", "Принцип асимметрии", "Принцип контраста",
    "Принцип аналогии", "Принцип инверсии", "Принцип декомпозиции",
    "Принцип иерархии", "Принцип приоритетов", "Принцип последовательности",
    "Принцип параллелизма", "Принцип синхронизации", "Принцип асинхронности",
    "Принцип кэширования", "Принцип мемоизации", "Принцип ленивых вычислений",
    "Принцип жадных алгоритмов", "Принцип динамического программирования",
    "Принцип разделяй и властвуй", "Принцип возврата к решению",
    "Принцип случайного поиска", "Принцип целенаправленного поиска",
    "Принцип эвристики", "Принцип приближения", "Принцип эскалации",
    "Принцип дескаалации", "Принцип компромисса", "Принцип торга",
    "Принцип первоначального предложения", "Принцип якоря", "Принцип фрейминга",
    "Принцип перспективы", "Принцип утилиты", "Принцип риска",
    "Принцип неопределенности", "Принцип вероятности", "Принцип статистики",
    "Принцип репрезентативности", "Принцип доступности", "Принцип подтверждения",
    "Принцип фалсификации", "Принцип верификации", "Принцип корреляции",
    "Принцип каузации", "Принцип следствия", "Принцип предшествования",
    "Принцип параллелизма", "Принцип взаимности", "Принцип реципрокности",
    "Принцип эскалации обязательств", "Принцип сожаления", "Принцип гордости",
    
    # Strategic Principles (60)
    "Принцип длинных ставок", "Принцип коротких ставок", "Принцип диверсификации",
    "Принцип концентрации", "Принцип специализации", "Принцип генерализации",
    "Принцип вертикальной интеграции", "Принцип горизонтальной интеграции",
    "Принцип аутсорсинга", "Принцип инсорсинга", "Принцип офшоринга",
    "Принцип локализации", "Принцип глобализации", "Принцип регионализации",
    "Принцип масштабирования", "Принцип оптимизации", "Принцип автоматизации",
    "Принцип ручного труда", "Принцип механизации", "Принцип цифровизации",
    "Принцип виртуализации", "Принцип контейнеризации", "Принцип микросервисов",
    "Принцип монолитности", "Принцип модульности", "Принцип композиции",
    "Принцип наследования", "Принцип полиморфизма", "Принцип инкапсуляции",
    "Принцип абстракции", "Принцип декомпозиции", "Принцип рекомпозиции",
    "Принцип итерации", "Принцип инкрементальности", "Принцип螺旋ного развития",
    "Принцип спиральной модели", "Принцип каскадной модели", "Принцип гибкой методологии",
    "Принцип scrum", "Принцип kanban", "Принцип lean",
    "Принцип six sigma", "Принцип total quality management", "Принцип continuous improvement",
    "Принцип kaizen", "Принцип pokayoke", "Принцип 5S",
    "Принцип just-in-time", "Принцип theory of constraints", "Принцип drums-buffer-rope",
    "Принцип optimized production technology", "Принцип синхронного производства",
    "Принцип pull-системы", "Принцип push-системы", "Принцип гибкого производства",
    "Принцип mass customization", "Принцип персонализации", "Принцип стандартизации",
    "Принцип нормализации", "Принцип регламентации", "Принцип формализации",
    
    # Personal Principles (60)
    "Принцип самодисциплины", "Принцип самоконтроля", "Принцип саморегуляции",
    "Принцип самомотивации", "Принцип самосовершенствования", "Принцип самопознания",
    "Принцип самореализации", "Принцип самовыражения", "Принцип аутентичности",
    "Принцип целостности", "Принцип последовательности", "Принцип интеграции",
    "Принцип баланса", "Принцип гармонии", "Принцип умеренности",
    "Принцип золотой середины", "Принцип баланса работы и жизни",
    "Принцип work-life balance", "Принцип эргономики", "Принцип эстетики",
    "Принцип минимализма", "Принцип максимализма", "Принцип простоты",
    "Принцип сложности", "Принцип элегантности", "Принцип функциональности",
    "Принцип красоты", "Принцип правды", "Принцип добра",
    "Принцип справедливости", "Принцип свободы", "Принцип равенства",
    "Принцип братства", "Принцип солидарности", "Принцип сообщества",
    "Принцип индивидуальности", "Принцип уникальности", "Принцип diversité",
    "Принцип плюрализма", "Принцип толерантности", "Принцип инклюзивности",
    "Принцип доступности", "Принцип универсальности", "Принцип специфичности",
    "Принцип контекстуальности", "Принцип ситуативности", "Принцип гибкости",
    "Принцип адаптивности", "Принцип устойчивости", "Принцип резилиентности",
    "Принцип антихрупкости", "Принцип эргодичности", "Принцип вероятностного мышления",
    "Принцип статистического мышления", "Принцип системного мышления", "Принцип критического мышления",
    "Принцип творческого мышления", "Принцип дизайнерского мышления", "Принцип латерального мышления",
    "Принцип вертикального мышления", "Принцип горизонтального мышления",
    
    # Logic Principles (60)
    "Закон тождества", "Закон противоречия", "Закон исключённого третьего",
    "Закон достаточного основания", "Закон причинности", "Закон следствия",
    "Закон необходимого следования", "Закон контингентного следования",
    "Закон дедукции", "Закон индукции", "Закон абдукции",
    "Закон аналогии", "Закон симметрии", "Закон транзитивности",
    "Закон рефлексивности", "Закон антисимметрии", "Закон асимметрии",
    "Закон монотонности", "Закон идемпотентности", "Закон ассоциативности",
    "Закон коммутативности", "Закон дистрибутивности", "Закон поглощения",
    "Закон нейтрального элемента", "Закон инверсии", "Закон двойного отрицания",
    "Закон де Моргана", "Закон Моргана", "Закон Канта-Поппера-Гемпеля",
    "Закон верификации", "Закон фальсификации", "Закон корреляции",
    "Закон каузации", "Закон спроса", "Закон предельной полезности",
    "Закон убывающей отдачи", "Закон возрастающих издержек", "Закон масштаба",
    "Закон Парето", "Закон Больцмана", "Закон энтропии",
    "Закон устойчивости", "Закон неустойчивости", "Закон равновесия",
    "Закон неравновесия", "Закон саморганизации", "Закон эмерджентности",
    "Закон холизма", "Закон редукционизма", "Закон системности",
    "Закон целостности", "Закон взаимосвязи", "Закон взаимозависимости",
    "Закон взаимодействия", "Закон взаимовлияния", "Закон反馈",
    "Закон положительной обратной связи", "Закон отрицательной обратной связи",
    "Закон катастрофы", "Закон бифуркации", "Закон хаоса",
    "Закон порядка"
)

# ============ RULES (500) ============
Write-Host "=== Defining Rules ==="
$rules = @()

# Generate rules based on values and principles
$ruleTemplates = @(
    "Всегда {principle} в контексте {value}",
    "Никогда не нарушай {principle} ради {value}",
    "Применяй {principle} когда {value} под угрозой",
    "Используй {principle} для достижения {value}",
    "Балансируй {principle} и {value}",
    "Приоритизируй {principle} над {value}",
    "Интегрируй {principle} с {value}",
    "Синтезируй {principle} и {value}",
    "Комбинируй {principle} для {value}",
    "Адаптируй {principle} к {value}",
    "Модифицируй {principle} для {value}",
    "Эскалируй {principle} при {value}",
    "Дескалируй {principle} для {value}",
    "Оптимизируй {principle} для {value}",
    "Максимизируй {principle} через {value}",
    "Минимизируй {principle} для {value}",
    "Балансируй {principle} с {value}",
    "Концентрируй {principle} на {value}",
    "Диверсифицируй {principle} для {value}",
    "Специализируй {principle} в {value}",
    "Генерализируй {principle} для {value}",
    "Интегрируй {principle} в {value}",
    "Сегментируй {principle} для {value}",
    "Персонализируй {principle} для {value}",
    "Стандартизируй {principle} для {value}",
    "Нормализируй {principle} для {value}",
    "Формализируй {principle} для {value}",
    "Регламентируй {principle} для {value}",
    "Автоматизируй {principle} для {value}",
    "Визуализируй {principle} для {value}",
    "Измеряй {principle} для {value}",
    "Контролируй {principle} для {value}",
    "Мониторь {principle} для {value}",
    "Оценивай {principle} для {value}",
    "Анализируй {principle} для {value}",
    "Синтезируй {principle} для {value}",
    "Декомпозируй {principle} для {value}",
    "Рекомпозируй {principle} для {value}",
    "Итерируй {principle} для {value}",
    "Инкрементируй {principle} для {value}",
    "Тестируй {principle} для {value}",
    "Валидируй {principle} для {value}",
    "Верифицируй {principle} для {value}",
    "Фалсифицируй {principle} для {value}",
    "Калибруй {principle} для {value}",
    "Настраивай {principle} для {value}",
    "Адаптируй {principle} для {value}",
    "Модифицируй {principle} для {value}",
    "Трансформируй {principle} для {value}",
    "Эволюционируй {principle} для {value}",
    "Революционизируй {principle} для {value}",
    "Реформируй {principle} для {value}",
    "Консервируй {principle} для {value}",
    "Либерализируй {principle} для {value}",
    "Консервируй {principle} для {value}",
    "Централлизируй {principle} для {value}",
    "Децентрализируй {principle} для {value}",
    "Иерархизируй {principle} для {value}",
    "Флатифицируй {principle} для {value}",
    "Сетифицируй {principle} для {value}",
    "Платформизируй {principle} для {value}",
    "Экосистемизируй {principle} для {value}"
)

foreach ($value in $values[0..49]) {
    foreach ($template in $ruleTemplates[0..9]) {
        $principle = $principles[$rand.Next($principles.Count)]
        $rule = $template -replace '\{principle\}', $principle -replace '\{value\}', $value
        $rules += $rule
    }
}

$rules = $rules | Select-Object -Unique | Select-Object -First 500

# ============ DECISIONS (500) ============
Write-Host "=== Defining Decisions ==="
$decisions = @()

$decisionTemplates = @(
    "Принять решение о {rule}",
    "Выбрать путь {rule}",
    "Определить стратегию {rule}",
    "Разработать план {rule}",
    "Реализовать {rule}",
    "Имплементировать {rule}",
    "Внедрить {rule}",
    "Модифицировать {rule}",
    "Оптимизировать {rule}",
    "Масштабировать {rule}",
    "Диверсифицировать {rule}",
    "Специализировать {rule}",
    "Консолидировать {rule}",
    "Интегрировать {rule}",
    "Сегментировать {rule}",
    "Персонализировать {rule}",
    "Стандартизировать {rule}",
    "Нормализовать {rule}",
    "Формализовать {rule}",
    "Регламентировать {rule}",
    "Автоматизировать {rule}",
    "Визуализировать {rule}",
    "Измерить {rule}",
    "Контролировать {rule}",
    "Мониторить {rule}",
    "Оценить {rule}",
    "Проанализировать {rule}",
    "Синтезировать {rule}",
    "Декомпозировать {rule}",
    "Рекомпозировать {rule}",
    "Итерировать {rule}",
    "Инкрементировать {rule}",
    "Протестировать {rule}",
    "Валидировать {rule}",
    "Верифицировать {rule}",
    "Фалсифицировать {rule}",
    "Калибровать {rule}",
    "Настроить {rule}",
    "Адаптировать {rule}",
    "Модифицировать {rule}",
    "Трансформировать {rule}",
    "Эволюционировать {rule}",
    "Революционизировать {rule}",
    "Реформировать {rule}",
    "Консервировать {rule}",
    "Либерализировать {rule}",
    "Централизовать {rule}",
    "Децентрализовать {rule}",
    "Иерархизировать {rule}",
    "Флатифицировать {rule}",
    "Сетифицировать {rule}",
    "Платформизировать {rule}",
    "Экосистемизировать {rule}"
)

foreach ($rule in $rules[0..299]) {
    foreach ($template in $decisionTemplates[0..1]) {
        $decision = $template -replace '\{rule\}', $rule
        $decisions += $decision
    }
}

$decisions = $decisions | Select-Object -Unique | Select-Object -First 500

# ============ OUTCOMES (600) ============
Write-Host "=== Defining Outcomes ==="
$outcomes = @()

$outcomeTemplates = @(
    "Успех в {decision}",
    "Провал в {decision}",
    "Частичный успех в {decision}",
    "Неожиданный результат {decision}",
    "Позитивный исход {decision}",
    "Негативный исход {decision}",
    "Нейтральный исход {decision}",
    "Смешанный исход {decision}",
    "Долгосрочный успех {decision}",
    "Краткосрочный успех {decision}",
    "Долгосрочный провал {decision}",
    "Краткосрочный провал {decision}",
    "Устойчивый успех {decision}",
    "Нестабильный успех {decision}",
    "Устойчивый провал {decision}",
    "Нестабильный провал {decision}",
    "Масштабируемый успех {decision}",
    "Немасштабируемый успех {decision}",
    "Масштабируемый провал {decision}",
    "Немасштабируемый провал {decision}",
    "Предсказуемый результат {decision}",
    "Непредсказуемый результат {decision}",
    "Контролируемый результат {decision}",
    "Неконтролируемый результат {decision}",
    "Измеримый результат {decision}",
    "Неизмеримый результат {decision}",
    "Воспроизводимый результат {decision}",
    "Невоспроизводимый результат {decision}",
    "Устойчивый результат {decision}",
    "Нестабильный результат {decision}",
    "Локальный результат {decision}",
    "Глобальный результат {decision}",
    "Частный результат {decision}",
    "Публичный результат {decision}",
    "Индивидуальный результат {decision}",
    "Коллективный результат {decision}",
    "Экономический результат {decision}",
    "Социальный результат {decision}",
    "Политический результат {decision}",
    "Технологический результат {decision}",
    "Научный результат {decision}",
    "Культурный результат {decision}",
    "Экологический результат {decision}",
    "Этический результат {decision}",
    "Правовой результат {decision}",
    "Моральный результат {decision}",
    "Психологический результат {decision}",
    "Эмоциональный результат {decision}",
    "Когнитивный результат {decision}",
    "Поведенческий результат {decision}",
    "Физический результат {decision}",
    "Цифровой результат {decision}",
    "Виртуальный результат {decision}",
    "Реальный результат {decision}",
    "Абстрактный результат {decision}",
    "Конкретный результат {decision}",
    "Теоретический результат {decision}",
    "Практический результат {decision}",
    "Гипотетический результат {decision}",
    "Эмпирический результат {decision}"
)

foreach ($decision in $decisions[0..299]) {
    foreach ($template in $outcomeTemplates[0..1]) {
        $outcome = $template -replace '\{decision\}', $decision
        $outcomes += $outcome
    }
}

$outcomes = $outcomes | Select-Object -Unique | Select-Object -First 600

Write-Host "Values: $($values.Count)"
Write-Host "Principles: $($principles.Count)"
Write-Host "Rules: $($rules.Count)"
Write-Host "Decisions: $($decisions.Count)"
Write-Host "Outcomes: $($outcomes.Count)"
Write-Host "Total: $($values.Count + $principles.Count + $rules.Count + $decisions.Count + $outcomes.Count)"

# ============ GENERATE FILES ============
Write-Host "`n=== Generating Files ==="

# Generate Value Notes
Write-Host "Generating Value notes..."
foreach ($value in $values) {
    $safeName = $value -replace '[\\/:*?"<>|]', '_'
    $filePath = Join-Path $baseDir "Values\$safeName.md"
    
    # Find related principles
    $relatedPrinciples = $principles | Where-Object { $_ -match $value -or $value -match $_ } | Select-Object -First 5
    if ($relatedPrinciples.Count -lt 3) {
        $relatedPrinciples = $principles | Get-Random -Count 5
    }
    $principleLinks = ($relatedPrinciples | ForEach-Object { "- [[Principle: $_]]" }) -join "`n"
    
    # Find related values
    $relatedValues = $values | Where-Object { $_ -ne $value } | Get-Random -Count 3
    $valueLinks = ($relatedValues | ForEach-Object { "- [[Value: $_]]" }) -join "`n"
    
    $content = @"
---
type: Value
importance: $($rand.Next(5, 11))
tags: [value, decision-making]
---

# $value

## Описание
Ценность, определяющая направление действий.

## Связанные принципы
$principleLinks

## Связанные ценности
$valueLinks

## Применение
Используется как основа для принятия решений.
"@
    
    $content | Out-File -FilePath $filePath -Encoding UTF8
}

# Generate Principle Notes
Write-Host "Generating Principle notes..."
foreach ($principle in $principles) {
    $safeName = $principle -replace '[\\/:*?"<>|]', '_'
    $filePath = Join-Path $baseDir "Principles\$safeName.md"
    
    # Find related values
    $relatedValues = $values | Get-Random -Count 3
    $valueLinks = ($relatedValues | ForEach-Object { "- [[Value: $_]]" }) -join "`n"
    
    # Find related rules
    $relatedRules = $rules | Where-Object { $_ -match $principle.Substring(0, [math]::Min(10, $principle.Length)) } | Select-Object -First 3
    if ($relatedRules.Count -lt 2) {
        $relatedRules = $rules | Get-Random -Count 3
    }
    $ruleLinks = ($relatedRules | ForEach-Object { "- [[Rule: $_]]" }) -join "`n"
    
    # Find related principles
    $relatedPrinciples = $principles | Where-Object { $_ -ne $principle } | Get-Random -Count 2
    $principleLinks = ($relatedPrinciples | ForEach-Object { "- [[Principle: $_]]" }) -join "`n"
    
    $content = @"
---
type: Principle
category: $($principle.Split(' ')[0])
tags: [principle, decision-making]
---

# $principle

## Описание
Принцип, направляющий принятие решений.

## Связанные ценности
$valueLinks

## Порождает правила
$ruleLinks

## Связанные принципы
$principleLinks
"@
    
    $content | Out-File -FilePath $filePath -Encoding UTF8
}

# Generate Rule Notes
Write-Host "Generating Rule notes..."
foreach ($rule in $rules) {
    $safeName = $rule -replace '[\\/:*?"<>|]', '_'
    if ($safeName.Length -gt 100) { $safeName = $safeName.Substring(0, 100) }
    $filePath = Join-Path $baseDir "Rules\$safeName.md"
    
    # Find related principles
    $relatedPrinciples = $principles | Get-Random -Count 2
    $principleLinks = ($relatedPrinciples | ForEach-Object { "- [[Principle: $_]]" }) -join "`n"
    
    # Find related decisions
    $relatedDecisions = $decisions | Where-Object { $_ -match $rule.Substring(0, [math]::Min(15, $rule.Length)) } | Select-Object -First 2
    if ($relatedDecisions.Count -lt 2) {
        $relatedDecisions = $decisions | Get-Random -Count 2
    }
    $decisionLinks = ($relatedDecisions | ForEach-Object { "- [[Decision: $_]]" }) -join "`n"
    
    # Find related rules
    $relatedRules = $rules | Where-Object { $_ -ne $rule } | Get-Random -Count 2
    $ruleLinks = ($relatedRules | ForEach-Object { "- [[Rule: $_]]" }) -join "`n"
    
    $content = @"
---
type: Rule
tags: [rule, decision-making]
---

# $rule

## Описание
Правило, вытекающее из принципов.

## Основано на принципах
$principleLinks

## Применяется в решениях
$decisionLinks

## Связанные правила
$ruleLinks
"@
    
    $content | Out-File -FilePath $filePath -Encoding UTF8
}

# Generate Decision Notes
Write-Host "Generating Decision notes..."
foreach ($decision in $decisions) {
    $safeName = $decision -replace '[\\/:*?"<>|]', '_'
    if ($safeName.Length -gt 100) { $safeName = $safeName.Substring(0, 100) }
    $filePath = Join-Path $baseDir "Decisions\$safeName.md"
    
    # Find related rules
    $relatedRules = $rules | Get-Random -Count 2
    $ruleLinks = ($relatedRules | ForEach-Object { "- [[Rule: $_]]" }) -join "`n"
    
    # Find related outcomes
    $relatedOutcomes = $outcomes | Where-Object { $_ -match $decision.Substring(0, [math]::Min(15, $decision.Length)) } | Select-Object -First 3
    if ($relatedOutcomes.Count -lt 2) {
        $relatedOutcomes = $outcomes | Get-Random -Count 3
    }
    $outcomeLinks = ($relatedOutcomes | ForEach-Object { "- [[Outcome: $_]]" }) -join "`n"
    
    # Find related decisions
    $relatedDecisions = $decisions | Where-Object { $_ -ne $decision } | Get-Random -Count 2
    $decisionLinks = ($relatedDecisions | ForEach-Object { "- [[Decision: $_]]" }) -join "`n"
    
    $content = @"
---
type: Decision
status: pending
tags: [decision, decision-making]
---

# $decision

## Описание
Конкретное решение, принятое на основе правил.

## Основано на правилах
$ruleLinks

## Ведёт к результатам
$outcomeLinks

## Связанные решения
$decisionLinks
"@
    
    $content | Out-File -FilePath $filePath -Encoding UTF8
}

# Generate Outcome Notes
Write-Host "Generating Outcome notes..."
foreach ($outcome in $outcomes) {
    $safeName = $outcome -replace '[\\/:*?"<>|]', '_'
    if ($safeName.Length -gt 100) { $safeName = $safeName.Substring(0, 100) }
    $filePath = Join-Path $baseDir "Outcomes\$safeName.md"
    
    # Find related decisions
    $relatedDecisions = $decisions | Get-Random -Count 2
    $decisionLinks = ($relatedDecisions | ForEach-Object { "- [[Decision: $_]]" }) -join "`n"
    
    # Find related outcomes
    $relatedOutcomes = $outcomes | Where-Object { $_ -ne $outcome } | Get-Random -Count 2
    $outcomeLinks = ($relatedOutcomes | ForEach-Object { "- [[Outcome: $_]]" }) -join "`n"
    
    # Find related principles (cross-connections)
    $relatedPrinciples = $principles | Get-Random -Count 2
    $principleLinks = ($relatedPrinciples | ForEach-Object { "- [[Principle: $_]]" }) -join "`n"
    
    $content = @"
---
type: Outcome
status: observed
tags: [outcome, decision-making]
---

# $outcome

## Описание
Результат принятого решения.

## Вызвано решением
$decisionLinks

## Связанные результаты
$outcomeLinks

## Влияет на принципы
$principleLinks
"@
    
    $content | Out-File -FilePath $filePath -Encoding UTF8
}

Write-Host "`n=== Generation Complete ==="

# Count files
$valuesCount = (Get-ChildItem -Path "$baseDir\Values" -Filter "*.md" -ErrorAction SilentlyContinue).Count
$principlesCount = (Get-ChildItem -Path "$baseDir\Principles" -Filter "*.md" -ErrorAction SilentlyContinue).Count
$rulesCount = (Get-ChildItem -Path "$baseDir\Rules" -Filter "*.md" -ErrorAction SilentlyContinue).Count
$decisionsCount = (Get-ChildItem -Path "$baseDir\Decisions" -Filter "*.md" -ErrorAction SilentlyContinue).Count
$outcomesCount = (Get-ChildItem -Path "$baseDir\Outcomes" -Filter "*.md" -ErrorAction SilentlyContinue).Count

Write-Host "Values: $valuesCount"
Write-Host "Principles: $principlesCount"
Write-Host "Rules: $rulesCount"
Write-Host "Decisions: $decisionsCount"
Write-Host "Outcomes: $outcomesCount"
Write-Host "Total: $($valuesCount + $principlesCount + $rulesCount + $decisionsCount + $outcomesCount)"
