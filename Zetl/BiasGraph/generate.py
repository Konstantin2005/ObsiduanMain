#!/usr/bin/env python3
# -*- coding: utf-8 -*-
"""BiasGraph Vault Generator - Creates 250+ interconnected Obsidian notes."""

import os
import random

random.seed(42)  # Reproducible

BASE = r"C:\obsidian\Main\BiasGraph"
DIRS = ["Biases", "Errors", "Corrections"]

# Create directories
for d in DIRS:
    os.makedirs(os.path.join(BASE, d), exist_ok=True)

# ============================================
# DATA DEFINITIONS
# ============================================

bias_data = [
    ("Подтверждающее искажение", "Склонность искать и интерпретировать информацию, подтверждающую наши убеждения, и игнорировать противоречащую", "high", "very_common"),
    ("Эффект толпы", "Склонность делать то, что делают другие люди, подчиняясь групповому давлению", "medium", "very_common"),
    ("Искажение выжившего", "Фокус на успехе и выживших, игнорируя неудачи и погибших", "high", "common"),
    ("Эффект свиньи", "Паразитарное поведение в групповых проектах — получение выгоды без вклада", "medium", "common"),
    ("Якорение", "Чрезмерное влияние первой полученной информации на последующие оценки", "high", "very_common"),
    ("Эффект приманки", "Добавление заведомо нежелательной альтернативы для влияния на выбор между другими", "low", "common"),
    ("Эффект неупомянутой альтернативы", "Нерассмотренные альтернативы кажутся менее вероятными", "medium", "common"),
    ("Искажение хинсайт", "После события кажется, что оно было предсказуемым — «я же знал»", "high", "very_common"),
    ("Эффект Дunningа-Крюгера", "Некомпетентные люди переоценивают свои способности, а компетентные — недооценивают", "high", "very_common"),
    ("Иллюзия контроля", "Переоценка влияния на события, которые мы не контролируем", "medium", "common"),
    ("Эффект плато", "Стагнация и потеря мотивации после начального прогресса", "medium", "common"),
    ("Фундаментальная ошибка атрибуции", "Приписывание поведения личности, а не ситуации", "high", "very_common"),
    ("Групповая поляризация", "Усиление групповых убеждений после обсуждения в группе", "high", "common"),
    ("Эффект сверхуверенности", "Завышенная оценка точности своих прогнозов и знаний", "high", "very_common"),
    ("Availability cascade", "Убеждения усиливаются по мере запоминаемости примеров из памяти", "medium", "common"),
    ("Bandwagon effect", "Склонность принимать то, что считается популярным", "medium", "very_common"),
    ("Bias blind spot", "Невосприимчивость к когнитивным искажениям у себя, признавая их у других", "high", "very_common"),
    ("Cheerleader effect", "Люди кажутся более привлекательными в группе, чем по отдельности", "low", "common"),
    ("Choice-supportive bias", "Ретроспективное одобрение своего выбора и преувеличение его достоинств", "medium", "common"),
    ("Clustering illusion", "Видение паттернов и закономерностей в случайных данных", "high", "common"),
    ("Curse of knowledge", "Невозможность представить, как не знать то, что знаешь сам", "medium", "very_common"),
    ("Decoy effect", "Влияние нерелевантной альтернативы на выбор между двумя другими", "low", "common"),
    ("Denomination effect", "Большие купюры кажутся более ценными, чем мелочь той же суммы", "low", "common"),
    ("Distinction bias", "Разница в восприятии при одновременном сравнении объектов", "low", "common"),
    ("Endowment effect", "Завышение ценности того, чем уже владеешь, по сравнению с тем, чем не владеешь", "high", "very_common"),
    ("Euler's identity bias", "Красота математического уравнения влияет на восприятие его истинности", "low", "rare"),
    ("Exponential growth bias", "Недооценка экспоненциального роста и сложных процентов", "high", "common"),
    ("Focusing effect", "Чрезмерный акцент на одной информации при оценке ситуации", "medium", "common"),
    ("Framing effect", "Влияние формулировки вопроса на восприятие и принятие решений", "high", "very_common"),
    ("Gambler's fallacy (probability)", "Вероятность прошлых событий влияет на оценку будущих", "high", "common"),
    ("Gaze aversion", "Избегание зрительного контакта при обработке сложной информации", "low", "common"),
    ("Google effect", "Забывание информации, которую можно легко найти в интернете", "medium", "common"),
    ("Grass is greener syndrome", "Вера, что другие варианты, места, отношения лучше текущих", "medium", "common"),
    ("Group attribution bias", "Приписывание личности всей группы поведению одного члена", "medium", "common"),
    ("Hard-easy effect", "Завышение результатов сложных задач, недооценка простых", "medium", "common"),
    ("Hindsight bias (advanced)", "Ретроспективное искажение — после события кажется, что оно было предсказуемым", "high", "very_common"),
    ("Hostile media effect", "Восприятие СМИ как предвзятых против своей группы или позиции", "medium", "common"),
    ("Hyperbolic discounting", "Предпочтение небольшого вознаграждения сейчас, чем большого позже", "high", "very_common"),
    ("Identifiable victim effect", "Большая эмпатия к конкретной жертве, чем к статистике множества", "medium", "common"),
    ("Impact bias", "Переоценка длительности и интенсивности эмоциональных реакций", "medium", "common"),
    ("Information bias", "Сбор избыточной информации, которая не влияет на качество решения", "medium", "common"),
    ("In-group bias", "Предпочтение и благосклонность к членам своей группы", "high", "very_common"),
    ("Inter-group bias", "Систематическое негативное отношение к представителям другой группы", "high", "common"),
    ("Irrational escalation", "Увеличение инвестиций в проигрышное дело из-за уже вложенных ресурсов", "high", "common"),
    ("Law of small numbers", "Вера в то, что малые выборки репрезентативны для генеральной совокупности", "medium", "common"),
    ("Less-is-more effect", "Предпочтение меньшего, но более релевантного набора", "low", "common"),
    ("Loss aversion", "Большая боль от потери, чем удовольствие от равного приобретения", "high", "very_common"),
    ("Mere exposure effect", "Повторное столкновение со стимулом порождает предпочтение", "medium", "very_common"),
    ("Money illusion", "Номинальная стоимость воспринимается важнее реальной purchasing power", "medium", "common"),
    ("Moral credential bias", "Прошлый моральный поступок подсознательно оправдывает будущий аморальный", "medium", "common"),
    ("Negativity bias", "Негативная информация имеет больший вес, чем позитивная", "high", "very_common"),
    ("Not Invented Here", "Отвержение идей и инноваций из-за их внешнего происхождения", "medium", "common"),
    ("Omission bias", "Предпочтение бездействия перед действием, даже если действие выгоднее", "medium", "common"),
    ("Optimism bias", "Завышение вероятности благоприятного исхода для себя", "high", "very_common"),
    ("Ostrich effect", "Сознательное игнорирование негативной информации о ситуации", "high", "common"),
    ("Outcome bias", "Оценка решения по его результату, а не по качеству процесса принятия", "high", "very_common"),
    ("Overconfidence effect", "Завышенная уверенность в точности своих знаний и суждений", "high", "very_common"),
    ("Pessimism bias", "Занижение вероятности благоприятного исхода для себя", "medium", "common"),
    ("Plan continuation bias", "Приоритет текущего плана перед новой, противоречащей информацией", "medium", "common"),
    ("Projection bias", "Проекция текущих чувств, ценностей и состояний на будущее и других людей", "medium", "common"),
    ("Pro-innovation bias", "Чрезмерный оптимизм к новым технологиям и идеям без учёта ограничений", "medium", "common"),
    ("Pseudocertainty effect", "Восприятие условной вероятности как безусловной", "low", "rare"),
    ("Reactance", "Сопротивление давлению на свободу выбора, даже когда давление обосновано", "medium", "common"),
    ("Reality tunnel", "Восприятие мира исключительно через призму собственных убеждений и опыта", "high", "common"),
    ("Recency bias", "Приоритет недавней информации над более ранней", "medium", "very_common"),
    ("Rhyme as reason", "Рифмованные аргументы кажутся более убедительными и истинными", "low", "common"),
    ("Risk compensation", "Чувство безопасности приводит к принятию больших рисков", "medium", "common"),
    ("Risk perception bias", "Искажённое субъективное восприятие объективных рисков", "high", "very_common"),
    ("Status quo bias", "Предпочтение текущего состояния изменениям даже в лучшую сторону", "high", "very_common"),
    ("Stereotyping", "Приписывание индивиду характеристик стереотипной группы", "high", "very_common"),
    ("Subadditivity effect", "Вероятность частных событий кажется больше, чем вероятность объединения", "low", "common"),
    ("Survivorship bias (advanced)", "Фокус на successes, игнорируя failures и промахи", "high", "very_common"),
    ("System justification", "Оправдание и поддержка существующей системы, даже если она несправедлива", "medium", "common"),
    ("Time-saving bias", "Переоценка времени, сэкономленного за счёт увеличения скорости", "low", "common"),
    ("Unit bias", "Восприятие одной стандартной порции как нормы потребления", "low", "common"),
    ("Uniqueness bias", "Вера в свою уникальность и непохожесть на других", "medium", "very_common"),
    ("Verbatim effect", "Запоминание сути лучше, чем точных формулировок и слов", "low", "common"),
    ("Zero-risk bias", "Предпочтение полного устранения одного риска вместо большего снижения двух", "medium", "common"),
    ("Zero-sum bias", "Восприятие ситуации как игры с нулевой суммой — чья-то выигрыш = чья-то потеря", "high", "very_common"),
    ("Online disinhibition effect", "Снижение сдержанности в онлайн-среде", "high", "common"),
    ("Automation bias", "Чрезмерное доверие к автоматическим системам", "medium", "common"),
    ("Authority bias", "Подчинение авторитетам без критической оценки", "high", "very_common"),
    ("Contrast effect", "Усиление восприятия за счёт контраста с предыдущим стимулом", "medium", "common"),
    ("Peak-end rule", "Оценка опыта по пиковому моменту и концовке", "medium", "common"),
    ("Planning fallacy", "Недооценка времени и ресурсов, необходимых для задачи", "high", "very_common"),
    ("Anchoring on irrelevant", "Якорение на заведомо нерелевантной информации", "medium", "common"),
]

