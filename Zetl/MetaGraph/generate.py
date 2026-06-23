"""MetaGraph Generator — создаёт систему из 150+ заметок в Obsidian."""
import os

BASE = r"C:\obsidian\Main\Zetl\MetaGraph"
DIRS = ["Graphs", "Bridges", "Gateways", "Clusters", "Routes", "Hubs"]

GRAPHS = [
    ("Knowledge", "Граф знаний — структура всех накопленных знаний"),
    ("KnowledgeGalaxy", "Галактика знаний — расширенная карта знаний"),
    ("DecisionMakingGraph", "Граф принятия решений"),
    ("DecisionMaze", "Лабиринт решений — сложные ветвления выбора"),
    ("BiasGraph", "Граф когнитивных искажений"),
    ("ConflictGraph", "Граф конфликтов"),
    ("PersonalityGraph", "Граф личности"),
    ("CausalLoop", "Петли причинно-следственных связей"),
    ("WorldModelGraph", "Мировая модель — карта реальности"),
    ("IntellectualNetwork", "Интеллектуальная сеть"),
    ("IdeaEcosystem", "Экосистема идей"),
    ("QuestionFractal", "Фрактал вопросов — бесконечная иерархия вопросов"),
    ("GameSystem", "Игровая система"),
    ("ShadowValueSystem", "Система теневых ценностей"),
    ("LabyrinthGraph", "Граф лабиринтов"),
    ("FractalGraph", "Фрактальный граф"),
    ("ParadoxGraph", "Граф парадоксов"),
    ("MythologyGraph", "Граф мифологии"),
    ("DreamscapeGraph", "Граф сновидений"),
    ("ConstellationGraph", "Граф созвездий"),
    ("SystemsGraph", "Граф систем"),
    ("EvolutionGraph", "Граф эволюции"),
    ("MetaGraph", "Мета-граф — граф графов"),
]

BRIDGES_DATA = [
    ("KnowledgeBridge", "Knowledge", "KnowledgeGalaxy", "Мост между базовым и расширенным графом знаний"),
    ("DecisionBridge", "DecisionMakingGraph", "DecisionMaze", "Связь между теорией и практикой решений"),
    ("BiasPersonalityBridge", "BiasGraph", "PersonalityGraph", "Искажения формируют личность"),
    ("ConflictShadowBridge", "ConflictGraph", "ShadowValueSystem", "Конфликт порождает теневые ценности"),
    ("CausalSystemBridge", "CausalLoop", "SystemsGraph", "Причинные петли — основа системного мышления"),
    ("SystemWorldBridge", "SystemsGraph", "WorldModelGraph", "Системы описывают модель мира"),
    ("IdeaEvolutionBridge", "IdeaEcosystem", "EvolutionGraph", "Идеи эволюционируют"),
    ("EvolutionWorldBridge", "EvolutionGraph", "WorldModelGraph", "Эволюция формирует реальность"),
    ("QuestionKnowledgeBridge", "QuestionFractal", "Knowledge", "Вопросы порождают знания"),
    ("KnowledgeDecisionBridge", "Knowledge", "DecisionMaze", "Знания ведут к решениям"),
    ("PersonalityDecisionBridge", "PersonalityGraph", "DecisionMaze", "Личность определяет выбор"),
    ("ShadowPersonalityBridge", "ShadowValueSystem", "PersonalityGraph", "Тени скрыты в личности"),
    ("GameSystemBridge", "GameSystem", "SystemsGraph", "Игры — частный случай систем"),
    ("ParadoxKnowledgeBridge", "ParadoxGraph", "Knowledge", "Парадоксы расширяют знания"),
    ("MythologyWorldBridge", "MythologyGraph", "WorldModelGraph", "Мифы формируют модель мира"),
    ("DreamscapeParadoxBridge", "DreamscapeGraph", "ParadoxGraph", "Сны нарушают логику"),
    ("ConstellationIdeaBridge", "ConstellationGraph", "IdeaEcosystem", "Созвездия идей"),
    ("FractalQuestionBridge", "FractalGraph", "QuestionFractal", "Фрактальная структура вопросов"),
    ("LabyrinthDecisionBridge", "LabyrinthGraph", "DecisionMaze", "Лабиринт как метафора выбора"),
    ("IntellectualKnowledgeBridge", "IntellectualNetwork", "Knowledge", "Интеллектуальная сеть знаний"),
    ("BiasDecisionBridge", "BiasGraph", "DecisionMaze", "Искажения искажают решения"),
    ("ConflictDecisionBridge", "ConflictGraph", "DecisionMakingGraph", "Конфликт как источник решений"),
    ("CausalKnowledgeBridge", "CausalLoop", "Knowledge", "Причинные связи — основа знаний"),
    ("MetaAllBridge", "MetaGraph", "Knowledge", "Мета-граф охватывает всё"),
    ("WorldConstellationBridge", "WorldModelGraph", "ConstellationGraph", "Мир как созвездие"),
    ("SystemsEvolutionBridge", "SystemsGraph", "EvolutionGraph", "Системы эволюционируют"),
    ("GameConflictBridge", "GameSystem", "ConflictGraph", "Игра как модель конфликта"),
    ("DreamscapeMythBridge", "DreamscapeGraph", "MythologyGraph", "Сны — источник мифов"),
    ("FractalLabyrinthBridge", "FractalGraph", "LabyrinthGraph", "Фрактальные лабиринты"),
    ("ParadoxShadowBridge", "ParadoxGraph", "ShadowValueSystem", "Парадоксы теней"),
    ("IdeaKnowledgeBridge", "IdeaEcosystem", "Knowledge", "Идеи обогащают знания"),
    ("EvolutionPersonalityBridge", "EvolutionGraph", "PersonalityGraph", "Эволюция личности"),
    ("SystemWorldBridge2", "SystemsGraph", "WorldModelGraph", "Системы моделируют мир"),
    ("ConstellationKnowledgeBridge", "ConstellationGraph", "Knowledge", "Созвездия знаний"),
    ("MetaSystemBridge", "MetaGraph", "SystemsGraph", "Мета-граф и системы"),
]

