---
name: csharp-source-generator
description: "Use when writing, reviewing, debugging, or testing C# source generators and Roslyn incremental generators. Covers IIncrementalGenerator architecture, SyntaxProvider pipelines, generated-code snapshots with Verify, analyzer packaging, marker attributes, AnalyzerConfigOptionsProvider, SDK compatibility, diagnostics, and performance. Also trigger when the user mentions source generator output, generated C# files, Roslyn analyzers with generators, ForAttributeWithMetadataName, RegisterSourceOutput, RegisterImplementationSourceOutput, RegisterPostInitializationOutput, CompilerVisibleProperty, InterceptsLocation, PolySharp, PolyType.Roslyn, or generator snapshot tests. Do NOT use for ordinary C# application code, runtime reflection serializers, T4 templates, or non-Roslyn code generation tools."
---

# C# Source Generator Skill

Use this skill to design, implement, review, debug, or test C# source generators. Prefer modern incremental generators, deterministic output, small dependency surfaces, and tests that verify both generated C# and real compiler integration.

## Operating Protocol

1. Identify the intent: create a generator, modify one, review one, debug output, fix packaging/configuration, or add tests.
2. Find the generator entry point, usually an `IIncrementalGenerator`, and the nearest snapshot, integration, or package test.
3. If the activation model is unclear, ask only for the missing trigger: attribute-driven, syntax-driven, additional-file-driven, analyzer-config-driven, interceptor-driven, or compilation-wide.
4. Do not implement or refactor a generator pipeline until all three are known: the activation trigger, the generated API shape, and the validation strategy.
5. Load the smallest supporting file needed for the task:
	- New generator skeleton: `assets/incremental-generator-template.md`.
	- Generated source formatting: `assets/generated-code-template.md`.
	- Project files, analyzer package layout, PolySharp, or analyzer dependencies: `references/project-packaging.md`.
	- Snapshot, integration, package, or cacheability tests: `references/testing.md`.
	- MSBuild properties, analyzer config, language version, or interceptor namespace opt-in: `references/configuration.md`.
	- Interceptor applicability, Roslyn APIs, generated code shape, or interceptor tests: `references/interceptors.md`.
	- Cross-cutting practical tips distilled from case studies (consult last; overlaps with the other references): `references/source-generator-practical-guidance.md`.
6. Keep changes deterministic and validate with the narrowest generator, snapshot, integration, package, or build check available.

When complete, return the implemented change or review findings, the validation performed, and any remaining generator risks such as missing diagnostics, unstable ordering, untested package layout, or unverified cacheability.

## Core Priorities

When the rules below compete for attention, prioritize these defaults first:

- Choose incremental generators and cheap activation triggers.
- Flow cacheable, generator-owned value models through providers.
- Emit deterministic, nullable-aware generated source with stable hint names.
- Report precise diagnostics without breaking incremental cacheability.
- Validate with the narrowest snapshot, integration, package, or build check that proves the change.

## Core Rules

### Incremental Pipeline

- Implement new generators with `IIncrementalGenerator`. `Initialize` defines providers only; do not store per-compilation state on the generator instance.
- Use `ForAttributeWithMetadataName` for attribute-driven generation when the supported Roslyn version allows it. It avoids broad syntax scans and reduces IDE work.
- Keep syntax predicates cheap and selective. Predicate code can run for many syntax nodes on every edit.
- Convert `SyntaxNode`, `ISymbol`, `SemanticModel`, `Compilation`, and `Location` values into small equatable models as early as possible. These Roslyn objects usually break incremental caching when carried through providers.
- Use `static` lambdas and honor `CancellationToken` in transforms.
- Extract stable values from high-churn providers before combining. For example, select `Compilation.AssemblyName` or a `LanguageVersion` value before combining with syntax-derived models.
- Sort symbols, members, attributes, diagnostics, generated files, and hint names before emission.
- Do not use runtime reflection to inspect target application types. Reflection runs against the compiler or IDE host, not the consumer runtime.
- Use `RegisterImplementationSourceOutput` instead of `RegisterSourceOutput` when the generated code does not affect the semantic meaning of user code (for example, helpers only invoked by native or external callers). It allows the IDE to defer running the generator until full compilation. Do not use it for partial method implementations or interceptors, which the IDE needs eagerly to avoid spurious errors.

### Models and Diagnostics

- Prefer `readonly record struct` or sealed record models with value equality. Use structural collection wrappers such as `ImmutableEquatableArray<T>` when collections affect caching.
- Treat invalid user input as diagnosable data. Report precise diagnostics at the closest useful location and continue generating valid outputs.
- Prefer shipping a separate analyzer to report diagnostics. Analyzers do not participate in incremental code generation, so they cannot break generator caching or produce stale diagnostics tied to cached pipeline state.
- Only report diagnostics from inside the generator when the diagnostic depends on data the generator has already extracted. In that case, store cacheable diagnostic data such as descriptor, file path, text span, and line span; create `Diagnostic` instances at the output edge.

