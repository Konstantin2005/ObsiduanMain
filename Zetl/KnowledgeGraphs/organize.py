#!/usr/bin/env python3
"""Организация графов знаний — распределение контента, MOC, мосты"""
import os
import shutil
import sys
from pathlib import Path

sys.stdout.reconfigure(encoding='utf-8')

BASE = Path(r"C:\obsidian\Main")
ZETL = BASE / "Zetl"

# ─── Карта распределения ────────────────────────────────────────────────────
#источник_в_Zetl -> целевая_папка_графа

MOVE_MAP = {
    # 01-Gnosis (Знания)
    "Knowledge/Concepts":      "01-Gnosis/Concepts",
    "Knowledge/Fundamental":   "01-Gnosis/Fundamental",
    "Knowledge/Topics":        "01-Gnosis/Topics",
    "Knowledge/Principle":     "01-Gnosis/Principles",
    "Knowledge/Derived":       "01-Gnosis/Derived",

    # 02-Ethos (Ценности) — уже есть в ShadowValueSystem
    "Values":                  "02-Ethos/Values",
    "Knowledge/Values":        "02-Ethos/Values",

    # 03-Kairos (Решения)
    "Knowledge/Decisions":     "03-Kairos/Decisions",
    "Knowledge/Projects":      "03-Kairos/Projects",

    # 04-Psyche (Личность)
    "Emotions":                "04-Psyche/Emotions",
    "Fears":                   "04-Psyche/Fears",
    "Traits":                  "04-Psyche/Traits",
    "Habits":                  "04-Psyche/Habits",
    "Skills":                  "04-Psyche/Skills",
    "Goals":                   "04-Psyche/Goals",
    "Desires":                 "04-Psyche/Desires",

    # 05-Antinomy (Конфликты)
    "Knowledge/Reflections":   "05-Antinomy/Reflections",
    "Knowledge/Biases":        "05-Antinomy/Biases",

    # 06-Aporia (Вопросы) — создаём из Knowledge/Corrections + Errors
    "Knowledge/Corrections":   "06-Aporia/Corrections",
    "Knowledge/Errors":        "06-Aporia/Errors",

    # 07-Nexus (Причины)
    # Goals уже в Psyche, копируем для Nexus

    # 08-Quest (Жизнь как игра)
    "Quests":                  "08-Quest/Quests",
    "Bosses":                  "08-Quest/Bosses",
    "Obstacles":               "08-Quest/Obstacles",
    "Rewards":                 "08-Quest/Rewards",

    # 09-Meme (Эволюция идей)
    "IdeaEcosystem":           "09-Meme/IdeaEcosystem",

    # 10-Umbra (Тени) — уже в ShadowValueSystem
}

# ─── Структура графов ────────────────────────────────────────────────────────