GATEWAYS_DATA = [
    ("GatewayEntrance", "Вход в систему MetaGraph — начни здесь"),
    ("GatewayQuestions", "Вход через вопросы — начни с сомнений"),
    ("GatewayProblems", "Вход через проблемы — начни с боли"),
    ("GatewayCuriosity", "Вход через любопытство — начни с интереса"),
    ("GatewayDecisions", "Вход через решения — начни с выбора"),
    ("GatewayConflict", "Вход через конфликт — начни с напряжения"),
    ("GatewayDreams", "Вход через сны — начни с подсознания"),
    ("GatewayIdeas", "Вход через идеи — начни с вдохновения"),
    ("GatewayBias", "Вход через искажения — начни с осознания"),
    ("GatewayMythology", "Вход через мифологию — начни с историй"),
    ("GatewaySystems", "Вход через системы — начни со структуры"),
    ("GatewayEvolution", "Вход через эволюцию — начни с роста"),
    ("GatewayParadox", "Вход через парадокс — начни с противоречия"),
    ("GatewayFractal", "Вход через фрактал — начни с паттерна"),
    ("GatewayLabyrinth", "Вход через лабиринт — начни с блуждания"),
    ("GatewayConstellation", "Вход через созвездия — начни с связей"),
    ("GatewayWorld", "Вход через модель мира — начни с реальности"),
    ("GatewayShadow", "Вход через тени — начни со скрытого"),
    ("GatewayGame", "Вход через игру — начни с эксперимента"),
    ("GatewayIntellectual", "Вход через интеллект — начни с анализа"),
]

