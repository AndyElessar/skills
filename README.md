# skills

Plugin marketplace for **GitHub Copilot CLI** and **Claude Code**, including dotnet, meta-prompts, etc.

## Plugins

| Plugin | License | Tags | Description |
| --- | --- | --- | --- |
| `meta-prompts` | `MIT` | `agents`, `prompts`, `meta`, `prose` | Skills for creating, reviewing, rewriting agent prompts — including agent/plugin file authoring and PROSE methodology guidance. |
| `agents-creator` | `MIT` | `agents`, `copilot`, `prompts`, `instructions` | Create, review, rewrite, and debug repository-specific `agents.md`, `.github/agents/*.md`, and `*.agent.md` files. |
| `plugin-creator` | `MIT` | `plugin`, `marketplace`, `copilot`, `manifest` | Create and maintain GitHub Copilot CLI and Claude Code plugins and marketplaces, including `plugin.json` and `marketplace.json` manifests for both platforms. |
| `prose-guide` | `CC-BY-NC-SA-4.0` | `prose`, `ai-native`, `agents`, `workflows` | Guide AI-native development with the PROSE methodology, including context engineering, agent primitives, and spec-driven workflows. |
| `dotnet` | `MIT` | `dotnet`, `aspire`, `csharp` | Skills for .NET development, including Aspire distributed-app orchestration, debugging, and documentation. |
| `aspire-dev` | `MIT` | `dotnet`, `aspire`, `apphost`, `csharp` | Guide .NET Aspire development, including AppHost setup, integrations, runtime operations, debugging, logs, and distributed traces. |
| `rpi-workflow` | `MIT` | `rpi`, `workflow`, `agents` | Agents for RPI workflow — orchestrator, planner, researcher, implementor, and reviewer — using VS Code memory to manage workflow tasks. |

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
