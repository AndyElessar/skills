---
name: aspire-dev
description: "Orchestrates Aspire distributed applications using the Aspire CLI and MCP tools. USE FOR: aspire start/stop, aspire describe, aspire doctor, view logs/traces, add integrations, debug resources, AppHost management. Also trigger for DistributedApplication.CreateBuilder, AddProject, AddContainer, or Aspire resource references. DO NOT USE FOR: non-Aspire .NET apps (dotnet CLI), container-only deployments (docker/podman), Azure deployment (azure-deploy skill). INVOKES: Aspire CLI (aspire start, aspire describe, aspire otel), Aspire MCP tools (mcp_aspire_doctor, mcp_aspire_list_resources, mcp_aspire_list_traces)."
---

# Aspire Skill

Orchestrate, monitor, and debug .NET Aspire distributed applications using the Aspire CLI and Aspire MCP tools.

Resources are defined in the AppHost project (`Program.cs` or `AppHost.cs`). The CLI manages the app lifecycle; the MCP tools provide real-time inspection from within the editor.

> **Aspire evolves rapidly.** When unsure about an API or behavior, use `mcp_aspire_search_docs` or `aspire docs search` to check before guessing.

## Quick reference — CLI commands

| Task | Command |
|---|---|
| Start the app (background) | `aspire start` |
| Start isolated (worktrees) | `aspire start --isolated` |
| Run the app (foreground) | `aspire run` |
| Restart the app | `aspire start` (stops previous automatically) |
| Wait for resource healthy | `aspire wait <resource>` |
| Stop the app | `aspire stop` |
| List resources | `aspire describe [resource]` |
| Run resource command | `aspire resource <resource> <command>` |
| View console logs | `aspire logs [resource]` |
| View structured logs | `aspire otel logs [resource]` |
| View spans | `aspire otel spans [resource]` |
| View traces | `aspire otel traces [resource]` |
| Logs for a trace | `aspire otel logs --trace-id <id>` |
| Add an integration | `aspire add` |
| Create new project | `aspire new` |
| Init Aspire in existing solution | `aspire init` |
| List running AppHosts | `aspire ps` |
| Update AppHost packages | `aspire update` |
| Export telemetry to zip | `aspire export [resource]` |
| Search docs | `aspire docs search <query>` |
| Get doc page | `aspire docs get <slug>` |
| List doc pages | `aspire docs list` |
| Environment diagnostics | `aspire doctor` |

Most commands support `--format Json` for machine-readable output. Use `--apphost <path>` to target a specific AppHost.

Full CLI reference → load [references/cli-reference.md](./references/cli-reference.md)

## Quick reference — MCP tools

| Task | MCP Tool |
|---|---|
| Environment diagnostics | `mcp_aspire_doctor` |
| List detected AppHosts | `mcp_aspire_list_apphosts` |
| Select an AppHost | `mcp_aspire_select_apphost(appHostPath=...)` |
| List resources & status | `mcp_aspire_list_resources` |
| Execute resource command | `mcp_aspire_execute_resource_command(resourceName, commandName)` |
| Console logs (stdout/stderr) | `mcp_aspire_list_console_logs(resourceName)` |
| Structured logs | `mcp_aspire_list_structured_logs(resourceName?)` |
| Distributed traces | `mcp_aspire_list_traces(resourceName?)` |
| Logs for a specific trace | `mcp_aspire_list_trace_structured_logs(traceId)` |
| List available integrations | `mcp_aspire_list_integrations` |
| Search aspire.dev docs | `mcp_aspire_search_docs(query, topK?)` |
| Get full doc page | `mcp_aspire_get_doc(slug, section?)` |
| List all doc pages | `mcp_aspire_list_docs` |
| Refresh tool list | `mcp_aspire_refresh_tools` |

Tools that do **not** require a running AppHost: `mcp_aspire_doctor`, `mcp_aspire_list_integrations`, `mcp_aspire_search_docs`, `mcp_aspire_get_doc`, `mcp_aspire_list_docs`.

Full MCP reference → load [references/mcp-tools.md](./references/mcp-tools.md)

## Key workflows

### Pre-flight check

Before starting the app for the first time, verify the environment:

```
mcp_aspire_doctor
```

This runs comprehensive checks (SDK version, container runtime, CLI version, etc.) and returns pass/warning/fail with actionable fix suggestions. **Does not require a running AppHost.**

