# Pipeline Design

Use this when designing or reviewing the shape of an incremental pipeline: choosing inputs and operators, deciding what is cacheable, picking an output registration, or carrying diagnostics through the pipeline.

## Contents

- Execution model
- Input providers
- Operators and their caching cost
- `ForAttributeWithMetadataName` details
- Triggers to avoid
- Models and equality
- Diagnostics as cacheable data
- Output registrations
- Pre-compilation source outputs (experimental)
- Cancellation

## Execution Model

- `Initialize` runs once per generator instance and only builds the pipeline graph.
- Syntax `predicate` runs for every syntax node in changed trees, on every edit. Keep it purely syntactic and selective.
- Syntax `transform` reruns for every node the predicate selected, in all files, on every edit, because a change in one file can change semantics in another.
- Later stages run only for new or changed values. A stage whose output equals the previous run's output stops propagation; this is where caching pays off.
- More stages mean more cache checkpoints. Extract small values early and transform in several cheap steps rather than one large step.

## Input Providers

| Provider | Changes when | Notes |
| --- | --- | --- |
| `SyntaxProvider.ForAttributeWithMetadataName` | Attributed syntax or semantics change | Preferred trigger. |
| `SyntaxProvider.CreateSyntaxProvider` | Any syntax edit | Only for non-attribute triggers. |
| `AdditionalTextsProvider` | An additional file changes | Per-file values. Filter by path first. |
| `AnalyzerConfigOptionsProvider` | `.editorconfig` / `.globalconfig` / MSBuild-visible properties change | Rarely changes. |
| `ParseOptionsProvider` | Language version, preprocessor symbols, features change | Rarely changes; prefer it over `CompilationProvider` for `LanguageVersion`. |
| `MetadataReferencesProvider` | References change | Per-reference values. |
| `CompilationProvider` | Every edit | Always `Select` a small value before combining. |

## Operators and Their Caching Cost

- `Select`: 1-to-1. Cheapest checkpoint; use it liberally to narrow values.
- `Where`: filter. Put it as early as possible (for example on file extension).
- `SelectMany`: 1-to-many, such as expanding one additional file into several elements.
- `Collect`: turns many values into one `ImmutableArray<T>`. Any change to any element produces a new array, so everything downstream reruns. Use only when the output genuinely aggregates (one registry file), and `Select` it into an equatable wrapper if more stages follow.
- `Combine`: pairs values. `values.Combine(value)` reruns every pair when the single value changes, so combine with the smallest possible value. Never combine with raw `Compilation`; select `AssemblyName`, options, or a flag first.
- `WithComparer`: supplies an `IEqualityComparer<T>` for one stage. Prefer making models inherently equatable; use a comparer only when that is impossible.
- `WithTrackingName`: names a stage for `GeneratorDriverRunResult.TrackedSteps`; required for cacheability tests.

```csharp
// Bad: reruns output for every additional file on every keystroke.
var combined = context.AdditionalTextsProvider.Combine(context.CompilationProvider);

// Good: only reruns when the assembly name changes.
var assemblyName = context.CompilationProvider.Select(static (c, _) => c.AssemblyName);
var combined = context.AdditionalTextsProvider.Combine(assemblyName);
```

## `ForAttributeWithMetadataName` Details

- Requires `Microsoft.CodeAnalysis.CSharp` 4.4+ (.NET 7 SDK). Roslyn indexes attribute names so ~99% of syntax never reaches your predicate; real-world measurements show it is roughly 99x more efficient than `CreateSyntaxProvider`.
- Pass the metadata name without assembly. Generic attributes use arity: `My.Namespace.MyAttribute<T>` becomes ``"My.Namespace.MyAttribute`1"``.
- When `AttributeUsage` already restricts targets, the predicate can be `static (_, _) => true`.
- In the transform, use `context.TargetSymbol`, `context.TargetNode`, `context.SemanticModel`, and `context.Attributes` (the matching `AttributeData` instances) instead of re-scanning `GetAttributes()`.
- Read attribute data from both `ConstructorArguments` (positional) and `NamedArguments` (property setters). Bail out when any `TypedConstant.Kind == TypedConstantKind.Error`; the user is mid-edit.

## Triggers to Avoid

These cannot be computed incrementally and force work across every type in the compilation, on every edit:

- Finding types that implement a marker interface directly or indirectly.
- Finding types that inherit, directly or indirectly, from a generator-defined base type.
- Finding types whose base types or interfaces carry a marker attribute.
- Unsealed marker attributes that users subclass to customize behavior. Every attributed type must be checked for inheritance, and values passed to the base constructor are invisible to the generator.

Instead, require an explicit marker attribute on the target and write an analyzer that tells users when they also need a base type or interface.

## Models and Equality

- Use `record` / `readonly record struct` models made of strings, primitives, enums, and other equatable models.
- Never store `ISymbol` (never equatable, and it roots whole compilations in memory). Avoid `SyntaxNode`, `Location`, `SemanticModel`, and `Compilation`.
- Arrays, `List<T>`, and `ImmutableArray<T>` compare by reference. Wrap them in a structural type such as `EquatableArray<T>` (CommunityToolkit pattern) or `PolyType.Roslyn`'s `ImmutableEquatableArray<T>`.
- `netstandard2.0` has no `System.HashCode`; vendor a small implementation or use one from a helper package when implementing `GetHashCode`.
- One exception: reading per-tree `AnalyzerConfigOptions` needs the `SyntaxTree`. Combine, read the option, and drop the tree in the very next `Select`.

