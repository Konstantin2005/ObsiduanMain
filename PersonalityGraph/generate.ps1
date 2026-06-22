$vaultPath = $PSScriptRoot
$folders = @("Emotions", "Fears", "Desires", "Values", "Habits", "Traits", "Goals")
foreach ($folder in $folders) {
    $path = Join-Path $vaultPath $folder
    if (!(Test-Path $path)) { New-Item -ItemType Directory -Path $path -Force | Out-Null }
}

$emotions = @(
    @{name="Радость"; desc="Чувство удовлетворения и счастья"; intensity=8},
    @{name="Грусть"; desc="Тягостное чувство утраты или разочарования"; intensity=5},
    @{name="Гнев"; desc="Резко отрицательная эмоция вызванная угрозой"; intensity=9},
    @{name="Страх"; desc="Эмоция возникающая при реальной или воображаемой опасности"; intensity=8},
    @{name="Удивление"; desc="Эмоция вызванная неожиданным событием"; intensity=6},
    @{name="Отвращение"; desc="Глубокое неприятие чего-либо"; intensity=7},
    @{name="Презрение"; desc="Глубокое неуважение к кому-то или чему-то"; intensity=7},
    @{name="Гордость"; desc="Чувство собственного достоинства"; intensity=7},
    @{name="Стыд"; desc="Душевное переживание вызванное осознанием предосудительности поступков"; intensity=8},
    @{name="Вина"; desc="Ощущение вины за содеянное"; intensity=7},
    @{name="Зависть"; desc="Болезненное желание обладать тем что есть у другого"; intensity=6},
    @{name="Благодарность"; desc="Чувство признательности"; intensity=7},
    @{name="Надежда"; desc="Уверенность в возможности достижения цели"; intensity=7},
    @{name="Отчаяние"; desc="Полная потеря надежды"; intensity=9},
    @{name="Любовь"; desc="Глубокое чувство привязанности"; intensity=9},
    @{name="Ненависть"; desc="Интенсивная форма неприязни"; intensity=9},
    @{name="Тревога"; desc="Состояние беспокойства и опасений"; intensity=7},
    @{name="Спокойствие"; desc="Состояние внутренней гармонии"; intensity=4},
    @{name="Воодушевление"; desc="Состояние вдохновения и энтузиазма"; intensity=8},
    @{name="Усталость"; desc="Физическое или моральное истощение"; intensity=5},
    @{name="Фрустрация"; desc="Эмоция вызванная непреодолимыми препятствиями"; intensity=7},
    @{name="Удовлетворение"; desc="Чувство удовлетворённости достигнутым"; intensity=6},
    @{name="Одиночество"; desc="Ощущение уединённости и покинутости"; intensity=7},
    @{name="Близость"; desc="Чувство эмоциональной связи с кем-то"; intensity=7},
    @{name="Восторг"; desc="Восторженное восхищение"; intensity=8},
    @{name="Печаль"; desc="Глубокая грусть"; intensity=6},
    @{name="Тоска"; desc="Тяжёлое душевное состояние"; intensity=7},
    @{name="Облегчение"; desc="Ощущение избавления от тяжести"; intensity=6},
    @{name="Ужас"; desc="Сильнейший страх"; intensity=10},
    @{name="Паника"; desc="Внезапный неконтролируемый страх"; intensity=9}
)

