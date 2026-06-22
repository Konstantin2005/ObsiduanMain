#!/usr/bin/env python3
"""Создание MOC для графов QuestionFractal, PersonalityGraph, BiasGraph, IdeaEcosystem"""
import os
import sys
from pathlib import Path

sys.stdout.reconfigure(encoding='utf-8')

BASE = Path(r"C:\obsidian\Main\Zetl")

# ─── Данные графов ───────────────────────────────────────────────────────────

GRAPHS = {
    "QuestionFractal": {
        "title": "Question Fractal",
        "emoji": "?",
        "desc": "Исследовательский фрактал открытых вопросов. Каждый вопрос раскрывается на подвопросы, каждый ответ — на новые вопросы.",
        "purpose": "Моделировать пространство непознанного — вопросы без ответов.",
        "subdirs": {
            "Questions": "Открытые вопросы",
            "Insights": "Прозрения и озарения",
        },
        "related": ["PersonalityGraph", "BiasGraph", "Knowledge"],
    },
    "PersonalityGraph": {
        "title": "Personality Graph",
        "emoji": "brain",
        "desc": "Карта человеческой психики: эмоции, страхи, черты характера, привычки, навыки, ценности и желания.",
        "purpose": "Моделировать структуру личности и механизмы поведения.",
        "subdirs": {
            "Desires": "Желания и мотивации",
            "Emotions": "Эмоциональный спектр",
            "Fears": "Страхи и тревоги",
            "Goals": "Цели и стремления",
            "Habits": "Привычки и паттерны",
            "Traits": "Черты характера",
            "Values": "Личные ценности",
        },
        "related": ["QuestionFractal", "BiasGraph", "ShadowValueSystem"],
    },
    "BiasGraph": {
        "title": "Bias Graph",
        "emoji": "warning",
        "desc": "Когнитивные искажения, ошибки мышления и их коррекции. Как我们的 мозг обманывает нас.",
        "purpose": "Моделировать когнитивные искажения и методы борьбы с ними.",
        "subdirs": {
            "Biases": "Когнитивные искажения",
            "Corrections": "Методы коррекции",
            "Errors": "Ошибки мышления",
        },
        "related": ["QuestionFractal", "PersonalityGraph", "Knowledge"],
    },
    "IdeaEcosystem": {
        "title": "Idea Ecosystem",
        "emoji": "dna",
        "desc": "Экосистема идей: как идеи рождаются, мутируют, конкурируют и умирают. Меметика и культурная эволюция.",
        "purpose": "Моделировать эволюцию идей как биологический процесс.",
        "subdirs": {
            "Concepts": "Базовые концепции",
            "Counterideas": "Контр-идеи",
            "Ideas": "Идеи и гипотезы",
            "Memes": "Мемы и культурные единицы",
        },
        "related": ["QuestionFractal", "BiasGraph", "Knowledge"],
    },
}

# ─── Генерация MOC ───────────────────────────────────────────────────────────

def count_files(directory):
    if not directory.exists():
        return 0
    return len(list(directory.rglob("*.md")))

def list_files_flat(directory, limit=30):
    if not directory.exists():
        return []
    files = [f.stem for f in sorted(directory.glob("*.md"))]
    return files[:limit]

