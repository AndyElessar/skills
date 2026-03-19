---
name: plugin-creator
description: "Guide AI agents through creating GitHub Copilot CLI and Claude Code plugins and plugin marketplaces — from scaffolding plugin directories and writing plugin.json manifests to building marketplace.json registries and testing installations. Use this skill whenever the user wants to create, scaffold, configure, package, or publish a Copilot CLI or Claude Code plugin, write or edit a plugin.json or marketplace.json file, set up a plugin marketplace repository, or troubleshoot plugin installation and loading issues. Also trigger when the user mentions 'copilot plugin', 'claude plugin', plugin manifests, plugin registries, plugin distribution, or asks how to package agents/skills/hooks/MCP servers into an installable plugin — even if they don't explicitly say 'plugin.json'. Do NOT use this skill for authoring the contents of plugin components (agents, skills, hooks, MCP configs) — delegate those to the appropriate specialized skills."
---

# Plugin Creator (Copilot CLI & Claude Code)

## Purpose

Help developers create, configure, and distribute plugins and plugin marketplaces for **both GitHub Copilot CLI and Claude Code**. This skill covers the structural scaffolding, manifest configuration, and testing workflow — not the authoring of individual components (agents, skills, hooks, MCP servers) that live inside plugins.

Both platforms share the same plugin concept but differ in directory conventions, manifest locations, CLI commands, and some schema features. This skill generates **dual-platform** compatible plugins whenever possible.

> **Docs evolve.** Check the latest references:
> - Copilot CLI: https://docs.github.com/en/copilot/reference/copilot-cli-reference/cli-plugin-reference
> - Claude Code plugins: https://code.claude.com/docs/en/plugins
> - Claude Code marketplaces: https://code.claude.com/docs/en/plugin-marketplaces

## Decision Flow

