#!/usr/bin/env python3
"""Neural Knowledge Network — граф как биологическая нейронная сеть"""
import os
import random
import sys
import math
from pathlib import Path
from collections import defaultdict

sys.stdout.reconfigure(encoding='utf-8')
random.seed(42)

BASE = Path(r"C:\obsidian\Main\KnowledgeGraphs\NeuralNetwork")

# ─── Конфигурация ────────────────────────────────────────────────────────────

NUM_NODES = 3000
TARGET_EDGES = 25000
NUM_CLUSTERS = 15
HUB_RATIO = 0.02  # 2% хабов
MINI_HUB_RATIO = 0.08  # 8% мини-хабов

# Размеры кластеров (нормальное распределение)
CLUSTER_SIZES = [random.randint(150, 300) for _ in range(NUM_CLUSTERS)]
# Корректируем до NUM_NODES
diff = NUM_NODES - sum(CLUSTER_SIZES)
for i in range(abs(diff)):
    CLUSTER_SIZES[i % NUM_CLUSTERS] += 1 if diff > 0 else -1

# ─── Позиционирование (для красивого graph view) ────────────────────────────

# Кластеры располагаются по кругу
cluster_positions = []
for i in range(NUM_CLUSTERS):
    angle = 2 * math.pi * i / NUM_CLUSTERS
    radius = 400
    x = radius * math.cos(angle)
    y = radius * math.sin(angle)
    cluster_positions.append((x, y))

# ─── Создание узлов ──────────────────────────────────────────────────────────

nodes = {}  # id -> {cluster, x, y, type, links, title}
link_count = defaultdict(int)
cluster_members = defaultdict(list)
node_counter = 0

def create_node(cluster_id, x, y, node_type="regular"):
    global node_counter
    node_counter += 1
    nid = f"n{node_counter:04d}"
    nodes[nid] = {
        "cluster": cluster_id,
        "x": x + random.gauss(0, 50),
        "y": y + random.gauss(0, 50),
        "type": node_type,
        "links": [],
        "title": f"Neuron_{node_counter}",
    }
    cluster_members[cluster_id].append(nid)
    return nid

def add_link(s, t):
    if s == t:
        return
    if t in nodes[s]["links"]:
        return
    nodes[s]["links"].append(t)
    nodes[t]["links"].append(s)
    link_count[s] += 1
    link_count[t] += 1

# Создаём кластеры
all_node_ids = []
for cid in range(NUM_CLUSTERS):
    cx, cy = cluster_positions[cid]
    size = CLUSTER_SIZES[cid]

    # Определяем типы узлов в кластере
    num_hubs = max(1, int(size * HUB_RATIO))
    num_mini_hubs = max(2, int(size * MINI_HUB_RATIO))
    num_regular = size - num_hubs - num_mini_hubs

    # Создаём узлы
    cluster_hubs = []
    for i in range(num_hubs):
        nid = create_node(cid, cx, cy, "hub")
        cluster_hubs.append(nid)
        all_node_ids.append(nid)

    cluster_mini_hubs = []
    for i in range(num_mini_hubs):
        nid = create_node(cid, cx, cy, "mini_hub")
        cluster_mini_hubs.append(nid)
        all_node_ids.append(nid)

    for i in range(num_regular):
        nid = create_node(cid, cx, cy, "regular")
        all_node_ids.append(nid)

# ─── Локальные связи (внутри кластера) ───────────────────────────────────────

