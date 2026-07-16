"""Classify PITS tasks into Nirvana projects and generate review file."""

import json, sys, os
from pathlib import Path

sys.stdout.reconfigure(encoding="utf-8")

BASE = Path(__file__).parent
SUGGESTED = BASE / "suggested_tasks.json"
REVIEW = BASE / "pending_review.md"

PROJECTS = {
    "active": {
        "ThingsBoard": "ThingsBoard",
        "bookclub": "Книжный клуб",
        "english": "Инглиш",
        "hike": "Поход",
        "moving": "Переезд",
        "offer": "оффер",
        "ai": "AI Learning",
    },
    "someday": {
        "armenian": "Армянский",
    },
}

def classify(title: str, desc: str) -> str:
    t = title.lower() + " " + desc.lower()

    # Hike / Поход
    hike_kw = ["поход", "маршрут", "палатка", "инвентарь", "плот", "армении",
               "еду", "клещ", "медвед", "билет", "поход и питер",
               "мин набор", "блоками готовить", "отрезки времени",
               "дельн", "дедлайн", "отпуск"]
    if any(k in t for k in hike_kw):
        return "Поход"

    # English / Инглиш
    eng_kw = ["англ", "инглиш", "english", "учит", "диалог", "занят",
              "сообщество"]
    if any(k in t for k in eng_kw):
        return "Инглиш"

    # AI / Tech
    ai_kw = ["нейрон", "ai", "технолог", "mcp", "bridge", "как она устроена",
             "код", "программир", "баг", "bug", "pits"]
    if any(k in t for k in ai_kw):
        return "AI Learning"

    # ThingsBoard
    tb_kw = ["thingsboard", "tb", "iot"]
    if any(k in t for k in tb_kw):
        return "ThingsBoard"

    # Moving / Переезд
    mv_kw = ["переезд", "переех", "списк", "обновлял"]
    if any(k in t for k in mv_kw):
        return "Переезд"

    # Offer / оффер
    of_kw = ["оффер", "offer", "собесед", "резюм"]
    if any(k in t for k in of_kw):
        return "оффер"

    # Book Club
    bk_kw = ["книг", "клуб", "book"]
    if any(k in t for k in bk_kw):
        return "Книжный клуб"

    # Armenian
    ar_kw = ["армян", "armenian"]
    if any(k in t for k in ar_kw):
        return "Армянский"

    return "Без проекта"


def main():
    if not SUGGESTED.exists():
        print(f"Not found: {SUGGESTED}")
        sys.exit(1)

    tasks = json.loads(SUGGESTED.read_text(encoding="utf-8"))
    print(f"Classifying {len(tasks)} tasks...")

    lines = []
    lines.append("# Pending Tasks — Review & Approve\n")
    lines.append("---\n")
    lines.append("## Legend\n")
    lines.append("- `[approve]` — send to Nirvana\n")
    lines.append("- `[reject]` — discard\n")
    lines.append("- `[edit]` — modify title/project before sending\n")
    lines.append("\n---\n")

    by_project = {}
    for t in tasks:
        if t.get("title", "").isascii() and t["title"].strip():
            continue
        proj = classify(t["title"], t.get("description", ""))
        by_project.setdefault(proj, []).append(t)

    idx = 0
    for proj in sorted(by_project.keys()):
        lines.append(f"\n## {proj}\n")
        for t in by_project[proj]:
            idx += 1
            conf = t.get("confidence", 0)
            priority = t.get("priority", "medium")
            emoji = "🟢" if conf >= 85 else "🟡" if conf >= 50 else "⚪"
            lines.append(f"### [{idx}] {emoji} {t['title']}")
            lines.append(f"- **Priority:** {priority}")
            lines.append(f"- **Confidence:** {conf}%")
            lines.append(f"- **Project:** `{proj}`")
            desc = t.get("description", "")
            if desc:
                lines.append(f"- *{desc}*")
            lines.append(f"\n**Decision:** `pending` (replace with `approve`, `reject`, or `edit:new title`)\n---\n")

    content = "\n".join(lines)
    REVIEW.write_text(content, encoding="utf-8")
    print(f"\nReview file created: {REVIEW}")
    print("Edit it, change `pending` to `approve`/`reject`/`edit:...`")
    print("Then run: python sync_approved.py")


if __name__ == "__main__":
    main()