CLUSTERS_DATA = [
    ("ClusterCognition", "Кластер познания", ["Knowledge", "KnowledgeGalaxy", "IntellectualNetwork", "QuestionFractal", "FractalGraph"], "Графы познавательной деятельности"),
    ("ClusterDecision", "Кластер решений", ["DecisionMakingGraph", "DecisionMaze", "BiasGraph", "PersonalityGraph"], "Графы принятия решений"),
    ("ClusterSystem", "Кластер систем", ["SystemsGraph", "CausalLoop", "WorldModelGraph", "EvolutionGraph"], "Системные графы"),
    ("ClusterConflict", "Кластер конфликтов", ["ConflictGraph", "ShadowValueSystem", "ParadoxGraph", "LabyrinthGraph"], "Графы напряжения и противоречий"),
    ("ClusterCreativity", "Кластер творчества", ["IdeaEcosystem", "DreamscapeGraph", "MythologyGraph", "ConstellationGraph"], "Графы творческого мышления"),
    ("ClusterMeta", "Кластер мета-уровня", ["MetaGraph", "FractalGraph", "ParadoxGraph", "LabyrinthGraph"], "Мета-графы — графы о графах"),
    ("ClusterDeep", "Кластер глубин", ["ShadowValueSystem", "DreamscapeGraph", "MythologyGraph", "ParadoxGraph"], "Глубинные графы"),
    ("ClusterPractical", "Кластер практичного", ["DecisionMaze", "GameSystem", "SystemsGraph", "Knowledge"], "Прикладные графы"),
    ("ClusterAbstract", "Кластер абстрактного", ["FractalGraph", "ParadoxGraph", "ConstellationGraph", "QuestionFractal"], "Абстрактные графы"),
    ("ClusterEvolution", "Кластер эволюции", ["EvolutionGraph", "WorldModelGraph", "SystemsGraph", "IdeaEcosystem"], "Графы роста и трансформации"),
    ("ClusterPersonality", "Кластер личности", ["PersonalityGraph", "BiasGraph", "ShadowValueSystem", "DecisionMaze"], "Графы самопознания"),
    ("ClusterKnowledge", "Кластер знаний", ["Knowledge", "KnowledgeGalaxy", "IntellectualNetwork", "IdeaEcosystem"], "Графы накопления знаний"),
    ("ClusterWorld", "Кластер мира", ["WorldModelGraph", "MythologyGraph", "ConstellationGraph", "SystemsGraph"], "Графы описания реальности"),
    ("ClusterFlow", "Кластер потока", ["LabyrinthGraph", "FractalGraph", "DreamscapeGraph", "QuestionFractal"], "Графы бесконечного движения"),
    ("ClusterLogic", "Кластер логики", ["CausalLoop", "SystemsGraph", "Knowledge", "DecisionMakingGraph"], "Логические графы"),
    ("ClusterEmotion", "Кластер эмоций", ["PersonalityGraph", "ConflictGraph", "DreamscapeGraph", "ShadowValueSystem"], "Эмоциональные графы"),
    ("ClusterStructure", "Кластер структуры", ["SystemsGraph", "FractalGraph", "ConstellationGraph", "MetaGraph"], "Структурные графы"),
    ("ClusterGrowth", "Кластер роста", ["EvolutionGraph", "Knowledge", "PersonalityGraph", "IdeaEcosystem"], "Графы развития"),
    ("ClusterMystery", "Кластер тайн", ["ShadowValueSystem", "ParadoxGraph", "DreamscapeGraph", "LabyrinthGraph"], "Графы тайного"),
    ("ClusterAction", "Кластер действия", ["DecisionMaze", "GameSystem", "ConflictGraph", "EvolutionGraph"], "Графы действия"),
    ("ClusterReflection", "Кластер рефлексии", ["MetaGraph", "QuestionFractal", "ParadoxGraph", "FractalGraph"], "Графы осмысления"),
    ("ClusterConnection", "Кластер связей", ["ConstellationGraph", "IntellectualNetwork", "IdeaEcosystem", "KnowledgeGalaxy"], "Графы связности"),
    ("ClusterFoundation", "Кластер основы", ["Knowledge", "CausalLoop", "SystemsGraph", "WorldModelGraph"], "Фундаментальные графы"),
    ("ClusterVision", "Кластер видения", ["WorldModelGraph", "ConstellationGraph", "DreamscapeGraph", "MetaGraph"], "Графы видения"),
    ("ClusterDepth", "Кластер глубины", ["LabyrinthGraph", "ShadowValueSystem", "ParadoxGraph", "MythologyGraph"], "Графы глубины"),
]

