---
type: Prompt
title: "Quick Prompt"
created: 2026-06-22
---

# Quick Prompt

> Компактный промпт для реализации графов

---

## Промпт

```
Реализуй все графы в C:\obsidian\Main\Zetl\. Для каждого графа:

1. Прочитай структуру папки
2. Создай MOC файл:
```markdown
---
type: MOC
title: "[Название]"
created: 2026-06-22
---
# [Название]
> [Описание]
## Структура
| Подпапка | Описание | Нод |
|----------|----------|-----|
| [[Name]] | Desc | N |
**ИТОГО: N нод**
## Навигация
| Тема | Куда |
|------|------|
| Topic | [[Folder]] |
## Связи
- [[MOC - Zetl]]
```

3. Создай Navigation.md:
```markdown
---
type: Navigation
title: "Navigation - [Название]"
created: 2026-06-22
---
# Navigation
## По подпапкам
- [[Folder]] — Desc
## Потоки
Folder1 → Folder2 → Folder3
```

Графы:
- KnowledgeGalaxy (1827): AI, Economics, GameTheory, Learning, Philosophy, Productivity, Programming, Psychology
- Knowledge (1205): Biases, Concepts, Corrections, Decisions, Derived, Errors, Fundamental, Goals, MOCs, Principle, Projects, Reflections, Topics, Values
- DecisionMakingGraph (1993): Decisions, Outcomes, Principles, Rules, Values
- DecisionMaze (949): Alternatives, Consequences, Constraints, Decisions
- QuestionFractal (647): Insights, Questions
- PersonalityGraph (310): Desires, Emotions, Fears, Goals, Habits, Traits, Values
- BiasGraph (267): Biases, Corrections, Errors
- IdeaEcosystem (260): Concepts, Counterideas, Ideas, Memes
- ConflictGraph (260): Principles, Tradeoffs, Values
- ShadowValueSystem (257): Behaviors, Shadows, Tradeoffs, Values
- IntellectualNetwork (172): Books, Concepts, Ideas, Thinkers
- CausalLoop (158): Causes, Effects, Events, FeedbackLoops
- WorldModelGraph (136): Bridges, Models
```

---

## Пример использования

1. Скопируй промпт выше
2. Вставь в нейросеть (ChatGPT, Claude, etc.)
3. Дождися результата
4. Проверь созданные файлы

---

## Ожидаемый результат

- 25 MOC файлов
- 25 Navigation.md файлов
- Связи между графами
