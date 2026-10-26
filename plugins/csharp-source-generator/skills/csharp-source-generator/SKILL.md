---
name: csharp-source-generator
description: "Use when writing, reviewing, debugging, testing, or packaging C# source generators (Roslyn IIncrementalGenerator): pipeline caching and performance, marker attributes, diagnostics, snapshot or cacheability tests, analyzer NuGet packaging, MSBuild/analyzer config options, and interceptors. Also use when the user mentions ForAttributeWithMetadataName, Register*Output APIs, InterceptsLocation, or generated .g.cs output. Not for ordinary C# code, reflection-based serializers, T4 templates, or non-Roslyn code generation."
---

# C# Source Generator Skill

Use this skill to design, implement, review, debug, or test C# source generators. Prefer modern incremental generators, deterministic output, small dependency surfaces, and tests that verify both generated C# and real compiler integration.

## Operating Protocol

1. Identify the intent: create a generator, modify one, review one, debug output, fix packaging/configuration, or add tests.
2. Find the generator entry point, usually an `IIncrementalGenerator`, the referenced `Microsoft.CodeAnalysis.CSharp` version (it decides which APIs are available), and the nearest snapshot, integration, or package test.
3. If the activation model is unclear, ask only for the missing trigger: attribute-driven, syntax-driven, additional-file-driven, analyzer-config-driven, interceptor-driven, or compilation-wide.
4. Do not implement or refactor a generator pipeline until all three are known: the activation trigger, the generated API shape, and the validation strategy.
5. Load the smallest supporting file needed for the task:
	- New generator skeleton: `assets/incremental-generator-template.md`.
	- Generated source formatting: `assets/generated-code-template.md`.
	- Pipeline shape, operators, caching, diagnostics carried through the pipeline, output registrations, or pre-compilation outputs: `references/pipeline-design.md`.
	- Project files, Roslyn version baseline, analyzer package layout, marker attribute distribution, PolySharp, or analyzer dependencies: `references/project-packaging.md`.
	- Snapshot, integration, package, or cacheability tests: `references/testing.md`.
	- MSBuild properties, analyzer config, language version, `.props`/`.targets`, or interceptor namespace opt-in: `references/configuration.md`.
	- Interceptor applicability, Roslyn APIs, generated code shape, or interceptor tests: `references/interceptors.md`.
	- Tracing a rule back to its source article: `references/source-map.md`.
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
- Use `ForAttributeWithMetadataName` (Roslyn 4.4+) for attribute-driven generation. It is roughly 99x cheaper than `CreateSyntaxProvider` because Roslyn indexes attribute names before your predicate runs. Generic attributes use their arity in the metadata name (``"Ns.MyAttribute`1"``).
- Keep syntax predicates purely syntactic and selective. The predicate runs for every node in changed files on every edit; the transform reruns for every selected node on every edit.
- Do not trigger on types that directly or indirectly implement an interface, inherit from a base type, or inherit a marker attribute. These scans cannot be incremental and hurt IDE performance for every user; require an explicit attribute and use an analyzer to enforce other requirements.
- Convert `SyntaxNode`, `ISymbol`, `SemanticModel`, `Compilation`, and `Location` values into small equatable models inside the transform. Symbols are never equatable and root old compilations in memory.
- Use `static` lambdas and forward `CancellationToken` to every Roslyn API that accepts one.
- Extract stable values from high-churn providers before combining. Select `Compilation.AssemblyName` or options from `CompilationProvider`, and read `LanguageVersion` from `ParseOptionsProvider`.
- Register one output per model when each model produces its own file. Use `Collect()` only for genuinely aggregate output; any change to any element reruns everything downstream of it.
- Sort collected symbols, members, attributes, and diagnostics by a stable key before emission.
- Do not use runtime reflection to inspect target application types. Reflection runs against the compiler or IDE host, not the consumer runtime.
- Choose the output registration by who needs to see the code: `RegisterPostInitializationOutput` for fixed source; `RegisterPreCompilationSourceOutput` (experimental, `RSEXPERIMENTAL007`) when source derived from additional files or options must be visible to compilation-dependent stages or other generators; `RegisterSourceOutput` otherwise. Use `RegisterImplementationSourceOutput` only when the code has no semantic effect on user code (for example helpers invoked only by native or external callers); never for partial method implementations or interceptors.

### Models and Diagnostics

- Prefer `readonly record struct` or sealed record models with value equality. Arrays, `List<T>`, and `ImmutableArray<T>` compare by reference; use structural wrappers such as `EquatableArray<T>` / `ImmutableEquatableArray<T>`.
- Treat invalid user input as diagnosable data. Report precise diagnostics at the closest useful location and continue generating valid outputs.
- Prefer shipping a separate analyzer to report diagnostics. Analyzers do not participate in incremental code generation, so they cannot break generator caching or produce stale diagnostics tied to cached pipeline state.
- Only report diagnostics from inside the generator when the diagnostic depends on data the generator has already extracted. Carry cacheable diagnostic data (descriptor, file path, text span, line span, string arguments) in a split pipeline and create `Diagnostic` instances at the output edge.

### Generated Code

- Generated files should start with `// <auto-generated/>` and include `#nullable enable` unless the repository has another convention.
- Generate partial types, extension methods, or additional helper types. Source generators add code; they do not rewrite existing user code or implement new language features.
- Require user types to be `partial` when generated code augments the same type.
- Emit text with raw string literals or an indented writer, not `SyntaxFactory` trees plus `NormalizeWhitespace()`.
- Normalize namespaces, nested type declarations, generic type names, hint names, and line endings so snapshots are stable. Include enough path or namespace information in hint names to avoid collisions.

