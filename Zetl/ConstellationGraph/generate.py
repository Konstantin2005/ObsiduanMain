#!/usr/bin/env python3
"""Generate ConstellationGraph cosmic knowledge structure in Russian."""

import os
import random
from pathlib import Path

# Base directory
BASE_DIR = Path(__file__).parent

# Cosmic node types
TYPES = ["star", "constellation", "nebula", "blackhole", "galaxy", "wormhole"]

# Russian content
STARS = [
    ("Алгоритмы сортировки", "Исследование различных методов упорядочивания данных"),
    ("Рекурсия", "Техника самовызывающих функций для решения задач"),
    ("Структуры данных", "Способы организации и хранения информации в памяти"),
    ("Объектно-ориентированное программирование", "Парадигма, основанная на объектах и классах"),
    ("Функциональное программирование", "Парадигма, использующая чистые функции без побочных эффектов"),
    ("Базы данных", "Системы хранения, управления и извлечения данных"),
    ("Сети и протоколы", "Механизмы передачи данных между устройствами"),
    ("Искусственный интеллект", "Создание интеллектуальных систем, имитирующих человеческий разум"),
    ("Машинное обучение", "Методы обучения алгоритмов на основе данных"),
    ("Нейронные сети", "Модели, вдохновлённые структурой мозга"),
    ("Криптография", "Наука о шифровании и защите информации"),
    ("Безопасность систем", "Защита от несанкционированного доступа и атак"),
    ("Облачные вычисления", "Предоставление вычислительных ресурсов по сети"),
    ("Микросервисная архитектура", "Разбиение приложения на небольшие независимые сервисы"),
    ("Контейнеризация", "Изоляция приложений в контейнерах для переносимости"),
    ("Тестирование ПО", "Процесс проверки качества и корректности программ"),
    ("DevOps", "Культура автоматизации разработки и эксплуатации"),
    ("Версионный контроль", "Управление изменениями в коде и документации"),
    ("Паттерны проектирования", "Повторяемые решения типичных задач проектирования"),
    ("Рефакторинг", "Улучшение структуры кода без изменения его поведения"),
    ("Асинхронное программирование", "Обработка операций, не блокирующих основной поток"),
    ("Потоки и конкурентность", "Одновременное выполнение нескольких задач"),
    ("Графы и деревья", "Структуры данных для представления связей"),
    ("Поиск и навигация", "Алгоритмы нахождения путей в графах"),
    ("Оптимизация", "Улучшение производительности алгоритмов и систем"),
    ("Анализ сложности", "Оценка временной и пространственной эффективности"),
    ("Математика в программировании", "Линейная алгебра, дискретная математика, теория вероятностей"),
    ("Обработка изображений", "Алгоритмы изменения и анализа графических данных"),
    ("Работа с текстом", "Парсинг, генерация и обработка текстовой информации"),
    ("Графический интерфейс", "Проектирование пользовательских интерфейсов"),
    ("Мобильная разработка", "Создание приложений для смартфонов и планшетов"),
    ("Веб-разработка", "Разработка веб-приложений и сайтов"),
    ("Backend-разработка", "Серверная часть приложений и API"),
    ("Frontend-разработка", "Клиентская часть, взаимодействующая с пользователем"),
    ("Блокчейн", "Распределённая реестр технология"),
    ("IoT", "Интернет вещей и связанные устройства"),
    ("AR/VR", "Дополненная и виртуальная реальность"),
    ("Квантовые вычисления", "Вычисления на основе квантовых явлений"),
    ("Биоинформатика", "Применение вычислительных методов к биологическим данным"),
    ("Экосистемы и фреймворки", "Инструменты и платформы для разработки"),
    ("Мониторинг и логирование", "Наблюдение за состоянием систем"),
    ("Лицензирование и право", "Юридические аспекты использования ПО"),
    ("Документирование", "Создание и поддержка технической документации"),
    ("Менторство и обучение", "Передача знаний и развитие навыков"),
]

