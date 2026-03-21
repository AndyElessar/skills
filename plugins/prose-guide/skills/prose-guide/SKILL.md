---
name: prose-guide
description: "Guide AI-native development using the PROSE methodology — Progressive Disclosure, Reduced Scope, Orchestrated Composition, Safety Boundaries, Explicit Hierarchy. Use when: setting up AI-native projects, creating agent primitives (.instructions.md, .prompt.md, .agent.md, SKILL.md, .spec.md, AGENTS.md), designing context engineering strategies, implementing spec-driven workflows, choosing agent delegation strategies (local vs async vs hybrid), scaling AI development to teams, assessing PROSE maturity level, or optimizing context window utilization. Also use when user mentions 'AI-native', 'agent primitives', 'context engineering', 'spec-driven development', 'AGENTS.md', 'agentic workflows', 'SKILL.md', 'agent skills', or asks how to make AI coding more reliable and repeatable."
---

# PROSE: AI-Native Development Methodology

PROSE defines an architectural style for reliable, scalable collaboration between humans and AI coding agents. Like REST for distributed systems, PROSE is model-agnostic and tool-agnostic.

## Decision Flow

| User Intent | Action |
|-------------|--------|
| "Set up AI-native project" | → [Getting Started](#getting-started) |
| "Create primitives for my project" | → [Agent Primitives](#discipline-2-agent-primitives) |
| "Optimize my AI context/instructions" | → [Context Engineering](#discipline-3-context-engineering) |
| "Run a named task / slash command" | → [Prompt Files vs Skills](#prompt-files-vs-skills--when-to-use-which) |
| "Package a reusable workflow / skill" | → [Prompt Files vs Skills](#prompt-files-vs-skills--when-to-use-which) |
| "How should I delegate to agents?" | → [Delegation Strategies](./references/delegation.md) |
| "Scale AI dev to my team" | → [Team Adoption](./references/team-adoption.md) |
| "APM / compile / deploy / CI/CD" | → [Tooling](./references/tooling.md) |
| "Assess / audit my setup" | → [Maturity Assessment](#maturity-assessment) |
| "Checklists / progression / docs" | → [Reference](./references/reference.md) |
| "Architect primitives from scratch" | → Defer to `prose-architect` skill |

## The Five PROSE Constraints

Every design decision should honor these constraints:

| Constraint | Principle | Failure It Prevents |
|------------|-----------|---------------------|
| **P** Progressive Disclosure | Context arrives just-in-time, not upfront | Context overload — model loses focus |
| **R** Reduced Scope | Match task size to context capacity | Scope creep — attention degrades |
| **O** Orchestrated Composition | Small primitives compose; monoliths collapse | Monolithic collapse — unpredictable results |
| **S** Safety Boundaries | Autonomy within explicit guardrails | Unbounded autonomy — unsafe behavior |
| **E** Explicit Hierarchy | Specificity increases as scope narrows | Flat guidance — context pollution |

For deep constraint definitions, see [constraints reference](./references/constraints.md).

## The Three Disciplines

PROSE is implemented through three interlocking disciplines:

### Discipline 1: Prompt Engineering

Transform natural language into structured, repeatable instructions using Markdown's semantic power.

**Key techniques:**
- **Context Loading** (P): Use Markdown links as context injection — `[Review patterns](./src/patterns/)`
- **Structured Thinking**: Headers and bullets create clear reasoning pathways
- **Role Activation**: "You are an expert [role]" triggers specialized knowledge
- **Tool Integration** (S): `Use MCP tool tool-name` connects to deterministic execution
- **Validation Gates** (S): "Stop and get user approval" for human oversight

**Example — Instead of** `Find and fix the bug`, **use:**

```markdown
You are an expert debugger specialized in this project.
Review [architecture](./docs/architecture.md) for context.

1. Review [error logs](./logs/error.log) and identify root cause
2. Use `azmcp-monitor-log-query` MCP tool for infrastructure logs
3. Propose 3 solutions with trade-offs
4. Present analysis to user — do not change files until approved
```

### Discipline 2: Agent Primitives

Composable, bounded configuration files that make prompt engineering reusable.

| Primitive | File | Purpose | PROSE Constraint |
|-----------|------|---------|-----------------|
| Instructions | `.instructions.md` | Always-on guidance with `applyTo` | O, E |
| Prompt Files | `.prompt.md` | Named on-demand tasks (slash commands) | O |
| Custom Agents | `.agent.md` | Role-based expertise + tool boundaries | S |
| Skills | `SKILL.md` | Packaged domain knowledge & auto-discovered workflows | P, O |
| Specifications | `.spec.md` | Implementation blueprints | R |
| Memory | `.memory.md` | Cross-session knowledge | P |
| Context Helpers | `.context.md` | Optimized information retrieval | P |
| Project Context | `AGENTS.md` | Universal agent instructions per directory | E |

**File structure:**
```
project/
├── AGENTS.md                            # Root: project-wide agent instructions
├── .github/
│   ├── instructions/
│   │   ├── frontend.instructions.md     # applyTo: "**/*.{jsx,tsx,css}"
│   │   ├── backend.instructions.md      # applyTo: "**/*.{py,go,java}"
│   │   └── testing.instructions.md      # applyTo: "**/test/**"
│   ├── agents/
│   │   ├── architect.agent.md           # Plans, cannot execute
│   │   ├── frontend-engineer.agent.md   # UI tools only
│   │   └── backend-engineer.agent.md    # API tools only
│   ├── prompts/
│   │   ├── security-review.prompt.md    # /security-review slash command
│   │   └── release-notes.prompt.md      # /release-notes slash command
│   ├── skills/
│   │   ├── code-review/SKILL.md         # Review capability (auto-discovered)
│   │   └── feature-impl/SKILL.md        # Implementation capability
│   └── specs/
│       └── api-endpoint.spec.md         # Feature blueprint
├── frontend/
│   └── AGENTS.md                        # Frontend-specific context
└── backend/
    └── AGENTS.md                        # Backend-specific context
```

For primitive templates and examples, see [primitives reference](./references/primitives.md).

### Discipline 3: Context Engineering

Strategic context window management — the key to scaling AI reliability.

**Core techniques:**

1. **Session Splitting** (R): Use distinct sessions for different phases (plan → implement → test). Fresh context = better focus.

2. **Modular Rule Loading** (P): Author `.instructions.md` with `applyTo` patterns. Only relevant rules load per file type.

3. **Hierarchical Discovery** (E): Nested `AGENTS.md` files — agents walk the directory tree and load closest context.
   ```
   project/
   ├── AGENTS.md                 # Root: project-wide principles
   ├── frontend/
   │   └── AGENTS.md            # Frontend-specific
   └── backend/
       └── AGENTS.md            # Backend-specific
   ```

4. **Memory-Driven Development**: `.memory.md` files preserve decisions and patterns across sessions.

5. **Context Optimization** (P): `.context.md` files accelerate information retrieval — curated summaries agents can load quickly.

6. **Cognitive Focus** (S): Agent modes constrain attention to relevant domains via tool boundaries.

## Getting Started

Follow this progression to build your AI-native environment:

### Step 1: Install Skills
```bash
apm install awesome-copilot/skill/<skill-name>
```
Skills auto-discover and load based on task relevance — no explicit invocation needed.

### Step 2: Create Instructions
1. Create root `AGENTS.md` with global project rules (universal across all coding agents)
2. Create domain-specific `.instructions.md` files with `applyTo` patterns
3. Use nested `AGENTS.md` files for domain-specific context in subdirectories

### Step 3: Configure Agents
Define domain-specific agents with explicit tool boundaries:
```yaml
---
description: 'Backend specialist with security focus'
tools: ['changes', 'codebase', 'editFiles', 'runCommands', 'search']
model: Claude Sonnet 4
---
```
Each agent gets only tools for its domain — preventing cross-domain security issues.

### Step 4: Create Prompt Files
Create `.prompt.md` files for named, repeatable tasks invoked via `/` slash commands:
```markdown
---
mode: agent
description: 'Review current file for security issues'
tools: ['codebase', 'search', 'problems']
---
Review ${file} for security vulnerabilities:
1. Check for hardcoded secrets and credentials
2. Identify injection risks and input validation gaps
3. Report findings with severity and remediation
```
Prompt files support built-in variables (`${selection}`, `${file}`, `${input:name}`) and can reference a custom agent via the `agent` field.

### Step 5: Build Skills
Package reusable domain knowledge and workflows as `SKILL.md` files:
```markdown
---
name: feature-impl
description: 'Implement features from specifications with validation gates'
---
# Feature Implementation

## Context Loading Phase
1. Review [specification](${specFile})
2. Analyze [existing patterns](./src/patterns/)

## Implementation Phase  
...

## Human Validation Gate
🚨 STOP: Review plan before proceeding.
```
Skills use progressive disclosure — agents load only the `name` and `description` at startup, then read the full `SKILL.md` body only when activated by a matching task. Skills can bundle scripts, templates, and references.

### Step 6: Create Specifications
Write `.spec.md` templates for repeatable feature planning. Specs bridge planning to implementation and enable parallel delegation.

### Quick Start Checklist
- [ ] Install relevant Skills for your stack
- [ ] Create root `AGENTS.md` with project rules
- [ ] Set up domain `.instructions.md` with `applyTo` patterns
- [ ] Configure custom `.agent.md` files with tool boundaries
- [ ] Create `.prompt.md` files for recurring tasks
- [ ] Create first `SKILL.md` for an auto-discovered capability
- [ ] Build first `.spec.md` template
- [ ] Practice spec-first: plan → implement → test

## Agentic Workflows

Workflows combine all three disciplines into end-to-end processes. Use `.prompt.md` for named on-demand tasks and `SKILL.md` for auto-discovered, resource-rich capabilities.

### Prompt Files vs Skills — When to Use Which

| Need | Use | Why |
|------|-----|-----|
| Named slash command (`/review`, `/release-notes`) | `.prompt.md` | Manual invocation, lightweight, supports `${variables}` |
| Auto-discovered workflow with bundled resources | `SKILL.md` | Progressive disclosure, scripts/references/assets |
| Quick one-shot repeatable task | `.prompt.md` | Lower overhead, single file |
| Cross-tool portable capability (VS Code + CLI + Coding Agent) | `SKILL.md` | Follows open Agent Skills standard |
| Task that runs inside a specific agent persona | `.prompt.md` | Set `agent:` in frontmatter to inherit tool set |

**Characteristics:**
- **Full Orchestration**: Combine prompt engineering + primitives + context engineering
- **Execution Flexibility**: Work locally in IDE or delegated to async agents
- **Validation Gates**: Human checkpoints at critical decisions
- **Self-Improving**: Include learning steps that update primitives post-execution

**Workflow pattern:**
1. **Context Loading** → Load specs, patterns, memory
2. **Mode Activation** → Trigger appropriate agent with tool boundaries
3. **Execution** → Guided by instructions, applied via `applyTo`
4. **Validation Gate** → Human approval at critical points
5. **Learning Integration** → Update `.memory.md` with patterns discovered

For delegation strategies (local vs async vs hybrid), see [delegation reference](./references/delegation.md).

## Maturity Assessment

Use this model to evaluate and improve your AI-native setup:

| Level | Name | Indicators |
|-------|------|------------|
| 0 | Ad-hoc | One-off prompts, no persistent context |
| 1 | Structured | `.instructions.md` used, some repeatability |
| 2 | Composed | Multiple primitives, validation gates, skills |
| 3 | Orchestrated | Multi-agent delegation, session splitting |
| 4 | Distributed | Primitives packaged as skills, ecosystem participation |

**PROSE compliance check:**

| Constraint | What to verify |
|------------|---------------|
| P | Context loads via links and `applyTo`, not inline dumps? |
| R | One concern per primitive? Fresh context per phase? |
| O | Small composing primitives, not mega-prompts? |
| S | Tool boundaries, knowledge scope, approval gates explicit? |
| E | Local rules inherit/override global? `AGENTS.md` hierarchy? |

**Common anti-patterns:**

| Symptom | Violation | Fix |
|---------|-----------|-----|
| 500+ line prompt | O | Decompose into primitives |
| All docs loaded upfront | P | Use links for just-in-time loading |
| No validation gates | S | Add human checkpoints |
| Same rules everywhere | E | Use `applyTo` + nested `AGENTS.md` |
| "Do everything" agent | R | Split into phases or agents |
| `applyTo: "**"` | P | Use specific globs |

## References

- [PROSE Constraints](./references/constraints.md) — Deep dive into the five constraints
- [Primitive Templates](./references/primitives.md) — Templates and examples for all primitive types
- [Delegation Strategies](./references/delegation.md) — Local, async, hybrid execution
- [Team Adoption](./references/team-adoption.md) — Scaling to organizations with spec-driven workflows
- [Tooling](./references/tooling.md) — APM, context compilation, CI/CD production deployment
- [Reference](./references/reference.md) — Checklists, mastery progression, documentation links, troubleshooting
