# Generate personality map notes with proper links

# Define personality elements (without duplicates or empty strings)
$emotions = @(
    "Joy", "Sorrow", "Anxiety", "Contentment", "Awe", "Frustration", "Hope", "Despair", 
    "Pride", "Shame", "Curiosity", "Fearfulness", "Compassion", "Ambition", "Peacefulness",
    "Excitement", "Melancholy", "Determination", "Confusion", "Gratitude", "Resentment",
    "Optimism", "Pessimism", "Courage", "Indifference", "Enthusiasm", "Boredom", "Nostalgia",
    "Satisfaction", "Relief", "Jealousy", "Guilt", "Disgust", "Surprise", "Fascination"
)

$fears = @(
    "Failure", "Rejection", "Loss of Control", "Inadequacy", "Isolation", "Change", 
    "Uncertainty", "Aging", "Illness", "Death", "Financial Instability", "Relationship Breakdown",
    "Professional Stagnation", "Public Embarrassment", "Being Unseen", "Being Unheard",
    "Being Unappreciated", "Being Overwhelmed", "Being Trapped", "Being Vulnerable",
    "Being Forgotten", "Being Replaced", "Being Judged", "Being Criticized", "Being Ignored",
    "Being Alone", "Being Different", "Being Weak", "Being Incompetent", "Being Unworthy"
)

$desires = @(
    "Connection", "Achievement", "Security", "Growth", "Recognition", "Freedom", "Love",
    "Understanding", "Creativity", "Adventure", "Comfort", "Control", "Independence",
    "Purpose", "Legacy", "Knowledge", "Beauty", "Peace", "Excitement", "Validation",
    "Self-Expression", "Contribution"
)

$values = @(
    "Family", "Integrity", "Growth", "Relationships", "Achievement", "Security", "Freedom",
    "Knowledge", "Creativity", "Service", "Adventure", "Comfort", "Control", "Independence",
    "Purpose", "Legacy", "Love", "Understanding", "Beauty", "Honesty", "Loyalty", "Curiosity"
)

$habits = @(
    "Exercise", "Reading", "Meditation", "Planning", "Networking", "Learning", "Writing",
    "Cooking", "Cleaning", "Organizing", "Socializing", "Researching", "Reflecting",
    "Journaling", "Listening", "Questioning", "Helping", "Creating", "Problem-solving",
    "Debugging", "Testing", "Documenting", "Practicing", "Reviewing", "Preparing"
)

$traits = @(
    "Analytical", "Creative", "Persistent", "Adaptable", "Methodical", "Spontaneous", "Patient",
    "Impulsive", "Optimistic", "Pessimistic", "Confident", "Insecure", "Charismatic", "Reserved",
    "Empathetic", "Logical", "Intuitive", "Decisive", "Procrastinating", "Perfectionist",
    "Flexible", "Rigorous", "Organized", "Messy", "Risk-taking", "Risk-averse", "Curious",
    "Practical", "Imaginative", "Detail-oriented", "Big-picture", "Collaborative", "Independent"
)

$goals = @(
    "Career Advancement", "Financial Independence", "Strong Relationships", "Personal Growth",
    "Health and Fitness", "Knowledge Mastery", "Creative Expression", "Community Contribution",
    "Travel and Experience", "Family Legacy", "Skill Development", "Social Impact",
    "Innovation", "Leadership", "Artistic Achievement", "Research", "Teaching", "Writing",
    "Entrepreneurship", "Spiritual Development", "Work-Life Balance", "Legacy Building"
)

function Create-Note {
    param(
        [string]$folder,
        [string]$type,
        [string]$name,
        [hashtable]$properties,
        [string[]]$links
    )
    
    $filePath = "$folder\${type}_${name}.md"
    
    $yaml = "---`n"
    $yaml += "type: ${type}`n"
    foreach ($key in $properties.Keys) {
        $yaml += "${key}: $($properties[$key])`n"
    }
    $yaml += "---`n`n"
    
    $content = $yaml
    $content += "# ${type}: ${name}`n`n"
    
    if ($links.Count -gt 0) {
        $content += "## Related Notes`n"
        foreach ($link in $links) {
            $content += "[[${link}]]`n"
        }
        $content += "`n"
    }
    
    $content += "## Description`n"
    $content += "This note represents a ${type} in the personality map. `n"
    
    Set-Content -Path $filePath -Value $content -NoNewline
    Write-Host "Created: ${type}_${name}.md"
}

# Create all notes
$totalNotes = 0

# Emotions (35 notes)
Write-Host "Creating emotions..."
for ($i = 0; $i -lt 35; $i++) {
    $emotion = $emotions[$i]
    $fearLinks = @("Fear_${fears[0]}", "Fear_${fears[1]}", "Fear_${fears[2]}")
    $desireLinks = @("Desire_${desires[0]}", "Desire_${desires[1]}")
    $allLinks = $fearLinks + $desireLinks
    $properties = @{ "intensity" = "$(Get-Random -Minimum 1 -Maximum 10)"; "frequency" = "$(Get-Random -Minimum 1 -Maximum 10)" }
    Create-Note -folder "C:\obsidian\Main\Zetl\Emotions" -type "Emotion" -name $emotion -properties $properties -links $allLinks
    $totalNotes++
}

