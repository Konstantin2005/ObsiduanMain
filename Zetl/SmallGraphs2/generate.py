# Intellectual Network Generator - Python version
import os
import random

random.seed(54321)

base_dir = r"C:\obsidian\Main\IntellectualNetwork"

# Create directories
for d in ["Thinkers", "Ideas", "Books", "Concepts"]:
    os.makedirs(os.path.join(base_dir, d), exist_ok=True)

# ============ THINKERS ============
thinkers = {
    "Nassim Taleb": {
        "ideas": ["Black Swan", "Antifragile", "Skin in the Game", "Barbell Strategy", "Antifragility", "Ergodicity", "Via Negativa", "Inversion", "Extremistan", "Mediocristan"],
        "books": ["The Black Swan", "Antifragile", "Skin in the Game", "Fooled by Randomness", "The Bed of Procrustes"],
        "concepts": ["Antifragility", "Black Swan", "Barbell Strategy", "Ergodicity", "Via Negativa", "Extremistan", "Mediocristan", "Ludic Fallacy"],
        "criticism": ["Intellectual arrogance", "Retrospective prediction", "Cherry picking evidence"]
    },
    "Charlie Munger": {
        "ideas": ["Mental Models", "Inversion", "Lollapalooza Effect", "Circle of Competence", "Checklist", "Model Grid"],
        "books": ["Poor Charlie's Almanack", "The Psychology of Human Misjudgment"],
        "concepts": ["Mental Models", "Inversion", "Lollapalooza Effect", "25 Cognitive Biases", "Circle of Competence", "Margin of Safety"],
        "criticism": ["Oversimplification", "Cult of personality", "Hindsight bias"]
    },
    "Daniel Kahneman": {
        "ideas": ["System 1 and System 2", "Prospect Theory", "Cognitive Biases", "Anchoring Effect", "Availability Heuristic", "Representativeness"],
        "books": ["Thinking Fast and Slow", "Noise", "The Psychology of Judgment"],
        "concepts": ["System 1", "System 2", "Prospect Theory", "Cognitive Biases", "Anchoring", "Framing Effect", "Loss Aversion"],
        "criticism": ["Replication crisis", "Overconfidence in biases", "Narrow focus"]
    },
    "Peter Thiel": {
        "ideas": ["Zero to One", "Competition is for Losers", "Secret Knowledge", "Long-term Thinking", "Definite Optimism", "Monopoly Theory"],
        "books": ["Zero to One", "The Education of a Value Investor"],
        "concepts": ["Zero to One", "Competition is for Losers", "Secret Knowledge", "Definite Optimism", "Indefinite Optimism", "Power Law"],
        "criticism": ["Elitism", "Contrarianism for its own sake", "Monopoly worship"]
    },
    "Karl Popper": {
        "ideas": ["Falsification", "Open Society", "Critical Rationalism", "Problem of Induction", "Three Worlds", "Demarcation Problem"],
        "books": ["The Open Society and Its Enemies", "The Logic of Scientific Discovery", "Conjectures and Refutations"],
        "concepts": ["Falsification", "Open Society", "Critical Rationalism", "Problem of Induction", "Three Worlds", "Demarcation"],
        "criticism": ["Idealism", "Ignoring social context", "Unfalsifiable itself"]
    },
    "Aristotle": {
        "ideas": ["Logic", "Categories", "Syllogism", "Virtue Ethics", "Politics", "Metaphysics", "Poetics"],
        "books": ["Nicomachean Ethics", "Politics", "Metaphysics", "Physics", "On the Soul", "Poetics"],
        "concepts": ["Logic", "Syllogism", "Virtue Ethics", "Golden Mean", "Four Causes", "Hylomorphism", "Eudaimonia"],
        "criticism": ["Medieval scholasticism", "Ignoring experiment", "Static worldview"]
    },
    "Friedrich Nietzsche": {
        "ideas": ["Will to Power", "Ubermensch", "Eternal Recurrence", "Master-Slave Morality", "Death of God", "Amor Fati"],
        "books": ["Thus Spoke Zarathustra", "Beyond Good and Evil", "The Gay Science", "On the Genealogy of Morality"],
        "concepts": ["Will to Power", "Ubermensch", "Eternal Recurrence", "Master-Slave Morality", "Amor Fati", "Will to Truth"],
        "criticism": ["Nazi appropriation", "Immoralism", "Elitism", "Inconsistency"]
    }
}