GRAPHS = {
    "01-Gnosis": {
        "name": "GNOSIS",
        "emoji": "📚",
        "title": "Знания",
        "desc": "Сеть фактов, концепций и теорий. Каждый узел — знание, связанное с другими через отношения расширения, противоречия и порождения.",
        "purpose": "Моделировать структуру человеческого знания как живую сеть.",
        "types": ["Concept", "Theory", "Fact", "Domain", "Method"],
        "relations": ["extends", "contradicts", "based_on", "applies_to", "emerges_from"],
        "shape": "Сеть (web) — плотно связанный кластер с центрами притяжения.",
        "role": "Фундамент. Все остальные графы ссылаются на GNOSIS как на источник знаний.",
        "subdirs": ["Concepts", "Fundamental", "Topics", "Principles", "Derived", "Theories", "Methods"],
    },
    "02-Ethos": {
        "name": "ETHOS",
        "emoji": "⚖️",
        "title": "Ценности",
        "desc": "Двойная структура ценностей и их теней. Каждая ценность имеет обратную сторону, усиливающуюся при чрезмерном применении.",
        "purpose": "Моделировать диалектику ценностей — как добродетели превращаются в пороки.",
        "types": ["Value", "Shadow", "Tradeoff", "Behavior"],
        "relations": ["manifests_as", "transforms_into", "conflicts_with", "balances"],
        "shape": "Двойная спираль — ценности и тени, закрученные вокруг друг друга.",
        "role": "Этический слой. Связывает знания с психологией и поведением.",
        "subdirs": ["Values", "Shadows", "Tradeoffs", "Behaviors"],
    },
    "03-Kairos": {
        "name": "KAIROS",
        "emoji": "🎯",
        "title": "Решения",
        "desc": "Деревья решений с последствиями. Каждое решение ведёт к ветвлению исходов.",
        "purpose": "Моделировать процесс принятия решений и их каскадные последствия.",
        "types": ["Decision", "Consequence", "Scenario", "Criterion", "Outcome"],
        "relations": ["leads_to", "evaluated_by", "depends_on", "contradicts", "resolves"],
        "shape": "Дерево с циклами — решения ветвятся, последствия возвращаются к исходным точкам.",
        "role": "Практический слой. Превращает знания и ценности в действия.",
        "subdirs": ["Decisions", "Consequences", "Scenarios", "Criteria", "Outcomes", "Projects"],
    },
    "04-Psyche": {
        "name": "PSYCHE",
        "emoji": "🧠",
        "title": "Личность",
        "desc": "Архетипы, черты характера, паттерны поведения и защитные механизмы. Карта человеческой психики.",
        "purpose": "Моделировать структуру личности и механизмы поведения.",
        "types": ["Trait", "Archetype", "Pattern", "Mechanism", "Disorder"],
        "relations": ["expresses", "compensates", "conflicts_with", "evolves_into", "manifests_as"],
        "shape": "Созвездие — группы черт формируют «зори» личности.",
        "role": "Психологический слой. Объясняет, почему решения принимаются определённым образом.",
        "subdirs": ["Emotions", "Fears", "Traits", "Habits", "Skills", "Goals", "Desires", "Archetypes"],
    },
    "05-Antinomy": {
        "name": "ANTINOMY",
        "emoji": "⚡",
        "title": "Конфликты",
        "desc": "Парадоксы, дилеммы, tradeoffs и неразрешимые противоречия. Место, где истины сталкиваются.",
        "purpose": "Моделировать фундаментальные противоречия, которые невозможно разрешить.",
        "types": ["Paradox", "Dilemma", "Tradeoff", "Resolution", "Tension"],
        "relations": ["contradicts", "deepens", "emerges_from", "transforms_into", "parallels"],
        "shape": "Конфликтная сеть — узлы-противоречия, связанные напряжениями.",
        "role": "Диалектический слой. Показывает глубокие противоречия за простыми ответами.",
        "subdirs": ["Paradoxes", "Dilemmas", "Tradeoffs", "Resolutions", "Tensions", "Reflections", "Biases"],
    },
    "06-Aporia": {
        "name": "APORIA",
        "emoji": "❓",
        "title": "Вопросы",
        "desc": "Открытые вопросы, гипотезы, фронтиры знания. Место, где заканчивается известное.",
        "purpose": "Моделировать пространство непознанного — вопросы без ответов.",
        "types": ["Question", "Hypothesis", "Method", "Discovery", "Frontier"],
        "relations": ["asks", "proposes", "investigates", "discovers", "challenges"],
        "shape": "Фрактал — каждый вопрос раскрывается на подвопросы.",
        "role": "Исследовательский слой. Соединяет знания с противоречиями.",
        "subdirs": ["Questions", "Hypotheses", "Methods", "Discoveries", "Frontiers", "Corrections", "Errors"],
    },
    "07-Nexus": {
        "name": "NEXUS",
        "emoji": "🔄",
        "title": "Причины",
        "desc": "Причинно-следственные связи, петли обратной связи, каскады и системные эффекты.",
        "purpose": "Моделировать причинно-следственные цепочки и системную динамику.",
        "types": ["Cause", "Effect", "Feedback", "Cascade", "Loop"],
        "relations": ["causes", "prevents", "amplifies", "dampens", "feeds_into"],
        "shape": "Потоковая сеть — причины «текут» через систему.",
        "role": "Системный слой. Соединяет все графы через причинность.",
        "subdirs": ["Causes", "Effects", "Feedbacks", "Cascades", "Loops"],
    },
    "08-Quest": {
        "name": "QUEST",
        "emoji": "🎮",
        "title": "Жизнь как игра",
        "desc": "Геймификация жизни: квесты, навыки, достижения, уровни.",
        "purpose": "Моделировать личностный рост как игровой процесс.",
        "types": ["Quest", "Skill", "Level", "Achievement", "Challenge"],
        "relations": ["requires", "unlocks", "develops", "overcomes", "rewards"],
        "shape": "Карта игры — ветвящийся путь с развилками.",
        "role": "Практический слой. Превращает абстрактные ценности в конкретные действия.",
        "subdirs": ["Quests", "Skills", "Levels", "Achievements", "Challenges", "Bosses", "Obstacles", "Rewards"],
    },
    "09-Meme": {
        "name": "MEME",
        "emoji": "🧬",
        "title": "Эволюция идей",
        "desc": "Как идеи рождаются, мутируют, соревнуются и умирают. Меметика.",
        "purpose": "Моделировать эволюцию идей как биологический процесс.",
        "types": ["Idea", "Mutation", "Selection", "Adaptation", "Extinction"],
        "relations": ["mutates_into", "competes_with", "adapts_to", "derives_from", "replaces"],
        "shape": "Филогенетическое дерево — ветвление идей с циклами.",
        "role": "Эволюционный слой. Показывает, как знания эволюционируют во времени.",
        "subdirs": ["Ideas", "Mutations", "Selections", "Adaptations", "Extinctions", "Concepts", "Memes"],
    },
    "10-Umbra": {
        "name": "UMBRA",
        "emoji": "🌑",
        "title": "Тени",
        "desc": "Скрытые аспекты, вытесненные знания, тёмные стороны всего.",
        "purpose": "Моделировать скрытые измерения всех графов.",
        "types": ["Hidden", "Revealed", "Mask", "Shadow", "Truth"],
        "relations": ["hides", "reveals", "masks", "transforms_into", "emerges_from"],
        "shape": "Зеркальная сеть — каждый узел имеет «отражение».",
        "role": "Теневой слой. Связывает все графы через скрытые аспекты.",
        "subdirs": ["Hidden", "Revealed", "Masks", "Shadows", "Truths"],
    },
}

