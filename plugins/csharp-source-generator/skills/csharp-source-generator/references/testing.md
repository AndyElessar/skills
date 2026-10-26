# Testing Source Generators

Use this when adding or reviewing generator tests. Prefer the narrowest test that proves the behavior, then add integration/package coverage when compiler or package layout matters.

## Test Project Setup

A unit/snapshot test project references the generator as a normal project and adds Roslyn plus snapshot packages:

```xml
<ItemGroup>
  <PackageReference Include="Microsoft.CodeAnalysis.CSharp" PrivateAssets="all" />
  <PackageReference Include="Microsoft.CodeAnalysis.Analyzers" PrivateAssets="all" />
  <PackageReference Include="Verify.SourceGenerators" />
  <PackageReference Include="Verify.XunitV3" /> <!-- or the adapter for the repository's test framework -->
  <ProjectReference Include="..\..\src\MyGenerator\MyGenerator.csproj" />
</ItemGroup>
```

`Microsoft.CodeAnalysis.CSharp.SourceGenerators.Testing` (roslyn-sdk) is the officially recommended alternative when the repository prefers expected-source assertions over snapshots.

Verify needs its source generator converters enabled once per test assembly; without this the snapshot is just `{}`:

```csharp
public static class ModuleInitializer
{
    [ModuleInitializer]
    public static void Init() => VerifySourceGenerators.Enable();
}
```

## Compilation Helper

A compilation without references cannot bind `System.Attribute`, so attribute-driven generators silently produce nothing (the symbol has `CandidateReason.NotAnAttributeType`). Always add references:

```csharp
public static class TestHelper
{
    public static CSharpCompilation CreateCompilation(params string[] sources)
    {
        IEnumerable<MetadataReference> references = AppDomain.CurrentDomain.GetAssemblies()
            .Where(static a => !a.IsDynamic && !string.IsNullOrWhiteSpace(a.Location))
            .Select(static a => MetadataReference.CreateFromFile(a.Location));

        return CSharpCompilation.Create(
            "Tests",
            sources.Select(static s => CSharpSyntaxTree.ParseText(s)),
            references,
            new CSharpCompilationOptions(OutputKind.DynamicallyLinkedLibrary));
    }
}
```

Pass `CSharpParseOptions` with a specific `LanguageVersion` when the generator branches on language version.

## Snapshot Tests

Snapshot tests fit because a generator should produce deterministic output for fixed input.

```csharp
[Fact]
public Task Generates_expected_source()
{
    CSharpCompilation compilation = TestHelper.CreateCompilation("""
        using MyGeneratorPackage;

        [My]
        public partial class Customer;
        """);

    GeneratorDriver driver = CSharpGeneratorDriver.Create(new MyGenerator())
        .RunGeneratorsAndUpdateCompilation(compilation, out Compilation output, out _);

    // Generated code must compile, not just look right.
    Assert.Empty(output.GetDiagnostics().Where(static d => d.Severity == DiagnosticSeverity.Error));

    return Verify(driver).UseDirectory("Snapshots");
}
```

Snapshot generated trees, hint names, and diagnostics. Avoid snapshotting unrelated compiler state.

## Diagnostics

- Include at least one negative test for invalid input.
- Assert diagnostic ID, severity, message arguments, and closest useful location.
- Verify that valid targets still generate when another target reports a diagnostic.

## Cacheability Tests

Run the generator twice on equivalent compilations with the same driver and assert every tracked stage was reused. Step tracking is off by default; without `trackIncrementalGeneratorSteps: true`, `TrackedSteps` is empty and the test proves nothing.