ROUTES_DATA = [
    ("RouteQuestionKnowledgeDecision", "Путь вопросов к решениям", "QuestionFractal → Knowledge → DecisionMaze", "От сомнений через понимание к выбору"),
    ("RouteBiasPersonalityDecision", "Путь искажений к личности", "BiasGraph → PersonalityGraph → DecisionMaze", "Искажения формируют личность, личность определяет выбор"),
    ("RouteIdeaEvolutionWorld", "Путь идей к миру", "IdeaEcosystem → EvolutionGraph → WorldModelGraph", "Идеи эволюционируют в модель мира"),
    ("RouteConflictShadowPersonality", "Путь конфликтов к теням", "ConflictGraph → ShadowValueSystem → PersonalityGraph", "Конфликт порождает тени, тени формируют личность"),
    ("RouteCausalSystemWorld", "Путь причин к миру", "CausalLoop → SystemsGraph → WorldModelGraph", "Причинные петли строят системы, системы описывают мир"),
    ("RouteKnowledgeGalaxyMeta", "Путь знаний к мета-уровню", "KnowledgeGalaxy → Knowledge → MetaGraph", "От галактики к ядру, от ядра к мета-уровню"),
    ("RouteDreamMythWorld", "Путь снов к миру", "DreamscapeGraph → MythologyGraph → WorldModelGraph", "Сны порождают мифы, мифы формируют мир"),
    ("RouteFractalLabyrinthDecision", "Путь фракталов к решениям", "FractalGraph → LabyrinthGraph → DecisionMaze", "Фрактальные паттерны ведут через лабиринт к выбору"),
    ("RouteParadoxKnowledge", "Путь парадоксов к знаниям", "ParadoxGraph → Knowledge → KnowledgeGalaxy", "Парадоксы расширяют горизонт знаний"),
    ("RouteSystemEvolutionWorld", "Путь систем к эволюции", "SystemsGraph → EvolutionGraph → WorldModelGraph", "Системы эволюционируют, формируя реальность"),
    ("RouteIntellectualBiasDecision", "Путь интеллекта к решениям", "IntellectualNetwork → BiasGraph → DecisionMaze", "Интеллект сталкивается с искажениями при выборе"),
    ("RouteGameConflictSystem", "Путь игр к конфликтам", "GameSystem → ConflictGraph → SystemsGraph", "Игры моделируют конфликты в системах"),
    ("RouteConstellationIdeaKnowledge", "Путь созвездий к идеям", "ConstellationGraph → IdeaEcosystem → Knowledge", "Созвездия связывают идеи в знания"),
    ("RouteShadowParadoxLabyrinth", "Путь теней к парадоксам", "ShadowValueSystem → ParadoxGraph → LabyrinthGraph", "Тени порождают парадоксы в лабиринтах"),
    ("RouteEvolutionPersonalityWorld", "Путь эволюции личности", "EvolutionGraph → PersonalityGraph → WorldModelGraph", "Эволюция личности формирует мир"),
    ("RouteCausalKnowledgeDecision", "Путь причин к решениям", "CausalLoop → Knowledge → DecisionMaze", "Понимание причин ведёт к осознанным решениям"),
    ("RouteMythDreamParadox", "Путь мифов к парадоксам", "MythologyGraph → DreamscapeGraph → ParadoxGraph", "Мифы и сны создают парадоксальные пространства"),
    ("RouteFractalMetaKnowledge", "Путь фракталов к мета-знаниям", "FractalGraph → MetaGraph → Knowledge", "Фрактальная структура ведёт к мета-пониманию"),
    ("RouteLabyrinthDecisionWorld", "Путь лабиринта к миру", "LabyrinthGraph → DecisionMaze → WorldModelGraph", "Прохождение лабиринта решений формирует мировоззрение"),
    ("RouteBiasConflictShadow", "Путь искажений к конфликтам", "BiasGraph → ConflictGraph → ShadowValueSystem", "Искажения усиливают конфликты и тени"),
    ("RouteIdeaFractalConstellation", "Путь идей к созвездиям", "IdeaEcosystem → FractalGraph → ConstellationGraph", "Идеи разрастаются фрактально в созвездия"),
    ("RoutePersonalityDreamShadow", "Путь личности к теням", "PersonalityGraph → DreamscapeGraph → ShadowValueSystem", "Глубины личности скрывают тени"),
    ("RouteSystemMetaEvolution", "Путь систем к мета-эволюции", "SystemsGraph → MetaGraph → EvolutionGraph", "Системы мета-эволюционируют"),
    ("RouteWorldConstellationKnowledge", "Путь мира к знаниям", "WorldModelGraph → ConstellationGraph → Knowledge", "Мир как созвездие знаний"),
    ("RouteConflictDecisionKnowledge", "Путь конфликтов к знаниям", "ConflictGraph → DecisionMakingGraph → Knowledge", "Конфликт как источник познания"),
    ("RouteDreamLabyrinthMyth", "Путь снов к мифологии", "DreamscapeGraph → LabyrinthGraph → MythologyGraph", "Сновидческие лабиринты становятся мифами"),
    ("RouteIntellectualSystemMeta", "Путь интеллекта к мета-системам", "IntellectualNetwork → SystemsGraph → MetaGraph", "Интеллектуальная сеть — фундамент мета-уровня"),
    ("RouteEvolutionBiasPersonality", "Путь эволюции искажений", "EvolutionGraph → BiasGraph → PersonalityGraph", "Эволюция искажений формирует личность"),
    ("RouteQuestionParadoxDecision", "Путь вопросов к парадоксам", "QuestionFractal → ParadoxGraph → DecisionMaze", "Вопросы порождают парадоксы, парадоксы — решения"),
    ("RouteShadowEvolutionWorld", "Путь теней к эволюции", "ShadowValueSystem → EvolutionGraph → WorldModelGraph", "Тени двигают эволюцию мира"),
    ("RouteCausalFractalSystem", "Путь причин к фракталам", "CausalLoop → FractalGraph → SystemsGraph", "Причинные петли — фрактальная основа систем"),
    ("RouteGamePersonalityDecision", "Путь игр к личности", "GameSystem → PersonalityGraph → DecisionMaze", "Игра раскрывает личность при выборе"),
    ("RouteMetaParadoxWorld", "Путь мета-парадоксов", "MetaGraph → ParadoxGraph → WorldModelGraph", "Мета-уровень содержит парадоксы мира"),
]

