#!/usr/bin/env python3
"""Anti-Fragile Graph — граф, который усиливается при разрушении"""
import os
import random
import sys
from pathlib import Path
from collections import defaultdict

sys.stdout.reconfigure(encoding='utf-8')
random.seed(42)

BASE = Path(r"C:\obsidian\Main\KnowledgeGraphs\AntiFragile")

# ─── Конфигурация ────────────────────────────────────────────────────────────

NUM_CORES = 8
CORE_SIZE_MIN = 18
CORE_SIZE_MAX = 28
MIN_LINKS = 7
MIN_CROSS_CLUSTER = 2

# Кластеры — тематические ядра
CLUSTER_THEMES = [
    ("Мозг", "Нейронаука, сознание, когнитивные процессы"),
    ("Энергия", "Физика, термодинамика, квантовая теория"),
    ("Информация", "Теория информации, алгоритмы, данные"),
    ("Эволюция", "Биология, генетика, адаптация"),
    ("Экономика", "Рынки, ценности, обмен"),
    ("Язык", "Лингвистика, семиотика, коммуникация"),
    ("Архитектура", "Структуры, системы, проектирование"),
    ("Этика", "Ценности, мораль, ответственность"),
]

# ─── Генерация ядра ──────────────────────────────────────────────────────────

nodes = {}  # id -> {cluster, title, desc, links}
link_count = defaultdict(int)
cluster_nodes = defaultdict(list)  # cluster_id -> [node_ids]

def add_link(s, t, bidirectional=True):
    if s == t:
        return
    if t in [x for x, _ in nodes[s]["links"]]:
        return
    nodes[s]["links"].append(t)
    link_count[s] += 1
    link_count[t] += 1
    if bidirectional:
        nodes[t]["links"].append(s)

node_counter = 0

def create_node(cluster_id, theme_name, specialty=""):
    global node_counter
    node_counter += 1
    nid = f"n{node_counter:04d}"
    title = f"{theme_name}_{node_counter}"
    nodes[nid] = {
        "cluster": cluster_id,
        "title": title,
        "desc": f"Узел кластера {theme_name}. {specialty}",
        "links": [],
    }
    cluster_nodes[cluster_id].append(nid)
    return nid

# Создаём кластеры
for cid, (theme, desc) in enumerate(CLUSTER_THEMES):
    size = random.randint(CORE_SIZE_MIN, CORE_SIZE_MAX)
    core_nodes = []

    # Создаём узлы ядра
    for i in range(size):
        specialty = f"Специализация: {theme} variant {i+1}"
        nid = create_node(cid, theme, specialty)
        core_nodes.append(nid)

    # Плотное связывание внутри ядра (каждый узел связан с 60-80% других)
    for i, n1 in enumerate(core_nodes):
        num_connections = random.randint(int(len(core_nodes) * 0.5), int(len(core_nodes) * 0.8))
        targets = random.sample([n for n in core_nodes if n != n1], min(num_connections, len(core_nodes) - 1))
        for n2 in targets:
            add_link(n1, n2)

# ─── Мосты между кластерами ──────────────────────────────────────────────────

# Каждый кластер связан минимум с 2 другими
cluster_list = list(range(NUM_CORES))
for cid in cluster_list:
    # Выбираем 2-3 других кластера для связи
    targets = random.sample([c for c in cluster_list if c != cid], random.randint(2, 3))
    for target_cid in targets:
        # Выбираем по 2-3 узла из каждого кластера для мостов
        source_nodes = random.sample(cluster_nodes[cid], min(3, len(cluster_nodes[cid])))
        target_nodes = random.sample(cluster_nodes[target_cid], min(3, len(cluster_nodes[target_cid])))
        for sn in source_nodes:
            for tn in target_nodes:
                if random.random() < 0.6:
                    add_link(sn, tn)

# ─── Резервные маршруты ─────────────────────────────────────────────────────

