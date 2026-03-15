---
name: prose-guide
description: "Guide AI-native development using the PROSE methodology — Progressive Disclosure, Reduced Scope, Orchestrated Composition, Safety Boundaries, Explicit Hierarchy. Use when: setting up AI-native projects, creating agent primitives (.instructions.md, .prompt.md, .agent.md, .spec.md), designing context engineering strategies, implementing spec-driven workflows, choosing agent delegation strategies (local vs async vs hybrid), scaling AI development to teams, assessing PROSE maturity level, or optimizing context window utilization. Also use when user mentions 'AI-native', 'agent primitives', 'context engineering', 'spec-driven development', 'AGENTS.md', 'agentic workflows', or asks how to make AI coding more reliable and repeatable."
---

# PROSE: AI-Native Development Methodology

PROSE defines an architectural style for reliable, scalable collaboration between humans and AI coding agents. Like REST for distributed systems, PROSE is model-agnostic and tool-agnostic.

## Decision Flow

| User Intent | Action |
|-------------|--------|
| "Set up AI-native project" | → [Getting Started](#getting-started) |
| "Create primitives for my project" | → [Agent Primitives](#discipline-2-agent-primitives) |
| "Optimize my AI context/instructions" | → [Context Engineering](#discipline-3-context-engineering) |
| "Design a workflow / .prompt.md" | → [Agentic Workflows](#agentic-workflows) |
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
| Instructions | `.instructions.md` | Domain-specific guidance with `applyTo` | O, E |
| Custom Agents | `.agent.md` / `.chatmode.md` | Role-based expertise + tool boundaries | S |
| Agentic Workflows | `.prompt.md` | Reusable multi-step processes | O |
| Specifications | `.spec.md` | Implementation blueprints | R |
| Memory | `.memory.md` | Cross-session knowledge | P |
| Context Helpers | `.context.md` | Optimized information retrieval | P |

**File structure:**
```
.github/
├── copilot-instructions.md              # Global rules
├── instructions/
│   ├── frontend.instructions.md         # applyTo: "**/*.{jsx,tsx,css}"
│   ├── backend.instructions.md          # applyTo: "**/*.{py,go,java}"
│   └── testing.instructions.md          # applyTo: "**/test/**"
├── agents/                              # or chatmodes/
│   ├── architect.agent.md               # Plans, cannot execute
│   ├── frontend-engineer.agent.md       # UI tools only
│   └── backend-engineer.agent.md        # API tools only
├── prompts/
│   ├── code-review.prompt.md            # Review workflow
│   └── feature-spec.prompt.md           # Spec-first implementation
└── specs/
    └── api-endpoint.spec.md             # Feature blueprint
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
1. Create `.github/copilot-instructions.md` with global project rules
2. Create domain-specific `.instructions.md` files with `applyTo` patterns
3. Compile to `AGENTS.md` for universal portability across all coding agents

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

### Step 4: Build Workflows
Create `.prompt.md` files with validation gates:
```markdown
---
mode: agent
description: 'Feature implementation with validation gates'
---
## Context Loading Phase
1. Review [specification](${specFile})
2. Analyze [existing patterns](./src/patterns/)

## Implementation Phase  
...

## Human Validation Gate
🚨 STOP: Review plan before proceeding.
```

### Step 5: Create Specifications
Write `.spec.md` templates for repeatable feature planning. Specs bridge planning to implementation and enable parallel delegation.

### Quick Start Checklist
- [ ] Install relevant Skills for your stack
- [ ] Create `copilot-instructions.md` with project rules
- [ ] Set up domain `.instructions.md` with `applyTo` patterns
- [ ] Configure custom agents with tool boundaries
- [ ] Create first `.prompt.md` with validation gates
- [ ] Build first `.spec.md` template
- [ ] Practice spec-first: plan → implement → test

## Agentic Workflows

Workflows combine all three disciplines into end-to-end processes via `.prompt.md` files.

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
