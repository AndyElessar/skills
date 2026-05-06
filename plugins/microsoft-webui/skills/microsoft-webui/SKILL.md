---
name: microsoft-webui
description: "Microsoft WebUI Framework expertise — a language-agnostic server-side rendering framework where templates compile to a binary protocol and interactive Web Components hydrate as islands. Use when authoring, reviewing, or debugging WebUI components (`.html` + `.css` + `.ts` triplets), wiring up routes, hydrating with `WebUIElement`, configuring `webui build` / `webui serve`, or integrating SSR into a backend. Also trigger when the user mentions `@microsoft/webui`, `@microsoft/webui-framework`, `@microsoft/webui-router`, `WebUIElement`, `@attr` / `@observable` decorators, `protocol.bin`, `Router.start`, `Router.navigate`, `Router.ensureLoaded`, `<route>` / `<outlet>` tags, `keep-alive`, `pending`, `cache-tags`, or shadow-DOM scoped components from Microsoft. Do NOT use for unrelated UI libraries (React, Vue, FAST standalone, Lit, Blazor, or generic Web Components projects)."
---

# Microsoft WebUI Framework

## Mental Model

WebUI is **server-side HTML rendering from a compiled binary protocol + JSON state**, with optional client-side hydration of interactive components as islands.

```
BUILD              SERVER RENDER          CLIENT HYDRATION
HTML+CSS+TS  →     protocol.bin     →     Web Components hydrate
webui build        + JSON state           as islands
                   → rendered HTML
```

Hard rules:

- Templates are declarative HTML, CSS is plain CSS, behavior is TypeScript — **always in separate files**.
- No JSX, no CSS-in-JS, no template literals, no virtual DOM, no JS on the server.
- Every binding `{{x}}` must exist in the server state JSON (or be on an `@observable` after hydration).
- Static content ships zero JavaScript. Only components with handlers/state hydrate.

## Project Layout

```
my-app/
├── src/
│   ├── index.html              ← entry template
│   ├── index.ts                ← hydration entry (imports register components)
│   ├── my-card/
│   │   ├── my-card.html        ← template (hyphenated name → <my-card>)
│   │   ├── my-card.css         ← scoped styles
│   │   └── my-card.ts          ← WebUIElement subclass
│   └── ...
├── data/state.json             ← dev-server state
└── package.json
```

Component discovery is by file naming convention: a hyphenated `.html` becomes a custom element; sibling `.css` and `.ts` of the same basename are auto-paired. Recursive through subfolders. **No imports between templates.**

## Authoring a Component (Default Workflow)

For any "create a WebUI component" request, produce the template and styles in a single folder first. Add the behavior file only when the component needs client-side interactivity such as event handlers, mutable `@observable` state, or form behavior.

Load [assets/component-triplet-template.md](./assets/component-triplet-template.md) when the user asks for a concrete component scaffold or when you need examples for the `.html`, `.css`, and optional `.ts` files. Keep the generated files in a hyphenated component folder and import the `.js` module from `index.ts` only when a behavior file exists.

## Template Syntax — the Essentials

| Need | Syntax |
|---|---|
| Escaped text | `{{expr}}` |
| Raw text (trusted only) | `{{{expr}}}` |
| Conditional block | `<if condition="status == 'active'">…</if>` |
| Loop | `<for each="item in items">…</for>` |
| Dynamic attribute | `<a href="{{url}}">` |
| Boolean attribute | `<button ?disabled="{{isLoading}}">` |
| Property binding | `<my-widget :config="{{settings}}">` |
| Event handler | `<button @click="{onClick()}">` |
| DOM ref | `<input w-ref="inputEl" />` → `inputEl!: HTMLInputElement;` |

Condition expression rules (apply to every `condition="..."`, `?attr="{{...}}"`, and `{{...}}` binding):

- **Operators allowed:** `==`, `!=`, `<`, `<=`, `>`, `>=`, `&&`, `||`, `!`.
- **One operator family per expression:** use either `&&` or `||`, never both. For mixed logic, nest a second `<if>` — instead of `condition="a && (b || c)"`, write `<if condition="a"><if condition="b || c">…</if></if>`.
- **No parentheses** inside an expression.
- **Max 5 logical operators** per expression.
- **No ternary** (`x ? a : b`) — use `<if>` or boolean attributes.
- **No function calls** in bindings — compute upstream in the handler or server.

For full template grammar and hydration patterns, load [references/template-syntax.md](./references/template-syntax.md). For routing, client navigation, loaders/actions, cache tags, and `Router.start` / `Router.navigate` / `Router.ensureLoaded`, load [references/routing.md](./references/routing.md).

