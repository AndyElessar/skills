# RPI Workflow Plugin

An alternative implementation of the **RPI (Research → Plan → Implement → Review)** workflow, adapted from Microsoft's [hve-core](https://github.com/microsoft/hve-core) project.

This plugin replaces the original file-based artifact storage (`.copilot-tracking/` directory + manual `/clear` between phases) with **VS Code Memory (`vscode/memory`)** for seamless, session-scoped state management — and adds an **Orchestrator agent** that drives the entire workflow automatically through subagent delegation.

> **Source**: The RPI workflow was originally designed in [microsoft/hve-core — docs/rpi/README.md](https://github.com/microsoft/hve-core/blob/main/docs/rpi/README.md).

---

## What Is the RPI Workflow?

AI coding assistants are effective at simple tasks but often fail on complex ones. The root cause: AI can't distinguish between *investigating* and *implementing*. When you ask for code, it writes code — it doesn't stop to verify that patterns match your existing modules or that the APIs it's calling actually exist.

RPI solves this through a counterintuitive insight: **when AI knows it cannot implement, it stops optimizing for "plausible code" and starts optimizing for "verified truth."** The constraint changes the goal.

The workflow transforms complex coding tasks into validated solutions through four structured phases:

> **Uncertainty → Knowledge → Strategy → Working Code → Validated Code**

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

- A single **Orchestrator** agent coordinates all phases via subagent delegation — no manual switching or `/clear` required.
- All workflow artifacts are stored in **`vscode/memory`** (under `/memories/session/rpi/`) instead of workspace files, so your repo stays clean and artifacts are automatically cleaned up when the session ends.
- **Plan approval** is enforced as a hard gate — the Orchestrator halts and asks for explicit confirmation before any implementation begins.
- **Iteration routing** is automatic — Review findings are classified and routed back to the earliest affected phase.

---

## The Four Phases

### 🔬 Phase 1: Research (RPI Researcher)

Transforms uncertainty into verified knowledge.

- Investigates codebase, external APIs, and documentation using read-only tools.
- Documents findings with evidence and source references.
- Creates one recommended approach per scenario.
- Output: `/memories/session/rpi/research.md`

### 📋 Phase 2: Plan (RPI Planner)

Transforms knowledge into actionable strategy.

- Creates a coordinated implementation plan with phases, steps, and file references.
- Maps every objective to supporting research evidence.
- Identifies dependencies and defines measurable success criteria.
- **Requires explicit user approval before proceeding.**
- Output: `/memories/session/rpi/plan.md`

### ⚡ Phase 3: Implement (RPI Implementor)

Transforms strategy into working code.

- Executes each plan phase sequentially with full codebase access.
- Follows exact file paths, schemas, and patterns cited in the plan.
- Runs validation commands (lint, build, test) when specified.
- Output: Working code + `/memories/session/rpi/changes.md`

### ✅ Phase 4: Review (RPI Reviewer)

Transforms working code into validated code.

- Validates implementation against research and plan specifications.
- Checks convention compliance using instruction files.
- Grades findings by severity (Critical / Major / Minor).
- Recommends next action: Complete, Needs Rework, Research Gap, or Plan Gap.
- Output: `/memories/session/rpi/review.md`

---

## Included Agents

| Agent | User-invocable | Primary Role |
| --- | :---: | --- |
| `RPI Orchestrator` | ✅ | Coordinate the full RPI workflow |
| `RPI Researcher` | — | Read-only codebase and web research |
| `RPI Planner` | — | Produce an implementation plan for approval |
| `RPI Implementor` | — | Edit files and run validation for one approved phase |
| `RPI Reviewer` | — | Read-only review against plan and research |

Only the **RPI Orchestrator** should be invoked directly. The other four agents are internal subagents managed by the orchestrator.

---

## Quick Start

1. Open a workspace in VS Code.
2. Start a chat and select `@RPI Orchestrator`.
3. Describe your task — the orchestrator handles the rest:
   - Runs research, presents a summary.
   - Creates a plan, presents it for your **explicit approval**.
   - Implements in phases, tracks all changes.
   - Reviews the result and recommends the next action.

No manual `/clear` or phase switching required.

---

## Customization

To customize the workflow, copy the agent files into your workspace and edit them directly.

### Step 1: Copy Agent Files

#### PowerShell

```powershell
$dest = ".github\agents\rpi-workflow"
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
dest=".github/agents/rpi-workflow"
mkdir -p "$dest"

base="https://raw.githubusercontent.com/AndyElessar/skills/main/plugins/rpi-workflow/agents"
for f in rpi-{orchestrator,researcher,planner,implementor,reviewer}.agent.md; do
    curl -sL "$base/$f" -o "$dest/$f"
done
```

### Step 2: Edit the Copies

Edit files under `.github/agents/rpi-workflow/` as needed:

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
