---
type: MOC
created: 2026-06-22
tags: [moc, cross-references, navigation]
---

# Cross-Graph Links

## Description
Индекс кросс-ссылок между графами Zetl. Показывает, какие графы связаны друг с другом.

---

## Матрица связей

| Из графа | В графа | Тип связи |
|----------|---------|-----------|
| Knowledge | KnowledgeGalaxy | Прямая |
| Knowledge | DecisionMakingGraph | Прямая |
| Knowledge | QuestionFractal | Прямая |
| Knowledge | BiasGraph | Прямая |
| Knowledge | PersonalityGraph | Прямая |
| KnowledgeGalaxy | Knowledge | Прямая |
| KnowledgeGalaxy | DecisionMakingGraph | Прямая |
| KnowledgeGalaxy | QuestionFractal | Прямая |
| DecisionMakingGraph | Knowledge | Прямая |
| DecisionMakingGraph | KnowledgeGalaxy | Прямая |
| DecisionMakingGraph | DecisionMaze | Прямая |
| DecisionMakingGraph | QuestionFractal | Прямая |
| DecisionMaze | Knowledge | Прямая |
| DecisionMaze | KnowledgeGalaxy | Прямая |
| DecisionMaze | DecisionMakingGraph | Прямая |
| DecisionMaze | QuestionFractal | Прямая |
| BiasGraph | Knowledge | Прямая |
| BiasGraph | PersonalityGraph | Прямая |
| BiasGraph | QuestionFractal | Прямая |
| ConflictGraph | ShadowValueSystem | Тематическая |
| ConflictGraph | DecisionMakingGraph | Тематическая |
| ShadowValueSystem | ConflictGraph | Тематическая |
| ShadowValueSystem | PersonalityGraph | Тематическая |
| PersonalityGraph | BiasGraph | Прямая |
| PersonalityGraph | ShadowValueSystem | Тематическая |
| CausalLoop | DecisionMakingGraph | Тематическая |
| CausalLoop | WorldModelGraph | Тематическая |
| WorldModelGraph | CausalLoop | Тематическая |
| WorldModelGraph | Knowledge | Тематическая |
| IntellectualNetwork | Knowledge | Тематическая |
| IntellectualNetwork | KnowledgeGalaxy | Тематическая |
| IdeaEcosystem | Knowledge | Тематическая |
| IdeaEcosystem | IntellectualNetwork | Тематическая |
| QuestionFractal | Knowledge | Прямая |
| QuestionFractal | KnowledgeGalaxy | Прямая |
| QuestionFractal | DecisionMakingGraph | Прямая |
| GameSystem | Knowledge | Тематическая |

---

## Связанные пары графов

### Knowledge ↔ KnowledgeGalaxy
Обмен знаниями и концепциями

### Knowledge ↔ DecisionMakingGraph
Применение знаний для принятия решений

### Knowledge ↔ QuestionFractal
Исследование неизвестного через базу знаний

### BiasGraph ↔ PersonalityGraph
Когнитивные искажения и личностные черты

### ConflictGraph ↔ ShadowValueSystem
Конфликты ценностей и их теневые стороны

### CausalLoop ↔ WorldModelGraph
Причинно-следственные связи в модели мира

### DecisionMakingGraph ↔ DecisionMaze
Два подхода к принятию решений

---

## Связи с корневым MOC

- [[MOC Global]] — Главный индекс всех графов
- [[MOC - All Graphs]] — Полный каталог с статистикой
- [[MOC - Zetl]] — Корневой MOC vault'а
