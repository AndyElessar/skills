# marketplace.json Reference

Complete schema reference for the plugin marketplace manifest file used by both **Copilot CLI** and **Claude Code**.

> **Sources**:
> - Copilot CLI: https://docs.github.com/en/copilot/reference/copilot-cli-reference/cli-plugin-reference#marketplacejson
> - Claude Code: https://code.claude.com/docs/en/plugin-marketplaces

## Table of Contents

- [Overview](#overview)
- [Top-Level Fields](#top-level-fields)
- [Plugin Entry Fields](#plugin-entry-fields)
- [Full Example](#full-example)
- [Source Field Formats](#source-field-formats)
- [Marketplace as Source of Truth](#marketplace-as-source-of-truth)
- [Claude Code Extras](#claude-code-extras)

---

## Overview

A `marketplace.json` file defines a plugin marketplace — a registry that makes plugins discoverable and installable. The location differs by platform:

| Platform | Location |
|---|---|
| Copilot CLI | `.github/plugin/marketplace.json` or `.claude-plugin/marketplace.json` |
| Claude Code | `.claude-plugin/marketplace.json` |

The `marketplace.json` is the **only required file** for a marketplace. Adding it to a repository allows the CLI to recognize the repository as a plugin marketplace.

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
| `pluginRoot` | `string` | No | Base directory prepended to relative plugin source paths (e.g., `"./plugins"` lets you write `"source": "formatter"` instead of `"source": "./plugins/formatter"`). |

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
| `strict` | `boolean` | `true` | **Claude Code**: When `true`, `plugin.json` is the authority for component definitions and the marketplace entry supplements with additional components (both merged). When `false`, the marketplace entry is the entire definition — plugin doesn't need its own `plugin.json`. **Copilot CLI**: When `true`, full schema validation. When `false`, relaxed validation. |

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

### Relative paths (both platforms)

| Format | Example | Description |
|---|---|---|
| Relative path | `"./plugins/frontend-design"` or `"plugins/frontend-design"` | Relative to the marketplace repository root. |

**Path notes:**
- `"./plugins/plugin-name"` and `"plugins/plugin-name"` resolve to the same directory
- The `./` prefix is optional
- Claude Code: paths must start with `./` and resolve relative to the marketplace root (the directory containing `.claude-plugin/`). Don't use `../`.

### Copilot CLI source formats

| Format | Example | Description |
|---|---|---|
| GitHub repo | `"OWNER/REPO"` | Root of a GitHub repository. |
| GitHub subdir | `"OWNER/REPO:path/to/plugin"` | Subdirectory within a GitHub repository. |
| Git URL | `"https://github.com/OWNER/REPO.git"` | Any Git URL. |

### Claude Code source formats (object syntax)

Claude Code supports richer source types as objects:

#### GitHub

```json
{
  "source": {
    "source": "github",
    "repo": "owner/plugin-repo",
    "ref": "v2.0.0",
    "sha": "a1b2c3d4e5f6a7b8c9d0e1f2a3b4c5d6e7f8a9b0"
  }
}
```

| Field | Type | Required | Description |
|---|---|---|---|
| `repo` | `string` | Yes | GitHub repository in `owner/repo` format. |
| `ref` | `string` | No | Git branch or tag (defaults to default branch). |
| `sha` | `string` | No | Full 40-character git commit SHA for exact version. |

#### Git URL

```json
{
  "source": {
    "source": "url",
    "url": "https://gitlab.com/team/plugin.git",
    "ref": "main",
    "sha": "a1b2c3d4e5f6a7b8c9d0e1f2a3b4c5d6e7f8a9b0"
  }
}
```

| Field | Type | Required | Description |
|---|---|---|---|
| `url` | `string` | Yes | Full git repository URL (https:// or git@). `.git` suffix optional. |
| `ref` | `string` | No | Git branch or tag. |
| `sha` | `string` | No | Full 40-character git commit SHA. |

#### Git subdirectory

Uses sparse partial clone to fetch only the subdirectory — ideal for monorepos.

```json
{
  "source": {
    "source": "git-subdir",
    "url": "https://github.com/acme-corp/monorepo.git",
    "path": "tools/claude-plugin",
    "ref": "v2.0.0"
  }
}
```

| Field | Type | Required | Description |
|---|---|---|---|
| `url` | `string` | Yes | Git repository URL, GitHub `owner/repo` shorthand, or SSH URL. |
| `path` | `string` | Yes | Subdirectory path within the repo containing the plugin. |
| `ref` | `string` | No | Git branch or tag. |
| `sha` | `string` | No | Full 40-character git commit SHA. |

#### NPM

```json
{
  "source": {
    "source": "npm",
    "package": "@acme/claude-plugin",
    "version": "^2.0.0",
    "registry": "https://npm.example.com"
  }
}
```

| Field | Type | Required | Description |
|---|---|---|---|
| `package` | `string` | Yes | Package name or scoped package (e.g., `@org/plugin`). |
| `version` | `string` | No | Version or range (e.g., `2.1.0`, `^2.0.0`, `~1.5.0`). |
| `registry` | `string` | No | Custom npm registry URL. Defaults to npmjs.org. |

#### pip

```json
{
  "source": {
    "source": "pip",
    "package": "claude-plugin-tools",
    "version": ">=2.0.0"
  }
}
```

| Field | Type | Required | Description |
|---|---|---|---|
| `package` | `string` | Yes | PyPI package name. |
| `version` | `string` | No | Version specifier. |
| `registry` | `string` | No | Custom PyPI registry URL. |

---

## Marketplace as Source of Truth

When a plugin is installed via marketplace, the metadata from the `marketplace.json` plugin entry takes priority over the plugin's own `plugin.json`. This is by design:

- **Curators** use `marketplace.json` to control how plugins are presented — descriptions, versions, categorization
- **Plugin authors** use `plugin.json` as the plugin's self-description — a fallback for direct installs

**Best practice:** Always provide comprehensive metadata in the `marketplace.json` plugin entries. Keep `plugin.json` as a minimal fallback with at least `name` and `description`.

### Copilot CLI behavior
Marketplace entry always takes priority over `plugin.json` for discoverability metadata.

### Claude Code behavior
Controlled by the `strict` field on each plugin entry:

| `strict` | Behavior |
|---|---|
| `true` (default) | `plugin.json` is the authority for components. Marketplace entry supplements with additional components — both sources merged. |
| `false` | Marketplace entry is the entire definition. If `plugin.json` also declares components, it creates a conflict and the plugin fails to load. |

**When to use:**
- **`strict: true`**: Plugin has its own `plugin.json` and manages its components. Marketplace entry adds extra commands or hooks. Works for most plugins.
- **`strict: false`**: Marketplace operator wants full control. Plugin repo provides raw files; marketplace entry defines which are exposed. Useful for restructuring or curating differently than the plugin author intended.

---

## Claude Code Extras

### Reserved marketplace names

Claude Code blocks the following marketplace names:
- `claude-code-marketplace`, `claude-code-plugins`, `claude-plugins-official`
- `anthropic-marketplace`, `anthropic-plugins`
- `agent-skills`, `life-sciences`
- Names impersonating official marketplaces (e.g., `official-claude-plugins`, `anthropic-tools-v2`)

### Version resolution

⚠️ Avoid setting version in both `marketplace.json` and `plugin.json`. The plugin manifest always wins silently, potentially ignoring the marketplace version. For relative-path plugins, set version in the marketplace entry. For external-source plugins, set it in the plugin manifest.

### Plugin caching and file resolution

When users install a plugin, Claude Code copies the plugin directory to a cache location. Plugins cannot reference files outside their directory using `../` — those files won't be copied. **Solution**: Use symlinks (which are followed during copying).

### Team distribution via settings

Require marketplaces for team members by adding to `.claude/settings.json`:

```json
{
  "extraKnownMarketplaces": {
    "company-tools": {
      "source": {
        "source": "github",
        "repo": "your-org/claude-plugins"
      }
    }
  },
  "enabledPlugins": {
    "code-formatter@company-tools": true,
    "deployment-tools@company-tools": true
  }
}
```

### Managed marketplace restrictions

Organizations can restrict which marketplaces users can add using `strictKnownMarketplaces` in managed settings:

| Value | Behavior |
|---|---|
| Undefined (default) | No restrictions — users can add any marketplace. |
| Empty array `[]` | Complete lockdown — users cannot add new marketplaces. |
| List of sources | Users can only add marketplaces matching the allowlist exactly. |

Supports exact matching, `hostPattern` (regex), and `pathPattern` (regex) for flexible control.

### Inline hooks and MCP servers

Claude Code marketplace entries can define hooks and MCP servers inline (not just paths):

```json
{
  "name": "enterprise-tools",
  "source": { "source": "github", "repo": "company/enterprise-plugin" },
  "hooks": {
    "PostToolUse": [{
      "matcher": "Write|Edit",
      "hooks": [{
        "type": "command",
        "command": "${CLAUDE_PLUGIN_ROOT}/scripts/validate.sh"
      }]
    }]
  },
  "mcpServers": {
    "enterprise-db": {
      "command": "${CLAUDE_PLUGIN_ROOT}/servers/db-server",
      "args": ["--config", "${CLAUDE_PLUGIN_ROOT}/config.json"]
    }
  }
}
```

Use `${CLAUDE_PLUGIN_ROOT}` to reference files within the plugin's cached installation directory.
