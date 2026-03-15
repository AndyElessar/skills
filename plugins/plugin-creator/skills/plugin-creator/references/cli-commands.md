# CLI Commands Reference

Commands and file locations for managing Copilot CLI plugins and marketplaces.

> **Source**: https://docs.github.com/en/copilot/reference/copilot-cli-reference/cli-plugin-reference

## Table of Contents

- [Plugin Commands](#plugin-commands)
- [Marketplace Commands](#marketplace-commands)
- [Install Specification Formats](#install-specification-formats)
- [In-Session Verification](#in-session-verification)
- [File Locations](#file-locations)
- [Loading Order & Precedence](#loading-order--precedence)

---

## Plugin Commands

| Command | Description |
|---|---|
| `copilot plugin install SPECIFICATION` | Install a plugin. See [Install Specification Formats](#install-specification-formats). |
| `copilot plugin uninstall NAME` | Remove a plugin (use plugin name, not path). |
| `copilot plugin list` | List installed plugins. |
| `copilot plugin update NAME` | Update a specific plugin. |
| `copilot plugin update --all` | Update all installed plugins. |
| `copilot plugin disable NAME` | Temporarily disable a plugin without uninstalling. |
| `copilot plugin enable NAME` | Re-enable a disabled plugin. |

> **Tip**: Use `copilot plugin [SUBCOMMAND] --help` for detailed help on any command.

---

## Marketplace Commands

| Command | Description |
|---|---|
| `copilot plugin marketplace add SPECIFICATION` | Register a marketplace. |
| `copilot plugin marketplace list` | List registered marketplaces. |
| `copilot plugin marketplace browse NAME` | Browse available plugins in a marketplace. |
| `copilot plugin marketplace remove NAME` | Unregister a marketplace. |

---

## Install Specification Formats

| Source | Format | Example |
|---|---|---|
| Marketplace | `plugin@marketplace` | `my-plugin@my-marketplace` |
| GitHub repo | `OWNER/REPO` | `janedoe/my-plugin` |
| GitHub subdir | `OWNER/REPO:PATH/TO/PLUGIN` | `janedoe/mono-repo:plugins/my-plugin` |
| Git URL | `https://github.com/o/r.git` | `https://github.com/janedoe/my-plugin.git` |
| Local path | `./my-plugin` or `/abs/path` | `./my-plugin` |

---

## In-Session Verification

After installing a plugin, verify its components loaded correctly in an interactive Copilot session:

```
# List custom agents
/agent

# List available skills
/skills list

# List plugins
/plugin list
```

---

## File Locations

| Component | Location |
|---|---|
| **Plugin manifest** | `plugin.json`, `.github/plugin/plugin.json`, or `.claude-plugin/plugin.json` |
| **Marketplace manifest** | `.github/plugin/marketplace.json` or `.claude-plugin/marketplace.json` |
| **Installed plugins (marketplace)** | `~/.copilot/state/installed-plugins/MARKETPLACE/PLUGIN-NAME` |
| **Installed plugins (direct)** | `~/.copilot/state/installed-plugins/PLUGIN-NAME` |
| **Marketplace cache** | `~/.copilot/state/marketplace-cache/` |
| **Agents** | `agents/` (default, overridable in manifest) |
| **Skills** | `skills/` (default, overridable in manifest) |
| **Hooks config** | `hooks.json` or `hooks/hooks.json` |
| **MCP config** | `.mcp.json`, `.vscode/mcp.json`, `.devcontainer/devcontainer.json`, `.github/mcp.json` |
| **LSP config** | `lsp.json` or `.github/lsp.json` |

---

## Loading Order & Precedence

When multiple sources provide components with the same name, the CLI resolves conflicts using the following order. Components listed earlier take priority for agents/skills (first-found wins).

### Agents (first-found wins, deduplicated by ID)

```
1. ~/.copilot/agents/              (user, .github convention)
2. <project>/.github/agents/       (project)
3. <parents>/.github/agents/       (inherited, monorepo)
4. ~/.claude/agents/               (user, .claude convention)
5. <project>/.claude/agents/       (project)
6. <parents>/.claude/agents/       (inherited, monorepo)
7. PLUGIN: agents/ dirs            (plugin, by install order)
8. Remote org/enterprise agents    (remote, via API)
```

### Skills (first-found wins, deduplicated by name)

```
1. <project>/.github/skills/       (project)
2. <project>/.agents/skills/       (project)
3. <project>/.claude/skills/       (project)
4. <parents>/.github/skills/ etc.  (inherited)
5. ~/.copilot/skills/              (personal-copilot)
6. ~/.claude/skills/               (personal-claude)
7. PLUGIN: skills/ dirs            (plugin)
8. COPILOT_SKILLS_DIRS env+config  (custom)
```

### MCP Servers (last-wins, deduplicated by server name)

```
1. ~/.copilot/mcp-config.json      (lowest priority)
2. .vscode/mcp.json                (workspace)
3. PLUGIN: MCP configs             (plugins)
4. --additional-mcp-config flag    (highest priority)
```

### Key implications for plugin authors

- **Your plugin cannot override project-level agents or skills.** If a user has a project-level agent or skill with the same name/ID, your plugin's version is silently ignored.
- **Your plugin's MCP servers can override user-level configs.** Be cautious about MCP server naming to avoid unintended overrides.
- **Built-in tools and agents are always present** and cannot be overridden by any user-defined component.
