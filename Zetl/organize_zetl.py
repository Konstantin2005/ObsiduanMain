#!/usr/bin/env python3
"""Организация Zetl vault — MOC, навигация, очистка"""
import os
import sys
from pathlib import Path

sys.stdout.reconfigure(encoding='utf-8')

BASE = Path(r"C:\obsidian\Main\Zetl")

# ─── Структура vault ────────────────────────────────────────────────────────

SECTIONS = {
    "Life": {
        "name": "Жизненная система",
        "emoji": "life",
        "desc": "Управление эмоциями, страхами, привычками, целями и навыками.",
        "dirs": ["Emotions", "Fears", "Habits", "Goals", "Skills", "Traits", "Desires", "Values"],
        "related": ["Quest", "Knowledge"],
    },
    "Quest": {
        "name": "Игровая система",
        "emoji": "quest",
        "desc": "Квесты, боссы, препятствия, награды — геймификация жизни.",
        "dirs": ["Quests", "Bosses", "Obstacles", "Rewards"],
        "related": ["Life", "Knowledge"],
    },
    "Knowledge": {
        "name": "База знаний",
        "emoji": "knowledge",
        "desc": "Концепции, теории, решения, проекты, рефлексии.",
        "dirs": ["Knowledge"],
        "related": ["Life", "Ideas"],
    },
    "Ideas": {
        "name": "Экосистема идей",
        "emoji": "ideas",
        "desc": "Рождение, мутирование и эволюция идей.",
        "dirs": ["IdeaEcosystem"],
        "related": ["Knowledge", "Values"],
    },
    "Values": {
        "name": "Теневая система ценностей",
        "emoji": "values",
        "desc": "Ценности и их тени, компромиссы, поведения.",
        "dirs": ["ShadowValueSystem"],
        "related": ["Life", "Knowledge"],
    },
    "Topics": {
        "name": "Тематические индексы",
        "emoji": "topics",
        "desc": "Программирование, сети, шахматы, языки.",
        "dirs": ["Index"],
        "related": ["Knowledge"],
    },
}

# ─── Вспомогательные функции ─────────────────────────────────────────────────

def count_files(directory):
    """Подсчёт .md файлов в директории"""
    if not directory.exists():
        return 0
    return len(list(directory.rglob("*.md")))

def list_files_flat(directory, limit=30):
    """Список файлов в директории (без рекурсии)"""
    if not directory.exists():
        return []
    files = [f.stem for f in directory.glob("*.md")]
    return sorted(files)[:limit]

def get_section_stats():
    """Получить статистику по секциям"""
    stats = {}
    for key, info in SECTIONS.items():
        total = 0
        details = {}
        for d in info["dirs"]:
            dirpath = BASE / d
            count = count_files(dirpath)
            total += count
            details[d] = count
        stats[key] = {"total": total, "details": details}
    return stats

# ─── Создание MOC для Life ──────────────────────────────────────────────────

