# Aspire MCP Tools Reference

Aspire MCP tools allow you to interact with a running Aspire AppHost directly from the editor — inspecting resources, viewing logs, executing commands, and diagnosing issues without switching to the dashboard or terminal.

## Tool Availability

| Requires running AppHost | Does NOT require running AppHost |
| --- | --- |
| `mcp_aspire_list_resources` | `mcp_aspire_doctor` |
| `mcp_aspire_execute_resource_command` | `mcp_aspire_list_integrations` |
| `mcp_aspire_list_console_logs` | `mcp_aspire_search_docs` |
| `mcp_aspire_list_structured_logs` | `mcp_aspire_get_doc` |
| `mcp_aspire_list_traces` | `mcp_aspire_list_docs` |
| `mcp_aspire_list_trace_structured_logs` | `mcp_aspire_list_apphosts` |
| `mcp_aspire_select_apphost` | `mcp_aspire_refresh_tools` |

---

## Environment Diagnostics

### `mcp_aspire_doctor`

Diagnose Aspire environment issues. Performs comprehensive checks (SDK version, container runtime, CLI installation, etc.) and returns detailed status (pass/warning/fail) with actionable fix suggestions.

**Use first** — before starting any AppHost, run this to verify the environment is ready.

```
mcp_aspire_doctor()
```

CLI equivalent: `aspire doctor`

---

## AppHost Management

### `mcp_aspire_list_apphosts`

Lists all AppHost connections detected by the Aspire MCP server. Shows which are within the current workspace scope and which are outside.

```
mcp_aspire_list_apphosts()
```

### `mcp_aspire_select_apphost`

Selects which AppHost to target when multiple are detected. Path can be fully qualified or relative to workspace root.

```
mcp_aspire_select_apphost(appHostPath="src/MyApp.AppHost")
```

---

## Resource Inspection

### `mcp_aspire_list_resources`

Lists all application resources with comprehensive details.

```
mcp_aspire_list_resources()
```

Returned information per resource:

- **name** — Resource identifier (used in other MCP calls)
- **type** — .NET project, container, executable
- **state** — Running, Stopped, Starting, Failed, FinishedState, etc.
- **endpoints** — HTTP/HTTPS URLs
- **healthStatus** — Healthy, Degraded, Unhealthy
- **commands** — Available commands (e.g., resource-start, resource-stop, resource-restart)
- **environmentVariables** — Configured env vars (including service discovery entries)
- **relationships** — Dependencies on other resources

CLI equivalent: `aspire describe`

### `mcp_aspire_execute_resource_command`

Executes a command on a specific resource. If a resource is currently stopped, use `resource-start` instead of `resource-restart`.

```
mcp_aspire_execute_resource_command(resourceName="apiservice", commandName="resource-restart")
mcp_aspire_execute_resource_command(resourceName="cache", commandName="resource-stop")
mcp_aspire_execute_resource_command(resourceName="cache", commandName="resource-start")
```

Built-in commands:

| Command | Purpose |
| --- | --- |
| `resource-start` | Start a stopped resource |
| `resource-stop` | Gracefully stop a running resource |
| `resource-restart` | Restart a running resource |

Resources may also expose **custom commands** — check `mcp_aspire_list_resources` to see available commands per resource.

CLI equivalent: `aspire resource <resource> start|stop|restart`

---

## Observability Tools

### `mcp_aspire_list_console_logs`

Returns console output (stdout/stderr) for a resource. Includes output from resource commands.

**Important:** Console logs can be very verbose. Read them to find relevant parts, then **summarize** for the user — never dump the full output.

```
mcp_aspire_list_console_logs(resourceName="apiservice")
```

- `resourceName` — **Required.** The resource to get logs for.

CLI equivalent: `aspire logs <resource>`

### `mcp_aspire_list_structured_logs`

Returns structured log entries with severity, category, message, and structured properties (from `ILogger`).

