# PROSE Constraints — Deep Reference

## P — Progressive Disclosure

> *"Context arrives just-in-time, not just-in-case."*

**Constraint:** Structure information to reveal complexity progressively. Agents access deeper detail only when contextually relevant.

**Why:** Context windows are finite. Loading everything upfront wastes capacity and dilutes attention. Progressive disclosure preserves context for what matters.

**Mechanisms:**
- Markdown links as lazy-loading pointers: `[auth patterns](./auth/patterns.md)`
- Skills metadata as capability indexes (name + description loaded first, body only when needed)
- `applyTo` patterns so instructions load only for matching files
- `.context.md` files as curated summaries for fast retrieval
- Hierarchical file references that reveal detail on demand

**Anti-patterns:**
- Dumping entire docs into system prompt
- Loading all instructions regardless of file type
- Using `applyTo: "**"` which burns context on every interaction

---

## R — Reduced Scope

> *"Match task size to context capacity."*

**Constraint:** Complex work is decomposed into tasks sized to fit available context. Each sub-task operates with fresh context and focused scope.

**Why:** Attention degrades with context length. When a task exceeds what an agent can hold in focus, quality suffers.

**Mechanisms:**
- Session splitting: plan → implement → test in separate sessions
- Subagent delegation for isolated subtasks
- Phased execution with clear phase boundaries
- `.spec.md` decomposition into independent tasks

**Anti-patterns:**
- "Find the bug, fix it, update tests, and refactor" in one session
- Accumulating context across many unrelated tasks
- "Do everything" agents with no scope limits

---

## O — Orchestrated Composition

> *"Simple things compose; complex things collapse."*

**Constraint:** Favor small, chainable primitives over monolithic frameworks. Build complex behaviors by composing well-defined units.

**Why:** LLMs reason better with clear, focused instructions. Monolithic prompts become unpredictable — small changes produce wildly different results.

**Mechanisms:**
- `.instructions.md` as atomic, targeted rules
- `.prompt.md` as reusable workflow compositions
- `.agent.md` as bounded capability units
- Skills as composable capability packages
- Explicit contracts between agents working in parallel

**Anti-patterns:**
- 500+ line mega-prompts capturing everything
- Single file with role + rules + examples + constraints + output format
- Debugging impossible because you can't tell which part failed

---

## S — Safety Boundaries

> *"Autonomy within guardrails."*

**Constraint:** Every agent operates within explicit boundaries: tools available (capability), context loaded (knowledge), and what requires human approval (authority).

**Why:** LLMs are non-deterministic. Unbounded autonomy + non-determinism = unpredictable, potentially unsafe behavior. Grounding outputs in deterministic tool execution transforms probabilistic generation into verifiable action.

**Mechanisms:**
- Tool whitelists in agent/chatmode definitions
- `applyTo` patterns for context scoping
- Validation gates requiring human approval before destructive actions
- MCP tools as truth anchors — code execution, API calls, file operations ground claims in reality
- Professional boundaries: architects plan, engineers build, writers document

**Template — Tool boundary in `.agent.md`:**
```yaml
---
description: 'Backend specialist with security focus'
tools: ['changes', 'codebase', 'editFiles', 'runCommands', 'search']
---
## Tool Boundaries
- CAN: Modify backend code, run server commands, execute tests
- CANNOT: Modify client-side assets, access production databases
```

**Anti-patterns:**
- Agents that can execute any command on any file
- No validation gates before destructive operations
- Missing professional boundaries between planning and execution agents

---

## E — Explicit Hierarchy

> *"Specificity increases as scope narrows."*

**Constraint:** Instructions form a hierarchy from global to local. Local context inherits from and may override global context.

**Why:** Different domains need different guidance. Global rules ensure consistency; local rules enable specialization. Hierarchy prevents context pollution.

**Mechanisms:**
- Root `AGENTS.md` → project-wide principles
- Nested `AGENTS.md` → domain-specific rules
- `.instructions.md` with `applyTo` patterns → file-type targeting
- `copilot-instructions.md` → global workspace rules

**Example hierarchy:**
```
project/
├── AGENTS.md                    # "Use TypeScript, follow REST conventions"
├── frontend/
│   ├── AGENTS.md               # "Use React, follow component patterns"
│   └── Button.tsx              # Inherits: root + frontend
└── backend/
    ├── AGENTS.md               # "Use Express, follow API patterns"
    └── auth.ts                 # Inherits: root + backend
```

**Anti-patterns:**
- Flat guidance: same rules applied everywhere
- Backend security rules loading when editing CSS
- No directory-level context differentiation

---

## The Minimal Sufficient Set

These five constraints are independently necessary and jointly sufficient:
- Remove P → context overload returns
- Remove R → scope creep returns
- Remove O → monolithic collapse returns
- Remove S → unbounded autonomy returns
- Remove E → context pollution returns

Together they manage context as a scarce resource while enabling reliable AI collaboration at scale.
