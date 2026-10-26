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

MSBuild writes compiler-visible properties to `obj/<Project>.GeneratedMSBuildEditorConfig.editorconfig`; inspect that file when a property seems missing. A few properties are always present, including `RootNamespace`, `ProjectDir`, and `TargetFramework`. Keys without the prefix (for example `mygenerator_emit_logging = true` in a `.globalconfig`) are also readable from `GlobalOptions`.

Expose custom properties to the compiler with `CompilerVisibleProperty`.

```xml
<ItemGroup>
  <CompilerVisibleProperty Include="MyGenerator_Enable" />
</ItemGroup>
```

Values travel through an editorconfig file, so non-trivial values can be corrupted: `;` and `#` start comments, which truncates semicolon-separated lists. Transport-encode such values in a target before exposing them:

```xml
<ItemGroup>
  <CompilerVisibleProperty Include="_MyGenerator_List" />
</ItemGroup>

<Target Name="MyGenerator_EncodeList" BeforeTargets="GenerateMSBuildEditorConfigFileShouldRun">
  <PropertyGroup>
    <_MyGenerator_List>$([System.String]::Copy('$(MyGenerator_List)').Replace(';', ' '))</_MyGenerator_List>
  </PropertyGroup>
</Target>
```

## Shipping Settings in a NuGet Package

Package a `.props` file so NuGet consumers only set the property, not `CompilerVisibleProperty`. NuGet imports `build/<PackageId>.props` and `build/<PackageId>.targets` automatically only when the file name matches the package ID exactly.

```xml
<!-- MyGenerator.props, where the package ID is MyGenerator -->
<Project>
  <ItemGroup>
    <CompilerVisibleProperty Include="MyGenerator_Enable" />
  </ItemGroup>
</Project>
```

```xml
<None Include="MyGenerator.props" Pack="true" PackagePath="build" Visible="false" />
```

- Use `.props` to declare items and defaults; it is imported before the consumer's project body.
- Use `.targets` when a value depends on properties the consumer sets, because targets are evaluated after the project file.
- Use `buildTransitive/` as well when projects that reference the consumer transitively must also get the settings.

## Additional File Metadata

Expose item metadata with `CompilerVisibleItemMetadata` and read it from per-file options.

```xml
<ItemGroup>
  <AdditionalFiles Include="Schemas\*.json" MyGenerator_Mode="Strict" />
  <CompilerVisibleItemMetadata Include="AdditionalFiles" MetadataName="MyGenerator_Mode" />
</ItemGroup>
```

```csharp
IncrementalValuesProvider<(string Path, string? Mode)> files = context.AdditionalTextsProvider
    .Where(static f => f.Path.EndsWith(".json", StringComparison.OrdinalIgnoreCase))
    .Combine(context.AnalyzerConfigOptionsProvider)
    .Select(static (pair, _) =>
    {
        pair.Right.GetOptions(pair.Left).TryGetValue("build_metadata.AdditionalFiles.MyGenerator_Mode", out string? mode);
        return (pair.Left.Path, mode);
    });
```

Include enough of the file path in hint names to avoid collisions between same-named files in different folders.

## Compilation Options

Select small values from `CompilationProvider` (`AssemblyName`, `Options.Platform`, `Options.OptimizationLevel`) instead of passing the `Compilation` downstream. The selector reruns on every edit, so keep it trivial.

## Language Version

Read the language version from `ParseOptionsProvider`; it changes only when project settings change, unlike `CompilationProvider`.

```csharp
IncrementalValueProvider<LanguageVersion> languageVersion = context.ParseOptionsProvider
    .Select(static (options, _) => ((CSharpParseOptions)options).LanguageVersion);
```

- `default`, `latest`, and `latestMajor` arrive already mapped to a concrete `CSharpN` value. `preview` arrives as `LanguageVersion.Preview` (`int.MaxValue - 1`), which compares greater than every numbered version.
- The enum members available at compile time depend on the referenced Roslyn package, but newer SDKs can pass newer values. Compare numerically when the named member does not exist yet:

```csharp
if (languageVersion >= (LanguageVersion)1300)
{
    // Generate C# 13-or-newer syntax, such as params collections.
}
```

## Interceptors

Interceptors require explicit consumer opt-in through allowed namespaces. If a package exposes one boolean setting, use a `.targets` file to append interceptor namespaces after consumer properties have been evaluated. Set both properties so older SDKs that only know the preview name keep working.

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

Also expose `MyGenerator_EnableInterceptors` through the `.props` file so the generator can skip interceptor generation when it is off.

## Checks

- Missing properties should have deterministic defaults.
- Configuration parsing should be case-insensitive only when the setting semantics allow it.
- Do not combine full `Compilation` with high-cardinality syntax models; select the small option value first.
- `.props`/`.targets` file names match the package ID.
- Package tests should prove `.props` and `.targets` files are applied for NuGet consumers.
