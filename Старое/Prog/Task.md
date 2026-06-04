# Заготовка для генерации 2000-узлового графа Zettelkasten в Obsidian

## Структура запроса для нейронной сети:

YAML

Копировать код

```
Генерируй граф знаний для Obsidian по следующей схеме:

ИЕРАРХИЯ:
Уровень 1 (Атомарные идеи) — 1200 узлов
Уровень 2 (Средние темы) — 600 узлов  
Уровень 3 (Обзорные статьи) — 200 узлов

СТРУКТУРА КАЖДОГО УЗЛА:
# [Название идеи] #тег1 #тег2 #уровень1

[2-3 строки описания]

**Ссылки вверх (на более крупные темы):**
- → [[Средняя тема A]]
- → [[Средняя тема B]]

**Ссылки в стороны (на похожие идеи):**
- ≈ [[Похожая идея 1]]
- ≈ [[Похожая идея 2]]

**Ссылки вниз (на более мелкие идеи):**
- ↓ [[Атомарная идея 1]]
- ↓ [[Атомарная идея 2]]

---
```

## Готовый шаблон-заготовка (копируй в нейронку):

YAML

Копировать код

```
# Уровень 1: Атомарные идеи (1200 узлов)

## BACKEND - DATABASES

# INDEX, PRIMARY KEY #database #sql #уровень1

Основной ключ таблицы, уникально идентифицирует строку.

→ [[SQL Индексирование]]
→ [[Оптимизация запросов]]

≈ [[UNIQUE Constraint]]
≈ [[Foreign Key]]

---

# B-TREE ИНДЕКС #database #indexing #структура-данных #уровень1

Самобалансирующееся дерево поиска для быстрого доступа к данным.

→ [[SQL Индексирование]]
→ [[Структуры данных]]

≈ [[Hash Index]]
≈ [[Bitmap Index]]

↓ [[B+ Tree]]
↓ [[B* Tree]]

---

# NORMALIZATION 1NF #database #design #уровень1

Первая нормальная форма: атомарность данных в каждой ячейке.

→ [[Нормализация БД]]
→ [[Database Design]]

≈ [[Atomicity]]

---

# ACID PROPERTIES #database #transactions #уровень1

Атомарность, Консистентность, Изоляция, Долговечность.

→ [[Транзакции]]
→ [[Надежность БД]]

≈ [[CAP Theorem]]

↓ [[Atomicity]]
↓ [[Consistency]]
↓ [[Isolation]]
↓ [[Durability]]

---

# N+1 QUERY PROBLEM #database #optimization #антипаттерн #уровень1

Проблема избыточных запросов при загрузке связанных данных.

→ [[SQL Performance]]
→ [[ORM Optimization]]

≈ [[Query Optimization]]

↓ [[Eager Loading]]
↓ [[Lazy Loading]]

---

## BACKEND - API & ARCHITECTURE

# REST ENDPOINT DESIGN #api #rest #backend #уровень1

Принципы дизайна RESTful API endpoints с правильными HTTP методами.

→ [[REST Architecture]]
→ [[API Design Patterns]]

≈ [[GraphQL Schema]]
≈ [[SOAP Web Service]]

---

# JWT AUTHENTICATION #security #auth #tokens #уровень1

JSON Web Token для безопасной аутентификации и авторизации.

→ [[Authentication Methods]]
→ [[Security Best Practices]]

≈ [[OAuth 2.0]]
≈ [[Session Cookies]]

↓ [[JWT Header]]
↓ [[JWT Payload]]
↓ [[JWT Signature]]

---

# CORS POLICY #http #security #api #уровень1

Cross-Origin Resource Sharing — управление кросс-доменными запросами.

→ [[HTTP Headers]]
→ [[Browser Security]]

≈ [[Same-Origin Policy]]

---

# CACHING STRATEGY #optimization #performance #уровень1

Стратегии кэширования для снижения нагрузки на БД и серверы.

→ [[Performance Optimization]]
→ [[Distributed Systems]]

≈ [[CDN]]
≈ [[Redis]]

↓ [[Cache Invalidation]]
↓ [[TTL Strategy]]
↓ [[LRU Cache]]

---

## BACKEND - DESIGN PATTERNS

# SINGLETON PATTERN #design-patterns #creational #уровень1

Паттерн для создания единственного экземпляра класса.

→ [[Design Patterns]]
→ [[Creational Patterns]]

≈ [[Factory Pattern]]

---

# OBSERVER PATTERN #design-patterns #behavioral #уровень1

Паттерн для оповещения множества объектов об изменениях.

→ [[Design Patterns]]
→ [[Behavioral Patterns]]

≈ [[Pub/Sub Pattern]]

↓ [[Event Emitter]]
↓ [[Event Listener]]

---

# STRATEGY PATTERN #design-patterns #behavioral #уровень1

Паттерн для инкапсуляции семейства алгоритмов.

→ [[Design Patterns]]
→ [[Behavioral Patterns]]

≈ [[State Pattern]]

---

# FACTORY PATTERN #design-patterns #creational #уровень1

Паттерн для создания объектов без указания конкретных классов.

→ [[Design Patterns]]
→ [[Creational Patterns]]

≈ [[Builder Pattern]]

↓ [[Simple Factory]]
↓ [[Factory Method]]
↓ [[Abstract Factory]]

---

# DEPENDENCY INJECTION #design-patterns #architecture #уровень1

Внедрение зависимостей через конструктор или сеттер.

→ [[Design Patterns]]
→ [[SOLID Principles]]

≈ [[IoC Container]]

---

## FRONTEND - REACT

# VIRTUAL DOM #react #frontend #optimization #уровень1

Виртуальное представление DOM для оптимизации обновлений.

→ [[React Architecture]]
→ [[Performance Optimization]]

≈ [[Fiber Architecture]]

---

# HOOKS STATE #react #state-management #уровень1

useState, useEffect и другие hooks для управления состоянием.

→ [[React Hooks]]
→ [[State Management]]

≈ [[Class Components]]

↓ [[useState Hook]]
↓ [[useEffect Hook]]
↓ [[useContext Hook]]
↓ [[useReducer Hook]]

---

# COMPONENT LIFECYCLE #react #frontend #уровень1

Стадии жизни компонента: монтирование, обновление, размонтирование.

→ [[React Fundamentals]]
→ [[Component Architecture]]

≈ [[Lifecycle Methods]]

---

# PROP DRILLING #react #antipattern #уровень1

Проблема передачи props через множество уровней компонентов.

→ [[React Patterns]]
→ [[State Management Issues]]

≈ [[Prop Passing]]

↓ [[Context API]]
↓ [[Redux Alternative]]

---

## DEVOPS & INFRASTRUCTURE

# DOCKER CONTAINER #devops #containerization #уровень1

Контейнеризация приложения с Docker для портативности.

→ [[Containerization]]
→ [[DevOps Tools]]

≈ [[Kubernetes Pod]]
≈ [[Virtual Machine]]

↓ [[Dockerfile]]
↓ [[Docker Compose]]
↓ [[Docker Registry]]

---

# KUBECTL DEPLOYMENT #kubernetes #devops #уровень1

Развертывание приложений на Kubernetes кластере.

→ [[Kubernetes]]
→ [[Orchestration]]

≈ [[Docker Swarm]]

↓ [[Pod]]
↓ [[Service]]
↓ [[Ingress]]

---

# CI/CD PIPELINE #devops #automation #уровень1

Непрерывная интеграция и развертывание для автоматизации релизов.

→ [[DevOps Practices]]
→ [[Automation]]

≈ [[GitHub Actions]]
≈ [[Jenkins]]

↓ [[Build Stage]]
↓ [[Test Stage]]
↓ [[Deploy Stage]]

---

# LOAD BALANCING #devops #scalability #уровень1

Распределение нагрузки между серверами для масштабируемости.

→ [[Scalability]]
→ [[Distributed Systems]]

≈ [[Reverse Proxy]]
≈ [[Round Robin]]

---

## ALGORITHMS & COMPLEXITY

# TIME COMPLEXITY O(N) #algorithms #complexity #уровень1

Линейная сложность, где время растет пропорционально входным данным.

→ [[Big O Notation]]
→ [[Algorithm Analysis]]

≈ [[Space Complexity]]

---

# BINARY SEARCH ALGORITHM #algorithms #search #уровень1

Алгоритм поиска с логарифмической сложностью O(log n).

→ [[Search Algorithms]]
→ [[Divide and Conquer]]

≈ [[Linear Search]]

↓ [[Recursive Binary Search]]
↓ [[Iterative Binary Search]]

---

# QUICKSORT ALGORITHM #algorithms #sorting #уровень1

Алгоритм сортировки с средней сложностью O(n log n).

→ [[Sorting Algorithms]]
→ [[Divide and Conquer]]

≈ [[Merge Sort]]
≈ [[Heap Sort]]

---
```