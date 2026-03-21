---
title: "Design Patterns Reference"
description: "Detailed examples and templates for all five skill design patterns"
---

This reference provides detailed examples for each of the five skill design patterns. Each section includes a complete SKILL.md template, the directory layout, and guidance on structuring the content.

## Pattern 1: Tool Wrapper

A Tool Wrapper packages a library or tool's conventions into on-demand knowledge. The agent becomes a domain expert when the skill loads. Think framework conventions, infrastructure patterns, security policies, or database query best practices.

No templates, no scripts. Instructions tell the agent what rules to follow. `references/` holds the detailed convention docs.

### Directory Layout

```text
api-expert/
├── SKILL.md
└── references/
    └── conventions.md
```

### Example SKILL.md

```yaml
---
name: api-expert
description: "FastAPI development best practices and conventions.
  Use when building, reviewing, or debugging FastAPI applications,
  REST APIs, or Pydantic models."
---
```

```markdown
You are an expert in FastAPI development. Apply these conventions
to the user's code or question.

## Core Conventions

Load 'references/conventions.md' for the complete list of
FastAPI best practices.

## When Reviewing Code

1. Load the conventions reference
2. Check the user's code against each convention
3. For each violation, cite the specific rule and suggest the fix

## When Writing Code

1. Load the conventions reference
2. Follow every convention exactly
3. Add type annotations to all function signatures
4. Use Annotated style for dependency injection
```

### When to Use Tool Wrapper

- Your agent needs expert-level conventions for a specific library, SDK, or internal system
- Your team's coding conventions should apply automatically when working with a particular technology
- You want to encode best practices so every agent follows the same standards

### Real-World Examples

- React and Next.js performance rules organized by impact level (CRITICAL to LOW), loaded on demand
- Postgres optimization guidelines across query performance, connection management, RLS, and security
- Internal team conventions for naming, model selection, error handling

### Key Design Points

- The `description` field must include specific technology keywords ("FastAPI", "REST APIs", "Pydantic models") rather than vague phrases like "helps with APIs"
- Keep SKILL.md concise. Push full rule sets into `references/` files
- Organize references by category (naming, error handling, performance, security) for selective loading

## Pattern 2: Generator

A Generator produces documents, reports, or configurations by filling a reusable template. It uses both optional directories: `assets/` holds the output template (the structure to fill), and `references/` holds the style guide (the quality rules to follow).

### Directory Layout

```text
report-generator/
├── SKILL.md
├── references/
│   └── style-guide.md
└── assets/
    └── report-template.md
```

### Example SKILL.md

```yaml
---
name: report-generator
description: "Generates structured technical reports in Markdown.
  Use when the user asks to write, create, or draft a report,
  summary, or analysis document."
---
```

```markdown
You are a technical report generator. Follow these steps exactly:

Step 1: Load 'references/style-guide.md' for tone and formatting rules.

Step 2: Load 'assets/report-template.md' for the required output structure.

Step 3: Ask the user for any missing information needed to fill
the template:
- Topic or subject
- Key findings or data points
- Target audience (technical, executive, general)

Step 4: Fill the template following the style guide rules. Every
section in the template must be present in the output.

Step 5: Return the completed report as a single Markdown document.
```

### When to Use Generator

- The output needs to follow a fixed structure every time. Consistency matters more than creativity.
- Technical reports: Executive Summary, Methodology, Findings, Recommendations, always in the same order
- API documentation: every endpoint documented with the same sections
- Commit messages: enforce a standard format from a template
- Project scaffolding: generate a standard directory structure from a template, pre-wired with team conventions

### Key Design Points

- The template enforces structure; the style guide enforces quality. Swap either file to change the output without touching instructions.
- Step-based instructions orchestrate the process: load rules first, load template second, gather inputs third, fill fourth.
- The style guide controls tone, formatting conventions, and quality thresholds (for example, "Executive Summary under 150 words").

## Pattern 3: Reviewer

A Reviewer evaluates code, content, or artifacts against a checklist stored in `references/`, producing a scored findings report grouped by severity.

### Directory Layout

```text
code-reviewer/
├── SKILL.md
└── references/
    └── review-checklist.md
```

### Example SKILL.md

```yaml
---
name: code-reviewer
description: "Reviews Python code for quality, style, and common bugs.
  Use when the user submits code for review, asks for feedback on
  their code, or wants a code audit."
---
```

```markdown
You are a Python code reviewer. Follow this review protocol exactly:

Step 1: Load 'references/review-checklist.md' for the complete
review criteria.

Step 2: Read the user's code carefully. Understand its purpose
before critiquing.

Step 3: Apply each rule from the checklist to the code. For every
violation found:
- Note the line number (or approximate location)
- Classify severity: error (must fix), warning (should fix),
  info (consider)
- Explain WHY it's a problem, not just WHAT is wrong
- Suggest a specific fix with corrected code

Step 4: Produce a structured review with these sections:
- Summary: What the code does, overall quality assessment
- Findings: Grouped by severity (errors first, then warnings,
  then info)
- Score: Rate 1-10 with brief justification
- Top 3 Recommendations: The most impactful improvements
```

### When to Use Reviewer

- Anywhere a human reviewer works from a checklist, a Reviewer skill can encode it
- Code review: catch mutable defaults, missing type hints, bare exception blocks against team style rules
- Security audit: run OWASP Top 10 checks against submitted code, classifying findings by severity
- Editorial review: check blog posts or docs against a house style guide
- Convention review: validate new artifacts against team standards

### Key Design Points