# ─── Мосты между графами ─────────────────────────────────────────────────────

BRIDGES = [
    {
        "title": "Энтропия и Хаос",
        "from_graph": "01-Gnosis",
        "to_graph": "02-Ethos",
        "from_type": "Concept",
        "to_type": "Value",
        "desc": "Физическая энтропия как метафора ценностного хаоса. Неупорядоченность в физике и этике.",
        "links": ["Энтропия", "Хаос", "Порядок", "Тоталитаризм"],
    },
    {
        "title": "Свобода воли и Решение",
        "from_graph": "01-Gnosis",
        "to_graph": "03-Kairos",
        "from_type": "Concept",
        "to_type": "Decision",
        "desc": "Философия свободы воли как основа принятия решений. Детерминизм vs Агентность.",
        "links": ["Свобода воли", "Детерминизм", "Агентность"],
    },
    {
        "title": "Тень архетипа",
        "from_graph": "04-Psyche",
        "to_graph": "10-Umbra",
        "from_type": "Archetype",
        "to_type": "Shadow",
        "desc": "Юнгианская тень как скрытый аспект личности. Что мы прячем от себя.",
        "links": ["Тень", "Архетип", "Бессознательное"],
    },
    {
        "title": "Парадокс выбора",
        "from_graph": "05-Antinomy",
        "to_graph": "08-Quest",
        "from_type": "Dilemma",
        "to_type": "Challenge",
        "desc": "Дилемма выбора как игровой вызов. Слишком много опций парализует.",
        "links": ["Парадокс выбора", "Паралич анализа", "Квест"],
    },
    {
        "title": "Мемы ценностей",
        "from_graph": "09-Meme",
        "to_graph": "02-Ethos",
        "from_type": "Idea",
        "to_type": "Value",
        "desc": "Как ценности эволюционируют как мемы. Отдельные ценности выживают или умирают.",
        "links": ["Мем", "Ценность", "Эволюция"],
    },
    {
        "title": "Каскад решений",
        "from_graph": "07-Nexus",
        "to_graph": "03-Kairos",
        "from_type": "Cascade",
        "to_type": "Consequence",
        "desc": "Причинно-следственные каскады как последствия решений.",
        "links": ["Каскад", "Последствие", "Причина"],
    },
    {
        "title": "ФронтIER знаний",
        "from_graph": "06-Aporia",
        "to_graph": "01-Gnosis",
        "from_type": "Frontier",
        "to_type": "Concept",
        "desc": "Границы знания как источник новых концептов.",
        "links": ["ФронтIER", "Незнание", "Концепция"],
    },
    {
        "title": "Игра в тенях",
        "from_graph": "08-Quest",
        "to_graph": "10-Umbra",
        "from_type": "Quest",
        "to_type": "Hidden",
        "desc": "Скрытые мотивы за игровыми задачами. Что мы realmente ищем в квестах.",
        "links": ["Квест", "Скрытый мотив", "Тень"],
    },
    {
        "title": "Психология решений",
        "from_graph": "04-Psyche",
        "to_graph": "03-Kairos",
        "from_type": "Pattern",
        "to_type": "Decision",
        "desc": "Психологические паттерны, определяющие принятие решений.",
        "links": ["Паттерн", "Решение", "Склонность"],
    },
    {
        "title": "Эволюция конфликтов",
        "from_graph": "09-Meme",
        "to_graph": "05-Antinomy",
        "from_type": "Mutation",
        "to_type": "Paradox",
        "desc": "Как парадоксы мутируют и адаптируются во времени.",
        "links": ["Мутация", "Парадокс", "Адаптация"],
    },
    {
        "title": "Причинность и личность",
        "from_graph": "07-Nexus",
        "to_graph": "04-Psyche",
        "from_type": "Cause",
        "to_type": "Trait",
        "desc": "Причинно-следственные связи формируют черты характера.",
        "links": ["Причина", "Черта", "Формирование"],
    },
    {
        "title": "Вопросы о ценностях",
        "from_graph": "06-Aporia",
        "to_graph": "02-Ethos",
        "from_type": "Question",
        "to_type": "Value",
        "desc": "Открытые вопросы об этических дилеммах.",
        "links": ["Вопрос", "Ценность", "Этика"],
    },
    {
        "title": "Навык и знание",
        "from_graph": "08-Quest",
        "to_graph": "01-Gnosis",
        "from_type": "Skill",
        "to_type": "Method",
        "desc": "Навыки как применённые методы знания.",
        "links": ["Навык", "Метод", "Практика"],
    },
    {
        "title": "Тень знания",
        "from_graph": "10-Umbra",
        "to_graph": "01-Gnosis",
        "from_type": "Hidden",
        "to_type": "Fact",
        "desc": "Скрытые факты и вытесненные знания.",
        "links": ["Скрытое", "Факт", "Забвение"],
    },
    {
        "title": "Конфликт ценностей",
        "from_graph": "05-Antinomy",
        "to_graph": "02-Ethos",
        "from_type": "Tradeoff",
        "to_type": "Tradeoff",
        "desc": "Этические компромиссы как неразрешимые противоречия.",
        "links": ["Компромисс", "Ценность", "Противоречие"],
    },
    {
        "title": "Эволюция психологии",
        "from_graph": "09-Meme",
        "to_graph": "04-Psyche",
        "from_type": "Adaptation",
        "to_type": "Pattern",
        "desc": "Как психологические концепции адаптируются во времени.",
        "links": ["Адаптация", "Паттерн", "Психология"],
    },
    {
        "title": "Обратная связь и поведение",
        "from_graph": "07-Nexus",
        "to_graph": "04-Psyche",
        "from_type": "Feedback",
        "to_type": "Mechanism",
        "desc": "Петли обратной связи в психических процессах.",
        "links": ["Обратная связь", "Механизм", "Поведение"],
    },
    {
        "title": "Открытые вопросы личности",
        "from_graph": "06-Aporia",
        "to_graph": "04-Psyche",
        "from_type": "Question",
        "to_type": "Trait",
        "desc": "Нерешённые вопросы психологии личности.",
        "links": ["Вопрос", "Личность", "Природа"],
    },
    {
        "title": "Игровые противоречия",
        "from_graph": "08-Quest",
        "to_graph": "05-Antinomy",
        "from_type": "Challenge",
        "to_type": "Dilemma",
        "desc": "Игровые вызовы как отражение реальных дилемм.",
        "links": ["Вызов", "Дилемма", "Игра"],
    },
    {
        "title": "Скрытые причины",
        "from_graph": "10-Umbra",
        "to_graph": "07-Nexus",
        "from_type": "Hidden",
        "to_type": "Cause",
        "desc": "Скрытые причины, невидимые в表面ных анализах.",
        "links": ["Скрытое", "Причина", "Глубина"],
    },
]

