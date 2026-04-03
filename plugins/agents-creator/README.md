# Agents Creator Plugin

Create, review, rewrite, and debug repository-specific `agents.md`, `.github/agents/*.md`, and `*.agent.md` files for GitHub Copilot custom agents.

## What It Does

This plugin provides a skill that turns vague requests into agent instructions with concrete commands, realistic examples, and explicit boundaries. It covers:

- Creating new agent files from scratch with proper frontmatter and six core sections
- Reviewing existing agent files for specificity, executability, and safety
- Rewriting unclear instructions into testable, enforceable rules
- Converting generic agent prompts into repository-aware operating manuals

## Reference

The skill's guidance is based on analysis of 2,500+ public `agents.md` files:

> **[How to write a great agents.md: Lessons from over 2,500 repositories](https://github.blog/ai-and-ml/github-copilot/how-to-write-a-great-agents-md-lessons-from-over-2500-repositories/)** — Matt Nigh, GitHub Blog (Nov 2025)

Key takeaways from the article that this skill encodes:

- **Put commands early** — executable commands with flags, not just tool names
- **Code examples over explanations** — one real snippet beats three paragraphs
- **Set clear boundaries** — three-tier model: ✅ Always / ⚠️ Ask first / 🚫 Never
- **Be specific about your stack** — versions and key dependencies, not generic labels
- **Cover six core areas** — Commands, Testing, Project Structure, Code Style, Git Workflow, Boundaries
- **Start minimal, iterate** — the best agent files grow through use, not upfront planning

## Installation

### VS Code / Copilot CLI

```bash
copilot plugin install agents-creator@andyelessar-skills
```

### Claude Code

```bash
/plugin install agents-creator@andyelessar-skills
```

## License

[MIT](./LICENSE)
