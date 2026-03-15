# Aspire CLI Reference

> **Latest reference**: https://aspire.dev/reference/cli/commands/aspire/
> CLI commands may change between versions. When in doubt, check the link above.

## Installation

```bash
# Install the Aspire CLI as a global .NET tool
dotnet tool install -g aspire

# Update to the latest version
dotnet tool update -g aspire

# Verify installation
aspire --version
```

Requires **.NET 8.0 SDK** or later.

## Core Commands

### `aspire init`

Initialize a new Aspire project.

```bash
# Interactive mode — prompts for template and name
aspire init

# Specify template
aspire init --template aspire-starter

# Specify output directory
aspire init --output ./MyApp
```

Available templates:
- `aspire` — Minimal AppHost + ServiceDefaults
- `aspire-starter` — AppHost + ServiceDefaults + API + Web frontend

### `aspire run`

**Start the AppHost and all its resources.** This is the primary command for running an Aspire application.

```bash
# Run from the solution or AppHost directory
aspire run

# Run a specific AppHost project
aspire run --project ./src/MyApp.AppHost/MyApp.AppHost.csproj

# Run with a specific launch profile
aspire run --launch-profile <profile-name>
```

What happens when you run `aspire run`:
1. Builds all projects in the AppHost's dependency graph
2. Starts resources in dependency order (respecting `WaitFor()` calls)
3. Launches the Aspire dashboard (URL printed to console)
4. Streams logs from all resources

Press `Ctrl+C` to gracefully stop all resources.

### `aspire add`

Add a hosting integration to the AppHost project.

```bash
# Add Redis integration
aspire add redis

# Add PostgreSQL
aspire add postgres
```

This installs the NuGet package and may scaffold initial configuration. Use `mcp_aspire_list_integrations` to see all available integrations.

### `aspire publish`

Publish the application for deployment.

```bash
aspire publish
```

📖 See CI/CD & deployment: https://aspire.dev/get-started/pipelines/

## Common Workflows

### New project from scratch

```bash
aspire init --template aspire-starter
cd MyApp
aspire add redis           # Add a cache
aspire run                 # Launch everything
```

### Add a new service to an existing project

1. Create the .NET project: `dotnet new webapi -n MyApp.NewService`
2. Reference it from AppHost's `Program.cs`:
   ```csharp
   builder.AddProject<Projects.MyApp_NewService>("newservice")
       .WithReference(existingResource);
   ```
3. Run: `aspire run`

### Restart after code changes

```bash
# Stop with Ctrl+C, then re-run
aspire run
```

Or, for individual resources without full restart, use the MCP tool:
```
mcp_aspire_execute_resource_command(resourceName="apiservice", commandName="resource-restart")
```
