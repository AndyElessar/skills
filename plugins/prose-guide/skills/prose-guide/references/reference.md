# Reference: Checklists, Progression & Resources

## Quick Start Checklist

### Conceptual Foundation

- [ ] Understand Markdown Prompt Engineering (semantic structure + precision + tools)
- [ ] Grasp Context Engineering fundamentals (buffer optimization + session strategy)
- [ ] Learn Skills as Distribution (capabilities packaged for auto-discovery)

### Implementation Steps

- [ ] Install Skills for your stack: `apm install owner/skill-name`
- [ ] Create `.github/copilot-instructions.md` with project guidelines
- [ ] Set up domain `.instructions.md` files with `applyTo` patterns
- [ ] Configure custom agents for your tech stack domains
- [ ] Create first `.prompt.md` with validation checkpoints
- [ ] Build first `.spec.md` template for feature specifications
- [ ] Package reusable patterns as a Skill: `apm init skill`
- [ ] Practice spec-first: plan → implement → test
- [ ] Test async delegation with GitHub Coding Agent
- [ ] Establish team governance and validation gates

## Mastery Progression

| Level | Goal | Key Outcomes |
|-------|------|-------------|
| Foundation | Build first primitives | Basic `.instructions.md`, first agent mode, first `.prompt.md` |
| Beginner | Consistent AI interactions | Domain instructions, 3-5 prompt templates, multiple modes |
| Intermediate | Spec-driven workflows | Spec-first planning, context optimization, session splitting |
| Advanced | Async agent orchestration | GitHub Coding Agent, parallel workflows, quality gates |
| Expert | Team-wide governance | Coordination frameworks, knowledge sharing, compliance integration |

## The Paradigm Shift

*Traditional:* "Tell the AI what to do"
*PROSE:* "Engineer the context and structure for optimal cognitive performance"

**Core principles:**

1. **Determinism through Structure** — Predictable outcomes via systematic approaches
2. **Context as Performance** — Strategic memory management for AI cognitive performance
3. **Compound Intelligence** — Systems that improve through iteration
4. **Human-AI Partnership** — Validation gates and collaborative workflows
5. **Team-Scale Coordination** — Knowledge sharing and organizational transformation

**Key insights:**

- The more determinism you need → more structured prompts + smaller scope
- The more complex the project → more critical context engineering becomes

## Documentation Links

### Agent Skills & Distribution

- [Agent Skills Standard](https://agentskills.io) — Capability packaging and auto-discovery spec
- [APM — Agent Package Manager](https://github.com/danielmeppiel/apm) — npm for Skills: install, compose, compile
- [AGENTS.md Standard](https://agents.md) — Universal context format for all coding agents

### Community Resources

- [Awesome GitHub Copilot](https://github.com/github/awesome-copilot) — Community instructions, prompts, and chat modes

### VS Code Copilot Customization

- [Main Customization Guide](https://code.visualstudio.com/docs/copilot/copilot-customization)
- [Custom Instructions](https://code.visualstudio.com/docs/copilot/copilot-customization#_use-a-githubcopilot-instructionsmd-file) — `.github/copilot-instructions.md`
- [Modular Instructions](https://code.visualstudio.com/docs/copilot/copilot-customization#_use-instructionsmd-files) — `.instructions.md` with `applyTo`
- [Prompt Files](https://code.visualstudio.com/docs/copilot/copilot-customization#_prompt-files-experimental) — `.prompt.md`
- [Custom Chat Modes](https://code.visualstudio.com/docs/copilot/copilot-customization#_custom-chat-modes)

### GitHub Copilot

- [GitHub Copilot Overview](https://docs.github.com/en/copilot)
- [GitHub Coding Agent](https://docs.github.com/en/copilot/about-github-copilot/about-copilot-coding-agent)
- [Enabling Coding Agent](https://docs.github.com/en/copilot/how-tos/agents/coding-agent/enabling-copilot-coding-agent)
- [MCP Integration](https://docs.github.com/en/copilot/how-tos/agents/coding-agent/extending-copilot-coding-agent-with-the-model-context-protocol-mcp)
- [Copilot Chat Best Practices](https://docs.github.com/en/copilot/copilot-chat/copilot-chat-cookbook)

## Quick Troubleshooting

| Issue | Solution |
|-------|---------|
| Inconsistent AI responses | Use structured Markdown prompts with headers and validation gates |
| Context window limitations | Session splitting + modular instructions with `applyTo` |
| Team coordination conflicts | Shared primitive libraries + repository coordination |
| Quality concerns with async agents | Validation gates — treat agent output as drafts requiring review |
| Compliance & security concerns | Risk-based agent boundaries + policy requirements in instructions |

## Success Metrics

### Individual

- **Productivity:** Time saved per feature
- **Quality:** Reduction in bugs and rework
- **Consistency:** Standardized AI interaction patterns

### Team

- **Coordination:** Fewer merge conflicts and sync meetings
- **Knowledge Sharing:** Primitive reuse rate across members
- **Onboarding:** Time to first productive contribution

### Organization

- **Adoption:** Teams using AI-native development
- **Compliance:** Governance framework adherence
- **ROI:** Overall productivity and quality improvement