### Generated Code

- Generated files should start with `// <auto-generated/>` and include `#nullable enable` unless the repository has another convention.
- Generate partial types, extension methods, or additional helper types. Source generators add code; they do not rewrite existing user code.
- Require user types to be `partial` when generated code augments the same type.
- Normalize namespaces, nested type declarations, generic type names, hint names, and line endings so snapshots are stable.

### Marker Attributes

- Prefer marker attributes from a companion runtime/shared assembly when the attribute or helper types are part of the consumer API.
- For generated internal marker attributes, use `RegisterPostInitializationOutput` only for fixed code. On SDKs that support it, add `Microsoft.CodeAnalysis.EmbeddedAttribute` via `AddEmbeddedAttributeDefinition()` and apply it to generated internal marker types to avoid cross-project `CS0436` conflicts.
- Keep marker attributes sealed and use their fully qualified metadata name in `ForAttributeWithMetadataName`.

### Helper Libraries

- `PolySharp` polyfills modern C# language features (records, `init`, required members, collection expressions, etc.) so the generator project can stay on `netstandard2.0` for analyzer host compatibility while writing modern C#. Reference it with `PrivateAssets="all"` so it does not flow to consumers.
- `PolyType.Roslyn` provides reusable building blocks specifically for source generators: `SourceWriter` for indented code emission, and `ImmutableEquatableArray<T>` / `ImmutableEquatableDictionary<TKey, TValue>` / `ImmutableEquatableSet<T>` for collections with structural equality (the equality semantics most BCL collections lack and that are required for cacheable pipeline models). Prefer these over hand-rolling equivalents unless the repository already has its own implementations.

### Configuration and Compatibility

- Read generator settings through `AnalyzerConfigOptionsProvider`. Global MSBuild properties are exposed as `build_property.<Name>`.
- Expose custom MSBuild settings with `CompilerVisibleProperty`; package `.props` or `.targets` files when a NuGet package should configure this automatically.
- Check `CSharpCompilation.LanguageVersion` before generating syntax that requires newer C# features. Future language versions may appear as enum numeric values even when the generator was compiled against an older Roslyn package.
- Add multi-Roslyn or multi-SDK packaging only when there is a real compatibility requirement; it adds project, package, and test complexity.

### Packaging and Tests

- Pack generator assemblies under `analyzers/dotnet/cs` or version-specific analyzer folders. Set `IncludeBuildOutput=false` so consumers do not reference the generator assembly as a normal library.
- If generated output should be reviewed in source control, use `EmitCompilerGeneratedFiles`, set `CompilerGeneratedFilesOutputPath`, and exclude that output from compilation with `Compile Remove`.
- Test positive generation, invalid input diagnostics, deterministic ordering, and package layout. Use Verify or the repository's snapshot tool for generated source.
- Add integration tests that reference the generator as an analyzer. For shipped packages, test the `.nupkg` from a local package source with isolated restore packages to avoid local NuGet cache pollution.
- For performance-sensitive generators, add `WithTrackingName` to important pipeline stages and test that unchanged inputs are cached across equivalent generator runs.

## Review Checklist

- The generator is incremental unless there is a documented compatibility reason.
- The trigger is explicit and efficient for the activation model.
- Provider outputs are cacheable value models, not Roslyn object graphs.
- Output is deterministic, nullable-aware, and uses stable hint names.
- Marker attributes have a clear distribution strategy.
- Diagnostics are stable, precise, and tested.
- Package layout matches analyzer loading rules.
- Tests include snapshot output and at least one compiler integration path.

## References

- `assets/incremental-generator-template.md` for a minimal incremental generator skeleton.
- `assets/generated-code-template.md` for stable generated C# output templates.
- `references/project-packaging.md` for source generator project and NuGet analyzer package patterns.
- `references/testing.md` for snapshot, integration, package, and cacheability test guidance.
- `references/configuration.md` for analyzer config, MSBuild properties, language version, and interceptor namespace opt-in.
- `references/interceptors.md` for interceptor use cases, implementation rules, generated code examples, and tests.
- `references/source-generator-practical-guidance.md` for distilled practical guidance from source generator case studies.
- [Incremental Generators](https://github.com/dotnet/roslyn/blob/main/docs/features/incremental-generators.md)
- [Incremental Generators Cookbook](https://github.com/dotnet/roslyn/blob/main/docs/features/incremental-generators.cookbook.md)
- [PolyType.Roslyn API](https://eiriktsarpalis.github.io/PolyType/api/PolyType.Roslyn.html)