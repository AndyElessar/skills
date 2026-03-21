---
title: "Anti-Patterns Reference"
description: "Common skill design mistakes with concrete examples and remediation guidance"
---

These anti-patterns degrade skill quality and agent performance. Each entry includes the problem, a concrete example of what to avoid, why it fails, and how to fix it. Drawn from benchmark research and production experience.

## 1. The Reference Dump

Loading exhaustive documentation into context instead of distilling procedural knowledge. Benchmark evidence shows "comprehensive" skills that dump full API references perform worse than having no skill at all (-2.9 pp).

### Example (avoid)

```yaml
---
name: react-expert
description: "React development help."
---
```

```markdown
# React Reference

## createElement
React.createElement(type, props, ...children)
Creates and returns a new React element of the given type...

## Component
class Component<P, S>
Base class for React components when using ES6 classes...

[500+ lines of API reference pasted verbatim]
```

### Why it fails

The agent spends context window on reference material it does not need for most tasks. The sheer volume dilutes the actually important conventions and patterns.

### Fix

Distill the reference into actionable rules. Push the full reference into `references/` for on-demand loading.

```markdown
# React Conventions

## Core Rules

- Use functional components with hooks. Class components only for error boundaries.
- Memoize expensive computations with useMemo; memoize callbacks with useCallback.
- Never mutate state directly; always use the setter from useState or useReducer.

For the complete API surface, load 'references/react-api.md'.
```

## 2. The Vague Description

Descriptions that provide no routing signal. The agent cannot distinguish this skill from dozens of others.

### Example (avoid)

```yaml
---
name: api-helper
description: "Helps with APIs."
---
```

### Why it fails

"Helps with APIs" matches virtually any programming task. The agent either triggers this skill for everything (wasting tokens) or never triggers it (because other skills have better descriptions).

### Fix

Include specific technology names, task verbs, and user intent phrases:

```yaml
---
name: fastapi-expert
description: "FastAPI development best practices and conventions.
  Use when building, reviewing, or debugging FastAPI applications,
  REST APIs, or Pydantic models. Also trigger when the user mentions
  route definitions, dependency injection, or async endpoints in Python.
  Do NOT use for Django or Flask projects."
---
```

## 3. The Missing Gate

Multi-step skills without explicit "DO NOT proceed until..." instructions.

### Example (avoid)

```markdown
## Step 1: Parse the code
Analyze all public functions.

## Step 2: Generate documentation
Write docstrings for each function.

## Step 3: Quality check
Verify all functions are documented.
```

### Why it fails

The agent treats steps as suggestions and barrels through all three in one pass. Step 2 runs on assumptions instead of confirmed analysis. Step 3 rubber-stamps the output.

### Fix

Add explicit gates at each transition:

```markdown
## Step 1: Parse the code
Analyze all public functions. Present the inventory to the user.
Ask: "Is this the complete public API you want documented?"
Do NOT proceed to Step 2 until the user confirms.

## Step 2: Generate documentation
Write docstrings for each function following the style guide.
Present each docstring for user approval.
Do NOT proceed to Step 3 until the user confirms.

## Step 3: Quality check
Verify all functions are documented. Report any gaps.
```

## 4. The Heavy-Handed Directive

Replacing reasoning with all-caps commands.

### Example (avoid)

```markdown
YOU MUST ALWAYS use TypeScript strict mode.
NEVER use `any` type.
YOU MUST NEVER disable ESLint rules.
ALWAYS write tests for every function.
```

### Why it fails

The agent follows the letter but not the spirit. When an edge case arises (a legacy file that genuinely needs `any` for a migration shim), the agent cannot exercise judgment because the instruction left no room for reasoning.

### Fix

Explain the reasoning so the agent can generalize:

```markdown
Enable TypeScript strict mode in all new projects. Strict mode catches
null reference errors and implicit any types at compile time, preventing
a class of runtime bugs that are expensive to debug in production.

Avoid the `any` type. Each `any` annotation disables type checking for
that value's entire call chain, undermining the safety guarantees that
TypeScript provides. Use `unknown` when the type is genuinely not known
and narrow it with type guards.
```

## 5. The Omnibus Skill

A single skill that tries to handle too many distinct responsibilities.

### Example (avoid)

```yaml
---
name: project-assistant
description: "Helps with code review, project planning, documentation
  generation, deployment configuration, and performance optimization."
---
```

### Why it fails

The description is too broad to serve as a reliable routing signal. The skill activates for everything but excels at nothing. The instructions inevitably become a sprawling document that exceeds the context budget.

### Fix

Split into focused skills that compose naturally:

- `code-reviewer`: evaluates code against a checklist
- `project-planner`: gathers requirements and produces a plan
- `doc-generator`: produces documentation from templates
- `deploy-config`: generates deployment configurations

