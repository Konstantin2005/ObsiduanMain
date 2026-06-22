import os
import random
from datetime import datetime, timedelta

# Base paths
base_dir = "Knowledge/Goals"
values_dir = "Knowledge/Values"
projects_dir = "Knowledge/Projects"

# Load existing data
def load_files(directory):
    files = []
    for filename in os.listdir(directory):
        if filename.endswith('.md'):
            files.append(filename)
    return files

values = load_files(values_dir)
projects = load_files(projects_dir)

# Generate remaining goals
remaining_goals = 100 - len(load_files(base_dir))
print(f"Generating {remaining_goals} more goals...")

for i in range(remaining_goals):
    goal_num = len(load_files(base_dir)) + i + 1
    goal_name = f"Goal_{goal_num}"
    goal_path = os.path.join(base_dir, f"{goal_name}.md")
    
    # Select random value
    value_file = random.choice(values)
    value_name = value_file.replace('.md', '')
    
    # Select random projects (1-2)
    project1_file = random.choice(projects)
    project1_name = project1_file.replace('.md', '')
    
    project2_file = random.choice(projects).replace('.md', '') if random.random() > 0.5 else ""
    
    # Generate goal overview
    overviews = [
        f"A goal to {random.choice(['improve health', 'develop new skills', 'achieve personal growth', 'build better habits', 'create meaningful impact'])}.",
        f"The pursuit of {random.choice(['better fitness', 'deeper knowledge', 'stronger relationships', 'greater creativity', 'enhanced well-being'])}.",
        f"An objective to {random.choice(['increase productivity', 'reduce stress', 'expand capabilities', 'achieve balance', 'gain new experiences'])}.",
        f"A target to {random.choice(['master new skills', 'achieve personal excellence', 'build resilience', 'develop wisdom', 'create value'])}.",
        f"An aim to {random.choice(['live authentically', 'serve others', 'innovate continuously', 'grow consciously', 'contribute meaningfully'])}."
    ]
    
    # Generate target date
    target_date = (datetime.now() + timedelta(days=random.randint(90, 365))).strftime("%Y-%m-%d")
    
    # Create goal content
    content = f"""---
type: goal
status: active
priority: {random.choice(['high', 'medium', 'low'])}
created: 2026-06-22
last_reviewed: 2026-06-22
review_frequency: monthly
value: [[{value_name}]]
project: [[{project1_name}]]
project2: [[{project2_file}]]
---

# {goal_name}

## Overview
{random.choice(overviews)}

## Target Date
{target_date}

## Priority
{random.choice(['high', 'medium', 'low'])}

## Status
Not Started

## Related Values
- [[{value_name}]]

## Related Projects
- [[{project1_name}]]
- [[{project2_file}]]
"""
    
    # Write goal file
    with open(goal_path, 'w') as f:
        f.write(content)
    
    if (i + 1) % 10 == 0:
        print(f"Generated {i + 1}/{remaining_goals} goals...")

print(f"Successfully generated {remaining_goals} goals!")