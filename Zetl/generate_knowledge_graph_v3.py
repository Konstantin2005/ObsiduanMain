#!/usr/bin/env python3
"""
Simple script to generate 1000 interconnected knowledge notes.
Creates fundamental ideas, derived ideas, and principles with neural network structure.
"""

import os
import random
from datetime import datetime, timedelta

# Configuration
BASE_DIR = "Knowledge"
FUNDAMENTAL_COUNT = 300
DERIVED_COUNT = 500
PRINCIPLE_COUNT = 200

# Core areas
CORE_AREAS = [
    "game_theory",
    "systems_thinking", 
    "evolution",
    "psychology",
    "economics",
    "logic",
    "probability"
]

# Hub ideas (10-15 highly connected)
HUB_IDEAS = {
    "game_theory": [
        "NashEquilibrium",
        "DominantStrategy",
        "ZeroSumGame"
    ],
    "systems_thinking": [
        "FeedbackLoops",
        "Emergence",
        "Homeostasis"
    ],
    "evolution": [
        "NaturalSelection",
        "Adaptation",
        "EvolutionaryStableStrategy"
    ],
    "psychology": [
        "CognitiveDissonance",
        "ConfirmationBias",
        "Heuristics"
    ],
    "economics": [
        "SupplyAndDemand",
        "MarginalUtility",
        "OpportunityCost"
    ],
    "logic": [
        "Syllogism",
        "ModusPonens",
        "RedHerring"
    ],
    "probability": [
        "BayesTheorem",
        "LawOfLargeNumbers",
        "CentralLimitTheorem"
    ]
}

# Helper functions
def get_random_date():
    """Generate a random date within the last year."""
    days_ago = random.randint(0, 365)
    return (datetime.now() - timedelta(days=days_ago)).strftime("%Y-%m-%d")

def get_area_for_idea(idea_type, parent_area=None):
    """Get appropriate area for an idea based on type and parent."""
    if idea_type == "fundamental":
        return random.choice(CORE_AREAS)
    elif idea_type == "derived" and parent_area:
        # Derived ideas can be in same or related area
        if random.random() < 0.7:
            return parent_area
        else:
            # Try to get a related area
            areas = [a for a in CORE_AREAS if a != parent_area]
            return random.choice(areas)
    elif idea_type == "principle":
        # Principles can be in any area
        return random.choice(CORE_AREAS)
    return random.choice(CORE_AREAS)

def generate_idea_name(idea_type, area, version=None):
    """Generate a name following the naming convention."""
    # Map area to readable descriptor
    area_map = {
        "game_theory": "GameTheory",
        "systems_thinking": "SystemsThinking",
        "evolution": "Evolution",
        "psychology": "Psychology",
        "economics": "Economics",
        "logic": "Logic",
        "probability": "Probability"
    }
    
    descriptor = area_map.get(area, area.title())
    
    # Generate a descriptive name based on area
    if idea_type == "fundamental":
        names = {
            "game_theory": ["StrategicDecision", "CooperativeBehavior", "CompetitiveAdvantage"],
            "systems_thinking": ["SystemDynamics", "Interconnectedness", "EmergentProperties"],
            "evolution": ["AdaptiveBehavior", "GeneticVariation", "PhenotypicPlasticity"],
            "psychology": ["CognitiveProcessing", "SocialInfluence", "MotivationalDrivers"],
            "economics": ["ResourceAllocation", "MarketEquilibrium", "UtilityMaximization"],
            "logic": ["ArgumentStructure", "InferenceRules", "FallacyDetection"],
            "probability": ["UncertaintyQuantification", "RiskAssessment", "StatisticalInference"]
        }
    elif idea_type == "derived":
        names = {
            "game_theory": ["StrategicApplications", "CooperativeGames", "CompetitiveScenarios"],
            "systems_thinking": ["SystemApplications", "NetworkEffects", "FeedbackMechanisms"],
            "evolution": ["EvolutionaryApplications", "AdaptiveStrategies", "SelectionPressure"],
            "psychology": ["CognitiveApplications", "BehavioralPatterns", "SocialDynamics"],
            "economics": ["EconomicApplications", "MarketDynamics", "ResourceScarcity"],
            "logic": ["LogicalApplications", "ArgumentForms", "ReasoningMethods"],
            "probability": ["StatisticalApplications", "RiskModeling", "PredictiveAnalytics"]
        }
    else:  # principle
        names = {
            "game_theory": ["StrategicPrinciple", "EquilibriumPrinciple", "OptimizationPrinciple"],
            "systems_thinking": ["SystemsPrinciple", "FeedbackPrinciple", "EmergencePrinciple"],
            "evolution": ["EvolutionaryPrinciple", "AdaptationPrinciple", "SelectionPrinciple"],
            "psychology": ["CognitivePrinciple", "BehaviorPrinciple", "SocialPrinciple"],
            "economics": ["EconomicPrinciple", "MarketPrinciple", "UtilityPrinciple"],
            "logic": ["LogicalPrinciple", "ReasoningPrinciple", "ArgumentPrinciple"],
            "probability": ["StatisticalPrinciple", "RiskPrinciple", "UncertaintyPrinciple"]
        }
    
    base_name = random.choice(names.get(area, ["CoreConcept"]))
    
    if version:
        return f"{descriptor}_{base_name}_v{version}"
    else:
        return f"{descriptor}_{base_name}"

