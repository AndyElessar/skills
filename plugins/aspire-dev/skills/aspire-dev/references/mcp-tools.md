# Aspire MCP Tools Reference

This reference covers all available Aspire MCP tools. These tools allow you to interact with a running Aspire AppHost directly from the editor — inspecting resources, viewing logs, executing commands, and diagnosing issues without switching to the dashboard.

## Prerequisites

- An Aspire AppHost must be **running** (via `aspire run`) for most tools to work
- Exception: `mcp_aspire_list_integrations` and `mcp_aspire_get_integration_docs` work without a running AppHost

---

## AppHost Management

### `mcp_aspire_list_apphosts`

Lists all AppHost connections detected by the Aspire MCP server. Shows which ones are within the current workspace scope and which are outside.

**When to use:** When the workspace might contain multiple AppHost projects, or to verify whether an AppHost is detected.

```
mcp_aspire_list_apphosts()
```

### `mcp_aspire_select_apphost`

Selects which AppHost to target when multiple are running. The path can be fully qualified or relative to workspace root.

**When to use:** After `mcp_aspire_list_apphosts` shows multiple options and you need to pick one.

```
mcp_aspire_select_apphost(appHostPath="src/MyApp.AppHost")
mcp_aspire_select_apphost(appHostPath="C:/Projects/MyApp/src/MyApp.AppHost")
```

---

## Resource Inspection

### `mcp_aspire_list_resources`

Lists all application resources with comprehensive details: type, running state, source, HTTP endpoints, health status, available commands, environment variables, and relationships.

**When to use:** To get an overview of the application's current state — what's running, what's healthy, what endpoints are available.

```
mcp_aspire_list_resources()
```

**Returned information per resource:**
- `name` — Resource identifier (used in other MCP calls)
- `type` — .NET project, container, executable
- `state` — Running, Stopped, Starting, Failed, FinishedState, etc.
- `endpoints` — HTTP/HTTPS URLs
- `healthStatus` — Healthy, Degraded, Unhealthy
- `commands` — Available commands (e.g., resource-start, resource-stop, resource-restart)
- `environmentVariables` — Configured env vars (including service discovery entries)
- `relationships` — Dependencies on other resources

### `mcp_aspire_execute_resource_command`

Executes a command on a specific resource. Used to start, stop, or restart individual resources without restarting the entire AppHost.

**When to use:** To restart a specific service after code changes, stop a misbehaving resource, or start a manually-managed resource.

```
# Restart a resource
mcp_aspire_execute_resource_command(resourceName="apiservice", commandName="resource-restart")

# Stop a resource
mcp_aspire_execute_resource_command(resourceName="cache", commandName="resource-stop")

# Start a stopped resource (don't use "restart" for a currently-stopped resource)
mcp_aspire_execute_resource_command(resourceName="cache", commandName="resource-start")
```

**Built-in commands:**
| Command | Purpose |
|---------|---------|
| `resource-start` | Start a stopped resource |
| `resource-stop` | Gracefully stop a running resource |
| `resource-restart` | Restart a running resource |

Resources may also expose **custom commands**. Check `mcp_aspire_list_resources` to see what's available.

---

## Observability Tools

### `mcp_aspire_list_console_logs`

Returns console output (stdout/stderr) for a resource. Includes output from resource commands like start/stop/restart.

**When to use:** To diagnose startup failures, unhandled exceptions, or build errors. This is the raw process output.

**Important:** Don't print the full console logs in the response to the user — they can be very verbose. Read them, find the relevant parts, and summarize.

```
mcp_aspire_list_console_logs(resourceName="apiservice")
```

### `mcp_aspire_list_structured_logs`

Returns structured log entries with severity, category, message, and structured properties. These are the application-level logs emitted via `ILogger`.

**When to use:** To inspect application behavior, find warnings/errors, or understand what the application is doing at runtime.

```
# Logs for a specific resource
mcp_aspire_list_structured_logs(resourceName="apiservice")

# Logs for ALL resources (can be noisy)
mcp_aspire_list_structured_logs()
```

### `mcp_aspire_list_traces`

Lists distributed traces across the application. Each trace represents an operation (like an HTTP request) that may span multiple services. Shows trace ID, participating resources, duration, and error status.

**When to use:** To find slow operations, cross-service errors, or understand the call chain of a distributed operation.

```
# Traces for a specific resource
mcp_aspire_list_traces(resourceName="apiservice")

# All traces
mcp_aspire_list_traces()
```

### `mcp_aspire_list_trace_structured_logs`

Returns structured logs belonging to a specific distributed trace. Each log entry is associated with a span within the trace.

**When to use:** After finding a problematic trace in `mcp_aspire_list_traces`, drill into its logs to understand what happened at each step of the operation. **This should be your first step when investigating a trace** — before looking at broader resource logs.

```
mcp_aspire_list_trace_structured_logs(traceId="abc123def456")
```

---

## Integration Discovery

### `mcp_aspire_list_integrations`

Lists all available Aspire hosting integrations — NuGet packages that can be added to an AppHost project to integrate with databases, caches, message brokers, cloud services, etc.

**When to use:** When the user needs to add a new service and wants to know what's available out of the box.

**Does not require a running AppHost.**

```
mcp_aspire_list_integrations()
```

Use `aspire add <integration-name>` to install one.

### `mcp_aspire_get_integration_docs`

Fetches detailed documentation for a specific integration package, including API usage, configuration options, and examples.

**When to use:** Before configuring a new integration — this gives you the exact API for that version, far more reliable than guessing. Also useful when troubleshooting integration-specific issues.

**Does not require a running AppHost.**

```
mcp_aspire_get_integration_docs(packageId="Aspire.Hosting.Redis", packageVersion="9.0.0")
mcp_aspire_get_integration_docs(packageId="Aspire.Hosting.PostgreSQL", packageVersion="9.0.0")
```

**Tip:** If unsure of the package version, check the project's `*.csproj` files or use `mcp_aspire_list_integrations` to see what's available.

---

## Common Workflows with MCP Tools

### "What's the current state of my app?"

```
1. mcp_aspire_list_resources()          → Overview of all resources
2. Look for any with state != "Running" or health != "Healthy"
3. For unhealthy ones: mcp_aspire_list_console_logs(resourceName="...")
```

### "A request is failing across services"

```
1. mcp_aspire_list_traces(resourceName="webfrontend")   → Find the failing trace
2. mcp_aspire_list_trace_structured_logs(traceId="...")  → See what happened at each span
3. mcp_aspire_list_structured_logs(resourceName="...")   → Broader context if needed
```

### "I want to add PostgreSQL to my app"

```
1. mcp_aspire_get_integration_docs(packageId="Aspire.Hosting.PostgreSQL", packageVersion="9.0.0")
2. Run: aspire add postgres
3. Update Program.cs following the docs
4. aspire run
5. mcp_aspire_list_resources()  → Verify it's running
```

### "Restart just the API service after code changes"

```
mcp_aspire_execute_resource_command(resourceName="apiservice", commandName="resource-restart")
```
