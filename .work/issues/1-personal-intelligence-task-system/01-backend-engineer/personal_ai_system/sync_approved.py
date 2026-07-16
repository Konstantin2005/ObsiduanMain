"""Read approved tasks from review file and send to Nirvana Bridge."""

import re, json, sys, urllib.request
from pathlib import Path

sys.stdout.reconfigure(encoding="utf-8")

BASE = Path(__file__).parent
REVIEW = BASE / "pending_review.md"
BRIDGE = "http://127.0.0.1:8712"

# Fetch project IDs from bridge
def get_projects():
    r = urllib.request.urlopen(f"{BRIDGE}/api/tasks?item_type=project&limit=200")
    data = json.loads(r.read())
    return {p["name"]: p["id"] for p in data["tasks"]}


def parse_review(text: str):
    """Extract task blocks with decisions from review markdown."""
    tasks = []
    current = {}

    for line in text.split("\n"):
        m_title = re.match(r"^###\s+\[(\d+)\]\s+\S\S\s+(.*)", line)
        if m_title:
            if current.get("decision"):
                tasks.append(current)
            current = {"idx": int(m_title.group(1)), "title": m_title.group(2).strip(), "decision": "pending", "project": ""}
            continue

        m_proj = re.match(r"\*\*Project:\*\*\s+`(.+)`", line)
        if m_proj and current:
            current["project"] = m_proj.group(1)

        m_dec = re.match(r"\*\*Decision:\*\*\s+`(.+)`", line)
        if m_dec and current:
            current["decision"] = m_dec.group(1).strip().lower()

    if current.get("decision"):
        tasks.append(current)

    return tasks


def main():
    if not REVIEW.exists():
        print(f"Not found: {REVIEW}")
        print("Run classify_tasks.py first")
        sys.exit(1)

    text = REVIEW.read_text(encoding="utf-8")
    tasks = parse_review(text)
    projects = get_projects()

    print(f"Found {len(tasks)} tasks in review file")
    print(f"Bridge projects: {list(projects.keys())}\n")

    approved = []
    rejected = []
    edited = []

    for t in tasks:
        dec = t["decision"]
        if dec == "approve":
            approved.append(t)
        elif dec == "reject":
            rejected.append(t)
        elif dec.startswith("edit:"):
            new_title = dec[5:].strip()
            t["title"] = new_title
            t["decision"] = "approve"
            edited.append(t)
            approved.append(t)
        else:
            print(f"  SKIP [{t['idx']}] {t['title'][:50]} — decision: {t['decision']}")

    print(f"\nApproved: {len(approved)}")
    print(f"Rejected: {len(rejected)}")

    if not approved:
        print("Nothing to send.")
        return

    print("\nSending to bridge...")
    sent = 0
    failed = 0
    for t in approved:
        proj = t.get("project", "Без проекта")
        parent_id = projects.get(proj)

        payload = {
            "title": t["title"][:500],
            "description": "",
            "priority": "medium",
        }

        try:
            data = json.dumps(payload).encode()
            req = urllib.request.Request(f"{BRIDGE}/api/tasks", data=data,
                                         headers={"Content-Type": "application/json"})
            resp = json.loads(urllib.request.urlopen(req).read())
            task_id = resp.get("id", "?")

            if parent_id:
                move_req = urllib.request.Request(
                    f"{BRIDGE}/api/tasks/{task_id}/move?parentid={parent_id}",
                    method="PUT")
                urllib.request.urlopen(move_req)

            print(f"  SENT [{t['idx']}] {t['title'][:60]}")
            sent += 1
        except Exception as e:
            print(f"  FAIL [{t['idx']}] {t['title'][:60]}: {e}")
            failed += 1

    print(f"\nSent: {sent}, Failed: {failed}")


if __name__ == "__main__":
    main()