HUBS_DATA = [
    ("HubKnowledge", "Центр знаний", ["Knowledge", "KnowledgeGalaxy", "IntellectualNetwork", "IdeaEcosystem"], "Объединяет все формы знания"),
    ("HubDecision", "Центр решений", ["DecisionMakingGraph", "DecisionMaze", "BiasGraph", "PersonalityGraph"], "Точка принятия всех решений"),
    ("HubSystem", "Центр систем", ["SystemsGraph", "CausalLoop", "WorldModelGraph", "EvolutionGraph"], "Системный стержень графа"),
    ("HubConflict", "Центр конфликтов", ["ConflictGraph", "ShadowValueSystem", "ParadoxGraph", "LabyrinthGraph"], "Узел всех противоречий"),
    ("HubCreativity", "Центр творчества", ["IdeaEcosystem", "DreamscapeGraph", "MythologyGraph", "ConstellationGraph"], "Источник нового"),
    ("HubMeta", "Центр мета-уровня", ["MetaGraph", "FractalGraph", "QuestionFractal", "LabyrinthGraph"], "Точка над系统的 точка"),
    ("HubWorld", "Центр мира", ["WorldModelGraph", "ConstellationGraph", "MythologyGraph", "SystemsGraph"], "Модель реальности"),
    ("HubPersonality", "Центр личности", ["PersonalityGraph", "BiasGraph", "ShadowValueSystem", "DreamscapeGraph"], "Глубины Я"),
    ("HubEvolution", "Центр эволюции", ["EvolutionGraph", "IdeaEcosystem", "SystemsGraph", "WorldModelGraph"], "Движение вперёд"),
    ("HubParadox", "Центр парадоксов", ["ParadoxGraph", "FractalGraph", "LabyrinthGraph", "ShadowValueSystem"], "Противоречия как двигатель"),
    ("HubFlow", "Центр потока", ["QuestionFractal", "FractalGraph", "LabyrinthGraph", "DreamscapeGraph"], "Бесконечное движение"),
    ("HubStructure", "Центр структуры", ["SystemsGraph", "CausalLoop", "FractalGraph", "ConstellationGraph"], "Архитектура графа"),
    ("HubDeep", "Центр глубин", ["ShadowValueSystem", "MythologyGraph", "DreamscapeGraph", "ParadoxGraph"], "Скрытые слои"),
    ("HubPractical", "Центр практики", ["DecisionMaze", "GameSystem", "ConflictGraph", "Knowledge"], "Прикладная точка"),
    ("HubAbstract", "Центр абстракций", ["FractalGraph", "ParadoxGraph", "ConstellationGraph", "MetaGraph"], "Высший уровень обобщения"),
    ("HubConnection", "Центр связей", ["ConstellationGraph", "IntellectualNetwork", "IdeaEcosystem", "KnowledgeGalaxy"], "Нейронная сеть графа"),
    ("HubGrowth", "Центр роста", ["EvolutionGraph", "Knowledge", "PersonalityGraph", "IdeaEcosystem"], "Точка трансформации"),
    ("HubMystery", "Центр тайн", ["ShadowValueSystem", "DreamscapeGraph", "MythologyGraph", "ParadoxGraph"], "Неизведанное"),
    ("HubAction", "Центр действия", ["DecisionMaze", "GameSystem", "ConflictGraph", "SystemsGraph"], "Точка действия"),
    ("HubReflection", "Центр рефлексии", ["MetaGraph", "QuestionFractal", "ParadoxGraph", "MetaGraph"], "Осмысление системы"),
]


