# Aspire Architecture Concepts

> **Latest docs**: Check https://aspire.dev/docs/ for the most current information.

## AppHost — The Orchestration Center

The AppHost project is the entry point of an Aspire application. It defines the **application model**: what resources exist and how they relate.

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

📖 https://aspire.dev/get-started/app-host/?lang=csharp

---

## Service Discovery

Aspire provides automatic service discovery between resources. When Service A has a `WithReference(serviceB)`, it receives environment variables that resolve to Service B's endpoints at runtime.

**How it works:**
1. AppHost assigns endpoints to resources
2. References create environment variables like `services__serviceb__https__0`
3. The Aspire service discovery client library resolves `https://serviceb` to the actual endpoint using these env vars
4. No manual URL configuration needed

**In code:**
```csharp
// AppHost
builder.AddProject<Projects.Web>("web")
    .WithReference(api);  // Web can now call "https://api"

// In the Web project's code
var client = httpClientFactory.CreateClient();
var response = await client.GetAsync("https://api/weatherforecast");
```

📖 https://aspire.dev/fundamentals/service-discovery/

---

## Service Defaults

Service Defaults is a shared project that configures cross-cutting concerns for all services in the Aspire app:

- **OpenTelemetry** — metrics, traces, and logs exported automatically
- **Health checks** — `/health` and `/alive` endpoints
- **Resilience** — retry policies, circuit breakers, timeouts via Microsoft.Extensions.Http.Resilience
- **Service discovery** — automatic endpoint resolution

Every project in the Aspire app calls `builder.AddServiceDefaults()` in its `Program.cs` to opt into these behaviors.

```csharp
var builder = WebApplication.CreateBuilder(args);
builder.AddServiceDefaults();  // Adds telemetry, health checks, resilience, service discovery
```

**Customizing:** Edit the `ServiceDefaults/Extensions.cs` file to adjust what's included (e.g., add custom health checks, change telemetry exporters, adjust resilience policies).

📖 https://aspire.dev/fundamentals/service-defaults/

---

## App Lifecycle

Aspire manages the lifecycle of all resources:

1. **Build** — .NET projects are compiled
2. **Start** — Resources start in dependency order (respecting `WaitFor()`)
3. **Health monitoring** — The dashboard and MCP tools continuously monitor health
4. **Shutdown** — `Ctrl+C` triggers graceful shutdown of all resources

Lifecycle hooks are available for custom behavior:
```csharp
var lifecycle = builder.Services.GetRequiredService<DistributedApplicationLifecycle>();
```

📖 https://aspire.dev/fundamentals/app-lifecycle/

---

## Telemetry

Aspire is built on OpenTelemetry. Every service that calls `AddServiceDefaults()` automatically exports:

- **Logs** → structured log entries via `ILogger`
- **Traces** → distributed traces across HTTP calls, database operations, etc.
- **Metrics** → counters, histograms for HTTP requests, connections, etc.

The Aspire dashboard collects and displays all telemetry data. The MCP tools (`mcp_aspire_list_structured_logs`, `mcp_aspire_list_traces`) tap into the same data.

📖 https://aspire.dev/fundamentals/telemetry/

---

## Resources

Resources represent the components of your distributed application:

| Resource Type | Example | Added via |
|--------------|---------|-----------|
| .NET Project | API, Web frontend | `builder.AddProject<T>()` |
| Container | Redis, PostgreSQL, RabbitMQ | `builder.AddRedis()`, `builder.AddPostgres()`, etc. |
| Executable | Non-.NET processes | `builder.AddExecutable()` |
| Cloud Service | Azure Storage, AWS S3 | Cloud-specific integrations |

Each resource has endpoints, environment variables, health status, and relationships to other resources.

📖 https://aspire.dev/get-started/resources/