error_data = [
    ("Ошибка подгонки", "Подгонка интерпретации данных и фактов под заранее сформированное заключение"),
    ("Ложная дихотомия", "Представление сложной ситуации как выбора между двумя вариантами, когда их больше"),
    ("Соломенное чучело", "Искажение позиции оппонента для более лёгкой атаки вместо работы с реальным аргументом"),
    ("Ad hominem", "Атака на личность оппонента вместо его аргументов и рассуждений"),
    ("Appeal to authority", "Аргумент к авторитету без обоснования экспертности в данной области"),
    ("Appeal to emotion", "Апелляция к эмоциям вместо логических аргументов для убеждения"),
    ("Appeal to nature", "Утверждение, что натуральное автоматически лучше искусственного"),
    ("Appeal to tradition", "Утверждение, что традиционное автоматически правильное"),
    ("Begging the question", "Заключение уже предполагается в предпосылке аргумента"),
    ("Black-or-white thinking", "Рассмотрение только двух极端 вариантов, когда есть промежуточные"),
    ("Burden of proof", "Перекладывание обязанности доказывать на того, кто оспаривает"),
    ("Cherry picking", "Избирательный выбор данных, подтверждающих позицию, с игнорированием остальных"),
    ("Causal oversimplification", "Упрощение причинно-следственных связей до одной причины"),
    ("Circular reasoning", "Доказательство утверждения через это же утверждение"),
    ("Composition fallacy", "Приписывание свойств частей целому объекту"),
    ("Confusion of necessary and sufficient", "Смешение необходимых и достаточных условий в логике"),
    ("Cum hoc ergo propter hoc", "Отождествление корреляции с каузацией"),
    ("Denying the antecedent", "Отрицание антецедента условного высказывания"),
    ("Dicto simpliciter", "Слепое обобщение без учёта исключений и контекста"),
    ("Discursive fallacy", "Использование стилистических уловок вместо содержательных аргументов"),
    ("Equivocation", "Использование термина в разных значениях в рамках одного аргумента"),
    ("Excluded middle fallacy", "Игнорирование третьего варианта в ложной дилемме"),
    ("Experiential fallacy", "Обобщение личного опыта на все ситуации"),
    ("False cause", "Установление ложной причинно-следственной связи между событиями"),
    ("False dilemma", "Представление ситуации как выбора между двумя альтернативами"),
    ("False equivalence", "Приравнивание не равноценных объектов, событий или аргументов"),
    ("Faulty analogy", "Построение некорректной или неуместной аналогии"),
    ("Genetic fallacy", "Оценка утверждения по его происхождению, а не по содержанию"),
    ("Half truth", "Использование частичной правды для введения в заблуждение"),
    ("Hedging fallacy", "Сознательный уход от прямого ответа через двусмысленности"),
    ("Hasty generalization", "Обобщение на основе недостаточного количества случаев"),
    ("Inner ring fallacy", "Вера в существование скрытых знаний, доступных избранным"),
    ("Intentional fallacy", "Определение смысла произведения по намерению автора"),
    ("Is-ought fallacy", "Вывод о том, как должно быть, из того, как есть"),
    ("Just-world fallacy", "Вера, что мир справедлив и каждый получает по заслугам"),
    ("Ludic fallacy", "Применение формализованных моделей из игр к хаотичной реальности"),
    ("Magical thinking", "Вера в магическую связь между мыслями и внешними событиями"),
    ("Modal fallacy", "Смешение的不同 модальностей в логическом рассуждении"),
    ("Morton's fork", "Дилемма, где оба варианта ведут к одному нежелательному результату"),
    ("Moving the goalposts", "Смена критериев успеха после их достижения"),
    ("Naturalistic fallacy", "Вывод о нормативности из описательности — естественное = хорошее"),
    ("Negative proof", "Принятие утверждения из-за отсутствия контраргументов"),
    ("No true Scotsman", "Изменение определения категории для исключения контрпримеров"),
    ("Non causa pro causa", "Указание неправильной причины явления"),
    ("Non sequitur", "Заключение не логически следует из предпосылок"),
    ("Nutshell fallacy", "Упрощение аргумента до потери его смысла"),
    ("One-sidedness", "Рассмотрение вопроса только с одной стороны"),
    ("Oversimplification", "Чрезмерное упрощение сложной проблемы"),
    ("Paradise lost fallacy", "Вера в утраченный идеальный порядок, который нужно восстановить"),
    ("Perfectionist fallacy", "Отвержение хорошего решения из-за его несовершенства"),
    ("Poisoning the well", "Предвзятость к собеседнику ещё до начала дискуссии"),
    ("Post hoc ergo propter hoc", "Вывод о причинности из хронологической последовательности"),
    ("Psychologist's fallacy", "Проекция собственных мыслей и мотивов на другого человека"),
    ("Questionable cause", "Предположение причинности без достаточных оснований"),
    ("Red herring", "Введение отвлекающего фактора для ухода от темы"),
    ("Reification", "Обращение с абстракцией как с конкретным объектом"),
    ("Relativist fallacy", "Отрицание объективных истин в пользу субъективизма"),
    ("Retreat to the impossible", "Уход к заведомо невозможным аргументам для защиты позиции"),
    ("Single cause fallacy", "Приписывание сложному явлению одной причины"),
    ("Slippery slope", "Утверждение, что малое действие неизбежно ведёт к крайним последствиям"),
    ("Special pleading", "Требование исключения из общих правил для себя"),
    ("Stolen concept", "Использование понятия для отрицания обоснованности этого понятия"),
    ("Straw man (advanced)", "Представление ослабленной версии аргумента оппонента"),
    ("Suppressed correlative", "Определение термина так, что альтернатива исключается"),
    ("Sweeping generalization", "Применение общего правила к исключению без учёта контекста"),
    ("Taboo fallacy", "Запрет на обсуждение определённых тем как аргумент"),
    ("Texas sharpshooter", "Подгонка теории под уже имеющиеся данные"),
    ("Truth by assertion", "Повторное утверждение без доказательств"),
    ("Two wrongs make a right", "Оправдание одного неправильного действия другим"),
    ("Unstated premise", "Использование неявной предпосылки, которую нельзя принять"),
    ("Weasel word", "Использование расплывчатых формулировок для избежания конкретики"),
    ("Wishful thinking", "Принятие утверждений желаемого за действительное"),
    ("Wrong direction fallacy", "Неправильное определение направления причинно-следственной связи"),
    ("Gambler's fallacy (error)", "Ожидаемое событие после серии противоположных исходов"),
    ("Genetic fallacy (advanced)", "Отвержение идеи из-за её источника"),
    ("Tone policing", "Критика тона вместо содержания аргумента"),
    ("Tu quoque", "Ответ обвинением в лицемерии вместо ответа на аргумент"),
    ("Whataboutism", "Переключение внимания на другую проблему"),
    ("False attribution", "Неправильное приписывание цитат или идей"),
    ("Anecdotal evidence", "Использование анекдотических свидетельств вместо данных"),
    ("Burden of proof reversal", "Перевёрнутая обязанность доказывания"),
    ("Nirvana fallacy", "Сравнение реальности с идеалом"),
    ("Ecological fallacy", "Выводы об индивиде на основе данных группы"),
    ("Simpson's paradox", "Тренд данных меняется при объединении подгрупп"),
    ("Base rate neglect", "Игнорирование базовой вероятности"),
    ("Confidence trick", "Использование ложной уверенности для манипуляции"),
    ("Dunning-Kruger error", "Неправильная самооценка компетентности"),
]

