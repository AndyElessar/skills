# WebUI Routing and Client Navigation

This reference covers route declaration, client navigation, loaders/actions, cache behavior, and routing-specific pitfalls.

## Route Tree

Declare the full route tree in the entry HTML, usually `src/index.html`. Do not spread `<route>` directives across leaf component templates.

```html
<route path="/" component="app-shell">
  <route path=""           component="home-page"   exact />
  <route path="users"      component="user-list"   exact />
  <route path="users/:id"  component="user-detail" exact />
</route>
```

`<outlet />` is where the matched child route mounts:

```html
<nav>…</nav>
<main><outlet /></main>
```

## Matching Rules

- Child paths are relative to the parent. Do not add a leading `/` to nested routes.
- Use `exact` on leaf routes.
- Omit `exact` on parent routes that host an `<outlet />` and should act as prefix matches.
- Path params: `:id` required, `:slug?` optional, `*rest` catch-all.

Route specificity:

- Static segments beat params.
- Params beat optional params.
- Catch-all routes are last.
- `exact` means the whole remaining path must match.

## Route Attributes

| Attribute | Purpose |
| --- | --- |
| `query` | Allowlisted query params exposed as component attributes. Unlisted query params are dropped. |
| `keep-alive` | Preserve DOM and local state across navigations. |
| `cache-tags` | Attach resolved cache tags to the route response. |
| `invalidates` | Invalidate cache tags after an action completes. |
| `pending` | Show a loading component on slower navigations. |
| `error` | Render an error boundary component. |

These attributes are compiled at build time. Do not expect to read `query`, `keep-alive`, `cache-tags`, or `invalidates` back from runtime DOM attributes.

## State Flow

- Default navigation applies server state through `setState(state)`.
- `keep-alive` preserves local DOM state and skips `setState()` on reactivation.
- `keep-alive` plus `static loader()` preserves DOM but refreshes route data.
- `static loader({ params, query, signal })` runs before commit and falls back to server state on failure.
- On first SSR bootstrap, `Router.start({ ssrFresh: true })` skips loader replay by default.
- Add `static ssrLoader = true` only when the first hydrated load must also run the loader.

Use this rule of thumb:

- Server already has the right state: no loader.
- Client must fetch route data: `static loader()`.
- Keep DOM state between visits: `keep-alive`.
- Keep DOM state and refresh data: `keep-alive` plus `static loader()`.

## Router.start

```typescript
Router.start({
  loaders: {
    'user-list': () => import('./pages/user-list.js'),
    'user-detail': () => import('./pages/user-detail.js'),
  },
  preload: true,
  ssrFresh: true,
  cache: {
    staleTime: 30_000,
    gcTime: 300_000,
    maxEntries: 50,
  },
  templateEndpoint: '/_webui/templates',
});
```

Important distinctions:

- `Router.start({ loaders })` is the lazy component-module map. It is not the same thing as a component's `static loader()`.
- Components not listed in `loaders` are eagerly loaded.
- Each lazy component loader runs at most once.
- On the SSR initial load, lazy imports are skipped because the content is already rendered.
- `preload: true` speculatively fetches on link hover.
- Cached navigations and keep-alive reactivation skip pending UI flashes.

## Client Navigation Lifecycle

For client-side navigation:

1. A link click or `Router.navigate(path)` starts navigation.
2. The router intercepts navigation via the browser Navigation API.
3. The client requests a partial response with `Accept: application/json` or `application/x-ndjson`.
4. The server returns the matched route chain. The client does not perform route matching itself.
5. The router finds the first changed level and only remounts that slice. Unchanged parents stay mounted.

This is why server routing correctness, partial-response shape, and cache tags matter to client navigation.

## Programmatic Navigation

Use `Router.navigate(path)` when navigation is triggered by code instead of a normal link.

```typescript
Router.navigate('/users/42');
```

Good uses:

- redirect after an action
- retry the current route
- next/back in a wizard
- drill into a selected record

Prefer normal `<a href="...">` links in templates for ordinary navigation.

## View Transitions

- Router-driven navigation already uses `document.startViewTransition()` when the browser supports it. Treat this as built-in progressive enhancement, not as extra setup work you need to duplicate.
- Customize transitions with CSS: assign stable `view-transition-name` values to the elements you want to animate, then style the related `::view-transition-*` pseudo-elements.
- Use `updateCallbackDone` when you need to know that the DOM update for the navigation has committed.
- Use `finished` only when you need to wait for the visual animation to end.
- Do not make navigation correctness depend on the transition. Unsupported browsers must still navigate correctly.
- Keep transition targeting narrow and stable. Avoid spraying `view-transition-name` across large or frequently changing subtrees.

## Dynamic Component Loading

Use `Router.ensureLoaded(...)` when a component is in the route graph but not in the current matched branch and you want to load its template payload before showing it.

```typescript
await Router.ensureLoaded('settings-dialog');
await import('./settings-dialog/settings-dialog.js');
this.showSettings = true;
```

Use this to avoid a flash of unstyled or missing content when opening dialogs, drawers, or other route-declared components on demand.

## Mutation Actions

`static action({ formData, params, signal })` is the write-side counterpart to `static loader()`.

- Router actions only handle same-origin form submissions that stay in `_self`.
- External form `action` URLs or other targets bypass router action handling.
- After action completion, the router merges returned invalidation tags with the route's `invalidates` attribute.
- The router dispatches `webui:route:action-complete` on `window` after the action flow completes.

## Pending, Error, Cache

- `pending` is for slower navigations. Fast navigations should not flash a loading state.
- `pending` is skipped for keep-alive reactivation.
- `pending` is skipped for cached navigations.
- `error` should point to a real component; missing references are compile errors.
- Cache tags are resolved from the full matched chain, not just the leaf route.

## Best Practices

- Keep route policy declarative in HTML instead of rebuilding it in runtime code.
- Use `query` as an allowlist. Do not pass arbitrary query params through to component state.
- Reach for `keep-alive` only when preserving local state is valuable enough to justify retained DOM.
- Prefer `static loader()` over ad hoc fetches in lifecycle code when the data is route-owned.
- Return scoped route state, not the entire app state, for both first paint and partial navigation.
- Use `Router.navigate()` only for imperative flows; use links for ordinary navigation.

## Anti-Patterns

- Do not confuse `Router.start({ loaders })` with `static loader()`. One lazy-loads component modules; the other fetches route data.
- Do not expect route attributes like `keep-alive` or `invalidates` to be readable from runtime DOM.
- Do not wrap `Router.navigate()` in your own `document.startViewTransition()` call.
- Do not add `pending` to flows that are already instant because of cache or keep-alive.
- Do not force every route through `keep-alive`; preserved DOM has a memory cost.
- Do not use router actions for forms that intentionally post to external URLs or non-`_self` targets.
