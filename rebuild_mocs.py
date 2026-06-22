# MOC Rebuilder
# Creates MOCs that link to 1 note per category, connected by global MOC

import os
import random

random.seed(77777)

base_dir = r"C:\obsidian\Main\Zetl"

# ============ VAULT STRUCTURE ============
vaults = {
    "KnowledgeGalaxy": {
        "clusters": {
            "Psychology": ["Cognitive Psychology", "Social Psychology", "Developmental Psychology", "Personality Psychology", "Clinical Psychology", "Emotional Psychology", "Motivation & Behavior"],
            "Philosophy": ["Metaphysics", "Epistemology", "Ethics", "Political Philosophy", "Aesthetics", "Existentialism & Phenomenology", "Logic"],
            "GameTheory": ["Core Concepts", "Classic Games", "Applications", "Mechanism Design", "Evolutionary Game Theory", "Decision Theory"],
            "Economics": ["Microeconomics", "Macroeconomics", "Financial Economics", "International Economics", "Behavioral Economics", "Institutional Economics"],
            "AI": ["Machine Learning", "Deep Learning", "NLP", "Computer Vision", "Reinforcement Learning", "AI Ethics & Safety", "AI Applications"],
            "Programming": ["Programming Languages", "Algorithms & Data Structures", "Software Architecture", "Web Development", "DevOps & Infrastructure", "Data Science", "Cybersecurity"],
            "Learning": ["Learning Theory", "Memory & Cognition", "Educational Technologies", "Neuroscience of Learning"],
            "Productivity": ["Time Management", "Productivity Systems", "Focus & Attention", "Decision Making & Thinking", "Personal Development"]
        }
    },
    "DecisionMaze": {
        "clusters": {
            "Decisions": ["Decision"],
            "Alternatives": ["Alternative"],
            "Consequences": ["Consequence"],
            "Constraints": ["Constraint"]
        }
    },
    "PersonalityGraph": {
        "clusters": {
            "Emotions": ["Emotion"],
            "Fears": ["Fear"],
            "Desires": ["Desire"],
            "Values": ["Value"],
            "Habits": ["Habit"],
            "Traits": ["Trait"],
            "Goals": ["Goal"]
        }
    },
    "ConflictGraph": {
        "clusters": {
            "Values": ["Value"],
            "Principles": ["Principle"],
            "Tradeoffs": ["Tradeoff"]
        }
    },
    "QuestionFractal": {
        "clusters": {
            "Questions": ["Question"],
            "Insights": ["Insight"]
        }
    },
    "BiasGraph": {
        "clusters": {
            "Biases": ["Bias"],
            "Errors": ["Error"],
            "Corrections": ["Correction"]
        }
    },
    "IdeaEcosystem": {
        "clusters": {
            "Ideas": ["Idea"],
            "Concepts": ["Concept"],
            "Memes": ["Meme"],
            "Counterideas": ["Counteridea"]
        }
    },
    "CausalLoop": {
        "clusters": {
            "Events": ["Event"],
            "Causes": ["Cause"],
            "Effects": ["Effect"],
            "FeedbackLoops": ["FeedbackLoop"]
        }
    },
    "IntellectualNetwork": {
        "clusters": {
            "Thinkers": ["Thinker"],
            "Ideas": ["Idea", "Shared Idea"],
            "Books": ["Book"],
            "Concepts": ["Concept", "Criticism"]
        }
    },
    "DecisionMakingGraph": {
        "clusters": {
            "Values": ["Value"],
            "Principles": ["Principle"],
            "Rules": ["Rule"],
            "Decisions": ["Decision"],
            "Outcomes": ["Outcome"]
        }
    },
    "zetl": {
        "clusters": {
            "Skills": ["Skill"],
            "Quests": ["Quest"],
            "Bosses": ["Boss"],
            "Rewards": ["Reward"],
            "Locations": ["Location"],
            "Obstacles": ["Obstacle"]
        }
    }
}

def get_representative_notes(cluster_dir, count=1):
    """Get 1 representative note from a cluster directory"""
    if not os.path.exists(cluster_dir):
        return []
    
    files = [f for f in os.listdir(cluster_dir) if f.endswith(".md") and not f.startswith("MOC")]
    if not files:
        return []
    
    # Pick 1 random representative
    return random.sample(files, min(count, len(files)))

