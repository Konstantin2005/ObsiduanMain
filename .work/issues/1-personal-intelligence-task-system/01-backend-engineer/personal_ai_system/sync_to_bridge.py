#!/usr/bin/env python3
import json
import sys
import os
import re
import requests
from typing import List, Set

BRIDGE_URL = "http://127.0.0.1:8712"


def get_existing_titles() -> Set[str]:
    try:
        resp = requests.get(f"{BRIDGE_URL}/api/tasks", timeout=10)
        if resp.status_code != 200:
            print(f"  ERROR: Bridge returned {resp.status_code}")
            return set()
        data = resp.json()
        tasks = data.get("tasks", [])
        titles = set()
        for t in tasks:
            title = t.get("title", "").lower().strip()
            title = re.sub(r"\s+", " ", title)
            titles.add(title)
        print(f"  Existing tasks in bridge: {len(titles)}")
        return titles
    except Exception as e:
        print(f"  ERROR: Cannot reach bridge: {e}")
        return set()


def normalize_title(title: str) -> str:
    return re.sub(r"\s+", " ", title.lower().strip())


def is_duplicate(title: str, existing: Set[str]) -> bool:
    norm = normalize_title(title)
    if norm in existing:
        return True
    for ex in existing:
        if len(norm) < 8 or len(ex) < 8:
            if norm == ex:
                return True
        elif norm in ex or ex in norm:
            return True
    return False


def send_task(task: dict) -> bool:
    payload = {
        "title": task["title"][:500],
        "description": task.get("description", ""),
        "priority": task.get("priority", "medium"),
    }
    try:
        resp = requests.post(f"{BRIDGE_URL}/api/tasks", json=payload, timeout=10)
        if resp.status_code in (200, 201):
            print(f"    -> SENT (id={resp.json().get('id', '?')})")
            return True
        else:
            print(f"    -> FAILED ({resp.status_code}): {resp.text[:100]}")
            return False
    except Exception as e:
        print(f"    -> ERROR: {e}")
        return False


def main():
    script_dir = os.path.dirname(os.path.abspath(__file__))
    suggested_path = os.path.join(script_dir, "suggested_tasks.json")

    if not os.path.exists(suggested_path):
        print("ERROR: suggested_tasks.json not found")
        sys.exit(1)

    with open(suggested_path, "r", encoding="utf-8") as f:
        tasks = json.load(f)

    print(f"PITS suggested tasks: {len(tasks)}")
    print(f"Bridge: {BRIDGE_URL}")

    print("\n[1] Checking existing tasks in bridge...")
    existing = get_existing_titles()
    if not existing:
        print("  WARNING: cannot read bridge, sending all tasks")
    else:
        print(f"  Bridge has {len(existing)} tasks")

    print("\n[2] Comparing and sending...")
    sent = 0
    skipped = 0
    failed = 0

    for task in tasks:
        title = task["title"]
        conf = task.get("confidence", 0)

        if conf >= 50:
            if existing and is_duplicate(title, existing):
                print(f"  SKIP (dup): [{conf}%] {title[:70]}")
                skipped += 1
            else:
                print(f"  SEND [{conf}%] {title[:70]}")
                if send_task(task):
                    sent += 1
                else:
                    failed += 1
        else:
            skipped += 1

    print(f"\n[3] Summary:")
    print(f"  Sent:     {sent}")
    print(f"  Skipped:  {skipped} (duplicates or low confidence)")
    print(f"  Failed:   {failed}")
    print(f"  Total:    {len(tasks)}")


if __name__ == "__main__":
    main()
