# skills

Plugin marketplace for **GitHub Copilot CLI** and **Claude Code**, including dotnet, meta-prompts, etc.

[![Add Marketplace in VS Code](https://img.shields.io/badge/VS_Code-Add_Marketplace-0098FF?logo=visualstudiocode&logoColor=white)](vscode://chat-plugin/add-marketplace?ref=AndyElessar/skills) [![Add Marketplace in Insiders](https://img.shields.io/badge/Insiders-Add_Marketplace-24bfa5?logo=visualstudiocode&logoColor=white)](vscode-insiders://chat-plugin/add-marketplace?ref=AndyElessar/skills)

## Plugins

| Plugin | License | Tags | Install | Description |
| --- | --- | --- | --- | --- |
| `meta-prompts` | `MIT` | `agents`, `prompts`, `skills`, `plugin`, `meta`, `prose` | [![VS Code](https://img.shields.io/badge/VS_Code-Install-0098FF?logo=visualstudiocode&logoColor=white)](vscode://chat-plugin/install?source=meta-prompts@andyelessar-skills) [![Insiders](https://img.shields.io/badge/Insiders-Install-24bfa5?logo=visualstudiocode&logoColor=white)](vscode-insiders://chat-plugin/install?source=meta-prompts@andyelessar-skills) | Skills for creating, reviewing, and rewriting agent prompts — including agent/plugin file authoring, `SKILL.md` design, and PROSE methodology guidance. |
| `agents-creator` | `MIT` | `agents`, `copilot`, `prompts`, `instructions` | [![VS Code](https://img.shields.io/badge/VS_Code-Install-0098FF?logo=visualstudiocode&logoColor=white)](vscode://chat-plugin/install?source=agents-creator@andyelessar-skills) [![Insiders](https://img.shields.io/badge/Insiders-Install-24bfa5?logo=visualstudiocode&logoColor=white)](vscode-insiders://chat-plugin/install?source=agents-creator@andyelessar-skills) | Create, review, rewrite, and debug repository-specific `agents.md`, `.github/agents/*.md`, and `*.agent.md` files. |
| `plugin-creator` | `MIT` | `plugin`, `marketplace`, `copilot`, `manifest` | [![VS Code](https://img.shields.io/badge/VS_Code-Install-0098FF?logo=visualstudiocode&logoColor=white)](vscode://chat-plugin/install?source=plugin-creator@andyelessar-skills) [![Insiders](https://img.shields.io/badge/Insiders-Install-24bfa5?logo=visualstudiocode&logoColor=white)](vscode-insiders://chat-plugin/install?source=plugin-creator@andyelessar-skills) | Create and maintain GitHub Copilot CLI and Claude Code plugins and marketplaces, including `plugin.json` and `marketplace.json` manifests for both platforms. |
| `prose-guide` | `CC-BY-NC-SA-4.0` | `prose`, `ai-native`, `agents`, `workflows` | [![VS Code](https://img.shields.io/badge/VS_Code-Install-0098FF?logo=visualstudiocode&logoColor=white)](vscode://chat-plugin/install?source=prose-guide@andyelessar-skills) [![Insiders](https://img.shields.io/badge/Insiders-Install-24bfa5?logo=visualstudiocode&logoColor=white)](vscode-insiders://chat-plugin/install?source=prose-guide@andyelessar-skills) | Guide AI-native development with the PROSE methodology, including context engineering, agent primitives, and spec-driven workflows. |
| `dotnet` | `MIT` | `dotnet`, `aspire`, `csharp` | [![VS Code](https://img.shields.io/badge/VS_Code-Install-0098FF?logo=visualstudiocode&logoColor=white)](vscode://chat-plugin/install?source=dotnet@andyelessar-skills) [![Insiders](https://img.shields.io/badge/Insiders-Install-24bfa5?logo=visualstudiocode&logoColor=white)](vscode-insiders://chat-plugin/install?source=dotnet@andyelessar-skills) | Skills for .NET development, including Aspire distributed-app orchestration, debugging, and documentation. |
| `aspire-dev` | `MIT` | `dotnet`, `aspire`, `apphost`, `csharp` | [![VS Code](https://img.shields.io/badge/VS_Code-Install-0098FF?logo=visualstudiocode&logoColor=white)](vscode://chat-plugin/install?source=aspire-dev@andyelessar-skills) [![Insiders](https://img.shields.io/badge/Insiders-Install-24bfa5?logo=visualstudiocode&logoColor=white)](vscode-insiders://chat-plugin/install?source=aspire-dev@andyelessar-skills) | Guide .NET Aspire development, including AppHost setup, integrations, runtime operations, debugging, logs, and distributed traces. |
| `rpi-workflow` | `MIT` | `rpi`, `workflow`, `agents` | [![VS Code](https://img.shields.io/badge/VS_Code-Install-0098FF?logo=visualstudiocode&logoColor=white)](vscode://chat-plugin/install?source=rpi-workflow@andyelessar-skills) [![Insiders](https://img.shields.io/badge/Insiders-Install-24bfa5?logo=visualstudiocode&logoColor=white)](vscode-insiders://chat-plugin/install?source=rpi-workflow@andyelessar-skills) | Agents for RPI workflow — orchestrator, planner, researcher, implementor, and reviewer — using VS Code memory to manage workflow tasks. |
| `skill-guide` | `MIT` | `skills`, `prompts`, `meta`, `design-patterns`, `agents`, `SKILL.md` | [![VS Code](https://img.shields.io/badge/VS_Code-Install-0098FF?logo=visualstudiocode&logoColor=white)](vscode://chat-plugin/install?source=skill-guide@andyelessar-skills) [![Insiders](https://img.shields.io/badge/Insiders-Install-24bfa5?logo=visualstudiocode&logoColor=white)](vscode-insiders://chat-plugin/install?source=skill-guide@andyelessar-skills) | Design, write, review, and improve `SKILL.md` files using proven patterns (Tool Wrapper, Generator, Reviewer, Inversion, Pipeline) with intent-based protocols for creating, reviewing, and improving agent skills. |

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
