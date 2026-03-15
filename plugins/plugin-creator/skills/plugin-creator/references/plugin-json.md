# plugin.json Reference

Complete schema reference for the Copilot CLI plugin manifest file.

> **Source**: https://docs.github.com/en/copilot/reference/copilot-cli-reference/cli-plugin-reference#pluginjson

## Table of Contents

- [Overview](#overview)
- [Required Fields](#required-fields)
- [Optional Metadata Fields](#optional-metadata-fields)
- [Component Path Fields](#component-path-fields)
- [Full Example](#full-example)
- [Validation Rules](#validation-rules)

---

## Overview

Every plugin must contain a `plugin.json` manifest at the root of the plugin directory. The CLI looks for this file at:

- `plugin.json` (root of plugin directory)
- `.github/plugin/plugin.json`
- `.claude-plugin/plugin.json`

---

## Required Fields

| Field | Type | Description |
|---|---|---|
| `name` | `string` | Kebab-case plugin name. Only letters, numbers, and hyphens. Max 64 characters. |

---

## Optional Metadata Fields

| Field | Type | Description |
|---|---|---|
| `description` | `string` | Brief description of the plugin. Max 1024 characters. |
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
| `commands` | `string \| string[]` | — | Path(s) to command directories. |
| `hooks` | `string \| object` | — | Path to a hooks config file (e.g., `"hooks.json"`), or an inline hooks object. |
| `mcpServers` | `string \| object` | — | Path to an MCP config file (e.g., `".mcp.json"`), or inline server definitions. |
| `lspServers` | `string \| object` | — | Path to an LSP config file (e.g., `"lsp.json"`), or inline server definitions. |

**Path resolution:**
- Paths are relative to the plugin root directory
- Use a single string for one directory: `"agents/"`
- Use an array for multiple directories: `["skills/", "extra-skills/"]`
- If omitted, the CLI checks the default directory (e.g., `agents/` for agents)

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
  "lspServers": "lsp.json"
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
7. When installing via marketplace, fields in `marketplace.json` plugin entries take priority over `plugin.json`
