---
name: skill-guide
description: "Design, write, and review SKILL.md files using proven patterns. Use when creating, improving, or reviewing agent skills, choosing a design pattern (Tool Wrapper, Generator, Reviewer, Inversion, Pipeline), structuring progressive disclosure, writing skill descriptions, or composing patterns. Also trigger for 'skill design', 'skill architecture', 'skill anti-patterns', 'skill checklist', or questions about writing better skills. Do NOT use for plugin.json or marketplace.json (use plugin-creator instead)."
---

# Skills Design Guide

A comprehensive guide for designing, writing, reviewing, and improving SKILL.md files. Grounded in both academic research on agentic skills and production experience from agent platforms. This skill adapts its behavior based on user intent — see [How This Skill Operates](#how-this-skill-operates) to determine the right protocol for the current task.

## Quick Navigation

| Intent | Section |
|---|---|
| "I need to create / review / improve a skill" | [How This Skill Operates](#how-this-skill-operates) |
| "What is a skill, exactly?" | [What Is an Agentic Skill?](#what-is-an-agentic-skill) |
| "What does a good skill look like?" | [Anatomy of a Good Skill](#anatomy-of-a-good-skill) |
| "Which pattern should I use?" | [The Five Patterns](#the-five-patterns) |
| "How do I write a great skill?" | [Writing Great Skills](#writing-great-skills) |
| "What should I avoid?" | [Anti-Patterns](#anti-patterns-what-not-to-do) |
| "Give me a checklist" | Load [references/quality-checklist.md](./references/quality-checklist.md) |
| Detailed pattern examples | Load [references/design-patterns.md](./references/design-patterns.md) |
| Core design principles | Load [references/design-principles.md](./references/design-principles.md) |
| Anti-patterns with examples | Load [references/anti-patterns.md](./references/anti-patterns.md) |
| Pattern selection decision guide | Load [references/decision-guide.md](./references/decision-guide.md) |

## How This Skill Operates

This skill covers a single, cohesive domain — skill design — but that domain spans multiple activities: creating, reviewing, improving, pattern selection, and concept education. Rather than splitting into separate skills with overlapping descriptions and routing conflicts, this skill routes internally by user intent, combining elements of Tool Wrapper (domain expertise in `references/`), Reviewer (checklist-based evaluation), Inversion (context gathering before generation), and Generator (artifact production).

Identify the user's primary intent, then follow the corresponding protocol.

### Create a New Skill

1. **Gather context** (Inversion): Ask the user what the skill should accomplish, what technology or domain it covers, and what output it should produce. DO NOT start writing the SKILL.md until you understand the intent, trigger conditions, and expected output.
2. **Choose a pattern**: Walk through the [Choosing a Pattern](#choosing-a-pattern) questions. For nuanced cases, load [references/decision-guide.md](./references/decision-guide.md).
3. **Draft the skill**: Apply the [Writing Great Skills](#writing-great-skills) guidance. Start with the description, then structure the body following the chosen pattern. Produce a SKILL.md with frontmatter and instructions, plus any needed reference/asset/script files.
4. **Validate**: Load [references/quality-checklist.md](./references/quality-checklist.md) and verify the draft passes all sections.
5. **Done**: The user confirms the SKILL.md and any supporting files are complete.

### Review an Existing Skill

1. **Load the checklist**: Load [references/quality-checklist.md](./references/quality-checklist.md).
2. **Read the skill**: Read the target SKILL.md and all its reference files.
3. **Apply every checklist item**: For each violation, classify severity (🔴 high / 🟡 medium / 🔵 low), cite the principle violated, explain why it matters, and suggest a fix.
4. **Cross-check anti-patterns**: Scan for the [ten anti-patterns](#anti-patterns-what-not-to-do). For detail on any, load [references/anti-patterns.md](./references/anti-patterns.md).
5. **Produce a findings report**: Group by severity, provide a summary score, list the top 3 improvements by impact.
6. **Done**: The findings report covers all checklist sections.

### Improve an Existing Skill

1. **Review first**: Follow the [Review](#review-an-existing-skill) protocol to identify issues.
2. **Prioritize**: Rank findings by impact. Address 🔴 high-severity items first.
3. **Propose edits**: For each change, explain the rationale (which principle it addresses) and provide the specific edit.
4. **Done**: The user confirms all desired improvements are applied.

### Choose a Pattern

1. Walk through the [Choosing a Pattern](#choosing-a-pattern) questions with the user.
2. For nuanced cases, load [references/decision-guide.md](./references/decision-guide.md) for the full decision tree and comparison.
3. Explain the recommendation with reasoning grounded in the user's specific use case.
4. **Done**: The user has a clear pattern choice with rationale.

### Understand Concepts

1. Identify which knowledge area the question concerns (patterns, principles, anti-patterns, progressive disclosure, etc.).
2. Answer from the relevant section below. For depth, load the corresponding L3 reference file.
3. **Done**: The question is answered with pointers to further depth.

### Composability

When this skill is called as part of a larger workflow, return the output (SKILL.md, findings report, or recommendation) to the orchestrator rather than presenting directly to the user.

## What Is an Agentic Skill?

A skill is a reusable, callable module that encapsulates procedural knowledge for an AI agent. Unlike a one-time plan or a single tool call, a skill persists across sessions, carries executable instructions, and exposes a clear activation boundary.

Research formalizes a skill as four components:

1. **Applicability condition**: When should this skill activate? The `description` field serves as this gate, telling the agent which user requests match.
2. **Executable policy**: What should the agent do? The SKILL.md body plus any referenced scripts, templates, and resource files form the policy.
3. **Termination condition**: When is the skill done? Implicit in the instructions (e.g., "Return the completed report") or explicit via gate conditions.
4. **Reusable interface**: How does the skill present itself? The frontmatter (name, description) acts as the callable interface for agent discovery.

### Skills versus Related Concepts

| Concept | Key Difference from Skills |
|---|---|
| Tool | A single atomic action (API call, file write). A skill may invoke tools but adds multi-step logic, applicability conditions, and termination criteria. |
| Plan | A one-time reasoning scaffold for a specific task. Skills persist and apply across many tasks. |
| Memory | Stored observations of what happened. Skills encode how to act, not what occurred. |
| Prompt template | Static text injected into context. Skills add applicability gating, structured execution, and resource loading. |

### Why Skills Matter

Benchmark evidence demonstrates that curated skills raise agent pass rates by +16.2 percentage points on average. Focused skills with 2-3 modules yield the highest improvement (+18.6 pp). A smaller model equipped with curated skills can outperform a larger model operating without them, making skills a practical compute equalizer.

However, quality matters more than quantity. Self-generated skills without human review degrade performance by -1.3 pp on average. "Comprehensive" skills that dump exhaustive documentation hurt performance (-2.9 pp), while "detailed" skills (moderate-length, focused guidance) help substantially (+18.8 pp). The lesson: distill procedural knowledge rather than dumping reference material.

## Anatomy of a Good Skill

### Directory Layout

Every skill shares the same directory structure. The design pattern you choose determines how you populate these directories.

```text
skill-name/
├── SKILL.md          # YAML frontmatter + markdown instructions (required)
├── references/       # Style guides, checklists, conventions (optional)
├── assets/           # Templates and output formats (optional)
└── scripts/          # Executable scripts (optional)
```

### Progressive Disclosure

Skills operate on three levels, minimizing context tokens until information is actually needed:

| Level | What Loads | Token Cost |
|---|---|---|
| L1: Discovery | Skill name + description from frontmatter | ~100 tokens per skill |
| L2: Instructions | Full SKILL.md body | On activation only |
| L3: Resources | Individual files from references/, assets/, scripts/ | On explicit demand |

The agent pays L1 cost for every registered skill at startup, then loads L2 and L3 only when the skill is relevant. This three-level architecture means SKILL.md should orchestrate ("Load reference X, then apply it") rather than contain everything inline.

### The Description Field

The `description` field is the single most important line in any skill. It serves as the agent's search index, determining whether the skill activates for a given user request. Modern agents tend to "under-trigger" rather than "over-trigger" skills, so lean toward being specific and slightly "pushy" in descriptions.

Effective descriptions:

- Include specific keywords matching how users phrase requests (library names, task verbs, artifact types)
- Use "Use when..." and "Also trigger when..." phrases that map to real user intents
- Add negative boundaries with "Do NOT use this skill for..." to prevent false activation
- Cover synonyms, alternate phrasings, and implicit scenarios where users need the skill without explicitly naming it

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

## The Five Patterns

Each pattern uses the same SKILL.md format but structures content differently.

| Pattern | Purpose | Directories | Complexity | Instruction Style |
|---|---|---|---|---|
| **Tool Wrapper** | Expert knowledge about a technology | `references/` | Low | Declarative rules: "Always X" / "Never Y" |
| **Generator** | Consistent output from a template | `assets/` + `references/` | Medium | Ordered steps: load rules → load template → fill |
| **Reviewer** | Evaluate against a checklist | `references/` | Medium | Review protocol: load checklist → apply → report |
| **Inversion** | Gather context before acting | `assets/` | Medium | Phased questions with gates between phases |
| **Pipeline** | Ordered workflow with validation | All three dirs | High | Gated steps: "Do NOT proceed until confirmed" |

For complete examples, directory layouts, and key design points per pattern, load [references/design-patterns.md](./references/design-patterns.md).

### Choosing a Pattern

1. Agent needs expert knowledge about a library or tool? **Tool Wrapper**
2. Output must follow a fixed template every time? **Generator**
3. Agent must evaluate something against a standard? **Reviewer**
4. Agent must gather context from the user before acting? **Inversion**
5. Workflow has ordered steps with validation gates? **Pipeline**

If none clearly fits, start with Tool Wrapper. For a detailed decision guide with use cases, load [references/decision-guide.md](./references/decision-guide.md).

### Composing Patterns

Production skills typically combine 2-3 patterns. Common compositions:

- Pipeline + Reviewer: one pipeline step loads a checklist and performs a quality review
- Inversion + Generator: gather requirements through questions, then produce templated output
- Tool Wrapper + Reviewer: encode conventions as knowledge, then evaluate code against them

If a skill needs more than three patterns, split it into separate skills orchestrated by a Pipeline.

## Writing Great Skills

### When Not to Write a Skill

Before investing in a skill, confirm it will actually help. Benchmark evidence shows that 16 of 84 tasks degraded when skills were added, with the worst case losing 39.3 percentage points. A skill is not worth writing when:

- The task is one-off and will not recur. A plan or prompt handles it better.
- The domain is already well-represented in the model's training data (basic language syntax, common math). Extra instructions risk conflicting with what the model already knows.
- The guidance is under ~20 lines with no reference files, templates, or scripts. Use an `.instructions.md` file instead.
- A quick comparison (run the task with and without the skill) shows no measurable improvement. If the skill does not change output quality, it is not ready.

### Step 1: Start with Intent

Before writing any instructions, answer four questions:

1. What should this skill enable the agent to do?
2. When should this skill trigger? (What user phrases, contexts, or file types?)
3. What is the expected output format?
4. Which pattern fits the task? (Use the decision process above.)

### Step 2: Write the Description First

The description is your skill's search index. Write it before the body. Include:

- The technology or domain keywords users type
- "Use when..." phrases mapping to real user intents
- "Also trigger when..." for implicit scenarios
- "Do NOT use this skill for..." to set boundaries

Agents under-trigger more often than over-trigger. Err on the side of being specific and slightly assertive about when the skill should activate.

When multiple skills coexist in the same environment, check existing skill descriptions before finalizing yours. If two descriptions overlap semantically, the agent cannot reliably choose between them. Narrow the overlap with more precise keywords (e.g., `FastAPI` instead of `Python APIs`) or explicit negative boundaries (`Do NOT use for Django`). Avoid relying on generic verbs like `create`, `review`, or `generate` as the sole trigger; pair them with specific nouns.

### Step 3: Structure Content with Progressive Disclosure

Keep SKILL.md under 500 lines. The instructions should orchestrate, not contain everything:

- Put the essential workflow, rules, and decision logic in SKILL.md (L2)
- Push detailed checklists, conventions, and style guides into `references/` (L3)
- Put output templates into `assets/` (L3)
- Put reusable scripts into `scripts/` (L3)
- For large reference files (>300 lines), include a table of contents at the top

If SKILL.md approaches 500 lines, add an extra layer of hierarchy with clear pointers to where the agent should look next.

When authoring L3 reference files, apply the same quality standards as the skill itself. Each file should focus on one topic (e.g., `naming.md`, `error-handling.md`) rather than bundling everything into a single `conventions.md`. For rule-based references, classify items by severity (error, warning, info) and make each item specific and checkable. For template files, use `{placeholder}` markers for fillable fields. A reference file that dumps raw documentation into `references/` simply moves the Reference Dump anti-pattern to L3.

### Step 4: Explain the Why, Not Just the What

Today's language models are capable reasoners. When given context for a rule, they follow it more reliably and can generalize it to edge cases the rule didn't explicitly cover. Instead of rigid directives, explain the reasoning:

Less effective:

```markdown
ALWAYS use type annotations on function signatures.
```

More effective:

```markdown
Add type annotations to all function signatures. Type annotations serve
as the primary documentation for both humans and language models parsing
the code, and they enable static analysis to catch errors before runtime.
```

If you find yourself writing ALWAYS or NEVER in all-caps repeatedly, reframe: explain why the thing matters so the model understands the reasoning and applies it appropriately.

### Step 5: Use Explicit Gates

Any step that requires validation, user confirmation, or preconditions needs a "DO NOT proceed until..." instruction. Without gates:

- Agents barrel through multi-step workflows without pausing
- Agents jump to conclusions after minimal context gathering
- Agents skip validation and present unverified output

Place the strongest gate at the top. Then reinforce at each critical transition point.

### Step 6: Define Clear Termination

Every skill needs an explicit done state so the agent (and any orchestrator calling it) knows when to stop. Without a clear termination condition, agents either loop indefinitely or stop too early.

Define termination per pattern:

- Tool Wrapper: implicit in the request (answer the question, fix the code)
- Generator: "Return the completed document with all template sections filled"
- Reviewer: "Produce the findings report with score and severity-grouped items"
- Inversion: two stages. Phase complete = all answers collected. Skill complete = user confirms the synthesized output.
- Pipeline: each step terminates at its gate. The skill terminates when the final step completes.

If the skill may be invoked as part of a larger workflow, state the termination condition at the end of the instructions so the caller knows when to resume.

### Step 7: Include Examples

Examples are one of the most powerful tools in skill instructions. They anchor the agent's behavior more effectively than abstract descriptions.

```markdown
## Commit Message Format

**Example 1:**
Input: Added user authentication with JWT tokens
Output: feat(auth): implement JWT-based authentication

**Example 2:**
Input: Fixed null pointer in user profile loading
Output: fix(profile): handle null user object during loading
```

### Step 8: Keep It Lean

Remove anything that is not pulling its weight. After drafting a skill, review each section with fresh eyes:

- Does this section change the agent's behavior? If not, remove it.
- Is the agent spending time on unproductive steps? Trim the instructions causing it.
- Can this detailed content live in a reference file instead? Move it to L3.
- Is there repeated work across invocations that could become a bundled script? Put it in `scripts/`.

Focused skills with 2-3 modules outperform comprehensive documentation. Brevity is a feature, not a limitation.

### Step 9: Design for Generalization

Skills get used across many different prompts, not just your test cases. Avoid overfitting to specific examples:

- Write instructions that apply to the general class of tasks, not one specific input
- Use theory of mind: think about what a broad range of users would ask
- Prefer flexible metaphors and patterns over narrow, rigid rules
- Test with diverse prompts to ensure the skill generalizes

## Anti-Patterns: What Not to Do

These are the ten most common mistakes that degrade skill quality. Watch for them when writing or reviewing any skill.

| # | Anti-Pattern | Core Problem |
|---|---|---|
| 1 | Reference Dump | Pasting exhaustive docs into context instead of distilling rules (-2.9 pp in benchmarks) |
| 2 | Vague Description | "Helps with APIs" gives the agent no routing signal |
| 3 | Missing Gate | No "DO NOT proceed until..." → agent barrels through steps |
| 4 | Heavy-Handed Directive | All-caps MUSTs without reasoning → brittle on edge cases |
| 5 | Omnibus Skill | One skill tries to do everything → weak activation, bloated context |
| 6 | Overfit Skill | Instructions only work for the author's specific test cases |
| 7 | Ignoring Progressive Disclosure | Everything in SKILL.md instead of references/, assets/, scripts/ |
| 8 | Template-Free Generator | Describes output format in prose instead of providing a template file |
| 9 | Uncheckable Checklist | Vague items like "follow best practices" produce vague reviews |
| 10 | No Evaluation | Shipping without testing against realistic prompts |

For concrete before/after examples and remediation guidance, load [references/anti-patterns.md](./references/anti-patterns.md).

## Skill Quality Checklist

When reviewing or validating a skill, load [references/quality-checklist.md](./references/quality-checklist.md) and apply every item. A well-crafted skill should pass all sections: Description Quality, Content Architecture, Instruction Quality, Pattern Alignment, Composability and Termination, and Evaluation.

## Core Design Principles

For the complete set of principles, load [references/design-principles.md](./references/design-principles.md). The most critical ones:

1. **Separate content from structure.** The SKILL.md format is the container; the pattern determines how you fill it.
2. **Push detail into resource files.** Keep SKILL.md concise; load references, templates, and checklists on demand.
3. **Write descriptions for activation.** The description is the agent's routing index. Make it specific, keyword-rich, and trigger-oriented.
4. **Use explicit gates.** Any step that requires validation needs a "DO NOT proceed until..." instruction.
5. **Design for swappability.** Separating rules from protocols means you can swap a checklist, template, or style guide without rewriting instructions.
6. **One concern per skill.** A skill that tries to do everything weakens its activation signal and confuses the agent.
7. **Explain the why.** Rules backed by reasoning are followed more reliably and generalize better than bare directives.
8. **Design for composability.** Define clear input expectations and output commitments so the skill works both standalone and as a step in a larger workflow.
