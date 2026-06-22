# Decision Making Graph Generator - Python version
import os
import random

random.seed(99999)

base_dir = r"C:\obsidian\Main\DecisionMakingGraph"

# Create directories
for d in ["Values", "Principles", "Rules", "Decisions", "Outcomes"]:
    os.makedirs(os.path.join(base_dir, d), exist_ok=True)

# ============ VALUES (100) ============
print("Defining Values...")
values = [
    "Honesty", "Justice", "Freedom", "Equality", "Dignity",
    "Responsibility", "Respect", "Loyalty", "Reliability", "Sincerity",
    "Kindness", "Mercy", "Gratitude", "Humility", "Patience",
    "Courage", "Decisiveness", "Persistence", "Discipline", "Hard Work",
    "Solidarity", "Collectivism", "Individualism", "Community", "Family",
    "Friendship", "Love", "Intimacy", "Trust", "Cooperation",
    "Competition", "Distributive Justice", "Procedural Justice",
    "Egalitarianism", "Meritocracy", "Aristocracy", "Democracy", "Autonomy",
    "Power", "Influence",
    "Knowledge", "Truth", "Wisdom", "Understanding", "Critical Thinking",
    "Logic", "Rationality", "Empiricism", "Rationalism", "Skepticism",
    "Openness", "Curiosity", "Innovation", "Tradition", "Progress",
    "Evolution", "Revolution", "Reform", "Conservatism", "Modernism",
    "Health", "Beauty", "Harmony", "Balance", "Comfort",
    "Safety", "Stability", "Growth", "Development", "Self-Realization",
    "Self-Respect", "Self-Knowledge", "Autonomy", "Independence", "Free Time",
    "Financial Freedom", "Creativity", "Inspiration", "Meaning", "Purpose",
    "Good", "Evil", "Innocence", "Guilt", "Shame",
    "Pride", "Compassion", "Empathy", "Altruism", "Egoism",
    "Sacrifice", "Selflessness", "Honesty", "Truthfulness", "Deception",
    "Lying", "Trust", "Betrayal", "Loyalty", "Devotion"
]

