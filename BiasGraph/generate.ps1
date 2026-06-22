# BiasGraph Vault Generator
# Generates 250+ interconnected notes for "Карта заблуждений"

$ErrorActionPreference = "Stop"
$basePath = "C:\obsidian\Main\BiasGraph"

# Create directories
$dirs = @("Biases", "Errors", "Corrections")
foreach ($dir in $dirs) {
    $path = Join-Path $basePath $dir
    if (-not (Test-Path $path)) {
        New-Item -ItemType Directory -Path $path -Force | Out-Null
    }
}

# Arrays to store note titles for linking
$biases = @()
$errors = @()
$corrections = @()

# ============================================
# BIASES (80+)
# ============================================
$biasData = @(
    @{name="Подтверждающее искажение"; desc="Склонность искать и интерпретировать информацию, подтверждающую наши убеждения"; sev="high"; freq="very_common"},
    @{name="Эффект толпы"; desc="Склонность делать то, что делают другие люди"; sev="medium"; freq="very_common"},
    @{name="Искажение выжившего"; desc="Сфокусированность на успехе, игнорируя неудачи"; sev="medium"; freq="common"},
    @{name="Эффект свиньи"; desc="Паразитарное поведение в групповых проектах"; sev="medium"; freq="common"},
    @{name="Якорение"; desc="Чрезмерное влияние первой полученной информации"; sev="high"; freq="very_common"},
    @{name="Эффект приманки"; desc="Добавление нежелательной альтернативы для влияния на выбор"; sev="low"; freq="common"},
    @{name="Эффект неупомянутой альтернативы"; desc="Нерассмотренные альтернативы кажутся менее вероятными"; sev="medium"; freq="common"},
    @{name="Искажение хинсайт"; desc="После события кажется, что оно было предсказуемым"; sev="high"; freq="very_common"},
    @{name="Эффект Дunningа-Крюгера"; desc="Некомпетентные люди переоценивают свои способности"; sev="high"; freq="very_common"},
    @{name="Иллюзия контроля"; desc="Переоценка влияния на события, которые мы не контролируем"; sev="medium"; freq="common"},
    @{name="Эффект плато"; desc="Стагнация после начального прогресса"; sev="medium"; freq="common"},
    @{name="Фундаментальная ошибка атрибуции"; desc="Приписывание поведения личности, а не ситуации"; sev="high"; freq="very_common"},
    @{name="Групповая поляризация"; desc="Усиление групповых убеждений после обсуждения"; sev="high"; freq="common"},
    @{name="Эффект сверхуверенности"; desc="Завышенная оценка точности своих прогнозов"; sev="high"; freq="very_common"},
    @{name="Availability cascade"; desc="Убеждения усиливаются по мере запоминаемости примеров"; sev="medium"; freq="common"},
    @{name="Bandwagon effect"; desc="Склонность делать то, что делают другие"; sev="medium"; freq="very_common"},
    @{name="Bias blind spot"; desc="Невосприимчивость к когнитивным искажениям у себя"; sev="high"; freq="very_common"},
    @{name="Cheerleader effect"; desc="Люди кажутся более привлекательными в группе"; sev="low"; freq="common"},
    @{name="Choice-supportive bias"; desc="Ретроспективное одобрение своего выбора"; sev="medium"; freq="common"},
    @{name="Clustering illusion"; desc="Видение паттернов в случайных данных"; sev="high"; freq="common"},
    @{name="Curse of knowledge"; desc="Невозможность представить, как не знать то, что знаешь сам"; sev="medium"; freq="very_common"},
    @{name="Decoy effect"; desc="Влияние нерелевантной альтернативы на выбор"; sev="low"; freq="common"},
    @{name="Denomination effect"; desc="Большие купюры кажутся более ценными"; sev="low"; freq="common"},
    @{name="Distinction bias"; desc="Разница в восприятии при сравнении"; sev="low"; freq="common"},
    @{name="Endowment effect"; desc="Завышение ценности того, чем уже владеешь"; sev="high"; freq="very_common"},
    @{name="Euler's identity bias"; desc="Красота уравнения влияет на восприятие его истинности"; sev="low"; freq="rare"},
    @{name="Exponential growth bias"; desc="Недооценка экспоненциального роста"; sev="high"; freq="common"},
    @{name="Focusing effect"; desc="Чрезмерный акцент на одной информации"; sev="medium"; freq="common"},
    @{name="Framing effect"; desc="Влияние формулировки на восприятие"; sev="high"; freq="very_common"},
    @{name="Gambler's fallacy"; desc="Вероятность прошлых событий влияет на будущие"; sev="high"; freq="common"},
    @{name="Gaze aversion"; desc="Избегание зрительного контакта при обработке информации"; sev="low"; freq="common"},
    @{name="Google effect"; desc="Забывание информации, доступной в интернете"; sev="medium"; freq="common"},
    @{name="Grass is greener"; desc="Вера, что другие варианты лучше"; sev="medium"; freq="common"},
    @{name="Group attribution bias"; desc="Приписывание личности группы отдельному члену"; sev="medium"; freq="common"},
    @{name="Hard-easy effect"; desc="Завышение сложных задач, недооценка простых"; sev="medium"; freq="common"},
    @{name="Hindsight bias"; desc="После события кажется, что оно было предсказуемым"; sev="high"; freq="very_common"},
    @{name="Hostile media effect"; desc="Восприятие СМИ как предвзятых против своей стороны"; sev="medium"; freq="common"},
    @{name="Hyperbolic discounting"; desc="Предпочтение небольшого вознаграждения сейчас, чем большого позже"; sev="high"; freq="very_common"},
    @{name="Identifiable victim effect"; desc="Большая эмпатия к конкретной жертве, чем к статистике"; sev="medium"; freq="common"},
    @{name="Impact bias"; desc="Переоценка длительности эмоциональных реакций"; sev="medium"; freq="common"},
    @{name="Information bias"; desc="Сбор избыточной информации, не влияющей на решение"; sev="medium"; freq="common"},
    @{name="In-group bias"; desc="Предпочтение членов своей группы"; sev="high"; freq="very_common"},
    @{name="Inter-group bias"; desc="Негативное отношение к другой группе"; sev="high"; freq="common"},
    @{name="Internet addiction"; desc="Чрезмерное использование интернета"; sev="high"; freq="common"},
    @{name="Irrational escalation"; desc="Увеличение инвестиций в проигрышное дело"; sev="high"; freq="common"},
    @{name="Law of small numbers"; desc="Вер в репрезентативность малых выборок"; sev="medium"; freq="common"},
    @{name="Less-is-more effect"; desc="Предпочтение меньшего, но более релевантного"; sev="low"; freq="common"},
    @{name="Loss aversion"; desc="Большая боль от потери, чем удовольствие от приобретения"; sev="high"; freq="very_common"},
    @{name="Mere exposure effect"; desc="Знакомство порождает предпочтение"; sev="medium"; freq="very_common"},
    @{name="Money illusion"; desc="Номинальная стоимость важнее реальной"; sev="medium"; freq="common"},
    @{name="Moral credential bias"; desc="Прошлый моральный поступок оправдывает будущий"; sev="medium"; freq="common"},
    @{name="Negativity bias"; desc="Негативная информация весомее позитивной"; sev="high"; freq="very_common"},
    @{name="Not Invented Here"; desc="Отвержение идей из-за их внешнего происхождения"; sev="medium"; freq="common"},
    @{name="Omission bias"; desc="Предпочтение бездействия перед действием"; sev="medium"; freq="common"},
    @{name="Optimism bias"; desc="Завышение вероятности благоприятного исхода"; sev="high"; freq="very_common"},
    @{name="Ostrich effect"; desc="Игнорирование негативной информации"; sev="high"; freq="common"},
    @{name="Outcome bias"; desc="Оценка решения по результату, а не по процессу"; sev="high"; freq="very_common"},
    @{name="Overconfidence effect"; desc="Завышенная уверенность в своих знаниях"; sev="high"; freq="very_common"},
    @{name="Pessimism bias"; desc="Занижение вероятности благоприятного исхода"; sev="medium"; freq="common"},
    @{name="Plan continuation bias"; desc="Приоритет текущего плана перед новой информацией"; sev="medium"; freq="common"},
    @{name="Projection bias"; desc="Проекция текущих чувств на будущее"; sev="medium"; freq="common"},
    @{name="Pro-innovation bias"; desc="Чрезмерный оптимизм к новым технологиям"; sev="medium"; freq="common"},
    @{name="Pseudocertainty effect"; desc="Восприятие условной вероятности как безусловной"; sev="low"; freq="rare"},
    @{name="Reactance"; desc="Сопротивление давлению на свободу выбора"; sev="medium"; freq="common"},
    @{name="Reality tunnel"; desc="Восприятие мира через призму убеждений"; sev="high"; freq="common"},
    @{name="Recency bias"; desc="Приоритет недавней информации"; sev="medium"; freq="very_common"},
    @{name="Rhyme as reason"; desc="Рифмованные аргументы кажутся более убедительными"; sev="low"; freq="common"},
    @{name="Risk compensation"; desc="Более безопасное поведение приводит к большему риску"; sev="medium"; freq="common"},
    @{name="Risk perception"; desc="Искажённое восприятие рисков"; sev="high"; freq="very_common"},
    @{name="Status quo bias"; desc="Предпочтение текущего состояния"; sev="high"; freq="very_common"},
    @{name="Stereotyping"; desc="Приписывание характеристик группе"; sev="high"; freq="very_common"},
    @{name="Subadditivity effect"; desc="Части кажутся более вероятными, чем целое"; sev="low"; freq="common"},
    @{name="Survivorship bias"; desc="Фокус на successes, игнорируя failures"; sev="high"; freq="very_common"},
    @{name="Survivorship guilt"; desc="Чувство вины за выживание"; sev="medium"; freq="common"},
    @{name="System justification"; desc="Оправдание существующей системы"; sev="medium"; freq="common"},
    @{name="Time-saving bias"; desc="Переоценка времени, сэкономленного увеличением скорости"; sev="low"; freq="common"},
    @{name="Unit bias"; desc="Восприятие одной порции как нормы"; sev="low"; freq="common"},
    @{name="Uniqueness bias"; desc="Вера в свою уникальность"; sev="medium"; freq="very_common"},
    @{name="Verbatim effect"; desc="Запоминание сути лучше, чем точных слов"; sev="low"; freq="common"},
    @{name="Zero-risk bias"; desc="Предпочтение полного устранения одного риска"; sev="medium"; freq="common"},
    @{name="Zero-sum bias"; desc="Восприятие ситуации как игры с нулевой суммой"; sev="high"; freq="very_common"}
)