Orchestrate them with a Pipeline skill if a workflow requires multiple steps.

## 6. The Overfit Skill

Instructions that only work for the specific examples used during development.

### Example (avoid)

A commit message skill that includes narrow patches for test failures:

```markdown
## Rules

- Start with a verb in imperative mood
- If the file is in src/auth/, prefix with "auth:"
- If the file is in src/payments/, prefix with "payments:"
- If the change touches both auth and payments, use "auth+payments:"
- If the file is test_login.py, always mention "login flow"
```

### Why it fails

Each rule is a patch for a specific test case. The skill works for the three files tested but produces bizarre results on any other file. Adding more patches creates compounding complexity.

### Fix

Write general rules that cover the class of tasks:

```markdown
## Rules

- Start with a conventional commit type (feat, fix, refactor, test, docs, chore)
- Add a scope in parentheses matching the top-level module directory
- Keep the subject line under 72 characters
- Focus on what changed and why, not which file was edited
```

## 7. Ignoring Progressive Disclosure

Putting everything in SKILL.md instead of leveraging `references/`, `assets/`, and `scripts/`.

### Example (avoid)

A 1200-line SKILL.md that inlines the complete style guide, all code examples, every checklist item, and the output template.

### Why it fails

Every activation loads all 1200 lines into context, even when the agent only needs a subset. The agent's attention is diluted across irrelevant sections, reducing instruction-following accuracy.

### Fix

Keep SKILL.md under 500 lines. Push detailed content to resource files:

```markdown
## When Reviewing Code

1. Load 'references/style-guide.md' for the complete rule set
2. Apply each rule to the user's code
3. Classify findings by severity

## When Generating Reports

1. Load 'references/report-conventions.md' for formatting rules
2. Load 'assets/report-template.md' for the output structure
3. Fill the template following the conventions
```

## 8. The Template-Free Generator

A Generator-pattern skill that describes the output format in prose rather than providing a template file.

### Example (avoid)

```markdown
Generate a report with an executive summary at the top,
then findings organized by category, then recommendations
at the bottom. Each finding should have a title, description,
severity, and suggested fix. The executive summary should be
concise but comprehensive.
```

### Why it fails

"Concise but comprehensive" is subjective. Without a concrete template, every invocation produces a slightly different structure. Section ordering drifts. Required fields get omitted.

### Fix

Provide an actual template in `assets/`:

```markdown
<!-- assets/report-template.md -->
# {Report Title}

## Executive Summary
{2-3 sentences summarizing key findings and top recommendation}

## Findings

### {Finding Title}
- **Severity**: {Critical | High | Medium | Low}
- **Description**: {What was found}
- **Impact**: {Why it matters}
- **Recommendation**: {Specific action to take}

## Recommendations
1. {Highest-priority recommendation with rationale}
2. {Second-priority recommendation with rationale}
3. {Third-priority recommendation with rationale}
```

## 9. The Uncheckable Checklist

Review checklists with vague, subjective items.

### Example (avoid)

```markdown
## Code Review Checklist
- [ ] Code follows best practices
- [ ] Functions are not too long
- [ ] Error handling is adequate
- [ ] Performance is acceptable
- [ ] Code is well-documented
```

### Why it fails

"Best practices" and "not too long" are not checkable. The agent produces vague reviews that mirror the vague checklist: "The code generally follows best practices."

### Fix

Make every item specific, measurable, and classified:

```markdown
## Code Review Checklist

### Correctness (severity: error)
- [ ] No mutable default arguments in function signatures
- [ ] All database connections are closed in finally blocks
- [ ] Division operations check for zero divisors

### Style (severity: warning)
- [ ] Functions are under 30 lines
- [ ] No single-letter variable names outside loop indices
- [ ] Import statements are grouped: stdlib, third-party, local

### Documentation (severity: info)
- [ ] All public functions have docstrings with parameter types
- [ ] Module-level docstring describes the module's purpose
```

## 10. No Evaluation

Shipping a skill without testing whether it actually improves agent output.

### Why it fails

A skill that looks good on paper may not change agent behavior, or may actively degrade performance on certain tasks. Without measurement, there is no signal.

### Fix

Create 2-3 test cases that exercise the skill's core scenarios:

1. Run each test case without the skill. Record the output quality.
2. Run each test case with the skill. Record the output quality.
3. Compare. If the skill does not improve the output, it is not ready.

Also test negative cases: prompts where the skill should NOT activate. A skill that triggers on irrelevant requests wastes context tokens and may confuse the agent.

Benchmark research found that 16 of 84 tasks showed performance degradation when skills were added (negative-delta tasks). Evaluation catches these cases before shipping.