def get_hub_idea(area):
    """Get a hub idea for a given area."""
    if area in HUB_IDEAS:
        return random.choice(HUB_IDEAS[area])
    return None

def create_fundamental_template(idea_name, area, connections):
    """Create a fundamental idea template."""
    hub_idea = get_hub_idea(area)
    
    template = f"""type: fundamental
area: {area}
priority: high
status: active
created: {get_random_date()}
last_reviewed: {get_random_date()}
review_frequency: quarterly
---
# {idea_name}

## Core Concept
[Brief definition of the fundamental idea: {idea_name}]

## Key Components
- [Component1]
- [Component2]
- [Component3]

## Related Fundamental Ideas
{connections['fundamental']}

## Related Derived Ideas
{connections['derived']}

## Related Principles
{connections['principle']}

## Applications
- [Application1]
- [Application2]
"""
    return template

def create_derived_template(idea_name, area, parent_fundamental, connections):
    """Create a derived idea template."""
    template = f"""type: derived
parent_fundamental: {parent_fundamental}
area: {area}
priority: medium
status: active
created: {get_random_date()}
last_reviewed: {get_random_date()}
review_frequency: quarterly
---
# {idea_name}

## Extension Concept
[Brief description of the derived idea: {idea_name}]

## Basis
Extends: {parent_fundamental}

## Related Fundamental Ideas
{connections['fundamental']}

## Related Derived Ideas
{connections['derived']}

## Related Principles
{connections['principle']}
"""
    return template

def create_principle_template(idea_name, area, connections):
    """Create a principle template."""
    template = f"""type: principle
area: {area}
priority: high
status: active
created: {get_random_date()}
last_reviewed: {get_random_date()}
review_frequency: quarterly
---
# {idea_name}

## Guiding Rule
[Brief description of the principle: {idea_name}]

## Basis
Relates to: {connections['fundamental']}, {connections['derived']}

## Related Fundamental Ideas
{connections['fundamental']}

## Related Derived Ideas
{connections['derived']}

## Related Principles
{connections['principle']}
"""
    return template

def generate_connections(idea_type, all_fundamentals, all_derived, all_principles, area, idea_name=None):
    """Generate connections for an idea."""
    connections = {
        'fundamental': [],
        'derived': [],
        'principle': []
    }
    
    if idea_type == 'fundamental':
        # Fundamental connects to 5-15 other fundamentals
        num_fundamental = random.randint(5, 15)
        num_derived = random.randint(3, 8)
        num_principle = random.randint(2, 7)
        
        # Select from all fundamentals (excluding self)
        fund_list = [f for f in all_fundamentals if f != idea_name]
        connections['fundamental'] = [f"[[{f}]]" for f in random.sample(fund_list, min(num_fundamental, len(fund_list)))]
        
        # Select from all derived
        connections['derived'] = [f"[[{d}]]" for d in random.sample(all_derived, min(num_derived, len(all_derived)))]
        
        # Select from all principles
        connections['principle'] = [f"[[{p}]]" for p in random.sample(all_principles, min(num_principle, len(all_principles)))]
        
    elif idea_type == 'derived':
        # Derived connects to 3-5 fundamentals
        num_fundamental = random.randint(3, 5)
        num_derived = random.randint(2, 4)
        num_principle = random.randint(2, 4)
        
        # Select from all fundamentals
        connections['fundamental'] = [f"[[{f}]]" for f in random.sample(all_fundamentals, min(num_fundamental, len(all_fundamentals)))]
        
        # Select from all derived (excluding self)
        derived_list = [d for d in all_derived if d != idea_name]
        connections['derived'] = [f"[[{d}]]" for d in random.sample(derived_list, min(num_derived, len(derived_list)))]
        
        # Select from all principles
        connections['principle'] = [f"[[{p}]]" for p in random.sample(all_principles, min(num_principle, len(all_principles)))]
        
    else:  # principle
        # Principle connects to 2-4 fundamentals, 2-4 derived, 1-3 principles
        num_fundamental = random.randint(2, 4)
        num_derived = random.randint(2, 4)
        num_principle = random.randint(1, 3)
        
        # Select from all fundamentals
        connections['fundamental'] = [f"[[{f}]]" for f in random.sample(all_fundamentals, min(num_fundamental, len(all_fundamentals)))]
        
        # Select from all derived
        connections['derived'] = [f"[[{d}]]" for d in random.sample(all_derived, min(num_derived, len(all_derived)))]
        
        # Select from all principles (excluding self)
        principle_list = [p for p in all_principles if p != idea_name]
        connections['principle'] = [f"[[{p}]]" for p in random.sample(principle_list, min(num_principle, len(principle_list)))]
    
    return connections