def create_moc(graph_name, info):
    graph_dir = BASE / graph_name
    moc_lines = []
    moc_lines.append("---")
    moc_lines.append("type: MOC")
    moc_lines.append(f'title: "{info["title"]}"')
    moc_lines.append("---")
    moc_lines.append("")
    moc_lines.append(f"# {info['emoji']} {info['title']}")
    moc_lines.append("")
    moc_lines.append(f"> {info['desc']}")
    moc_lines.append("")
    moc_lines.append(f"**Цель:** {info['purpose']}")
    moc_lines.append("")
    moc_lines.append("---")
    moc_lines.append("")

    # Подпапки
    total = 0
    for subdir, subdesc in info["subdirs"].items():
        dirpath = graph_dir / subdir
        count = count_files(dirpath)
        total += count
        moc_lines.append(f"## {subdir} ({count})")
        moc_lines.append(f"*{subdesc}*")
        moc_lines.append("")
        files = list_files_flat(dirpath)
        for f in files:
            moc_lines.append(f"- [[{f}]]")
        if count > 30:
            moc_lines.append(f"- ...и ещё {count - 30}")
        moc_lines.append("")

    # Статистика
    moc_lines.append("---")
    moc_lines.append("")
    moc_lines.append("## Статистика")
    moc_lines.append("")
    moc_lines.append(f"- **{total}** заметок")
    moc_lines.append(f"- **{len(info['subdirs'])}** подразделов")
    moc_lines.append("")

    # Связи с другими графами
    moc_lines.append("---")
    moc_lines.append("")
    moc_lines.append("## Связи с другими графами")
    moc_lines.append("")
    for rel in info["related"]:
        moc_lines.append(f"- [[MOC - {rel}]]")
    moc_lines.append("")

    content = "\n".join(moc_lines)
    with open(graph_dir / f"MOC - {info['title']}.md", "w", encoding="utf-8") as f:
        f.write(content)
    print(f"[OK] {graph_name}: MOC created ({total} files)")


def create_navigation(graph_name, info):
    graph_dir = BASE / graph_name
    nav_lines = []
    nav_lines.append("---")
    nav_lines.append("type: Navigation")
    nav_lines.append(f'title: "Навигация - {info["title"]}"')
    nav_lines.append("---")
    nav_lines.append("")
    nav_lines.append(f"# Навигация: {info['title']}")
    nav_lines.append("")
    nav_lines.append("---")
    nav_lines.append("")

    # Быстрый доступ
    nav_lines.append("## Быстрый доступ")
    nav_lines.append("")
    for subdir, subdesc in info["subdirs"].items():
        nav_lines.append(f"- **{subdir}** — {subdesc}")
    nav_lines.append("")

    # Все MOC
    nav_lines.append("---")
    nav_lines.append("")
    nav_lines.append("## Файлы")
    nav_lines.append("")
    nav_lines.append(f"- [[MOC - {info['title']}]]")
    for subdir in info["subdirs"]:
        nav_lines.append(f"- [[MOC - {subdir}]]")
    nav_lines.append("")

    content = "\n".join(nav_lines)
    with open(graph_dir / "Navigation.md", "w", encoding="utf-8") as f:
        f.write(content)
    print(f"[OK] {graph_name}: Navigation created")


def create_subdir_mocs(graph_name, info):
    graph_dir = BASE / graph_name
    for subdir, subdesc in info["subdirs"].items():
        dirpath = graph_dir / subdir
        if not dirpath.exists():
            continue
        files = list_files_flat(dirpath, limit=50)
        if not files:
            continue

        lines = []
        lines.append("---")
        lines.append("type: MOC")
        lines.append(f'title: "{subdir}"')
        lines.append("---")
        lines.append("")
        lines.append(f"# {subdir}")
        lines.append("")
        lines.append(f"> {subdesc}")
        lines.append("")
        lines.append("---")
        lines.append("")

        for f in files:
            lines.append(f"- [[{f}]]")

        lines.append("")
        lines.append("---")
        lines.append("")
        lines.append(f"← [[MOC - {info['title']}]]")

        content = "\n".join(lines)
        with open(dirpath / f"MOC - {subdir}.md", "w", encoding="utf-8") as f:
            pass  # Don't overwrite existing MOCs
        with open(dirpath / f"MOC - {subdir}.md", "w", encoding="utf-8") as f:
            f.write(content)
    print(f"[OK] {graph_name}: Sub-MOCs created")


# ─── Main ─────────────────────────────────────────────────────────────────────

if __name__ == "__main__":
    print("=" * 60)
    print("CREATING MOCS FOR ISSUES #41-44")
    print("=" * 60)

    for graph_name, info in GRAPHS.items():
        print(f"\n--- {graph_name} ---")
        create_moc(graph_name, info)
        create_navigation(graph_name, info)
        create_subdir_mocs(graph_name, info)

    print("\n" + "=" * 60)
    print("[DONE] All MOCs created!")
    print("=" * 60)
