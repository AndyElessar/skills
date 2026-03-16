# plugin.json Reference

Complete schema reference for the plugin manifest file used by both **Copilot CLI** and **Claude Code**.

> **Sources**:
> - Copilot CLI: https://docs.github.com/en/copilot/reference/copilot-cli-reference/cli-plugin-reference#pluginjson
> - Claude Code: https://code.claude.com/docs/en/plugins

## Table of Contents

- [Overview](#overview)
- [Required Fields](#required-fields)
- [Optional Metadata Fields](#optional-metadata-fields)
- [Component Path Fields](#component-path-fields)
- [Full Example](#full-example)
- [Validation Rules](#validation-rules)
- [Platform Differences](#platform-differences)

---

## Overview

Every plugin must contain a `plugin.json` manifest. The location differs by platform:

### Copilot CLI

Looks for the manifest at (in order):

- `plugin.json` (root of plugin directory)
- `.github/plugin/plugin.json`
- `.claude-plugin/plugin.json`

### Claude Code

Looks for the manifest at:

- `.claude-plugin/plugin.json` (inside the plugin directory)

⚠️ **Claude Code**: Only `plugin.json` goes inside `.claude-plugin/`. Do **not** put `commands/`, `agents/`, `skills/`, or `hooks/` inside `.claude-plugin/` — those belong at the plugin root.

### Dual-platform

To support both platforms, place `plugin.json` at:
- `<plugin-dir>/plugin.json` → Copilot CLI
- `<plugin-dir>/.claude-plugin/plugin.json` → Claude Code

Both files can have identical content.

---

## Required Fields

| Field | Type | Description |
|---|---|---|
| `name` | `string` | Kebab-case plugin name. Only letters, numbers, and hyphens. Max 64 characters. Used as skill namespace in Claude Code (e.g., `/my-plugin:hello`). |

---

## Optional Metadata Fields

| Field | Type | Description |
|---|---|---|
| `description` | `string` | Brief description of the plugin. Max 1024 characters. Shown in plugin manager. |
| `version` | `string` | Semantic version (e.g., `"1.0.0"`). |
| `author` | `object` | Author information. See [Author Object](#author-object). |
| `homepage` | `string` | Plugin homepage URL. |
| `repository` | `string` | Source repository URL. |
| `license` | `string` | License identifier (e.g., `"MIT"`, `"Apache-2.0"`). |
| `keywords` | `string[]` | Search keywords for discoverability. |
| `category` | `string` | Plugin category. |
| `tags` | `string[]` | Additional tags. |

### Author Object

| Field | Type | Required | Description |
|---|---|---|---|
| `name` | `string` | Yes | Author name. |
| `email` | `string` | No | Author email. |
| `url` | `string` | No | Author URL. |

---

## Component Path Fields

These tell the CLI where to find plugin components. All are optional. The CLI uses default conventions if omitted.

| Field | Type | Default | Description |
|---|---|---|---|
| `agents` | `string \| string[]` | `agents/` | Path(s) to agent directories containing `.agent.md` files. |
| `skills` | `string \| string[]` | `skills/` | Path(s) to skill directories containing `SKILL.md` files. |
| `commands` | `string \| string[]` | `commands/` | Path(s) to command directories (Markdown files). |
| `hooks` | `string \| object` | — | Path to a hooks config file (e.g., `"hooks.json"`) or an inline hooks object. Claude Code convention: `hooks/hooks.json`. |
| `mcpServers` | `string \| object` | — | Path to an MCP config file (e.g., `".mcp.json"`) or inline server definitions. |
| `lspServers` | `string \| object` | — | Path to an LSP config file (e.g., `".lsp.json"` for Claude Code, `"lsp.json"` for Copilot CLI) or inline server definitions. |

**Path resolution:**
- Paths are relative to the plugin root directory
- Use a single string for one directory: `"agents/"`
- Use an array for multiple directories: `["skills/", "extra-skills/"]`
- If omitted, the CLI checks the default directory (e.g., `agents/` for agents)
- **Claude Code**: Use `${CLAUDE_PLUGIN_ROOT}` in hooks and MCP server configs to reference files within the plugin's cached installation directory

---

## Full Example

```json
{
  "name": "my-dev-tools",
  "description": "React development utilities with code generation, testing helpers, and deployment automation",
  "version": "1.2.0",
  "author": {
    "name": "Jane Doe",
    "email": "jane@example.com",
    "url": "https://github.com/janedoe"
  },
  "homepage": "https://github.com/janedoe/my-dev-tools",
  "repository": "https://github.com/janedoe/my-dev-tools",
  "license": "MIT",
  "keywords": ["react", "frontend", "testing"],
  "category": "development",
  "tags": ["react", "vite", "typescript"],
  "agents": "agents/",
  "skills": ["skills/", "extra-skills/"],
  "commands": "commands/",
  "hooks": "hooks.json",
  "mcpServers": ".mcp.json",
  "lspServers": ".lsp.json"
}
```

---

## Validation Rules

1. **`name`** is the only required field
2. **`name`** must be kebab-case: lowercase letters, numbers, hyphens only (no spaces, underscores, or special characters)
3. **`name`** max length: 64 characters
4. **`description`** max length: 1024 characters
5. **`version`** should follow semantic versioning (`MAJOR.MINOR.PATCH`)
6. Component path fields must point to existing directories or files within the plugin
7. When installing via marketplace, fields in `marketplace.json` plugin entries take priority over `plugin.json` (Copilot CLI) or supplement/override depending on `strict` mode (Claude Code)
8. **Claude Code**: Run `claude plugin validate .` or `/plugin validate .` to check for errors

---

## Platform Differences

| Aspect | Copilot CLI | Claude Code |
|---|---|---|
| **Manifest location** | `plugin.json` at plugin root | `.claude-plugin/plugin.json` |
| **Hooks convention** | `hooks.json` at root | `hooks/hooks.json` |
| **LSP config** | `lsp.json` or `.github/lsp.json` | `.lsp.json` |
| **Commands** | `commands/` | `commands/` |
| **Settings** | — | `settings.json` (default agent, tool restrictions) |
| **Path variable** | — | `${CLAUDE_PLUGIN_ROOT}` for hooks/MCP paths |
| **Validation** | — | `claude plugin validate .` |
| **Marketplace authority** | Marketplace entry always takes priority | Controlled by `strict` field |

### Claude Code: settings.json

Claude Code plugins can include a `settings.json` at the plugin root to set defaults when the plugin is enabled:

```json
{
  "agent": "security-reviewer"
}
```

This activates a custom agent as the main thread, applying its system prompt, tool restrictions, and model. Takes priority over `plugin.json` settings.

### Claude Code: strict mode interaction

When installed via a marketplace:
- **`strict: true`** (default) — `plugin.json` is the authority for component definitions. The marketplace entry can add supplementary components; both sources are merged.
- **`strict: false`** — The marketplace entry is the entire plugin definition. If `plugin.json` also declares components, it creates a conflict and the plugin fails to load.
