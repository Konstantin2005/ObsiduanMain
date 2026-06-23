#!/usr/bin/env python3
"""
Генератор карты лабиринта для Obsidian.
Создаёт структуру директорий и markdown-файлов с frontmatter.
"""

import os
from pathlib import Path

BASE_DIR = Path(__file__).parent

CATEGORIES = {
    "Rooms": 40,
    "Doors": 30,
    "Keys": 20,
    "Traps": 25,
    "DeadEnds": 15,
    "Secrets": 20,
    "BossRooms": 10,
}

ROOM_NAMES = [
    "Тёмный коридор", "Зал с колоннами", "Комната зеркал", "Пыльная библиотека",
    "Кухня стража", "Спальня пленников", "Оружейная", "Сокровищница",
    "Тронный зал", "Подземелье", "Канализация", "Сворачивающийся тупик",
    "Зал с факелами", "Комната с решёткой", "Ледяная пещера", "Огненная яма",
    "Зал с песочными часами", "Комната с механизмами", "Скрытый проход", "Узкий лаз",
    "Комната с черепами", "Зал предков", "Арена", "Кузница",
    "Зельеварня", "Астрономическая башня", "Сад теней", "Ротонда",
    "Галерея статуй", "Комната с картой", "Тайник алхимика", "Зал с колоколами",
    "Комната голосов", "Зеркальный лабиринт", "Комната с книгами", "Древний храм",
    "Зал с витражами", "Комната с глобусом", "Склеп", "Королевские покои",
]

DOOR_NAMES = [
    "Железная дверь", "Дубовая дверь", "Кованая дверь", "Каменная дверь",
    "Дверь с замком", "Секретная дверь", "Дверь с решёткой", "Дверь с кольцом",
    "Дверь со щитом", "Дверь с черепом", "Дверь с ключевой дырой", "Двойная дверь",
    "Дверь-портик", "Дверь с барельефом", "Дверь с цепями", "Дверь с печатью",
    "Дверь с рунами", "Дверь с глазом", "Дверь с луной", "Дверь с звездой",
    "Дверь с молнией", "Дверь с пламенем", "Дверь с водой", "Дверь с ветром",
    "Дверь со змеёй", "Дверь с орлом", "Дверь с львом", "Дверь с драконом",
    "Дверь с фениксом", "Дверь с грифоном",
]

KEY_NAMES = [
    "Железный ключ", "Золотой ключ", "Костяной ключ", "Хрустальный ключ",
    "Ключ-зубец", "Ключ-пера", "Ключ-глаз", "Ключ-сердце",
    "Ключ-змея", "Ключ-молния", "Ключ-луна", "Ключ-звезда",
    "Ключ-пламя", "Ключ-вода", "Ключ-ветер", "Ключ-земля",
    "Ключ-тень", "Ключ-свет", "Ключ-кровь", "Ключ-душа",
]

TRAP_NAMES = [
    "Яма с шипами", "Падающий камень", "Сигнальная стрела", "Сетка проводов",
    "Кислотная ловушка", "Пламенная струя", "Ледяной пол", "Ядовитые иглы",
    "Подвижная стена", "Качающийся мост", "Раздвижной пол", "Секретный рычаг",
    "Запертая дверь", "Таймер бомбы", "Песчаная ловушка", "Магическая печать",
    "Невидимая стена", "Отравленная еда", "Взрывная ловушка", "Электрическая сеть",
    "Звуковая сигнализация", "Дымовая завеса", "Магнитная ловушка", "Скользкий пол",
    "Пружинный механизм",
]

DEADEND_NAMES = [
    "Тупик с паутиной", "Мёртвый колодец", "Заваленный выход", "Разрушенная стена",
    "Запечатанный проход", "Каменная глыба", "Провал в полу", "Сломанная лестница",
    "Засыпанный тоннель", "Обвал", "Упавшая колонна", "Затопленный коридор",
    "Замурованный проход", "Песчаная буря", "Обветренная галерея",
]