correction_data = [
    ("Мысленный эксперимент", "Создание гипотетических сценариев для проверки логики и последствий идей"),
    ("Альтернативная гипотеза", "Формулировка конкурирующих объяснений для каждого наблюдения"),
    ("Статистический анализ", "Применение статистических методов для проверки закономерностей"),
    ("Peer review", "Экспертиза и рецензирование равными специалистами"),
    ("Факт-чекинг", "Систематическая проверка фактов перед принятием решений"),
    ("Критическое мышление", "Анализ и оценка информации с применением логических стандартов"),
    ("Метод исключения", "Последовательное исключение вариантов на основе доказательств"),
    ("Обратное доказательство", "Сознательный поиск доказательств против собственной позиции"),
    ("Аргументация со справедливой стороны", "Лучшее представление позиции оппонента перед её критикой"),
    ("Контрольные вопросы", "Стандартизированный чек-лист для проверки качества решений"),
    ("Список контрольных точек", "Определённый перечень этапов проверки перед действием"),
    ("Байесовское обновление", "Обновление вероятностей убеждений на основе новых данных"),
    ("Калибровка уверенности", "Обучение соотнесению уровня уверенности с реальной точностью"),
    ("Декомпозиция проблемы", "Разбиение сложной задачи на простые, управляемые компоненты"),
    ("Структурированный анализ", "Системный подход с использованием формализованных методов"),
    ("Мозговой штурм", "Свободная генерация идей без критики для расширения пространства"),
    ("Devil's advocate", "Намеренная аргументация против доминирующей позиции"),
    ("6 шляп мышления", "Шесть перспектив анализа: факты, эмоции, критика, оптимизм, творчество, управление"),
    ("SWOT-анализ", "Оценка сильных и слабых сторон, возможностей и угроз"),
    ("Матрица решений", "Систематическая оценка вариантов по взвешенным критериям"),
    ("Агентный подход", "Анализ решения от имени третьего лица для снижения эмоциональности"),
    ("Ментальные модели", "Фреймворки и концепции для структурированного понимания мира"),
    ("First principles thinking", "Анализ проблемы с основополагающих принципов, без допущений"),
    ("Second-order thinking", "Мыслить на два шага вперёд, предвидя побочные эффекты"),
    ("Inversion thinking", "Решение проблемы наоборот — что нужно сделать, чтобы гарантированно проиграть"),
    ("Circle of competence", "Чёткое определение границ своих знаний и компетенций"),
    ("Margin of safety", "Добавление запаса прочности к планам и расчётам"),
    ("Pre-mortem analysis", "Анализ проекта до его начала, предсказывание причин провала"),
    ("After-action review", "Структурированный анализ результата после завершения"),
    ("Decision journal", "Систематическая запись решений и мотиваций для обучения"),
    ("Red team thinking", "Специальная команда, атакующая собственную стратегию"),
    ("Scenario planning", "Разработка и анализultiple сценариев развития событий"),
    ("Force field analysis", "Анализ сил, способствующих и препятствующих изменению"),
    ("Root cause analysis", "Систематический поиск корневой причины проблемы"),
    ("Five whys", "Цепочка из пяти вопросов «почему» для выявления корневой причины"),
    ("Ishikawa diagram", "Диаграмма «рыбий скелет» для визуализации причинно-следственных связей"),
    ("Pareto analysis", "Анализ по правилу 80/20 — фокус на жизненно важных few"),
    ("Cost-benefit analysis", "Систематическое сравнение затрат и выгод для каждого варианта"),
    ("Decision matrix", "Матрица для количественной оценки альтернатив"),
    ("Risk assessment", "Идентификация, оценка и приоритизация рисков"),
    ("Sensitivity analysis", "Анализ чувствительности результата к изменению входных параметров"),
    ("Expected value calculation", "Расчёт взвешенной средней стоимости исходов"),
    ("Regret minimization", "Выбор, минимизирующий потенциальные сожаления в будущем"),
    ("Second-order effects analysis", "Анализ косвенных и отложенных последствий"),
    ("Time horizon analysis", "Рассмотрение последствий на разных временных масштабах"),
    ("Outside view", "Взгляд со стороны, использование данных о аналогичных случаях"),
    ("Reference class forecasting", "Прогнозирование на основе статистики класса подобных проектов"),
    ("Pre-commitment", "Заранее данное обещание или правило для себя"),
    ("Implementation intentions", "Формулирование конкретных планов действий: если X, то Y"),
    ("Temptation bundling", "Связывание приятной деятельности с необходимой"),
    ("If-then planning", "Детальное планирование реакций на сценарии"),
    ("Accountability partner", "Назначение человека, контролирующего выполнение"),
    ("Track record analysis", "Анализ прошлых результатов для оценки будущих"),
    ("Calibration training", "Тренировка точности самооценки"),
    ("Probabilistic thinking", "Оценка вероятностей вместо категоричных утверждений"),
    ("Confidence intervals", "Определение диапазона достоверных значений"),
    ("Fermi estimation", "Приближённая оценка через разбиение на простые компоненты"),
    ("Order of magnitude", "Оценка порядка величины для быстрой проверки"),
    ("Fermi question", "Разбиение сложного вопроса на подсчитываемые части"),
    ("Lateral thinking", "Решение проблем нетривиальными, косвенными путями"),
    ("Reverse brainstorming", "Генерация идей наоборот — как ухудшить проблему"),
    ("Assumption busting", "Идентификация и сознательное разрушение скрытых допущений"),
    ("Random input", "Введение случайного стимула для генерации новых связей"),
    ("Provocation", "Сознательное нарушение правил для выхода за рамки"),
    ("Challenge assumptions", "Систематическая проверка всех принятых допущений"),
    ("Question everything", "Практика систематического сомнения"),
    ("Seek disconfirming evidence", "Активный поиск данных, опровергающих вашу гипотезу"),
    ("Steel-manning", "Укрепление аргумента оппонента до максимально сильной версии"),
    ("Charity principle", "Интерпретация позиции оппонента в наиболее разумном свете"),
    ("Bayesian updating", "Обновление убеждений по формуле Байеса"),
    ("Prior probability", "Оценка начальной вероятности до получения данных"),
    ("Likelihood ratio", "Отношение правдоподобий данных при двух гипотезах"),
    ("Posterior probability", "Обновлённая вероятность после учёта новых данных"),
    ("Expected utility", "Расчёт ожидаемой полезности для принятия решений"),
    ("Loss function", "Определение штрафа за различные типы ошибок"),
    ("Risk aversion accounting", "Учёт склонности к риску в принятии решений"),
    ("Prospect theory application", "Применение теории перспектив для анализа выбора"),
    ("Satisficing", "Выбор решения, удовлетворяющего минимальным критериям"),
    ("Optimizing", "Поиск наилучшего возможного решения"),
    ("Bounded rationality", "Учёт ограничений的认知ных ресурсов"),
    ("Ecological rationality", "Адаптация методов решения к среде"),
    ("Fast and frugal heuristics", "Использование простых, быстрых правил принятия решений"),
    ("Recognition heuristic", "Использование узнавания как критерия выбора"),
    ("Take the best heuristic", "Выбор по первому различающему критерию"),
    ("1/N heuristic", "Равное распределение ресурсов между вариантами"),
    ("Equally weighted model", "Модель с равными весами критериев"),
    ("Tallying", "Простой подсчёт баллов по критериям"),
    ("Natural sampling", "Оценка вероятностей на основе собственного опыта"),
]

