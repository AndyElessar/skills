# Testing Source Generators

Use this when adding or reviewing generator tests. Prefer the narrowest test that proves the behavior, then add integration/package coverage when compiler or package layout matters.

## Snapshot Tests

Snapshot tests are useful because a source generator should produce deterministic output for fixed input.

```csharp
[Fact]
public async Task Generates_expected_source()
{
    string source = """
        using MyGeneratorPackage;

        [My]
        public partial class Customer;
        """;

    GeneratorDriver driver = CSharpGeneratorDriver.Create(new MyGenerator());
    CSharpCompilation compilation = CreateCompilation(source);

    driver = driver.RunGenerators(compilation);
    GeneratorDriverRunResult result = driver.GetRunResult();

    await Verify(result)
        .UseDirectory("Snapshots");
}
```

Snapshot generated trees, hint names, and diagnostics. Avoid snapshotting unrelated compiler state.

## Diagnostics

- Include at least one negative test for invalid input.
- Assert diagnostic ID, severity, message arguments, and closest useful location.
- Verify that valid targets still generate when another target reports a diagnostic.

## Integration Tests

Use integration tests when generated code must compile and run as part of a real project.

```xml
<ItemGroup>
  <ProjectReference Include="..\..\src\MyGenerator\MyGenerator.csproj"
                    OutputItemType="Analyzer"
                    ReferenceOutputAssembly="false" />
</ItemGroup>
```

Integration tests should cover the public behavior of generated code, not only the generated text.

## Package Tests

Use package tests before shipping a NuGet generator. Restore from a local package source and isolate the package cache so stale global packages cannot hide package layout bugs.

```powershell
dotnet pack -c Release -o ./artifacts -p:Version=0.1.0-beta
dotnet new nugetconfig
Rename-Item nuget.config nuget.integration-tests.config
dotnet nuget add source ./artifacts -n local-packages --configfile nuget.integration-tests.config
dotnet restore ./tests/MyGenerator.PackageTests --packages ./packages --configfile nuget.integration-tests.config
dotnet test ./tests/MyGenerator.PackageTests -c Release --no-restore
```

## Cacheability Tests

For performance-sensitive generators, add tracking names to pipeline stages and assert equivalent compilations reuse cached outputs.

```csharp
IncrementalValuesProvider<MyModel> models = context.SyntaxProvider
    .ForAttributeWithMetadataName(
        "MyGeneratorPackage.MyAttribute",
        predicate: static (node, _) => node is TypeDeclarationSyntax,
        transform: static (context, cancellationToken) => CreateModel(context, cancellationToken))
    .WithTrackingName("MyGenerator.Models");
```

Check that tracked outputs are equal between runs and do not contain `Compilation`, `SyntaxNode`, `ISymbol`, `SemanticModel`, `Location`, or non-structural collections.

## Minimum Coverage

- Minimal positive generation.
- Multiple targets with deterministic ordering and hint names.
- Invalid usage diagnostic.
- Integration compile/run path when generated code affects runtime behavior.
- Package layout test when shipping a `.nupkg`.
