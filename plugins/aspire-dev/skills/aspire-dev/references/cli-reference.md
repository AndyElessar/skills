# Aspire CLI Reference

> **Latest reference**: <https://aspire.dev/reference/cli/commands/aspire/>
> CLI commands may change between versions. Use `mcp_aspire_search_docs` or check the link above.

## Installation

```bash
# Install the Aspire CLI as a global .NET tool
dotnet tool install -g aspire

# Update to the latest version
dotnet tool update -g aspire

# Verify installation
aspire --version
```

Requires **.NET 8.0 SDK** or later. **Never install the Aspire workload** — it is obsolete.

## App Lifecycle Commands

### `aspire start`

**Start the AppHost in the background.** Preferred for agent environments — returns control immediately.

```bash
aspire start
aspire start --isolated          # Randomized ports + isolated user secrets (for worktrees)
aspire start --apphost <path>    # Target a specific AppHost project
aspire start --no-build          # Skip build/restore
```

Key behaviors:

- **Automatically stops any previous instance** before starting — safe to re-run
- Starts resources in dependency order (respecting `WaitFor()` calls)
- Launches the Aspire dashboard

### `aspire run`

**Run the AppHost in the foreground.** The process stays alive and streams logs until stopped.

```bash
aspire run
aspire run --isolated
aspire run --detach              # Start in background, then exit (similar to aspire start)
```

> **Agent note:** `aspire run` is long-running. If using it instead of `aspire start`, launch as a background terminal process (`isBackground=true`).

### `aspire wait`

**Block until a resource reaches a target status.** Use after `aspire start` to ensure readiness.

```bash
aspire wait myapi                        # Wait for healthy (default)
aspire wait myapi --status up            # Wait for running (not necessarily healthy)
aspire wait myapi --timeout 60           # Custom timeout in seconds (default: 120)
```

Options: `--status` (healthy | up | down, default: healthy), `--timeout` (default: 120s).

### `aspire stop`

**Stop the running AppHost and all its resources.**

```bash
aspire stop
aspire stop --apphost <path>
```

> Prefer re-running `aspire start` instead of `aspire stop` + `aspire start`. The start command handles stopping automatically.

### `aspire ps`

**List running AppHosts.**

```bash
aspire ps
```

## Resource Management

### `aspire describe`

**Show a resource snapshot** — status, endpoints, health, environment variables.

```bash
aspire describe                  # All resources
aspire describe myapi            # Specific resource
aspire describe --follow         # Continuously stream state changes
aspire describe --format Json    # Machine-readable output
```

### `aspire resource`

**Execute a command on a specific resource.**

```bash
aspire resource <resource> start     # Start a stopped resource
aspire resource <resource> stop      # Stop a running resource
aspire resource <resource> restart   # Restart a running resource
aspire resource <resource> <custom>  # Execute a custom resource command
```

## Observability Commands

### `aspire logs`

**View console output (stdout/stderr) for resources.**

```bash
aspire logs                          # All resources
aspire logs myapi                    # Specific resource
aspire logs myapi --follow           # Live stream
aspire logs myapi --tail 50          # Last 50 lines
aspire logs --timestamps             # Show timestamps
aspire logs --format Json            # NDJSON output
```

### `aspire otel logs`

**View structured (OpenTelemetry) log entries.**

```bash
aspire otel logs myapi                       # Structured logs for a resource
aspire otel logs                             # All resources
aspire otel logs --trace-id <id>             # Logs belonging to a specific trace
aspire otel logs --severity Warning          # Filter by minimum severity
aspire otel logs --follow                    # Live stream
aspire otel logs --limit 100                 # Limit results
```

### `aspire otel spans`

**View spans from distributed traces.**

```bash
aspire otel spans myapi                      # Spans for a resource
aspire otel spans --trace-id <id>            # Spans for a specific trace
aspire otel spans --has-error                # Only spans with errors
aspire otel spans --follow                   # Live stream
```

### `aspire otel traces`

**View distributed traces.**

```bash
aspire otel traces myapi                     # Traces involving a resource
aspire otel traces                           # All traces
aspire otel traces --trace-id <id>           # Specific trace by ID
aspire otel traces --has-error               # Only traces with errors
aspire otel traces --limit 20               # Limit results
```

