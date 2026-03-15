# Aspire Integrations Guide

> **Latest integration list**: Use `mcp_aspire_list_integrations` or check https://aspire.dev/docs/
> **Integration docs**: Use `mcp_aspire_get_integration_docs(packageId="...", packageVersion="...")` to get the exact API for your version.

## What are Integrations?

Aspire integrations are NuGet packages that add support for external services (databases, caches, message brokers, etc.) to your AppHost with minimal configuration. They handle:

- Container/resource provisioning in development
- Connection string management and service discovery
- Health checks for the integrated service
- Telemetry instrumentation

## Adding an Integration

```bash
# via CLI
aspire add redis

# via NuGet (manual)
dotnet add package Aspire.Hosting.Redis
```

## Common Integration Patterns

### Cache — Redis

```csharp
// AppHost
var cache = builder.AddRedis("cache");
builder.AddProject<Projects.Web>("web").WithReference(cache);
```

```csharp
// In consuming project
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
// In consuming project
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

Since Aspire updates frequently, **always check the integration docs** before configuring:

```
mcp_aspire_get_integration_docs(packageId="Aspire.Hosting.Redis", packageVersion="9.0.0")
```

This returns the latest API shape, configuration options, and usage patterns for that specific version. This is far more reliable than relying on memorized patterns that may be outdated.

## Common Integration NuGet Packages

| Service | Hosting Package | Client Package |
|---------|----------------|----------------|
| Redis | `Aspire.Hosting.Redis` | `Aspire.StackExchange.Redis` |
| PostgreSQL | `Aspire.Hosting.PostgreSQL` | `Aspire.Npgsql` |
| SQL Server | `Aspire.Hosting.SqlServer` | `Aspire.Microsoft.Data.SqlClient` |
| MongoDB | `Aspire.Hosting.MongoDB` | `Aspire.MongoDB.Driver` |
| RabbitMQ | `Aspire.Hosting.RabbitMQ` | `Aspire.RabbitMQ.Client` |
| Azure Storage | `Aspire.Hosting.Azure.Storage` | `Aspire.Azure.Storage.Blobs` |
| Azure Key Vault | `Aspire.Hosting.Azure.KeyVault` | `Aspire.Azure.Security.KeyVault` |

> This table may be incomplete or outdated. Use `mcp_aspire_list_integrations` for the authoritative list.

## Patterns for Integration Configuration

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

This reads from configuration (appsettings, environment, secrets) instead of creating a container — useful for production where the database already exists.