def create_life_moc():
    lines = []
    lines.append("---")
    lines.append("type: MOC")
    lines.append('title: "Жизненная система"')
    lines.append("---")
    lines.append("")
    lines.append("# Жизненная система")
    lines.append("")
    lines.append("> Управление эмоциями, страхами, привычками, целями и навыками.")
    lines.append("")
    lines.append("---")
    lines.append("")

    # Emotions
    lines.append("## Эмоции")
    lines.append("")
    emotions_dir = BASE / "Emotions"
    if emotions_dir.exists():
        for f in sorted(emotions_dir.glob("*.md")):
            lines.append(f"- [[{f.stem}]]")
    lines.append("")

    # Fears
    lines.append("## Страхи")
    lines.append("")
    fears_dir = BASE / "Fears"
    if fears_dir.exists():
        for f in sorted(fears_dir.glob("*.md")):
            lines.append(f"- [[{f.stem}]]")
    lines.append("")

    # Habits
    lines.append("## Привычки")
    lines.append("")
    habits_dir = BASE / "Habits"
    if habits_dir.exists():
        for f in sorted(habits_dir.glob("*.md")):
            lines.append(f"- [[{f.stem}]]")
    lines.append("")

    # Goals
    lines.append("## Цели")
    lines.append("")
    goals_dir = BASE / "Goals"
    if goals_dir.exists():
        for f in sorted(goals_dir.glob("*.md")):
            lines.append(f"- [[{f.stem}]]")
    lines.append("")

    # Skills
    lines.append("## Навыки")
    lines.append("")
    skills_dir = BASE / "Skills"
    if skills_dir.exists():
        for f in sorted(skills_dir.glob("*.md")):
            lines.append(f"- [[{f.stem}]]")
    lines.append("")

    # Traits
    lines.append("## Черты характера")
    lines.append("")
    traits_dir = BASE / "Traits"
    if traits_dir.exists():
        for f in sorted(traits_dir.glob("*.md")):
            lines.append(f"- [[{f.stem}]]")
    lines.append("")

    # Desires
    lines.append("## Желания")
    lines.append("")
    desires_dir = BASE / "Desires"
    if desires_dir.exists():
        for f in sorted(desires_dir.glob("*.md")):
            lines.append(f"- [[{f.stem}]]")
    lines.append("")

    # Values
    lines.append("## Ценности")
    lines.append("")
    values_dir = BASE / "Values"
    if values_dir.exists():
        for f in sorted(values_dir.glob("*.md")):
            lines.append(f"- [[{f.stem}]]")
    lines.append("")

    lines.append("---")
    lines.append("")
    lines.append("## Связи")
    lines.append("")
    lines.append("- [[MOC - Игровая система]] — квесты на основе привычек и целей")
    lines.append("- [[MOC - База знаний]] — знания для развития навыков")
    lines.append("- [[MOC - Теневая система ценностей]] — тени ценностей")

    content = "\n".join(lines)
    with open(BASE / "MOC - Жизненная система.md", "w", encoding="utf-8") as f:
        f.write(content)
    print("[OK] Created MOC - Жизненная система")


# ─── Создание MOC для Quest ─────────────────────────────────────────────────

def create_quest_moc():
    lines = []
    lines.append("---")
    lines.append("type: MOC")
    lines.append('title: "Игровая система"')
    lines.append("---")
    lines.append("")
    lines.append("# Игровая система")
    lines.append("")
    lines.append("> Квесты, боссы, препятствия, награды — геймификация жизни.")
    lines.append("")
    lines.append("---")
    lines.append("")

    sections = [
        ("Квесты", "Quests"),
        ("Боссы", "Bosses"),
        ("Препятствия", "Obstacles"),
        ("Награды", "Rewards"),
    ]

    for title, dirname in sections:
        lines.append(f"## {title}")
        lines.append("")
        dirpath = BASE / dirname
        if dirpath.exists():
            for f in sorted(dirpath.glob("*.md")):
                lines.append(f"- [[{f.stem}]]")
        lines.append("")

    lines.append("---")
    lines.append("")
    lines.append("## Связи")
    lines.append("")
    lines.append("- [[MOC - Жизненная система]] — навыки и привычки для квестов")
    lines.append("- [[MOC - База знаний]] — знания для прохождения")
    lines.append("- [[MOC - Экосистема идей]] — идеи для новых квестов")

    content = "\n".join(lines)
    with open(BASE / "MOC - Игровая система.md", "w", encoding="utf-8") as f:
        f.write(content)
    print("[OK] Created MOC - Игровая система")


# ─── Создание MOC для Knowledge ─────────────────────────────────────────────

def create_knowledge_moc():
    lines = []
    lines.append("---")
    lines.append("type: MOC")
    lines.append('title: "База знаний"')
    lines.append("---")
    lines.append("")
    lines.append("# База знаний")
    lines.append("")
    lines.append("> Концепции, теории, решения, проекты, рефлексии.")
    lines.append("")
    lines.append("---")
    lines.append("")

    knowledge_dir = BASE / "Knowledge"
    if knowledge_dir.exists():
        for subdir in sorted(knowledge_dir.iterdir()):
            if subdir.is_dir() and not subdir.name.startswith('.'):
                count = count_files(subdir)
                if count > 0:
                    lines.append(f"## {subdir.name} ({count})")
                    lines.append("")
                    for f in sorted(subdir.glob("*.md"))[:15]:
                        lines.append(f"- [[{f.stem}]]")
                    if count > 15:
                        lines.append(f"- ...и ещё {count - 15}")
                    lines.append("")

    lines.append("---")
    lines.append("")
    lines.append("## Связи")
    lines.append("")
    lines.append("- [[MOC - Жизненная система]] — применение знаний")
    lines.append("- [[MOC - Игровая система]] — знания для квестов")
    lines.append("- [[MOC - Экосистема идей]] — эволюция знаний")
    lines.append("- [[MOC - Тематические индексы]] — тематическая навигация")

    content = "\n".join(lines)
    with open(BASE / "MOC - База знаний.md", "w", encoding="utf-8") as f:
        f.write(content)
    print("[OK] Created MOC - База знаний")


