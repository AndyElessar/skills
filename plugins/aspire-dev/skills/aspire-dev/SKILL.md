---
name: aspire-dev
description: "Guide AI agents through .NET Aspire development — from project creation and AppHost configuration to running, debugging, and monitoring distributed applications. Use this skill whenever the user works with .NET Aspire projects, mentions AppHost, Aspire resources, Aspire integrations, `aspire run`, `aspire add`, distributed app orchestration in .NET, or asks about service discovery, telemetry, health checks, or container orchestration in .NET. Also trigger when the user references Aspire dashboard, resource logs, structured logs, distributed traces, or wants to start/stop/restart Aspire resources. Even if the user doesn't say 'Aspire' explicitly, use this skill when they are clearly working in an Aspire AppHost project (e.g., referencing `Program.cs` with `DistributedApplication.CreateBuilder`, `AddProject`, `AddContainer`, or similar Aspire APIs)."
---

# .NET Aspire Development Skill

## Purpose

Help developers build, run, monitor, and debug .NET Aspire distributed applications using the Aspire CLI and Aspire MCP tools. Aspire is an opinionated stack for building observable, production-ready, cloud-native apps with .NET.

> **Aspire evolves rapidly.** Always prefer fetching the latest documentation via the links in [references/docs-index.md](./references/docs-index.md) before giving advice. If unsure about an API or behavior, check the docs first rather than guessing.

## Decision Flow