## Diagnostics as Cacheable Data

Prefer a separate `DiagnosticAnalyzer`; it never affects generator caching. When the generator must report diagnostics, carry plain data and create `Diagnostic` only at the output edge, in a pipeline split from source generation. `EquatableArray<T>` below stands for whatever structural array wrapper the repository uses.

```csharp
internal sealed record LocationInfo(string FilePath, TextSpan TextSpan, LinePositionSpan LineSpan)
{
    public Location ToLocation() => Location.Create(FilePath, TextSpan, LineSpan);

    public static LocationInfo? From(Location location)
        => location.SourceTree is null
            ? null
            : new LocationInfo(location.SourceTree.FilePath, location.SourceSpan, location.GetLineSpan().Span);
}

// DiagnosticDescriptor implements IEquatable<DiagnosticDescriptor>.
// Message arguments must be strings or other equatable values, never symbols.
internal sealed record DiagnosticInfo(DiagnosticDescriptor Descriptor, LocationInfo? Location, EquatableArray<string> MessageArgs)
{
    public Diagnostic ToDiagnostic()
        => Diagnostic.Create(Descriptor, Location?.ToLocation(), MessageArgs.ToArray());
}

internal sealed record Result<TValue>(TValue? Value, EquatableArray<DiagnosticInfo> Diagnostics)
    where TValue : IEquatable<TValue>?;
```

```csharp
IncrementalValuesProvider<Result<MyModel>> results = /* FAWMN transform returning Result<MyModel> */;

context.RegisterSourceOutput(
    results.SelectMany(static (r, _) => r.Diagnostics),
    static (spc, info) => spc.ReportDiagnostic(info.ToDiagnostic()));

context.RegisterSourceOutput(
    results.Where(static r => r.Value is not null).Select(static (r, _) => r.Value!),
    static (spc, model) => Emit(spc, model));
```

## Output Registrations

Execution order: post-initialization → pre-compilation (experimental) → standard outputs.

| Registration | Inputs | Added to the compilation other stages see? | Use for |
| --- | --- | --- | --- |
| `RegisterPostInitializationOutput` | None | Yes | Fixed source: marker attributes, `AddEmbeddedAttributeDefinition()`. |
| `RegisterPreCompilationSourceOutput` | Non-compilation providers only | Yes | Types derived from additional files / options that later stages or other generators must bind to. |
| `RegisterSourceOutput` | Any | No (final output only) | Normal generated code and diagnostics. |
| `RegisterImplementationSourceOutput` | Any | No | Code with no semantic impact on user code (only called from native/external code). The IDE may skip it. Not for partial method implementations or interceptors. |

Generators never see each other's `RegisterSourceOutput` results; all generators receive the same input compilation.

## Pre-Compilation Source Outputs (Experimental)

`RegisterPreCompilationSourceOutput` adds generated source to the *initial* compilation before compilation-dependent stages run, while still reading `AdditionalTextsProvider`, `AnalyzerConfigOptionsProvider`, and `ParseOptionsProvider`.

- Marked `[Experimental]`; suppress `RSEXPERIMENTAL007` only around the call. The compiler in .NET SDK 10.0.4xx (Roslyn 5.9) contains it, but it is new and may change: confirm the referenced `Microsoft.CodeAnalysis.CSharp` version exposes it, raise the package's minimum SDK accordingly (or ship it only in a version-specific analyzer folder), and keep a fallback for older SDKs.
- Its value provider must not depend on `CompilationProvider` or `SyntaxProvider`. This is enforced at runtime only: the generator enters an error state, reports a diagnostic, and its standard phase is skipped.
- `PreCompilationSourceProductionContext` has `AddSource` but no `ReportDiagnostic`; report problems from an analyzer.
- Output is visible to this generator's and every other generator's standard phase (`compilation.GetTypeByMetadataName(...)` finds it), and it appears in `GeneratorRunResult.GeneratedSources`. The tracked step name is `PreCompilationSourceOutput`.
- Good fits: `.proto`/schema files that become C# types other code binds to; marker attributes whose shape depends on MSBuild options (configurable post-init); replacing a private intermediate compilation inside the generator.

```csharp
#pragma warning disable RSEXPERIMENTAL007
var protoFiles = context.AdditionalTextsProvider
    .Where(static f => f.Path.EndsWith(".proto", StringComparison.OrdinalIgnoreCase));

context.RegisterPreCompilationSourceOutput(protoFiles, static (ctx, file) =>
{
    string code = ProtoToCSharp(file.GetText(ctx.CancellationToken)!.ToString());
    ctx.AddSource($"{Path.GetFileName(file.Path)}.g.cs", code);
});
#pragma warning restore RSEXPERIMENTAL007

// Standard phase sees the types emitted above.
context.RegisterSourceOutput(
    context.CompilationProvider.Select(static (c, _) => c.GetTypeByMetadataName("MyProto.Message") is not null),
    static (ctx, hasMessage) => { /* ... */ });
```

## Cancellation

- Forward the provided `CancellationToken` to every Roslyn API that accepts one (`GetText`, `GetDeclaredSymbol`, `GetOperation`, `GetInterceptableLocation`, ...).
- In loops over collected values, call `cancellationToken.ThrowIfCancellationRequested()` periodically. Do not try to save partial results; let the host rerun the stage.
