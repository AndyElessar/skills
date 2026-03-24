# Aspire Architecture Concepts

> **Latest docs**: https://aspire.dev/docs/ — use `mcp_aspire_search_docs` to search, `mcp_aspire_get_doc` to read full pages.

## AppHost — The Orchestration Center

The AppHost project is the entry point of an Aspire application. It defines the **application model**: what resources exist and how they relate. The entry file is typically `Program.cs` or `AppHost.cs` (newer templates). The entry file is typically `Program.cs` or `AppHost.cs` (newer templates).

```csharp
var builder = DistributedApplication.CreateBuilder(args);

var cache = builder.AddRedis("cache");
var api = builder.AddProject<Projects.ApiService>("api")
    .WithReference(cache);

builder.Build().Run();
```

Key concepts:

- **Resources** are the building blocks: projects, containers, executables, cloud services
- **References** (`WithReference()`) establish relationships and enable service discovery
- **WaitFor** (`WaitFor()`) adds startup ordering — a resource waits for its dependency to be healthy before starting

Typical solution structure after `aspire new aspire-starter`:

```text
MyApp/
├── MyApp.AppHost/           # Orchestrator — defines resources & dependencies
│   └── Program.cs / AppHost.cst.cs  # DistributedApplication.CreateBuilder() entry point
├── MyApp.ServiceDefaults/   # Shared service configuration (telemetry, health, resilience)
├── MyApp.ApiService/        # API project(s)
└── MyApp.Web/               # Frontend project(s)
```

---

## Service Discovery

Aspire provides automatic service discovery between resources. When Service A has a `WithReference(serviceB)`, it receives environment variables that resolve to Service B's endpoints at runtime.

**How it works:**

1. AppHost assigns endpoints to resources
2. References create environment variables like `services__serviceb__https__0`
3. The Aspire service discovery client library resolves `https://serviceb` to the actual endpoint
4. No manual URL configuration needed

**In code:**

```csharp
// AppHost
builder.AddProject<Projects.Web>("web")
    .WithReference(api);  // Web can now call "https://api"

// In the Web project
var client = httpClientFactory.CreateClient();
var response = await client.GetAsync("https://api/weatherforecast");
```

**Troubleshooting:** Use `mcp_aspire_list_resources` to verify endpoints are assigned and environment variables are present.

---

## Service Defaults

Service Defaults is a shared project that configures cross-cutting concerns for all services:

- **OpenTelemetry** — metrics, traces, and logs exported automatically
- **Health checks** — `/health` and `/alive` endpoints
- **Resilience** — retry policies, circuit breakers, timeouts
- **Service discovery** — automatic endpoint resolution

Every project in the Aspire app calls `builder.AddServiceDefaults()` to opt in:

```csharp
var builder = WebApplication.CreateBuilder(args);
builder.AddServiceDefaults();
```

Customize by editing `ServiceDefaults/Extensions.cs`.

---

## App Lifecycle

Aspire manages the lifecycle of all resources:

1. **Build** — .NET projects are compiled
2. **Start** — Resources start in dependency order (respecting `WaitFor()`)
3. **Health monitoring** — Dashboard and MCP tools continuously monitor health
4. **Shutdown** — Graceful shutdown of all resources

Use `aspire start` to start the app in the background. Re-running `aspire start` automatically stops the previous instance and restarts.

---

## Telemetry

Aspire is built on OpenTelemetry. Every service that calls `AddServiceDefaults()` automatically exports:

- **Logs** → structured log entries via `ILogger`
- **Traces** → distributed traces across HTTP calls, database operations, etc.
- **Metrics** → counters, histograms for HTTP requests, connections, etc.

The Aspire dashboard collects and displays all telemetry data. The MCP tools (`mcp_aspire_list_structured_logs`, `mcp_aspire_list_traces`) and CLI commands (`aspire otel logs`, `aspire otel traces`) tap into the same data.

---

## Resources

Resources represent the components of your distributed application:

| Resource Type | Example | Added via |
| --- | --- | --- |
| .NET Project | API, Web frontend | `builder.AddProject<T>()` |
| Container | Redis, PostgreSQL, RabbitMQ | `builder.AddRedis()`, `builder.AddPostgres()`, etc. |
| Executable | Non-.NET processes | `builder.AddExecutable()` |
| Cloud Service | Azure Storage, AWS S3 | Cloud-specific integrations |

Each resource has endpoints, environment variables, health status, and relationships to other resources. Inspect them with `mcp_aspire_list_resources` or `aspire describe`.
