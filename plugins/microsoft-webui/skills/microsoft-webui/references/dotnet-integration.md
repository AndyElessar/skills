# `Microsoft.WebUI` .NET Integration

The WebUI native engine renders from `protocol.bin` + JSON state in any host language. This reference is specific to the current .NET binding.

## .NET: `Microsoft.WebUI`

### Install

```bash
dotnet add package Microsoft.WebUI
```

NuGet automatically resolves the right native runtime:

| Runtime | Package |
|---|---|
| Windows x64 | `Microsoft.WebUI.Runtime.win-x64` |
| Windows ARM64 | `Microsoft.WebUI.Runtime.win-arm64` |
| Linux x64 | `Microsoft.WebUI.Runtime.linux-x64` |
| Linux ARM64 | `Microsoft.WebUI.Runtime.linux-arm64` |
| macOS x64 | `Microsoft.WebUI.Runtime.osx-x64` |
| macOS ARM64 | `Microsoft.WebUI.Runtime.osx-arm64` |

### One-shot render (`WebUIRenderer`)

Useful for tests, snippets, or single fragments — parses the template every call.

```csharp
using Microsoft.WebUI;

var html = "<div>Hello, {{name}}!</div>";
var json = """{ "name": "World" }""";
var result = WebUIRenderer.RenderHtml(html, json);
// → "<div>Hello, World!</div>"
```

### Production: `WebUIHandler`

Load `protocol.bin` once, render many times. The handler is `IDisposable` — keep one per process (typically a singleton in DI).

```csharp
using Microsoft.WebUI;

using var handler = new WebUIHandler("fast-v3"); // hydration plugin
byte[] protocol = File.ReadAllBytes("app.webui");

var html = handler.Render(
    protocol,
    """{ "user": "Alice" }""",
    "index.html",   // entry template name
    "/");           // request path
```

Plugin values:

| Value | Use |
|---|---|
| `"fast-v3"` | `@microsoft/fast-element` 3.x hydration. **Default for new apps.** |
| `"fast-v2"` | Deprecated 2.x compatibility. |
| `"fast"` | Legacy alias for 2.x. |

### ASP.NET Core endpoint (full SSR + client-router partials)

The WebUI Router negotiates via `Accept: application/json` and an `X-WebUI-Inventory` header listing already-loaded templates. One endpoint serves both:

```csharp
app.MapGet("/users/{id}", (HttpContext ctx, string id) =>
{
    var stateJson = JsonSerializer.Serialize(new { name = GetUser(id).Name });

    if (ctx.Request.Headers.Accept.Contains("application/json"))
    {
        var inventoryHex = ctx.Request.Headers["X-WebUI-Inventory"].FirstOrDefault() ?? "";
        var json = handler.RenderPartial(
            protocol, stateJson, "index.html", ctx.Request.Path, inventoryHex);
        return Results.Content(json, "application/json");
    }

    var html = handler.Render(protocol, stateJson, "index.html", ctx.Request.Path);
    return Results.Content(html, "text/html");
});
```

`RenderPartial` returns a complete JSON response (state, templates, inventory, path, matched route chain). Pipe it directly to the wire — no deserialization needed.

### `Router.ensureLoaded` endpoint contract

Upstream WebUI docs define a `GET /_webui/templates?t=tag1,tag2` endpoint for `Router.ensureLoaded(...)`, but the current .NET binding does **not** document or expose a dedicated `RenderComponentTemplates`-style helper in `Microsoft.WebUI`. Treat this as an integration boundary: verify your package version first, or add your own native binding if you need this endpoint from .NET today.

### Custom native library path

```bash
export WEBUI_LIB_PATH=/path/to/dir          # directory containing libwebui_ffi.*
# or
export WEBUI_LIB_PATH=/path/to/libwebui_ffi.dylib   # explicit file
```

## Operational notes

- **Reuse the handler.** Construction parses the protocol; per-request work is just rendering. In ASP.NET Core, register `WebUIHandler` as a singleton.
- **Dispose on shutdown.** `WebUIHandler` owns a native resource — wrap in `using` or register with the DI container so it disposes with the host.
- **State is per-request.** The protocol is shared; pass route-specific JSON each call.
- **Partial responses are opaque JSON.** Don't reshape them server-side — the client router expects the exact contract.