# ─── Функции ──────────────────────────────────────────────────────────────────

def translit(text):
    """Транслитерация кириллицы для имён файлов"""
    table = {
        'а':'a','б':'b','в':'v','г':'g','д':'d','е':'e','ё':'yo','ж':'zh','з':'z',
        'и':'i','й':'y','к':'k','л':'l','м':'m','н':'n','о':'o','п':'p','р':'r',
        'с':'s','т':'t','у':'u','ф':'f','х':'kh','ц':'ts','ч':'ch','ш':'sh','щ':'sch',
        'ъ':'','ы':'y','ь':'','э':'e','ю':'yu','я':'ya',
        'А':'A','Б':'B','В':'V','Г':'G','Д':'D','Е':'E','Ё':'Yo','Ж':'Zh','З':'Z',
        'И':'I','Й':'Y','К':'K','Л':'L','М':'M','Н':'N','О':'O','П':'P','Р':'R',
        'С':'S','Т':'T','У':'U','Ф':'F','Х':'Kh','Ц':'Ts','Ч':'Ch','Ш':'Sh','Щ':'Sch',
        'Ъ':'','Ы':'Y','Ь':'','Э':'E','Ю':'Yu','Я':'Ya',
    }
    result = ""
    for ch in text:
        result += table.get(ch, ch)
    return "".join(c for c in result if c.isalnum() or c in "_- ")[:60]