$fears = @(
    @{name="Страх одиночества"; desc="Боязнь остаться одному без поддержки"; intensity=8},
    @{name="Страх неудачи"; desc="Боязнь не достичь поставленной цели"; intensity=7},
    @{name="Страх успеха"; desc="Боязнь ответственности при достижении успеха"; intensity=6},
    @{name="Страх смерти"; desc="Боязнь кончины и умирания"; intensity=9},
    @{name="Страх отвержения"; desc="Боязнь быть отвергнутым другими"; intensity=8},
    @{name="Страх критики"; desc="Боязнь негативной оценки"; intensity=7},
    @{name="Страх перемен"; desc="Боязнь неизвестности и перемен"; intensity=7},
    @{name="Страх потери контроля"; desc="Боязнь потери контроля над ситуацией"; intensity=8},
    @{name="Страх уязвимости"; desc="Боязнь показать свою слабость"; intensity=7},
    @{name="Страх близости"; desc="Боязнь эмоциональной близости"; intensity=7},
    @{name="Страх конфликта"; desc="Боязнь столкновений и ссор"; intensity=6},
    @{name="Страх банкротства"; desc="Боязнь финансового краха"; intensity=8},
    @{name="Страх болезни"; desc="Боязнь заболеть серьёзным заболеванием"; intensity=8},
    @{name="Страх старости"; desc="Боязнь утраты молодости"; intensity=6},
    @{name="Страх непонимания"; desc="Боязнь что вас не поймут"; intensity=7},
    @{name="Страх заброшенности"; desc="Боязнь быть покинутым"; intensity=8},
    @{name="Страх провала"; desc="Боязнь неудачи в важном деле"; intensity=7},
    @{name="Страх осуждения"; desc="Боязнь осуждения со стороны общества"; intensity=7},
    @{name="Страх потери"; desc="Боязнь потерять близких"; intensity=9},
    @{name="Страх будущего"; desc="Тревога перед неизвестным будущим"; intensity=7},
    @{name="Страх прошлого"; desc="Страх перед воспоминаниями о прошлом"; intensity=6},
    @{name="Страх неизвестности"; desc="Боязнь того что неизвестно"; intensity=7},
    @{name="Страх ответственности"; desc="Боязнь брать на себя ответственность"; intensity=7},
    @{name="Страх свободы"; desc="Боязнь неограниченной свободы"; intensity=6},
    @{name="Страх смерти близких"; desc="Боязнь потерять родных людей"; intensity=9}
)

$desires = @(
    @{name="Любовь"; desc="Желание быть любимым и любить"; priority=9},
    @{name="Признание"; desc="Желание быть признанным окружающими"; priority=8},
    @{name="Безопасность"; desc="Потребность в стабильности и защите"; priority=9},
    @{name="Свобода"; desc="Желание действовать без ограничений"; priority=8},
    @{name="Власть"; desc="Желание влиять на других"; priority=7},
    @{name="Знания"; desc="Стремление к познанию нового"; priority=7},
    @{name="Красота"; desc="Желание окружить себя прекрасным"; priority=6},
    @{name="Богатство"; desc="Стремление к материальному изобилию"; priority=7},
    @{name="Здоровье"; desc="Желание быть здоровым"; priority=9},
    @{name="Семья"; desc="Потребность в семье и домашнем очаге"; priority=9},
    @{name="Путешествия"; desc="Желание видеть мир"; priority=6},
    @{name="Творчество"; desc="Стремление к созданию нового"; priority=7},
    @{name="Справедливость"; desc="Желание справедливого порядка"; priority=7},
    @{name="Гармония"; desc="Стремление к внутреннему равновесию"; priority=8},
    @{name="Успех"; desc="Желание достичь значимых результатов"; priority=8},
    @{name="Влияние"; desc="Стремление оказывать воздействие"; priority=7},
    @{name="Уважение"; desc="Желание быть уважаемым"; priority=8},
    @{name="Комфорт"; desc="Потребность в удобстве"; priority=6},
    @{name="Приключения"; desc="Желание новых впечатлений"; priority=6},
    @{name="Понимание"; desc="Стремление быть понятым"; priority=7},
    @{name="Контроль"; desc="Желание контролировать свою жизнь"; priority=7},
    @{name="Принадлежность"; desc="Потребность быть частью группы"; priority=8},
    @{name="Рост"; desc="Стремление к личностному развитию"; priority=8},
    @{name="Духовность"; desc="Потребность в духовном развитии"; priority=6},
    @{name="Наследие"; desc="Желание оставить след в истории"; priority=6}
)

