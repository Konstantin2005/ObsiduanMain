# Add more personality map notes to reach 250-300 total

# Add more emotions
$additionalEmotions = @(
    "Nostalgia", "Satisfaction", "Anxiety", "Contentment", "Awe", "Frustration", "Hope", "Despair",
    "Pride", "Shame", "Curiosity", "Fearfulness", "Compassion", "Ambition", "Peacefulness",
    "Excitement", "Melancholy", "Determination", "Confusion", "Gratitude", "Resentment",
    "Optimism", "Pessimism", "Courage", "Indifference", "Enthusiasm", "Boredom", "Relief",
    "Jealousy", "Guilt", "Pride", "Disgust", "Surprise", "Fascination", "Anxiety", "Contentment"
)

# Add more fears
$additionalFears = @(
    "Failure", "Rejection", "Loss of Control", "Inadequacy", "Isolation", "Change", 
    "Uncertainty", "Aging", "Illness", "Death", "Financial Instability", "Relationship Breakdown",
    "Professional Stagnation", "Public Embarrassment", "Being Unseen", "Being Unheard",
    "Being Unappreciated", "Being Overwhelmed", "Being Trapped", "Being Vulnerable",
    "Being Forgotten", "Being Replaced", "Being Judged", "Being Criticized", "Being Ignored",
    "Being Alone", "Being Different", "Being Weak", "Being Incompetent", "Being Unworthy"
)

# Add more desires
$additionalDesires = @(
    "Connection", "Achievement", "Security", "Growth", "Recognition", "Freedom", "Love",
    "Understanding", "Creativity", "Adventure", "Comfort", "Control", "Independence",
    "Purpose", "Legacy", "Knowledge", "Beauty", "Peace", "Excitement", "Validation",
    "Self-Expression", "Contribution", "Adventure", "Comfort", "Control", "Independence",
    "Purpose", "Legacy", "Love", "Understanding", "Beauty", "Honesty", "Loyalty", "Curiosity",
    "Security", "Growth", "Achievement", "Recognition", "Freedom", "Creativity"
)

# Add more values
$additionalValues = @(
    "Family", "Integrity", "Growth", "Relationships", "Achievement", "Security", "Freedom",
    "Knowledge", "Creativity", "Service", "Adventure", "Comfort", "Control", "Independence",
    "Purpose", "Legacy", "Love", "Understanding", "Beauty", "Honesty", "Loyalty", "Curiosity",
    "Family", "Integrity", "Growth", "Relationships", "Achievement", "Security", "Freedom",
    "Knowledge", "Creativity", "Service", "Adventure", "Comfort", "Control", "Independence",
    "Purpose", "Legacy", "Love", "Understanding", "Beauty", "Honesty", "Loyalty", "Curiosity"
)

# Add more habits
$additionalHabits = @(
    "Exercise", "Reading", "Meditation", "Planning", "Networking", "Learning", "Writing",
    "Cooking", "Cleaning", "Organizing", "Exercise", "Socializing", "Researching", "Reflecting",
    "Journaling", "Listening", "Questioning", "Helping", "Creating", "Problem-solving",
    "Debugging", "Testing", "Documenting", "Practicing", "Reviewing", "Preparing",
    "Exercise", "Reading", "Meditation", "Planning", "Networking", "Learning", "Writing",
    "Cooking", "Cleaning", "Organizing", "Exercise", "Socializing", "Researching", "Reflecting",
    "Journaling", "Listening", "Questioning", "Helping", "Creating", "Problem-solving"
)

