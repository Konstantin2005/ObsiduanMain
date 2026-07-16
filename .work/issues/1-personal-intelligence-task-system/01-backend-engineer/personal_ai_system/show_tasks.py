import json

path = "suggested_tasks.json"
with open(path, "r", encoding="utf-8") as f:
    data = json.load(f)

auto = [t for t in data if t["confidence"] >= 85]
suggest = [t for t in data if 50 <= t["confidence"] < 85]

print(f"Всего кандидатов: {len(data)}")
print(f"  Automatic (>=85): {len(auto)}")
print(f"  Suggest (50-85):  {len(suggest)}")
print()

print("=== AUTOMATIC (готовы к отправке в мост) ===")
for i, t in enumerate(auto, 1):
    print(f'{i}. [{t["confidence"]}%] {t["title"][:80]}')

print()
print("=== SUGGEST (требуют подтверждения) ===")
for i, t in enumerate(suggest, 1):
    print(f'{i}. [{t["confidence"]}%] {t["title"][:80]}')
