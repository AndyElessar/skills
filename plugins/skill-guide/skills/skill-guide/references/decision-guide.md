---
title: "Decision Guide"
description: "Pattern selection guide with decision tree and comparison table"
---

Use this guide when you are unsure which skill design pattern fits your use case. Walk through the decision tree first, then consult the comparison table for confirmation.

## Decision Tree

Ask these questions in order. The first "yes" answer points to your primary pattern.

1. **Does the agent need expert knowledge about a specific library, SDK, or tool?**
   Yes: **Tool Wrapper**. Package conventions and best practices into `references/` files. The agent loads them on demand and applies the rules.

2. **Must the output follow a fixed template every time?**
   Yes: **Generator**. Place the template in `assets/` and quality rules in `references/`. The instructions orchestrate: load rules, load template, gather inputs, fill.

3. **Must the agent evaluate something against a checklist or standard?**
   Yes: **Reviewer**. Store the checklist in `references/`. The instructions define the review protocol. Output is a scored findings report.

4. **Must the agent gather context from the user before it can do useful work?**
   Yes: **Inversion**. Structure the instructions as phased questions with gates. The agent interviews the user, then synthesizes output (optionally from a template in `assets/`).

5. **Does the workflow have ordered steps where each must complete before the next, with validation gates between them?**
   Yes: **Pipeline**. Define sequential steps with explicit gate conditions. Uses all three optional directories as needed.

If none clearly fits, start with Tool Wrapper. It is the simplest pattern and the most widely adopted starting point.

## Comparison Table

| Pattern | Core Question It Answers | Primary Directories | Complexity |
| --- | --- | --- | --- |
| Tool Wrapper | "How should the agent use this technology?" | `references/` | Low |
| Generator | "What structure should the output follow?" | `assets/` + `references/` | Medium |
| Reviewer | "Does this artifact meet the standard?" | `references/` | Medium |
| Inversion | "What does the agent need to know first?" | `assets/` | Medium (multi-turn) |
| Pipeline | "What steps must happen in order?" | `references/` + `assets/` + `scripts/` | High |

## Pattern Selection by Use Case

### Tool Wrapper Use Cases

- Encoding library conventions (framework best practices, coding standards)
- Team coding standards that apply automatically when working with a technology
- Security policies, database query patterns, infrastructure guidelines
- Wrapping an internal tool's API with usage conventions

### Generator Use Cases

- Technical reports with consistent sections
- API documentation with uniform structure per endpoint
- Commit messages following a standard format
- Project scaffolding from templates
- Configuration file generation

### Reviewer Use Cases

- Code review against team style rules
- Security audit using threat checklists
- Editorial review against a house style guide
- Architecture review against design principles
- Compliance checking against regulatory standards

### Inversion Use Cases

- Requirements gathering before design
- Diagnostic interviews before troubleshooting
- Configuration wizards before generating infrastructure
- User onboarding questionnaires
- Design interviews before scaffolding artifacts

### Pipeline Use Cases

- Documentation generation (parse, generate, assemble, validate)
- Data processing (validate, transform, enrich, output)
- Deployment workflows (test, build, stage, verify, promote)
- Onboarding workflows composing multiple patterns in sequence

## Composing Patterns

Most production skills combine 2-3 patterns. Common compositions:

| Composition | How It Works |
| --- | --- |
| Inversion + Generator | Gather requirements through questions, then produce templated output |
| Tool Wrapper + Reviewer | Encode conventions as knowledge, then evaluate code against them |
| Pipeline + Reviewer | One pipeline step loads a checklist and performs a quality review |
| Pipeline + Generator | One pipeline step fills a template to produce documentation |
| Inversion + Pipeline | Interview the user first, then execute a multi-step workflow with gates |

Start with the primary pattern. Layer in secondary patterns only when the use case genuinely requires them. If a skill needs more than three patterns, split it into separate skills orchestrated by a Pipeline.

## Progression Path

If you are new to skill design, follow this order:

1. Start with **Tool Wrapper**: wrap your team's coding conventions or a favored library's best practices. It requires only SKILL.md plus `references/`.
2. Graduate to **Generator** or **Reviewer**: when you need structured output or evaluation against a standard.
3. Use **Inversion**: when you find agents acting on assumptions instead of asking.
4. Build **Pipeline** skills: when workflows require ordered steps with human validation between them.
5. **Compose patterns**: once you are comfortable with individual patterns, combine them for complex workflows.
