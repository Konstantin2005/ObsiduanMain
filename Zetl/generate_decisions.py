import os
import random
from datetime import datetime, timedelta

# Base paths
base_dir = "Knowledge/Decisions"
projects_dir = "Knowledge/Projects"
reflections_dir = "Knowledge/Reflections"

# Load existing data
def load_files(directory):
    files = []
    for filename in os.listdir(directory):
        if filename.endswith('.md'):
            files.append(filename)
    return files

projects = load_files(projects_dir)
reflections = load_files(reflections_dir)

# Generate remaining decisions
remaining_decisions = 300 - len(load_files(base_dir))
print(f"Generating {remaining_decisions} more decisions...")

for i in range(remaining_decisions):
    decision_num = len(load_files(base_dir)) + i + 1
    decision_name = f"Decision_{decision_num}"
    decision_path = os.path.join(base_dir, f"{decision_name}.md")
    
    # Select random project
    project_file = random.choice(projects)
    project_name = project_file.replace('.md', '')
    
    # Select random reflection (optional)
    reflection_file = random.choice(reflections).replace('.md', '') if random.random() > 0.3 else ""
    
    # Generate decision context
    contexts = [
        f"Decided to {random.choice(['improve health', 'learn new skills', 'start a business', 'build relationships', 'develop habits'])}.",
        f"Chose between {random.choice(['two career paths', 'different learning methods', 'various investment options'])}.",
        f"Made a decision about {random.choice(['personal development', 'financial planning', 'time management', 'health optimization'])}.",
        f"Selected an approach to {random.choice(['achieve goals', 'solve problems', 'improve skills', 'build capabilities'])}.",
        f"Decided on a {random.choice(['lifestyle change', 'skill acquisition', 'relationship building', 'habit formation'])} approach."
    ]
    
    # Generate options
    option1 = f"Option 1: {random.choice(['Method A', 'Approach 1', 'Strategy X', 'Technique 1'])}"
    option2 = f"Option 2: {random.choice(['Method B', 'Approach 2', 'Strategy Y', 'Technique 2'])}"
    option3 = f"Option 3: {random.choice(['Method C', 'Approach 3', 'Strategy Z', 'Technique 3'])}"
    
    # Generate choice made
    choices = [option1, option2, option3]
    choice_made = random.choice(choices)
    
    # Generate rationale
    rationales = [
        f"Cost-effective and practical solution.",
        f"Aligns with long-term goals and values.",
        f"Minimal resource requirements.",
        f"High potential impact and benefits.",
        f"Easy to implement and maintain."
    ]
    
    # Generate outcome
    outcomes = [
        f"Positive results and improved situation.",
        f"Mixed results with some challenges.",
        f"Learning experience despite difficulties.",
        f"Unexpected benefits discovered.",
        f"Needs further refinement and adjustment."
    ]
    
    # Create decision content
    content = f"""---
type: decision
status: active
created: 2026-06-22
last_reviewed: 2026-06-22
review_frequency: monthly
project: [[{project_name}]]
reflection: [[{reflection_file}]]
---

# {decision_name}

## Context
{random.choice(contexts)}

## Options
- {option1}
- {option2}
- {option3}

## Choice Made
{choice_made}

## Rationale
{random.choice(rationales)}

## Outcome
{random.choice(outcomes)}

## Related Reflections
- [[{reflection_file}]]
"""
    
    # Write decision file
    with open(decision_path, 'w') as f:
        f.write(content)
    
    if (i + 1) % 20 == 0:
        print(f"Generated {i + 1}/{remaining_decisions} decisions...")

print(f"Successfully generated {remaining_decisions} decisions!")