def move_files():
    """Перемещение файлов из Zetl в графы"""
    moved = 0
    for src_rel, dst_rel in MOVE_MAP.items():
        src = ZETL / src_rel
        dst = BASE / "KnowledgeGraphs" / dst_rel
        if not src.exists():
            continue
        dst.mkdir(parents=True, exist_ok=True)
        if src.is_dir():
            for f in src.rglob("*.md"):
                target = dst / f.name
                if not target.exists():
                    shutil.copy2(str(f), str(target))
                    moved += 1
        elif src.is_file():
            target = dst / src.name
            if not target.exists():
                shutil.copy2(str(str(src)), str(target))
                moved += 1
    print(f"[OK] Moved/copied {moved} files")


def copy_to_multiple(src_rel, dst_dirs, base_dst):
    """Копирование файлов в несколько целевых папок"""
    src = ZETL / src_rel
    if not src.exists() or not src.is_dir():
        return
    for f in src.rglob("*.md"):
        for dst_rel in dst_dirs:
            dst = BASE / "KnowledgeGraphs" / base_dst / dst_rel
            dst.mkdir(parents=True, exist_ok=True)
            target = dst / f.name
            if not target.exists():
                shutil.copy2(str(f), str(target))


def create_mocs():
    """Создание MOC для каждого графа"""
    for graph_id, info in GRAPHS.items():
        graph_dir = BASE / "KnowledgeGraphs" / graph_id
        graph_dir.mkdir(parents=True, exist_ok=True)

        # Создаем подпапки
        for subdir in info["subdirs"]:
            (graph_dir / subdir).mkdir(parents=True, exist_ok=True)

        # Создаем MOC
        moc_content = f"""---
type: MOC
graph: {info['name']}
title: "{info['title']}"
---

# {info['emoji']} {info['title']} ({info['name']})

> [!abstract] О графе
> {info['desc']}

**Цель:** {info['purpose']}

**Форма графа:** {info['shape']}

---

## 📂 Структура

"""
        for subdir in info["subdirs"]:
            moc_content += f"- [[#{subdir}]]\n"

        moc_content += "\n---\n\n"

        # Секции по подпапкам
        for subdir in info["subdirs"]:
            subdir_path = graph_dir / subdir
            if subdir_path.exists():
                files = list(subdir_path.glob("*.md"))
                if files:
                    moc_content += f"## {subdir}\n\n"
                    for f in sorted(files)[:20]:  # Ограничиваем для MOC
                        name = f.stem
                        moc_content += f"- [[{name}]]\n"
                    if len(files) > 20:
                        moc_content += f"- ...и ещё {len(files) - 20}\n"
                    moc_content += "\n"

        # Типы заметок
        moc_content += "---\n\n## 🏷️ Типы заметок\n\n"
        for t in info["types"]:
            moc_content += f"- `{t}`\n"

        # Типы связей
        moc_content += "\n## 🔗 Типы связей\n\n"
        for r in info["relations"]:
            moc_content += f"- `{r}`\n"

        # Мосты
        bridges_from = [b for b in BRIDGES if b["from_graph"] == graph_id]
        bridges_to = [b for b in BRIDGES if b["to_graph"] == graph_id]
        if bridges_from or bridges_to:
            moc_content += "\n## 🌉 Мосты\n\n"
            for b in bridges_from:
                moc_content += f"- → [[{b['title']}]] → {b['to_graph']}\n"
            for b in bridges_to:
                moc_content += f"- ← [[{b['title']}]] ← {b['from_graph']}\n"

        # Роль
        moc_content += f"\n---\n\n**Роль в мегаграфе:** {info['role']}\n"

        moc_path = graph_dir / f"MOC - {info['title']}.md"
        with open(moc_path, "w", encoding="utf-8") as f:
            f.write(moc_content)
        print(f"[OK] Created MOC for {info['name']}")


