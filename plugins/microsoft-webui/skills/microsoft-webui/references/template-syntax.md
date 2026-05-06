# WebUI Template Syntax and CLI — Full Reference

## Table of Contents
- [The `<template>` wrapper](#the-template-wrapper)
- [Bindings](#bindings)
- [Conditionals](#conditionals)
- [Loops](#loops)
- [Attributes](#attributes)
- [Events](#events)
- [DOM refs](#dom-refs)
- [Component class API](#component-class-api)
- [State JSON and truthiness](#state-json-and-truthiness)
- [CLI: build, serve, inspect](#cli-build-serve-inspect)
- [`--components` external sources](#--components-external-sources)
- [`--theme` design tokens](#--theme-design-tokens)

## The `<template>` wrapper

`<template shadowrootmode="open">` is **optional** — the build tool injects it when absent. Include it explicitly only when you need root-host events:

```html
<template shadowrootmode="open"
  @toggle-item="{onToggleItem(e)}"
  @delete-item="{onDeleteItem(e)}">
  <for each="item in items">
    <todo-item id="{{item.id}}"></todo-item>
  </for>
</template>
```

This is the delegated event pattern for parent↔child communication.

## Bindings

| Form | Behavior |
|---|---|
| `{{expr}}` | HTML-escaped output (safe for user input). |
| `{{{expr}}}` | Raw output — **never use for user input or URL params**; an attacker can inject `<script>`. Only for server-sanitized HTML. |

Path lookups only — no arithmetic, no function calls. If you need `{{currentIndex + 1}}`, store it as an `@observable` or precompute it in SSR state.

Supported path forms (resolved by `find_value_by_dotted_path`):

| Pattern | Example | Resolves to |
|---|---|---|
| Simple property | `title` | `"My App"` |
| Nested property | `user.profile.avatar` | `"/img/alice.png"` |
| Array index (integer segment) | `items.0.label` | first item's `label` |
| Array length | `items.length` | element count |

Missing paths render empty (text/attrs) or evaluate to `false` (`<if>`) — no error is raised.

## Conditionals

```html
<if condition="isLoggedIn">…</if>
<if condition="!hasItems">…</if>
<if condition="status == 'active'">…</if>
```

Operators: `==`, `!=`, `<`, `<=`, `>`, `>=`, `&&`, `||`, `!`.

Constraints:
- Max 5 logical operators per expression.
- Cannot mix `&&` and `||` in the same expression.
- No parentheses, no ternary.

## Loops

```html
<for each="item in items">
  <div>{{item.name}} — {{item.price}}</div>
</for>
```

- Collection must be a JSON array.
- Global state remains accessible alongside the loop moniker (e.g. `{{user.name}}` works inside `<for each="item in items">`).
- Nested loops: every active outer moniker stays in scope. An inner moniker may shadow a **global** state key, but cannot shadow an **outer loop** moniker.
- **Components inside loops do NOT inherit loop variables.** Pass data via attributes:

```html
<for each="category in categories">
  <h2>{{category.name}}</h2>
  <for each="product in category.products">
    <!-- category.* still in scope; title resolves from global state -->
    <p>{{title}} — {{category.name}}: {{product.name}}</p>
  </for>
</for>

<for each="contact in contacts">
  <contact-card name="{{contact.name}}" email="{{contact.email}}"></contact-card>
</for>
```

## Attributes

```html
<a href="{{url}}">{{linkText}}</a>

<button ?disabled="{{isLoading}}">Submit</button>
<input type="checkbox" ?checked="{{isSelected}}" />

<!-- Booleans accept the same expressions as <if> -->
<button ?disabled="{{currentIndex == 0}}">Prev</button>
<option ?selected="{{item.id == selectedId}}">{{item.name}}</option>

<!-- Mixed static + dynamic -->
<img src="/img/{{user.avatar}}" alt="{{user.name}}" />

<!-- Property binding (object/array) -->
<my-widget :config="{{settings}}"></my-widget>
```

## Events

```html
<button @click="{handleClick()}">Click</button>
<input @keydown="{onKeydown(e)}" />
<div @mouseenter="{onHover()}" @mouseleave="{onLeave()}">…</div>
```

Template handlers cannot pass loop-scope arguments. Use a child component that `$emit`s:

```html
<for each="item in items">
  <list-item id="{{item.id}}" text="{{item.text}}"
    @remove-item="{onRemove(e)}">
  </list-item>
</for>
```

## DOM refs

```html
<input w-ref="searchInput" type="text" />
```

```typescript
searchInput!: HTMLInputElement;
```

Use only for imperative DOM access (focus, scroll, measure). Never for reactive state.

Routing and client navigation now live in [routing.md](./routing.md). Load that file for `<route>`, `<outlet>`, `Router.start`, `Router.navigate`, `Router.ensureLoaded`, loaders/actions, cache tags, pending/error, and navigation pitfalls.

## Component class API

```typescript
import { WebUIElement, attr, observable } from '@microsoft/webui-framework';

export class MyComponent extends WebUIElement {
  @attr label = 'Default';                          // string attribute
  @attr({ mode: 'boolean' }) disabled = false;      // boolean attribute
  @observable count = 0;                            // reactive state
  @observable items: Item[] = [];

  inputEl!: HTMLInputElement;                       // populated by w-ref="inputEl"

  onSubmit(): void {
    const text = this.inputEl.value.trim();
    if (!text) return;
    this.items = [...this.items, { id: crypto.randomUUID(), text, price: 0 }];
    this.inputEl.value = '';
  }

  onItemDelete(e: CustomEvent<{ id: string }>): void {
    this.items = this.items.filter(i => i.id !== e.detail.id);
  }
}

MyComponent.define('my-component');
```

| Decorator / API | Purpose | SSR? | Triggers DOM update? |
|---|---|---|---|
| `@attr` | HTML attribute reflection | Yes (from JSON state) | Yes |
| `@attr({ mode: 'boolean' })` | Boolean attribute | Yes | Yes |
| `@observable` | Reactive internal state | Yes (from JSON state) | Yes |
| `this.$emit(name, detail?)` | Dispatch bubbling `CustomEvent` | — | — |
| `this.$update()` | Force a reactive update cycle | — | — |
| `this.$flushUpdates()` | Synchronously flush pending updates | — | — |
| `setState(state)` | Populated by router navigation | — | Yes |
| `static define(tagName)` | Register custom element | — | — |

Child→parent custom event. `$emit` accepts a `CustomEventInit` — payload goes inside `detail`:

```typescript
// child
this.$emit('item-selected', { detail: { id: this.id, name: this.name } });
```

```html
<!-- parent template -->
<child-component @item-selected="{onItemSelected(e)}"></child-component>
```

```typescript
// parent
onItemSelected(e: CustomEvent<{ id: string; name: string }>): void {
  this.selectedId = e.detail.id;
}
```

## State JSON and truthiness

```json
{
  "title": "My App",
  "user": { "name": "Alice", "role": "admin" },
  "items": [{ "id": "1", "label": "First", "done": false }],
  "isAdmin": true
}
```

Path resolution: `title`, `user.name`, `items.0.label`, `items.length`. Missing paths render empty / evaluate to false — no error.

Truthiness:

| Value | Truthy? |
|---|---|
| `true` | Yes |
| `false` | No |
| `0` | No |
| Non-zero number | Yes |
| `""` | No |
| `"false"` (string!) | **Yes** |
| `null` / missing | No |

**Always use real booleans** for boolean state.

## CLI: build, serve, inspect

```bash
webui build  ./src --out ./dist --plugin=webui
webui serve  ./src --state ./data/state.json --plugin=webui --watch
webui inspect ./dist/protocol.bin
```

Selected flags (apply to both `build` and `serve` unless noted):

| Flag | Default | Description |
|---|---|---|
| `--out <DIR>` | required (build) | Output directory. |
| `--entry <FILE>` | `index.html` | Entry HTML. |
| `--css <MODE>` | `link` | `link` / `style` / `module`. |
| `--dom <MODE>` | `shadow` | `shadow` / `light`. |
| `--plugin <NAME>` | none | `webui` or `fast-v3`. |
| `--components <PKG>` | none | Repeatable; external component sources. |
| `--state <FILE>` | required (serve) | JSON state file. |
| `--port <PORT>` | `3000` | Dev server port. |
| `--watch` | false | Live reload. |
| `--servedir <DIR>` | none | Static asset directory. |
| `--api-port <PORT>` | none | Proxy route requests to API server. |
| `--theme <PKG>` | none | Design token theme (serve only). |

## `--components` external sources

Accepts:
- npm package name: `@scope/my-button` or `my-button`
- Scoped prefix: `@scope` discovers all packages under `node_modules/@scope/`
- Local path: `./shared/components`, `/libs/ui-kit` (anything starting with `.`, `/`, `\`, or a drive letter)

npm package `package.json` requirements:

```json
{
  "name": "@scope/my-button",
  "customElements": "./custom-elements.json",
  "exports": {
    "./template-webui.html": "./dist/template-webui.html",
    "./styles.css":          "./dist/styles.css"
  }
}
```

| Field | Required | Purpose |
|---|---|---|
| `exports["./template-webui.html"]` | Yes | Component template. |
| `exports["./styles.css"]` | No | Component CSS. |
| `customElements` | Yes | Custom Elements Manifest path (provides tag name). |

Local-path scanning works the same as the app folder. npm results are cached at `~/.webui/cache/components/` and invalidated on `package.json` changes; local paths are always re-scanned.

```bash
webui build ./src --out ./dist \
  --components @reactive-ui \
  --components ./shared/components
```

## `--theme` design tokens

Serve-only flag. Loads a JSON token file, filters to tokens actually used in CSS (`var(--name)`), expands transitive references, and injects per-theme CSS declarations into render state as `state.tokens.<name>`.

Multi-theme:

```json
{
  "themes": {
    "light": { "surface-page": "#ffffff", "text-primary": "#111827" },
    "dark":  { "surface-page": "#171717", "text-primary": "#fafafa" }
  }
}
```

Flat (single theme, treated as `"default"`):

```json
{ "surface-page": "#ffffff", "text-primary": "#111827" }
```

Inject in template via comment-based signal:

```html
<style>
  :root { <!--{{{tokens.light}}}--> }
</style>
```
