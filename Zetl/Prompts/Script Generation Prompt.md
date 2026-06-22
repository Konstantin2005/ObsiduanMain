---
type: Prompt
title: "Script Generation Prompt"
created: 2026-06-22
---

# Script Generation Prompt

> Промпт для генерации скрипта автоматизации

---

## Промпт

```
Напиши Python скрипт для автоматической реализации графов в Obsidian.

## Требования

1. Сканируй директорию C:\obsidian\Main\Zetl\
2. Находи все папки с графами (исключай .obsidian, Templates, Documentation)
3. Для каждого графа:
   - Подсчитывай количество .md файлов
   - Создавай MOC файл
   - Создавай Navigation.md
4. Связывай графы между собой

## Функции

```python
import os
from pathlib import Path
from datetime import datetime

def scan_graphs(base_path):
    """Сканирует графы"""
    pass

def count_nodes(path):
    """Считает ноды"""
    pass

def create_moc(graph_name, subdirs, nodes):
    """Создает MOC"""
    pass

def create_navigation(graph_name, subdirs):
    """Создает Navigation"""
    pass

def main():
    base = Path(r"C:\obsidian\Main\Zetl")
    graphs = scan_graphs(base)
    for graph in graphs:
        create_moc(graph['name'], graph['subdirs'], graph['nodes'])
        create_navigation(graph['name'], graph['subdirs'])
```

## Выход

Готовый скрипт, который можно запустить.
```

---

## Результат

Скрипт будет создан в файле `generate_all_graphs.py`