If `mcp_aspire_doctor` is unavailable, use the CLI equivalent:

```bash
aspire doctor
```

### Running in agent environments

Use `aspire start` to run the AppHost in the background. When working in a git worktree, use `--isolated` to avoid port conflicts:

```bash
aspire start --isolated
```

Use `aspire wait <resource>` to block until a resource is healthy before interacting with it:

```bash
aspire start --isolated
aspire wait myapi
```

Relaunching is safe — `aspire start` automatically stops any previous instance. Re-run `aspire start` whenever changes are made to the AppHost project.

### Monitoring resources

Once running, use MCP **or** CLI interchangeably:

| Intent | MCP tool | CLI equivalent |
|---|---|---|
| Resource status overview | `mcp_aspire_list_resources` | `aspire describe` |
| Restart a resource | `mcp_aspire_execute_resource_command(resourceName, "resource-restart")` | `aspire resource <name> restart` |
| Stop a resource | `mcp_aspire_execute_resource_command(resourceName, "resource-stop")` | `aspire resource <name> stop` |
| Start a stopped resource | `mcp_aspire_execute_resource_command(resourceName, "resource-start")` | `aspire resource <name> start` |

### Debugging issues

Before making code changes, inspect the app state:

1. **Check resource status** — `mcp_aspire_list_resources` or `aspire describe`
2. **View structured logs** — `mcp_aspire_list_structured_logs(resourceName=...)` or `aspire otel logs <resource>`
3. **View distributed traces** — `mcp_aspire_list_traces(resourceName=...)` or `aspire otel traces <resource>`
4. **Drill into trace logs** — `mcp_aspire_list_trace_structured_logs(traceId=...)` or `aspire otel logs --trace-id <id>`
5. **Fall back to console logs** — `mcp_aspire_list_console_logs(resourceName=...)` or `aspire logs <resource>`

This top-down approach (status → structured logs → traces → trace logs → console logs) finds root causes efficiently.

> **Console logs can be extremely verbose.** Never dump full console logs to the user. Read them, find the relevant parts, and summarize.

### Adding integrations

1. Search for the integration: `mcp_aspire_search_docs(query="redis integration")` or `aspire docs search redis`
2. Read the docs: `mcp_aspire_get_doc(slug="redis-integration")` or `aspire docs get redis-integration`
3. Add the package: `aspire add redis`
4. Restart the app: `aspire start` (automatically stops previous instance)

For a catalog of available integrations: `mcp_aspire_list_integrations` or see [references/integrations.md](./references/integrations.md).

### Multiple AppHosts

If the workspace contains multiple AppHost projects:

```
mcp_aspire_list_apphosts                                    # See all detected AppHosts
mcp_aspire_select_apphost(appHostPath="src/MyApp.AppHost")  # Select one
```

Or via CLI: `aspire ps` to list, `--apphost <path>` flag on any command to target a specific one.

## Important rules

- **Always verify the starting state** before making changes — run `mcp_aspire_doctor` for environment checks, then `aspire start` and `mcp_aspire_list_resources` to confirm baseline health.
- **To restart, just run `aspire start` again** — it automatically stops the previous instance. NEVER chain `aspire stop` then `aspire start`.
- **`aspire start` vs `aspire run`**: `aspire start` runs in background (preferred for agents); `aspire run` runs in foreground (long-running, must be a background terminal process).
- Use `--isolated` when working in a worktree.
- **Avoid persistent containers** early in development to prevent state management issues.
- **Never install the Aspire workload** — it is obsolete. Use the Aspire CLI (`dotnet tool install -g aspire`).
- Prefer `aspire.dev` and `learn.microsoft.com/dotnet/aspire` for official documentation.
- **Never print full console logs** to the user — summarize the relevant parts.

## Reference files

Load these on demand for deeper detail:

| File | When to load |
|---|---|
| [references/cli-reference.md](./references/cli-reference.md) | Full CLI command reference with examples |
| [references/mcp-tools.md](./references/mcp-tools.md) | Detailed MCP tool usage and workflows |
| [references/architecture.md](./references/architecture.md) | AppHost, service discovery, service defaults, lifecycle |
| [references/integrations.md](./references/integrations.md) | Common integration patterns and configuration |
| [references/docs-index.md](./references/docs-index.md) | Documentation links and when to fetch docs |