for cid in range(NUM_CLUSTERS):
    members = cluster_members[cid]
    hubs = [n for n in members if nodes[n]["type"] == "hub"]
    mini_hubs = [n for n in members if nodes[n]["type"] == "mini_hub"]
    regulars = [n for n in members if nodes[n]["type"] == "regular"]

    # Хабы связаны со всеми мини-хабами
    for h in hubs:
        for mh in mini_hubs:
            add_link(h, mh)

    # Мини-хабы связаны с 30-50% регулярных узлов
    for mh in mini_hubs:
        targets = random.sample(regulars, min(int(len(regulars) * 0.4), len(regulars)))
        for r in targets:
            add_link(mh, r)

    # Регулярные узлы связаны с 2-4 соседями
    for i, r in enumerate(regulars):
        num_local = random.randint(2, min(4, len(regulars) - 1))
        start = max(0, i - num_local // 2)
        end = min(len(regulars), i + num_local // 2 + 1)
        for j in range(start, end):
            if j != i:
                add_link(r, regulars[j])

# ─── Межкластерные связи (дальние связи) ────────────────────────────────────

# Каждый кластер связан со всеми другими через хабы
for cid1 in range(NUM_CLUSTERS):
    for cid2 in range(cid1 + 1, NUM_CLUSTERS):
        hubs1 = [n for n in cluster_members[cid1] if nodes[n]["type"] == "hub"]
        hubs2 = [n for n in cluster_members[cid2] if nodes[n]["type"] == "hub"]

        # Хабы связаны с хабами других кластеров
        for h1 in hubs1:
            for h2 in hubs2:
                if random.random() < 0.3:
                    add_link(h1, h2)

        # Некоторые мини-хабы связаны с мини-хабами других кластеров
        mh1 = [n for n in cluster_members[cid1] if nodes[n]["type"] == "mini_hub"]
        mh2 = [n for n in cluster_members[cid2] if nodes[n]["type"] == "mini_hub"]
        for m1 in mh1[:3]:
            for m2 in mh2[:3]:
                if random.random() < 0.15:
                    add_link(m1, m2)

# ─── Случайные дальние связи ─────────────────────────────────────────────────

# Добавляем случайные связи для "длинных аксонов"
current_edges = sum(link_count.values()) // 2
edges_to_add = TARGET_EDGES - current_edges

for _ in range(edges_to_add):
    n1 = random.choice(all_node_ids)
    # Предпочитаем узлы из разных кластеров
    candidates = [n for n in all_node_ids if nodes[n]["cluster"] != nodes[n1]["cluster"]]
    if candidates:
        n2 = random.choice(candidates)
        add_link(n1, n2)

# ─── Гарантируем 3-12 связей ────────────────────────────────────────────────

for nid in all_node_ids:
    while link_count[nid] < 3:
        # Находим узел с наименьшим количеством связей
        candidates = sorted(all_node_ids, key=lambda x: link_count[x])
        for c in candidates:
            if c != nid and c not in nodes[nid]["links"]:
                add_link(nid, c)
                break
    while link_count[nid] > 12:
        # Удаляем лишние связи (самые длинные)
        if nodes[nid]["links"]:
            removed = nodes[nid]["links"].pop()
            nodes[removed]["links"].remove(nid)
            link_count[nid] -= 1
            link_count[removed] -= 1

# ─── Генерация markdown ──────────────────────────────────────────────────────

total_files = 0
for nid, data in nodes.items():
    filepath = BASE / f"{nid}.md"

    lines = []
    lines.append("---")
    lines.append(f"type: Neuron")
    lines.append(f"cluster: {data['cluster']}")
    lines.append(f"neuron_type: {data['type']}")
    lines.append(f"x: {data['x']:.1f}")
    lines.append(f"y: {data['y']:.1f}")
    lines.append(f"title: \"{data['title']}\"")
    lines.append("---")
    lines.append("")
    lines.append(f"# {data['title']}")
    lines.append("")
    lines.append(f"**Тип:** {data['type']}")
    lines.append(f"**Кластер:** {data['cluster']}")
    lines.append(f"**Связей:** {link_count[nid]}")
    lines.append("")
    lines.append("---")
    lines.append("")

    # Связи (ограничиваем для читаемости)
    lines.append("## Связи")
    lines.append("")
    for tid in data["links"][:20]:
        if tid in nodes:
            t = nodes[tid]
            same = " [local]" if t["cluster"] == data["cluster"] else " [long-range]"
            lines.append(f"- [[{t['title']}]] ({t['type']}{same})")
    if len(data["links"]) > 20:
        lines.append(f"- ...и ещё {len(data['links']) - 20}")
    lines.append("")

    lines.append("---")
    lines.append("")
    lines.append("> [!note] Neuron")
    lines.append(f"> Этот узел — нейрон в сети из {len(nodes)} нейронов.")

    content = "\n".join(lines)
    with open(filepath, "w", encoding="utf-8") as f:
        f.write(content)
    total_files += 1

# ─── MOC ──────────────────────────────────────────────────────────────────────

def create_moc():
    lines = []
    lines.append("---")
    lines.append("type: MOC")
    lines.append('title: "Neural Knowledge Network"')
    lines.append("---")
    lines.append("")
    lines.append("# Neural Knowledge Network")
    lines.append("")
    lines.append("> Граф знаний, похожий на биологическую нейронную сеть.")
    lines.append("> 3000 нейронов, 25000+ связей, 15 кластеров.")
    lines.append("")
    lines.append("---")
    lines.append("")

    # Кластеры
    lines.append("## Кластеры (наборы нейронов)")
    lines.append("")
    for cid in range(NUM_CLUSTERS):
        count = len(cluster_members[cid])
        hubs = len([n for n in cluster_members[cid] if nodes[n]["type"] == "hub"])
        mini_hubs = len([n for n in cluster_members[cid] if nodes[n]["type"] == "mini_hub"])
        regulars = count - hubs - mini_hubs
        lines.append(f"- **Кластер {cid}**: {count} нейронов ({hubs} хабов, {mini_hubs} мини-хабов, {regulars} регулярных)")
    lines.append("")

    # Типы нейронов
    lines.append("---")
    lines.append("")
    lines.append("## Типы нейронов")
    lines.append("")
    lines.append("- **Hub** — центральный узел кластера, связан со всеми мини-хабами")
    lines.append("- **Mini-hub** — промежуточный узел, связывает хабы с регулярными")
    lines.append("- **Regular** — обычный нейрон, связан с 3-12 соседями")
    lines.append("")

    # Статистика
    lines.append("---")
    lines.append("")
    lines.append("## Статистика")
    lines.append("")
    lines.append(f"- **{len(nodes)}** нейронов")
    total_links = sum(link_count.values()) // 2
    lines.append(f"- **{total_links}** связей")
    lines.append(f"- **{NUM_CLUSTERS}** кластеров")
    lines.append(f"- Среднее связей/нейрон: **{sum(link_count.values())/len(link_count):.1f}**")
    lines.append("")

    # Визуальная карта
    lines.append("---")
    lines.append("")
    lines.append("## Визуальная карта")
    lines.append("")
    lines.append("```")
    lines.append("              [0]")
    lines.append("            /  |  \\")
    lines.append("        [14]--[1]--[2]")
    lines.append("       / |    |    | \\")
    lines.append("   [13]-+----+----+-[3]")
    lines.append("   |   / \\  / \\  / \\   |")
    lines.append("  [12]+---[7]--[4]+---[4]")
    lines.append("   |   \\ /  \\ /  \\ /   |")
    lines.append("   [11]-+----+----+-[5]")
    lines.append("       \\ |    |    | /")
    lines.append("        [10]--[6]--[6]")
    lines.append("            \\  |  /")
    lines.append("              [8]")
    lines.append("```")
    lines.append("")

    content = "\n".join(lines)
    with open(BASE / "MOC - Neural Network.md", "w", encoding="utf-8") as f:
        f.write(content)
    print("[OK] Created MOC")

create_moc()

# ─── Статистика ──────────────────────────────────────────────────────────────

print(f"\n[STATS] Nodes: {len(nodes)}")
total_links = sum(link_count.values()) // 2
print(f"[STATS] Links: {total_links}")
print(f"[STATS] Clusters: {NUM_CLUSTERS}")

# Распределение по типам
types = defaultdict(int)
for nid, data in nodes.items():
    types[data["type"]] += 1
for t, c in sorted(types.items()):
    print(f"[STATS] {t}: {c}")

# Распределение по связям
link_dist = defaultdict(int)
for nid in all_node_ids:
    link_dist[link_count[nid]] += 1
print("[STATS] Link distribution:")
for lc in sorted(link_dist.keys()):
    print(f"  {lc} links: {link_dist[lc]} nodes")

print("=" * 60)
print("[DONE] Neural Knowledge Network generated!")