# ============================================
# AMPLIFICATION CHAINS (Bias A amplifies Bias B)
# ============================================
amplification_chains = [
    # Chain 1: Confirmation -> Dunning-Kruger -> Overconfidence -> Reality tunnel
    (0, 8), (8, 13), (13, 61),
    # Chain 2: Loss aversion -> Status quo -> Endowment -> Omission
    (47, 65), (65, 24), (24, 54),
    # Chain 3: Bandwagon -> Group polarization -> In-group -> Stereotyping
    (15, 12), (12, 40), (40, 66),
    # Chain 4: Anchoring -> Framing -> Focusing -> Recency
    (4, 28), (28, 27), (27, 62),
    # Chain 5: Hindsight -> Outcome bias -> Just-world -> System justification
    (7, 56), (56, 65), (65, 67),
    # Chain 6: Negativity -> Availability cascade -> Risk perception -> Pessimism
    (49, 14), (14, 64), (64, 58),
    # Chain 7: Optimism -> Planning fallacy -> Overconfidence -> Sunk cost
    (55, 79), (79, 57), (57, 44),
    # Chain 8: Survivorship -> Clustering -> Confirmation -> Projection
    (2, 19), (19, 0), (0, 59),
    # Chain 9: Hyperbolic discounting -> Loss aversion -> Status quo -> Endowment
    (37, 47), (47, 65), (65, 24),
    # Chain 10: Stereotyping -> In-group bias -> Bandwagon -> Authority bias
    (66, 40), (40, 15), (15, 76),
    # Chain 11: Authority bias -> Confirmation -> Not Invented Here -> Pro-innovation
    (76, 0), (0, 50), (50, 60),
    # Chain 12: Projection -> False consensus -> Bias blind spot -> Dunning-Kruger
    (59, 33), (33, 16), (16, 8),
]