foreach ($b in $biasData) {
    $biases += $b.name
    $cleanName = $b.name -replace '[\\/:*?"<>|]', '_'
    $filePath = Join-Path $basePath "Biases\$cleanName.md"
    $content = @"
---
type: Bias
severity: $($b.sev)
frequency: $($b.freq)
tags: [bias, cognitive]
---

# $($b.name)

## Описание
$($b.desc)

## Порождает ошибки
$(if ($biasData.IndexOf($b) -lt 20) {
    "- [[$($errors[($biasData.IndexOf($b) * 3) % $errors.Count])]]"
    "- [[$($errors[($biasData.IndexOf($b) * 3 + 1) % $errors.Count])]]"
    "- [[$($errors[($biasData.IndexOf($b) * 3 + 2) % $errors.Count])]]"
} else {
    "- [[$($errors[($biasData.IndexOf($b)) % $errors.Count])]]"
    "- [[$($errors[($biasData.IndexOf($b) + 1) % $errors.Count])]]"
})

## Усиливает
- [[$($biases[($biasData.IndexOf($b) + 1) % $biases.Count])]]
- [[$($biases[($biasData.IndexOf($b) + 5) % $biases.Count])]]

## Ослабляется
- [[$($corrections[($biasData.IndexOf($b)) % $corrections.Count])]]
- [[$($corrections[($biasData.IndexOf($b) + 1) % $corrections.Count])]]

## Ловушки связанные
- [[$($errors[($biasData.IndexOf($b) + 2) % $errors.Count])]]
"@
    Set-Content -Path $filePath -Value $content -Encoding UTF8
}