$values = @(
    @{name="Честность"; desc="Приверженность правде"; category="мораль"},
    @{name="Лояльность"; desc="Верность своим и чужим принципам"; category="мораль"},
    @{name="Свобода"; desc="Право на свободный выбор"; category="общество"},
    @{name="Справедливость"; desc="Равенство и справедливость"; category="общество"},
    @{name="Ответственность"; desc="Осознание последствий своих поступков"; category="мораль"},
    @{name="Уважение"; desc="Уважение к себе и другим"; category="мораль"},
    @{name="Трудолюбие"; desc="Ценность труда и трудовой этики"; category="работа"},
    @{name="Семья"; desc="Центральная ценность семьи"; category="семья"},
    @{name="Здоровье"; desc="Ценность физического и ментального здоровья"; category="здоровье"},
    @{name="Знания"; desc="Ценность образования и познания"; category="работа"},
    @{name="Красота"; desc="Ценность эстетики"; category="красота"},
    @{name="Традиции"; desc="Приверженность культурным традициям"; category="общество"},
    @{name="Инновации"; desc="Открытость к новому"; category="работа"},
    @{name="Коллективизм"; desc="Приоритет группы над личностью"; category="общество"},
    @{name="Индивидуализм"; desc="Приоритет личности"; category="общество"},
    @{name="Милосердие"; desc="Сострадание к страждущим"; category="мораль"},
    @{name="Сила"; desc="Ценность силы характера"; category="работа"},
    @{name="Терпение"; desc="Способность ждать и выдерживать"; category="мораль"},
    @{name="Решительность"; desc="Способность принимать решения"; category="работа"},
    @{name="Гибкость"; desc="Способность адаптироваться"; category="работа"},
    @{name="Дисциплина"; desc="Самоконтроль и организованность"; category="работа"},
    @{name="Креативность"; desc="Ценность творческого подхода"; category="работа"},
    @{name="Лидерство"; desc="Способность вести за собой"; category="работа"},
    @{name="Служение"; desc="Готовность служить другим"; category="мораль"},
    @{name="Благодарность"; desc="Умение быть благодарным"; category="мораль"},
    @{name="Смирение"; desc="Способность признавать ошибки"; category="мораль"},
    @{name="Амбициозность"; desc="Стремление к великим целям"; category="работа"},
    @{name="Осторожность"; desc="Взвешенный подход к действиям"; category="работа"},
    @{name="Риск"; desc="Готовность идти на риск"; category="работа"},
    @{name="Истина"; desc="Стремление к познанию истины"; category="мораль"}
)

$habits = @(
    @{name="Утренняя рутина"; desc="Систематическое выполнение утренних процедур"; frequency="ежедневно"; category="здоровье"},
    @{name="Медитация"; desc="Регулярная практика медитации"; frequency="ежедневно"; category="здоровье"},
    @{name="Чтение"; desc="Регулярное чтение книг"; frequency="ежедневно"; category="работа"},
    @{name="Спорт"; desc="Регулярные физические нагрузки"; frequency="3-5 раз в неделю"; category="здоровье"},
    @{name="Прокрастинация"; desc="Привычка откладывать дела на потом"; frequency="часто"; category="работа"},
    @{name="Перфекционизм"; desc="Стремление к совершенству во всём"; frequency="постоянно"; category="работа"},
    @{name="Откладывание"; desc="Привычка откладывать важные дела"; frequency="часто"; category="работа"},
    @{name="Раннее пробуждение"; desc="Привычка вставать рано утром"; frequency="ежедневно"; category="здоровье"},
    @{name="Поздний сон"; desc="Привычка ложиться поздно"; frequency="часто"; category="здоровье"},
    @{name="Здоровое питание"; desc="Следование принципам здорового питания"; frequency="ежедневно"; category="здоровье"},
    @{name="Фастфуд"; desc="Регулярное употребление фастфуда"; frequency="часто"; category="здоровье"},
    @{name="Курение"; desc="Регулярное курение"; frequency="ежедневно"; category="здоровье"},
    @{name="Алкоголь"; desc="Регулярное употребление алкоголя"; frequency="часто"; category="здоровье"},
    @{name="Журналирование"; desc="Ведение дневника"; frequency="ежедневно"; category="работа"},
    @{name="Планирование"; desc="Планирование дня и задач"; frequency="ежедневно"; category="работа"},
    @{name="Анализ"; desc="Анализ своих действий и решений"; frequency="ежедневно"; category="работа"},
    @{name="Ведение блога"; desc="Регулярное ведение блога"; frequency="2-3 раза в неделю"; category="работа"},
    @{name="Нетворкинг"; desc="Расширение круга общения"; frequency="еженедельно"; category="работа"},
    @{name="Самокритика"; desc="Частая самокритика"; frequency="постоянно"; category="здоровье"},
    @{name="Самоанализ"; desc="Анализ своих поступков и мотивов"; frequency="ежедневно"; category="здоровье"},
    @{name="Работа до ночи"; desc="Работа допоздна"; frequency="часто"; category="работа"},
    @{name="Прогулки"; desc="Регулярные прогулки на свежем воздухе"; frequency="ежедневно"; category="здоровье"},
    @{name="Музыка"; desc="Слушание или создание музыки"; frequency="ежедневно"; category="работа"},
    @{name="Творчество"; desc="Занятия творчеством"; frequency="3-5 раз в неделю"; category="работа"},
    @{name="Экономия"; desc="Систематическое откладывание денег"; frequency="ежедневно"; category="работа"},
    @{name="Транжирство"; desc="Беспорядочные траты"; frequency="часто"; category="работа"},
    @{name="Помощь другим"; desc="Регулярная помощь окружающим"; frequency="еженедельно"; category="мораль"},
    @{name="Избегание конфликтов"; desc="Избегание споров и конфликтов"; frequency="постоянно"; category="мораль"},
    @{name="Споры"; desc="Частые споры и дискуссии"; frequency="часто"; category="мораль"},
    @{name="Чтение книг"; desc="Регулярное чтение книг"; frequency="ежедневно"; category="работа"},
    @{name="Дыхательные практики"; desc="Дыхательные упражнения"; frequency="ежедневно"; category="здоровье"},
    @{name="Уборка"; desc="Регулярная уборка пространства"; frequency="еженедельно"; category="здоровье"},
    @{name="Общение с семьёй"; desc="Регулярное общение с родными"; frequency="ежедневно"; category="семья"},
    @{name="Волонтёрство"; desc="Добровольческая деятельность"; frequency="ежемесячно"; category="мораль"},
    @{name="Дневник благодарности"; desc="Запись того за что благодарен"; frequency="ежедневно"; category="здоровье"},
    @{name="Анализ финансов"; desc="Анализ расходов и доходов"; frequency="еженедельно"; category="работа"},
    @{name="Обучение"; desc="Самостоятельное изучение нового"; frequency="еженедельно"; category="работа"},
    @{name="Тайм-менеджмент"; desc="Управление временем и задачами"; frequency="ежедневно"; category="работа"},
    @{name="Отдых"; desc="Осознанный отдых и восстановление"; frequency="еженедельно"; category="здоровье"},
    @{name="Дискуссии"; desc="Участие в интеллектуальных дискуссиях"; frequency="еженедельно"; category="работа"}
)