# ============================================
# ERROR CYCLES
# ============================================
error_cycles = [
    # Cycle 1: Cherry picking -> Confirmation -> Ad hominem -> Red herring
    (11, 0, 3, 47),  # Cherry picking -> Begging the question -> Ad hominem -> Red herring
    # Cycle 2: Straw man -> Ad hominem -> Appeal to emotion -> Red herring
    (64, 3, 5, 47),  # Straw man -> Ad hominem -> Appeal to emotion -> Red herring
    # Cycle 3: False dilemma -> Black-or-white -> Slippery slope -> Naturalistic fallacy
    (24, 9, 60, 42),  # False dilemma -> Black-or-white -> Slippery slope -> Naturalistic
    # Cycle 4: Circular reasoning -> Begging the question -> Equivocation -> Weasel word
    (13, 8, 20, 72),  # Circular -> Begging -> Equivocation -> Weasel
    # Cycle 5: Post hoc -> False cause -> Cum hoc -> Single cause
    (51, 23, 16, 59),  # Post hoc -> False cause -> Cum hoc -> Single cause
]

# ============================================
# GENERATE ALL FILES
# ============================================

all_biases = []
all_errors = []
all_corrections = []

# Helper to get link targets
def get_link_targets(idx, total, count=3, offset=1):
    return [(idx + offset + i) % total for i in range(count)]

