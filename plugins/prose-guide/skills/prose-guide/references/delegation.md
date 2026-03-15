# Agent Delegation Strategies

## Strategy Overview

The same agentic workflow can be executed through different strategies based on needs:

| Strategy | Control | Speed | Learning | Best For |
|----------|---------|-------|----------|----------|
| Local IDE | High | Low | High | New workflows, complex tasks, learning |
| Async Single Agent | Low | High | Low | Mature workflows, proven patterns |
| Async Multi-Agent | Low | Highest | Low | Parallelizable specs, large features |
| Hybrid | Medium | Medium | Medium | Balanced approach, iterative work |

## Decision Matrix

| Situation | Local | Async | Hybrid |
|-----------|:-----:|:-----:|:------:|
| First time with this workflow | ✅ | ❌ | ✅ |
| Well-established workflow | ❌ | ✅ | ❌ |
| High-risk / critical feature | ✅ | ❌ | ✅ |
| Need speed / parallel work | ❌ | ✅ | ✅ |
| Want to learn & understand | ✅ | ❌ | ✅ |

## Local IDE Execution

Execute workflows directly in your IDE for maximum control.

**Pattern:**
1. Select workflow → `/workflow-name` in chat
2. Prepare context → Ensure specs and files are ready
3. Execute with control → Provide input at validation gates
4. Capture learning → Document insights, refine workflow

**When to use:**
- New or unproven workflows
- Complex requirements needing human judgment
- Learning how your primitives perform
- High-stakes features where mistakes are costly

## Async Single Agent Delegation

Hand off complete workflows to GitHub Coding Agents.

**Methods:**
- **VS Code**: Use `#copilotCodingAgent` in Ask chat mode
- **GitHub MCP Server**: `create_issue` + `assign_copilot_to_issue`
- **GitHub Web**: Direct via Agents control plane

**Pattern:**
1. Validate `.spec.md` with human reviewer
2. Delegate via chosen method with spec reference
3. Monitor progress through PR updates
4. Review and merge results

**When to use:**
- Mature, well-tested workflows
- Clear specifications with low ambiguity
- Tasks that can run overnight
- Repetitive implementations following proven patterns

## Async Multi-Agent (Spec-to-Issues Pattern)

Decompose specs into parallel workstreams for maximum throughput.

**Pattern:**
1. **Decompose** → Break spec into non-overlapping components
2. **Map dependencies** → Define integration points and sequence
3. **Create issues** → Use GitHub MCP `create_issue` for each component
4. **Delegate in parallel** → `assign_copilot_to_issue` for each
5. **Monitor & integrate** → Review PRs, merge in dependency order

**Key rules:**
- Components must be independent (no overlapping file modifications)
- Each issue references shared architecture context
- Define implementation order based on dependencies
- Use sub-issue hierarchies for dependency chains

## Hybrid Orchestration

Combine local control with async delegation.

**Pattern:**
1. **Plan locally** → Design architecture, split work in IDE
2. **Delegate routine** → Send well-specified components async
3. **Build complex locally** → Keep novel/risky work in IDE
4. **Integrate** → Review async results, merge, iterate

**Context preservation strategy:**
- Keep `.memory.md` updated with decisions made in each context
- Use `.spec.md` as coordination artifact between local and async work
- Reference the same `.instructions.md` files in both contexts

## Progress Monitoring & Quality Gates

Regardless of strategy, maintain quality through:

1. **Spec validation** → Human approves spec before delegation
2. **Architecture review** → Approve technical plan before implementation
3. **Code review** → Same standards for agent-generated and human code
4. **Test verification** → Automated tests must pass

**Treat agent output as high-quality drafts requiring review**, not finished products.
