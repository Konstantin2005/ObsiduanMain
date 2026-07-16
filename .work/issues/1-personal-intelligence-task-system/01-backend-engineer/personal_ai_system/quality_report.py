#!/usr/bin/env python3
import sys
import os
import json
import re
from datetime import datetime
from collections import defaultdict

SEP = "=" * 70
SEP2 = "-" * 70

sys.path.insert(0, os.path.dirname(os.path.abspath(__file__)))


def load_json(path):
    with open(path, "r", encoding="utf-8") as f:
        return json.load(f)


def filter_quality_items(items):
    noise_patterns = [
        r"надо было", r"надо будет", r"надо же",
        r"должен был", r"хотел бы",
        r"может быть", r"could", r"might", r"maybe",
        r"мечтаю", r"хочу понять",
        r"просто", r"вообще",
        r"надо\s+просто", r"надо\s+же",
        r"потому что", r"как-то",
    ]
    keep = []
    ignored = []

    for item in items:
        title = item["title"].lower().strip()
        reason = item.get("reason", "").lower()

        # фильтр по длине
        if len(title) < 8:
            ignored.append({"title": item["title"], "reason": "Слишком короткий заголовок"})
            continue

        # фильтр по шумовым паттернам
        is_noise = False
        for pat in noise_patterns:
            if re.search(pat, title) or re.search(pat, reason):
                is_noise = True
                break
        if is_noise:
            ignored.append({"title": item["title"], "reason": "Шумовой паттерн (размышление, не задача)"})
            continue

        # фильтр: если title почти совпадает с reason content — слишком общий
        if item["type"] == "task":
            keep.append(item)
        elif item["type"] in ("idea", "goal") and item["confidence"] >= 55:
            keep.append(item)
        elif item["type"] == "problem" and item["confidence"] >= 60:
            keep.append(item)
        else:
            ignored.append({"title": item["title"], "reason": f"Низкий confidence для типа {item['type']}"})

    return keep, ignored


def group_by_topic(items):
    topics = defaultdict(list)
    topic_keywords = {
        "english": ["english", "translate", "language", "dialogues", "write.*english", "speak.*english"],
        "hike": ["поход", "маршрут", "плот", "река", "палатка", "еда", "инвентарь", "билеты", "клещ"],
        "move": ["переезд", "питер", "вещ", "продав", "список"],
        "obsidian": ["obsidian", "дневник", "заметк", "систем"],
        "java": ["java", "дедлайн", "проект", "технолог"],
        "mindset": ["мышлен", "проблем", "чистк", "мысл"],
        "social": ["люд", "сообществ", "занят"],
    }

    for item in items:
        title_lower = item["title"].lower()
        matched = False
        for topic, kws in topic_keywords.items():
            for kw in kws:
                if re.search(kw, title_lower):
                    topics[topic].append(item)
                    matched = True
                    break
            if matched:
                break
        if not matched:
            topics["other"].append(item)

    return dict(topics)


def make_report(analysis_result, suggested_tasks, keep, ignored, topics):
    print(SEP)
    print("  PITS DIARY ANALYSIS -- QUALITY REPORT")
    print(SEP)

    src = analysis_result.get("source", "unknown")
    date = analysis_result.get("date", "unknown")
    print(f"\n  Source: {os.path.basename(src)}")
    print(f"  Date: {date}")
    print(f"  Total raw items: {len(analysis_result['found_items'])}")

    print(f"\n{SEP2}")
    print(f"  QUALITY FILTER RESULTS")
    print(f"{SEP2}")
    print(f"  After filtering:   {len(keep)} items kept")
    print(f"  Ignored as noise:  {len(ignored)} items")

    print(f"\n{SEP2}")
    print(f"  TOPIC BREAKDOWN")
    print(f"{SEP2}")
    for topic, items in topics.items():
        if items:
            tasks = [i for i in items if i["type"] == "task"]
            others = [i for i in items if i["type"] != "task"]
            print(f"\n  ++ {topic.upper()} ({len(items)} items)")
            for t in tasks:
                conf_str = f"[{t['confidence']}%]"
                print(f"     * {conf_str} {t['title'][:70]}")
            for o in others:
                conf_str = f"[{o['confidence']}%]"
                print(f"     . {conf_str} ({o['type']}) {o['title'][:60]}")

    print(f"\n{SEP2}")
    print(f"  SUGGESTED TASKS (for Nirvana)")
    print(f"{SEP2}")
    for t in suggested_tasks:
        priority = t.get("priority", "medium")
        conf = t["confidence"]
        p_mark = "!" if conf >= 85 else "-" if conf >= 65 else " "
        print(f"  {p_mark} [{priority.upper()}] {t['title'][:80]}")
        print(f"       confidence: {conf}%")

    print(f"\n{SEP2}")
    print(f"  IGNORED ITEMS (noise)")
    print(f"{SEP2}")
    for i in ignored[:10]:
        print(f"  x {i['title'][:60]} -- {i['reason']}")
    if len(ignored) > 10:
        print(f"  ... and {len(ignored) - 10} more")

    print(f"\n{SEP2}")
    print(f"  QUALITY SELF-CHECK")
    print(f"{SEP2}")
    for t in suggested_tasks:
        issues = []
        title = t["title"].lower()
        if len(t["title"]) < 10:
            issues.append("Too short title")
        noise_words = ["maybe", "perhaps", "someday", "could", "might", "может", "возможно"]
        if any(w in title for w in noise_words):
            issues.append("Vague/uncertainty words")
        if t["confidence"] < 50:
            issues.append("Low confidence")
        if issues:
            print(f"  WARN {t['title'][:60]}")
            for issue in issues:
                print(f"     + {issue}")

    print(f"\n  OK Quality check complete: {len(suggested_tasks)} task candidates ready")
    print(f"  INFO Nirvana Bridge: NOT AVAILABLE -- tasks saved locally only")
    print(f"{SEP2}\n")


def main():
    output_dir = os.path.dirname(os.path.abspath(__file__))
    analysis_path = os.path.join(output_dir, "analysis_result.json")
    suggested_path = os.path.join(output_dir, "suggested_tasks.json")

    if not os.path.exists(analysis_path):
        print("ERROR: analysis_result.json not found. Run run_diary_test.py first.")
        sys.exit(1)

    analysis_result = load_json(analysis_path)
    suggested_tasks = load_json(suggested_path) if os.path.exists(suggested_path) else []

    keep, ignored = filter_quality_items(analysis_result["found_items"])
    topics = group_by_topic(keep)

    make_report(analysis_result, suggested_tasks, keep, ignored, topics)

    consolidated = {
        "report_date": datetime.now().isoformat(),
        "source": analysis_result["source"],
        "diary_date": analysis_result["date"],
        "total_raw": len(analysis_result["found_items"]),
        "after_filter": len(keep),
        "ignored": len(ignored),
        "topics": {t: len(items) for t, items in topics.items()},
    }
    with open(os.path.join(output_dir, "consolidated_report.json"), "w", encoding="utf-8") as f:
        json.dump(consolidated, f, ensure_ascii=False, indent=2)


if __name__ == "__main__":
    main()
