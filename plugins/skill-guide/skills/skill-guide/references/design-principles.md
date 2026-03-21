---
title: "Design Principles"
description: "Core principles for writing effective, maintainable agent skills"
---

These principles apply to every skill regardless of which pattern it follows. They address content architecture, context efficiency, activation reliability, and maintainability.

## 1. Separate Content from Structure

The SKILL.md format defines the container (frontmatter, instructions, resource directories). The design pattern determines how you fill that container. Recognize which pattern fits your use case, then follow its content structure.

A skill that wraps library conventions looks nothing like a skill that runs a 4-step documentation pipeline, yet both use the same SKILL.md format. The format is the packaging; the pattern is the architecture.

## 2. Design for Progressive Disclosure

Structure content so context tokens are spent only when needed:

- L1 (Discovery): Name and description load for every registered skill on every request (~100 tokens each). Keep descriptions precise.
- L2 (Instructions): The full SKILL.md body loads only when the skill activates. Keep it concise enough to fit the task.
- L3 (Resources): Individual files from `references/`, `assets/`, `scripts/` load only when explicitly requested by the instructions.

Push detailed rules, templates, checklists, and style guides into resource files. The instructions should orchestrate: "Load reference X, then apply it."

## 3. Write Descriptions for Activation

The `description` field is the agent's search index for deciding when to activate a skill. A poorly written description means the skill never triggers when it should.

Effective descriptions:

- Include the specific keywords users type ("FastAPI", "REST APIs", "Pydantic models")
- Use "Use when..." phrases that match real user intents
- Add negative boundaries with "Do NOT use this skill for..."
- Cover synonyms and alternate phrasings users might employ

Ineffective descriptions:

- "Helps with APIs" (too generic, matches everything)
- "Useful for development" (no distinguishing information)
- Single-word descriptions (provide no routing signal)

## 4. Use Explicit Gates

Any step that requires validation, user confirmation, or preconditions needs a "DO NOT proceed until..." instruction. Without explicit gates:

- Agents barrel through multi-step workflows without pausing
- Agents jump to conclusions after minimal context gathering
- Agents skip validation and present unverified output

Place the strongest gate at the top of the skill. For example: "DO NOT start building or designing until all phases are complete." Then reinforce at each transition: "Do NOT proceed to Step 3 until the user confirms."

## 5. Design for Swappability

Separate what changes from what stays the same:

- Review protocol (instructions) stays constant; the checklist (reference file) varies by domain
- Generation workflow (instructions) stays constant; the template (asset file) varies by output type
- Convention enforcement (instructions) stays constant; the rules (reference file) vary by technology

This separation means you can swap `references/python-checklist.md` for `references/typescript-checklist.md` and get a completely different review without rewriting the review protocol.

## 6. One Concern per Skill

Each skill should address a single, well-defined concern. A skill that tries to be both a code reviewer and a project planner splits user intent and weakens the description's routing signal.

Prefer composing multiple focused skills over building one omnibus skill:

- `code-reviewer` evaluates code against a checklist
- `project-planner` gathers requirements and produces a plan
- `onboarding-pipeline` composes both into a multi-step workflow

## 7. Match Instruction Style to Pattern

Each pattern has a natural instruction style. Using the wrong style confuses the agent:

| Pattern | Instruction Style |
| --- | --- |
| Tool Wrapper | Declarative rules: "Always X" / "Never Y" / "When Z, do W" |
| Generator | Ordered steps: "Step 1: Load... Step 2: Load... Step 3: Fill..." |
| Reviewer | Review protocol: "Load checklist, apply each rule, classify severity" |
| Inversion | Phased questions: "Phase 1: ask Q1-Q3. Phase 2: ask Q4-Q6." |
| Pipeline | Gated steps: "Step 1: ... Do NOT proceed until confirmed." |

## 8. Explain the Why, Not Just the What

Today's language models are capable reasoners. When given context for a rule, they follow it more reliably and can generalize it to edge cases the rule did not explicitly cover.

Less effective:

```markdown
ALWAYS use type annotations on function signatures.
```

More effective:

```markdown
Add type annotations to all function signatures. Type annotations
serve as the primary documentation for both humans and language models
parsing the code, and they enable static analysis to catch errors
before runtime.
```

## 9. Design for Composability

Skills that work in isolation may fail when embedded in a Pipeline or invoked by another skill. Design every skill so it can function both standalone and as a composable step:

- Define the skill's input expectation (what context or data the skill needs from the caller) and output commitment (what the skill produces when done).
- Avoid depending on conversational history to activate. If the skill may be called as a sub-step, the L2 instructions should be self-contained.
- State the termination condition explicitly so a caller knows when to resume.
- If the skill can serve both standalone and composed use cases, include guidance at the top: "If called as part of a larger workflow, return output to the orchestrator rather than presenting directly to the user."

## 10. Design for Generalization

Skills get used across many different prompts, not just the author's test cases. Avoid overfitting to specific examples:

- Write instructions that apply to the general class of tasks, not one specific input
- Think about what a broad range of users would ask, not just the author's workflow
- Prefer flexible patterns over narrow, rigid rules
- Test with diverse prompts to ensure the skill generalizes

Benchmark evidence shows that "focused" skills (covering 2-3 modules with clear guidance) outperform "comprehensive" skills (exhaustive documentation dumps). The goal is distilled procedural knowledge that transfers across contexts, not exhaustive reference material that overwhelms.

## 11. Make Checklists Specific and Checkable

Vague checklist items produce vague reviews. Each item should be:

- Specific: "No mutable default arguments" rather than "Follow best practices"
- Checkable: "Functions under 30 lines" rather than "Keep functions short"
- Classified: Assign a severity level (error, warning, info) to each item
- Actionable: "Replace bare `except:` with specific exceptions" rather than "Handle errors properly"

Organize items by category (Correctness, Style, Documentation, Security, Performance) so the agent can report findings in a structured way.

## 12. Anchor Output with Templates

When the output must be consistent, provide a template in `assets/`. Templates:

- Define the exact sections every output must have
- Prevent the agent from inventing its own structure
- Ensure different runs of the same skill produce comparable results
- Make quality measurable: does the output contain all required sections?

The template is the contract. The style guide (in `references/`) controls how each section is written. Together they produce consistent, quality-controlled output.

## 13. Test Skills with Evaluation

Create test cases that exercise the skill's behavior. Run each case with and without the skill and measure the difference (the pass rate delta). This tells you exactly what the skill buys versus what it costs in context tokens.

Effective test cases:

- Include inputs that should trigger the skill's activation
- Verify the agent loads the correct reference files
- Check that output follows the expected structure
- Confirm gates and phases execute in the correct order
- Test edge cases where the skill should not activate

## 14. Store Skills at the Right Level

Choose the storage location based on the skill's audience:

- Project-level (inside the repository): team-shared skills that live with the codebase. Version-controlled, reviewed alongside code.
- User-level (personal configuration): personal skills that apply across all projects. Carry your preferences everywhere.
- Plugin-distributed: skills packaged in plugins for installation across teams or communities.

## 15. Compose Patterns Deliberately

Production skills typically combine 2-3 patterns. Common compositions:

- Inversion + Generator: gather requirements, then produce templated output
- Tool Wrapper + Reviewer: encode conventions, then evaluate code against them
- Pipeline with embedded Reviewer: run a multi-step workflow where one step is a quality review
- Pipeline with embedded Generator: one step produces templated output

Start with the primary pattern, then layer in secondary patterns as needed. Avoid combining more than three patterns in a single skill; split into separate skills orchestrated by a Pipeline instead.
