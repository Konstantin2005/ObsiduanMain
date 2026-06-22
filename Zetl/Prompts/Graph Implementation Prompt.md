---
type: Prompt
title: "Graph Implementation Prompt"
created: 2026-06-22
---

# Graph Implementation Prompt

> Промпт для нейросети для реализации всех графов в Zetl

---

## Базовый промпт

```
Ты - эксперт по созданию графов знаний в Obsidian. Твоя задача - реализовать все графы в директории C:\obsidian\Main\Zetl\.

## Контекст

У нас есть 26 графов разного размера. Нужно добавить в каждый граф:
1. MOC (Map of Content) файл
2. Navigation.md для навигации
3. Индексы для каждой подпапки
4. Стандартизировать структуру

## Шаблон MOC файла

Для каждого графа создай MOC файл по шаблону:

```markdown
---
type: MOC
title: "[Название графа]"
created: [Дата]
---

# [Название графа]

> [Краткое описание графа]

---

## Структура

| Подпапка | Описание | Нод |
|----------|----------|-----|
|  | [Описание] | [Кол-во] |
|  | [Описание] | [Кол-во] |

**ИТОГО: [Общее кол-во] нод**

---

## Навигация

| Тема | Куда идти |
|------|-----------|
| [Тема 1] |  |
| [Тема 2] |  |

---

## Ключевые концепции

-  — [Описание]
-  — [Описание]

---

## Связи

-  — [Описание связи]
-  — [Описание связи]
```

## Шаблон Navigation.md

```markdown
---
type: Navigation
title: "Navigation - [Название графа]"
created: [Дата]
---

# Navigation

## Быстрый доступ

### По подпапкам
-  — [Описание]
-  — [Описание]

### По темам
- **[Тема 1]**: Subfolder1 → Subfolder2
- **[Тема 2]**: Subfolder3 → Subfolder4

---

## Потоки

### Изучение
```
Subfolder1 → Subfolder2 → Subfolder3
```

### Применение
```
Subfolder4 → Subfolder5 → Subfolder6
```

---

## Связи между подпапками

```
Subfolder1 ←→ Subfolder2
     ↓           ↓
Subfolder3 ←→ Subfolder4
```
```

## Список графов для реализации

### Высокий приоритет

1. **KnowledgeGalaxy** (1827 нод)
   - Подпапки: AI, Economics, GameTheory, Learning, Philosophy, Productivity, Programming, Psychology
   - Создать MOC для каждой подпапки

2. **Knowledge** (1205 нод)
   - Подпапки: Biases, Concepts, Corrections, Decisions, Derived, Errors, Fundamental, Goals, MOCs, Principle, Projects, Reflections, Topics, Values
   - Создать MOC для каждой подпапки

3. **DecisionMakingGraph** (1993 нод)
   - Подпапки: Decisions, Outcomes, Principles, Rules, Values
   - Создать MOC для каждой подпапки

4. **DecisionMaze** (949 нод)
   - Подпапки: Alternatives, Consequences, Constraints, Decisions
   - Создать MOC для каждой подпапки

5. **QuestionFractal** (647 нод)
   - Подпапки: Insights, Questions
   - Создать MOC для каждой подпапки

### Средний приоритет

6. **PersonalityGraph** (310 нод)
   - Подпапки: Desires, Emotions, Fears, Goals, Habits, Traits, Values

7. **BiasGraph** (267 нод)
   - Подпапки: Biases, Corrections, Errors

8. **IdeaEcosystem** (260 нод)
   - Подпапки: Concepts, Counterideas, Ideas, Memes

9. **ConflictGraph** (260 нод)
   - Подпапки: Principles, Tradeoffs, Values

10. **ShadowValueSystem** (257 нод)
    - Подпапки: Behaviors, Shadows, Tradeoffs, Values

11. **IntellectualNetwork** (172 нод)
    - Подпапки: Books, Concepts, Ideas, Thinkers

12. **CausalLoop** (158 нод)
    - Подпапки: Causes, Effects, Events, FeedbackLoops

13. **WorldModelGraph** (136 нод)
    - Подпапки: Bridges, Models

### Низкий приоритет (объединить в группы)

14. **Игровая система** (164 ноды)
    - Quests (81), Obstacles (31), Rewards (31), Bosses (21)
    - Объединить в папку GameSystem

15. **Жизненная система** (88 нод)
    - Skills (41), Habits (25), Goals (22)
    - Объединить в папку LifeSystem

16. **Психология** (152 ноды)
    - Emotions (40), Traits (30), Fears (30), Desires (22), Values (22)
    - Объединить в папку PsychologyGraph

## Порядок действий

1. Прочитай структуру каждой папки
2. Определи количество нод в каждой подпапке
3. Создай MOC файл для графа
4. Создай Navigation.md для графа
5. Создай MOC для каждой подпапки
6. Свяжи все MOC файлы между собой

## Важные замечания

- Все ссылки должны быть в формате 
- Даты в формате YYYY-MM-DD
- Используй эмодзи для визуального разделения
- Добавляй краткие описания ко всем элементам
- Связывай графы между собой через MOC файлы
```