CONSTELLATIONS = [
    ("Алгоритмы", "Совокупность методов решения вычислительных задач"),
    ("Структуры данных и алгоритмы", "Фундаментальные основы компьютерных наук"),
    ("Программирование", "Процесс создания компьютерных программ"),
    ("Базы данных и хранилища", "Системы永久ного хранения информации"),
    ("Сетевые технологии", "Компоненты сетевой инфраструктуры"),
    ("Искусственный интеллект и данные", "Методы обработки и анализа данных"),
    ("Безопасность", "Комплекс мер по защите систем и данных"),
    ("Облачные технологии", "Сервисы и инфраструктура облака"),
    ("Микросервисы и контейнеры", "Сервисная архитектура и контейнеризация"),
    ("Тестирование и качество", "Обеспечение надёжности программных продуктов"),
    ("DevOps и автоматизация", "Инструменты и практики CI/CD"),
    ("Управление кодом", "Версионный контроль и совместная разработка"),
    ("Архитектурные решения", "Паттерны и подходы к проектированию"),
    ("Асинхронность и параллелизм", "Методы конкурентной обработки"),
    ("Графовые структуры", "Представление и обработка связей"),
    ("Математические основы", "Математический аппарат для программирования"),
    ("Обработка данных", "Текст, изображения и мультимедиа"),
    ("Пользовательские интерфейсы", "Проектирование взаимодействия с человеком"),
    ("Платформы разработки", "Среды и инструменты для создания ПО"),
    ("Блокчейн и децентрализация", "Технологии распределённых реестров"),
    ("Emerging Tech", "Перспективные и экспериментальные технологии"),
    ("Интеграция и экосистемы", "Взаимодействие компонентов и платформ"),
    ("Обучение и развитие", "Профессиональный рост в IT"),
    ("Производительность", "Оптимизация и профилирование систем"),
    ("Проектирование API", "Принципы создания интерфейсов взаимодействия"),
    ("Работа с файлами и потоками", "Ввод/вывод и обработка данных"),
    ("Криптография и безопасность", "Защита данных шифрованием"),
    ("Мониторинг систем", "Наблюдение и анализ состояния"),
]

NEBULAS = [
    ("Квантовое машинное обучение", "Применение квантовых вычислений к ML"),
    ("Нейроморфные чипы", "Аппаратные реализации, имитирующие нейроны"),
    ("Автономные системы", "Самоуправляемые роботы и транспорт"),
    ("Цифровые двойники", "Виртуальные копии физических объектов"),
    ("Edge computing", "Вычисления на периферии сети"),
    ("Web3", "Децентрализованные веб-протоколы"),
    ("Диффузионные модели", "Генерация данных методом диффузии"),
    ("LLM и генеративный ИИ", "Большие языковые модели и генерация контента"),
    ("Сторонние вычисления", "Децентрализованные вычислительные сети"),
    ("Квантовая криптография", "Защита на основе квантовых свойств"),
    ("Биоинженерия и ИИ", "Пересечение биологии и искусственного интеллекта"),
    ("Устойчивые вычисления", "Энергоэффективные и экологичные ИТ"),
    ("Космические вычисления", "Вычислительные системы для космоса"),
    ("Квантовые сети", "Передача данных с помощью квантовой запутанности"),
    ("Голограммы данных", "3D-визуализация и хранение информации"),
]

BLACKHOLES = [
    ("Legacy-системы", "Устаревшие технологии, требующие поддержки"),
    ("Технический долг", "Накопленные проблемы в коде, требующие решения"),
    ("Безопасность ядра", "Уязвимости на уровне операционной системы"),
    ("Распределённые блокировки", "Проблемы синхронизации в распределённых системах"),
    ("Энтропия кодовой базы", "Неизбежное ухудшение структуры кода со временем"),
    ("Масштабирование БД", "Проблемы производительности при росте данных"),
    ("Сетевые задержки", "Физические ограничения скорости передачи данных"),
    ("Обработка ошибок", "Сложность обработки исключений в распределённых системах"),
    ("Версионная совместимость", "Обратная совместимость и миграция данных"),
    ("Одновременный доступ", "Конфликты при параллельной записи данных"),
    ("Сбои оборудования", "Аппаратные отказы и восстановление"),
    ("Потеря данных", "Риск утраты информации при сбоях"),
]