# ============================================
# ERRORS (80+)
# ============================================
$errorData = @(
    @{name="Ошибка подгонки"; desc="Подгонка интерпретации данных под ожидания"},
    @{name="Ложная дихотомия"; desc="Представление двух вариантов, когда их больше"},
    @{name="Соломенное чучело"; desc="Искажение аргумента оппонента для атаки"},
    @{name="Ad hominem"; desc="Атака на личность вместо аргумента"},
    @{name="Appeal to authority"; desc="Аргумент к авторитету без обоснования"},
    @{name="Appeal to emotion"; desc="Апелляция к эмоциям вместо логики"},
    @{name="Appeal to nature"; desc="Натуральное = лучшее"},
    @{name="Appeal to tradition"; desc="Традиционное = правильное"},
    @{name="Begging the question"; desc="Заключение предполагается в предпосылке"},
    @{name="Black-or-white"; desc="Только два варианта, когда есть другие"},
    @{name="Burden of proof"; desc="Перекладывание обязанности доказывать"},
    @{name="Cherry picking"; desc="Выбор данных, подтверждающих позицию"},
    @{name="Causal oversimplification"; desc="Упрощение причинно-следственных связей"},
    @{name="Circular reasoning"; desc="Доказательство через то, что нужно доказать"},
    @{name="Composition"; desc="Части обладают свойствами целого"},
    @{name="Confusion of necessary and sufficient"; desc="Смешение необходимых и достаточных условий"},
    @{name="Cum hoc"; desc="Корреляция = каузация"},
    @{name="Denying the antecedent"; desc="Отрицание антецедента"},
    @{name="Dicto simpliciter"; desc="Обобщение без исключений"},
    @{name="Discursive fallacy"; desc="Стилистические уловки вместо аргументов"},
    @{name="Equivocation"; desc="Двойное значение термина"},
    @{name="Eternal God fallacy"; desc="Всё было всегда, ничего не меняется"},
    @{name="Excluded middle"; desc="Третий вариант исключён"},
    @{name="Experiential fallacy"; desc="Личный опыт = универсальная истина"},
    @{name="False cause"; desc="Ложная причинно-следственная связь"},
    @{name="False dilemma"; desc="Ложная дилемма"},
    @{name="False equivalence"; desc="Равнозначность не равноценных вещей"},
    @{name="Faulty analogy"; desc="Некорректная аналогия"},
    @{name="Gambler's fallacy error"; desc="Ожидаемое событие после серии проигрышей"},
    @{name="Genetic fallacy"; desc="Оценка по происхождению"},
    @{name="Half truth"; desc="Частичная правда"},
    @{name="Hedging"; desc="Уход от прямого ответа"},
    @{name="Hasty generalization"; desc="Обобщение на основе малого числа случаев"},
    @{name="Inner ring fallacy"; desc="Вера в скрытые знания"},
    @{name="Inquisition"; desc="Допрос вместо дискуссии"},
    @{name="Intentional fallacy"; desc="Намерение автора определяет значение"},
    @{name="Is-ought"; desc="Избытие из долженствования"},
    @{name="Just-world fallacy"; desc="Мир справедлив, каждый получает по заслугам"},
    @{name="Ludic fallacy"; desc="Применение игральных моделей к реальности"},
    @{name="Magical thinking"; desc="Магическая связь между мыслями и событиями"},
    @{name="Masked man"; desc="Невозможность доказать идентичность"},
    @{name="Modal fallacy"; desc="Смешение модальностей"},
    @{name="Moralistic fallacy"; desc="Избытие из морали"},
    @{name="Morton's fork"; desc="Дилемма, где оба варианта ведут к одному"},
    @{name="Moving the goalposts"; desc="Смена критериев после достижения"},
    @{name="Naturalistic fallacy"; desc="Естественное = хорошее"},
    @{name="Negative proof"; desc="Отсутствие доказательства не есть доказательство"},
    @{name="No true Scotsman"; desc="Изменение определения для исключения контрпримеров"},
    @{name="Non causa"; desc="Ложная причина"},
    @{name="Non sequitur"; desc="Заключение не следует из предпосылок"},
    @{name="Not my job"; desc="Уклонение от ответственности"},
    @{name="Nutshell fallacy"; desc="Упрощение до потери смысла"},
    @{name="One-sidedness"; desc="Односторонний анализ"},
    @{name="Oversimplification"; desc="Чрезмерное упрощение"},
    @{name="Paradise lost"; desc="Вера в утраченный рай"},
    @{name="Pathos"; desc="Апелляция к страданию"},
    @{name="Perfectionist fallacy"; desc="Всё или ничего"},
    @{name="Personal attack"; desc="Атака на личность"},
    @{name="Poisoning the well"; desc="Предвзятость до начала дискуссии"},
    @{name="Post hoc"; desc="Хронологическая последовательность = причинность"},
    @{name="Psychologist's fallacy"; desc="Проекция своих мыслей на других"},
    @{name="Questionable cause"; desc="Сомнительная причинность"},
    @{name="Red herring"; desc="Отвлекающий манёвр"},
    @{name="Reification"; desc="Овеществление абстракций"},
    @{name="Relativist fallacy"; desc="Отрицание объективных истин"},
    @{name="Retreat to the impossible"; desc="Уход к невозможным аргументам"},
    @{name="Single cause"; desc="Одна причина сложного явления"},
    @{name="Slippery slope"; desc="Катящийся склон"},
    @{name="Special pleading"; desc="Исключение из правил для себя"},
    @{name="Stolen concept"; desc="Использование понятия для отрицания его"},
    @{name="Straw man"; desc="Соломенное чучело"},
    @{name="Suppressed correlative"; desc="Подавление альтернативы"},
    @{name="Sweeping generalization"; desc="Слепое обобщение"},
    @{name="Taboo"; desc="Запрет на обсуждение"},
    @{name="Texas sharpshooter"; desc="Подгонка теории под данные"},
    @{name="Truth by assertion"; desc="Утверждение = истина"},
    @{name="Two wrongs"; desc="Два неправильных = одно правильное"},
    @{name="Unity of virtue"; desc="Единство добродетелей"},
    @{name="Unstated premise"; desc="Неявная предпосылка"},
    @{name="Weasel word"; desc="Нечёткие формулировки"},
    @{name="Wishful thinking"; desc="Желаемое за действительное"},
    @{name="Wrong direction"; desc="Направление причинности"}
)