SECRET_NAMES = [
    "Древний свиток", "Карта сокровищ", "Пророчество", "Рецепт зелья",
    "Заклинание огня", "Кодекс воина", "Дневник алхимика", "Гримуар волшебника",
    "Тайный шифр", "Послание предков", "Ключ к загадке", "Карта лабиринта",
    "Запретный текст", "Записка шпиона", "Инструкция стража", "Рецепт яда",
    "Магическая формула", "Схема механизма", "Древний артефакт", "Проклятие",
]

BOSS_NAMES = [
    "Тёмный лорд", "Дракон огня", "Лич-король", "Демон бездны",
    "Тень предателя", "Голем камня", "Вампир-аристократ", "Некромант",
    "Демонический князь", "Древний страж",
]

BOSS_DESCRIPTIONS = [
    "Существование, окутанное тьмой. Его взгляд пронизывает душу.",
    "Огромная тварь с чешуёй, пылающей жаром.",
    "Нежить с короной из костей, повелевающий армией мертвецов.",
    "Зловещее создание из глубин преисподней.",
    "Тёмный двойник, знающий все твои слабости.",
    "Каменный великан, охраняющий древние тайны.",
    "Бессмертный аристократ, пьющий кровь.",
    "Повелитель мёртвых, плетущий нить судьбы.",
    "Властитель демонов, стремящийся к разрушению.",
    "Страж входа, испытывающий каждого путника.",
]

def create_directories():
    """Создаёт необходимые директории."""
    dirs = list(CATEGORIES.keys())
    dirs.append("MOC")
    for d in dirs:
        path = BASE_DIR / d
        path.mkdir(exist_ok=True)
    print(f"Созданы директории: {', '.join(dirs)}")

def frontmatter(type_: str) -> str:
    """Возвращает YAML frontmatter."""
    return f"---\ntype: {type_}\ntags: [labyrinth]\n---\n"

def generate_doors(n: int) -> list[dict]:
    """Генерирует двери и их связи с комнатами."""
    doors = []
    for i in range(n):
        name = DOOR_NAMES[i % len(DOOR_NAMES)]
        if i >= len(DOOR_NAMES):
            name += f" {i - len(DOOR_NAMES) + 2}"
        room_from = ROOM_NAMES[i % len(ROOM_NAMES)]
        room_to = ROOM_NAMES[(i + 1) % len(ROOM_NAMES)]
        key = KEY_NAMES[i % len(KEY_NAMES)]
        doors.append({
            "name": name,
            "room_from": room_from,
            "room_to": room_to,
            "key": key,
        })
    return doors

def generate_keys(n: int, doors: list[dict]) -> list[dict]:
    """Генерирует ключи и их привязку к дверям."""
    keys = []
    for i in range(n):
        name = KEY_NAMES[i]
        door = doors[i] if i < len(doors) else doors[0]
        keys.append({
            "name": name,
            "door": door["name"],
            "room": door["room_from"],
        })
    return keys

def generate_traps(n: int) -> list[dict]:
    """Генерирует ловушки и комнаты, в которых они находятся."""
    traps = []
    for i in range(n):
        name = TRAP_NAMES[i % len(TRAP_NAMES)]
        if i >= len(TRAP_NAMES):
            name += f" {i - len(TRAP_NAMES) + 2}"
        room = ROOM_NAMES[i % len(ROOM_NAMES)]
        traps.append({"name": name, "room": room})
    return traps

def generate_deadends(n: int) -> list[dict]:
    """Генерирует тупики и связанные с ними комнаты."""
    deadends = []
    for i in range(n):
        name = DEADEND_NAMES[i]
        room = ROOM_NAMES[i % len(ROOM_NAMES)]
        deadends.append({"name": name, "room": room})
    return deadends

def generate_secrets(n: int, deadends: list[dict]) -> list[dict]:
    """Генерирует секреты и их местоположение."""
    secrets = []
    for i in range(n):
        name = SECRET_NAMES[i]
        deadend = deadends[i % len(deadends)]
        secrets.append({"name": name, "deadend": deadend["name"]})
    return secrets

def generate_rooms(n: int, doors: list[dict], traps: list[dict]) -> list[dict]:
    """Генерирует комнаты со связями."""
    rooms = []
    for i in range(n):
        name = ROOM_NAMES[i]
        connected_doors = [d["name"] for d in doors if d["room_from"] == name or d["room_to"] == name]
        room_traps = [t["name"] for t in traps if t["room"] == name]
        rooms.append({
            "name": name,
            "connected_doors": connected_doors,
            "traps": room_traps,
        })
    return rooms

