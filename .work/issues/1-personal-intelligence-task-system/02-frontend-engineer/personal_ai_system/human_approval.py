#!/usr/bin/env python3
import sys
import os
import json
from datetime import datetime

sys.path.insert(0, os.path.dirname(os.path.abspath(__file__)))

from config.settings import load_config
from memory.database import Database
from memory.storage import Storage
from memory.models import Feedback


class HumanApprovalMode:
    def __init__(self, storage: Storage):
        self.storage = storage

    def show_and_ask(self) -> int:
        suggestions = self.storage.get_tasks_by_status("suggested")
        if not suggestions:
            print("No pending suggestions.")
            return 0

        processed = 0
        for task in suggestions:
            print("\n" + "=" * 60)
            print(f"🤔 I noticed:")
            print(f"\n  \"{task.title}\"")
            if task.description:
                print(f"\n  Context: {task.description[:200]}")
            print(f"\n  Confidence: {task.confidence:.0f}%")

            while True:
                resp = input("\n  Create task? (y/n/skip): ").strip().lower()
                if resp == "y":
                    self.storage.update_task_status(task.id, "approved")
                    fb = Feedback(task_id=task.id, decision="accepted", reason="user_approved")
                    self.storage.save_feedback(fb)
                    print("  -> Task approved ✓")
                    processed += 1
                    break
                elif resp == "n":
                    reason = input("  Why not? (optional): ").strip()
                    self.storage.update_task_status(task.id, "rejected")
                    fb = Feedback(task_id=task.id, decision="rejected", reason=reason or "user_rejected")
                    self.storage.save_feedback(fb)
                    print("  -> Task rejected ✗")
                    processed += 1
                    break
                elif resp == "skip":
                    print("  -> Skipped")
                    break
                else:
                    print("  Please answer y/n/skip")

        return processed


def main():
    settings = load_config()
    db = Database(settings.db_path)
    db.create_schema()
    storage = Storage(db)

    app = HumanApprovalMode(storage)
    count = app.show_and_ask()
    print(f"\nProcessed {count} suggestions.")
    db.close()


if __name__ == "__main__":
    main()