```csharp
public static GeneratorDriverRunResult RunAndAssertCached<T>(CSharpCompilation compilation, string[] trackingNames)
    where T : IIncrementalGenerator, new()
{
    GeneratorDriver driver = CSharpGeneratorDriver.Create(
        [new T().AsSourceGenerator()],
        driverOptions: new GeneratorDriverOptions(IncrementalGeneratorOutputKind.None, trackIncrementalGeneratorSteps: true));

    // Keep the returned driver: it holds the cached state from the first run.
    driver = driver.RunGenerators(compilation);
    GeneratorDriverRunResult first = driver.GetRunResult();
    GeneratorDriverRunResult second = driver.RunGenerators(compilation.Clone()).GetRunResult();

    foreach (string name in trackingNames)
    {
        ImmutableArray<IncrementalGeneratorRunStep> steps1 = first.Results[0].TrackedSteps[name];
        ImmutableArray<IncrementalGeneratorRunStep> steps2 = second.Results[0].TrackedSteps[name];
        Assert.Equal(steps1.Length, steps2.Length);

        for (int i = 0; i < steps1.Length; i++)
        {
            // Equal outputs prove the model has value equality.
            Assert.Equal(steps1[i].Outputs.Select(static o => o.Value), steps2[i].Outputs.Select(static o => o.Value));
            // Cached: input unchanged. Unchanged: input changed but output is equal.
            Assert.All(steps2[i].Outputs, static o => Assert.True(
                o.Reason is IncrementalStepRunReason.Cached or IncrementalStepRunReason.Unchanged));
            AssertNoBannedTypes(steps1[i]);
        }
    }

    // Final source outputs must also come from the cache.
    Assert.All(
        second.Results[0].TrackedOutputSteps.SelectMany(static s => s.Value).SelectMany(static s => s.Outputs),
        static o => Assert.Equal(IncrementalStepRunReason.Cached, o.Reason));

    return first;
}
```

`AssertNoBannedTypes` walks each output's object graph (fields via reflection, recursing into `IEnumerable`) and fails on any value assignable to `Compilation`, `ISymbol`, `SyntaxNode`, `SemanticModel`, or `Location`. Use an assignability check (`is ISymbol`, `IsAssignableFrom`), not an exact-type check: `ISymbol` is an interface, so exact type matching never fires.

Keep tracking names as `const string` fields on one class so tests can enumerate them. If a stage uses `WithComparer`, compare with that comparer instead of `Equals`.

## Integration Tests

Use integration tests when generated code must compile and run as part of a real project.

```xml
<ItemGroup>
  <ProjectReference Include="..\..\src\MyGenerator\MyGenerator.csproj"
                    OutputItemType="Analyzer"
                    ReferenceOutputAssembly="false" />
</ItemGroup>
```

Integration tests should cover the public behavior of generated code, not only the generated text. IDEs cache loaded analyzers; after changing the generator, restart the IDE (or build from the CLI) before trusting IDE results.

## Package Tests

Use package tests before shipping a NuGet generator. Restore from a local package source and isolate the package cache so stale global packages cannot hide package layout bugs.

```powershell
dotnet pack -c Release -o ./artifacts -p:Version=0.1.0-beta
dotnet new nugetconfig
Rename-Item nuget.config nuget.integration-tests.config
dotnet nuget add source ./artifacts -n local-packages --configfile nuget.integration-tests.config
dotnet restore ./tests/MyGenerator.PackageTests --packages ./packages --configfile nuget.integration-tests.config
dotnet build ./tests/MyGenerator.PackageTests -c Release --packages ./packages --no-restore
dotnet test ./tests/MyGenerator.PackageTests -c Release --no-build --no-restore
```

Keep the package test project out of the solution (or out of all solution build configurations) and share test files with the integration test project instead of duplicating them:

```xml
<ItemGroup>
  <PackageReference Include="MyGenerator" Version="0.1.0-beta" />
  <Compile Include="..\MyGenerator.IntegrationTests\*.cs" Link="%(Filename)%(Extension)" />
</ItemGroup>
```

## Minimum Coverage

- Minimal positive generation, including a check that the updated compilation has no errors.
- Multiple targets with deterministic ordering and hint names.
- Invalid usage diagnostic.
- Cacheability test for every tracked stage.
- Integration compile/run path when generated code affects runtime behavior.
- Package layout test when shipping a `.nupkg`, including `.props`/`.targets` behavior.
- When multi-targeting Roslyn versions, run the suites against each analyzer flavor under a matching SDK.