# ============ SHARED IDEAS ============
shared_ideas = {
    "Inversion": ["Nassim Taleb", "Charlie Munger", "Karl Popper"],
    "Cognitive Biases": ["Daniel Kahneman", "Charlie Munger", "Nassim Taleb"],
    "Risk and Uncertainty": ["Nassim Taleb", "Daniel Kahneman", "Peter Thiel"],
    "Long-term Thinking": ["Peter Thiel", "Charlie Munger", "Aristotle"],
    "Critical Rationalism": ["Karl Popper", "Daniel Kahneman", "Nassim Taleb"],
    "Mental Models": ["Charlie Munger", "Daniel Kahneman", "Peter Thiel"],
    "Competition": ["Peter Thiel", "Nassim Taleb", "Aristotle"],
    "Free Will": ["Friedrich Nietzsche", "Aristotle", "Karl Popper"],
    "Evolution of Ideas": ["Karl Popper", "Friedrich Nietzsche", "Daniel Kahneman"],
    "Ethical Systems": ["Aristotle", "Friedrich Nietzsche", "Karl Popper"],
    "Decision Making": ["Daniel Kahneman", "Charlie Munger", "Peter Thiel"],
    "Technological Progress": ["Peter Thiel", "Nassim Taleb", "Friedrich Nietzsche"],
    "Knowledge and Learning": ["Karl Popper", "Aristotle", "Daniel Kahneman"],
    "Individualism": ["Friedrich Nietzsche", "Peter Thiel", "Nassim Taleb"],
    "Systems Thinking": ["Charlie Munger", "Nassim Taleb", "Daniel Kahneman"],
    "Rationality": ["Karl Popper", "Charlie Munger", "Daniel Kahneman"],
    "Antifragility": ["Nassim Taleb", "Peter Thiel", "Charlie Munger"],
    "Open Society": ["Karl Popper", "Aristotle", "Friedrich Nietzsche"],
    "Ergodicity": ["Nassim Taleb", "Daniel Kahneman", "Charlie Munger"],
    "Lollapalooza Effect": ["Charlie Munger", "Daniel Kahneman", "Nassim Taleb"]
}

# ============ GENERATE THINKER NOTES ============
print("Generating Thinker notes...")

for thinker, data in thinkers.items():
    safe_name = thinker.replace(" ", "_")
    file_path = os.path.join(base_dir, "Thinkers", f"{thinker}.md")
    
    ideas_links = "\n".join([f"- [[Idea: {i}]]" for i in data["ideas"]])
    books_links = "\n".join([f"- [[Book: {b}]]" for b in data["books"]])
    concepts_links = "\n".join([f"- [[Concept: {c}]]" for c in data["concepts"]])
    criticism_links = "\n".join([f"- [[Criticism: {cr}]]" for cr in data["criticism"]])
    
    # Find related thinkers
    related = set()
    for idea, people in shared_ideas.items():
        if thinker in people:
            related.update([p for p in people if p != thinker])
    related_links = "\n".join([f"- [[Thinker: {r}]]" for r in list(related)[:5]])
    
    # Find shared ideas
    shared_list = [idea for idea, people in shared_ideas.items() if thinker in people]
    shared_links = "\n".join([f"- [[Shared Idea: {s}]]" for s in shared_list])
    
    content = f"""---
type: Thinker
cluster: Intellectual Network
tags: [thinker, intellectual, {safe_name.lower()}]
---

# {thinker}

## Key Ideas
{ideas_links}

## Books
{books_links}

## Concepts
{concepts_links}

## Criticism
{criticism_links}

## Related Thinkers
{related_links}

## Shared Ideas
{shared_links}
"""
    
    with open(file_path, "w", encoding="utf-8") as f:
        f.write(content)
    print(f"  Created: {thinker}")

# ============ GENERATE IDEA NOTES ============
print("\nGenerating Idea notes...")

all_ideas = set()
for data in thinkers.values():
    all_ideas.update(data["ideas"])