$traits = @(
    @{name="Интроверсия"; desc="Сосредоточенность на внутреннем мире"; category="темперамент"},
    @{name="Экстраверсия"; desc="Направленность на внешний мир"; category="темперамент"},
    @{name="Эмоциональность"; desc="Высокая чувствительность к эмоциям"; category="темперамент"},
    @{name="Логичность"; desc="Предпочтение логического мышления"; category="мышление"},
    @{name="Креативность"; desc="Способность к нестандартному мышлению"; category="мышление"},
    @{name="Практичность"; desc="Прагматичный подход к жизни"; category="мышление"},
    @{name="Амбициозность"; desc="Стремление к высоким целям"; category="мотивация"},
    @{name="Спокойствие"; desc="Уравновешенность и внутренний покой"; category="темперамент"},
    @{name="Тревожность"; desc="Склонность к беспокойству"; category="темперамент"},
    @{name="Упрямство"; desc="Настойчивость в достижении целей"; category="характер"},
    @{name="Гибкость"; desc="Способность адаптироваться"; category="характер"},
    @{name="Добросовестность"; desc="Ответственное отношение к делу"; category="характер"},
    @{name="Импульсивность"; desc="Склонность действовать импульсивно"; category="темперамент"},
    @{name="Осторожность"; desc="Взвешенный подход к действиям"; category="характер"},
    @{name="Оптимизм"; desc="Позитивный взгляд на мир"; category="темперамент"},
    @{name="Пессимизм"; desc="Негативный взгляд на мир"; category="темперамент"},
    @{name="Эмпатия"; desc="Способность сопереживать другим"; category="характер"},
    @{name="Аналитичность"; desc="Способность к анализу"; category="мышление"},
    @{name="Наблюдательность"; desc="Внимание к деталям"; category="мышление"},
    @{name="Коммуникабельность"; desc="Способность к общению"; category="характер"},
    @{name="Замкнутость"; desc="Склонность к уединению"; category="темперамент"},
    @{name="Независимость"; desc="Самостоятельность в решениях"; category="характер"},
    @{name="Зависимость"; desc="Нужда в чужом одобрении"; category="характер"},
    @{name="Настойчивость"; desc="Способность доводить дело до конца"; category="характер"},
    @{name="Уступчивость"; desc="Склонность уступать другим"; category="характер"},
    @{name="Честность"; desc="Соблюдение правдивости"; category="мораль"},
    @{name="Дипломатичность"; desc="Способность находить компромиссы"; category="характер"},
    @{name="Надежность"; desc="Можно положиться"; category="характер"},
    @{name="Адаптивность"; desc="Способность приспосабливаться"; category="характер"},
    @{name="Лидерство"; desc="Способность вести за собой"; category="мотивация"}
)

