#!/usr/bin/env python3
"""
Скрипт для автоматической реализации графов в Obsidian
"""

import os
from pathlib import Path
from datetime import datetime

def scan_graphs(base_path):
    """Сканирует все графы в директории"""
    graphs = []
    exclude_dirs = {'.obsidian', 'Templates', 'Documentation', 'Inbox', 'Index', 
                   'Locations', 'MasterPrompt', 'PromptAtoms-main', 'Node',
                   'KnowledgeGraphs_Core', 'NeuralNetwork_Vault', 'Zettelkasten_Vault'}
    
    for item in Path(base_path).iterdir():
        if item.is_dir() and item.name not in exclude_dirs:
            nodes = count_md_files(item)
            subdirs = [d.name for d in item.iterdir() if d.is_dir() and d.name != '.obsidian']
            has_moc = any(f.name.startswith('MOC') for f in item.iterdir() if f.is_file())
            has_nav = (item / 'Navigation.md').exists()
            
            graphs.append({
                'name': item.name,
                'path': str(item),
                'nodes': nodes,
                'subdirs': subdirs,
                'has_moc': has_moc,
                'has_nav': has_nav
            })
    
    return sorted(graphs, key=lambda x: x['nodes'], reverse=True)

def count_md_files(path):
    """Подсчитывает количество .md файлов"""
    return len(list(path.rglob('*.md')))

def create_moc(graph):
    """Создает MOC файл для графа"""
    template = f"""---
type: MOC
title: "{graph['name']}"
created: {datetime.now().strftime('%Y-%m-%d')}
---

# {graph['name']}

> Граф знаний: {graph['name']}

---

## Структура

| Подпапка | Описание | Нод |
|----------|----------|-----|
"""
    
    total_nodes = 0
    for subdir in graph['subdirs']:
        subdir_path = Path(graph['path']) / subdir
        nodes = count_md_files(subdir_path)
        total_nodes += nodes
        template += f"| [[{subdir}]] | Описание | {nodes} |\n"
    
    template += f"""
**ИТОГО: {total_nodes} нод**

---

## Навигация

| Тема | Куда идти |
|------|-----------|
"""
    
    for subdir in graph['subdirs']:
        template += f"| {subdir} | [[{subdir}]] |\n"
    
    template += f"""
---

## Ключевые концепции

- [[Concept1]] — Описание
- [[Concept2]] — Описание

---

## Связи

- [[MOC - Zetl]] — главный индекс
- [[MOC - All Graphs]] — все графы
"""
    
    return template

def create_navigation(graph):
    """Создает Navigation.md для графа"""
    template = f"""---
type: Navigation
title: "Navigation - {graph['name']}"
created: {datetime.now().strftime('%Y-%m-%d')}
---

# Navigation

## Быстрый доступ

### По подпапкам
"""
    
    for subdir in graph['subdirs']:
        template += f"- [[{subdir}]] — Описание\n"
    
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

---

## Связи между подпапками

```
"""
    
    if len(graph['subdirs']) >= 2:
        template += f"{graph['subdirs'][0]} ←→ {graph['subdirs'][1]}\n"
    
    if len(graph['subdirs']) >= 4:
        template += f"     ↓           ↓\n"
        template += f"{graph['subdirs'][2]} ←→ {graph['subdirs'][3]}\n"
    
    template += """```
"""
    
    return template

def create_subdir_mocs(graph):
    """Создает MOC для каждой подпапки"""
    created = []
    
    for subdir in graph['subdirs']:
        subdir_path = Path(graph['path']) / subdir
        moc_path = subdir_path / f"MOC - {subdir}.md"
        
        if not moc_path.exists():
            # Подсчитываем файлы в подпапке
            files = list(subdir_path.glob('*.md'))
            files = [f for f in files if not f.name.startswith('MOC')]
            
            template = f"""---
type: MOC
title: "{subdir}"
created: {datetime.now().strftime('%Y-%m-%d')}
---

# {subdir}

> Подпапка графа {graph['name']}

---

## Файлы ({len(files)})

"""
            
            for f in files[:20]:  # Ограничиваем 20 файлами
                template += f"- [[{f.stem}]]\n"
            
            if len(files) > 20:
                template += f"- ... и ещё {len(files) - 20}\n"
            
            template += f"""
---

## Связи

- [[MOC - {graph['name']}]] — родительский граф
"""
            
            with open(moc_path, 'w', encoding='utf-8') as f:
                f.write(template)
            
            created.append(subdir)
    
    return created

def main():
    base_path = Path(r"C:\obsidian\Main\Zetl")
    
    print("Сканирование графов...")
    graphs = scan_graphs(base_path)
    
    print(f"Найдено {len(graphs)} графов\n")
    
    stats = {
        'total': len(graphs),
        'moc_created': 0,
        'nav_created': 0,
        'subdir_mocs_created': 0
    }
    
    for graph in graphs:
        print(f"Обработка: {graph['name']} ({graph['nodes']} нод)")
        
        # Создаем MOC
        if not graph['has_moc']:
            moc_content = create_moc(graph)
            moc_path = Path(graph['path']) / f"MOC - {graph['name']}.md"
            with open(moc_path, 'w', encoding='utf-8') as f:
                f.write(moc_content)
            stats['moc_created'] += 1
            print(f"  ✅ Создан MOC")
        
        # Создаем Navigation
        if not graph['has_nav']:
            nav_content = create_navigation(graph)
            nav_path = Path(graph['path']) / "Navigation.md"
            with open(nav_path, 'w', encoding='utf-8') as f:
                f.write(nav_content)
            stats['nav_created'] += 1
            print(f"  ✅ Создан Navigation")
        
        # Создаем MOC для подпапок
        created_mocs = create_subdir_mocs(graph)
        if created_mocs:
            stats['subdir_mocs_created'] += len(created_mocs)
            print(f"  ✅ Создано {len(created_mocs)} MOC для подпапок")
    
    print("\n" + "="*50)
    print("ИТОГО:")
    print(f"  Всего графов: {stats['total']}")
    print(f"  Создано MOC: {stats['moc_created']}")
    print(f"  Создано Navigation: {stats['nav_created']}")
    print(f"  Создано MOC для подпапок: {stats['subdir_mocs_created']}")

if __name__ == "__main__":
    main()