### `aspire export`

**Export telemetry and resource data to a zip file.**

```bash
aspire export                                # Export all data
aspire export myapi                          # Export for specific resource
aspire export --output ./debug-data.zip      # Custom output path
```

## Integration Commands

### `aspire add`

**Add a hosting integration to the AppHost project.**

```bash
aspire add                   # Interactive — lists available integrations
aspire add redis             # Add Redis integration
aspire add postgres          # Add PostgreSQL integration
```

After adding, restart the app with `aspire start` for the new resource to take effect.

### `aspire update`

**Update Aspire hosting packages in the AppHost project.** (Preview)

```bash
aspire update
```

## Project Scaffolding

### `aspire new`

**Create a new Aspire project** from a template.

```bash
aspire new                               # Interactive — shows available templates
aspire new aspire-starter                # ASP.NET Core + Blazor starter
aspire new aspire-ts-cs-starter          # ASP.NET Core + React starter
aspire new aspire-py-starter             # FastAPI + React starter
aspire new aspire-ts-starter             # Express + React starter
aspire new aspire-empty                  # Empty C# AppHost
aspire new aspire-ts-empty               # Empty TypeScript AppHost
aspire new aspire-starter -n MyApp       # Specify project name
aspire new aspire-starter -o ./MyApp     # Specify output directory
```

### `aspire init`

**Initialize Aspire support in an existing solution** or create a single-file AppHost.

```bash
aspire init                              # Interactive
aspire init --language csharp            # C# AppHost
aspire init --language typescript        # TypeScript AppHost
```

## Documentation Commands

### `aspire docs`

```bash
aspire docs search "redis integration"   # Search aspire.dev documentation
aspire docs get redis-integration        # Retrieve full page by slug
aspire docs list                         # List all available pages
```

## Diagnostics & Tools

### `aspire doctor`

**Run environment diagnostics.** Checks SDK version, container runtime, CLI version, and prerequisites.

```bash
aspire doctor
```

Equivalent to MCP tool `mcp_aspire_doctor`. Does not require a running AppHost.

### `aspire restore`

**Restore dependencies and generate SDK code for an AppHost.**

```bash
aspire restore
```

### `aspire agent`

**Manage AI agent integrations.** Replaces the deprecated `aspire mcp init` and `aspire mcp start` subcommands.

```bash
aspire agent mcp              # Start the MCP server (replaces aspire mcp start)
aspire agent init             # Initialize agent environment settings (replaces aspire mcp init)
```

> **Note:** Only `aspire mcp init` and `aspire mcp start` are deprecated (use `aspire agent` instead). `aspire mcp tools` and `aspire mcp call` are **not** deprecated — they remain the way to discover and invoke resource-level MCP tools.

### `aspire secret`

**Manage AppHost user secrets.**

```bash
aspire secret
```

### `aspire certs`

**Manage HTTPS development certificates.**

```bash
aspire certs
```

## Resource MCP Tools (via CLI)

Some resources expose MCP tools (e.g. `WithPostgresMcp()` adds SQL query tools):

```bash
aspire mcp tools                                              # List available tools
aspire mcp tools --format Json                                # Includes input schemas
aspire mcp call <resource> <tool> --input '{"key":"value"}'   # Invoke a tool
```

## Common Workflows

### New project from scratch

```bash
aspire new aspire-starter -n MyApp
cd MyApp
aspire add redis
aspire start
aspire wait apiservice
```

### Restart after AppHost changes

```bash
aspire start    # Automatically stops previous instance and restarts
```

### Restart a single resource

```bash
aspire resource apiservice restart
```

### Global flags

| Flag | Purpose |
| --- | --- |
| `--format Json\|Table` | Machine-readable output |
| `--apphost <path>` | Target a specific AppHost project |
| `--isolated` | Isolated mode (randomized ports, separate secrets) |
| `--no-build` | Skip build/restore before running |
| `--non-interactive` | Disable prompts and spinners |
| `--log-level <level>` | Set console log level (Trace/Debug/Information/Warning/Error/Critical) |
