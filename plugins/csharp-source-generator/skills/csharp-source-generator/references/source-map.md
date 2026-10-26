# Source Map

Use this file to trace a rule in this skill back to the article or design document it came from, for example when a user asks why a rule exists or when checking whether guidance has changed upstream. The rules themselves live in `SKILL.md` and the other references; this file intentionally does not repeat them.

## Roslyn Design Documents

| Document | Topics | Where in this skill |
| --- | --- | --- |
| [Incremental Generators](https://github.com/dotnet/roslyn/blob/main/docs/features/incremental-generators.md) | Input providers, `Select`/`Where`/`SelectMany`/`Collect`/`Combine`, `CreateSyntaxProvider` vs FAWMN execution, output registrations, cancellation, caching and `WithComparer` | `pipeline-design.md` |
| [Incremental Generators Cookbook](https://github.com/dotnet/roslyn/blob/main/docs/features/incremental-generators.cookbook.md) | Out-of-scope designs, value-equatable models, FAWMN, indented writers, `EmbeddedAttribute`, indirect-marker anti-patterns, additional files, diagnostics via analyzers, NuGet packaging, generation-time dependencies, analyzer config and MSBuild properties | `SKILL.md`, `pipeline-design.md`, `project-packaging.md`, `configuration.md`, `generated-code-template.md` |
| [Pre-Compilation Source Outputs](https://github.com/dotnet/roslyn/blob/main/docs/features/pre-compilation-source-outputs.md) | `RegisterPreCompilationSourceOutput`, execution order, phase enforcement, step tracking | `pipeline-design.md` |
| [Interceptors](https://github.com/dotnet/roslyn/blob/main/docs/features/interceptors.md) | Interceptor rules and opt-in | `interceptors.md` |

The cookbook still describes interceptors as experimental; the interceptor design document and Part 11 below reflect their stable status in the .NET 9.0.2xx SDK.

## Andrew Lock: Creating a Source Generator

Series index: [andrewlock.net/series/creating-a-source-generator](https://andrewlock.net/series/creating-a-source-generator/).

| Part | Topic | Where in this skill |
| --- | --- | --- |
| 1 | Incremental generator project structure and first pipeline | `incremental-generator-template.md` |
| 2 | Verify snapshot tests, `VerifySourceGenerators.Enable()`, metadata references, diagnostics snapshots | `testing.md` |
| 3 | Analyzer project references, NuGet layout, local package source, isolated restore | `testing.md`, `project-packaging.md` |
| 4 | Reading marker attribute named and constructor arguments | `pipeline-design.md` |
| 5 | Namespaces and nested/generic type hierarchies | `generated-code-template.md` |
| 6 | `EmitCompilerGeneratedFiles`, output path, `Compile Remove`, per-TFM output | `SKILL.md` |
| 7-8 | Marker attribute distribution, `CS0436`, companion assembly, `[Conditional]`, `ExcludeAssets` | `project-packaging.md` |
| 9 | Performance pitfalls: FAWMN, symbols/syntax in models, collections, `CompilationProvider`, diagnostics, `RegisterImplementationSourceOutput`, reflection | `SKILL.md`, `pipeline-design.md` |
| 10 | Cacheability tests with tracking names | `testing.md` |
| 11 | Interceptors via `GetInterceptableLocation` | `interceptors.md` |
| 12 | Compilation options and `LanguageVersion` | `configuration.md` |
| 13 | MSBuild properties, generated editorconfig, `.props`/`.targets`, interceptor opt-in | `configuration.md` |
| 14 | Multiple Roslyn/SDK versions, split projects, pack project, multi-SDK tests | `project-packaging.md`, `testing.md` |
| 15 | `[Embedded]` and `AddEmbeddedAttributeDefinition()` (Roslyn 4.14 / SDK 9.0.300) | `SKILL.md`, `project-packaging.md` |

## Known Corrections to the Sources

- Part 10's banned-type check uses an exact-type assertion against `ISymbol`, which never matches an interface; `testing.md` uses an assignability check instead.
- The cookbook's editorconfig transport-encoding sample uses a `<Task>` element; `configuration.md` uses a `<Target>` hooked before `GenerateMSBuildEditorConfigFileShouldRun`.