foreach ($e in $errorData) {
    $errors += $e.name
    $cleanName = $e.name -replace '[\\/:*?"<>|]', '_'
    $filePath = Join-Path $basePath "Errors\$cleanName.md"
    $idx = $errorData.IndexOf($e)
    $content = @"
---
type: Error
tags: [error, logical-fallacy]
---

# $($e.name)

## Описание
$($e.desc)

## Порождает следствия
- [[$($corrections[$idx % $corrections.Count])]]
- [[$($corrections[($idx + 1) % $corrections.Count])]]
- [[$($corrections[($idx + 2) % $corrections.Count])]]

## Вызывается искажениями
- [[$($biases[$idx % $biases.Count])]]
- [[$($biases[($idx + 3) % $biases.Count])]]

## Связанные ошибки
- [[$($errors[($idx + 1) % $errors.Count])]]
- [[$($errors[($idx + 2) % $errors.Count])]]

## Как исправить
- [[Критическое мышление]]
- [[Seek disconfirming evidence]]
"@
    Set-Content -Path $filePath -Value $content -Encoding UTF8
}

# ============================================
# CORRECTIONS (90+)
# ============================================
$correctionData = @(
    @{name="Мысленный эксперимент"; desc="Гипотетические сценарии для проверки идей"},
    @{name="Альтернативная гипотеза"; desc="Формулировка конкурирующих объяснений"},
    @{name="Статистический анализ"; desc="Использование статистических методов"},
    @{name="Peer review"; desc="Экспертиза равными"},
    @{name="Факт-чекинг"; desc="Проверка фактов перед принятием"},
    @{name="Критическое мышление"; desc="Анализ и оценка информации"},
    @{name="Метод исключения"; desc="Последовательное исключение вариантов"},
    @{name="Обратное доказательство"; desc="Поиск доказательств против自己的 позиции"},
    @{name="Аргументация со справедливой стороны"; desc="Лучшее представление оппонента"},
    @{name="Контрольные вопросы"; desc="Чек-лист для проверки решений"},
    @{name="Список контрольных точек"; desc="Этапы проверки"},
    @{name="Байесовское обновление"; desc="Обновление вероятностей на основе данных"},
    @{name="Калибровка уверенности"; desc="Соответствие уверенности и точности"},
    @{name="Декомпозиция проблемы"; desc="Разбиение на части"},
    @{name="Структурированный анализ"; desc="Системный подход к анализу"},
    @{name="Мозговой штурм"; desc="Генерация идей без критики"},
    @{name="Devil's advocate"; desc="Намеренная аргументация против"},
    @{name="6 шляп мышления"; desc="Шесть перспектив анализа"},
    @{name="SWOT-анализ"; desc="Сильные, слабые стороны, возможности, угрозы"},
    @{name="Матрица решений"; desc="Оценка вариантов по критериям"},
    @{name="Агентный подход"; desc="Действия от третьего лица"},
    @{name="Ментальные модели"; desc="Фреймворки для понимания мира"},
    @{name="First principles thinking"; desc="Анализ с основ"},
    @{name="Second-order thinking"; desc="Мыслить на два шага вперёд"},
    @{name="Inversion"; desc="Решение наоборот"},
    @{name="Circle of competence"; desc="Знание своих границ"},
    @{name="Margin of safety"; desc="Запас прочности"},
    @{name="Pre-mortem analysis"; desc="Анализ до начала проекта"},
    @{name="After-action review"; desc="Анализ после события"},
    @{name="Decision journal"; desc="Запись решений для обучения"},
    @{name="Red team thinking"; desc="Атака на собственную стратегию"},
    @{name="Scenario planning"; desc="Планирование сценариев"},
    @{name="Force field analysis"; desc="Анализ сил за и против"},
    @{name="Root cause analysis"; desc="Поиск корневой причины"},
    @{name="Five whys"; desc="Пять вопросов почему"},
    @{name="Ishikawa diagram"; desc="Диаграмма причинно-следственных связей"},
    @{name="Pareto analysis"; desc="Правило 80/20"},
    @{name="Cost-benefit analysis"; desc="Сравнение затрат и выгод"},
    @{name="Decision matrix"; desc="Матрица решений"},
    @{name="Risk assessment"; desc="Оценка рисков"},
    @{name="Sensitivity analysis"; desc="Анализ чувствительности"},
    @{name="Expected value calculation"; desc="Расчёт ожидаемой стоимости"},
    @{name="Regret minimization"; desc="Минимизация сожалений"},
    @{name="Inversion thinking"; desc="Мыслить наоборот"},
    @{name="Second-order effects"; desc="Побочные эффекты"},
    @{name="Time horizon analysis"; desc="Анализ временного горизонта"},
    @{name="Outside view"; desc="Внешняя перспектива"},
    @{name="Reference class forecasting"; desc="Прогнозирование по классу"},
    @{name="Pre-commitment"; desc="Заранее данное обещание"},
    @{name="Implementation intentions"; desc="Конкретные планы действий"},
    @{name="Temptation bundling"; desc="Связывание удовольствий"},
    @{name="If-then planning"; desc="Планирование если-то"},
    @{name="Accountability partner"; desc="Партнёр по ответственности"},
    @{name="Track record analysis"; desc="Анализ прошлых результатов"},
    @{name="Calibration training"; desc="Тренировка точности"},
    @{name="Probabilistic thinking"; desc="Вероятностное мышление"},
    @{name="Confidence intervals"; desc="Доверительные интервалы"},
    @{name="Fermi estimation"; desc="Оценка Ферми"},
    @{name="Order of magnitude"; desc="Порядок величины"},
    @{name="Fermi question"; desc="Вопрос Ферми"},
    @{name="Decomposition"; desc="Разбиение на составляющие"},
    @{name="Lateral thinking"; desc="Боковое мышление"},
    @{name="Reverse brainstorming"; desc="Обратный мозговой штурм"},
    @{name="Assumption busting"; desc="Разрушение допущений"},
    @{name="Random input"; desc="Случайный стимул"},
    @{name="Provocation"; desc="Провокация"},
    @{name="Challenge assumptions"; desc="Проверка допущений"},
    @{name="Question everything"; desc="Вопрошать всё"},
    @{name="Seek disconfirming evidence"; desc="Искать опровергающие данные"},
    @{name="Steel-manning"; desc="Укрепление аргумента оппонента"},
    @{name="Charity principle"; desc="Принцип благожелательности"},
    @{name="Bayesian updating"; desc="Обновление по Байесу"},
    @{name="Prior probability"; desc="Пrior вероятность"},
    @{name="Likelihood ratio"; desc="Отношение правдоподобий"},
    @{name="Posterior probability"; desc="Posterior вероятность"},
    @{name="Expected utility"; desc="Ожидаемая полезность"},
    @{name="Utility function"; desc="Функция полезности"},
    @{name="Loss function"; desc="Функция потерь"},
    @{name="Risk aversion"; desc="Неприятие риска"},
    @{name="Prospect theory"; desc="Теория перспектив"},
    @{name="Satisficing"; desc="Достаточно хорошее решение"},
    @{name="Optimizing"; desc="Оптимизация"},
    @{name="Satisficing vs optimizing"; desc="Сравнение подходов"},
    @{name="Good enough"; desc="Достаточно хорошо"},
    @{name="Bounded rationality"; desc="Ограниченная рациональность"},
    @{name="Ecological rationality"; desc="Экологическая рациональность"},
    @{name="Fast and frugal heuristics"; desc="Быстрые эвристики"},
    @{name="Recognition heuristic"; desc="Эвристика узнавания"},
    @{name="Take the best"; desc="Выбор лучшего"},
    @{name="1/N heuristic"; desc="Равномерное распределение"},
    @{name="Equally weighted"; desc="Равный вес"},
    @{name="Tallying"; desc="Подсчёт"},
    @{name="Natural sampling"; desc="Естественная выборка"}
)

