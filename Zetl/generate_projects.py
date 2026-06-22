import os
import random
from datetime import datetime, timedelta

# Base paths
base_dir = "Knowledge/Projects"
goals_dir = "Knowledge/Goals"
values_dir = "Knowledge/Values"
concepts_dir = "Knowledge/Concepts"
topics_dir = "Knowledge/Topics"

# Load existing data
def load_files(directory):
    files = []
    for filename in os.listdir(directory):
        if filename.endswith('.md'):
            files.append(filename)
    return files

values = load_files(values_dir)
goals = load_files(goals_dir)
concepts = load_files(concepts_dir)
topics = load_files(topics_dir)

# Generate remaining projects
remaining_projects = 300 - len(load_files(base_dir))
print(f"Generating {remaining_projects} more projects...")

for i in range(remaining_projects):
    project_num = len(load_files(base_dir)) + i + 1
    project_name = f"Project_{project_num}"
    project_path = os.path.join(base_dir, f"{project_name}.md")
    
    # Select random goal
    goal_file = random.choice(goals)
    goal_name = goal_file.replace('.md', '')
    
    # Select random values
    value1 = random.choice(values).replace('.md', '')
    value2 = random.choice(values).replace('.md', '')
    
    # Select random concepts
    concept1 = random.choice(concepts).replace('.md', '')
    concept2 = random.choice(concepts).replace('.md', '')
    
    # Select random topics
    topic = random.choice(topics).replace('.md', '')
    
    # Select random dependency (optional)
    dependency = random.choice(load_files(base_dir)).replace('.md', '') if random.random() > 0.5 else ""
    
    # Select random MOC
    moc = random.choice(topics).replace('.md', '')
    
    # Generate dates
    date1 = (datetime.now() + timedelta(days=random.randint(30, 90))).strftime("%Y-%m-%d")
    date2 = (datetime.now() + timedelta(days=random.randint(90, 180))).strftime("%Y-%m-%d")
    
    # Create project content
    content = f"""---
type: project
project: {project_name}
status: active
created: 2026-06-22
last_reviewed: 2026-06-22
review_frequency: monthly
tags: #project/{project_name.lower().replace('_', '-')} #status/active #priority/{random.choice(['high', 'medium', 'low'])}
---

# {project_name}

## Overview
A project to {random.choice(['achieve specific goals', 'develop new skills', 'improve personal growth', 'create meaningful impact', 'build better habits'])}.

## Goals
- [[{goal_name}]]

## Current Progress
### Completed
- [x] Project setup
- [x] Initial planning

### In Progress
- [ ] Project implementation
- [ ] Progress tracking

### Not Started
- [ ] Project completion
- [ ] Review and evaluation

## Related Concepts
- [[{concept1}]]
- [[{concept2}]]

## Related Values
- [[{value1}]]
- [[{value2}]]

## Related Topics
- [[{topic}]]

## Resources
- [[Resource1]]
- [[Resource2]]

## Dependencies
- [[{dependency}]]

## Related MOCs
- [[{moc}]]

## Timeline
### Upcoming Milestones
- {date1}
- {date2}

### Past Milestones
- Started project - 2026-06-22

## Notes
Focus on consistent progress and continuous improvement.

## See Also
- [[{dependency}]]
"""
    
    # Write project file
    with open(project_path, 'w') as f:
        f.write(content)
    
    if (i + 1) % 10 == 0:
        print(f"Generated {i + 1}/{remaining_projects} projects...")

print(f"Successfully generated {remaining_projects} projects!")