| User Intent | Go To |
|---|---|
| "Create a new plugin" | → [Creating a Plugin](#creating-a-plugin) |
| "Set up plugin.json" | → [references/plugin-json.md](./references/plugin-json.md) |
| "Create a marketplace" | → [Creating a Marketplace](#creating-a-marketplace) |
| "Set up marketplace.json" | → [references/marketplace-json.md](./references/marketplace-json.md) |
| "Test / install my plugin" | → [references/testing.md](./references/testing.md) |
| "Distribute my plugin" | → [references/distribution.md](./references/distribution.md) |
| CLI commands reference | → [references/cli-commands.md](./references/cli-commands.md) |
| Plugin loading order | → [Loading Order & Precedence](#loading-order--precedence) |
| "Sync plugin.json from marketplace" | → [Automation Scripts](#automation-scripts) |
| Platform differences | → [Platform Comparison](#platform-comparison) |

---

## Platform Comparison

Both Copilot CLI and Claude Code support the same plugin concept but with different conventions:

| Aspect | Copilot CLI | Claude Code |
|---|---|---|
| **Plugin manifest location** | `plugin.json` at plugin root (or `.github/plugin/plugin.json`, `.claude-plugin/plugin.json`) | `.claude-plugin/plugin.json` inside plugin dir |
| **Marketplace manifest** | `.github/plugin/marketplace.json` or `.claude-plugin/marketplace.json` | `.claude-plugin/marketplace.json` |
| **CLI prefix** | `copilot plugin ...` | `/plugin ...` (in-session) or `claude plugin ...` (terminal) |
| **Reload command** | Reinstall the plugin | `/reload-plugins` |
| **Validation command** | — | `claude plugin validate .` or `/plugin validate .` |
| **Extra component types** | — | `commands/`, `settings.json`, `.lsp.json` |
| **Plugin source types** | Relative path, GitHub repo, Git URL | Relative path, `github`, `url`, `git-subdir`, `npm`, `pip` |
| **Path variable in hooks/MCP** | — | `${CLAUDE_PLUGIN_ROOT}` |
| **Strict mode** | — | `strict` field (default `true`) controls marketplace vs plugin.json authority |
| **Plugin cache** | `~/.copilot/state/installed-plugins/` | `~/.claude/plugins/cache/` |
| **Skills invocation** | `/skills list` | `/plugin-name:skill-name` (namespaced) |

> **Dual-platform strategy**: To support both platforms from a single repository, place `plugin.json` at both the plugin root (for Copilot CLI) **and** `.claude-plugin/plugin.json` (for Claude Code). Use the automation script to generate both from `marketplace.json`.

---

## Creating a Plugin

A plugin is a directory containing, at minimum, a `plugin.json` manifest. Components are optional.

### Step 1: Scaffold the directory

**Dual-platform layout** (recommended):

```
my-plugin/
├── plugin.json               # Copilot CLI manifest
├── .claude-plugin/
│   └── plugin.json           # Claude Code manifest
├── agents/                   # Custom agents (optional)
│   └── helper.agent.md
├── skills/                   # Skills (optional)
│   └── deploy/
│       └── SKILL.md
├── commands/                 # Commands — Claude Code (optional)
│   └── deploy.md
├── hooks.json                # Hook configuration — Copilot CLI (optional)
├── hooks/
│   └── hooks.json            # Hook configuration — Claude Code (optional)
├── .mcp.json                 # MCP server config (optional)
├── .lsp.json                 # LSP server config — Claude Code (optional)
└── settings.json             # Default settings — Claude Code (optional)
```

Create the plugin directory first, then add the manifest(s). Component directories are only needed when the plugin provides those components.

> **Copilot CLI only?** Put `plugin.json` at root, skip `.claude-plugin/`.
> **Claude Code only?** Put `plugin.json` inside `.claude-plugin/`, skip root `plugin.json`.
> **Both?** Generate both with the [automation script](#automation-scripts).

⚠️ **Claude Code**: Don't put `commands/`, `agents/`, `skills/`, or `hooks/` inside `.claude-plugin/` — only `plugin.json` goes there.

### Step 2: Write plugin.json

The manifest is the identity of the plugin. At minimum it needs a `name`; everything else is optional but recommended for discoverability.

```json
{
  "name": "my-dev-tools",
  "description": "React development utilities",
  "version": "1.2.0",
  "author": {
    "name": "Jane Doe",
    "email": "jane@example.com"
  },
  "license": "MIT",
  "keywords": ["react", "frontend"],
  "agents": "agents/",
  "skills": ["skills/", "extra-skills/"],
  "hooks": "hooks.json",
  "mcpServers": ".mcp.json",
  "lspServers": ".lsp.json"
}
```

For the full schema with all fields, see [references/plugin-json.md](./references/plugin-json.md).

**Key rules:**
- `name` must be kebab-case (letters, numbers, hyphens only), max 64 characters
- Component path fields (`agents`, `skills`, `commands`, `hooks`, `mcpServers`, `lspServers`) tell the CLI where to find components. If omitted, the CLI uses default conventions (e.g., `agents/` for agents, `skills/` for skills)
- Paths can be a single string or an array of strings for multiple directories

### Step 3: Add components

Add the appropriate files in the directories you defined:

- **Agents**: Create `NAME.agent.md` files in the agents directory
- **Skills**: Create `skills/NAME/SKILL.md` subdirectories
- **Commands**: Create Markdown files in `commands/` (Claude Code)
- **Hooks**: Create `hooks.json` at root (Copilot CLI) or `hooks/hooks.json` (Claude Code)
- **MCP servers**: Create `.mcp.json`, `.vscode/mcp.json`, or `.github/mcp.json`
- **LSP servers**: Create `.lsp.json` or `lsp.json` (Claude Code / Copilot CLI)
- **Settings**: Create `settings.json` at plugin root (Claude Code — sets default agent, etc.)

The contents of these components are outside the scope of this skill. Use specialized skills (e.g., `agents-creator` for agent files) for authoring component contents.

**Claude Code hooks note**: Use `${CLAUDE_PLUGIN_ROOT}` in hook commands and MCP server configs to reference files within the plugin's installation directory (plugins are copied to a cache location):

```json
{
  "hooks": {
    "PostToolUse": [{
      "matcher": "Write|Edit",
      "hooks": [{
        "type": "command",
        "command": "${CLAUDE_PLUGIN_ROOT}/scripts/validate.sh"
      }]
    }]
  }
}
```

### Step 4: Test the plugin

See [Testing & Validation](#testing--validation) below.

---

## Creating a Marketplace

A marketplace is a registry of plugins stored in a repository. The `marketplace.json` file is the **primary source of truth** for plugin metadata — it's what users see when browsing and what the CLI reads for installation. Individual `plugin.json` files inside each plugin serve as fallback.

### Marketplace structure

**Dual-platform layout** (recommended):

```
my-marketplace/
├── .github/
│   └── plugin/
│       └── marketplace.json    # Copilot CLI marketplace manifest
├── .claude-plugin/
│   └── marketplace.json        # Claude Code marketplace manifest
└── plugins/
    ├── frontend-design/
    │   ├── plugin.json         # Copilot CLI plugin manifest
    │   ├── .claude-plugin/
    │   │   └── plugin.json     # Claude Code plugin manifest
    │   ├── agents/
    │   └── skills/
    └── security-checks/
        ├── plugin.json
        ├── .claude-plugin/
        │   └── plugin.json
        └── skills/
```

> Use the [automation script](#automation-scripts) to generate all manifest files from a single `marketplace.json` source of truth.

### Step 1: Write marketplace.json

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
      "description": "Create a professional-looking GUI ...",
      "version": "2.1.0",
      "source": "./plugins/frontend-design"
    },
    {
      "name": "security-checks",
      "description": "Check for potential security vulnerabilities ...",
      "version": "1.3.0",
      "source": "./plugins/security-checks"
    }
  ]
}
```

For the full schema with all fields, see [references/marketplace-json.md](./references/marketplace-json.md).

### Marketplace as source of truth

When publishing plugins through a marketplace, define complete metadata in the `plugins` array entries of `marketplace.json`. This is what users see when browsing. Each plugin entry can include all metadata fields (`description`, `version`, `author`, `keywords`, `category`, `tags`, etc.) plus component path overrides — the same fields available in `plugin.json`.

**Copilot CLI**: marketplace entry takes priority over `plugin.json` for discoverability.

**Claude Code**: the `strict` field controls authority:
- `strict: true` (default) — `plugin.json` is authority for components; marketplace entry supplements with additional components (both merged)
- `strict: false` — marketplace entry is the entire definition; plugin doesn't need its own `plugin.json`

Think of it this way:
- **`marketplace.json` plugin entries** → Curator's view. Controls what users see and how plugins are presented.
- **`plugin.json`** → Plugin's self-description. Fallback when installed directly (not via marketplace).

### Step 2: Add plugin directories

For each plugin listed in `marketplace.json`, create the plugin directory at the `source` path specified. Each plugin directory should contain its own `plugin.json` (unless `strict: false` in Claude Code).

The `source` field is relative to the repository root. Both `"./plugins/plugin-name"` and `"plugins/plugin-name"` resolve to the same directory.

**Claude Code plugin sources** can also be objects for external sources:

```json
{
  "name": "external-tool",
  "source": {
    "source": "github",
    "repo": "company/external-plugin",
    "ref": "v2.0.0"
  }
}
```

See [references/marketplace-json.md](./references/marketplace-json.md) for all source types (`github`, `url`, `git-subdir`, `npm`, `pip`).

### Step 3: Place marketplace.json

| Platform | Location |
|---|---|
| Copilot CLI | `.github/plugin/marketplace.json` |
| Claude Code | `.claude-plugin/marketplace.json` |
| Both | Place in both locations (use the automation script) |

### Step 4: Test the marketplace

See [Testing & Validation](#testing--validation) below.

---

## Testing & Validation

Always test plugins before distributing. The full testing guide — CLI commands for both platforms, a pre-distribution checklist, and a troubleshooting table — lives in [references/testing.md](./references/testing.md).

**Quick test flow:**

1. **Install / load** the plugin locally (`copilot plugin install ./my-plugin` or `claude --plugin-dir ./my-plugin`)
2. **Verify** it appears in the plugin list and components are accessible
3. **Iterate** — Copilot: reinstall the plugin; Claude Code: `/reload-plugins`
4. **Claude Code validation**: `claude plugin validate .` checks JSON syntax and schema
5. **Clean up** — uninstall when done testing

> Read [references/testing.md](./references/testing.md) for platform-specific commands, marketplace testing, the full validation checklist, and troubleshooting common issues.

---

## Distribution

Full distribution guide with CLI commands for every method: [references/distribution.md](./references/distribution.md).

**Distribution methods** (from most to least recommended):

| Method | Copilot CLI | Claude Code |
| --- | --- | --- |
| **Marketplace** (recommended) | `copilot plugin marketplace add OWNER/REPO` | `/plugin marketplace add OWNER/REPO` |
| **GitHub repo** (direct) | `copilot plugin install OWNER/REPO` | — |
| **Git URL** | `copilot plugin install https://...` | — |
| **Local path** | `copilot plugin install ./path` | `claude --plugin-dir ./path` |

**Claude Code extras:**
- **Team distribution**: Add marketplaces to `.claude/settings.json` via `extraKnownMarketplaces` + `enabledPlugins`
- **Official marketplace**: Submit at https://claude.ai/settings/plugins/submit

> Read [references/distribution.md](./references/distribution.md) for full CLI examples, team settings JSON, and submission links.

---

## Loading Order & Precedence

When multiple plugins provide components with the same name, the CLI resolves conflicts using these rules:

**Agents & Skills → first-found wins**
- Project-level components always take priority over plugin components
- Agents are deduplicated by ID (derived from filename, e.g., `reviewer.agent.md` → ID `reviewer`)
- Skills are deduplicated by `name` field in SKILL.md
- A plugin cannot override project-level or personal configurations

**MCP Servers → last-wins**
- If a plugin defines an MCP server with the same name as an existing one, the plugin's definition takes precedence
- Use `--additional-mcp-config` flag to override plugin MCP configs

**Built-in tools and agents** are always present and cannot be overridden.

For the full loading order diagram and file locations, see [references/cli-commands.md](./references/cli-commands.md).

---

## Automation Scripts

> **Source**: [`scripts/generate-plugin-json.ps1`](./scripts/generate-plugin-json.ps1)

Reads `marketplace.json` and generates manifests for **both platforms** from a single source of truth. Edit metadata in `marketplace.json`, then run the script to sync everything.

```powershell
# Preview what would be generated (no files written)
./scripts/generate-plugin-json.ps1 -DryRun

# Generate / overwrite all manifests for both platforms
./scripts/generate-plugin-json.ps1 -Force

# Generate only for one platform
./scripts/generate-plugin-json.ps1 -Force -Target Copilot
./scripts/generate-plugin-json.ps1 -Force -Target Claude
```

Run after adding or updating plugin entries in `marketplace.json`, or in CI to keep manifests in sync. The script generates `plugin.json` at plugin root (Copilot), `.claude-plugin/plugin.json` per plugin (Claude), and `.claude-plugin/marketplace.json` at repo root (Claude).

---

## Quick Reference

For file locations, loading order diagrams, and complete CLI command listings for both platforms, see [references/cli-commands.md](./references/cli-commands.md).
