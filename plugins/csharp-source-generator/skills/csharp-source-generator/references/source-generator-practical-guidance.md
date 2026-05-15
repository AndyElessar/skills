# Source Generator Practical Guidance

Use this file for source generator tasks that need practical design, testing, packaging, performance, or compatibility guidance.

## Design Guidance

- Build the pipeline as syntax filtering, semantic extraction, value-model transformation, then emission. Each layer gives Roslyn another cache boundary.
- Prefer `ForAttributeWithMetadataName` for attribute-driven generators on Roslyn 4.4+ / .NET 7+ SDK support. Use `CreateSyntaxProvider` only when the trigger is not attribute-driven or compatibility requires it.
- Extract all data needed from syntax and semantic APIs inside the transform. Downstream providers should receive equatable generator-owned models.
- Avoid `SyntaxNode`, `ISymbol`, `SemanticModel`, `Compilation`, `Location`, and ordinary collections as provider output values. If the provider output cannot compare by value, downstream work usually reruns on every edit.
- Use record models and structural collection wrappers. `ImmutableArray<T>` equality is not structural by contents, so wrap collections when cacheability matters.
- If a pipeline needs `CompilationProvider`, select a small stable value first, such as assembly name, options, platform, optimization level, or language version.
- Prefer reporting diagnostics from a separate analyzer rather than from the generator. Analyzers do not participate in incremental code generation and cannot break generator cacheability. Only report diagnostics inside the generator when the diagnostic depends on data the generator has already extracted; in that case, flow a lightweight diagnostic model and reconstruct `Diagnostic` at the reporting edge.
- Use `RegisterImplementationSourceOutput` instead of `RegisterSourceOutput` when the generated code does not change the semantic meaning of user code (for example, AOT helpers only invoked by native or external code). It allows the IDE to defer execution until full compilation. Do not use it for partial method implementations or interceptors.
- Avoid runtime reflection in generators. It inspects the compiler host runtime, not the target application's runtime.

## Marker Attributes

- A generated internal marker attribute is convenient but can produce `CS0436` conflicts when multiple generated assemblies expose internals across project references.
- If the marker attribute or helper types are part of the consumer-facing API, prefer a shared runtime/attributes assembly packed with the generator package.
- If the marker attribute is only an internal trigger and the minimum SDK supports Roslyn 4.14+, generate `Microsoft.CodeAnalysis.EmbeddedAttribute` with `AddEmbeddedAttributeDefinition()` and apply `[global::Microsoft.CodeAnalysis.EmbeddedAttribute]` to the generated marker attribute.
- Keep generated marker attributes fixed, sealed, and fully qualified. Use `RegisterPostInitializationOutput` for fixed marker source, not for compilation-dependent source.

## Testing Strategy

- Snapshot tests are a good fit because generators should produce deterministic output for fixed input. Snapshot generated trees and diagnostics, not entire compiler state.
- Integration tests should reference the generator as an analyzer so the generator runs during compilation and generated code is compiled and executable.
- Package tests should install the built `.nupkg` from a local package source. Use a custom NuGet config and isolated package restore folder to avoid accidentally testing stale packages from the global cache.
- For cacheability tests, add `WithTrackingName` to important provider stages, run the generator twice with equivalent compilations, and assert tracked outputs are cached, equal, and free of problematic types such as `Compilation`.

## Packaging and Output

- Analyzer packages should place generator DLLs under `analyzers/dotnet/cs` or version-specific analyzer folders such as `analyzers/dotnet/roslyn4.11/cs`.
- Set `IncludeBuildOutput=false` so the generator DLL is not referenced as a normal library by consumers.
- If the generator needs runtime-visible attribute/helper types, pack that assembly under `lib/<tfm>` and, when the generator also needs it at analyzer runtime, pack a copy beside the analyzer DLL.
- To review generated output in source control, set `EmitCompilerGeneratedFiles=true` and `CompilerGeneratedFilesOutputPath`. Exclude emitted `.cs` files from compilation with `Compile Remove` to avoid duplicate definitions.
- For multi-targeted consumer projects where generator output differs by target framework, include `$(TargetFramework)` in `CompilerGeneratedFilesOutputPath`.

## Configuration and Language Version

- Read MSBuild properties via `AnalyzerConfigOptionsProvider.GlobalOptions` using the `build_property.` prefix.
- Expose custom settings with `CompilerVisibleProperty`. Package a `.props` file to make the property visible automatically for NuGet consumers.
- Use `.targets` when a package must derive one MSBuild setting from another after consumer props have been evaluated, such as appending to `InterceptorsNamespaces` when a generator-specific property is enabled.
- Read C# language version from `CSharpCompilation.LanguageVersion` when generated code depends on newer syntax. Do not assume the enum only contains values known at generator compile time; compare numeric values when necessary.

## Interceptors and SDK Compatibility

- Interceptors replace method calls at compile time and require explicit consumer opt-in through `InterceptorsNamespaces` or related preview properties. Generate them only when the project configuration and SDK support are confirmed.
- For interceptor applicability, Roslyn APIs, generated code shape, constraints, and tests, load `references/interceptors.md`.
- Supporting multiple Roslyn API versions can let newer features light up while preserving older SDK support, but it usually requires split generator projects, separate package layout entries, duplicated test projects, and CI that runs package tests under multiple SDKs.
- Prefer a single supported Roslyn baseline unless there is a concrete consumer compatibility requirement.

## Source References

This guidance was distilled from Andrew Lock's .NET Escapades blog series and a related .NET 10 preview article.

- Blog: Andrew Lock | .NET Escapades.
- Series index: [Creating a source generator](https://andrewlock.net/series/creating-a-source-generator/).
- Part 1: incremental generator project structure and initial pipeline.
- Part 2: Verify snapshot testing for generated source and diagnostics.
- Part 3: integration tests and NuGet analyzer package layout.
- Part 4: marker attribute properties and constructor arguments.
- Part 5: namespace and nested type hierarchy extraction.
- Part 6: persisting generated output with `EmitCompilerGeneratedFiles`.
- Parts 7-8: marker attribute distribution strategies.
- Part 9: incremental generator performance pitfalls.
- Part 10: cacheability tests using tracking names.
- Part 11: interceptors generated by source generators.
- Parts 12-13: compilation options, C# language version, and MSBuild settings.
- Part 14: supporting multiple Roslyn or .NET SDK versions.
- Related .NET 10 article: `[Embedded]` marker attributes and `AddEmbeddedAttributeDefinition()`.