GALAXIES = {
    "Computer Science": "Фундаментальные основы информатики",
    "Data Engineering": "Инженерия данных и ETL-процессы",
    "Software Engineering": "Инженерия программного обеспечения",
    "Network Engineering": "Проектирование и обслуживание сетей",
    "Cybersecurity": "Кибербезопасность и защита информации",
    "Cloud Computing": "Облачные вычисления и инфраструктура",
    "Artificial Intelligence": "Искусственный интеллект и его области",
    "Data Science": "Наука о данных и аналитика",
    "DevOps & SRE": "Эксплуатация и надёжность систем",
    "Frontend Engineering": "Клиентская разработка",
    "Backend Engineering": "Серверная разработка",
    "Mobile Development": "Разработка мобильных приложений",
    "Game Development": "Разработка компьютерных игр",
    "Embedded Systems": "Встраиваемые системы и IoT",
    "Blockchain & Web3": "Технологии блокчейна и децентрализации",
    "Quantum Computing": "Квантовые вычисления",
    "Bioinformatics": "Биоинформатика и вычислительная биология",
    "Robotics": "Робототехника и автоматизация",
    "AR/VR Engineering": "Инженерия дополненной и виртуальной реальности",
    "Systems Programming": "Системное программирование",
    "Compiler Design": "Проектирование компиляторов",
    "Operating Systems": "Операционные системы",
}

WORMHOLES = [
    ("AI <-> Data Science", "Связь между ИИ и наукой о данных"),
    ("Frontend <-> Backend", "Взаимодействие клиентской и серверной частей"),
    ("DevOps <-> Cloud", "Интеграция DevOps с облачными платформами"),
    ("Security <-> Networking", "Безопасность сетевых технологий"),
    ("Embedded <-> IoT", "Встраиваемые системы и интернет вещей"),
    ("Blockchain <-> Cryptography", "Блокчейн и криптографические методы"),
    ("Mobile <-> Frontend", "Мобильная разработка и пользовательские интерфейсы"),
    ("Robotics <-> AI", "Робототехника и искусственный интеллект"),
    ("AR/VR <-> Graphics", "Графические технологии для AR/VR"),
    ("Quantum <-> Crypto", "Квантовые методы в криптографии"),
    ("Systems <-> OS", "Системное программирование и ОС"),
    ("Bioinformatics <-> Data", "Биоинженерия и обработка данных"),
    ("Game Dev <-> Graphics", "Игровая разработка и графика"),
    ("Compiler <-> PL", "Компиляторы и языки программирования"),
]

# Track generated files for connections
generated = {
    "star": [],
    "constellation": [],
    "nebula": [],
    "blackhole": [],
    "galaxy": [],
    "wormhole": [],
}