# ============ PRINCIPLES (300) ============
print("Defining Principles...")
principles = [
    # Ethical Principles
    "Principle of Non-Violence", "Principle of Justice", "Principle of Autonomy",
    "Principle of Beneficence", "Principle of Non-Maleficence", "Principle of Fidelity",
    "Principle of Honesty", "Principle of Kindness", "Principle of Respect",
    "Principle of Dignity", "Principle of Equality", "Principle of Brotherhood",
    "Principle of Solidarity", "Principle of Responsibility", "Principle of Duty",
    "Principle of Conscience", "Principle of Just Punishment", "Principle of Proportionality",
    "Principle of Self-Defense", "Principle of Necessity",
    "Principle of Humanism", "Principle of Benevolence", "Principle of Mercy",
    "Principle of Compassion", "Principle of Altruism", "Principle of Egoism",
    "Principle of Utilitarianism", "Principle of Deontology", "Principle of Consequentialism",
    "Principle of Virtue Ethics", "Principle of Cardiology", "Principle of Virtue",
    "Principle of Wisdom", "Principle of Courage", "Principle of Moderation",
    "Principle of Distributive Justice", "Principle of Procedural Justice",
    "Principle of Retributive Justice", "Principle of Restorative Justice",
    "Principle of Consensus", "Principle of Majority", "Principle of Minority",
    "Principle of Competence", "Principle of Merit", "Principle of Need",
    "Principle of Contribution", "Principle of Equal Opportunity", "Principle of Affirmative Action",
    "Principle of Non-Discrimination", "Principle of Tolerance", "Principle of Pluralism",
    "Principle of Secularism", "Principle of Freedom of Conscience", "Principle of Religious Freedom",
    "Principle of Free Speech", "Principle of Freedom of Assembly", "Principle of Association Freedom",
    "Principle of Right to Life", "Principle of Right to Liberty", "Principle of Right to Fair Trial",
    
    # Decision Principles
    "Principle of Rationality", "Principle of Empiricism", "Principle of Pragmatism",
    "Principle of Optimization", "Principle of Maximization", "Principle of Minimization",
    "Principle of Balance", "Principle of Harmony", "Principle of Proportion",
    "Principle of Symmetry", "Principle of Asymmetry", "Principle of Contrast",
    "Principle of Analogy", "Principle of Inversion", "Principle of Decomposition",
    "Principle of Hierarchy", "Principle of Priorities", "Principle of Sequence",
    "Principle of Parallelism", "Principle of Synchronization", "Principle of Asynchrony",
    "Principle of Caching", "Principle of Memoization", "Principle of Lazy Evaluation",
    "Principle of Greedy Algorithms", "Principle of Dynamic Programming",
    "Principle of Divide and Conquer", "Principle of Backtracking",
    "Principle of Random Search", "Principle of Directed Search",
    "Principle of Heuristics", "Principle of Approximation", "Principle of Escalation",
    "Principle of De-escalation", "Principle of Compromise", "Principle of Bargaining",
    "Principle of Initial Offer", "Principle of Anchoring", "Principle of Framing",
    "Principle of Perspective", "Principle of Utility", "Principle of Risk",
    "Principle of Uncertainty", "Principle of Probability", "Principle of Statistics",
    "Principle of Representativeness", "Principle of Availability", "Principle of Confirmation",
    "Principle of Falsification", "Principle of Verification", "Principle of Correlation",
    "Principle of Causation", "Principle of Consequence", "Principle of Precedence",
    "Principle of Reciprocity", "Principle of Escalation of Commitment", "Principle of Regret",
    "Principle of Pride",
    
    # Strategic Principles
    "Principle of Long-term Bets", "Principle of Short-term Bets", "Principle of Diversification",
    "Principle of Concentration", "Principle of Specialization", "Principle of Generalization",
    "Principle of Vertical Integration", "Principle of Horizontal Integration",
    "Principle of Outsourcing", "Principle of Insourcing", "Principle of Offshoring",
    "Principle of Localization", "Principle of Globalization", "Principle of Regionalization",
    "Principle of Scaling", "Principle of Optimization", "Principle of Automation",
    "Principle of Manual Labor", "Principle of Mechanization", "Principle of Digitalization",
    "Principle of Virtualization", "Principle of Containerization", "Principle of Microservices",
    "Principle of Monolithic", "Principle of Modularity", "Principle of Composition",
    "Principle of Inheritance", "Principle of Polymorphism", "Principle of Encapsulation",
    "Principle of Abstraction", "Principle of Decomposition", "Principle of Recomposition",
    "Principle of Iteration", "Principle of Incrementality", "Principle of Spiral Development",
    "Principle of Spiral Model", "Principle of Waterfall Model", "Principle of Agile",
    "Principle of Scrum", "Principle of Kanban", "Principle of Lean",
    "Principle of Six Sigma", "Principle of TQM", "Principle of Continuous Improvement",
    "Principle of Kaizen", "Principle of Poka-Yoke", "Principle of 5S",
    "Principle of JIT", "Principle of TOC", "Principle of DBR",
    "Principle of OPT", "Principle of Synchronous Production",
    "Principle of Pull System", "Principle of Push System", "Principle of Flexible Production",
    "Principle of Mass Customization", "Principle of Personalization", "Principle of Standardization",
    "Principle of Normalization", "Principle of Formalization", "Principle of Regulation",
    
    # Personal Principles
    "Principle of Self-Discipline", "Principle of Self-Control", "Principle of Self-Regulation",
    "Principle of Self-Motivation", "Principle of Self-Improvement", "Principle of Self-Knowledge",
    "Principle of Self-Realization", "Principle of Self-Expression", "Principle of Authenticity",
    "Principle of Integrity", "Principle of Consistency", "Principle of Integration",
    "Principle of Balance", "Principle of Harmony", "Principle of Moderation",
    "Principle of Golden Mean", "Principle of Work-Life Balance",
    "Principle of Ergonomics", "Principle of Aesthetics",
    "Principle of Minimalism", "Principle of Maximalism", "Principle of Simplicity",
    "Principle of Complexity", "Principle of Elegance", "Principle of Functionality",
    "Principle of Beauty", "Principle of Truth", "Principle of Goodness",
    "Principle of Fairness", "Principle of Freedom", "Principle of Equality",
    "Principle of Brotherhood", "Principle of Solidarity", "Principle of Community",
    "Principle of Individuality", "Principle of Uniqueness", "Principle of Diversity",
    "Principle of Pluralism", "Principle of Tolerance", "Principle of Inclusivity",
    "Principle of Accessibility", "Principle of Universality", "Principle of Specificity",
    "Principle of Contextuality", "Principle of Situationality", "Principle of Flexibility",
    "Principle of Adaptability", "Principle of Resilience", "Principle of Antifragility",
    "Principle of Ergodicity", "Principle of Probabilistic Thinking", "Principle of Statistical Thinking",
    "Principle of Systems Thinking", "Principle of Critical Thinking", "Principle of Creative Thinking",
    "Principle of Design Thinking", "Principle of Lateral Thinking", "Principle of Vertical Thinking",
    "Principle of Horizontal Thinking",
    
    # Logic Principles
    "Law of Identity", "Law of Non-Contradiction", "Law of Excluded Middle",
    "Law of Sufficient Reason", "Law of Causality", "Law of Consequence",
    "Law of Necessary Consequence", "Law of Contingent Consequence",
    "Law of Deduction", "Law of Induction", "Law of Abduction",
    "Law of Analogy", "Law of Symmetry", "Law of Transitivity",
    "Law of Reflexivity", "Law of Anti-Symmetry", "Law of Asymmetry",
    "Law of Monotonicity", "Law of Idempotency", "Law of Associativity",
    "Law of Commutativity", "Law of Distributivity", "Law of Absorption",
    "Law of Neutral Element", "Law of Inversion", "Law of Double Negation",
    "Law of De Morgan", "Law of Morgan", "Law of Verification",
    "Law of Falsification", "Law of Correlation", "Law of Causation",
    "Law of Supply", "Law of Marginal Utility", "Law of Diminishing Returns",
    "Law of Increasing Costs", "Law of Scale", "Law of Pareto",
    "Law of Boltzmann", "Law of Entropy", "Law of Stability",
    "Law of Instability", "Law of Equilibrium", "Law of Disequilibrium",
    "Law of Self-Organization", "Law of Emergence", "Law of Holism",
    "Law of Reductionism", "Law of Systemicity", "Law of Integrity",
    "Law of Interconnection", "Law of Interdependence", "Law of Interaction",
    "Law of Mutual Influence", "Law of Feedback", "Law of Positive Feedback",
    "Law of Negative Feedback", "Law of Catastrophe", "Law of Bifurcation",
    "Law of Chaos", "Law of Order"
]

