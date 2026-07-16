#!/usr/bin/env python3
import sys
import os
import json
import logging
from datetime import datetime

sys.path.insert(0, os.path.dirname(os.path.abspath(__file__)))

from config.settings import load_config
from memory.database import Database
from memory.storage import Storage
from memory.models import Entry, Memory
from analyzer import AnalyzerAgent
from decision_engine import DecisionRouter
from ingestion import Loader, Parser, Cleaner


def main():
    settings = load_config()
    db_path = "pits_diary_test.db"
    settings.db_path = db_path

    if os.path.exists(db_path):
        os.remove(db_path)

    db = Database(db_path)
    db.create_schema()
    storage = Storage(db)

    diary_path = r"C:\obsidian\Main\Calendula\Calendula\2026\Июль\13-07-26\13-07-26.md"
    date_str = "2026-07-13"

    print(f"Reading diary: {diary_path}")
    with open(diary_path, "r", encoding="utf-8", errors="replace") as f:
        raw_text = f.read()

    cleaner = Cleaner()
    cleaned = cleaner.clean(raw_text)

    entry = Entry(
        source="file",
        raw_text=raw_text,
        cleaned_text=cleaned,
        source_file=diary_path,
    )
    entry_id = storage.save_entry(entry)
    print(f"Entry saved (id={entry_id}), size={len(raw_text)} chars")

    mem = Memory(
        entry_id=entry_id,
        content=cleaned[:500],
        memory_type="diary",
        confidence=100.0,
    )
    storage.save_memory(mem)

    print(f"\n--- Running Analyzer (local mode - no Ollama) ---")
    analyzer = AnalyzerAgent("http://localhost:11434", "llama3")
    suggestions = analyzer.analyze(raw_text)

    print(f"Analyzer found {len(suggestions)} items\n")

    decision = DecisionRouter(storage, auto_threshold=85.0, suggest_threshold=50.0)
    tasks = decision.route(suggestions, entry_id)

    print(f"Decision Engine processed {len(tasks)} tasks")

    auto_tasks = [t for t in tasks if t.status == "automatic"]
    suggested_tasks = [t for t in tasks if t.status == "suggested"]
    memory_tasks = [t for t in tasks if t.status == "memory"]

    analysis_result = {
        "source": diary_path,
        "date": date_str,
        "found_items": [],
        "ignored_items": [],
        "memory_updates": [],
    }

    for s in suggestions:
        item = {
            "type": s.type,
            "title": s.title,
            "confidence": s.confidence,
            "reason": s.reason,
            "evidence": s.reason,
            "recommended_action": s.recommended_action,
        }
        analysis_result["found_items"].append(item)

    output_dir = os.path.dirname(os.path.abspath(__file__))
    with open(os.path.join(output_dir, "analysis_result.json"), "w", encoding="utf-8") as f:
        json.dump(analysis_result, f, ensure_ascii=False, indent=2)
    print("Saved: analysis_result.json")

    suggested = []
    for t in suggested_tasks + auto_tasks:
        task_entry = {
            "title": t.title,
            "description": t.description or "",
            "priority": "high" if t.confidence >= 85 else "medium",
            "confidence": t.confidence,
            "source": "diary",
        }
        suggested.append(task_entry)

    with open(os.path.join(output_dir, "suggested_tasks.json"), "w", encoding="utf-8") as f:
        json.dump(suggested, f, ensure_ascii=False, indent=2)
    print("Saved: suggested_tasks.json")

    print("\n" + "=" * 60)
    print("===== PITS DIARY ANALYSIS =====")
    print("=" * 60)
    print(f"\nSource: {diary_path}")
    print(f"Date: {date_str}")
    print(f"\n--- Overview ---")
    print(f"Total entries: 1")
    print(f"Found items: {len(suggestions)}")
    type_counts = {}
    for s in suggestions:
        type_counts[s.type] = type_counts.get(s.type, 0) + 1
    for t, c in type_counts.items():
        print(f"  {t}: {c}")

    print(f"\n--- Task breakdown ---")
    print(f"Automatic: {len(auto_tasks)}")
    print(f"Suggested: {len(suggested_tasks)}")
    print(f"Memory only: {len(memory_tasks)}")

    if auto_tasks:
        print(f"\n--- Automatic tasks ---")
        for t in auto_tasks:
            entry_data = next((s for s in suggestions if s.title == t.title), None)
            reason = entry_data.reason if entry_data else ""
            print(f"\n  {t.title}")
            print(f"    Reason: {reason}")
            print(f"    Confidence: {t.confidence}")

    if suggested_tasks:
        print(f"\n--- Suggestions ({len(suggested_tasks)}) ---")
        for t in suggested_tasks:
            print(f"\n  {t.title}")
            print(f"    Confidence: {t.confidence}")

    if memory_tasks:
        print(f"\n--- Memory only ({len(memory_tasks)}) ---")
        for t in memory_tasks[:5]:
            print(f"  {t.title} ({t.confidence})")

    print(f"\n--- Quality Check ---")
    for s in suggestions:
        issues = []
        if s.confidence < 50:
            issues.append("low confidence")
        if s.type == "task":
            noise_words = ["maybe", "perhaps", "someday", "eventually", "could", "might", "может", "возможно", "когда-нибудь"]
            title_lower = s.title.lower()
            noise_count = sum(1 for w in noise_words if w in title_lower)
            if noise_count >= 2:
                issues.append("possibly just a thought (vague)")
        if issues:
            print(f"  ⚠ {s.title}: {', '.join(issues)}")

    print(f"\nMemory updated: yes")
    print(f"DB file: {db_path}")
    print(f"\nNote: Nirvana Bridge not available — tasks NOT sent to Nirvana.")
    print("=" * 60)

    db.close()


if __name__ == "__main__":
    main()
