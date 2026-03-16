# Testing & Validation

Testing is essential — always verify plugins work before distributing them. Follow this sequence:

## Test a Standalone Plugin

### Copilot CLI

```bash
# 1. Install locally
copilot plugin install ./my-plugin

# 2. Verify it appears in the plugin list
copilot plugin list

# 3. Start an interactive session and verify components loaded
/agent
/skills list

# 4. After making changes, reinstall to pick up updates
copilot plugin install ./my-plugin

# 5. Clean up when done testing
copilot plugin uninstall my-plugin
```

### Claude Code

```bash
# 1. Load locally (during development)
claude --plugin-dir ./my-plugin

# 2. Test skills (namespaced by plugin name)
/my-plugin:skill-name

# 3. Check agents
/agents

# 4. After making changes, reload without restarting
/reload-plugins

# 5. Load multiple plugins
claude --plugin-dir ./plugin-one --plugin-dir ./plugin-two
```

> **Copilot CLI**: Use the plugin `name` (from `plugin.json`) for uninstall, not the directory path.
> **Claude Code**: Local `--plugin-dir` plugins take precedence over installed marketplace plugins.

---

## Test a Marketplace

### Copilot CLI

```bash
# 1. Add the marketplace
copilot plugin marketplace add /path/to/my-marketplace
# or: copilot plugin marketplace add OWNER/REPO

# 2. Browse available plugins
copilot plugin marketplace browse my-marketplace

# 3. Install a plugin from the marketplace
copilot plugin install my-plugin@my-marketplace

# 4. Clean up
copilot plugin uninstall my-plugin
copilot plugin marketplace remove my-marketplace
```

### Claude Code

```bash
# 1. Add the marketplace
/plugin marketplace add ./my-marketplace
# or: /plugin marketplace add OWNER/REPO

# 2. Install a plugin
/plugin install my-plugin@my-marketplace

# 3. Validate marketplace structure
claude plugin validate .
# or in-session: /plugin validate .

# 4. Clean up
/plugin uninstall my-plugin
/plugin marketplace remove my-marketplace
```

---

## Validation Checklist

Before distribution, verify:

- [ ] `plugin.json` has a valid `name` (kebab-case, ≤64 chars)
- [ ] All `source` paths in `marketplace.json` resolve correctly
- [ ] Each referenced plugin directory contains a `plugin.json` (at root for Copilot CLI, in `.claude-plugin/` for Claude Code)
- [ ] Component paths in manifests point to existing files/directories
- [ ] Plugin appears in listing after installation
- [ ] Agents appear in `/agent` or `/agents` listing
- [ ] Skills are accessible (`/skills list` or `/plugin-name:skill-name`)
- [ ] MCP servers connect successfully (if any)
- [ ] No name collisions with existing plugins or built-in components
- [ ] `claude plugin validate .` passes without errors (Claude Code)

---

## Troubleshooting Common Issues

| Symptom | Likely Cause | Fix |
|---|---|---|
| Plugin not listed after install | Invalid `plugin.json` or wrong path | Check manifest syntax and install path |
| Agent/skill not loading | Name collision with project-level component | Rename — project-level wins (first-found precedence) |
| MCP server overriding existing one | MCP uses last-wins precedence | Check server name conflicts |
| Changes not picked up | CLI caches components | Copilot: reinstall plugin. Claude Code: `/reload-plugins` |
| Marketplace browse shows nothing | `marketplace.json` not in correct directory | Copilot: `.github/plugin/`. Claude Code: `.claude-plugin/` |
| Components inside `.claude-plugin/` | Wrong structure (Claude Code) | Move `commands/`, `agents/`, `skills/`, `hooks/` to plugin root |
| `strict: false` conflict | Plugin has `plugin.json` with components AND marketplace entry defines components | Remove component declarations from one side |
| Claude Code validation error | JSON syntax or schema issues | Run `claude plugin validate .` and fix reported errors |