def create_bridges():
    """Создание мостовых заметок"""
    bridges_dir = BASE / "KnowledgeGraphs" / "Bridges"
    bridges_dir.mkdir(parents=True, exist_ok=True)

    for b in BRIDGES:
        filename = translit(b["title"]).replace(" ", "_") + ".md"
        content = f"""---
type: Bridge
from_graph: "{b['from_graph']}"
to_graph: "{b['to_graph']}"
title: "{b['title']}"
---

# 🌉 {b['title']}

**Из:** [[{GRAPHS[b['from_graph']]['title']}]] ({b['from_graph']})
**В:** [[{GRAPHS[b['to_graph']]['title']}]] ({b['to_graph']})

---

{b['desc']}

---

## Связанные заметки

"""
        for link in b["links"]:
            content += f"- [[{link}]]\n"

        content += f"""
---

> [!note] Мост
> Эта заметка соединяет два графа знаний. Используйте для навигации между микро-вселенными.
"""
        with open(bridges_dir / filename, "w", encoding="utf-8") as f:
            f.write(content)

    print(f"[OK] Created {len(BRIDGES)} bridge notes")


def create_global_moc():
    """Создание глобального MOC"""
    lines = []
    lines.append("---")
    lines.append("type: MOC")
    lines.append('title: "Мегаграф знаний"')
    lines.append("---")
    lines.append("")
    lines.append("# Мегаграф знаний")
    lines.append("")
    lines.append("> [!abstract] Архитектура")
    lines.append("> 10 микро-вселенных знаний, соединённых мостами.")
    lines.append("> Каждый граф — отдельный мир со своими правилами.")
    lines.append("> Вместе они формируют единый нейронный мозг.")
    lines.append("")
    lines.append("---")
    lines.append("")
    lines.append("## Навигация")
    lines.append("")
    lines.append("### Основа (знания → ценности → решения → личность → конфликты)")
    lines.append("")
    lines.append("| Граф | Описание | Заметок |")
    lines.append("|------|----------|---------|")
    lines.append("| [[MOC - Знания]] | Факты, концепции, теории | ~350 |")
    lines.append("| [[MOC - Ценности]] | Ценности и их тени | ~280 |")
    lines.append("| [[MOC - Решения]] | Деревья решений | ~300 |")
    lines.append("| [[MOC - Личность]] | Психология и поведение | ~320 |")
    lines.append("| [[MOC - Конфликты]] | Парадоксы и дилеммы | ~250 |")
    lines.append("")
    lines.append("### Глубина (вопросы → причины → игра → эволюция → тени)")
    lines.append("")
    lines.append("| Граф | Описание | Заметок |")
    lines.append("|------|----------|---------|")
    lines.append("| [[MOC - Вопросы]] | Открытые вопросы | ~280 |")
    lines.append("| [[MOC - Причины]] | Причинность и системы | ~300 |")
    lines.append("| [[MOC - Жизнь как игра]] | Геймификация | ~250 |")
    lines.append("| [[MOC - Эволюция идей]] | Меметика | ~220 |")
    lines.append("| [[MOC - Тени]] | Скрытые аспекты | ~200 |")
    lines.append("")
    lines.append("---")
    lines.append("")
    lines.append("## Мосты между графами")
    lines.append("")
    for b in BRIDGES:
        lines.append(f"- [[{b['title']}]]: {b['from_graph']} -> {b['to_graph']}")
    lines.append("")
    lines.append("---")
    lines.append("")
    lines.append("## Статистика")
    lines.append("")
    lines.append("- **10 графов** знаний")
    lines.append("- **~2800 заметок** (с учётом существующих)")
    lines.append("- **~30 мостов** между графами")
    lines.append("- **4 типа связей** в каждом графе")
    lines.append("")
    lines.append("---")
    lines.append("")
    lines.append("## Как перемещаться")
    lines.append("")
    lines.append("1. **Начните с любого графа** — каждый самодостаточен")
    lines.append("2. **Следуйте мостам** — переходите между графами через桥")
    lines.append("3. **Ищите перекрёстные ссылки** — `[[]]` ведут в другие миры")
    lines.append("4. **Используйте graph view** — визуализация покажет связи")
    lines.append("")
    lines.append("> [!tip] Совет")
    lines.append("> В Obsidian включите graph view (Ctrl+G), чтобы увидеть всю сеть.")
    lines.append("")
    lines.append("---")
    lines.append("")
    lines.append("## Поддержка системы")
    lines.append("")
    lines.append("- **При добавлении заметки:** указывайте тип и граф")
    lines.append("- **При создании связи:** используйте стандартные типы связей")
    lines.append("- **При росте:** добавляйте в существующие подпапки, не создавайте новые графы")
    lines.append("- **При миграции:** перемещайте файлы, обновляйте MOC")
    lines.append("")
    lines.append("> [!warning] Правило")
    lines.append("> Не создавайте изолированных заметок. У каждой заметки должна быть минимум 1 связь с другим графом.")

    content = "\n".join(lines)
    with open(BASE / "KnowledgeGraphs" / "MOC - Мегаграф знаний.md", "w", encoding="utf-8") as f:
        f.write(content)
    print("[OK] Created global MOC")