# ---- Generate Bias Notes ----
for i, (name, desc, sev, freq) in enumerate(bias_data):
    all_biases.append(name)
    
    # Find amplification targets
    amp_targets = [t for s, t in amplification_chains if s == i]
    if len(amp_targets) < 2:
        amp_targets += get_link_targets(i, len(bias_data), 2, 5)
    amp_targets = amp_targets[:3]
    
    # Find what it's weakened by
    fix_targets = [j for j, c_name in enumerate(correction_data) 
                   if i in [t % len(bias_data) for t in range(len(correction_data)) 
                           if (t + j) % len(bias_data) == i]]
    weak_by = get_link_targets(i, len(correction_data), 2, 1)
    
    # Errors this bias generates
    error_targets = get_link_targets(i, len(error_data), 3, 2)
    
    # Related traps (other errors)
    trap_targets = get_link_targets(i, len(error_data), 2, 6)
    
    links_count = len(amp_targets) + len(weak_by) + len(error_targets) + len(trap_targets)
    # Ensure minimum 4 links
    while links_count < 4:
        extra = get_link_targets(i, len(bias_data), 1, links_count)
        amp_targets.extend(extra)
        links_count += 1
    
    content = f"""---
type: Bias
severity: {sev}
frequency: {freq}
tags:
  - bias
  - cognitive
---

# {name}

## Описание

{desc}

## Порождает ошибки
{chr(10).join(f'- [[{error_data[e][0]}]]' for e in error_targets[:3])}

## Усиливает
{chr(10).join(f'- [[{bias_data[t][0]}]]' for t in amp_targets[:3])}

## Ослабляется
{chr(10).join(f'- [[{correction_data[c][0]}]]' for c in weak_by[:2])}

## Ловушки связанные
{chr(10).join(f'- [[{error_data[t][0]}]]' for t in trap_targets[:2])}
"""
    
    fname = name.replace("/", "-").replace("\\", "-").replace(":", " -")
    fpath = os.path.join(BASE, "Biases", f"{fname}.md")
    with open(fpath, "w", encoding="utf-8") as f:
        f.write(content)

