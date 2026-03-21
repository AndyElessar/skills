# Scaling PROSE to Teams & Organizations

## The Core Insight

AI productivity doesn't scale through isolation — it scales through explicit coordination primitives. The same Agent Primitives mastered individually become the shared language for team coordination.

When tribal knowledge becomes `.instructions.md` files, every developer and agent inherits the same understanding. When requirements become `.spec.md` files, everyone works from the same specification. When validation gates are built into workflows, quality remains consistent.

## Spec-Driven Team Workflow

The coordination framework follows five phases, each producing artifacts that serve as coordination mechanisms:

### Phase 1: Constitution (Setup once, refine quarterly)

**Who:** Tech leads, architects
**What:** Capture team standards as primitives

- Create root `AGENTS.md` with project-wide rules
- Create domain `.instructions.md` files with `applyTo` patterns
- Configure `.agent.md` files with professional boundaries
- Package compliance requirements as distributable skills

```bash
# Distribute standards across projects instantly
apm install acme-corp/security-standards
```

**Output:** Explicit, version-controlled standards that every developer and agent inherits automatically.

### Phase 2: Specify (Sprint planning / backlog refinement)

**Who:** Product owner + team
**What:** Translate requirements into `.spec.md` files

- Clear problem statement and approach
- Acceptance criteria and security considerations
- Version-controlled alongside code

**Benefit:** Multiple developers read the same spec and implement different components in parallel. No tribal knowledge dependency.

### Phase 3: Plan (Architecture review)

**Who:** Senior engineers, architects
**What:** Technical decisions documented as `.context.md` or planning docs

- Component breakdown and technology choices
- API contracts and database schema
- Integration points between components

**Validation gate:** Architecture must be approved before delegation. Architectural mistakes are expensive — this gate maintains quality while enabling AI productivity downstream.

### Phase 4: Tasks (Sprint breakdown)

**Who:** Whole team
**What:** Decompose plan into parallelizable GitHub Issues

- Each task is isolated and independently testable
- Clear acceptance criteria referencing spec and plan
- Assigned to developer + their agent
- Dependencies visible in GitHub Projects

### Phase 5: Implement (Developer + agent execution)

**Who:** Individual developers with agents
**What:** Execute using `SKILL.md` capabilities, `.agent.md` workflows, or async delegation

- Agent follows spec + plan + constitution (`.instructions.md`)
- Code committed to feature branch, PR opened
- **Validation gate:** Code review before merge — same standards for agent and human code

## Agent Onboarding (Enterprise)

Traditional developer onboarding: weeks of documentation, training, tribal knowledge absorption.

Agent onboarding: **deterministic, instant, enforceable through context injection.**

A coding agent receives:
- `security-policy.instructions.md` (loaded automatically via `applyTo`)
- `gdpr-compliance.instructions.md` (applied to data-handling files)
- `accessibility-standards.instructions.md` (applied to UI files)

Every standard applied instantly, consistently, verifiably. No training decay.

### Policies as Primitives

Enterprise governance transforms from a training challenge into an engineering problem:

| Traditional | PROSE Approach |
|-------------|---------------|
| 50-page security policy PDF | `security-policy.instructions.md` |
| 4-hour GDPR training video | `gdpr-compliance.instructions.md` |
| Wiki coding standards | `coding-standards.instructions.md` |

**Distribution via APM:**
```bash
apm install acme-corp/security-policy
apm install acme-corp/gdpr-compliance
```

Every project, every agent, instantly compliant. Policy updates propagate everywhere.

## Knowledge Sharing & Compound Intelligence

Each sprint improves the primitive library:

1. **After implementation:** Capture patterns in `.instructions.md` and `.memory.md`
2. **After failures:** Document anti-patterns and workarounds
3. **Sprint retrospective:** Refine primitives based on team experience
4. **Cross-team:** Package successful patterns as skills via APM

The team gets smarter collectively — compound intelligence that improves through iterative refinement.

## Implementation Roadmap

### Weeks 1-2: Foundation
- [ ] Create root `AGENTS.md` with team standards
- [ ] Set up domain `.instructions.md` files
- [ ] Configure basic agent boundaries

### Weeks 3-4: Workflows
- [ ] Create `.prompt.md` files for recurring team tasks
- [ ] Create first `SKILL.md` capabilities for complex team workflows
- [ ] Build `.spec.md` templates
- [ ] Practice spec-first workflow on one feature

### Weeks 5-6: Scale
- [ ] Introduce async delegation for mature workflows
- [ ] Establish code review process for agent-generated code
- [ ] Begin team-wide primitive library

### Ongoing: Compound Intelligence
- [ ] Sprint retrospectives refine primitives
- [ ] Package reusable patterns as skills
- [ ] Measure: coordination overhead, consistency, velocity

## Success Metrics

| Metric | What to Track |
|--------|--------------|
| Coordination overhead | Reduction in sync meetings needed |
| Consistency | Fewer "style" comments in code review |
| Onboarding speed | Time to first productive contribution |
| Knowledge reuse | Primitive reuse rate across team |
| Quality | Bug rate in agent-generated vs human code |