| User Intent | Go To |
|---|---|
| "Create a new Aspire project" | → [Project Setup](#project-setup) |
| "Add a database/cache/service" | → [Adding Integrations](#adding-integrations) |
| "Run my Aspire app" | → [Running the AppHost](#running-the-apphost) |
| "Check resource status / health" | → [Monitoring Resources](#monitoring-resources) |
| "View logs or traces" | → [Observability & Debugging](#observability--debugging) |
| "Debug a failing resource" | → [Troubleshooting](#troubleshooting) |
| "Understand service discovery" | → [references/architecture.md](./references/architecture.md) |
| "Configure integrations" | → [references/integrations.md](./references/integrations.md) |
| CLI command reference | → [references/cli-reference.md](./references/cli-reference.md) |
| MCP tool reference | → [references/mcp-tools.md](./references/mcp-tools.md) |

---

## Project Setup

Use the Aspire CLI to scaffold new projects. The CLI provides templates and tooling for creating AppHost projects.

```bash
# Install or update the Aspire CLI (requires .NET 8+)
dotnet tool install -g aspire

# Create a new Aspire project (starter template)
aspire init

# Or create with specific template
aspire init --template aspire-starter
```

After scaffolding, the typical solution structure looks like:

```
MyApp/
├── MyApp.AppHost/         # Orchestrator — defines resources & dependencies
│   └── Program.cs         # DistributedApplication.CreateBuilder() entry point
├── MyApp.ServiceDefaults/  # Shared service configuration (telemetry, health, resilience)
├── MyApp.ApiService/       # Your API project(s)
└── MyApp.Web/              # Your frontend project(s)
```

The **AppHost** is the orchestration center. It defines what resources your app comprises and how they relate. See [App Host docs](https://aspire.dev/get-started/app-host/?lang=csharp) for details.

**Service Defaults** provide cross-cutting concerns — OpenTelemetry, health checks, resilience policies — shared across all services. See [Service Defaults docs](https://aspire.dev/fundamentals/service-defaults/).

📖 Latest docs: https://aspire.dev/get-started/app-host/?lang=csharp

---

## Adding Integrations

Aspire integrations are NuGet packages that wire up external services (databases, caches, message brokers, cloud services) with minimal boilerplate.

### Discover available integrations

Use the MCP tool to browse what's available:

```
mcp_aspire_list_integrations
```

This returns the full catalog of hosting integration packages (e.g., `Aspire.Hosting.Redis`, `Aspire.Hosting.PostgreSQL`).

### Add an integration

```bash
aspire add <integration-name>
```

### Get integration documentation

Before configuring an integration, fetch its docs using MCP:

```
mcp_aspire_get_integration_docs(packageId="Aspire.Hosting.Redis", packageVersion="9.0.0")
```

This returns detailed usage instructions for that specific package version — much more reliable than guessing the API.

### Typical AppHost pattern

```csharp
var builder = DistributedApplication.CreateBuilder(args);

// Add infrastructure resources
var cache = builder.AddRedis("cache");
var db = builder.AddPostgres("postgres").AddDatabase("mydb");

// Add application projects with references
var api = builder.AddProject<Projects.MyApp_ApiService>("apiservice")
    .WithReference(db)
    .WithReference(cache);

builder.AddProject<Projects.MyApp_Web>("webfrontend")
    .WithExternalHttpEndpoints()
    .WithReference(cache)
    .WithReference(api);

builder.Build().Run();
```

📖 Latest docs: https://aspire.dev/get-started/resources/

---

## Running the AppHost

### Start the AppHost

The primary way to run an Aspire application is through the CLI:

```bash
aspire run
```

This starts the AppHost, which orchestrates all defined resources (projects, containers, executables) and launches the Aspire dashboard for monitoring.

**Important behaviors:**
- `aspire run` starts all resources defined in the AppHost's `Program.cs`
- The Aspire dashboard URL is printed to the console (typically `https://localhost:15XXX`)
- Resources start in dependency order based on `WithReference()` / `WaitFor()` calls
- Use `Ctrl+C` to gracefully shut down all resources

### Multiple AppHosts

If the workspace contains multiple AppHost projects, you may need to select which one to use:

```
mcp_aspire_list_apphosts        # See all detected AppHosts
mcp_aspire_select_apphost(appHostPath="src/MyApp.AppHost")  # Select one
```

### Run with specific launch profile

```bash
aspire run --launch-profile <profile-name>
```

📖 CLI reference: https://aspire.dev/reference/cli/commands/aspire/

---

## Monitoring Resources

Once the AppHost is running, use MCP tools to inspect resource state without leaving the editor.

### List all resources and their status

```
mcp_aspire_list_resources
```

This returns comprehensive information for each resource:
- **Type**: .NET project, container, or executable
- **Running state**: Running, Stopped, Starting, Failed, etc.
- **HTTP endpoints**: URLs where the resource is accessible
- **Health status**: Healthy, Degraded, Unhealthy
- **Commands**: Available commands for the resource
- **Environment variables**: Configured env vars
- **Relationships**: Dependencies between resources

### Execute commands on resources

Use `mcp_aspire_execute_resource_command` to control individual resources:

```
# Restart a resource
mcp_aspire_execute_resource_command(resourceName="apiservice", commandName="resource-restart")

# Stop a resource
mcp_aspire_execute_resource_command(resourceName="apiservice", commandName="resource-stop")

# Start a stopped resource
mcp_aspire_execute_resource_command(resourceName="apiservice", commandName="resource-start")
```

Known built-in commands: `resource-start`, `resource-stop`, `resource-restart`.

Resources may also expose custom commands — check `mcp_aspire_list_resources` to see what commands are available for each resource.

---

## Observability & Debugging

Aspire provides three pillars of observability through its MCP tools: console logs, structured logs, and distributed traces.

### Console Logs

Console logs capture stdout/stderr from resources — useful for startup errors, crash output, and build issues.

```
mcp_aspire_list_console_logs(resourceName="apiservice")
```

> **Note:** Console logs can be verbose. Examine them when diagnosing why a resource isn't starting or is crashing, but avoid dumping the full output to the user. Summarize the relevant parts.

### Structured Logs

Structured logs provide rich, queryable log entries with severity, category, and structured properties.

```
# Logs for a specific resource
mcp_aspire_list_structured_logs(resourceName="apiservice")

# Logs for all resources
mcp_aspire_list_structured_logs()
```

### Distributed Traces

Traces track operations as they flow across multiple services — essential for understanding latency and errors in distributed calls.

```
# List traces (optionally filter by resource)
mcp_aspire_list_traces(resourceName="apiservice")
mcp_aspire_list_traces()  # all resources

# Get structured logs for a specific trace
mcp_aspire_list_trace_structured_logs(traceId="<trace-id>")
```

### Recommended debugging flow

When investigating an issue:

1. **Start with traces** — `mcp_aspire_list_traces` to find traces with errors or high latency
2. **Drill into trace logs** — `mcp_aspire_list_trace_structured_logs(traceId=...)` for the specific operation
3. **Check structured logs** — `mcp_aspire_list_structured_logs(resourceName=...)` if you need broader context
4. **Fall back to console logs** — `mcp_aspire_list_console_logs(resourceName=...)` for startup failures or unhandled exceptions

This top-down approach (traces → trace logs → structured logs → console logs) helps you find root causes efficiently instead of searching through raw output.

📖 Telemetry docs: https://aspire.dev/fundamentals/telemetry/

---

## Troubleshooting

### Resource won't start

1. Check current state: `mcp_aspire_list_resources` — look for the resource's running state and health status
2. Read console logs: `mcp_aspire_list_console_logs(resourceName="...")` — look for exceptions, missing dependencies, port conflicts
3. Try restarting: `mcp_aspire_execute_resource_command(resourceName="...", commandName="resource-restart")`
4. Check if dependencies are running — a resource with `WaitFor()` won't start until its dependencies are healthy

### Container resource issues

- Ensure Docker Desktop (or compatible runtime) is running
- Check that the container image exists and is accessible
- Review container logs via `mcp_aspire_list_console_logs`

### Service discovery problems

Aspire uses automatic service discovery via environment variables. If Service A references Service B:
- Service A gets `services__serviceb__https__0` (or similar) environment variables automatically
- Check with `mcp_aspire_list_resources` to verify endpoints are assigned
- See [Service Discovery docs](https://aspire.dev/fundamentals/service-discovery/)

### Common pitfalls

- **Port conflicts**: If a resource fails with "address already in use", another process may be occupying that port
- **Missing Docker**: Container resources require a container runtime — Aspire will report an error if none is found
- **Stale state**: After changing `Program.cs`, you need to restart the AppHost (`Ctrl+C` then `aspire run` again)

---

## Reference Files

For detailed information, read the reference files in this skill:

| File | When to read |
|------|-------------|
| [references/docs-index.md](./references/docs-index.md) | Fetch latest Aspire documentation links |
| [references/cli-reference.md](./references/cli-reference.md) | Full CLI command reference and examples |
| [references/mcp-tools.md](./references/mcp-tools.md) | Detailed MCP tool usage guide with examples |
| [references/architecture.md](./references/architecture.md) | Service discovery, service defaults, app lifecycle |
| [references/integrations.md](./references/integrations.md) | Common integration patterns and configuration |