# ---- Generate Error Notes ----
for i, (name, desc) in enumerate(error_data):
    all_errors.append(name)
    
    # Leads to consequences (corrections needed)
    corr_targets = get_link_targets(i, len(correction_data), 3, 1)
    
    # Caused by biases
    bias_causes = get_link_targets(i, len(bias_data), 2, 3)
    
    # Related errors
    rel_errors = get_link_targets(i, len(error_data), 2, 5)
    
    # Corrections that help
    fix_corrs = get_link_targets(i, len(correction_data), 2, 7)
    
    # Check if this error is part of a cycle
    cycle_links = []
    for cycle in error_cycles:
        if i in cycle:
            cycle_pos = cycle.index(i)
            next_in_cycle = cycle[(cycle_pos + 1) % len(cycle)]
            if next_in_cycle < len(error_data):
                cycle_links.append(error_data[next_in_cycle][0])
    
    links_count = len(corr_targets) + len(bias_causes) + len(rel_errors) + len(fix_corrs)
    while links_count < 4:
        extra = get_link_targets(i, len(error_data), 1, links_count + i)
        rel_errors.extend(extra)
        links_count += 1
    
    cycle_section = ""
    if cycle_links:
        cycle_section = chr(10) + "## Циклы ошибок" + chr(10) + chr(10).join(f"- [[{c}]] → следствие в цикле" for c in cycle_links[:2])
    
    content = f"""---
type: Error
tags:
  - error
  - logical-fallacy
---

# {name}

## Описание

{desc}

## Порождает следствия
{chr(10).join(f'- [[{correction_data[c][0]}]]' for c in corr_targets[:3])}

## Вызывается искажениями
{chr(10).join(f'- [[{bias_data[b][0]}]]' for b in bias_causes[:2])}

## Связанные ошибки
{chr(10).join(f'- [[{error_data[e][0]}]]' for e in rel_errors[:2])}
{cycle_section}

## Как исправить
- [[Критическое мышление]]
- [[Seek disconfirming evidence]]
- [[{correction_data[fix_corrs[0]][0]}]]
"""
    
    fname = name.replace("/", "-").replace("\\", "-").replace(":", " -")
    fpath = os.path.join(BASE, "Errors", f"{fname}.md")
    with open(fpath, "w", encoding="utf-8") as f:
        f.write(content)