# ─── Создание MOC для Ideas ─────────────────────────────────────────────────

def create_ideas_moc():
    lines = []
    lines.append("---")
    lines.append("type: MOC")
    lines.append('title: "Экосистема идей"')
    lines.append("---")
    lines.append("")
    lines.append("# Экосистема идей")
    lines.append("")
    lines.append("> Рождение, мутирование и эволюция идей.")
    lines.append("")
    lines.append("---")
    lines.append("")

    idea_dir = BASE / "IdeaEcosystem"
    if idea_dir.exists():
        for subdir in sorted(idea_dir.iterdir()):
            if subdir.is_dir() and not subdir.name.startswith('.'):
                count = count_files(subdir)
                if count > 0:
                    lines.append(f"## {subdir.name} ({count})")
                    lines.append("")
                    for f in sorted(subdir.glob("*.md"))[:15]:
                        lines.append(f"- [[{f.stem}]]")
                    if count > 15:
                        lines.append(f"- ...и ещё {count - 15}")
                    lines.append("")

    lines.append("---")
    lines.append("")
    lines.append("## Связи")
    lines.append("")
    lines.append("- [[MOC - База знаний]] — идеи как основа знаний")
    lines.append("- [[MOC - Теневая система ценностей]] — эволюция ценностей")
    lines.append("- [[MOC - Игровая система]] — идеи для квестов")

    content = "\n".join(lines)
    with open(BASE / "MOC - Экосистема идей.md", "w", encoding="utf-8") as f:
        f.write(content)
    print("[OK] Created MOC - Экосистема идей")


# ─── Создание MOC для Values ────────────────────────────────────────────────

def create_values_moc():
    lines = []
    lines.append("---")
    lines.append("type: MOC")
    lines.append('title: "Теневая система ценностей"')
    lines.append("---")
    lines.append("")
    lines.append("# Теневая система ценностей")
    lines.append("")
    lines.append("> Ценности и их тени, компромиссы, поведения.")
    lines.append("")
    lines.append("---")
    lines.append("")

    sv_dir = BASE / "ShadowValueSystem"
    if sv_dir.exists():
        for subdir in sorted(sv_dir.iterdir()):
            if subdir.is_dir() and not subdir.name.startswith('.'):
                count = count_files(subdir)
                if count > 0:
                    lines.append(f"## {subdir.name} ({count})")
                    lines.append("")
                    for f in sorted(subdir.glob("*.md"))[:15]:
                        lines.append(f"- [[{f.stem}]]")
                    if count > 15:
                        lines.append(f"- ...и ещё {count - 15}")
                    lines.append("")

    lines.append("---")
    lines.append("")
    lines.append("## Связи")
    lines.append("")
    lines.append("- [[MOC - Жизненная система]] — ценности в жизни")
    lines.append("- [[MOC - Экосистема идей]] — эволюция ценностей")
    lines.append("- [[MOC - База знаний]] — этика в знаниях")

    content = "\n".join(lines)
    with open(BASE / "MOC - Теневая система ценностей.md", "w", encoding="utf-8") as f:
        f.write(content)
    print("[OK] Created MOC - Теневая система ценностей")


# ─── Создание MOC для Topics ────────────────────────────────────────────────