$goals = @(
    @{name="Карьерный рост"; desc="Достичь высокой должности"; timeframe="5-10 лет"; category="работа"},
    @{name="Финансовая независимость"; desc="Обеспечить стабильный доход"; timeframe="10-20 лет"; category="работа"},
    @{name="Здоровье"; desc="Поддерживать отличное здоровье"; timeframe="постоянно"; category="здоровье"},
    @{name="Семья"; desc="Создать крепкую семью"; timeframe="5-15 лет"; category="семья"},
    @{name="Путешествия"; desc="Победать во всех уголках мира"; timeframe="постоянно"; category="путешествия"},
    @{name="Образование"; desc="Получить высшее образование"; timeframe="5-10 лет"; category="работа"},
    @{name="Творчество"; desc="Реализовать творческий потенциал"; timeframe="постоянно"; category="работа"},
    @{name="Духовность"; desc="Достичь духовного просветления"; timeframe="постоянно"; category="здоровье"},
    @{name="Влияние"; desc="Оказывать положительное влияние"; timeframe="постоянно"; category="работа"},
    @{name="Наследие"; desc="Оставить значимый след"; timeframe="жизнь"; category="работа"},
    @{name="Гармония"; desc="Достичь внутренней гармонии"; timeframe="постоянно"; category="здоровье"},
    @{name="Свобода времени"; desc="Иметь свободное время"; timeframe="5-10 лет"; category="работа"},
    @{name="Мастерство"; desc="Стать мастером в своём деле"; timeframe="10-20 лет"; category="работа"},
    @{name="Узнаваемость"; desc="Стать известным"; timeframe="5-15 лет"; category="работа"},
    @{name="Сообщество"; desc="Создать сообщество единомышленников"; timeframe="5-10 лет"; category="работа"},
    @{name="Дом"; desc="Иметь собственный дом"; timeframe="10-15 лет"; category="семья"},
    @{name="Книга"; desc="Написать и издать книгу"; timeframe="5-10 лет"; category="работа"},
    @{name="Марафон"; desc="Пробежать марафон"; timeframe="1-2 года"; category="здоровье"},
    @{name="Бизнес"; desc="Создать успешный бизнес"; timeframe="5-10 лет"; category="работа"},
    @{name="Инвестиции"; desc="Создать инвестиционный портфель"; timeframe="10-20 лет"; category="работа"},
    @{name="Пенсия"; desc="Обеспечить комфортную пенсию"; timeframe="30-40 лет"; category="работа"},
    @{name="Мудрость"; desc="Достичь мудрости"; timeframe="жизнь"; category="здоровье"},
    @{name="Гармония в отношениях"; desc="Построить гармоничные отношения"; timeframe="постоянно"; category="семья"},
    @{name="Самопознание"; desc="Глубоко понять себя"; timeframe="постоянно"; category="здоровье"},
    @{name="Помощь миру"; desc="Внести вклад в улучшение мира"; timeframe="жизнь"; category="мораль"},
    @{name="Экология"; desc="Вести экологичный образ жизни"; timeframe="постоянно"; category="здоровье"},
    @{name="Наука"; desc="Внести вклад в науку"; timeframe="жизнь"; category="работа"},
    @{name="Искусство"; desc="Создать значимые произведения искусства"; timeframe="жизнь"; category="работа"},
    @{name="Спорт"; desc="Достичь спортивных результатов"; timeframe="5-10 лет"; category="здоровье"},
    @{name="Медитация"; desc="Достичь глубокой медитативной практики"; timeframe="постоянно"; category="здоровье"}
)