# Mapping: constellation -> stars
CONSTELLATION_STARS = {
    "Алгоритмы": ["Алгоритмы сортировки", "Поиск и навигация", "Оптимизация", "Анализ сложности"],
    "Структуры данных и алгоритмы": ["Структуры данных", "Графы и деревья", "Алгоритмы сортировки", "Поиск и навигация"],
    "Программирование": ["Рекурсия", "Объектно-ориентированное программирование", "Функциональное программирование", "Асинхронное программирование"],
    "Базы данных и хранилища": ["Базы данных", "Облачные вычисления", "Оптимизация"],
    "Сетевые технологии": ["Сети и протоколы", "Безопасность систем", "Криптография"],
    "Искусственный интеллект и данные": ["Искусственный интеллект", "Машинное обучение", "Нейронные сети", "Обработка изображений", "Работа с текстом"],
    "Безопасность": ["Криптография", "Безопасность систем", "Тестирование ПО"],
    "Облачные технологии": ["Облачные вычисления", "Микросервисная архитектура", "Контейнеризация"],
    "Микросервисы и контейнеры": ["Микросервисная архитектура", "Контейнеризация", "Тестирование ПО"],
    "Тестирование и качество": ["Тестирование ПО", "Рефакторинг", "Паттерны проектирования"],
    "DevOps и автоматизация": ["DevOps", "Версионный контроль", "Мониторинг и логирование"],
    "Управление кодом": ["Версионный контроль", "Рефакторинг", "Паттерны проектирования"],
    "Архитектурные решения": ["Паттерны проектирования", "Микросервисная архитектура", "Экосистемы и фреймворки"],
    "Асинхронность и параллелизм": ["Асинхронное программирование", "Потоки и конкурентность"],
    "Графовые структуры": ["Графы и деревья", "Поиск и навигация", "Математика в программировании"],
    "Математические основы": ["Математика в программирования", "Анализ сложности", "Квантовые вычисления"],
    "Обработка данных": ["Обработка изображений", "Работа с текстом", "Базы данных"],
    "Пользовательские интерфейсы": ["Графический интерфейс", "Веб-разработка", "Мобильная разработка"],
    "Платформы разработки": ["Экосистемы и фреймворки", "Веб-разработка", "Backend-разработка", "Frontend-разработка"],
    "Блокчейн и децентрализация": ["Блокчейн", "Криптография", "Безопасность систем"],
    "Emerging Tech": ["Квантовые вычисления", "AR/VR", "IoT", "Биоинформатика"],
    "Интеграция и экосистемы": ["Экосистемы и фреймворки", "Микросервисная архитектура", "Облачные вычисления"],
    "Обучение и развитие": ["Менторство и обучение", "Документирование", "Тестирование ПО"],
    "Производительность": ["Оптимизация", "Анализ сложности", "Потоки и конкурентность"],
    "Проектирование API": ["Backend-разработка", "Микросервисная архитектура", "Сети и протоколы"],
    "Работа с файлами и потоками": ["Потоки и конкурентность", "Асинхронное программирование", "Базы данных"],
    "Криптография и безопасность": ["Криптография", "Безопасность систем", "Блокчейн"],
    "Мониторинг систем": ["Мониторинг и логирование", "DevOps", "Облачные вычисления"],
}

# Mapping: galaxy -> constellations
GALAXY_CONSTELLATIONS = {
    "Computer Science": ["Алгоритмы", "Структуры данных и алгоритмы", "Графовые структуры", "Математические основы"],
    "Data Engineering": ["Базы данных и хранилища", "Обработка данных", "Облачные технологии"],
    "Software Engineering": ["Программирование", "Тестирование и качество", "Архитектурные решения", "Управление кодом"],
    "Network Engineering": ["Сетевые технологии", "Безопасность", "Мониторинг систем"],
    "Cybersecurity": ["Безопасность", "Криптография и безопасность", "Сетевые технологии"],
    "Cloud Computing": ["Облачные технологии", "DevOps и автоматизация", "Микросервисы и контейнеры"],
    "Artificial Intelligence": ["Искусственный интеллект и данные", "Emerging Tech"],
    "Data Science": ["Искусственный интеллект и данные", "Обработка данных", "Математические основы"],
    "DevOps & SRE": ["DevOps и автоматизация", "Облачные технологии", "Мониторинг систем"],
    "Frontend Engineering": ["Пользовательские интерфейсы", "Платформы разработки"],
    "Backend Engineering": ["Платформы разработки", "Проектирование API", "Базы данных и хранилища"],
    "Mobile Development": ["Пользовательские интерфейсы", "Платформы разработки"],
    "Game Development": ["Пользовательские интерфейсы", "Обработка данных", "Графовые структуры"],
    "Embedded Systems": ["IoT", "Программирование", "Сетевые технологии"],
    "Blockchain & Web3": ["Блокчейн и децентрализация", "Криптография и безопасность"],
    "Quantum Computing": ["Emerging Tech", "Математические основы"],
    "Bioinformatics": ["Emerging Tech", "Обработка данных", "Математические основы"],
    "Robotics": ["Emerging Tech", "Искусственный интеллект и данные"],
    "AR/VR Engineering": ["Emerging Tech", "Пользовательские интерфейсы"],
    "Systems Programming": ["Программирование", "Архитектурные решения"],
    "Compiler Design": ["Программирование", "Математические основы"],
    "Operating Systems": ["Программирование", "Архитектурные решения", "Сетевые технологии"],
}