def create_topics_moc():
    lines = []
    lines.append("---")
    lines.append("type: MOC")
    lines.append('title: "Тематические индексы"')
    lines.append("---")
    lines.append("")
    lines.append("# Тематические индексы")
    lines.append("")
    lines.append("> Программирование, сети, шахматы, языки.")
    lines.append("")
    lines.append("---")
    lines.append("")

    index_dir = BASE / "Index"
    if index_dir.exists():
        for subdir in sorted(index_dir.iterdir()):
            if subdir.is_dir():
                count = count_files(subdir)
                if count > 0:
                    lines.append(f"## {subdir.name} ({count})")
                    lines.append("")
                    for f in sorted(subdir.glob("*.md"))[:15]:
                        lines.append(f"- [[{f.stem}]]")
                    if count > 15:
                        lines.append(f"- ...и ещё {count - 15}")
                    lines.append("")

    lines.append("---")
    lines.append("")
    lines.append("## Связи")
    lines.append("")
    lines.append("- [[MOC - База знаний]] — знания по темам")
    lines.append("- [[MOC - Игровая система]] — навыки программирования")

    content = "\n".join(lines)
    with open(BASE / "MOC - Тематические индексы.md", "w", encoding="utf-8") as f:
        f.write(content)
    print("[OK] Created MOC - Тематические индексы")


# ─── Создание главного MOC ──────────────────────────────────────────────────

def create_master_moc():
    stats = get_section_stats()

    lines = []
    lines.append("---")
    lines.append("type: MOC")
    lines.append('title: "Zetl"')
    lines.append("---")
    lines.append("")
    lines.append("# Zetl — Персональная система знаний")
    lines.append("")
    lines.append("> Жизнь, знания, ценности, игра — всё связано.")
    lines.append("")
    lines.append("---")
    lines.append("")

    # Секции
    lines.append("## Секции vault'а")
    lines.append("")
    lines.append("| Секция | Описание | Заметок |")
    lines.append("|--------|----------|---------|")

    for key, info in SECTIONS.items():
        s = stats[key]
        lines.append(f"| [[MOC - {info['name']}]] | {info['desc'][:50]}... | {s['total']} |")

    total = sum(s["total"] for s in stats.values())
    lines.append(f"| **ИТОГО** | | **{total}** |")
    lines.append("")

    # Навигация по темам
    lines.append("---")
    lines.append("")
    lines.append("## Навигация по темам")
    lines.append("")
    lines.append("| Хочу... | Куда идти |")
    lines.append("|---------|-----------|")
    lines.append("| Разобраться в эмоциях | [[MOC - Жизненная система]] → Эмоции |")
    lines.append("| Поставить цель | [[MOC - Жизненная система]] → Цели |")
    lines.append("| Развить навык | [[MOC - Жизненная система]] → Навыки |")
    lines.append("| Начать квест | [[MOC - Игровая система]] → Квесты |")
    lines.append("| Узнать что-то новое | [[MOC - База знаний]] → Concepts |")
    lines.append("| Понять ценности | [[MOC - Теневая система ценностей]] |")
    lines.append("| Найти идею | [[MOC - Экосистема идей]] |")
    lines.append("| Запрограммировать | [[MOC - Тематические индексы]] → Программирование |")
    lines.append("")

    # Связи между секциями
    lines.append("---")
    lines.append("")
    lines.append("## Как секции связаны")
    lines.append("")
    lines.append("```")
    lines.append("    Жизненная система")
    lines.append("    (эмоции, цели, навыки)")
    lines.append("         ↓↑")
    lines.append("    Игровая система")
    lines.append("    (квесты, боссы, награды)")
    lines.append("         ↓↑")
    lines.append("    База знаний")
    lines.append("    (концепции, проекты)")
    lines.append("         ↓↑")
    lines.append("    Экосистема идей + Теневая система ценностей")
    lines.append("```")
    lines.append("")

    # Быстрый доступ
    lines.append("---")
    lines.append("")
    lines.append("## Быстрый доступ")
    lines.append("")
    lines.append("- [[MOC - Жизненная система]] — эмоции, страхи, привычки, цели")
    lines.append("- [[MOC - Игровая система]] — квесты, боссы, награды")
    lines.append("- [[MOC - База знаний]] — концепции, решения, проекты")
    lines.append("- [[MOC - Экосистема идей]] — эволюция идей")
    lines.append("- [[MOC - Теневая система ценностей]] — ценности и тени")
    lines.append("- [[MOC - Тематические индексы]] — программирование, сети")
    lines.append("")

    # Инфраструктура
    lines.append("---")
    lines.append("")
    lines.append("## Инфраструктура")
    lines.append("")
    lines.append("- Templates/ — шаблоны заметок")
    lines.append("- Inbox/ — входящие заметки")
    lines.append("- Documentation/ — документация")
    lines.append("- Setengs/ — настройки")
    lines.append("")

    content = "\n".join(lines)
    with open(BASE / "MOC - Zetl.md", "w", encoding="utf-8") as f:
        f.write(content)
    print("[OK] Created MOC - Zetl (master)")


