# Aspire Integrations Guide

> **Authoritative integration list**: Use `mcp_aspire_list_integrations` to get the full, up-to-date catalog.
> **Integration docs**: Use `mcp_aspire_search_docs(query="...")` to find the right doc, then `mcp_aspire_get_doc(slug="...")` to read it.

## What are Integrations?

Aspire integrations are NuGet packages that add support for external services (databases, caches, message brokers, etc.) to your AppHost with minimal configuration. They handle:

- Container/resource provisioning in development
- Connection string management and service discovery
- Health checks for the integrated service
- Telemetry instrumentation

## Adding an Integration

```bash
# Via CLI (interactive — lists available integrations)
aspire add

# Via CLI (specific integration)
aspire add redis

# Via NuGet (manual)
dotnet add package Aspire.Hosting.Redis
```

After adding an integration, restart the app with `aspire start` for the new resource to take effect.

## Common Integration Patterns

### Cache — Redis

```csharp
// AppHost
var cache = builder.AddRedis("cache");
builder.AddProject<Projects.Web>("web").WithReference(cache);
```

```csharp
// Consuming project
builder.AddRedisOutputCache("cache");
// or
builder.AddRedisDistributedCache("cache");
```

### Database — PostgreSQL

```csharp
// AppHost
var postgres = builder.AddPostgres("postgres")
    .AddDatabase("mydb");
builder.AddProject<Projects.Api>("api").WithReference(postgres);
```

```csharp
// Consuming project
builder.AddNpgsqlDbContext<MyDbContext>("mydb");
```

### Database — SQL Server

```csharp
// AppHost
var sql = builder.AddSqlServer("sql")
    .AddDatabase("mydb");
```

### Message Broker — RabbitMQ

```csharp
// AppHost
var messaging = builder.AddRabbitMQ("messaging");
builder.AddProject<Projects.Worker>("worker").WithReference(messaging);
```

### Message Broker — Azure Service Bus

```csharp
// AppHost
var sb = builder.AddAzureServiceBus("messaging");
```

## Finding Integration APIs

Since Aspire updates frequently, **always check the docs** before configuring:

```text
mcp_aspire_search_docs(query="redis integration")    → Find the slug
mcp_aspire_get_doc(slug="redis-integration")          → Read full API guide
```

This is far more reliable than relying on memorized patterns that may be outdated.

## Common Integration NuGet Packages

| Service | Hosting Package | Client Package |
| --- | --- | --- |
| Redis | `Aspire.Hosting.Redis` | `Aspire.StackExchange.Redis` |
| PostgreSQL | `Aspire.Hosting.PostgreSQL` | `Aspire.Npgsql` |
| SQL Server | `Aspire.Hosting.SqlServer` | `Aspire.Microsoft.Data.SqlClient` |
| MongoDB | `Aspire.Hosting.MongoDB` | `Aspire.MongoDB.Driver` |
| RabbitMQ | `Aspire.Hosting.RabbitMQ` | `Aspire.RabbitMQ.Client` |
| Azure Storage | `Aspire.Hosting.Azure.Storage` | `Aspire.Azure.Storage.Blobs` |
| Azure Key Vault | `Aspire.Hosting.Azure.KeyVault` | `Aspire.Azure.Security.KeyVault` |

> This table may be incomplete or outdated. Use `mcp_aspire_list_integrations` for the authoritative list.

## Configuration Patterns

### Persistent volumes (data survives restarts)

```csharp
var postgres = builder.AddPostgres("postgres")
    .WithDataVolume("postgres-data");
```

### Custom container images

```csharp
var redis = builder.AddRedis("cache")
    .WithImage("redis", "7.2");
```

### External connection strings (production)

```csharp
var db = builder.AddConnectionString("mydb");
```

Reads from configuration (appsettings, environment, secrets) instead of creating a container — useful for production where the database already exists.

### Resource MCP tools

Some integrations expose MCP tools for direct interaction (e.g. `WithPostgresMcp()` adds SQL query tools):

```bash
aspire mcp tools                                              # List available tools
aspire mcp call <resource> <tool> --input '{"key":"value"}'   # Invoke a tool
```
