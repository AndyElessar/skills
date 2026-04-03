# Validation Commands Reference

Commands for inspecting, validating, and debugging agent files. Use `PowerShell` first and `Bash` as fallback.

## Placeholders

- `<TARGET>`: target agent file path
- `<ROOT>`: repository root or search root

## Detect section patterns used by existing agent files

PowerShell:
```powershell
Get-ChildItem -Path "<ROOT>" -Recurse -File | Where-Object { $_.Name -ieq 'agents.md' -or $_.Name -like '*.agent.md' -or $_.FullName -match '[\\/]\.github[\\/]agents[\\/].+\.md$' } | ForEach-Object { $_.FullName; Select-String -Path $_.FullName -Pattern '^## ' | Select-Object -ExpandProperty Line }
```

Bash:
```bash
find "<ROOT>" -type f \( -iname "agents.md" -o -iname "*.agent.md" -o -path "*/.github/agents/*.md" \) -print0 | while IFS= read -r -d '' f; do echo "$f"; grep -nE '^## ' "$f"; done
```

## Inspect frontmatter keys (inside frontmatter block only)

PowerShell:
```powershell
$content = Get-Content "<TARGET>" -Raw; if ($content -match '(?s)^---\r?\n(.*?)\r?\n---') { $matches[1] -split "`r?`n" | Select-String -Pattern '^(description:|tools:|user-invocable:|name:|argument-hint:|model:|agents:)' }
```

Bash:
```bash
awk 'f;/^---$/{c++; if(c==1){f=1; next} if(c==2){exit}}' "<TARGET>" | grep -nE '^(description:|tools:|user-invocable:|name:|argument-hint:|model:|agents:)'
```

## Verify six-core coverage headings (template mode)

Matches Required Agent Sections headings and their known aliases.

PowerShell:
```powershell
Select-String -Path "<TARGET>" -Pattern '^## (Commands|Tools you can use|Testing|Validation|Quality checks|Project (Structure|Knowledge)|Code Style|Standards|Conventions|Git Workflow|Version control|Commit conventions|Boundaries)$'
```

Bash:
```bash
grep -nE '^## (Commands|Tools you can use|Testing|Validation|Quality checks|Project (Structure|Knowledge)|Code Style|Standards|Conventions|Git Workflow|Version control|Commit conventions|Boundaries)$' "<TARGET>"
```

## Verify mapped coverage (existing-schema mode)

PowerShell:
```powershell
Select-String -Path "<TARGET>" -Pattern '^## '
```

Bash:
```bash
grep -nE '^## ' "<TARGET>"
```

## Check that commands include executable syntax

PowerShell:
```powershell
Select-String -Path "<TARGET>" -Pattern 'build|test|lint|check|verify|publish|deploy'
```

Bash:
```bash
grep -nE 'build|test|lint|check|verify|publish|deploy' "<TARGET>"
```