# Add more traits
$additionalTraits = @(
    "Analytical", "Creative", "Persistent", "Adaptable", "Methodical", "Spontaneous", "Patient",
    "Impulsive", "Optimistic", "Pessimistic", "Confident", "Insecure", "Charismatic", "Reserved",
    "Empathetic", "Logical", "Intuitive", "Decisive", "Procrastinating", "Perfectionist",
    "Flexible", "Rigorous", "Organized", "Messy", "Risk-taking", "Risk-averse", "Curious",
    "Practical", "Imaginative", "Detail-oriented", "Big-picture", "Collaborative", "Independent",
    "Analytical", "Creative", "Persistent", "Adaptable", "Methodical", "Spontaneous", "Patient",
    "Impulsive", "Optimistic", "Pessimistic", "Confident", "Insecure", "Charismatic", "Reserved",
    "Empathetic", "Logical", "Intuitive", "Decisive", "Procrastinating", "Perfectionist"
)

# Add more goals
$additionalGoals = @(
    "Career Advancement", "Financial Independence", "Strong Relationships", "Personal Growth",
    "Health and Fitness", "Knowledge Mastery", "Creative Expression", "Community Contribution",
    "Travel and Experience", "Family Legacy", "Skill Development", "Social Impact",
    "Innovation", "Leadership", "Artistic Achievement", "Research", "Teaching", "Writing",
    "Entrepreneurship", "Spiritual Development", "Work-Life Balance", "Legacy Building",
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

# Add more emotions
Write-Host "Adding more emotions..."
for ($i = 20; $i -lt 40; $i++) {
    $emotion = $additionalEmotions[$i-20]
    $fearLinks = @("Fear_${additionalFears[0]}", "Fear_${additionalFears[1]}", "Fear_${additionalFears[2]}")
    $desireLinks = @("Desire_${additionalDesires[0]}", "Desire_${additionalDesires[1]}")
    $allLinks = $fearLinks + $desireLinks
    $properties = @{ "intensity" = "$(Get-Random -Minimum 1 -Maximum 10)"; "frequency" = "$(Get-Random -Minimum 1 -Maximum 10)" }
    Create-Note -folder "C:\obsidian\Main\Zetl\Emotions" -type "Emotion" -name $emotion -properties $properties -links $allLinks
}

# Add more fears
Write-Host "Adding more fears..."
for ($i = 20; $i -lt 40; $i++) {
    $fear = $additionalFears[$i-20]
    $habitLinks = @()
    for ($j = 0; $j -lt 3; $j++) {
        $habitLinks += "Habit_${additionalHabits[$j]}"
    }
    $emotionLinks = @("Emotion_${additionalEmotions[$i-20]}", "Emotion_${additionalEmotions[$i-19]}")
    $allLinks = $habitLinks + $emotionLinks
    $properties = @{ "severity" = "$(Get-Random -Minimum 1 -Maximum 10)"; "trigger" = "$(Get-Random -Minimum 1 -Maximum 10)" }
    Create-Note -folder "C:\obsidian\Main\Zetl\Fears" -type "Fear" -name $fear -properties $properties -links $allLinks
}

# Add more desires
Write-Host "Adding more desires..."
for ($i = 20; $i -lt 40; $i++) {
    $desire = $additionalDesires[$i-20]
    $emotionLinks = @("Emotion_${additionalEmotions[$i-20]}", "Emotion_${additionalEmotions[$i-19]}")
    $valueLinks = @("Value_${additionalValues[$i-20]}", "Value_${additionalValues[$i-19]}")
    $allLinks = $emotionLinks + $valueLinks
    $properties = @{ "strength" = "$(Get-Random -Minimum 1 -Maximum 10)"; "urgency" = "$(Get-Random -Minimum 1 -Maximum 10)" }
    Create-Note -folder "C:\obsidian\Main\Zetl\Desires" -type "Desire" -name $desire -properties $properties -links $allLinks
}

# Add more values
Write-Host "Adding more values..."
for ($i = 20; $i -lt 40; $i++) {
    $value = $additionalValues[$i-20]
    $goalLinks = @("Goal_${additionalGoals[$i-20]}", "Goal_${additionalGoals[$i-19]}")
    $desireLinks = @("Desire_${additionalDesires[$i-20]}", "Desire_${additionalDesires[$i-19]}")
    $allLinks = $goalLinks + $desireLinks
    $properties = @{ "importance" = "$(Get-Random -Minimum 1 -Maximum 10)"; "flexibility" = "$(Get-Random -Minimum 1 -Maximum 10)" }
    Create-Note -folder "C:\obsidian\Main\Zetl\Values" -type "Value" -name $value -properties $properties -links $allLinks
}

# Add more habits
Write-Host "Adding more habits..."
for ($i = 20; $i -lt 40; $i++) {
    $habit = $additionalHabits[$i-20]
    $traitLinks = @()
    for ($j = 0; $j -lt 3; $j++) {
        $traitLinks += "Trait_${additionalTraits[$j]}"
    }
    $fearLinks = @("Fear_${additionalFears[$i-20]}", "Fear_${additionalFears[$i-19]}")
    $goalLinks = @("Goal_${additionalGoals[$i-20]}", "Goal_${additionalGoals[$i-19]}")
    $allLinks = $traitLinks + $fearLinks + $goalLinks
    $properties = @{ "frequency" = "$(Get-Random -Minimum 1 -Maximum 10)"; "difficulty" = "$(Get-Random -Minimum 1 -Maximum 10)" }
    Create-Note -folder "C:\obsidian\Main\Zetl\Habits" -type "Habit" -name $habit -properties $properties -links $allLinks
}

# Add more traits
Write-Host "Adding more traits..."
for ($i = 20; $i -lt 40; $i++) {
    $trait = $additionalTraits[$i-20]
    $habitLinks = @("Habit_${additionalHabits[$i-20]}", "Habit_${additionalHabits[$i-19]}")
    $fearLinks = @("Fear_${additionalFears[$i-20]}", "Fear_${additionalFears[$i-19]}")
    $allLinks = $habitLinks + $fearLinks
    $properties = @{ "stability" = "$(Get-Random -Minimum 1 -Maximum 10)"; "expression" = "$(Get-Random -Minimum 1 -Maximum 10)" }
    Create-Note -folder "C:\obsidian\Main\Zetl\Traits" -type "Trait" -name $trait -properties $properties -links $allLinks
}

# Add more goals
Write-Host "Adding more goals..."
for ($i = 20; $i -lt 40; $i++) {
    $goal = $additionalGoals[$i-20]
    $valueLinks = @("Value_${additionalValues[$i-20]}", "Value_${additionalValues[$i-19]}")
    $habitLinks = @("Habit_${additionalHabits[$i-20]}", "Habit_${additionalHabits[$i-19]}")
    $allLinks = $valueLinks + $habitLinks
    $properties = @{ "priority" = "$(Get-Random -Minimum 1 -Maximum 10)"; "timeline" = "$(Get-Random -Minimum 1 -Maximum 10)" }
    Create-Note -folder "C:\obsidian\Main\Zetl\Goals" -type "Goal" -name $goal -properties $properties -links $allLinks
}

# Add more cycle notes
Write-Host "Adding more cycle notes..."
for ($i = 10; $i -lt 20; $i++) {
    $cycleName = "Cycle_${i}"
    $fearLink = "Fear_${additionalFears[$i-10]}"
    $habitLink = "Habit_${additionalHabits[$i-10]}"
    $outcomeLink = "Trait_${additionalTraits[$i-10]}"
    $cycleLink = "Fear_${additionalFears[($i-10+1)%20]}"
    
    $properties = @{ "type" = "cycle"; "stage" = "feedback" }
    $allLinks = @($fearLink, $habitLink, $outcomeLink, $cycleLink)
    Create-Note -folder "C:\obsidian\Main\Zetl" -type "Cycle" -name $cycleName -properties $properties -links $allLinks
}

Write-Host "Additional personality map notes creation complete!"
Write-Host "Total notes created: $((40*7) + 10)"