## Component Class — the Essentials

`WebUIElement` decorators and API:

| Construct | Purpose |
|---|---|
| `@attr name = '...'` | Reflects to/from a kebab-case HTML attribute (string mode). |
| `@attr({ mode: 'boolean' }) flag = false` | Boolean attribute (present/absent). |
| `@observable name = ...` | Reactive internal state; mutation triggers DOM update. |
| `w-ref="x"` + `x!: HTMLElement` | Imperative DOM access (focus, scroll, measure). |
| `this.$emit(name, { detail })` | Dispatch a bubbling `CustomEvent`; payload goes inside `detail`. Parent reads via `e.detail.*`. |
| `this.$update()` / `this.$flushUpdates()` | Force/flush a reactive update cycle. |
| `setState(state)` | Populated by the router on navigation. |
| `static define(tagName)` | Register the class as a custom element. |

**Derived state belongs in the template, not in mirror observables.** Prefer `?disabled="{{currentIndex == 0}}"` over a `prevDisabled` `@observable`. Per-iteration flags like `isCurrent` should be derived via comparisons inside `<for>`, not baked into JSON.

For the full decorator/API surface plus child→parent custom-event patterns and dynamic component loading, see [references/template-syntax.md](./references/template-syntax.md).

## When to Hydrate (Islands Decision)

**Create a `.ts` file only when the component needs client-side interactivity** — specifically one or more of: `@click` / `@input` / `@keydown` (or other DOM event) handlers, `@observable` state that mutates after hydration, form input handling, or client-side sorting/filtering/pagination. If none of these apply, ship template + CSS only. Static content pages, read-only data displays, and link-only headers/footers should ship as pure SSR — adding `.ts` costs JavaScript bytes and hydration time for no benefit.

The rule of thumb: **add `.ts` only when the user will interact with this component**. The server already rendered everything else perfectly.

## Hydration Entry

Declare the route tree in `src/index.html` (the entry HTML). Do not put `<route>` directives inside leaf component templates.

```typescript
// src/index.ts
import { WebUIElement } from '@microsoft/webui-framework';
import './app-shell/app-shell.js';
import './widget-name/widget-name.js';

// Optional: with client-side routing
import { Router } from '@microsoft/webui-router';
Router.start({
  loaders: {
    'home-page':   () => import('./pages/home-page.js'),
    'user-detail': () => import('./pages/user-detail.js'),
  },
});
```

Importing a component module is what registers it and triggers hydration. There is no manual `customElements.define` call needed beyond the static `define()` inside the class file.

`Router.start()` boots client-side routing on top of SSR output. On the first SSR bootstrap, the router uses the server-rendered state and skips replaying `static loader()` by default. Add `static ssrLoader = true` only when the first hydrated load must also run the loader.

Use `Router.navigate(path)` for imperative navigation from code: post-submit redirects, retry buttons, wizard next/back flows, or selection-driven drill-in. For normal navigation in markup, prefer regular links.

## CLI

```bash
# Production build → emits dist/protocol.bin + assets
webui build ./src --out ./dist --plugin=webui

# Dev server with live reload + JSON state
webui serve ./src --state ./data/state.json --plugin=webui --watch

# Inspect compiled protocol
webui inspect ./dist/protocol.bin
```

Common `package.json`:

```json
{
  "scripts": {
    "build": "webui build ./src --out ./dist --plugin=webui",
    "dev":   "webui serve ./src --state ./data/state.json --plugin=webui --watch"
  },
  "dependencies": {
    "@microsoft/webui": "latest",
    "@microsoft/webui-framework": "latest"
  }
}
```

Add `@microsoft/webui-router` if using `<route>` / `Router`. For external component libraries via `--components` and design tokens via `--theme`, see [references/template-syntax.md](./references/template-syntax.md).

**Light DOM** (`--dom=light`, default is `shadow`) is the performance-oriented option when style encapsulation is not the priority. In the upstream Light DOM vs Shadow DOM comparison, it showed 26% faster First Contentful Paint and 60% fewer layout operations by avoiding shadow-root overhead and shadow boundary recalculations. Prefer it on high-component-count or FCP-sensitive pages where global CSS is acceptable; otherwise keep Shadow DOM for style isolation.

## Common React Habits to Avoid

LLMs (and developers) coming from React reflexively reach for patterns that fight WebUI's declarative template model. Watch for these:

