# Configuration Inputs

Use this when a generator reads MSBuild properties, analyzer config options, C# language version, parse options, or interceptor settings.

## Analyzer Config Options

Read global MSBuild properties through `AnalyzerConfigOptionsProvider`. The key must use the `build_property.` prefix.

```csharp
IncrementalValueProvider<bool> enabled = context.AnalyzerConfigOptionsProvider
    .Select(static (options, _) =>
        options.GlobalOptions.TryGetValue("build_property.MyGenerator_Enable", out string? value)
        && value.Equals("true", StringComparison.OrdinalIgnoreCase));
```

Expose custom properties to the compiler with `CompilerVisibleProperty`.

```xml
<ItemGroup>
  <CompilerVisibleProperty Include="MyGenerator_Enable" />
</ItemGroup>
```

Package a `.props` file when NuGet consumers should not have to add `CompilerVisibleProperty` manually.

```xml
<Project>
  <ItemGroup>
    <CompilerVisibleProperty Include="MyGenerator_Enable" />
  </ItemGroup>
</Project>
```

```xml
<None Include="MyGenerator.props" Pack="true" PackagePath="build" Visible="false" />
```

## Additional File Metadata

Expose item metadata with `CompilerVisibleItemMetadata` and read it from per-file options.

```xml
<ItemGroup>
  <AdditionalFiles Include="Schemas\*.json" MyGenerator_Mode="Strict" />
  <CompilerVisibleItemMetadata Include="AdditionalFiles" MetadataName="MyGenerator_Mode" />
</ItemGroup>
```

```csharp
AnalyzerConfigOptions fileOptions = options.GetOptions(additionalText);
fileOptions.TryGetValue("build_metadata.AdditionalFiles.MyGenerator_Mode", out string? mode);
```

## Language Version

Use `CSharpCompilation.LanguageVersion` when generated syntax depends on newer C# features.

```csharp
IncrementalValueProvider<LanguageVersion?> languageVersion = context.CompilationProvider
    .Select(static (compilation, _) =>
        compilation is CSharpCompilation csharp ? csharp.LanguageVersion : null);
```

Future C# versions can appear as enum numeric values not known at generator compile time. Compare numeric values when the referenced Roslyn package does not expose the named enum member.

```csharp
if (languageVersion >= (LanguageVersion)1300)
{
    // Generate C# 13-or-newer syntax.
}
```

## Interceptors

Interceptors require explicit consumer opt-in through allowed namespaces. If a package exposes one boolean setting, use a `.targets` file to append interceptor namespaces after consumer properties have been evaluated.

```xml
<Project InitialTargets="MyGenerator_ConfigureInterceptors">
  <Target Name="MyGenerator_ConfigureInterceptors">
    <PropertyGroup Condition="'$(MyGenerator_EnableInterceptors)' == 'true'">
      <InterceptorsNamespaces>$(InterceptorsNamespaces);MyGeneratorPackage.Generated</InterceptorsNamespaces>
      <InterceptorsPreviewNamespaces>$(InterceptorsPreviewNamespaces);MyGeneratorPackage.Generated</InterceptorsPreviewNamespaces>
    </PropertyGroup>
  </Target>
</Project>
```

```xml
<None Include="MyGenerator.targets" Pack="true" PackagePath="build" Visible="false" />
```

## Checks

- Missing properties should have deterministic defaults.
- Configuration parsing should be case-insensitive only when the setting semantics allow it.
- Do not combine full `Compilation` with high-cardinality syntax models; select the small option value first.
- Package tests should prove `.props` and `.targets` files are applied for NuGet consumers.
