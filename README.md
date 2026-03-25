# skills

Plugin marketplace for **GitHub Copilot CLI** and **Claude Code**, including dotnet, meta-prompts, etc.

[![Add Marketplace in VS Code](https://img.shields.io/badge/VS_Code-Add_Marketplace-0098FF?logo=visualstudiocode&logoColor=white)](https://vscode.dev/redirect?url=vscode://chat-plugin/add-marketplace?ref=AndyElessar/skills) [![Add Marketplace in Insiders](https://img.shields.io/badge/Insiders-Add_Marketplace-24bfa5?logo=visualstudiocode&logoColor=white)](https://insiders.vscode.dev/redirect?url=vscode-insiders://chat-plugin/add-marketplace?ref=AndyElessar/skills)

## Plugins

[![VS Code](https://img.shields.io/badge/VS_Code-Install-0098FF?logo=visualstudiocode&logoColor=white)](https://vscode.dev/redirect?url=vscode://chat-plugin/install?source=AndyElessar/skills) [![Insiders](https://img.shields.io/badge/Insiders-Install-24bfa5?logo=visualstudiocode&logoColor=white)](https://insiders.vscode.dev/redirect?url=vscode-insiders://chat-plugin/install?source=AndyElessar/skills)\
Click the button to select a plugin!

| Plugin | License | Tags | Description |
| --- | --- | --- | --- |
| `meta-prompts` | `MIT` | `agents`, `prompts`, `skills`, `plugin`, `meta`, `prose` | Skills for creating, reviewing, and rewriting agent prompts — including agent/plugin file authoring, `SKILL.md` design, and PROSE methodology guidance. |
| `agents-creator` | `MIT` | `agents`, `copilot`, `prompts`, `instructions` | Create, review, rewrite, and debug repository-specific `agents.md`, `.github/agents/*.md`, and `*.agent.md` files. |
| `plugin-creator` | `MIT` | `plugin`, `marketplace`, `copilot`, `manifest` | Create and maintain GitHub Copilot CLI and Claude Code plugins and marketplaces, including `plugin.json` and `marketplace.json` manifests for both platforms. |
| `prose-guide` | `CC-BY-NC-SA-4.0` | `prose`, `ai-native`, `agents`, `workflows` | Guide AI-native development with the PROSE methodology, including context engineering, agent primitives, and spec-driven workflows. |
| `dotnet` | `MIT` | `dotnet`, `aspire`, `csharp` | Skills for .NET development, including Aspire distributed-app orchestration, debugging, and documentation. |
| `aspire-dev` | `MIT` | `dotnet`, `aspire`, `apphost`, `csharp` | Guide .NET Aspire development, including AppHost setup, integrations, runtime operations, debugging, logs, and distributed traces. |
| `rpi-workflow` | `MIT` | `rpi`, `workflow`, `agents` | Agents for RPI workflow — orchestrator, planner, researcher, implementor, and reviewer — using VS Code memory to manage workflow tasks. |
| `skill-guide` | `MIT` | `skills`, `prompts`, `meta`, `design-patterns`, `agents`, `SKILL.md` | Design, write, review, and improve `SKILL.md` files using proven patterns (Tool Wrapper, Generator, Reviewer, Inversion, Pipeline) with intent-based protocols for creating, reviewing, and improving agent skills. |

## Installation

### Copilot CLI

```bash
# Add and browse marketplace
copilot plugin marketplace add AndyElessar/skills
copilot plugin marketplace list
copilot plugin marketplace browse andyelessar-skills

# Install a plugin
copilot plugin install plugin-creator@andyelessar-skills
copilot plugin list
```

### Claude Code

```bash
# Add marketplace (in-session)
/plugin marketplace add AndyElessar/skills

# Install a plugin
/plugin install plugin-creator@andyelessar-skills

# Or load directly from local path during development
claude --plugin-dir ./plugins/plugin-creator
```

## License

See [`LICENSE`](./LICENSE) for repository-level licensing and the table above for each plugin's license.

Some plugins, such as `plugins/prose-guide`, also include their own `LICENSE` files.