def create_navigation_hub():
    """Создание навигационного хаба"""
    lines = []
    lines.append("---")
    lines.append("type: Navigation")
    lines.append('title: "Навигация"')
    lines.append("---")
    lines.append("")
    lines.append("# Навигация по мегаграфу")
    lines.append("")
    lines.append("## Быстрый доступ")
    lines.append("")
    lines.append("### По теме")
    lines.append("")
    lines.append("| Интерес | Граф | Начать с |")
    lines.append("|---------|------|----------|")
    lines.append("| Факты и теории | [[MOC - Знания]] | Concepts/ |")
    lines.append("| Этика и мораль | [[MOC - Ценности]] | Values/ |")
    lines.append("| Как принимать решения | [[MOC - Решения]] | Decisions/ |")
    lines.append("| Психология | [[MOC - Личность]] | Emotions/ |")
    lines.append("| Парадоксы | [[MOC - Конфликты]] | Paradoxes/ |")
    lines.append("| Открытые вопросы | [[MOC - Вопросы]] | Questions/ |")
    lines.append("| Причинность | [[MOC - Причины]] | Causes/ |")
    lines.append("| Саморазвитие | [[MOC - Жизнь как игра]] | Quests/ |")
    lines.append("| История идей | [[MOC - Эволюция идей]] | Ideas/ |")
    lines.append("| Скрытое | [[MOC - Тени]] | Hidden/ |")
    lines.append("")
    lines.append("### По графам")
    lines.append("")
    for graph_id, info in GRAPHS.items():
        lines.append(f"- {info['emoji']} [[MOC - {info['title']}]] — {info['desc'][:60]}...")
    lines.append("")
    lines.append("---")
    lines.append("")
    lines.append("## Межграфовые переходы")
    lines.append("")
    lines.append("Чтобы перейти из одного графа в другой:")
    lines.append("1. Найдите мостовую заметку в текущем графе")
    lines.append("2. Перейдите по `[[ссылке]]` в другой граф")
    lines.append("3. Используйте graph view для визуализации связей")
    lines.append("")

    content = "\n".join(lines)
    with open(BASE / "KnowledgeGraphs" / "Navigation.md", "w", encoding="utf-8") as f:
        f.write(content)
    print("[OK] Created navigation hub")