# ============ RULES (500) ============
print("Defining Rules...")
rules = []
templates = [
    "Always apply {principle} in context of {value}",
    "Never violate {principle} for {value}",
    "Apply {principle} when {value} is threatened",
    "Use {principle} to achieve {value}",
    "Balance {principle} and {value}",
    "Prioritize {principle} over {value}",
    "Integrate {principle} with {value}",
    "Synthesize {principle} and {value}",
    "Combine {principle} for {value}",
    "Adapt {principle} to {value}",
    "Modify {principle} for {value}",
    "Escalate {principle} for {value}",
    "De-escalate {principle} for {value}",
    "Optimize {principle} for {value}",
    "Maximize {principle} through {value}",
    "Minimize {principle} for {value}",
    "Balance {principle} with {value}",
    "Concentrate {principle} on {value}",
    "Diversify {principle} for {value}",
    "Specialize {principle} in {value}"
]

for value in values[:50]:
    for template in templates[:10]:
        principle = random.choice(principles)
        rule = template.replace("{principle}", principle).replace("{value}", value)
        rules.append(rule)

rules = list(set(rules))[:500]

# ============ DECISIONS (500) ============
print("Defining Decisions...")
decisions = []
d_templates = [
    "Accept decision about {rule}",
    "Choose path of {rule}",
    "Define strategy of {rule}",
    "Develop plan for {rule}",
    "Implement {rule}",
    "Realize {rule}",
    "Deploy {rule}",
    "Modify {rule}",
    "Optimize {rule}",
    "Scale {rule}"
]