def ensure_dirs():
    for d in DIRS:
        os.makedirs(os.path.join(BASE, d), exist_ok=True)


def write_note(subdir, name, content):
    path = os.path.join(BASE, subdir, f"{name}.md")
    with open(path, "w", encoding="utf-8") as f:
        f.write(content)


def gen_graph(name, desc):
    connected = [b[2] for b in BRIDGES_DATA if b[1] == name] + [b[1] for b in BRIDGES_DATA if b[2] == name]
    clusters = [c[0] for c in CLUSTERS_DATA if name in c[2]]
    routes = [r[0] for r in ROUTES_DATA if name in r[2]]
    hubs = [h[0] for h in HUBS_DATA if name in h[2]]

    links = "\n".join(f"    - [[{c}]]" for c in clusters) if clusters else "    - Нет"
    route_links = "\n".join(f"    - [[{r}]]" for r in routes) if routes else "    - Нет"
    hub_links = "\n".join(f"    - [[{h}]]" for h in hubs) if hubs else "    - Нет"
    connected_links = "\n".join(f"    - [[{c}]]" for c in connected) if connected else "    - Нет"

    return f"""---
type: graph
tags: [meta, graph]
---
# {name}
{desc}

## Назначение
Основной граф в системе MetaGraph. Соединён с другими графами через мосты и маршруты.

## Маршруты
{route_links}

## Связи
### Через мосты
{connected_links}

### Кластеры
{links}

### Хабы
{hub_links}
"""


def gen_bridge(name, g1, g2, desc):
    clusters = [c[0] for c in CLUSTERS_DATA if g1 in c[2] and g2 in c[2]]
    links = "\n".join(f"    - [[{c}]]" for c in clusters) if clusters else "    - Нет"

    return f"""---
type: bridge
tags: [meta, bridge]
---
# {name}
{desc}

## Назначение
Связывает [[{g1}]] с [[{g2}]].

## Маршруты
    - {g1} → {g2}
    - {g2} → {g1}

## Связи
    - [[{g1}]]
    - [[{g2}]]
{links}
"""


def gen_gateway(name, desc):
    return f"""---
type: gateway
tags: [meta, gateway]
---
# {name}
{desc}

## Назначение
Точка входа в систему MetaGraph. Один из способов начать исследование.

## Маршруты
    - Начало маршрута
    - Любой граф как следующий шаг

## Связи
    - [[MetaGraph]]
    - [[Knowledge]]
    - [[DecisionMaze]]
"""


def gen_cluster(name, title, members, desc):
    member_links = "\n".join(f"    - [[{m}]]" for m in members)
    return f"""---
type: cluster
tags: [meta, cluster]
---
# {title}
{desc}

## Назначение
Группирует связанные графы в осмысленную структуру.

## Маршруты
    - Через любой из участников

## Связи
{member_links}
"""


def gen_route(name, title, path_str, desc):
    return f"""---
type: route
tags: [meta, route]
---
# {title}
{desc}

## Назначение
Маршрут через систему MetaGraph. Путь от начальной точки к конечной.

## Маршруты
    - {path_str}

## Связи
    - [[MetaGraph]]
    - См. путь выше
"""


def gen_hub(name, title, members, desc):
    member_links = "\n".join(f"    - [[{m}]]" for m in members)
    return f"""---
type: hub
tags: [meta, hub]
---
# {title}
{desc}

## Назначение
Центральный узел, объединяющий несколько графов. Точка пересечения маршрутов.

## Маршруты
    - Через любой из участников

## Связи
{member_links}
"""