# Fears (35 notes)
Write-Host "Creating fears..."
for ($i = 0; $i -lt 35; $i++) {
    $fear = $fears[$i]
    $habitLinks = @()
    for ($j = 0; $j -lt 3; $j++) {
        $habitLinks += "Habit_${habits[$j]}"
    }
    $emotionLinks = @("Emotion_${emotions[$i]}", "Emotion_${emotions[$i+1]}")
    $allLinks = $habitLinks + $emotionLinks
    $properties = @{ "severity" = "$(Get-Random -Minimum 1 -Maximum 10)"; "trigger" = "$(Get-Random -Minimum 1 -Maximum 10)" }
    Create-Note -folder "C:\obsidian\Main\Zetl\Fears" -type "Fear" -name $fear -properties $properties -links $allLinks
    $totalNotes++
}

# Desires (30 notes)
Write-Host "Creating desires..."
for ($i = 0; $i -lt 30; $i++) {
    $desire = $desires[$i]
    $emotionLinks = @("Emotion_${emotions[$i]}", "Emotion_${emotions[$i+1]}")
    $valueLinks = @("Value_${values[$i]}", "Value_${values[$i+1]}")
    $allLinks = $emotionLinks + $valueLinks
    $properties = @{ "strength" = "$(Get-Random -Minimum 1 -Maximum 10)"; "urgency" = "$(Get-Random -Minimum 1 -Maximum 10)" }
    Create-Note -folder "C:\obsidian\Main\Zetl\Desires" -type "Desire" -name $desire -properties $properties -links $allLinks
    $totalNotes++
}

# Values (30 notes)
Write-Host "Creating values..."
for ($i = 0; $i -lt 30; $i++) {
    $value = $values[$i]
    $goalLinks = @("Goal_${goals[$i]}", "Goal_${goals[$i+1]}")
    $desireLinks = @("Desire_${desires[$i]}", "Desire_${desires[$i+1]}")
    $allLinks = $goalLinks + $desireLinks
    $properties = @{ "importance" = "$(Get-Random -Minimum 1 -Maximum 10)"; "flexibility" = "$(Get-Random -Minimum 1 -Maximum 10)" }
    Create-Note -folder "C:\obsidian\Main\Zetl\Values" -type "Value" -name $value -properties $properties -links $allLinks
    $totalNotes++
}

# Habits (30 notes)
Write-Host "Creating habits..."
for ($i = 0; $i -lt 30; $i++) {
    $habit = $habits[$i]
    $traitLinks = @()
    for ($j = 0; $j -lt 3; $j++) {
        $traitLinks += "Trait_${traits[$j]}"
    }
    $fearLinks = @("Fear_${fears[$i]}", "Fear_${fears[$i+1]}")
    $goalLinks = @("Goal_${goals[$i]}", "Goal_${goals[$i+1]}")
    $allLinks = $traitLinks + $fearLinks + $goalLinks
    $properties = @{ "frequency" = "$(Get-Random -Minimum 1 -Maximum 10)"; "difficulty" = "$(Get-Random -Minimum 1 -Maximum 10)" }
    Create-Note -folder "C:\obsidian\Main\Zetl\Habits" -type "Habit" -name $habit -properties $properties -links $allLinks
    $totalNotes++
}

# Traits (30 notes)
Write-Host "Creating traits..."
for ($i = 0; $i -lt 30; $i++) {
    $trait = $traits[$i]
    $habitLinks = @("Habit_${habits[$i]}", "Habit_${habits[$i+1]}")
    $fearLinks = @("Fear_${fears[$i]}", "Fear_${fears[$i+1]}")
    $allLinks = $habitLinks + $fearLinks
    $properties = @{ "stability" = "$(Get-Random -Minimum 1 -Maximum 10)"; "expression" = "$(Get-Random -Minimum 1 -Maximum 10)" }
    Create-Note -folder "C:\obsidian\Main\Zetl\Traits" -type "Trait" -name $trait -properties $properties -links $allLinks
    $totalNotes++
}

# Goals (30 notes)
Write-Host "Creating goals..."
for ($i = 0; $i -lt 30; $i++) {
    $goal = $goals[$i]
    $valueLinks = @("Value_${values[$i]}", "Value_${values[$i+1]}")
    $habitLinks = @("Habit_${habits[$i]}", "Habit_${habits[$i+1]}")
    $allLinks = $valueLinks + $habitLinks
    $properties = @{ "priority" = "$(Get-Random -Minimum 1 -Maximum 10)"; "timeline" = "$(Get-Random -Minimum 1 -Maximum 10)" }
    Create-Note -folder "C:\obsidian\Main\Zetl\Goals" -type "Goal" -name $goal -properties $properties -links $allLinks
    $totalNotes++
}

# Cycle notes (20 notes)
Write-Host "Creating cycle notes..."
for ($i = 0; $i -lt 20; $i++) {
    $cycleName = "Cycle_${i}"
    $fearLink = "Fear_${fears[$i]}"
    $habitLink = "Habit_${habits[$i]}"
    $outcomeLink = "Trait_${traits[$i]}"
    $cycleLink = "Fear_${fears[($i+1)%35]}"
    
    $properties = @{ "type" = "cycle"; "stage" = "feedback" }
    $allLinks = @($fearLink, $habitLink, $outcomeLink, $cycleLink)
    Create-Note -folder "C:\obsidian\Main\Zetl" -type "Cycle" -name $cycleName -properties $properties -links $allLinks
    $totalNotes++
}

Write-Host "Personality map creation complete!"
Write-Host "Total notes created: $totalNotes"