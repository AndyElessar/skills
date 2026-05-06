# WebUI Component Triplet Template

Use this template when creating a new WebUI component. Replace placeholders like `{component-name}` and `{ClassName}` before returning files to the user.

## Folder Layout

```text
src/{component-name}/
|-- {component-name}.html
|-- {component-name}.css
`-- {component-name}.ts    # Only when the component needs client-side interactivity
```

## `{component-name}.html`

Keep templates declarative. Omit `<template shadowrootmode="open">` unless you need root host events.

```html
<h2>{{title}}</h2>

<if condition="items.length">
  <ul>
    <for each="item in items">
      <li>
        <span>{{item.label}}</span>
        <span ?hidden="{{!item.locked}}">Locked</span>
      </li>
    </for>
  </ul>
</if>

<if condition="!items.length">
  <p class="empty">No items.</p>
</if>

<button ?disabled="{{disabled}}" @click="{onRefresh()}">Refresh</button>
```

Template handlers cannot depend on loop variables being passed as arguments. If an interaction needs an item id, prefer a child component that receives the id as an attribute and emits a `CustomEvent` with the id in `detail`.

## `{component-name}.css`

Styles are scoped by the component boundary. Use `:host` for the component root.

```css
:host {
  display: block;
  padding: 1rem;
}

:host([variant="primary"]) {
  background: var(--colorBrandBackground);
}

.empty {
  opacity: 0.6;
}
```

## `{component-name}.ts`

Add this file only for interactive components. Extend `WebUIElement`, declare reactive state, and register the tag with `static define()`.

```typescript
import { WebUIElement, attr, observable } from '@microsoft/webui-framework';

interface Item {
  id: string;
  label: string;
  locked: boolean;
}

export class {ClassName} extends WebUIElement {
  @attr title = 'Items';
  @attr({ mode: 'boolean' }) disabled = false;
  @observable items: Item[] = [];

  onRefresh(): void {
    this.$emit('{event-name}', { detail: { source: '{component-name}' } });
  }
}

{ClassName}.define('{component-name}');
```

Then import the component module from the hydration entry so it registers:

```typescript
import './{component-name}/{component-name}.js';
```

## Static Variant

For static content, read-only displays, and link-only navigation, create only `{component-name}.html` and `{component-name}.css`. Do not add a `.ts` file unless the user can interact with the component after first paint.