def create_moc(name, notes, description="", connections=None):
    """Create a MOC file"""
    notes_md = "\n".join([f"- [[{n.replace('.md', '')}]]" for n in notes])
    
    connections_md = "\n## Connected MOCs\n- [[MOC Global]]"
    if connections:
        connections_md += "\n" + "\n".join([f"- [[{c}]]" for c in connections])
    
    content = f"""---
type: MOC
tags: [moc, map-of-content]
---

# {name}

## Description
{description}

## Notes (1 per category)
{notes_md}
{connections_md}
"""
    return content

# ============ CREATE CLUSTER MOCs ============
print("=== Creating Cluster MOCs ===")

cluster_mocs = {}  # vault -> [moc_names]

for vault_name, vault_data in vaults.items():
    vault_dir = os.path.join(base_dir, vault_name)
    if not os.path.exists(vault_dir):
        print(f"  Skipping {vault_name} (not found)")
        continue
    
    print(f"\nProcessing {vault_name}...")
    cluster_mocs[vault_name] = []
    
    for cluster_name, categories in vault_data["clusters"].items():
        cluster_dir = os.path.join(vault_dir, cluster_name)
        if not os.path.exists(cluster_dir):
            continue
        
        # Get 1 representative note from this cluster
        reps = get_representative_notes(cluster_dir, count=1)
        if not reps:
            continue
        
        moc_name = f"MOC {cluster_name}"
        cluster_mocs[vault_name].append(moc_name)
        
        # Find other cluster MOCs in same vault for connections
        same_vault_mocs = [m for m in cluster_mocs[vault_name] if m != moc_name]
        connections = same_vault_mocs[:3]  # Connect to up to 3 other clusters
        
        content = create_moc(
            name=moc_name,
            notes=reps,
            description=f"Map of Content for {cluster_name} cluster in {vault_name}",
            connections=connections
        )
        
        moc_path = os.path.join(cluster_dir, f"{moc_name}.md")
        with open(moc_path, "w", encoding="utf-8") as f:
            f.write(content)
        
        print(f"  Created {moc_name} with {len(reps)} notes")

# ============ CREATE GLOBAL MOC ============
print("\n=== Creating Global MOC ===")

# Collect all cluster MOCs
all_cluster_mocs = []
for vault_name, mocs in cluster_mocs.items():
    for moc in mocs:
        all_cluster_mocs.append(f"[[{moc}]]")

# Group by vault for the global MOC
vault_sections = []
for vault_name, mocs in cluster_mocs.items():
    if mocs:
        moc_links = "\n".join([f"- [[{m}]]" for m in mocs])
        vault_sections.append(f"## {vault_name}\n{moc_links}")

vault_sections_text = "\n\n".join(vault_sections)
all_mocs_text = "\n".join(all_cluster_mocs)

global_moc_content = f"""---
type: Global MOC
tags: [moc, global, map-of-content]
---

# Global Map of Content

## Description
Master index connecting all Maps of Content across all vaults.

{vault_sections_text}

## All Cluster MOCs
{all_mocs_text}
"""

# Save global MOC in each vault directory
for vault_name in vaults.keys():
    vault_dir = os.path.join(base_dir, vault_name)
    if os.path.exists(vault_dir):
        global_path = os.path.join(vault_dir, "MOC Global.md")
        with open(global_path, "w", encoding="utf-8") as f:
            f.write(global_moc_content)
        print(f"  Created MOC Global.md in {vault_name}")

# ============ UPDATE CLUSTER MOCs WITH GLOBAL LINK ============
print("\n=== Updating Cluster MOCs with Global Link ===")

for vault_name, mocs in cluster_mocs.items():
    vault_dir = os.path.join(base_dir, vault_name)
    if not os.path.exists(vault_dir):
        continue
    
    for moc_name in mocs:
        # Find which cluster this MOC belongs to
        for cluster_name in vaults[vault_name]["clusters"].keys():
            moc_path = os.path.join(vault_dir, cluster_name, f"{moc_name}.md")
            if os.path.exists(moc_path):
                with open(moc_path, "r", encoding="utf-8") as f:
                    content = f.read()
                
                # Add global MOC link if not present
                if "MOC Global" not in content:
                    content = content.replace(
                        "## Connected MOCs",
                        "## Connected MOCs\n- [[MOC Global]]"
                    )
                    with open(moc_path, "w", encoding="utf-8") as f:
                        f.write(content)
                
                break

print("\n=== Done! ===")
print(f"Created {sum(len(m) for m in cluster_mocs.values())} cluster MOCs")
print(f"Created 1 Global MOC in each vault")
