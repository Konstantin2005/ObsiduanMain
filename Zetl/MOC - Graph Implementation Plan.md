---
type: MOC
title: "Graph Implementation Plan"
created: 2026-06-22
---

# Graph Implementation Plan

> План реализации всех графов в Zetl

---

## Общая статистика

| Метрика | Значение |
|---------|----------|
| Всего графов | 26 |
| Полностью реализован | 1 |
| Частично реализован | 13 |
| Не реализован (маленькие) | 12 |
| Всего нод | 15 781 |
| Нужно добавить MOC | 25 |
| Нужно добавить Navigation | 25 |

---

## Приоритеты реализации

### 🔴 Высокий приоритет (большие графы)

#### 1. KnowledgeGalaxy (1827 нод)
- **Статус**: ⚠️ Частичный
- **Что есть**: 8 подпапок, generate.py
- **Что нужно**:
  - [ ] Добавить MOC файл
  - [ ] Добавить Navigation.md
  - [ ] Стандартизировать структуру подпапок
  - [ ] Добавить индексы в каждую подпапку
- **Подпапки**:
  - `AI` — нужен MOC
  - `Economics` — нужен MOC
  - `GameTheory` — нужен MOC
  - `Learning` — нужен MOC
  - `Philosophy` — нужен MOC
  - `Productivity` — нужен MOC
  - `Programming` — нужен MOC
  - `Psychology` — нужен MOC

#### 2. Knowledge (1205 нод)
- **Статус**: ⚠️ Частичный
- **Что есть**: 14 подпапок
- **Что нужно**:
  - [ ] Добавить MOC файл
  - [ ] Добавить Navigation.md
  - [ ] Добавить индексы в каждую подпапку
- **Подпапки**:
  - `Biases` — нужен MOC
  - `Concepts` — нужен MOC
  - `Corrections` — нужен MOC
  - `Decisions` — нужен MOC
  - `Derived` — нужен MOC
  - `Errors` — нужен MOC
  - `Fundamental` — нужен MOC
  - `Goals` — нужен MOC
  - `MOCs` — есть
  - `Principle` — нужен MOC
  - `Projects` — нужен MOC
  - `Reflections` — нужен MOC
  - `Topics` — нужен MOC
  - `Values` — нужен MOC

#### 3. DecisionMakingGraph (1993 нод)
- **Статус**: ⚠️ Частичный
- **Что есть**: 5 подпапок, generate.py
- **Что нужно**:
  - [ ] Добавить MOC файл
  - [ ] Добавить Navigation.md
  - [ ] Стандартизировать структуру
- **Подпапки**:
  - `Decisions` — нужен MOC
  - `Outcomes` — нужен MOC
  - `Principles` — нужен MOC
  - `Rules` — нужен MOC
  - `Values` — нужен MOC

#### 4. DecisionMaze (949 нод)
- **Статус**: ⚠️ Частичный
- **Что есть**: 4 подпапки, generate.ps1
- **Что нужно**:
  - [ ] Добавить MOC файл
  - [ ] Добавить Navigation.md
  - [ ] Добавить generate.py
- **Подпапки**:
  - `Alternatives` — нужен MOC
  - `Consequences` — нужен MOC
  - `Constraints` — нужен MOC
  - `Decisions` — нужен MOC

#### 5. QuestionFractal (647 нод)
- **Статус**: ⚠️ Частичный
- **Что есть**: 2 подпапки, generate.ps1
- **Что нужно**:
  - [ ] Добавить MOC файл
  - [ ] Добавить Navigation.md
  - [ ] Добавить generate.py
- **Подпапки**:
  - `Insights` — нужен MOC
  - `Questions` — нужен MOC

---

### 🟡 Средний приоритет (средние графы)

#### 6. PersonalityGraph (310 нод)
- **Статус**: ⚠️ Частичный
- **Что есть**: 7 подпапок, generate.py
- **Что нужно**:
  - [ ] Добавить MOC файл
  - [ ] Добавить Navigation.md
- **Подпапки**:
  - `Desires` — нужен MOC
  - `Emotions` — нужен MOC
  - `Fears` — нужен MOC
  - `Goals` — нужен MOC
  - `Habits` — нужен MOC
  - `Traits` — нужен MOC
  - `Values` — нужен MOC

#### 7. BiasGraph (267 нод)
- **Статус**: ⚠️ Частичный
- **Что есть**: 3 подпапки, generate.py
- **Что нужно**:
  - [ ] Добавить MOC файл
  - [ ] Добавить Navigation.md
- **Подпапки**:
  - `Biases` — нужен MOC
  - `Corrections` — нужен MOC
  - `Errors` — нужен MOC

#### 8. IdeaEcosystem (260 нод)
- **Статус**: ⚠️ Частичный
- **Что есть**: 4 подпапки, generate.ps1
- **Что нужно**:
  - [ ] Добавить MOC файл
  - [ ] Добавить Navigation.md
  - [ ] Добавить generate.py