```
mcp_aspire_list_structured_logs(resourceName="apiservice")   # Specific resource
mcp_aspire_list_structured_logs()                             # All resources (can be noisy)
```

- `resourceName` — Optional. Omit to get logs for all resources.

CLI equivalent: `aspire otel logs [resource]`

### `mcp_aspire_list_traces`

Lists distributed traces across the application. Each trace represents an operation that may span multiple services, showing trace ID, participating resources, duration, and error status.

```
mcp_aspire_list_traces(resourceName="apiservice")    # Specific resource
mcp_aspire_list_traces()                              # All resources
```

- `resourceName` — Optional. Omit to get traces for all resources.

CLI equivalent: `aspire otel traces [resource]`

### `mcp_aspire_list_trace_structured_logs`

Returns structured logs belonging to a specific distributed trace. Each log entry is associated with a span within the trace.

**This should be your first step when investigating a trace** — before looking at broader resource logs.

```
mcp_aspire_list_trace_structured_logs(traceId="abc123def456")
```

- `traceId` — **Required.** The trace ID from `mcp_aspire_list_traces`.

CLI equivalent: `aspire otel logs --trace-id <id>`

---

## Documentation Tools

### `mcp_aspire_search_docs`

Searches aspire.dev documentation using keyword-based lexical search. Returns ranked results with titles, slugs, and excerpts.

```
mcp_aspire_search_docs(query="redis integration", topK=5)
```

- `query` — **Required.** Use specific terms (API names, feature names) for best results.
- `topK` — Optional. Number of results (default: 5, max: 10).

### `mcp_aspire_get_doc`

Retrieves full content of a specific documentation page by slug. Optionally filter to a specific section.

```
mcp_aspire_get_doc(slug="redis-integration")
mcp_aspire_get_doc(slug="service-discovery", section="Configuration")
```

- `slug` — **Required.** Use `mcp_aspire_list_docs` or `mcp_aspire_search_docs` to find slugs.
- `section` — Optional. Heading of a specific section to return.

### `mcp_aspire_list_docs`

Lists all available documentation pages with titles, slugs, and brief summaries.

```
mcp_aspire_list_docs()
```

---

## Integration Discovery

### `mcp_aspire_list_integrations`

Lists all available Aspire hosting integrations — NuGet packages for databases, caches, message brokers, cloud services, etc.

```
mcp_aspire_list_integrations()
```

Use `aspire add <integration-name>` to install one.

---

## Utility

### `mcp_aspire_refresh_tools`

Requests the MCP server to emit a tools list changed notification so clients re-fetch available tools. Use after adding new resources that expose MCP tools.

```text
mcp_aspire_refresh_tools()
```

---

## Common MCP Workflows

### Pre-flight: Is the environment ready?

```
mcp_aspire_doctor()    → Check for pass/warning/fail on all prerequisites
```

### What's the current state of my app?

```
1. mcp_aspire_list_resources()                                → Overview of all resources
2. Look for any with state ≠ "Running" or health ≠ "Healthy"
3. For unhealthy: mcp_aspire_list_console_logs(resourceName="...")
```

### A request is failing across services

```
1. mcp_aspire_list_traces(resourceName="webfrontend")            → Find the failing trace
2. mcp_aspire_list_trace_structured_logs(traceId="...")          → See what happened at each span
3. mcp_aspire_list_structured_logs(resourceName="...")           → Broader context if needed
```

### I want to add PostgreSQL to my app

```
1. mcp_aspire_search_docs(query="PostgreSQL integration")       → Find the right doc slug
2. mcp_aspire_get_doc(slug="postgresql-integration")             → Read full setup guide
3. Run: aspire add postgres
4. Update Program.cs following the docs
5. aspire start                                                   → Restart
6. mcp_aspire_list_resources()                                    → Verify it's running
```

### "Restart just the API service after code changes"

```
mcp_aspire_execute_resource_command(resourceName="apiservice", commandName="resource-restart")
```