for idea in all_ideas:
    file_path = os.path.join(base_dir, "Ideas", f"Idea - {idea}.md")
    
    # Find which thinkers have this idea
    thinkers_with = [t for t, d in thinkers.items() if idea in d["ideas"]]
    thinker_links = "\n".join([f"- [[Thinker: {t}]]" for t in thinkers_with])
    
    # Find related ideas
    related = set()
    for t in thinkers_with:
        related.update([i for i in thinkers[t]["ideas"] if i != idea])
    related_links = "\n".join([f"- [[Idea: {i}]]" for i in list(related)[:5]])
    
    content = f"""---
type: Idea
cluster: Intellectual Network
tags: [idea, intellectual]
---

# {idea}

## Thinkers
{thinker_links}

## Related Ideas
{related_links}
"""
    
    with open(file_path, "w", encoding="utf-8") as f:
        f.write(content)

# ============ GENERATE BOOK NOTES ============
print("Generating Book notes...")

all_books = []
for thinker, data in thinkers.items():
    for book in data["books"]:
        all_books.append((book, thinker))

for book, author in all_books:
    file_path = os.path.join(base_dir, "Books", f"Book - {book}.md")
    
    content = f"""---
type: Book
author: {author}
cluster: Intellectual Network
tags: [book, intellectual, {author.lower().replace(" ", "_")}]
---

# {book}

## Author
- [[Thinker: {author}]]

## Key Ideas
- [[Idea: {book}]]
"""
    
    with open(file_path, "w", encoding="utf-8") as f:
        f.write(content)

# ============ GENERATE CONCEPT NOTES ============
print("Generating Concept notes...")

all_concepts = set()
for data in thinkers.values():
    all_concepts.update(data["concepts"])

for concept in all_concepts:
    file_path = os.path.join(base_dir, "Concepts", f"Concept - {concept}.md")
    
    thinkers_with = [t for t, d in thinkers.items() if concept in d["concepts"]]
    thinker_links = "\n".join([f"- [[Thinker: {t}]]" for t in thinkers_with])
    
    related = set()
    for t in thinkers_with:
        related.update([c for c in thinkers[t]["concepts"] if c != concept])
    related_links = "\n".join([f"- [[Concept: {c}]]" for c in list(related)[:5]])
    
    content = f"""---
type: Concept
cluster: Intellectual Network
tags: [concept, intellectual]
---

# {concept}

## Thinkers
{thinker_links}

## Related Concepts
{related_links}
"""
    
    with open(file_path, "w", encoding="utf-8") as f:
        f.write(content)

# ============ GENERATE SHARED IDEA NOTES ============
print("Generating Shared Idea notes...")

for idea, people in shared_ideas.items():
    file_path = os.path.join(base_dir, "Ideas", f"Shared Idea - {idea}.md")
    
    thinker_links = "\n".join([f"- [[Thinker: {p}]]" for p in people])
    
    content = f"""---
type: Shared Idea
cluster: Intellectual Network
tags: [shared-idea, intellectual]
---

# {idea}

## Thinkers
{thinker_links}

## Description
A shared idea connecting multiple thinkers.
"""
    
    with open(file_path, "w", encoding="utf-8") as f:
        f.write(content)

# ============ GENERATE CRITICISM NOTES ============
print("Generating Criticism notes...")

all_criticisms = []
for thinker, data in thinkers.items():
    for criticism in data["criticism"]:
        all_criticisms.append((criticism, thinker))

for criticism, target in all_criticisms:
    file_path = os.path.join(base_dir, "Concepts", f"Criticism - {criticism}.md")
    
    content = f"""---
type: Criticism
cluster: Intellectual Network
tags: [criticism, intellectual]
---

# {criticism}

## Target
- [[Thinker: {target}]]

## Related Concepts
- [[Concept: {criticism}]]
"""
    
    with open(file_path, "w", encoding="utf-8") as f:
        f.write(content)

# ============ COUNT FILES ============
print("\n=== Generation Complete ===")
for d in ["Thinkers", "Ideas", "Books", "Concepts"]:
    count = len([f for f in os.listdir(os.path.join(base_dir, d)) if f.endswith(".md")])
    print(f"{d}: {count}")

total = sum(len([f for f in os.listdir(os.path.join(base_dir, d)) if f.endswith(".md")]) for d in ["Thinkers", "Ideas", "Books", "Concepts"])
print(f"Total: {total}")