| React habit | WebUI replacement |
|---|---|
| **Array rebuild to toggle one property** (`items.map(i => i.id === id ? {...i, x: !i.x} : i)`) | Mutate the item in place: `item.x = !item.x;` then bind `?data-x="{{item.x}}"` in the template. |
| **Shadow observable mirroring derived state** (`@observable hasItems` synced from `items.length`) | Use a template expression: `<if condition="items.length">`. No extra property, no sync. |
| **`onItemsChanged` cascading filter/count chain** (useEffect-style) | Compose conditions in the template: nested `<if>`/`<for>`. No intermediate state. |
| **Storing `fullName` derived from `firstName`+`lastName`** | Bind both directly: `<span>{{firstName}} {{lastName}}</span>`. |
| **Manual `setAttribute` / `classList.toggle` via `w-ref`** | Use declarative bindings: `?aria-pressed="{{isActive}}"`, `?data-active="{{isActive}}"`, then style in CSS via attribute selectors. |

The through-line: **derived state belongs in the template, not in mirror observables.** Reserve `@observable` for state that genuinely changes, and reserve `w-ref` for imperative DOM ops (focus, measure, scroll).

## .NET Integration (`Microsoft.WebUI`)

WebUI renders from any backend. For .NET, use the official native bindings — they load `protocol.bin` once and render with per-request JSON state.

Load [references/dotnet-integration.md](./references/dotnet-integration.md) before writing or reviewing .NET host code. Use `WebUIRenderer.RenderHtml` only for tests, snippets, or small one-shot renders. For production, construct one reusable `WebUIHandler`, render precompiled protocol with per-request JSON state, and choose `RenderPartial` for client-router JSON navigations based on the `Accept` header.

Use `"fast-v3"` for new `@microsoft/fast-element` 3.x integrations; `"fast"` and `"fast-v2"` are legacy 2.x compatibility values. For the `/_webui/templates` endpoint contract used by `Router.ensureLoaded` and for non-.NET host samples, load [references/host-integrations.md](./references/host-integrations.md).

## Things You Must NOT Do

1. No ternary in templates (`{{x ? a : b}}`). Use `<if>` or boolean attributes.
2. No function calls in bindings (`{{format(x)}}`). Compute in handler or server.
3. No mixed `&&` and `||` in one expression. Split into nested `<if>`.
4. No parentheses inside `condition="..."`.
5. No JavaScript in `.html`; no JavaScript in `.css`. Logic lives in `.ts`.
6. No computed getters for SSR-bound state — every template-bound value must exist in JSON state or as `@observable`.
7. Components inside `<for>` do **not** inherit loop variables. Pass via attributes.
8. Never use the string `"false"` as a boolean — non-empty strings are truthy. Use real booleans.
9. Don't `querySelector` for reactive state. Use `@observable` + bindings; reserve `w-ref` for imperative DOM ops.
10. Don't wrap `Router.navigate()` in your own `startViewTransition()` — the router already does it.

## SSR State Completeness Checklist

Before shipping a route handler, walk every `{{binding}}`, `<if condition>`, and `<for each>` in the template and confirm the server JSON provides each path. Missing keys do **not** raise an error — they silently render empty (text), false (conditions), or zero items (loops). If your initial paint is missing data, check the server state first.

Also prune the other direction: **return only what this route's templates actually bind to**. Sending the entire app state on every route can balloon a 15 KB response into 240 KB. Per-route, scoped JSON is the rule.

## When the Task Is Done

- For a new component: the three files (`name.html`, `name.css`, plus `name.ts` only if interactive) exist in their own folder, the class registers via `static define()`, and `index.ts` imports it.
- For a .NET integration: the package is referenced, a `WebUIHandler` is constructed once and reused, and the route handler distinguishes JSON-partial vs full-HTML responses by `Accept` header.
- For a review: every binding has a backing state path, no rule from "Things You Must NOT Do" is violated, derived values are template expressions (not shadow observables), and child→parent events use `this.$emit('name', { detail: {...} })`.

## References

- [assets/component-triplet-template.md](./assets/component-triplet-template.md) — reusable `.html` + `.css` + optional `.ts` scaffold for new WebUI components.
- [references/template-syntax.md](./references/template-syntax.md) — full template grammar, component API, and CLI flags (`--components`, `--theme`).
- [references/routing.md](./references/routing.md) — routing, client navigation, loaders/actions, cache behavior, and navigation pitfalls.
- [references/dotnet-integration.md](./references/dotnet-integration.md) — `Microsoft.WebUI` patterns and integration notes for .NET hosts.
- [references/host-integrations.md](./references/host-integrations.md) — `/_webui/templates` endpoint contract and non-.NET host samples.
- Upstream: <https://github.com/microsoft/webui/blob/main/docs/ai.md>, <https://github.com/microsoft/webui/tree/main/docs/guide>.