# Mapping: galaxy -> wormholes (bidirectional, stored as galaxy pairs)
GALAXY_WORMHOLES = {
    "Artificial Intelligence": ["AI <-> Data Science", "AI <-> Data Science", "Robotics <-> AI"],
    "Data Science": ["AI <-> Data Science", "Bioinformatics <-> Data"],
    "Frontend Engineering": ["Frontend <-> Backend", "Mobile <-> Frontend"],
    "Backend Engineering": ["Frontend <-> Backend", "Systems <-> OS"],
    "DevOps & SRE": ["DevOps <-> Cloud"],
    "Cloud Computing": ["DevOps <-> Cloud"],
    "Cybersecurity": ["Security <-> Networking", "Blockchain <-> Crypto"],
    "Network Engineering": ["Security <-> Networking"],
    "Mobile Development": ["Mobile <-> Frontend"],
    "Robotics": ["Robotics <-> AI"],
    "AR/VR Engineering": ["AR/VR <-> Graphics"],
    "Game Development": ["Game Dev <-> Graphics"],
    "Quantum Computing": ["Quantum <-> Crypto"],
    "Blockchain & Web3": ["Blockchain <-> Crypto"],
    "Embedded Systems": ["Embedded <-> IoT"],
    "Bioinformatics": ["Bioinformatics <-> Data"],
    "Compiler Design": ["Compiler <-> PL"],
    "Systems Programming": ["Systems <-> OS"],
    "Operating Systems": ["Systems <-> OS"],
    "Software Engineering": ["Frontend <-> Backend", "DevOps <-> Cloud"],
}


def ensure_dirs():
    """Create all subdirectories."""
    for d in ["Stars", "Constellations", "Nebulas", "BlackHoles", "Galaxies", "Wormholes"]:
        (BASE_DIR / d).mkdir(exist_ok=True)


def slug(title: str) -> str:
    """Sanitize title for filename."""
    return title.replace("/", "_").replace(" ", "_").replace("<->", "_")


def make_frontmatter(node_type: str, extra_tags: list[str] | None = None) -> str:
    """Generate YAML frontmatter."""
    tags = ["constellation"]
    if extra_tags:
        tags.extend(extra_tags)
    return f"---\ntype: {node_type}\ntags: [{', '.join(tags)}]\n---\n"


def write_file(directory: str, filename: str, content: str):
    """Write a markdown file."""
    path = BASE_DIR / directory / f"{filename}.md"
    path.write_text(content, encoding="utf-8")
    return filename


def generate_star(name: str, description: str, related: list[str]) -> str:
    """Generate a star note."""
    fm = make_frontmatter("star")
    links = "\n".join(f"- [[{r}]]" for r in related)
    return f"{fm}\n# {name}\n\n{description}\n\n## Связи\n\n{links}\n"


def generate_constellation(name: str, description: str, stars: list[str], galaxies: list[str]) -> str:
    """Generate a constellation note."""
    fm = make_frontmatter("constellation")
    star_links = "\n".join(f"- [[{s}]] (звезда)" for s in stars)
    galaxy_links = "\n".join(f"- [[{g}]] (галактика)" for g in galaxies)
    return (
        f"{fm}\n# {name}\n\n{description}\n\n"
        f"## Звёзды (части)\n\n{star_links}\n\n"
        f"## Галактика\n\n{galaxy_links}\n"
    )