- Separate WHAT to check (the checklist file) from HOW to check (the review protocol in the instructions)
- Swap `references/review-checklist.md` for `references/security-checklist.md` and you get a completely different review from the same skill structure
- Organize checklists by category with severity levels: Correctness (error), Style (warning), Documentation (info), Security (error), Performance (info)
- Each category contains specific, checkable items like "No mutable default arguments" or "Functions under 30 lines"

## Pattern 4: Inversion

Inversion flips the typical agent interaction: instead of the user driving, the skill instructs the agent to ask structured questions through defined phases before producing any output. No special framework support required. Inversion is purely an instruction-authoring pattern.

### Directory Layout

```text
project-planner/
├── SKILL.md
└── assets/
    └── plan-template.md
```

### Example SKILL.md

```yaml
---
name: project-planner
description: "Plans a new software project by gathering requirements
  through structured questions before producing a plan. Use when
  the user says 'I want to build', 'help me plan', 'design a
  system', or 'start a new project'."
---
```

```markdown
You are conducting a structured requirements interview. DO NOT
start building or designing until all phases are complete.

## Phase 1: Problem Discovery
Ask one question at a time, wait for each answer.

- Q1: "What problem does this project solve for its users?"
- Q2: "Who are the primary users? What is their technical level?"
- Q3: "What is the expected scale? (users per day, data volume,
  request rate)"

## Phase 2: Technical Constraints
Only after Phase 1 is fully answered.

- Q4: "What deployment environment will you use?"
- Q5: "Do you have any technology stack requirements or
  preferences?"
- Q6: "What are the non-negotiable requirements? (latency, uptime,
  compliance, budget)"

## Phase 3: Synthesis
Only after all questions are answered.

1. Load 'assets/plan-template.md' for the output format
2. Fill in every section of the template using the gathered
   requirements
3. Present the completed plan to the user
4. Ask: "Does this plan accurately capture your requirements?
   What would you change?"
5. Iterate on feedback until the user confirms
```

### When to Use Inversion

- The agent needs context from the user before it can do useful work
- Requirements gathering: interview a user about a project before producing a technical design
- Diagnostic interviews: walk through a structured troubleshooting checklist
- Configuration wizards: gather deployment preferences before generating infrastructure config
- Design interviews: before scaffolding artifacts, interview the user about constraints and preferences

### Key Design Points

- Phased structure is what makes Inversion work. Phase 1 must complete before Phase 2 starts. Phase 3 only triggers after all questions are answered.
- The `DO NOT start building or designing until all phases are complete` instruction is the critical gate. Without it, agents jump to conclusions after the first answer.
- The template in `assets/` anchors the synthesis step, producing consistent output regardless of how the conversation went.
- Prevents the most common agent failure mode: generating a detailed plan based on assumptions instead of asking.

## Pattern 5: Pipeline

A Pipeline defines a sequential workflow where each step must complete before the next begins, with explicit gate conditions that prevent the agent from skipping validation. This is the most complex pattern. It uses all three optional directories and adds control flow between steps.

### Directory Layout

```text
doc-pipeline/
├── SKILL.md
├── references/
│   ├── docstring-style.md
│   └── quality-checklist.md
└── assets/
    └── api-doc-template.md
```

### Example SKILL.md

```yaml
---
name: doc-pipeline
description: "Generates API documentation from Python source code
  through a multi-step pipeline. Use when the user asks to document
  a module, generate API docs, or create documentation from code."
---
```

```markdown
You are running a documentation generation pipeline. Execute each
step in order. Do NOT skip steps or proceed if a step fails.

## Step 1: Parse and Inventory
Analyze the user's Python code to extract all public classes,
functions, and constants. Present the inventory as a checklist.
Ask: "Is this the complete public API you want documented?"

## Step 2: Generate Docstrings
For each function lacking a docstring:
- Load 'references/docstring-style.md' for the required format
- Generate a docstring following the style guide exactly
- Present each generated docstring for user approval
Do NOT proceed to Step 3 until the user confirms.

## Step 3: Assemble Documentation
Load 'assets/api-doc-template.md' for the output structure.
Compile all classes, functions, and docstrings into a single
API reference document.

## Step 4: Quality Check
Review against 'references/quality-checklist.md':
- Every public symbol documented
- Every parameter has a type and description
- At least one usage example per function
Report results. Fix issues before presenting the final document.
```

### When to Use Pipeline

- Any multi-step process where steps have dependencies and order matters
- Documentation generation: parse code, generate docstrings (with user approval), assemble docs, quality check
- Data processing: validate input, transform, enrich, write output
- Deployment workflows: run tests, build artifact, deploy to staging, smoke test, promote
- Onboarding workflows: interview user (Inversion), scaffold files (Generator), validate against conventions (Reviewer)

### Key Design Points

- Gate conditions are the defining feature. "Do NOT proceed to Step 3 until the user confirms" prevents the agent from assembling documentation with unreviewed docstrings.
- "Do NOT skip steps or proceed if a step fails" at the top enforces the sequential constraint.
- Each step loads different resources. The agent only pays context tokens for the resources it needs at each step.
- Without gates, agents tend to barrel through all steps and present a final result that skipped validation.

### Handling Step Failures

Gates stop forward progress, but the skill also needs to tell the agent what to do when a step does not pass. Without failure guidance, the agent stalls at the gate indefinitely. For each gate, include a fallback path:

```markdown
Do NOT proceed to Step 3 until the user confirms.
If the user identifies issues, revise the Step 2 output and present again.
If revisions fail after two rounds, ask the user whether to continue
with known gaps or adjust the requirements.
```

Define what the agent should report on failure: which step failed, what was attempted, and what needs to change. This gives the user (or an orchestrating Pipeline) enough information to recover.
