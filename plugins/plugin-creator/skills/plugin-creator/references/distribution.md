# Distribution

How to distribute plugins and marketplaces to users across both platforms.

## Via Marketplace (Recommended)

1. Push your marketplace repository to GitHub
2. Share the install command with users:

   **Copilot CLI:**
   ```bash
   copilot plugin marketplace add OWNER/REPO
   ```

   **Claude Code:**
   ```bash
   /plugin marketplace add OWNER/REPO
   ```

3. Users can then browse and install individual plugins:
   ```bash
   # Copilot CLI
   copilot plugin marketplace browse marketplace-name
   copilot plugin install plugin-name@marketplace-name

   # Claude Code
   /plugin install plugin-name@marketplace-name
   ```

---

## Via GitHub Repository (Direct)

Users can install directly from a repo:
```bash
# Copilot CLI — from repo root
copilot plugin install OWNER/REPO

# Copilot CLI — from a subdirectory
copilot plugin install OWNER/REPO:path/to/plugin
```

---

## Via Git URL

```bash
copilot plugin install https://github.com/OWNER/REPO.git
```

---

## Via Local Path

```bash
# Copilot CLI
copilot plugin install ./my-plugin

# Claude Code
claude --plugin-dir ./my-plugin
```

---

## Claude Code: Team Distribution via Settings

Require marketplaces for your team by adding to `.claude/settings.json`:

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
    "code-formatter@company-tools": true
  }
}
```

---

## Claude Code: Submit to Official Marketplace

- **claude.ai**: https://claude.ai/settings/plugins/submit
- **Console**: https://platform.claude.com/plugins/submit
