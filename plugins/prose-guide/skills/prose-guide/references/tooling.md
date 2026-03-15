# Tooling: Scaling Agent Primitives

Agent Primitives are executable software written in natural language. Like any software, they need infrastructure: runtimes, package management, compilation, and deployment.

## Natural Language as Code

Your primitives exhibit all characteristics of professional software:

- **Modularity** — Separate concerns across files that work together
- **Reusability** — Same primitives work across projects and contexts
- **Dependencies** — MCP servers, tools, and context requirements to manage
- **Evolution** — Continuous refinement and versioning
- **Distribution** — Teams share proven primitives like code libraries

## Agent CLI Runtimes

VS Code + GitHub Copilot handles interactive development. For automated and production scenarios, Agent CLI Runtimes provide command-line execution.

**Implementations:** OpenAI Codex CLI, Anthropic Claude Code, GitHub Copilot CLI

### Inner Loop vs Outer Loop

| Environment | Use Case |
|-------------|----------|
| Inner Loop (VS Code + Copilot) | Interactive development, testing, workflow refinement |
| Outer Loop (Agent CLI Runtimes) | Reproducible execution, CI/CD, production deployment |

## APM — Agent Package Manager

[APM](https://github.com/danielmeppiel/apm) provides unified runtime management and package distribution — npm for natural language programs.

```bash
# Install APM
curl -sSL https://raw.githubusercontent.com/danielmeppiel/apm/main/install.sh | sh

# Runtime management
apm runtime setup copilot        # Install GitHub Copilot CLI
apm runtime setup codex          # Install OpenAI Codex CLI
apm runtime list                 # Show installed runtimes

# Package management
apm install                      # Install MCP dependencies
apm compile                      # Compile instructions → AGENTS.md
apm run <script> --param key=val # Execute workflow
```

### apm.yml Configuration

```yaml
name: security-review-workflow
version: 1.2.0
description: Comprehensive security review with GitHub integration
scripts:
  copilot-sec-review: "copilot --allow-all-tools -p security-review.prompt.md"
  codex-sec-review: "codex security-review.prompt.md"

dependencies:
  apm:
    - company/compliance-rules
    - company/design-guidelines
  mcp:
    - github/github-mcp-server
```

## Context Compilation

Transforms modular `.instructions.md` into portable, optimized `AGENTS.md` hierarchies.

**Why compile:**
- **Portability** — Works across all coding agents supporting AGENTS.md
- **Efficiency** — Optimal context per file vs manual approaches
- **Coverage** — Every file gets needed instructions
- **Maintenance** — Edit primitives, recompile, AGENTS.md updates

```bash
# Author modular primitives
.apm/instructions/
├── security.instructions.md      # applyTo: "**/auth/**"
├── react.instructions.md         # applyTo: "**/*.{tsx,jsx}"
└── api-design.instructions.md    # applyTo: "backend/api/**"

# Compile
apm compile

# Optimal hierarchy generated
├── AGENTS.md                     # Global context
├── frontend/AGENTS.md           # React patterns
└── backend/
    ├── AGENTS.md                # Backend patterns
    └── auth/AGENTS.md           # Security + backend (merged)
```

Multiple APM packages can target the same `applyTo` patterns — compilation merges contexts with source attribution. No conflicts, complete coverage.

## Distribution & Packaging

```bash
# Create package
apm init security-review-workflow

# Develop and test locally
apm compile && apm install
apm run copilot-sec-review --param pr_id=123

# Publish
git tag v1.0.0 && git push --tags

# Team member installs
apm install company/security-review-workflow
```

**Enterprise governance pattern:** When compliance team updates `company/compliance-rules`, every team runs `apm install && apm compile` — every agent, every project, instantly compliant.

## Production Deployment (CI/CD)

Deploy Agent Primitives as first-class CI/CD citizens:

```yaml
# .github/workflows/security-review.yml
name: AI Security Review Pipeline
on:
  pull_request:
    types: [opened, synchronize]

jobs:
  security-analysis:
    runs-on: ubuntu-latest
    permissions:
      models: read
      pull-requests: write
      contents: read
    steps:
    - uses: actions/checkout@v4
    - name: Run Security Review
      uses: danielmeppiel/action-apm-cli@v1
      with:
        script: copilot-sec-review
        parameters: '{"pr_id": "${{ github.event.number }}"}'
      env:
        GITHUB_COPILOT_PAT: ${{ secrets.GITHUB_COPILOT_PAT }}
```

## Ecosystem Evolution

The progression mirrors every programming ecosystem:

1. **Raw Code** → Agent Primitives (`.prompt.md`, `.instructions.md`)
2. **Runtime Environments** → Agent CLI Runtimes (Codex, Claude Code, Copilot CLI)
3. **Package Management** → APM (distribution and orchestration)
4. **Thriving Ecosystem** → Shared libraries, community packages
