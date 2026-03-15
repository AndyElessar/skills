# Agent Primitive Templates & Examples

## Instructions (`.instructions.md`)

**Purpose:** Domain-specific guidance that loads automatically via `applyTo` patterns.

**Template:**
```yaml
---
applyTo: "**/*.{ts,tsx}"
description: "TypeScript development guidelines with context engineering"
---
```

```markdown
# TypeScript Development Guidelines

## Context Loading
Review [project conventions](../docs/conventions.md) and
[type definitions](../types/index.ts) before starting.

## Requirements
- Use strict TypeScript configuration
- Implement error boundaries for React components
- Apply ESLint TypeScript rules consistently

## Validation Checklist
- [ ] JSDoc comments for all public APIs
- [ ] Unit tests in `__tests__/` directory
- [ ] Type exports in appropriate index files
```

---

## Custom Agents (`.agent.md` / `.chatmode.md`)

**Purpose:** Role-based expertise with explicit tool boundaries. Like professional licenses — each agent operates within its area of competence.

**Template:**
```yaml
---
description: 'Backend development specialist with security focus'
tools: ['changes', 'codebase', 'editFiles', 'runCommands', 'runTasks',
        'search', 'problems', 'testFailure', 'terminalLastCommand']
model: Claude Sonnet 4
---
```

```markdown
You are a backend development specialist focused on secure API development,
database design, and server-side architecture.

## Domain Expertise
- RESTful API design and implementation
- Database schema design and optimization
- Authentication and authorization systems

## Context Loading
Review [backend docs](../../docs/backend) for project-specific patterns.

## Tool Boundaries
- CAN: Modify backend code, run server commands, execute tests
- CANNOT: Modify client-side assets, access production systems
```

**Security boundary examples:**

| Agent | CAN | CANNOT |
|-------|-----|--------|
| Architect | Research, plan, design | Execute code, modify files |
| Frontend | Build UI, modify CSS/JSX | Access databases, run backend |
| Backend | Build APIs, run tests | Modify UI, deploy to production |
| Writer | Write docs, read code | Run code, modify source |

---

## Agentic Workflows (`.prompt.md`)

**Purpose:** Reusable multi-step processes that orchestrate primitives into end-to-end solutions.

**Template:**
```yaml
---
mode: agent
model: gpt-4
tools: ['codebase', 'search', 'problems', 'changes']
description: 'Feature implementation workflow with validation gates'
---
```

```markdown
# Feature Implementation from Specification

## Context Loading Phase
1. Review [project specification](${specFile})
2. Analyze [existing patterns](./src/patterns/)
3. Check [API documentation](./docs/api.md)

## Implementation Phase
Use semantic search to find similar implementations.
Follow [coding standards](./docs/standards.md).

## Structured Output
- [ ] Feature code in appropriate module
- [ ] Comprehensive unit tests (>90% coverage)
- [ ] Integration tests for API endpoints
- [ ] Documentation updates

## Human Validation Gate
🚨 STOP: Review implementation plan before proceeding.
Confirm: Architecture alignment, test strategy, breaking change impact.
```

---

## Specifications (`.spec.md`)

**Purpose:** Implementation-ready blueprints that bridge planning to implementation. Enable parallel delegation and deterministic outcomes.

**Template:**
```markdown
# Feature: [Feature Name]

## Problem Statement
[Business need this feature addresses]

## Approach
[High-level technical approach]

## Requirements
- [ ] Requirement 1 with acceptance criteria
- [ ] Requirement 2 with acceptance criteria

## API Contract
- Method: [GET|POST|PUT|DELETE]
- Path: `/api/v1/[resource]`
- Request/Response schema

## Security Requirements
- [ ] Input validation
- [ ] Authentication check
- [ ] Authorization check

## Testing Requirements
- [ ] Unit tests for business logic
- [ ] Integration tests for API
- [ ] Edge case coverage

## Implementation Checklist
- [ ] Code implementation
- [ ] Tests passing
- [ ] Documentation updated
- [ ] Code review approved
```

---

## Memory Files (`.memory.md`)

**Purpose:** Preserve project knowledge and decisions across sessions.

**Template:**
```markdown
# Project Memory

## Architecture Decisions
- [Date] Decision: [What was decided and why]

## Successful Patterns
- Pattern: [Description]
- Context: [When to use]
- Example: [Reference to implementation]

## Known Issues & Workarounds
- Issue: [Description]
- Workaround: [Current approach]

## Lessons Learned
- [Date] [What was learned from implementation]
```

---

## Context Helpers (`.context.md`)

**Purpose:** Curated summaries that accelerate agent information retrieval and reduce cognitive load.

**Template:**
```markdown
# [Domain] Context

## Quick Reference
[Concise summary of key facts agents need frequently]

## Architecture Overview
[Brief system architecture relevant to this domain]

## Key Files
- `src/auth/` — Authentication service
- `src/api/` — API endpoints
- `docs/` — Documentation

## Common Patterns
[Patterns used in this domain with brief examples]

## Gotchas
[Non-obvious things agents need to know]
```

---

## Composition Example

How primitives work together for "Implement secure user authentication":

1. **Agent activation** → `backend-engineer.agent.md` with security tools
2. **Instructions loaded** → `security.instructions.md` via `applyTo: "auth/**"`
3. **Context injected** → `[auth patterns](.memory.md#security)` + `[API standards](api-security.context.md)`
4. **Spec generated** → `user-auth.spec.md` using structured templates
5. **Workflow executed** → `implement-from-spec.prompt.md` with validation gates
6. **Learning captured** → Update `.memory.md` with patterns discovered