# ---- Generate Correction Notes ----
for i, (name, desc) in enumerate(correction_data):
    all_corrections.append(name)
    
    # Fixes biases (target 2-4)
    bias_fixes = get_link_targets(i, len(bias_data), 3, 0)
    
    # Related methods
    rel_methods = get_link_targets(i, len(correction_data), 2, 4)
    
    # Applies to errors
    error_fixes = get_link_targets(i, len(error_data), 2, 2)
    
    # How to use steps
    steps = f"""1. Определите проблему или искажение
2. Выберите метод «{name}»
3. Примените пошагово
4. Проверьте результат
5. Запишите выводы"""
    
    links_count = len(bias_fixes) + len(rel_methods) + len(error_fixes)
    while links_count < 4:
        extra = get_link_targets(i, len(correction_data), 1, links_count + 3)
        rel_methods.extend(extra)
        links_count += 1
    
    content = f"""---
type: Correction
tags:
  - correction
  - improvement
  - method
---

# {name}

## Описание

{desc}

## Исправляет искажения
{chr(10).join(f'- [[{bias_data[b][0]}]]' for b in bias_fixes[:3])}

## Связанные методы
{chr(10).join(f'- [[{correction_data[c][0]}]]' for c in rel_methods[:2])}

## Применяется к ошибкам
{chr(10).join(f'- [[{error_data[e][0]}]]' for e in error_fixes[:2])}

## Как использовать
{steps}
"""
    
    fname = name.replace("/", "-").replace("\\", "-").replace(":", " -")
    fpath = os.path.join(BASE, "Corrections", f"{fname}.md")
    with open(fpath, "w", encoding="utf-8") as f:
        f.write(content)

# ============================================
# SUMMARY
# ============================================
print(f"Vault created at: {BASE}")
print(f"Biases:   {len(all_biases)}")
print(f"Errors:   {len(all_errors)}")
print(f"Corrections: {len(all_corrections)}")
print(f"Total:    {len(all_biases) + len(all_errors) + len(all_corrections)}")
print(f"\nAmplification chains: {len(amplification_chains)}")
print(f"Error cycles: {len(error_cycles)}")