$emotionFearLinks = @{
    "Радость" = @("Страх потери", "Страх одиночества");
    "Грусть" = @("Страх потери", "Страх заброшенности");
    "Гнев" = @("Страх отвержения", "Страх критики", "Страх потери контроля");
    "Страх" = @("Страх смерти", "Страх неизвестности", "Страх болезни");
    "Удивление" = @("Страх перемен", "Страх неизвестности");
    "Отвращение" = @("Страх болезни", "Страх отвержения");
    "Презрение" = @("Страх критики", "Страх осуждения");
    "Гордость" = @("Страх неудачи", "Страх успеха");
    "Стыд" = @("Страх осуждения", "Страх отвержения", "Страх критики");
    "Вина" = @("Страх потери", "Страх осуждения");
    "Зависть" = @("Страх неудачи", "Страх потери");
    "Благодарность" = @("Страх потери", "Страх одиночества");
    "Надежда" = @("Страх провала", "Страх будущего");
    "Отчаяние" = @("Страх смерти", "Страх потери", "Страх будущего");
    "Любовь" = @("Страх потери", "Страх близости", "Страх отвержения");
    "Ненависть" = @("Страх отвержения", "Страх конфликта");
    "Тревога" = @("Страх будущего", "Страх неизвестности", "Страх ответственности");
    "Спокойствие" = @("Страх перемен", "Страх свободы");
    "Воодушевление" = @("Страх провала", "Страх ответственности");
    "Усталость" = @("Страх старости", "Страх болезни");
    "Фрустрация" = @("Страх неудачи", "Страх потери контроля", "Страх провала");
    "Удовлетворение" = @("Страх успеха", "Страх ответственности");
    "Одиночество" = @("Страх одиночества", "Страх заброшенности", "Страх близости");
    "Близость" = @("Страх близости", "Страх потери");
    "Восторг" = @("Страх потери", "Страх успеха");
    "Печаль" = @("Страх потери", "Страх заброшенности", "Страх смерти");
    "Тоска" = @("Страх одиночества", "Страх заброшенности");
    "Облегчение" = @("Страх ответственности", "Страх перемен");
    "Ужас" = @("Страх смерти", "Страх болезни", "Страх потери контроля");
    "Паника" = @("Страх смерти", "Страх потери контроля", "Страх неизвестности")
}

$emotionDesireLinks = @{
    "Радость" = @("Любовь", "Признание");
    "Грусть" = @("Любовь", "Безопасность");
    "Гнев" = @("Справедливость", "Контроль");
    "Страх" = @("Безопасность", "Защита");
    "Удивление" = @("Знания", "Приключения");
    "Отвращение" = @("Гигиена", "Безопасность");
    "Презрение" = @("Успех", "Признание");
    "Гордость" = @("Признание", "Успех");
    "Стыд" = @("Признание", "Понимание");
    "Вина" = @("Прощение", "Понимание");
    "Зависть" = @("Успех", "Богатство");
    "Благодарность" = @("Семья", "Любовь");
    "Надежда" = @("Успех", "Гармония");
    "Отчаяние" = @("Безопасность", "Любовь");
    "Любовь" = @("Любовь", "Близость");
    "Ненависть" = @("Справедливость", "Контроль");
    "Тревога" = @("Безопасность", "Контроль");
    "Спокойствие" = @("Гармония", "Духовность");
    "Воодушевление" = @("Творчество", "Успех");
    "Усталость" = @("Отдых", "Комфорт");
    "Фрустрация" = @("Успех", "Контроль");
    "Удовлетворение" = @("Гармония", "Признание");
    "Одиночество" = @("Принадлежность", "Любовь");
    "Близость" = @("Любовь", "Принадлежность");
    "Восторг" = @("Приключения", "Путешествия");
    "Печаль" = @("Любовь", "Семья");
    "Тоска" = @("Свобода", "Путешествия");
    "Облегчение" = @("Безопасность", "Свобода");
    "Ужас" = @("Безопасность", "Защита");
    "Паника" = @("Безопасность", "Контроль")
}

$fearHabitLinks = @{}
foreach ($f in $fears) {
    $links = @()
    $allHabits = $habits | ForEach-Object { $_.name }
    $count = Get-Random -Minimum 3 -Maximum 5
    $selected = $allHabits | Get-Random -Count $count
    $fearHabitLinks[$f.name] = $selected
}

$habitTraitLinks = @{}
foreach ($h in $habits) {
    $links = @()
    $allTraits = $traits | ForEach-Object { $_.name }
    $count = Get-Random -Minimum 2 -Maximum 4
    $selected = $allTraits | Get-Random -Count $count
    $habitTraitLinks[$h.name] = $selected
}

$valueGoalLinks = @{}
foreach ($v in $values) {
    $links = @()
    $allGoals = $goals | ForEach-Object { $_.name }
    $count = Get-Random -Minimum 2 -Maximum 4
    $selected = $allGoals | Get-Random -Count $count
    $valueGoalLinks[$v.name] = $selected
}

$goalHabitLinks = @{}
foreach ($g in $goals) {
    $links = @()
    $allHabits = $habits | ForEach-Object { $_.name }
    $count = Get-Random -Minimum 2 -Maximum 4
    $selected = $allHabits | Get-Random -Count $count
    $goalHabitLinks[$g.name] = $selected
}

$counters = @{
    "Emotions" = 0
    "Fears" = 0
    "Desires" = 0
    "Values" = 0
    "Habits" = 0
    "Traits" = 0
    "Goals" = 0
}

