# marketplace.json Reference

Complete schema reference for the Copilot CLI marketplace manifest file.

> **Source**: https://docs.github.com/en/copilot/reference/copilot-cli-reference/cli-plugin-reference#marketplacejson

## Table of Contents

- [Overview](#overview)
- [Top-Level Fields](#top-level-fields)
- [Plugin Entry Fields](#plugin-entry-fields)
- [Full Example](#full-example)
- [Source Field Formats](#source-field-formats)
- [Marketplace as Source of Truth](#marketplace-as-source-of-truth)

---

## Overview

A `marketplace.json` file defines a plugin marketplace — a registry that makes plugins discoverable and installable. The CLI looks for this file at:

- `.github/plugin/marketplace.json`
- `.claude-plugin/marketplace.json`

The `marketplace.json` is the **only required file** for a marketplace. Adding it to a repository allows Copilot CLI to recognize the repository as a plugin marketplace.

---

## Top-Level Fields

| Field | Type | Required | Description |
|---|---|---|---|
| `name` | `string` | Yes | Kebab-case marketplace name. Max 64 characters. |
| `owner` | `object` | Yes | Marketplace owner info. See [Owner Object](#owner-object). |
| `plugins` | `array` | Yes | List of plugin entries. See [Plugin Entry Fields](#plugin-entry-fields). |
| `metadata` | `object` | No | Marketplace metadata. See [Metadata Object](#metadata-object). |

### Owner Object

| Field | Type | Required | Description |
|---|---|---|---|
| `name` | `string` | Yes | Owner/organization name. |
| `email` | `string` | No | Contact email. |

### Metadata Object

| Field | Type | Required | Description |
|---|---|---|---|
| `description` | `string` | No | Marketplace description. |
| `version` | `string` | No | Marketplace version. |
| `pluginRoot` | `string` | No | Common root directory for plugins. |

---

## Plugin Entry Fields

Each object in the `plugins` array describes a plugin. These entries are the **primary source of metadata** for marketplace-distributed plugins.

### Required Fields

| Field | Type | Description |
|---|---|---|
| `name` | `string` | Kebab-case plugin name. Max 64 characters. |
| `source` | `string \| object` | Where to fetch the plugin. See [Source Field Formats](#source-field-formats). |

### Optional Metadata Fields

| Field | Type | Description |
|---|---|---|
| `description` | `string` | Plugin description. Max 1024 characters. |
| `version` | `string` | Plugin version (semver). |
| `author` | `object` | `{ name, email?, url? }` — plugin author info. |
| `homepage` | `string` | Plugin homepage URL. |
| `repository` | `string` | Source repository URL. |
| `license` | `string` | License identifier (e.g., `"MIT"`). |
| `keywords` | `string[]` | Search keywords. |
| `category` | `string` | Plugin category. |
| `tags` | `string[]` | Additional tags. |

### Optional Component Path Fields

| Field | Type | Description |
|---|---|---|
| `agents` | `string \| string[]` | Path(s) to agent directories. |
| `skills` | `string \| string[]` | Path(s) to skill directories. |
| `commands` | `string \| string[]` | Path(s) to command directories. |
| `hooks` | `string \| object` | Path to hooks config or inline hooks object. |
| `mcpServers` | `string \| object` | Path to MCP config or inline server definitions. |
| `lspServers` | `string \| object` | Path to LSP config or inline server definitions. |

### Validation Control

| Field | Type | Default | Description |
|---|---|---|---|
| `strict` | `boolean` | `true` | When `true`, plugins must conform to the full schema and validation rules. When `false`, relaxed validation is used — useful for direct installs or legacy plugins. |

---

## Full Example

```json
{
  "name": "my-marketplace",
  "owner": {
    "name": "Your Organization",
    "email": "plugins@example.com"
  },
  "metadata": {
    "description": "Curated plugins for our team",
    "version": "1.0.0"
  },
  "plugins": [
    {
      "name": "frontend-design",
      "description": "Create a professional-looking GUI with React and Tailwind CSS, including responsive layouts and accessible components",
      "version": "2.1.0",
      "author": {
        "name": "Design Team",
        "email": "design@example.com"
      },
      "license": "MIT",
      "keywords": ["react", "tailwind", "ui", "design"],
      "category": "frontend",
      "tags": ["react", "css", "components"],
      "source": "./plugins/frontend-design",
      "agents": "agents/",
      "skills": ["skills/"],
      "mcpServers": ".mcp.json"
    },
    {
      "name": "security-checks",
      "description": "Check for potential security vulnerabilities in code, dependencies, and configurations",
      "version": "1.3.0",
      "author": {
        "name": "Security Team"
      },
      "license": "MIT",
      "keywords": ["security", "audit", "vulnerability"],
      "category": "security",
      "source": "./plugins/security-checks",
      "skills": ["skills/"],
      "strict": true
    }
  ]
}
```

---

## Source Field Formats

The `source` field tells the CLI where to find the plugin directory.

| Format | Example | Description |
|---|---|---|
| Relative path | `"./plugins/frontend-design"` or `"plugins/frontend-design"` | Relative to the marketplace repository root. |
| GitHub repo | `"OWNER/REPO"` | Root of a GitHub repository. |
| GitHub subdir | `"OWNER/REPO:path/to/plugin"` | Subdirectory within a GitHub repository. |
| Git URL | `"https://github.com/OWNER/REPO.git"` | Any Git URL. |

**Path notes:**
- `"./plugins/plugin-name"` and `"plugins/plugin-name"` resolve to the same directory
- The `./` prefix is optional

---

## Marketplace as Source of Truth

When a plugin is installed via marketplace, the metadata from the `marketplace.json` plugin entry takes priority over the plugin's own `plugin.json`. This is by design:

- **Curators** use `marketplace.json` to control how plugins are presented — descriptions, versions, categorization
- **Plugin authors** use `plugin.json` as the plugin's self-description — a fallback for direct installs

**Best practice:** Always provide comprehensive metadata in the `marketplace.json` plugin entries. Keep `plugin.json` as a minimal fallback with at least `name` and `description`.