# ─── Создание навигационного хаба ───────────────────────────────────────────

def create_navigation():
    lines = []
    lines.append("---")
    lines.append("type: Navigation")
    lines.append('title: "Навигация"')
    lines.append("---")
    lines.append("")
    lines.append("# Навигация по Zetl")
    lines.append("")
    lines.append("---")
    lines.append("")

    # Быстрый доступ
    lines.append("## Быстрый доступ")
    lines.append("")
    lines.append("| Действие | Секция | Файл |")
    lines.append("|----------|--------|------|")
    lines.append("| Посмотреть эмоции | Жизнь | [[MOC - Жизненная система]] |")
    lines.append("| Начать квест | Игра | [[MOC - Игровая система]] |")
    lines.append("| Изучить концепцию | Знания | [[MOC - База знаний]] |")
    lines.append("| Найти идею | Идеи | [[MOC - Экосистема идей]] |")
    lines.append("| Понять ценность | Ценности | [[MOC - Теневая система ценностей]] |")
    lines.append("| Запрограммировать | Темы | [[MOC - Тематические индексы]] |")
    lines.append("")

    # Все MOC
    lines.append("---")
    lines.append("")
    lines.append("## Все MOC")
    lines.append("")
    lines.append("- [[MOC - Zetl]] — главный MOC")
    lines.append("- [[MOC - Жизненная система]]")
    lines.append("- [[MOC - Игровая система]]")
    lines.append("- [[MOC - База знаний]]")
    lines.append("- [[MOC - Экосистема идей]]")
    lines.append("- [[MOC - Теневая система ценностей]]")
    lines.append("- [[MOC - Тематические индексы]]")
    lines.append("")

    # Шаблоны
    lines.append("---")
    lines.append("")
    lines.append("## Шаблоны")
    lines.append("")
    lines.append("- [[Concept_Template]]")
    lines.append("- [[MOC_Template]]")
    lines.append("- [[Principle_Template]]")
    lines.append("- [[Project_Template]]")
    lines.append("- [[Topic_Template]]")
    lines.append("- [[Value_Template]]")
    lines.append("")

    content = "\n".join(lines)
    with open(BASE / "Navigation.md", "w", encoding="utf-8") as f:
        f.write(content)
    print("[OK] Created Navigation.md")


# ─── Очистка пустых файлов ──────────────────────────────────────────────────

def cleanup_empty_files():
    """Удаление пустых .md файлов"""
    removed = 0
    for md_file in BASE.rglob("*.md"):
        if md_file.stat().st_size == 0 and md_file.name != ".obsidian":
            # Не удаляем шаблоны и MOC
            if "Templates" in str(md_file) or "MOC" in md_file.name:
                continue
            md_file.unlink()
            removed += 1
    print(f"[OK] Removed {removed} empty files")


# ─── Main ─────────────────────────────────────────────────────────────────────

if __name__ == "__main__":
    print("=" * 60)
    print("ORGANIZING ZETL VAULT")
    print("=" * 60)

    print("\n[1/7] Creating section MOCs...")
    create_life_moc()
    create_quest_moc()
    create_knowledge_moc()
    create_ideas_moc()
    create_values_moc()
    create_topics_moc()

    print("\n[2/7] Creating master MOC...")
    create_master_moc()

    print("\n[3/7] Creating navigation...")
    create_navigation()

    print("\n[4/7] Cleaning up empty files...")
    cleanup_empty_files()

    # Статистика
    print("\n" + "=" * 60)
    stats = get_section_stats()
    total = 0
    for key, info in SECTIONS.items():
        s = stats[key]
        total += s["total"]
        print(f"  {info['name']}: {s['total']} files")
        for d, c in s["details"].items():
            if c > 0:
                print(f"    {d}/: {c}")
    print(f"  TOTAL: {total} files")
    print("=" * 60)
    print("[DONE] Organization complete!")