### Marker Attributes

- When the minimum supported Roslyn is 4.14+ (.NET SDK 9.0.300+), generate marker attributes in `RegisterPostInitializationOutput`, call `AddEmbeddedAttributeDefinition()`, and apply `[global::Microsoft.CodeAnalysis.EmbeddedAttribute]` to avoid `CS0436` across `[InternalsVisibleTo]` projects.
- Use a companion attributes assembly packed into the generator package when older SDKs must be supported or when generated public APIs expose package-defined types.
- Keep marker attributes `sealed`, give them an explicit `AttributeUsage`, and use their fully qualified metadata name in `ForAttributeWithMetadataName`. Consider `[Conditional("...")]` so the marker does not appear in consumer metadata.
- In the transform, read `GeneratorAttributeSyntaxContext.Attributes`; handle both `ConstructorArguments` and `NamedArguments`, and skip targets whose arguments have `TypedConstantKind.Error`.

### Helper Libraries

- `PolySharp` polyfills modern C# language features (records, `init`, required members, collection expressions, etc.) so the generator project can stay on `netstandard2.0` for analyzer host compatibility while writing modern C#. Reference it with `PrivateAssets="all"` so it does not flow to consumers.
- `PolyType.Roslyn` provides reusable building blocks specifically for source generators: `SourceWriter` for indented code emission, and `ImmutableEquatableArray<T>` / `ImmutableEquatableDictionary<TKey, TValue>` / `ImmutableEquatableSet<T>` for collections with structural equality. Prefer these over hand-rolling equivalents unless the repository already has its own implementations.

### Configuration and Compatibility

- Read generator settings through `AnalyzerConfigOptionsProvider`. Global MSBuild properties are exposed as `build_property.<Name>`; values pass through an editorconfig file, so `;`-separated lists need transport encoding.
- Expose custom MSBuild settings with `CompilerVisibleProperty`; package `build/<PackageId>.props` or `.targets` files when a NuGet package should configure this automatically.
- Check `LanguageVersion` before generating syntax that requires newer C# features. Future language versions may appear as enum numeric values unknown to the referenced Roslyn package, and `preview` arrives unmapped as `LanguageVersion.Preview`.
- The referenced `Microsoft.CodeAnalysis.CSharp` version is the consumer's minimum SDK (4.4 → 7.0.100, 4.11 → 8.0.400, 4.14 → 9.0.300). Add multi-Roslyn packaging only when there is a real compatibility requirement; it adds project, package, and test complexity.

### Packaging and Tests

- Target `netstandard2.0`, set `EnforceExtendedAnalyzerRules=true`, pack generator assemblies under `analyzers/dotnet/cs` or version-specific analyzer folders, and set `IncludeBuildOutput=false` so consumers do not reference the generator assembly as a normal library.
- If generated output should be reviewed in source control, use `EmitCompilerGeneratedFiles`, set `CompilerGeneratedFilesOutputPath`, and exclude that output from compilation with `Compile Remove`.
- Test positive generation (including that the updated compilation has no errors), invalid input diagnostics, deterministic ordering, and package layout. Use Verify or the repository's snapshot tool for generated source.
- Add integration tests that reference the generator as an analyzer. For shipped packages, test the `.nupkg` from a local package source with isolated restore packages to avoid local NuGet cache pollution.
- For performance-sensitive generators, add `WithTrackingName` to important pipeline stages, enable `trackIncrementalGeneratorSteps`, and test that a second run on a cloned compilation reuses cached outputs.

## Review Checklist

- The generator is incremental unless there is a documented compatibility reason.
- The trigger is explicit and efficient for the activation model; no indirect interface/base-type scanning.
- Provider outputs are cacheable value models, not Roslyn object graphs or reference-equality collections.
- `Collect` and `Combine` are used only where needed, and never with raw `Compilation`.
- Output is deterministic, nullable-aware, and uses stable hint names.
- Marker attributes have a distribution strategy that fits the Roslyn baseline.
- Diagnostics are stable, precise, and tested.
- Package layout and Roslyn version match analyzer loading rules and the intended minimum SDK.
- Tests include snapshot output, a cacheability check, and at least one compiler integration path.

## References

- `assets/incremental-generator-template.md` for a minimal incremental generator skeleton.
- `assets/generated-code-template.md` for stable generated C# output templates.
- `references/pipeline-design.md` for operators, caching, diagnostics models, output registrations, and pre-compilation outputs.
- `references/project-packaging.md` for project files, Roslyn version baselines, and NuGet analyzer package patterns.
- `references/testing.md` for snapshot, integration, package, and cacheability test guidance.
- `references/configuration.md` for analyzer config, MSBuild properties, language version, and interceptor namespace opt-in.
- `references/interceptors.md` for interceptor use cases, implementation rules, generated code examples, and tests.
- `references/source-map.md` for a map from source articles to the rules in this skill.
- [Incremental Generators](https://github.com/dotnet/roslyn/blob/main/docs/features/incremental-generators.md)
- [Incremental Generators Cookbook](https://github.com/dotnet/roslyn/blob/main/docs/features/incremental-generators.cookbook.md)
- [Pre-Compilation Source Outputs](https://github.com/dotnet/roslyn/blob/main/docs/features/pre-compilation-source-outputs.md)
- [Andrew Lock: Creating a source generator series](https://andrewlock.net/series/creating-a-source-generator/)
- [PolyType.Roslyn API](https://eiriktsarpalis.github.io/PolyType/api/PolyType.Roslyn.html)