def gen_moc_metagraph():
    graph_links = "\n".join(f"    - [[{g[0]}]] — {g[1]}" for g in GRAPHS)
    bridge_links = "\n".join(f"    - [[{b[0]}]] ({b[1]} ↔ {b[2]})" for b in BRIDGES_DATA)
    gateway_links = "\n".join(f"    - [[{g[0]}]] — {g[1]}" for g in GATEWAYS_DATA)
    cluster_links = "\n".join(f"    - [[{c[0]}]] — {c[1]}" for c in CLUSTERS_DATA)
    route_links = "\n".join(f"    - [[{r[0]}]] — {r[1]}" for r in ROUTES_DATA)
    hub_links = "\n".join(f"    - [[{h[0]}]] — {h[1]}" for h in HUBS_DATA)

    return f"""---
type: moc
tags: [meta, moc]
---
# MOC MetaGraph
Карта системы MetaGraph — граф графов.

## Графы ({len(GRAPHS)})
{graph_links}

## Мосты ({len(BRIDGES_DATA)})
{bridge_links}

## Шлюзы ({len(GATEWAYS_DATA)})
{gateway_links}

## Кластеры ({len(CLUSTERS_DATA)})
{cluster_links}

## Маршруты ({len(ROUTES_DATA)})
{route_links}

## Хабы ({len(HUBS_DATA)})
{hub_links}

## Навигация
- [[MOC Global]] — глобальная карта
- [[Navigation]] — системная навигация
"""


def gen_moc_global():
    return f"""---
type: moc
tags: [meta, moc, global]
---
# MOC Global
Глобальная карта знаний MetaGraph.

## Система MetaGraph
- [[MetaGraph]] — ядро системы
- [[MOC MetaGraph]] — полная карта
- [[Navigation]] — навигация

## Кластеры знаний
- [[ClusterCognition]] — познание
- [[ClusterDecision]] — решения
- [[ClusterSystem]] — системы
- [[ClusterConflict]] — конфликты
- [[ClusterCreativity]] — творчество
- [[ClusterMeta]] — мета-уровень

## Ключевые маршруты
- [[RouteQuestionKnowledgeDecision]] — путь вопросов
- [[RouteCausalSystemWorld]] — путь причин
- [[RouteIdeaEvolutionWorld]] — путь идей

## Точки входа
- [[GatewayEntrance]] — основной вход
- [[GatewayQuestions]] — вход через вопросы
- [[GatewayProblems]] — вход через проблемы
"""


def gen_navigation():
    return f"""---
type: navigation
tags: [meta, navigation]
---
# Navigation
Системная навигация по MetaGraph.

## Как начать
1. [[GatewayEntrance]] — общий вход
2. Выберите интересующую область
3. Следуйте маршрутам

## По типу исследования
### Анализ
→ [[Knowledge]], [[IntellectualNetwork]], [[SystemsGraph]]

### Творчество
→ [[IdeaEcosystem]], [[DreamscapeGraph]], [[ConstellationGraph]]

### Понимание себя
→ [[PersonalityGraph]], [[BiasGraph]], [[ShadowValueSystem]]

### Понимание мира
→ [[WorldModelGraph]], [[MythologyGraph]], [[SystemsGraph]]

### Решения
→ [[DecisionMaze]], [[DecisionMakingGraph]], [[GameSystem]]

### Глубина
→ [[ParadoxGraph]], [[LabyrinthGraph]], [[FractalGraph]]

## По маршруту
- [[RouteQuestionKnowledgeDecision]]
- [[RouteBiasPersonalityDecision]]
- [[RouteIdeaEvolutionWorld]]
- [[RouteConflictShadowPersonality]]
- [[RouteCausalSystemWorld]]

## Связи
- [[MOC MetaGraph]]
- [[MOC Global]]
"""


def main():
    ensure_dirs()

    for name, desc in GRAPHS:
        write_note("Graphs", name, gen_graph(name, desc))

    for b in BRIDGES_DATA:
        write_note("Bridges", b[0], gen_bridge(*b))

    for g in GATEWAYS_DATA:
        write_note("Gateways", g[0], gen_gateway(*g))

    for c in CLUSTERS_DATA:
        write_note("Clusters", c[0], gen_cluster(*c))

    for r in ROUTES_DATA:
        write_note("Routes", r[0], gen_route(*r))

    for h in HUBS_DATA:
        write_note("Hubs", h[0], gen_hub(*h))

    write_note(".", "MOC MetaGraph", gen_moc_metagraph())
    write_note(".", "MOC Global", gen_moc_global())
    write_note(".", "Navigation", gen_navigation())

    total = len(GRAPHS) + len(BRIDGES_DATA) + len(GATEWAYS_DATA) + len(CLUSTERS_DATA) + len(ROUTES_DATA) + len(HUBS_DATA) + 3
    print(f"Создано {total} заметок в {BASE}")


if __name__ == "__main__":
    main()
