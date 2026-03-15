---
name: plugin-creator
description: "Guide AI agents through creating GitHub Copilot CLI plugins and plugin marketplaces — from scaffolding plugin directories and writing plugin.json manifests to building marketplace.json registries and testing installations. Use this skill whenever the user wants to create, scaffold, configure, package, or publish a Copilot CLI plugin, write or edit a plugin.json or marketplace.json file, set up a plugin marketplace repository, or troubleshoot plugin installation and loading issues. Also trigger when the user mentions 'copilot plugin', plugin manifests, plugin registries, plugin distribution, or asks how to package agents/skills/hooks/MCP servers into an installable plugin — even if they don't explicitly say 'plugin.json'. Do NOT use this skill for authoring the contents of plugin components (agents, skills, hooks, MCP configs) — delegate those to the appropriate specialized skills."
---

# Copilot CLI Plugin Creator

## Purpose

Help developers create, configure, and distribute GitHub Copilot CLI plugins and plugin marketplaces. This skill covers the structural scaffolding, manifest configuration, and testing workflow — not the authoring of individual components (agents, skills, hooks, MCP servers) that live inside plugins.

> **Docs evolve.** The official reference is at https://docs.github.com/en/copilot/reference/copilot-cli-reference/cli-plugin-reference. When in doubt, check the latest docs.

## Decision Flow