def write_file(category: str, filename: str, content: str):
    """Записывает файл в указанную категорию."""
    path = BASE_DIR / category / filename
    path.write_text(content, encoding="utf-8")

def main():
    create_directories()

    n_doors = CATEGORIES["Doors"]
    n_keys = CATEGORIES["Keys"]
    n_traps = CATEGORIES["Traps"]
    n_deadends = CATEGORIES["DeadEnds"]
    n_secrets = CATEGORIES["Secrets"]
    n_rooms = CATEGORIES["Rooms"]
    n_bosses = CATEGORIES["BossRooms"]

    doors = generate_doors(n_doors)
    keys = generate_keys(n_keys, doors)
    traps = generate_traps(n_traps)
    deadends = generate_deadends(n_deadends)
    secrets = generate_secrets(n_secrets, deadends)
    rooms = generate_rooms(n_rooms, doors, traps)

    # Запись дверей
    for door in doors:
        safe_name = door["name"].replace(" ", "_")
        content = (
            f"{frontmatter('door')}"
            f"# {door['name']}\n\n"
            f"Дверь, соединяющая комнаты **{door['room_from']}** и **{door['room_to']}**.\n\n"
            f"## Связи\n"
            f"- [[{door['room_from'].replace(' ', '_')}]]\n"
            f"- [[{door['room_to'].replace(' ', '_')}]]\n"
            f"- [[{door['key'].replace(' ', '_')}]]\n"
        )
        write_file("Doors", f"{safe_name}.md", content)

    # Запись ключей
    for key in keys:
        safe_name = key["name"].replace(" ", "_")
        content = (
            f"{frontmatter('key')}"
            f"# {key['name']}\n\n"
            f"Ключ, открывающий **{key['door']}**.\n\n"
            f"## Связи\n"
            f"- [[{key['door'].replace(' ', '_')}]]\n"
            f"- [[{key['room'].replace(' ', '_')}]]\n"
        )
        write_file("Keys", f"{safe_name}.md", content)

    # Запись ловушек
    for trap in traps:
        safe_name = trap["name"].replace(" ", "_")
        content = (
            f"{frontmatter('trap')}"
            f"# {trap['name']}\n\n"
            f"Ловушка в комнате **{trap['room']}**.\n\n"
            f"## Связи\n"
            f"- [[{trap['room'].replace(' ', '_')}]]\n"
        )
        write_file("Traps", f"{safe_name}.md", content)

    # Запись тупиков
    for deadend in deadends:
        safe_name = deadend["name"].replace(" ", "_")
        content = (
            f"{frontmatter('deadend')}"
            f"# {deadend['name']}\n\n"
            f"Тупик, ведущий из комнаты **{deadend['room']}**.\n\n"
            f"## Связи\n"
            f"- [[{deadend['room'].replace(' ', '_')}]]\n"
        )
        write_file("DeadEnds", f"{safe_name}.md", content)

    # Запись секретов
    for secret in secrets:
        safe_name = secret["name"].replace(" ", "_")
        content = (
            f"{frontmatter('secret')}"
            f"# {secret['name']}\n\n"
            f"Скрытое знание, найденное в тупике **{secret['deadend']}**.\n\n"
            f"## Связи\n"
            f"- [[{secret['deadend'].replace(' ', '_')}]]\n"
        )
        write_file("Secrets", f"{safe_name}.md", content)

    # Запись босс-комнат
    for i in range(n_bosses):
        name = BOSS_NAMES[i]
        desc = BOSS_DESCRIPTIONS[i]
        safe_name = name.replace(" ", "_")
        connected_room = ROOM_NAMES[i % len(ROOM_NAMES)]
        content = (
            f"{frontmatter('boss')}"
            f"# {name}\n\n"
            f"{desc}\n\n"
            f"Комната расположена рядом с **{connected_room}**.\n\n"
            f"## Связи\n"
            f"- [[{connected_room.replace(' ', '_')}]]\n"
        )
        write_file("BossRooms", f"{safe_name}.md", content)

    # Запись комнат
    for room in rooms:
        safe_name = room["name"].replace(" ", "_")
        connections = ""
        for d in room["connected_doors"]:
            connections += f"- [[{d.replace(' ', '_')}]]\n"
        traps_str = ""
        for t in room["traps"]:
            traps_str += f"- [[{t.replace(' ', '_')}]]\n"
        content = (
            f"{frontmatter('room')}"
            f"# {room['name']}\n\n"
            f"Описание комнаты: загадочное пространство с множеством проходов.\n\n"
            f"## Двери\n"
            f"{connections}\n"
            f"## Ловушки\n"
            f"{traps_str}\n"
        )
        write_file("Rooms", f"{safe_name}.md", content)

    # MOC LabyrinthGraph.md
    moc_labyrinth = (
        f"{frontmatter('moc')}"
        f"# Карта лабиринта\n\n"
        f"## Комнаты\n"
    )
    for room in rooms:
        moc_labyrinth += f"- [[{room['name'].replace(' ', '_')}]]\n"
    moc_labyrinth += "\n## Двери\n"
    for door in doors:
        moc_labyrinth += f"- [[{door['name'].replace(' ', '_')}]]\n"
    moc_labyrinth += "\n## Ключи\n"
    for key in keys:
        moc_labyrinth += f"- [[{key['name'].replace(' ', '_')}]]\n"
    moc_labyrinth += "\n## Ловушки\n"
    for trap in traps:
        moc_labyrinth += f"- [[{trap['name'].replace(' ', '_')}]]\n"
    moc_labyrinth += "\n## Тупики\n"
    for deadend in deadends:
        moc_labyrinth += f"- [[{deadend['name'].replace(' ', '_')}]]\n"
    moc_labyrinth += "\n## Секреты\n"
    for secret in secrets:
        moc_labyrinth += f"- [[{secret['name'].replace(' ', '_')}]]\n"
    moc_labyrinth += "\n## Боссы\n"
    for i in range(n_bosses):
        moc_labyrinth += f"- [[{BOSS_NAMES[i].replace(' ', '_')}]]\n"

    (BASE_DIR / "MOC").mkdir(exist_ok=True)
    (BASE_DIR / "MOC" / "LabyrinthGraph.md").write_text(moc_labyrinth, encoding="utf-8")

    # MOC Global.md
    moc_global = (
        f"{frontmatter('moc')}\n"
        f"# Глобальная карта\n\n"
        f"## Основные разделы\n"
        f"- [[LabyrinthGraph]]\n"
        f"- [[Navigation]]\n\n"
        f"## Статистика\n"
        f"- Комнат: {n_rooms}\n"
        f"- Дверей: {n_doors}\n"
        f"- Ключей: {n_keys}\n"
        f"- Ловушек: {n_traps}\n"
        f"- Тупиков: {n_deadends}\n"
        f"- Секретов: {n_secrets}\n"
        f"- Боссов: {n_bosses}\n"
    )
    (BASE_DIR / "MOC" / "Global.md").write_text(moc_global, encoding="utf-8")

    # Navigation.md
    nav = (
        f"{frontmatter('navigation')}\n"
        f"# Навигация по лабиринту\n\n"
        f"## Как пользоваться картой\n\n"
        f"1. Начните с любой комнаты\n"
        f"2. Следуйте по дверям, открывая их ключами\n"
        f"3. Остерегайтесь ловушек\n"
        f"4. Исследуйте тупики в поисках секретов\n"
        f"5. Доберитесь до босс-комнаты\n\n"
        f"## Порядок прохождения\n\n"
        f"### Начало\n"
        f"- [[{rooms[0]['name'].replace(' ', '_')}]]\n\n"
        f"### Середина\n"
        f"- [[{rooms[n_rooms // 2]['name'].replace(' ', '_')}]]\n\n"
        f"### Финал\n"
        f"- [[{BOSS_NAMES[0].replace(' ', '_')}]]\n"
    )
    (BASE_DIR / "Navigation.md").write_text(nav, encoding="utf-8")

    total = n_rooms + n_doors + n_keys + n_traps + n_deadends + n_secrets + n_bosses
    print(f"Генерация завершена. Создано {total} заметок.")

if __name__ == "__main__":
    main()
