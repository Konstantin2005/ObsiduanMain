#!/usr/bin/env python3
import sys
import os
import json
import argparse
from pathlib import Path

sys.path.insert(0, os.path.dirname(os.path.abspath(__file__)))

from config.settings import load_config
from memory.database import Database
from memory.storage import Storage
from memory.models import Entry, Memory
from analyzer import AnalyzerAgent
from decision_engine import DecisionRouter
from ingestion import Loader, Parser, Cleaner


def cmd_analyze(args):
    settings = load_config()
    db = Database(settings.db_path)
    db.create_schema()
    storage = Storage(db)

    entry = Entry(source="manual", raw_text=args.text, cleaned_text=args.text)
    entry_id = storage.save_entry(entry)

    mem = Memory(entry_id=entry_id, content=args.text, memory_type="thought")
    storage.save_memory(mem)

    analyzer = AnalyzerAgent(settings.ollama_url, settings.ollama_model)
    suggestions = analyzer.analyze(args.text)

    decision = DecisionRouter(storage, settings.auto_threshold, settings.suggest_threshold)
    tasks = decision.route(suggestions, entry_id)

    print("\n=== ANALYSIS RESULTS ===")
    for s in suggestions:
        print(f"\n[{s.type.upper()}] {s.title}")
        print(f"  Confidence: {s.confidence}%")
        print(f"  Reason: {s.reason}")
        print(f"  Action: {s.recommended_action}")

    auto_tasks = [t for t in tasks if t.status == "automatic"]
    suggested_tasks = [t for t in tasks if t.status == "suggested"]
    if auto_tasks:
        print(f"\n  AUTO-CREATED ({len(auto_tasks)}):")
        for t in auto_tasks:
            print(f"    - {t.title}")
    if suggested_tasks:
        print(f"\n  SUGGESTED ({len(suggested_tasks)}):")
        for t in suggested_tasks:
            print(f"    - {t.title} (confidence: {t.confidence}%)")

    db.close()


def cmd_ingest(args):
    settings = load_config()
    db = Database(settings.db_path)
    db.create_schema()
    storage = Storage(db)
    loader = Loader(settings.data_dirs)
    parser = Parser()
    cleaner = Cleaner()

    files = loader.load_all_dirs()
    total = 0
    for file_path, content in files:
        parsed = parser.parse_file(file_path, content)
        cleaned = cleaner.clean_entries(parsed)
        for entry_data in cleaned:
            entry = Entry(
                source="file",
                raw_text=entry_data["raw_text"],
                cleaned_text=entry_data["cleaned_text"],
                source_file=entry_data["source_file"],
            )
            storage.save_entry(entry)
            total += 1

    print(f"Ingested {total} entries from {len(files)} files.")
    db.close()


def cmd_memory(args):
    settings = load_config()
    db = Database(settings.db_path)
    db.create_schema()
    storage = Storage(db)

    entries = storage.get_all_entries(limit=args.limit)
    print(f"\n=== MEMORY ({len(entries)} entries) ===\n")
    for e in entries:
        date_str = e.created_at[:19] if e.created_at else "unknown"
        text = (e.cleaned_text or e.raw_text)[:80]
        print(f"[{date_str}] #{e.id}: {text}...")
    db.close()


def cmd_tasks(args):
    settings = load_config()
    db = Database(settings.db_path)
    db.create_schema()
    storage = Storage(db)

    status_filter = args.status
    if status_filter:
        tasks = storage.get_tasks_by_status(status_filter)
    else:
        tasks = storage.get_all_tasks()

    print(f"\n=== TASKS ({len(tasks)}) ===\n")
    for t in tasks:
        print(f"[{t.status}] #{t.id} ({t.confidence}%): {t.title}")
    db.close()


def cmd_suggestions(args):
    settings = load_config()
    db = Database(settings.db_path)
    db.create_schema()
    storage = Storage(db)

    tasks = storage.get_tasks_by_status("suggested")
    print(f"\n=== PENDING SUGGESTIONS ({len(tasks)}) ===\n")
    for t in tasks:
        print(f"#{t.id}: {t.title} (confidence: {t.confidence}%)")
        print(f"  Description: {t.description}")

    if args.interactive:
        for t in tasks:
            print(f"\n---")
            print(f"Task: {t.title}")
            resp = input("Accept? (y/n/q): ").strip().lower()
            if resp == "q":
                break
            if resp == "y":
                storage.update_task_status(t.id, "approved")
                storage.save_feedback({"task_id": t.id, "decision": "accepted"})
                print("  -> Approved")
            elif resp == "n":
                storage.update_task_status(t.id, "rejected")
                storage.save_feedback({"task_id": t.id, "decision": "rejected"})
                print("  -> Rejected")

    db.close()


def main():
    parser = argparse.ArgumentParser(description="PITS — Personal Intelligence Task System")
    subparsers = parser.add_subparsers(dest="command")

    analyze_parser = subparsers.add_parser("analyze", help="Analyze a diary entry")
    analyze_parser.add_argument("text", help="Text to analyze")

    ingest_parser = subparsers.add_parser("ingest", help="Ingest diary files")

    memory_parser = subparsers.add_parser("memory", help="View memory")
    memory_parser.add_argument("--limit", type=int, default=20)

    tasks_parser = subparsers.add_parser("tasks", help="View tasks")
    tasks_parser.add_argument("--status", choices=["memory", "suggested", "automatic", "approved", "rejected"])

    suggest_parser = subparsers.add_parser("suggestions", help="View pending suggestions")
    suggest_parser.add_argument("--interactive", "-i", action="store_true", help="Interactive approval mode")

    args = parser.parse_args()
    if args.command == "analyze":
        cmd_analyze(args)
    elif args.command == "ingest":
        cmd_ingest(args)
    elif args.command == "memory":
        cmd_memory(args)
    elif args.command == "tasks":
        cmd_tasks(args)
    elif args.command == "suggestions":
        cmd_suggestions(args)
    else:
        parser.print_help()


if __name__ == "__main__":
    main()