function Create-Note {
    param(
        [string]$folder,
        [string]$name,
        [string]$type,
        [hashtable]$frontmatter,
        [string]$description,
        [string[]]$sections
    )
    
    $filePath = Join-Path $vaultPath $folder "$name.md"
    $fm = "---`n"
    foreach ($key in $frontmatter.Keys) {
        $fm += "$key`: $($frontmatter[$key])`n"
    }
    $fm += "---`n`n"
    $fm += "# $name`n`n"
    $fm += "## Описание`n$description`n`n"
    foreach ($section in $sections) {
        $fm += "$section`n`n"
    }
    
    Set-Content -Path $filePath -Value $fm -Encoding UTF8
    $counters[$folder]++
}

foreach ($e in $emotions) {
    $fm = @{
        type = "Emotion"
        intensity = $e.intensity
        tags = @("emotion", "personality")
    }
    
    $fearLinks = ""
    if ($emotionFearLinks.ContainsKey($e.name)) {
        $fearLinks = ($emotionFearLinks[$e.name] | ForEach-Object { "- [[$_]]" }) -join "`n"
    }
    
    $desireLinks = ""
    if ($emotionDesireLinks.ContainsKey($e.name)) {
        $desireLinks = ($emotionDesireLinks[$e.name] | ForEach-Object { "- [[$_]]" }) -join "`n"
    }
    
    $sections = @()
    if ($fearLinks) { $sections += "## Связанные страхи`n$fearLinks" }
    if ($desireLinks) { $sections += "## Связанные желания`n$desireLinks" }
    
    Create-Note -folder "Emotions" -name $e.name -type "Emotion" -frontmatter $fm -description $e.desc -sections $sections
}

foreach ($f in $fears) {
    $fm = @{
        type = "Fear"
        intensity = $f.intensity
        tags = @("fear", "personality")
    }
    
    $habitLinks = ($fearHabitLinks[$f.name] | ForEach-Object { "- [[$_]]" }) -join "`n"
    
    $relatedEmotions = $emotionFearLinks.GetEnumerator() | Where-Object { $_.Value -contains $f.name } | ForEach-Object { $_.Key }
    $emotionLinks = ($relatedEmotions | Select-Object -First 3 | ForEach-Object { "- [[$_]]" }) -join "`n"
    
    $relatedFears = $fears | Where-Object { $_.name -ne $f.name } | Get-Random -Count 2
    $fearLinks = ($relatedFears | ForEach-Object { "- [[$($_.name)]]" }) -join "`n"
    
    $sections = @(
        "## Порождает привычки`n$habitLinks",
        "## Связанные эмоции`n$emotionLinks",
        "## Связанные страхи`n$fearLinks"
    )
    
    Create-Note -folder "Fears" -name $f.name -type "Fear" -frontmatter $fm -description $f.desc -sections $sections
}

foreach ($d in $desires) {
    $fm = @{
        type = "Desire"
        priority = $d.priority
        tags = @("desire", "personality")
    }
    
    $emotionLinks = ""
    if ($emotionDesireLinks.ContainsKey($d.name)) {
        $emotionLinks = ($emotionDesireLinks[$d.name] | ForEach-Object { "- [[$_]]" }) -join "`n"
    } else {
        $relatedEmotions = $emotions | Get-Random -Count 2
        $emotionLinks = ($relatedEmotions | ForEach-Object { "- [[$($_.name)]]" }) -join "`n"
    }
    
    $relatedDesires = $desires | Where-Object { $_.name -ne $d.name } | Get-Random -Count 2
    $desireLinks = ($relatedDesires | ForEach-Object { "- [[$($_.name)]]" }) -join "`n"
    
    $sections = @(
        "## Связанные эмоции`n$emotionLinks",
        "## Связанные желания`n$desireLinks"
    )
    
    Create-Note -folder "Desires" -name $d.name -type "Desire" -frontmatter $fm -description $d.desc -sections $sections
}

foreach ($v in $values) {
    $fm = @{
        type = "Value"
        category = $v.category
        tags = @("value", "personality")
    }
    
    $goalLinks = ($valueGoalLinks[$v.name] | ForEach-Object { "- [[$_]]" }) -join "`n"
    
    $relatedValues = $values | Where-Object { $_.name -ne $v.name -and $_.category -eq $v.category } | Get-Random -Count 2
    $valueLinks = ($relatedValues | ForEach-Object { "- [[$($_.name)]]" }) -join "`n"
    
    $sections = @(
        "## Влияет на цели`n$goalLinks",
        "## Связанные ценности`n$valueLinks"
    )
    
    Create-Note -folder "Values" -name $v.name -type "Value" -frontmatter $fm -description $v.desc -sections $sections
}