- **Подпапки**:
  - `Concepts` — нужен MOC
  - `Counterideas` — нужен MOC
  - `Ideas` — нужен MOC
  - `Memes` — нужен MOC

#### 9. ConflictGraph (260 нод)
- **Статус**: ⚠️ Частичный
- **Что есть**: 3 подпапки, generate.ps1
- **Что нужно**:
  - [ ] Добавить MOC файл
  - [ ] Добавить Navigation.md
  - [ ] Добавить generate.py
- **Подпапки**:
  - `Principles` — нужен MOC
  - `Tradeoffs` — нужен MOC
  - `Values` — нужен MOC

#### 10. ShadowValueSystem (257 нод)
- **Статус**: ⚠️ Частичный
- **Что есть**: 4 подпапки, generate_vault.py, MOC
- **Что нужно**:
  - [ ] Добавить Navigation.md
- **Подпапки**:
  - `Behaviors` — нужен MOC
  - `Shadows` — нужен MOC
  - `Tradeoffs` — нужен MOC
  - `Values` — нужен MOC

#### 11. IntellectualNetwork (172 нод)
- **Статус**: ⚠️ Частичный
- **Что есть**: 4 подпапки, generate.py
- **Что нужно**:
  - [ ] Добавить MOC файл
  - [ ] Добавить Navigation.md
- **Подпапки**:
  - `Books` — нужен MOC
  - `Concepts` — нужен MOC
  - `Ideas` — нужен MOC
  - `Thinkers` — нужен MOC

#### 12. CausalLoop (158 нод)
- **Статус**: ⚠️ Частичный
- **Что есть**: 4 подпапки, generate.py
- **Что нужно**:
  - [ ] Добавить MOC файл
  - [ ] Добавить Navigation.md
- **Подпапки**:
  - `Causes` — нужен MOC
  - `Effects` — нужен MOC
  - `Events` — нужен MOC
  - `FeedbackLoops` — нужен MOC

#### 13. WorldModelGraph (136 нод)
- **Статус**: ⚠️ Частичный
- **Что есть**: 2 подпапки + тематические файлы
- **Что нужно**:
  - [ ] Добавить MOC файл
  - [ ] Добавить Navigation.md
  - [ ] Добавить generate.py
- **Подпапки**:
  - `Bridges` — нужен MOC
  - `Models` — нужен MOC

---

### 🟢 Низкий приоритет (маленькие графы)

#### Объединить в тематические группы

**Группа "Игровая система"** (164 ноды)
- Quests (81)
- Obstacles (31)
- Rewards (31)
- Bosses (21)
- **Действия**:
  - [ ] Создать общий MOC
  - [ ] Создать Navigation.md
  - [ ] Объединить в одну папку `GameSystem`

**Группа "Жизненная система"** (88 нод)
- Skills (41)
- Habits (25)
- Goals (22)
- **Действия**:
  - [ ] Создать общий MOC
  - [ ] Создать Navigation.md
  - [ ] Объединить в одну папку `LifeSystem`

**Группа "Психология"** (152 ноды)
- Emotions (40)
- Traits (30)
- Fears (30)
- Desires (22)
- Values (22)
- **Действия**:
  - [ ] Создать общий MOC
  - [ ] Создать Navigation.md
  - [ ] Объединить в одну папку `PsychologyGraph`

---

## Дорожная карта

### Фаза 1: Стандартизация (1-2 дня)
1. Создать шаблон MOC для всех графов
2. Создать шаблон Navigation.md
3. Добавить MOC и Navigation в все графы

### Фаза 2: Крупные графы (3-5 дней)
1. Доработать KnowledgeGalaxy
2. Доработать Knowledge
3. Доработать DecisionMakingGraph
4. Доработать DecisionMaze
5. Доработать QuestionFractal

### Фаза 3: Средние графи (2-3 дня)
1. Доработать PersonalityGraph
2. Доработать BiasGraph
3. Доработать IdeaEcosystem
4. Доработать ConflictGraph
5. Доработать ShadowValueSystem
6. Доработать IntellectualNetwork
7. Доработать CausalLoop
8. Доработать WorldModelGraph

### Фаза 4: Маленькие графы (1-2 дня)
1. Объединить игровые графы
2. Объединить жизненные графы
3. Объединить психологические графы

### Фаза 5: Интеграция (1 день)
1. Создать общий MOC для всех графов
2. Связать графы между собой
3. Проверить навигацию

---

## Итого

| Этап | Время | Результат |
|------|-------|-----------|
| Фаза 1 | 1-2 дня | Стандартизация |
| Фаза 2 | 3-5 дней | Крупные графы |
| Фаза 3 | 2-3 дня | Средние графы |
| Фаза 4 | 1-2 дня | Маленькие графы |
| Фаза 5 | 1 день | Интеграция |
| **ИТОГО** | **8-13 дней** | **Полная реализация** |

---

## Связи

- [[MOC - All Graphs]] — все графы
- [[MOC - Realized Graphs]] — реализованные графы
- [[MOC - Zetl]] — главный индекс