foreach ($c in $correctionData) {
    $corrections += $c.name
    $cleanName = $c.name -replace '[\\/:*?"<>|]', '_'
    $filePath = Join-Path $basePath "Corrections\$cleanName.md"
    $idx = $correctionData.IndexOf($c)
    $content = @"
---
type: Correction
tags: [correction, improvement]
---

# $($c.name)

## Описание
$($c.desc)

## Исправляет искажения
- [[$($biases[$idx % $biases.Count])]]
- [[$($biases[($idx + 2) % $biases.Count])]]
- [[$($biases[($idx + 5) % $biases.Count])]]

## Связанные методы
- [[$($corrections[($idx + 1) % $corrections.Count])]]
- [[$($corrections[($idx + 3) % $corrections.Count])]]

## Применяется к ошибкам
- [[$($errors[$idx % $errors.Count])]]
- [[$($errors[($idx + 4) % $errors.Count])]]

## Как использовать
1. Определите проблему
2. Выберите метод
3. Примените пошагово
4. Проверьте результат
"@
    Set-Content -Path $filePath -Value $content -Encoding UTF8
}

Write-Host "Vault created at: $basePath"
Write-Host "Biases: $($biases.Count)"
Write-Host "Errors: $($errors.Count)"
Write-Host "Corrections: $($corrections.Count)"
Write-Host "Total: $($biases.Count + $errors.Count + $corrections.Count)"