for rule in rules[:250]:
    for template in d_templates[:2]:
        decision = template.replace("{rule}", rule)
        decisions.append(decision)

decisions = list(set(decisions))[:500]

# ============ OUTCOMES (600) ============
print("Defining Outcomes...")
outcomes = []
o_templates = [
    "Success in {decision}",
    "Failure in {decision}",
    "Partial success in {decision}",
    "Unexpected result of {decision}",
    "Positive outcome of {decision}",
    "Negative outcome of {decision}",
    "Neutral outcome of {decision}",
    "Mixed outcome of {decision}",
    "Long-term success of {decision}",
    "Short-term success of {decision}",
    "Long-term failure of {decision}",
    "Short-term failure of {decision}",
    "Sustainable success of {decision}",
    "Unsustainable success of {decision}",
    "Sustainable failure of {decision}",
    "Unsustainable failure of {decision}",
    "Scalable success of {decision}",
    "Non-scalable success of {decision}",
    "Scalable failure of {decision}",
    "Non-scalable failure of {decision}"
]

for decision in decisions[:200]:
    for template in o_templates[:3]:
        outcome = template.replace("{decision}", decision)
        outcomes.append(outcome)

outcomes = list(set(outcomes))[:600]

print(f"\nValues: {len(values)}")
print(f"Principles: {len(principles)}")
print(f"Rules: {len(rules)}")
print(f"Decisions: {len(decisions)}")
print(f"Outcomes: {len(outcomes)}")
print(f"Total: {len(values) + len(principles) + len(rules) + len(decisions) + len(outcomes)}")

# ============ GENERATE FILES ============
print("\n=== Generating Files ===")

# Value Notes
print("Generating Value notes...")
for value in values:
    file_path = os.path.join(base_dir, "Values", f"{value}.md")
    
    rp = random.sample(principles, min(5, len(principles)))
    rv = random.sample([v for v in values if v != value], min(3, len(values)-1))
    
    principle_links = "\n".join([f"- [[Principle: {p}]]" for p in rp])
    value_links = "\n".join([f"- [[Value: {v}]]" for v in rv])
    
    content = f"""---
type: Value
importance: {random.randint(5, 10)}
tags: [value, decision-making]
---

# {value}

## Description
A value that guides decision-making direction.

## Related Principles
{principle_links}

## Related Values
{value_links}

## Application
Used as foundation for decision-making.
"""
    
    with open(file_path, "w", encoding="utf-8") as f:
        f.write(content)

# Principle Notes
print("Generating Principle notes...")
for principle in principles:
    file_path = os.path.join(base_dir, "Principles", f"{principle}.md")
    
    rv = random.sample(values, min(3, len(values)))
    rr = random.sample(rules, min(3, len(rules)))
    rp = random.sample([p for p in principles if p != principle], min(2, len(principles)-1))
    
    value_links = "\n".join([f"- [[Value: {v}]]" for v in rv])
    rule_links = "\n".join([f"- [[Rule: {r}]]" for r in rr])
    principle_links = "\n".join([f"- [[Principle: {p}]]" for p in rp])
    
    content = f"""---
type: Principle
tags: [principle, decision-making]
---

# {principle}

## Description
A principle that guides decision-making.

## Related Values
{value_links}

## Generates Rules
{rule_links}

## Related Principles
{principle_links}
"""
    
    with open(file_path, "w", encoding="utf-8") as f:
        f.write(content)