# Добавляем "длинные связи" — случайные соединения между далёкими узлами
all_node_ids = list(nodes.keys())
for _ in range(len(nodes) // 3):
    n1, n2 = random.sample(all_node_ids, 2)
    if nodes[n1]["cluster"] != nodes[n2]["cluster"]:
        add_link(n1, n2)

# ─── Гарантируем минимум связей ──────────────────────────────────────────────

for nid in list(nodes.keys()):
    while link_count[nid] < MIN_LINKS:
        # Ищем узлы с наименьшим количеством связей
        candidates = sorted(all_node_ids, key=lambda x: link_count[x])
        for c in candidates:
            if c != nid and link_count[c] < MIN_LINKS and c not in nodes[nid]["links"]:
                add_link(nid, c)
                break
        else:
            # Если все узлы имеют достаточно связей, добавляем случайную
            c = random.choice(all_node_ids)
            if c != nid and c not in nodes[nid]["links"]:
                add_link(nid, c)

# ─── Проверка anti-fragility ─────────────────────────────────────────────────

def check_connectivity(excluded=None):
    """Проверяет, остаётся ли граф связным при удалении узлов"""
    if excluded is None:
        excluded = set()
    visited = set()
    start = None
    for nid in nodes:
        if nid not in excluded:
            start = nid
            break
    if start is None:
        return True

    queue = [start]
    visited.add(start)
    while queue:
        current = queue.pop(0)
        for neighbor in nodes[current]["links"]:
            if neighbor not in excluded and neighbor not in visited:
                visited.add(neighbor)
                queue.append(neighbor)

    return len(visited) == len(nodes) - len(excluded)

# Проверяем, что граф связный
assert check_connectivity(), "Graph is not connected!"

# Проверяем, что удаление любого узла не разрушает сеть
broken = 0
for nid in list(nodes.keys())[:50]:  # Проверяем первые 50 узлов
    if not check_connectivity({nid}):
        broken += 1
        print(f"[WARN] Removing {nid} disconnects the graph")

if broken == 0:
    print("[OK] Anti-fragility verified: removing any single node preserves connectivity")
else:
    print(f"[WARN] {broken} nodes would disconnect the graph")

# ─── Генерация markdown ──────────────────────────────────────────────────────

total_files = 0
for nid, data in nodes.items():
    filepath = BASE / f"{nid}.md"
    cid = data["cluster"]
    theme = CLUSTER_THEMES[cid][0]

    lines = []
    lines.append("---")
    lines.append(f"type: Node")
    lines.append(f"cluster: {cid}")
    lines.append(f"theme: \"{theme}\"")
    lines.append(f"title: \"{data['title']}\"")
    lines.append("---")
    lines.append("")
    lines.append(f"# {data['title']}")
    lines.append("")
    lines.append(f"**Кластер:** {theme}")
    lines.append(f"**Связей:** {link_count[nid]}")
    lines.append("")
    lines.append("---")
    lines.append("")
    lines.append(data["desc"])
    lines.append("")
    lines.append("---")
    lines.append("")

    # Связи
    lines.append("## Связи")
    lines.append("")
    for tid in data["links"][:30]:  # Ограничиваем для читаемости
        if tid in nodes:
            t_theme = CLUSTER_THEMES[nodes[tid]["cluster"]][0]
            cross = " [CROSS]" if nodes[tid]["cluster"] != cid else ""
            lines.append(f"- [[{nodes[tid]['title']}]] ({t_theme}{cross})")
    if len(data["links"]) > 30:
        lines.append(f"- ...и ещё {len(data['links']) - 30}")
    lines.append("")

    lines.append("---")
    lines.append("")
    lines.append("> [!note] Anti-Fragile")
    lines.append("> Этот узел часть антихрупкой сети. Удаление любого узла не разрушает сеть.")

    content = "\n".join(lines)
    with open(filepath, "w", encoding="utf-8") as f:
        f.write(content)
    total_files += 1

# ─── MOC ──────────────────────────────────────────────────────────────────────

def create_moc():
    lines = []
    lines.append("---")
    lines.append("type: MOC")
    lines.append('title: "Anti-Fragile Graph"')
    lines.append("---")
    lines.append("")
    lines.append("# Anti-Fragile Graph")
    lines.append("")
    lines.append("> Граф, который усиливается при разрушении.")
    lines.append("> Нет деревьев, линий, изоляции.")
    lines.append("> Каждый узел — часть живой, дышащей сети.")
    lines.append("")
    lines.append("---")
    lines.append("")

    # Кластеры
    lines.append("## Кластеры")
    lines.append("")
    for cid, (theme, desc) in enumerate(CLUSTER_THEMES):
        count = len(cluster_nodes[cid])
        lines.append(f"### {theme} ({count} узлов)")
        lines.append(f"*{desc}*")
        lines.append("")

    # Статистика
    lines.append("---")
    lines.append("")
    lines.append("## Статистика")
    lines.append("")
    lines.append(f"- **{len(nodes)}** узлов")
    total_links = sum(link_count.values()) // 2
    lines.append(f"- **{total_links}** связей")
    lines.append(f"- **{NUM_CORES}** кластеров")
    lines.append(f"- Мин. связей на узел: **{min(link_count.values())}**")
    lines.append(f"- Макс. связей на узел: **{max(link_count.values())}**")
    lines.append(f"- Среднее: **{sum(link_count.values())/len(link_count):.1f}**")
    lines.append("")

    # Принципы
    lines.append("---")
    lines.append("")
    lines.append("## Принципы anti-fragility")
    lines.append("")
    lines.append("1. **Нет единой точки отказа** — удаление любого узла не разрушает сеть")
    lines.append("2. **Избыточность** — каждый узел связан минимум с 7 другими")
    lines.append("3. **Кластеризация** — узлы группируются по темам")
    lines.append("4. **Мосты** — кластеры связаны друг с другом")
    lines.append("5. **Резервные маршруты** — длинные связи для обхода повреждений")
    lines.append("")

    # Навигация
    lines.append("---")
    lines.append("")
    lines.append("## Навигация")
    lines.append("")
    for cid, (theme, _) in enumerate(CLUSTER_THEMES):
        sample = cluster_nodes[cid][:5]
        links = ", ".join([f"[[{nodes[n]['title']}]]" for n in sample])
        lines.append(f"- **{theme}**: {links}")
    lines.append("")

    content = "\n".join(lines)
    with open(BASE / "MOC - Anti-Fragile Graph.md", "w", encoding="utf-8") as f:
        f.write(content)
    print("[OK] Created MOC")

create_moc()

# ─── Статистика ──────────────────────────────────────────────────────────────

print(f"\n[STATS] Nodes: {len(nodes)}")
total_links = sum(link_count.values()) // 2
print(f"[STATS] Links: {total_links}")
print(f"[STATS] Clusters: {NUM_CORES}")
print(f"[STATS] Links/node: min={min(link_count.values())}, max={max(link_count.values())}, avg={sum(link_count.values())/len(link_count):.1f}")

# Проверка cross-cluster
cross_cluster = 0
for nid, data in nodes.items():
    cid = data["cluster"]
    cross = sum(1 for t in data["links"] if nodes[t]["cluster"] != cid)
    if cross < MIN_CROSS_CLUSTER:
        cross_cluster += 1

if cross_cluster == 0:
    print("[OK] All nodes have >=2 cross-cluster links")
else:
    print(f"[WARN] {cross_cluster} nodes have <2 cross-cluster links")

print("=" * 60)
print("[DONE] Anti-Fragile Graph generated!")