| User Intent | Go To |
|---|---|
| "Create a new plugin" | → [Creating a Plugin](#creating-a-plugin) |
| "Set up plugin.json" | → [references/plugin-json.md](./references/plugin-json.md) |
| "Create a marketplace" | → [Creating a Marketplace](#creating-a-marketplace) |
| "Set up marketplace.json" | → [references/marketplace-json.md](./references/marketplace-json.md) |
| "Test / install my plugin" | → [Testing & Validation](#testing--validation) |
| "Distribute my plugin" | → [Distribution](#distribution) |
| CLI commands reference | → [references/cli-commands.md](./references/cli-commands.md) |
| Plugin loading order | → [Loading Order & Precedence](#loading-order--precedence) |
| "Sync plugin.json from marketplace" | → [Automation Scripts](#automation-scripts) |

---

## Creating a Plugin

A plugin is a directory containing, at minimum, a `plugin.json` manifest. Components are optional.

### Step 1: Scaffold the directory

```
my-plugin/
├── plugin.json           # Required — plugin manifest
├── agents/               # Custom agents (optional)
│   └── helper.agent.md
├── skills/               # Skills (optional)
│   └── deploy/
│       └── SKILL.md
├── hooks.json            # Hook configuration (optional)
└── .mcp.json             # MCP server config (optional)
```

Create the plugin directory first, then add `plugin.json` at the root. Component directories are only needed when the plugin provides those components.

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
  "mcpServers": ".mcp.json"
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
- **Hooks**: Create a `hooks.json` or `hooks/hooks.json` file
- **MCP servers**: Create `.mcp.json`, `.vscode/mcp.json`, or `.github/mcp.json`
- **LSP servers**: Create `lsp.json` or `.github/lsp.json`

The contents of these components are outside the scope of this skill. Use specialized skills (e.g., `agents-creator` for agent files) for authoring component contents.

### Step 4: Test the plugin

See [Testing & Validation](#testing--validation) below.

---

## Creating a Marketplace

A marketplace is a registry of plugins stored in a repository. The `marketplace.json` file is the **primary source of truth** for plugin metadata — it's what users see when browsing and what the CLI reads for installation. Individual `plugin.json` files inside each plugin serve as fallback.

### Marketplace structure

```
my-marketplace/
├── .github/
│   └── plugin/
│       └── marketplace.json    # Required — marketplace manifest
└── plugins/
    ├── frontend-design/
    │   ├── plugin.json
    │   ├── agents/
    │   └── skills/
    └── security-checks/
        ├── plugin.json
        └── skills/
```

> **Alternative location**: Copilot CLI also looks for `marketplace.json` in the `.claude-plugin/` directory.

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

When publishing plugins through a marketplace, define complete metadata in the `plugins` array entries of `marketplace.json`. This is what users see when browsing (`copilot plugin marketplace browse`). Each plugin entry can include all metadata fields (`description`, `version`, `author`, `keywords`, `category`, `tags`, etc.) plus component path overrides — the same fields available in `plugin.json`.

Each plugin still needs its own `plugin.json` with at least a `name` field, but the marketplace entry takes priority for discoverability. Think of it this way:

- **`marketplace.json` plugin entries** → Curator's view. Controls what users see and how plugins are presented.
- **`plugin.json`** → Plugin's self-description. Fallback when installed directly (not via marketplace).

### Step 2: Add plugin directories

For each plugin listed in `marketplace.json`, create the plugin directory at the `source` path specified. Each plugin directory must contain its own `plugin.json`.

The `source` field is relative to the repository root. Both `"./plugins/plugin-name"` and `"plugins/plugin-name"` resolve to the same directory.

### Step 3: Place marketplace.json

Save `marketplace.json` to `.github/plugin/marketplace.json` (or `.claude-plugin/marketplace.json`).

### Step 4: Test the marketplace

See [Testing & Validation](#testing--validation) below.

---

## Testing & Validation

Testing is essential — always verify plugins work before distributing them. Follow this sequence:

### Test a standalone plugin

```bash
# 1. Install locally
copilot plugin install ./my-plugin

# 2. Verify it appears in the plugin list
copilot plugin list

# 3. Start an interactive session and verify components loaded
#    Check agents:
/agent

#    Check skills:
/skills list

# 4. Exercise the plugin's functionality
#    Try using the agents/skills/hooks the plugin provides

# 5. After making changes, reinstall to pick up updates
#    (The CLI caches plugin components — reinstall to refresh)
copilot plugin install ./my-plugin

# 6. Clean up when done testing
copilot plugin uninstall my-plugin
```

> **Important**: Use the plugin `name` (from `plugin.json`) for uninstall, not the directory path.

### Test a marketplace

```bash
# 1. Add the marketplace (local path or GitHub repo)
copilot plugin marketplace add /path/to/my-marketplace
# or: copilot plugin marketplace add OWNER/REPO

# 2. Verify it's registered
copilot plugin marketplace list

# 3. Browse available plugins
copilot plugin marketplace browse my-marketplace

# 4. Install a plugin from the marketplace
copilot plugin install my-plugin@my-marketplace

# 5. Verify the plugin loaded
copilot plugin list

# 6. Test functionality in an interactive session
#    /agent
#    /skills list

# 7. Clean up
copilot plugin uninstall my-plugin
copilot plugin marketplace remove my-marketplace
```

### Validation checklist

Before distribution, verify:

- [ ] `plugin.json` has a valid `name` (kebab-case, ≤64 chars)
- [ ] All `source` paths in `marketplace.json` resolve correctly
- [ ] Each referenced plugin directory contains a `plugin.json`
- [ ] Component paths in manifests point to existing files/directories
- [ ] `copilot plugin list` shows the plugin after installation
- [ ] Agents appear in `/agent` listing
- [ ] Skills appear in `/skills list`
- [ ] MCP servers connect successfully (if any)
- [ ] No name collisions with existing plugins or built-in components

### Troubleshooting common issues

| Symptom | Likely Cause | Fix |
|---|---|---|
| Plugin not listed after install | Invalid `plugin.json` or wrong path | Check manifest syntax and install path |
| Agent/skill not loading | Name collision with project-level component | Rename — project-level wins (first-found precedence) |
| MCP server overriding existing one | MCP uses last-wins precedence | Check server name conflicts |
| Changes not picked up | CLI caches components | Reinstall: `copilot plugin install ./my-plugin` |
| Marketplace browse shows nothing | `marketplace.json` not in correct directory | Must be in `.github/plugin/` or `.claude-plugin/` |

---

## Distribution

### Via marketplace (recommended)

1. Push your marketplace repository to GitHub
2. Share the install command with users:
   ```bash
   copilot plugin marketplace add OWNER/REPO
   ```
3. Users can then browse and install individual plugins:
   ```bash
   copilot plugin marketplace browse marketplace-name
   copilot plugin install plugin-name@marketplace-name
   ```

### Via GitHub repository (direct)

Users can install directly from a repo:
```bash
# From repo root
copilot plugin install OWNER/REPO

# From a subdirectory
copilot plugin install OWNER/REPO:path/to/plugin
```

### Via Git URL

```bash
copilot plugin install https://github.com/OWNER/REPO.git
```

### Via local path

```bash
copilot plugin install ./my-plugin
copilot plugin install /absolute/path/to/plugin
```

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

Reusable scripts for marketplace maintenance. Located in [`scripts/`](./scripts/).

### generate-plugin-json.ps1

> **Source**: [`scripts/generate-plugin-json.ps1`](./scripts/generate-plugin-json.ps1)

Reads `marketplace.json` and generates a `plugin.json` manifest in each plugin's `source` directory. Keeps `marketplace.json` as the single source of truth — edit metadata there, then run the script to sync.

**What it maps:**
- Metadata fields: `name`, `description`, `version`, `author`, `keywords`, `category`, `tags`, `homepage`, `repository`, `license`
- Component paths: `agents`, `skills`, `commands`, `hooks`, `mcpServers`, `lspServers`
- Falls back to marketplace `owner` for `author` when a plugin entry doesn't define one

**Usage:**

```powershell
# Preview what would be generated (no files written)
.\eng\generate-plugin-json.ps1 -DryRun

# Generate / overwrite all plugin.json files
.\eng\generate-plugin-json.ps1 -Force

# Use a custom marketplace path
.\eng\generate-plugin-json.ps1 -MarketplacePath .\custom\marketplace.json
```

**When to run:**
- After adding a new plugin entry to `marketplace.json`
- After updating metadata (description, version, keywords, etc.) in `marketplace.json`
- As part of CI to ensure `plugin.json` files are never out of sync

---

## File Locations Summary

| What | Where |
|---|---|
| Plugin manifest | `plugin.json`, `.github/plugin/plugin.json`, or `.claude-plugin/plugin.json` |
| Marketplace manifest | `.github/plugin/marketplace.json` or `.claude-plugin/marketplace.json` |
| Installed plugins (marketplace) | `~/.copilot/state/installed-plugins/MARKETPLACE/PLUGIN-NAME` |
| Installed plugins (direct) | `~/.copilot/state/installed-plugins/PLUGIN-NAME` |
| Marketplace cache | `~/.copilot/state/marketplace-cache/` |
| Automation scripts | `.github/skills/plugin-creator/scripts/` |