# Rule Notes
print("Generating Rule notes...")
for rule in rules:
    safe_name = rule[:80].replace("/", "_").replace("\\", "_")
    file_path = os.path.join(base_dir, "Rules", f"{safe_name}.md")
    
    rp = random.sample(principles, min(2, len(principles)))
    rd = random.sample(decisions, min(2, len(decisions)))
    rr = random.sample([r for r in rules if r != rule], min(2, len(rules)-1))
    
    principle_links = "\n".join([f"- [[Principle: {p}]]" for p in rp])
    decision_links = "\n".join([f"- [[Decision: {d}]]" for d in rd])
    rule_links = "\n".join([f"- [[Rule: {r}]]" for r in rr])
    
    content = f"""---
type: Rule
tags: [rule, decision-making]
---

# {rule}

## Description
A rule derived from principles.

## Based on Principles
{principle_links}

## Applied in Decisions
{decision_links}

## Related Rules
{rule_links}
"""
    
    with open(file_path, "w", encoding="utf-8") as f:
        f.write(content)

# Decision Notes
print("Generating Decision notes...")
for decision in decisions:
    safe_name = decision[:80].replace("/", "_").replace("\\", "_")
    file_path = os.path.join(base_dir, "Decisions", f"{safe_name}.md")
    
    rr = random.sample(rules, min(2, len(rules)))
    ro = random.sample(outcomes, min(3, len(outcomes)))
    rd = random.sample([d for d in decisions if d != decision], min(2, len(decisions)-1))
    
    rule_links = "\n".join([f"- [[Rule: {r}]]" for r in rr])
    outcome_links = "\n".join([f"- [[Outcome: {o}]]" for o in ro])
    decision_links = "\n".join([f"- [[Decision: {d}]]" for d in rd])
    
    content = f"""---
type: Decision
status: pending
tags: [decision, decision-making]
---

# {decision}

## Description
A specific decision made based on rules.

## Based on Rules
{rule_links}

## Leads to Outcomes
{outcome_links}

## Related Decisions
{decision_links}
"""
    
    with open(file_path, "w", encoding="utf-8") as f:
        f.write(content)

# Outcome Notes
print("Generating Outcome notes...")
for outcome in outcomes:
    safe_name = outcome[:80].replace("/", "_").replace("\\", "_")
    file_path = os.path.join(base_dir, "Outcomes", f"{safe_name}.md")
    
    rd = random.sample(decisions, min(2, len(decisions)))
    ro = random.sample([o for o in outcomes if o != outcome], min(2, len(outcomes)-1))
    rp = random.sample(principles, min(2, len(principles)))
    
    decision_links = "\n".join([f"- [[Decision: {d}]]" for d in rd])
    outcome_links = "\n".join([f"- [[Outcome: {o}]]" for o in ro])
    principle_links = "\n".join([f"- [[Principle: {p}]]" for p in rp])
    
    content = f"""---
type: Outcome
status: observed
tags: [outcome, decision-making]
---

# {outcome}

## Description
A result of a decision made.

## Caused by Decision
{decision_links}

## Related Outcomes
{outcome_links}

## Influences Principles
{principle_links}
"""
    
    with open(file_path, "w", encoding="utf-8") as f:
        f.write(content)

# ============ COUNT FILES ============
print("\n=== Generation Complete ===")
for d in ["Values", "Principles", "Rules", "Decisions", "Outcomes"]:
    count = len([f for f in os.listdir(os.path.join(base_dir, d)) if f.endswith(".md")])
    print(f"{d}: {count}")

total = sum(len([f for f in os.listdir(os.path.join(base_dir, d)) if f.endswith(".md")]) for d in ["Values", "Principles", "Rules", "Decisions", "Outcomes"])
print(f"Total: {total}")