def generate_nebula(name: str, description: str, related: list[str]) -> str:
    """Generate a nebula note."""
    fm = make_frontmatter("nebula", ["nebula", "emerging"])
    links = "\n".join(f"- [[{r}]]" for r in related)
    return f"{fm}\n# {name}\n\n{description}\n\n## Связанные области\n\n{links}\n"


def generate_blackhole(name: str, description: str, absorbs: list[str]) -> str:
    """Generate a black hole note."""
    fm = make_frontmatter("blackhole", ["blackhole", "sink"])
    links = "\n".join(f"- [[{a}]] (поглощает)" for a in absorbs)
    return f"{fm}\n# {name}\n\n{description}\n\n## Поглощает\n\n{links}\n"


def generate_galaxy(name: str, description: str, constellations: list[str], wormholes: list[str]) -> str:
    """Generate a galaxy note."""
    fm = make_frontmatter("galaxy", ["galaxy", "domain"])
    const_links = "\n".join(f"- [[{c}]] (созвездие)" for c in constellations)
    worm_links = "\n".join(f"- [[{w}]] (червоточина)" for w in wormholes)
    return (
        f"{fm}\n# {name}\n\n{description}\n\n"
        f"## Созвездия\n\n{const_links}\n\n"
        f"## Червоточины\n\n{worm_links}\n"
    )


def generate_wormhole(name: str, galaxies: list[str]) -> str:
    """Generate a wormhole note."""
    fm = make_frontmatter("wormhole", ["wormhole", "connection"])
    links = "\n".join(f"- [[{g}]] (галактика)" for g in galaxies)
    return f"{fm}\n# {name}\n\nДвунаправленная червоточина, соединяющая галактики.\n\n## Соединённые галактики\n\n{links}\n"


def generate_moc_constellation(stars: list[str], constellations: list[str], nebulas: list[str],
                               blackholes: list[str], galaxies: list[str], wormholes: list[str]) -> str:
    """Generate ConstellationGraph MOC."""
    fm = make_frontmatter("moc", ["moc", "index"])
    star_links = "\n".join(f"- [[{s}]]" for s in stars)
    const_links = "\n".join(f"- [[{c}]]" for c in constellations)
    neb_links = "\n".join(f"- [[{n}]]" for n in nebulas)
    bh_links = "\n".join(f"- [[{b}]]" for b in blackholes)
    gal_links = "\n".join(f"- [[{g}]]" for g in galaxies)
    worm_links = "\n".join(f"- [[{w}]]" for w in wormholes)
    return (
        f"{fm}\n# ConstellationGraph\n\nКарта космической структуры знаний.\n\n"
        f"## Звёзды ({len(stars)})\n\n{star_links}\n\n"
        f"## Созвездия ({len(constellations)})\n\n{const_links}\n\n"
        f"## Туманности ({len(nebulas)})\n\n{neb_links}\n\n"
        f"## Чёрные дыры ({len(blackholes)})\n\n{bh_links}\n\n"
        f"## Галактики ({len(galaxies)})\n\n{gal_links}\n\n"
        f"## Червоточины ({len(wormholes)})\n\n{worm_links}\n"
    )


def generate_moc_global(stars: list[str], constellations: list[str], nebulas: list[str],
                        blackholes: list[str], galaxies: list[str], wormholes: list[str]) -> str:
    """Generate Global MOC."""
    fm = make_frontmatter("moc", ["moc", "global"])
    total = len(stars) + len(constellations) + len(nebulas) + len(blackholes) + len(galaxies) + len(wormholes)
    return (
        f"{fm}\n# Глобальная карта знаний\n\nОбщее количество заметок: **{total}**\n\n"
        f"## По типам\n\n"
        f"- Звёзды: {len(stars)}\n"
        f"- Созвездия: {len(constellations)}\n"
        f"- Туманности: {len(nebulas)}\n"
        f"- Чёрные дыры: {len(blackholes)}\n"
        f"- Галактики: {len(galaxies)}\n"
        f"- Червоточины: {len(wormholes)}\n\n"
        f"## Навигация\n\n"
        f"- [[ConstellationGraph]] — основная карта\n"
        f"- [[Navigation]] — интерактивная навигация\n"
    )


