---
title: "Skill Quality Checklist"
description: "Validation checklist for evaluating skill quality before shipping"
---

Use this checklist to validate any skill before shipping. A well-crafted skill should pass all items.

## Description Quality

- [ ] Includes specific keywords matching user vocabulary (library names, task verbs)
- [ ] Contains "Use when..." phrases mapping to real user intents
- [ ] Includes "Also trigger when..." phrases for implicit scenarios
- [ ] Sets negative boundaries with "Do NOT use this skill for..."
- [ ] Does not use vague phrases ("helps with", "useful for")
- [ ] Is slightly "pushy" to counter agent under-triggering
- [ ] Does not semantically overlap with other skills in the same environment

## Content Architecture

- [ ] SKILL.md is under 500 lines
- [ ] Detailed rules, checklists, and style guides live in `references/`
- [ ] Output templates live in `assets/`
- [ ] Reusable scripts live in `scripts/`
- [ ] Large reference files (>300 lines) include a table of contents
- [ ] SKILL.md orchestrates resource loading rather than inlining everything
- [ ] Each reference file covers one topic and classifies items by severity where applicable

## Instruction Quality

- [ ] Instructions explain the reasoning behind rules, not just directives
- [ ] Uses the imperative form for clarity
- [ ] Includes concrete examples where helpful
- [ ] Instructions are general enough to work across diverse prompts
- [ ] Multi-step workflows have explicit gate conditions
- [ ] Instruction style matches the chosen pattern (declarative for Tool Wrapper, ordered steps for Generator, etc.)

## Pattern Alignment

- [ ] Skill follows a recognized pattern (Tool Wrapper, Generator, Reviewer, Inversion, or Pipeline)
- [ ] Directory structure matches the pattern's expected layout
- [ ] Skill addresses a single, well-defined concern (one cohesive domain, even if that domain spans multiple activities)
- [ ] If composing patterns, the combination is limited to 2-3 maximum
- [ ] If the skill serves multiple intents within one domain, it routes by intent with distinct protocols rather than mixing instruction styles

## Composability and Termination

- [ ] Input expectation is defined (what context or data the skill needs from the caller)
- [ ] Output commitment is defined (what the skill produces when done)
- [ ] Termination condition is explicit so callers know when to resume
- [ ] Skill can function both standalone and as a step in a larger workflow

## Evaluation

- [ ] Tested against 2-3 realistic user prompts with defined pass criteria
- [ ] Outputs improve compared to the agent operating without the skill
- [ ] Includes at least one negative test case (prompt where the skill should NOT activate)
- [ ] Edge cases where the skill should NOT activate have been considered
- [ ] Checklist items (if Reviewer pattern) are specific, checkable, and classified by severity
- [ ] Test cases follow the structure: input prompt, expected behavior, pass/fail criteria