foreach ($h in $habits) {
    $fm = @{
        type = "Habit"
        frequency = $h.frequency
        tags = @("habit", "personality")
    }
    
    $traitLinks = ($habitTraitLinks[$h.name] | ForEach-Object { "- [[$_]]" }) -join "`n"
    
    $relatedHabits = $habits | Where-Object { $_.name -ne $h.name -and $_.category -eq $h.category } | Get-Random -Count 2
    $habitLinks = ($relatedHabits | ForEach-Object { "- [[$($_.name)]]" }) -join "`n"
    
    $fearSources = $fearHabitLinks.GetEnumerator() | Where-Object { $_.Value -contains $h.name } | ForEach-Object { $_.Key }
    $fearLinks = ($fearSources | Select-Object -First 2 | ForEach-Object { "- [[$_]]" }) -join "`n"
    
    $sections = @(
        "## Связанные черты`n$traitLinks",
        "## Связанные привычки`n$habitLinks",
        "## Порождается страхами`n$fearLinks"
    )
    
    Create-Note -folder "Habits" -name $h.name -type "Habit" -frontmatter $fm -description $h.desc -sections $sections
}

foreach ($t in $traits) {
    $fm = @{
        type = "Trait"
        category = $t.category
        tags = @("trait", "personality")
    }
    
    $relatedTraits = $traits | Where-Object { $_.name -ne $t.name -and $_.category -eq $t.category } | Get-Random -Count 2
    $traitLinks = ($relatedTraits | ForEach-Object { "- [[$($_.name)]]" }) -join "`n"
    
    $habitSources = $habitTraitLinks.GetEnumerator() | Where-Object { $_.Value -contains $t.name } | ForEach-Object { $_.Key }
    $habitLinks = ($habitSources | Select-Object -First 3 | ForEach-Object { "- [[$_]]" }) -join "`n"
    
    $sections = @(
        "## Связанные черты`n$traitLinks",
        "## Проявляется в привычках`n$habitLinks"
    )
    
    Create-Note -folder "Traits" -name $t.name -type "Trait" -frontmatter $fm -description $t.desc -sections $sections
}

foreach ($g in $goals) {
    $fm = @{
        type = "Goal"
        timeframe = $g.timeframe
        tags = @("goal", "personality")
    }
    
    $habitLinks = ($goalHabitLinks[$g.name] | ForEach-Object { "- [[$_]]" }) -join "`n"
    
    $valueSources = $valueGoalLinks.GetEnumerator() | Where-Object { $_.Value -contains $g.name } | ForEach-Object { $_.Key }
    $valueLinks = ($valueSources | Select-Object -First 3 | ForEach-Object { "- [[$_]]" }) -join "`n"
    
    $relatedGoals = $goals | Where-Object { $_.name -ne $g.name -and $_.category -eq $g.category } | Get-Random -Count 2
    $goalLinks = ($relatedGoals | ForEach-Object { "- [[$($_.name)]]" }) -join "`n"
    
    $sections = @(
        "## Достигается через привычки`n$habitLinks",
        "## Поддерживается ценностями`n$valueLinks",
        "## Связанные цели`n$goalLinks"
    )
    
    Create-Note -folder "Goals" -name $g.name -type "Goal" -frontmatter $fm -description $g.desc -sections $sections
}

Write-Host "`n=== Personality Graph Generated ===" -ForegroundColor Green
Write-Host ""
Write-Host "Создано заметок по типам:" -ForegroundColor Cyan
Write-Host "  Emotions: $($counters['Emotions'])" -ForegroundColor Yellow
Write-Host "  Fears:    $($counters['Fears'])" -ForegroundColor Yellow
Write-Host "  Desires:  $($counters['Desires'])" -ForegroundColor Yellow
Write-Host "  Values:   $($counters['Values'])" -ForegroundColor Yellow
Write-Host "  Habits:   $($counters['Habits'])" -ForegroundColor Yellow
Write-Host "  Traits:   $($counters['Traits'])" -ForegroundColor Yellow
Write-Host "  Goals:    $($counters['Goals'])" -ForegroundColor Yellow
Write-Host ""
$total = $counters.Values | Measure-Object -Sum | Select-Object -ExpandProperty Sum
Write-Host "Всего: $total заметок" -ForegroundColor Green
Write-Host ""
Write-Host "Vault location: $vaultPath" -ForegroundColor Cyan
