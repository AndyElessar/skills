# WebUI Host Integrations and Template Endpoint

This reference covers non-.NET hosts plus the upstream `/_webui/templates` endpoint contract used by `Router.ensureLoaded(...)`.

## `Router.ensureLoaded` server endpoint

Upstream WebUI docs define a `GET /_webui/templates?t=tag1,tag2` endpoint for `Router.ensureLoaded(...)`. The FFI layer exposes `webui_render_component_templates`, which returns JSON containing templates, template styles, CSS hrefs, and updated inventory data.

If you are implementing this endpoint in a host language, use the host's component-template render API when available. Do not assume every host binding exposes the same helper surface.

## Rust

```rust
let protocol = WebUIProtocol::from_protobuf(&fs::read("dist/protocol.bin")?)?;
let state = json!({ "title": "Home", "items": items_vec });
let mut handler = WebUIHandler::new();
handler.handle(&protocol, &state, &options, &mut writer)?;
```

Templates endpoint:

```rust
let result = route_handler::render_component_templates(&protocol, &tags, &inv);
```

## Node.js

```javascript
import { render } from '@microsoft/webui';
const protocol = readFileSync('./dist/protocol.bin');
const html = render(protocol, JSON.stringify(state), 'index.html', req.url);
```

Templates endpoint:

```javascript
import { renderComponentTemplates } from '@microsoft/webui';
const result = renderComponentTemplates(protocolBuf, ['settings-dialog'], invHex);
```

## Python (FFI)

```python
ptr = lib.webui_render(html_bytes, json_bytes)
result = ctypes.cast(ptr, c_char_p).value.decode("utf-8")
lib.webui_free(ptr)
```

## Go (cgo)

```go
ptr := C.webui_render(cHTML, cJSON)
defer C.webui_free(ptr)
result := C.GoString(ptr)
```