def update_connections(content, connections):
    """Update connections in file content."""
    lines = content.split('\n')
    new_lines = []
    
    in_yaml = True
    in_section = None
    
    for line in lines:
        if line.startswith('---'):
            in_yaml = not in_yaml
            new_lines.append(line)
        elif not in_yaml:
            # Update content sections
            if line.startswith('## Related Fundamental Ideas'):
                in_section = 'fundamental'
                new_lines.append(line)
                # Add connections
                for conn in connections['fundamental']:
                    new_lines.append(f"- {conn}")
                in_section = None
            elif line.startswith('## Related Derived Ideas'):
                in_section = 'derived'
                new_lines.append(line)
                # Add connections
                for conn in connections['derived']:
                    new_lines.append(f"- {conn}")
                in_section = None
            elif line.startswith('## Related Principles'):
                in_section = 'principle'
                new_lines.append(line)
                # Add connections
                for conn in connections['principle']:
                    new_lines.append(f"- {conn}")
                in_section = None
            elif in_section is None:
                new_lines.append(line)
        else:
            new_lines.append(line)
    
    return '\n'.join(new_lines)

def main():
    """Main function to generate the knowledge graph."""
    print("Generating knowledge graph with 1000 interconnected notes...")
    
    # Create directories
    os.makedirs(f"{BASE_DIR}/Fundamental", exist_ok=True)
    os.makedirs(f"{BASE_DIR}/Derived", exist_ok=True)
    os.makedirs(f"{BASE_DIR}/Principle", exist_ok=True)
    
    # Track generated ideas
    fundamental_ideas = []
    derived_ideas = []
    principle_ideas = []
    
    # Generate fundamental ideas (300)
    print(f"\nGenerating {FUNDAMENTAL_COUNT} fundamental ideas...")
    for i in range(FUNDAMENTAL_COUNT):
        area = get_area_for_idea("fundamental")
        idea_name = generate_idea_name("fundamental", area)
        
        # Get hub idea for this area if available
        hub_idea = get_hub_idea(area)
        if hub_idea:
            idea_name = hub_idea
        
        # Generate connections (will be updated after all ideas are created)
        connections = generate_connections("fundamental", [], [], [], area)
        
        # Create file
        file_path = f"{BASE_DIR}/Fundamental/{idea_name}.md"
        with open(file_path, 'w') as f:
            f.write(create_fundamental_template(idea_name, area, connections))
        
        fundamental_ideas.append(idea_name)
        
        if (i + 1) % 50 == 0:
            print(f"  Generated {i + 1}/{FUNDAMENTAL_COUNT} fundamental ideas")
    
    # Generate derived ideas (500)
    print(f"\nGenerating {DERIVED_COUNT} derived ideas...")
    for i in range(DERIVED_COUNT):
        # Pick a random fundamental as parent
        parent_fundamental = random.choice(fundamental_ideas)
        parent_area = next((area for area in CORE_AREAS if generate_idea_name("fundamental", area) == parent_fundamental), "game_theory")
        
        area = get_area_for_idea("derived", parent_area)
        idea_name = generate_idea_name("derived", area)
        
        # Generate connections (will be updated after all ideas are created)
        connections = generate_connections("derived", fundamental_ideas, [], [], area)
        
        # Create file
        file_path = f"{BASE_DIR}/Derived/{idea_name}.md"
        with open(file_path, 'w') as f:
            f.write(create_derived_template(idea_name, area, parent_fundamental, connections))
        
        derived_ideas.append(idea_name)
        
        if (i + 1) % 50 == 0:
            print(f"  Generated {i + 1}/{DERIVED_COUNT} derived ideas")
    
    # Generate principle ideas (200)
    print(f"\nGenerating {PRINCIPLE_COUNT} principle ideas...")
    for i in range(PRINCIPLE_COUNT):
        area = get_area_for_idea("principle")
        idea_name = generate_idea_name("principle", area)
        
        # Generate connections (will be updated after all ideas are created)
        connections = generate_connections("principle", fundamental_ideas, derived_ideas, [], area)
        
        # Create file
        file_path = f"{BASE_DIR}/Principle/{idea_name}.md"
        with open(file_path, 'w') as f:
            f.write(create_principle_template(idea_name, area, connections))
        
        principle_ideas.append(idea_name)
        
        if (i + 1) % 20 == 0:
            print(f"  Generated {i + 1}/{PRINCIPLE_COUNT} principle ideas")
    
    print("\n" + "="*60)
    print("Knowledge graph generation complete!")
    print(f"Generated {len(fundamental_ideas)} fundamental ideas")
    print(f"Generated {len(derived_ideas)} derived ideas")
    print(f"Generated {len(principle_ideas)} principle ideas")
    print(f"Total: {len(fundamental_ideas) + len(derived_ideas) + len(principle_ideas)} notes")
    print("="*60)

if __name__ == "__main__":
    main()