import os
import random
from datetime import datetime, timedelta

# Base paths
base_dir = "Knowledge/Reflections"
decisions_dir = "Knowledge/Decisions"
values_dir = "Knowledge/Values"

# Load existing data
def load_files(directory):
    files = []
    for filename in os.listdir(directory):
        if filename.endswith('.md'):
            files.append(filename)
    return files

decisions = load_files(decisions_dir)
values = load_files(values_dir)

# Generate remaining reflections
remaining_reflections = 250 - len(load_files(base_dir))
print(f"Generating {remaining_reflections} more reflections...")

for i in range(remaining_reflections):
    reflection_num = len(load_files(base_dir)) + i + 1
    reflection_name = f"Reflection_{reflection_num}"
    reflection_path = os.path.join(base_dir, f"{reflection_name}.md")
    
    # Select random decision
    decision_file = random.choice(decisions)
    decision_name = decision_file.replace('.md', '')
    
    # Select random values
    value1 = random.choice(values).replace('.md', '')
    value2 = random.choice(values).replace('.md', '')
    
    # Generate reflection content
    content = f"""---
type: reflection
status: active
created: 2026-06-22
last_reviewed: 2026-06-22
review_frequency: monthly
decision: [[{decision_name}]]
value: [[{value1}]]
value2: [[{value2}]]
---

# {reflection_name}

## What Happened
{random.choice(['An interesting experience occurred.', 'A significant event took place.', 'A challenging situation was encountered.', 'A positive outcome was achieved.', 'A lesson was learned through trial and error.'])}

## What I Learned
{random.choice(['I discovered new insights about myself.', 'I learned valuable skills and knowledge.', 'I understood the importance of persistence.', 'I realized the value of flexibility and adaptation.', 'I gained a deeper appreciation for the process.'])}

## What I'd Do Differently
{random.choice(['I would approach the situation more strategically.', 'I would seek more guidance and support.', 'I would allocate more time and resources.', 'I would prepare more thoroughly.', 'I would communicate more effectively.'])}

## Related Values
- [[{value1}]]
- [[{value2}]]
"""
    
    # Write reflection file
    with open(reflection_path, 'w') as f:
        f.write(content)
    
    if (i + 1) % 20 == 0:
        print(f"Generated {i + 1}/{remaining_reflections} reflections...")

print(f"Successfully generated {remaining_reflections} reflections!")