def generate_navigation(stars: list[str], constellations: list[str], nebulas: list[str],
                        blackholes: list[str], galaxies: list[str], wormholes: list[str]) -> str:
    """Generate Navigation.md."""
    fm = make_frontmatter("moc", ["moc", "navigation"])
    return (
        f"{fm}\n# Навигация\n\n"
        f"## Быстрый доступ\n\n"
        f"### По галактикам\n\n"
        + "\n".join(f"#### {g}\n" + "\n".join(f"- [[{c}]]" for c in GALAXY_CONSTELLATIONS.get(g, []))
                     for g in galaxies) +
        f"\n\n## Связи между галактиками\n\n"
        + "\n".join(f"- [[{w}]]" for w in wormholes) +
        f"\n\n## Поисковые ссылки\n\n"
        f"- [[ConstellationGraph]]\n"
        f"- [[MOC Global]]\n"
    )


def main():
    random.seed(42)
    ensure_dirs()

    # 1) Generate stars (44 total)
    for name, desc in STARS:
        # Find related items: same constellation or random stars
        related = random.sample([n for n, _ in STARS if n != name], k=min(3, len(STARS) - 1))
        # Also link to its constellation if known
        for const_name, const_stars in CONSTELLATION_STARS.items():
            if name in const_stars:
                related.append(const_name)
                break
        content = generate_star(name, desc, related)
        fname = write_file("Stars", slug(name), content)
        generated["star"].append(fname)

    # 2) Generate constellations (28 total)
    for item in CONSTELLATIONS:
        if isinstance(item, tuple):
            name, desc = item
        else:
            name = item
            desc = f"Созвездие «{name}»"
        star_list = CONSTELLATION_STARS.get(name, [])
        # Find which galaxy this constellation belongs to
        galaxy_of = []
        for gname, gconsts in GALAXY_CONSTELLATIONS.items():
            if name in gconsts:
                galaxy_of.append(gname)
        content = generate_constellation(name, desc, star_list, galaxy_of)
        fname = write_file("Constellations", slug(name), content)
        generated["constellation"].append(fname)

    # 3) Generate nebulas (15 total)
    nebula_connections = {
        "Квантовое машинное обучение": ["Machine learning", "Quantum Computing"],
        "Нейроморфные чипы": ["Нейронные сети", "Embedded Systems"],
        "Автономные системы": ["IoT", "Robotics"],
        "Цифровые двойники": ["IoT", "Data Engineering"],
        "Edge computing": ["Cloud Computing", "IoT"],
        "Web3": ["Blockchain", "Distributed systems"],
        "Диффузионные модели": ["Machine Learning", "AI"],
        "LLM и генеративный ИИ": ["AI", "Machine Learning"],
        "Сторонние вычисления": ["Distributed Computing", "Blockchain"],
        "Квантовая криптография": ["Quantum Computing", "Cryptography"],
        "Биоинженерия и ИИ": ["AI", "Bioinformatics"],
        "Устойчивые вычисления": ["Green IT", "Cloud Computing"],
        "Космические вычисления": ["Space Tech", "IoT"],
        "Квантовые сети": ["Quantum Computing", "Networking"],
        "Голограммы данных": ["Data Visualization", "AR/VR"],
    }
    for name, desc in NEBULAS:
        rel = nebula_connections.get(name, random.sample([n for n, _ in STARS], k=3))
        content = generate_nebula(name, f"Перспективное направление: {desc}", rel)
        fname = write_file("Nebulas", slug(name), content)
        generated["nebula"].append(fname)

    # 4) Generate black holes (12 total)
    blackhole_absorbs = {
        "Legacy-системы": ["Программирование", "Управление кодом", "Тестирование и качество"],
        "Технический долг": ["Управление кодом", "Архитектурные решения", "Рефакторинг"],
        "Безопасность ядра": ["Безопасность", "Сетевые технологии", "Операционные системы"],
        "Распределённые блокировки": ["Асинхронность и параллелизм", "Базы данных и хранилища"],
        "Энтропия кодовой базы": ["Архитектурные решения", "Рефакторинг", "Тестирование и качество"],
        "Масштабирование БД": ["Базы данных и хранилища", "Облачные технологии"],
        "Сетевые задержки": ["Сетевые технологии", "Производительность"],
        "Обработка ошибок": ["Программирование", "Асинхронность и параллелизм"],
        "Версионная совместимость": ["Управление кодом", "DevOps и автоматизация"],
        "Одновременный доступ": ["Базы данных и хранилища", "Асинхронность и параллелизм"],
        "Сбои оборудования": ["Облачные технологии", "Мониторинг систем"],
        "Потеря данных": ["Базы данных и хранилища", "Безопасность"],
    }
    for name, desc in BLACKHOLES:
        absorbs = blackhole_absorbs.get(name, random.sample(CONSTELLATIONS, k=3))
        content = generate_blackhole(name, f"Зона знаний, поглощающая ресурсы: {desc}", absorbs)
        fname = write_file("BlackHoles", slug(name), content)
        generated["blackhole"].append(fname)

    # 5) Generate galaxies (22 total)
    for name, desc in GALAXIES.items():
        const_list = GALAXY_CONSTELLATIONS.get(name, [])
        worm_list = GALAXY_WORMHOLES.get(name, [])
        content = generate_galaxy(name, desc, const_list, worm_list)
        fname = write_file("Galaxies", slug(name), content)
        generated["galaxy"].append(fname)

    # 6) Generate wormholes (14 total)
    for item in WORMHOLES:
        if isinstance(item, tuple):
            name, desc = item
        else:
            name = item
            desc = f"Связь: {name}"
        # Extract galaxy names from the wormhole name (e.g., "AI <-> Data Science")
        parts = [p.strip() for p in name.split("<->")]
        # Find matching galaxy names
        galaxy_pair = []
        for gname in GALAXIES:
            for part in parts:
                if part.lower() in gname.lower() or gname.lower().startswith(part.lower()):
                    if gname not in galaxy_pair:
                        galaxy_pair.append(gname)
        # If we didn't find exactly 2, just pick first two galaxies
        if len(galaxy_pair) < 2:
            galaxy_pair = list(GALAXIES.keys())[:2]
        content = generate_wormhole(name, galaxy_pair[:2])
        fname = write_file("Wormholes", slug(name), content)
        generated["wormhole"].append(fname)

    # 7) Generate MOC files
    moc_const = generate_moc_constellation(
        generated["star"], generated["constellation"], generated["nebula"],
        generated["blackhole"], generated["galaxy"], generated["wormhole"]
    )
    write_file(".", "ConstellationGraph", moc_const)

    moc_global = generate_moc_global(
        generated["star"], generated["constellation"], generated["nebula"],
        generated["blackhole"], generated["galaxy"], generated["wormhole"]
    )
    write_file(".", "MOC Global", moc_global)

    nav = generate_navigation(
        generated["star"], generated["constellation"], generated["nebula"],
        generated["blackhole"], generated["galaxy"], generated["wormhole"]
    )
    write_file(".", "Navigation", nav)

    # Summary
    total = sum(len(v) for v in generated.values())
    print(f"ConstellationGraph сгенерирован: {total} космических заметок")
    for t, files in generated.items():
        print(f"   {t}: {len(files)}")
    print(f"   MOC файлов: 3")


if __name__ == "__main__":
    main()