---

## Расширенный промпт для автоматизации

```
Ты - автоматизатор для создания графов знаний в Obsidian. Напиши скрипт на Python, который:

1. Сканирует директорию C:\obsidian\Main\Zetl\
2. Находит все папки с графами
3. Для каждой папки:
   - Подсчитывает количество .md файлов
   - Создает MOC файл по шаблону
   - Создает Navigation.md по шаблону
   - Создает MOC для каждой подпапки
4. Связывает все MOC файлы между собой

## Входные данные

- Путь к директории: C:\obsidian\Main\Zetl\
- Шаблон MOC: [см. выше]
- Шаблон Navigation: [см. выше]

## Выходные данные

- MOC файлы в каждой папке
- Navigation.md в каждой папке
- Связи между графами

## Формат вывода

```python
import os
from pathlib import Path

def scan_graphs(base_path):
    """Сканирует все графы в директории"""
    graphs = []
    for item in Path(base_path).iterdir():
        if item.is_dir() and item.name != '.obsidian':
            nodes = count_md_files(item)
            subdirs = [d.name for d in item.iterdir() if d.is_dir()]
            graphs.append({
                'name': item.name,
                'path': str(item),
                'nodes': nodes,
                'subdirs': subdirs
            })
    return graphs

def count_md_files(path):
    """Подсчитывает количество .md файлов"""
    return len(list(path.rglob('*.md')))

def create_moc(graph):
    """Создает MOC файл для графа"""
    template = f"""---
type: MOC
title: "{graph['name']}"
created: 2026-06-22
---

# {graph['name']}

> Описание графа

---

## Структура

| Подпапка | Описание | Нод |
|----------|----------|-----|
"""
    for subdir in graph['subdirs']:
        nodes = count_md_files(Path(graph['path']) / subdir)
        template += f"|  | Описание | {nodes} |\n"
    
    template += f"""
**ИТОГО: {graph['nodes']} нод**

---

## Навигация

| Тема | Куда идти |
|------|-----------|
"""
    for subdir in graph['subdirs']:
        template += f"| {subdir} |  |\n"
    
    template += """
---

## Связи

-  — главный индекс
"""
    
    return template

def create_navigation(graph):
    """Создает Navigation.md для графа"""
    template = f"""---
type: Navigation
title: "Navigation - {graph['name']}"
created: 2026-06-22
---

# Navigation

## Быстрый доступ

### По подпапкам
"""
    for subdir in graph['subdirs']:
        template += f"-  — Описание\n"
    
    template += """
---

## Потоки

### Изучение
```
"""
    if len(graph['subdirs']) >= 2:
        template += f"{graph['subdirs'][0]} → {graph['subdirs'][1]}\n"
    
    template += """```

### Применение
```
"""
    if len(graph['subdirs']) >= 3:
        template += f"{graph['subdirs'][2]} → {graph['subdirs'][3] if len(graph['subdirs']) > 3 else graph['subdirs'][0]}\n"
    
    template += """```
"""
    
    return template

# Основной скрипт
base_path = r"C:\obsidian\Main\Zetl"
graphs = scan_graphs(base_path)

for graph in graphs:
    # Создаем MOC
    moc_content = create_moc(graph)
    moc_path = Path(graph['path']) / f"MOC - {graph['name']}.md"
    with open(moc_path, 'w', encoding='utf-8') as f:
        f.write(moc_content)
    
    # Создаем Navigation
    nav_content = create_navigation(graph)
    nav_path = Path(graph['path']) / "Navigation.md"
    with open(nav_path, 'w', encoding='utf-8') as f:
        f.write(nav_content)
    
    print(f"Создано для {graph['name']}: MOC + Navigation")
```

---

## Промпт для проверки

```
Проверь реализацию всех графов в C:\obsidian\Main\Zetl\:

1. Проверь наличие MOC файла в каждом графе
2. Проверь наличие Navigation.md в каждом графе
3. Проверь количество нод в каждом графе
4. Проверь связи между графами
5. Составь отчет о реализации

Формат отчета:

| Граф | Нод | MOC | Navigation | Статус |
|------|-----|-----|------------|--------|
| Graph1 | 100 | ✅ | ✅ | Готово |
| Graph2 | 200 | ❌ | ❌ | Нужна доработка |
```