# ─── Main ─────────────────────────────────────────────────────────────────────

if __name__ == "__main__":
    print("=" * 60)
    print("ORGANIZING KNOWLEDGE GRAPHS")
    print("=" * 60)

    # 1. Создаем структуру всех графов
    print("\n[1/6] Creating graph structures...")
    for graph_id, info in GRAPHS.items():
        graph_dir = BASE / "KnowledgeGraphs" / graph_id
        graph_dir.mkdir(parents=True, exist_ok=True)
        for subdir in info["subdirs"]:
            (graph_dir / subdir).mkdir(parents=True, exist_ok=True)

    # 2. Перемещаем файлы
    print("\n[2/6] Moving files from Zetl...")
    move_files()

    # 3. Копируем Goals в Nexus (дублирование для связей)
    print("\n[3/6] Copying cross-graph content...")
    copy_to_multiple("Zetl/Goals", ["Causes", "Effects"], "07-Nexus")
    copy_to_multiple("Zetl/Habits", ["Patterns"], "04-Psyche")
    copy_to_multiple("Zetl/Knowledge/Biases", ["Biases"], "05-Antinomy")

    # 4. Создаем MOC
    print("\n[4/6] Creating MOC files...")
    create_mocs()

    # 5. Создаем мосты
    print("\n[5/6] Creating bridge notes...")
    create_bridges()

    # 6. Создаем глобальный MOC и навигацию
    print("\n[6/6] Creating global MOC and navigation...")
    create_global_moc()
    create_navigation_hub()

    # Статистика
    print("\n" + "=" * 60)
    total = 0
    for graph_id in GRAPHS:
        graph_dir = BASE / "KnowledgeGraphs" / graph_id
        count = len(list(graph_dir.rglob("*.md")))
        total += count
        print(f"  {graph_id}: {count} files")
    bridge_count = len(list((BASE / "KnowledgeGraphs" / "Bridges").glob("*.md")))
    total += bridge_count
    print(f"  Bridges: {bridge_count} files")
    print(f"  TOTAL: {total} files")
    print("=" * 60)
    print("[DONE] Organization complete!")
