# Scripts Index

> All scripts in the vault. Updated: 2026-06-24
> Run via: `.\vault\run.ps1 <path>` (auto-logs to vault/log/script-history.md)

---

## Git Automation

| Script | Purpose |
|--------|---------|
| Technical/Scripts/Git/daily-push.ps1 | Daily git push automation |
| Technical/Scripts/Git/monitor-daily-push.ps1 | Monitor push status |
| Technical/Scripts/Git/threshold-git.ps1 | Threshold-based git operations |
| Technical/Scripts/Git/update-github-issues.ps1 | Update GitHub issues from vault |
| Calendula/git-monitor.ps1 | Git monitor for Calendula |
| Calendula/git-automation-monitor.ps1 | Automation monitor |

## Vault Operations

| Script | Purpose |
|--------|---------|
| Technical/Scripts/Vault/collect-mentions.ps1 | Collect mentions across vault |
| Technical/Scripts/Vault/Consolidate-PeopleSplit.ps1 | Consolidate people notes |
| Technical/Scripts/Vault/Split-DiaryPeople.ps1 | Split diary by people |
| Technical/Scripts/Vault/Restore-PeopleSplit.ps1 | Restore people from split |
| Technical/Scripts/Vault/Normalize-DayNoteNumbers.ps1 | Normalize day note numbering |
| Technical/Scripts/Vault/Move-TodayTasks.ps1 | Move today's tasks |
| Technical/Scripts/Vault/Sort-BoardTasks.ps1 | Sort board tasks |
| Technical/Scripts/Vault/generate_terms_v2.ps1 | Generate term definitions |
| Technical/Scripts/Vault/Watch-Kanban.ps1 | Watch kanban changes |
| Technical/Scripts/Vault/sync_leetcode.ps1 | Sync LeetCode progress |

## Graph Generation (Python)

| Script | Purpose |
|--------|---------|
| Zetl/generate_all_graphs.py | Regenerate all knowledge graphs |
| Zetl/generate_knowledge_graph.py | Knowledge graph generator v1 |
| Zetl/generate_knowledge_graph_v2.py | Knowledge graph generator v2 |
| Zetl/generate_knowledge_graph_v3.py | Knowledge graph generator v3 |
| Zetl/generate_projects.py | Generate project notes |
| Zetl/generate_goals.py | Generate goal structures |
| Zetl/generate_decisions.py | Generate decision trees |
| Zetl/generate_reflections.py | Generate reflection notes |
| Zetl/generate_personality_map.ps1 | Personality map generator |
| Zetl/create_mocs.py | MOC (Map of Content) generator |
| Zetl/rebuild_mocs.py | Rebuild all MOCs |
| Zetl/organize_zetl.py | Organize Zettelkasten notes |
| Zetl/BiasGraph/generate.py | Bias graph generator |
| Zetl/DecisionMakingGraph/generate.py | Decision making graph |
| Zetl/DecisionMaze/generate.py | Decision maze generator |
| Zetl/KnowledgeGalaxy/generate.py | Knowledge galaxy generator |
| Zetl/KnowledgeGraphs_Core/*/generate.py | Core knowledge graphs |
| Zetl/NeuralNetwork_Vault/*/generate.py | Neural network graphs |
| Zetl/PersonalityGraph/generate.py | Personality graph |
| Zetl/SmallGraphs1/generate.py | Small graphs set 1 |
| Zetl/SmallGraphs2/generate.py | Small graphs set 2 |

## Launchers

| Script | Purpose |
|--------|---------|
| Technical/Scripts/Launchers/run-discord-send-from-clipboard.ps1 | Send clipboard to Discord |
| Technical/Scripts/Launchers/run-normalize-daynote-numbers.ps1 | Quick normalize |
| Technical/Scripts/Launchers/run-split-diary-people.ps1 | Quick split diary |

## Discord

| Script | Purpose |
|--------|---------|
| Technical/Scripts/Discord/Send-FileToDiscord.ps1 | Send files to Discord channel |

## Obsidian

| Script | Purpose |
|--------|---------|
| Technical/Scripts/Obsidian/Build-CalendulaGraphStore.ps1 | Build graph store |
| Technical/Scripts/Obsidian/Measure-CalendulaGraphPerformance.ps1 | Measure graph perf |
| Technical/Scripts/Obsidian/Set-Calendula20KGraphProfile.ps1 | Set graph profile |

## Tests

| Script | Purpose |
|--------|---------|
| Technical/Tests/Scripts.Tests.ps1 | Script tests |
| Technical/Tests/test-legacy.ps1 | Legacy tests |
| Calendula/test-scripts.ps1 | Calendula tests |

---

## Log Structure

```
vault/log/
  activity.md              # Human-readable activity timeline
  script-history.md        # Every script run (date, script, branch, exit, duration, output)
  script/
    <name>.log             # Per-script execution history
    README.md              # This system's documentation
```

## Quick Start

```powershell
# Run any script with auto-logging
.\vault\run.ps1 .\Zetl\generate_projects.py

# View script history
cat vault/log/script-history.md

# View per-script logs
cat vault/log/script/daily-push.ps1.log
```
