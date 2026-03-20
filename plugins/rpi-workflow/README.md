# RPI Workflow Plugin

An alternative implementation of the **RPI (Research → Plan → Implement → Review)** workflow, adapted from Microsoft's [hve-core](https://github.com/microsoft/hve-core) project. This version extends the original four-phase model with a fifth phase, **Discover**, and introduces adaptive difficulty assessment.

This plugin replaces the original file-based artifact storage (`.copilot-tracking/` directory + manual `/clear` between phases) with **VS Code Memory (`vscode/memory`)** for seamless, session-scoped state management, and adds an **Orchestrator agent** that drives the entire workflow automatically through subagent delegation.

> **Source**: The RPI workflow was originally designed in [microsoft/hve-core — docs/rpi/README.md](https://github.com/microsoft/hve-core/blob/main/docs/rpi/README.md).

---

## What Is the RPI Workflow?

AI coding assistants are effective at simple tasks but often fail on complex ones. The root cause: AI can't distinguish between *investigating* and *implementing*. When you ask for code, it writes code — it doesn't stop to verify that patterns match your existing modules or that the APIs it's calling actually exist.

RPI solves this through a counterintuitive insight: **when AI knows it cannot implement, it stops optimizing for "plausible code" and starts optimizing for "verified truth."** The constraint changes the goal.

The workflow transforms complex coding tasks into validated solutions through five structured phases:

> **Uncertainty → Knowledge → Strategy → Working Code → Validated Code → Follow-Up Discovery**

### Key Benefits

- Uses verified existing patterns instead of inventing plausible ones.
- Traces every decision to specific files and line numbers.
- Creates research documents anyone can follow, eliminating tribal knowledge.

### When to Use RPI

| Use RPI When…                    | Use Quick Edits When…  |
| -------------------------------- | ---------------------- |
| Changes span multiple files      | Fixing a typo          |
| Learning new patterns or APIs    | Adding a log statement |
| External dependencies involved   | Refactoring < 50 lines |
| Requirements are unclear         | Change is obvious      |

**Rule of Thumb**: If you need to *understand something* before implementing, use RPI.

---

## How This Plugin Differs from the Original

The original hve-core RPI workflow requires the user to **manually invoke four separate agents** in sequence, run `/clear` between phases to avoid context contamination, and store artifacts as dated markdown files in a `.copilot-tracking/` directory.

This plugin automates the entire flow:

- A single **Orchestrator** agent coordinates all phases via subagent delegation. No manual switching or `/clear` required.
- **Difficulty assessment** classifies tasks as Simple, Medium, or Complex and adjusts workflow depth accordingly (Simple tasks skip Research and formal Review).
- All workflow artifacts are stored in **`vscode/memory`** (under `/memories/session/rpi/`) instead of workspace files, so your repo stays clean and artifacts are automatically cleaned up when the session ends.
- **Plan approval** is enforced as a hard gate. The Orchestrator halts and asks for explicit confirmation before any implementation begins (Medium and Complex tasks).
- **Iteration routing** is automatic. Review findings are classified and routed back to the earliest affected phase.
- A **Discover** phase runs after Review, surfacing 3–5 high-value follow-up suggestions the user can continue with immediately.
- **Session resumption** recovers gracefully when memory artifacts from a prior session exist, letting you continue where you left off.

---

## Difficulty Assessment

Before entering Phase 1, the Orchestrator classifies task difficulty. This classification is dynamic and can be upgraded mid-workflow if new complexity emerges.

| Difficulty | Typical Signals | Workflow Adjustment |
| --- | --- | --- |
| Simple | Small, localized edits; low ambiguity; ≤ 2 files | Skip Research. Lightweight plan checklist. Skip formal Review. |
| Medium | A few related files; some investigation required | All five phases, concise artifacts. Plan approval still required. |
| Complex | Cross-cutting changes; competing approaches; substantial risk | All five phases with full artifact depth and formal review. |

---

## The Five Phases

### 🔬 Phase 1: Research (RPI Researcher)

Transforms uncertainty into verified knowledge.

- Investigates codebase, external APIs, and documentation using read-only tools (including a browser for JavaScript-rendered pages).
- Evaluates competing approaches with a technical scenario analysis, including architecture diagrams (Mermaid) when multi-component interaction is involved.
- Documents findings with evidence and source references.
- Creates one recommended approach per scenario with concrete code examples.
- Flags open questions for the user and suggests deeper research areas.
- Output: `/memories/session/rpi/research.md`

### 📋 Phase 2: Plan (RPI Planner)

Transforms knowledge into actionable strategy.

- Creates a coordinated implementation plan with phases, steps, and file references.
- Maps every objective to supporting research evidence.
- Distinguishes user-stated requirements from planner-derived objectives.
- Marks phases with parallelization indicators so the Orchestrator can delegate efficiently.
- Identifies dependencies and defines measurable success criteria.
- Logs discrepancies, implementation paths considered, and suggested follow-on work.
- Can ask the user questions directly when planning reveals decision points.
- **Requires explicit user approval before proceeding** (Medium and Complex tasks).
- Output: `/memories/session/rpi/plan.md` + `/memories/session/rpi/plan-log.md`

### ⚡ Phase 3: Implement (RPI Implementor)

Transforms strategy into working code.

- Receives one or more plan phases per delegation. The Orchestrator chooses a strategy: sequential (dependent phases), parallel (independent phases), or batched (tightly related phases).
- Follows exact file paths, schemas, and patterns cited in the plan.
- Reads applicable instruction files and mirrors existing code conventions.
- Runs validation commands (lint, build, test), auto-discovering them from project config when not specified in the plan.
- Reports blockers with recommended resolution paths instead of guessing.
- Supports resumption: skips completed phases and resumes from the first incomplete step.
- Output: Working code + `/memories/session/rpi/changes.md`

### ✅ Phase 4: Review (RPI Reviewer)

Transforms working code into validated code.

- Validates implementation against research and plan specifications.
- Checks convention compliance using instruction files.
- Assesses code quality, architecture alignment, security posture, and error handling.
- Runs validation commands independently and records pass/fail results.
- Tracks implementation decisions made during Phase 3 and flags any that should be revisited.
- Grades findings by severity (Critical / Major / Minor).
- Recommends next action: Complete, Needs Rework, Research Gap, or Plan Gap.
- Output: `/memories/session/rpi/review.md`

### 🔍 Phase 5: Discover

Identifies follow-up work after Review completes.

- Reviews conversation history and all memory artifacts to summarize what was accomplished.
- Collects candidate follow-up items from the review, plan log, and research.
- Presents 3–5 high-value suggestions prioritized by impact and dependency order.
- The user selects an option to start a new workflow cycle, or describes different work.
- Output: Suggested next work items (presented inline, not persisted to memory).

---

## Memory Artifacts

All session state lives under `/memories/session/rpi/`. Artifacts are created and updated progressively as the workflow advances.

| File | Written By | Purpose |
| ------ | --------- | -------- |
| `goal.md` | Orchestrator | Original task description, user requirements, and acceptance criteria |
| `research.md` | Researcher | Consolidated research: scope, findings, alternatives, selected approach, open questions |
| `plan.md` | Planner | Implementation plan: objectives, phases, steps, dependencies, success criteria |
| `plan-log.md` | Planner | Planning log: discrepancies, implementation paths, follow-on work |
| `changes.md` | Implementor | Progressive change log: per-phase changes, validation results, deviations |
| `review.md` | Reviewer | Review findings: severity-graded issues, plan compliance, quality assessment |

---

## Included Agents

| Agent | User-invocable | Primary Role |
| --- | :---: | --- |
| `RPI Orchestrator` | ✅ | Coordinate the full five-phase workflow with difficulty-based adaptation |
| `RPI Researcher` | — | Read-only codebase, web, and browser research |
| `RPI Planner` | — | Produce a parallelization-aware implementation plan for approval |
| `RPI Implementor` | — | Edit files and run validation for one or more approved phases |
| `RPI Reviewer` | — | Read-only review with validation command execution |

Only the **RPI Orchestrator** should be invoked directly. The other four agents are internal subagents managed by the orchestrator.

---

## Quick Start

1. Open a workspace in VS Code.
2. Start a chat and select `RPI Orchestrator` agent.
3. Describe your task. The orchestrator handles the rest:
   - Assesses difficulty (Simple / Medium / Complex) and adjusts workflow depth.
   - Runs research, presents a summary (skipped for Simple tasks).
   - Creates a plan, presents it for your **explicit approval** (Medium and Complex tasks).
   - Implements in phases (sequential, parallel, or batched), tracks all changes.
   - Reviews the result and recommends the next action (skipped for Simple tasks).
   - Surfaces follow-up suggestions so you can continue with the next high-value task.
4. If you resume a conversation with existing artifacts, the orchestrator detects prior progress and offers to continue, restart, or review status.

---

## Customization

To customize the workflow, copy the agent files into your workspace and edit them directly.

### Step 1: Copy Agent Files

#### PowerShell

```powershell
$dest = ".github\agents"
New-Item -ItemType Directory -Path $dest -Force

$base = "https://raw.githubusercontent.com/AndyElessar/skills/main/plugins/rpi-workflow/agents"
@(
    "rpi-orchestrator.agent.md",
    "rpi-researcher.agent.md",
    "rpi-planner.agent.md",
    "rpi-implementor.agent.md",
    "rpi-reviewer.agent.md"
) | ForEach-Object { Invoke-WebRequest "$base/$_" -OutFile "$dest\$_" }
```

#### Bash

```bash
dest=".github/agents"
mkdir -p "$dest"

base="https://raw.githubusercontent.com/AndyElessar/skills/main/plugins/rpi-workflow/agents"
for f in rpi-{orchestrator,researcher,planner,implementor,reviewer}.agent.md; do
    curl -sL "$base/$f" -o "$dest/$f"
done
```

### Step 2: Edit the Copies

Edit files under `.github/agents/` as needed:

- Add tools — e.g. append `browser` to the Implementor's `tools:` list.
- Change model — update any agent's `model:` field.
- Adjust behavior — modify the agent body text.

### Step 3: Update the Orchestrator (if renaming)

If you change a subagent's `name:` in its frontmatter, update the Orchestrator's `agents:` list to match:

```yaml
agents: [RPI Researcher, RPI Planner, RPI Implementor, RPI Reviewer]
```

No Orchestrator change is needed if you only modify tools, model, or body text.

> **Note**: Workspace agents in `.github/agents/` take precedence over plugin-installed agents with the same name.

---

## Credits

- **Original RPI Workflow**: [microsoft/hve-core](https://github.com/microsoft/hve-core) — [docs/rpi/README.md](https://github.com/microsoft/hve-core/blob/main/docs/rpi/README.md)
- **This Plugin**: An alternative implementation using `vscode/memory` for artifact storage and an orchestrator-driven subagent architecture. See the [source repository](https://github.com/AndyElessar/skills) for the latest version.
