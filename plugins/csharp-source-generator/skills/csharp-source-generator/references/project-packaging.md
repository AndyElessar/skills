# Project Packaging

Use this when creating or reviewing source generator project files, analyzer NuGet packages, companion attribute assemblies, or generator runtime dependencies.

## Minimal Analyzer Project

```xml
<Project Sdk="Microsoft.NET.Sdk">
  <PropertyGroup>
    <TargetFramework>netstandard2.0</TargetFramework>
    <IsPackable>true</IsPackable>
    <IsRoslynComponent>true</IsRoslynComponent>
    <EnforceExtendedAnalyzerRules>true</EnforceExtendedAnalyzerRules>
    <IncludeBuildOutput>false</IncludeBuildOutput>
    <Nullable>enable</Nullable>
    <LangVersion>latest</LangVersion>
  </PropertyGroup>

  <ItemGroup>
    <PackageReference Include="Microsoft.CodeAnalysis.CSharp" PrivateAssets="all" />
    <PackageReference Include="Microsoft.CodeAnalysis.Analyzers" PrivateAssets="all" />
  </ItemGroup>

  <ItemGroup>
    <None Include="$(OutputPath)$(AssemblyName).dll"
          Pack="true"
          PackagePath="analyzers/dotnet/cs"
          Visible="false" />
  </ItemGroup>
</Project>
```

- `netstandard2.0` is required so the generator loads in both .NET (SDK) and .NET Framework (Visual Studio) compiler hosts. It has no implicit usings, `HashCode`, or `IsExternalInit`; see PolySharp below.
- `EnforceExtendedAnalyzerRules` turns on analyzer-author rules (for example banning file I/O and non-portable APIs in generator code).
- `PackageReference` items omit `Version` here because many repositories use central package management; add versions otherwise.

## Roslyn Version Baseline

Pin `Microsoft.CodeAnalysis.CSharp` to the lowest version whose APIs the generator actually requires. That version is the minimum compiler consumers must have; bumping it is a breaking change for the generator package.

| Roslyn package | Minimum .NET SDK | Minimum Visual Studio | Notable generator APIs |
| --- | --- | --- | --- |
| 4.0 | 6.0.100 | 17.0 | `IIncrementalGenerator` |
| 4.4 | 7.0.100 | 17.4 | `ForAttributeWithMetadataName` |
| 4.8 | 8.0.100 | 17.8 | |
| 4.11 | 8.0.400 | 17.11 | `GetInterceptableLocation`, `InterceptsLocation(version, data)` |
| 4.12 | 9.0.100 | 17.12 | |
| 4.14 | 9.0.300 | 17.14 | `AddEmbeddedAttributeDefinition()` |

Newer bands follow the same pattern; check [Roslyn version support](https://learn.microsoft.com/visualstudio/extensibility/roslyn-version-support) before choosing a newer baseline.

## Generator Dependencies

- Roslyn packages should be `PrivateAssets="all"`; do not ship compiler assemblies with the analyzer package.
- **Generation-time dependencies** (used while the generator runs) are not loaded from normal package references. Reference them with `PrivateAssets="all" GeneratePathProperty="true"` and pack their DLLs beside the generator:

```xml
<PackageReference Include="Newtonsoft.Json" PrivateAssets="all" GeneratePathProperty="true" />
<None Include="$(PkgNewtonsoft_Json)\lib\netstandard2.0\*.dll" Pack="true" PackagePath="analyzers/dotnet/cs" Visible="false" />
```

- **Consumer runtime dependencies** (types the generated code uses) are ordinary public package dependencies or a companion `lib/<tfm>` assembly.

## PolySharp and Modern CSharp

Use PolySharp when the generator implementation needs records, `init`, required members, or other modern C# features while staying on `netstandard2.0`.

```xml
<PackageReference Include="PolySharp" PrivateAssets="all" />
```

Keep PolySharp private and follow the repository's central package versioning pattern. PolySharp does not provide `System.HashCode`; vendor one if equality helpers need it.

## Marker Attribute Distribution

Choose one strategy per package:

1. **Generated + `[Embedded]` (Roslyn 4.14+ baseline).** Simplest. Emit the attribute in `RegisterPostInitializationOutput`, call `AddEmbeddedAttributeDefinition()`, and apply `[global::Microsoft.CodeAnalysis.EmbeddedAttribute]`. Prevents `CS0436` when projects share internals through `[InternalsVisibleTo]`.
2. **Companion assembly packed into the generator package.** Works on older SDKs, and is required when generated public APIs expose package-defined types (an `[Embedded]` type cannot be used across assemblies).
3. **Generated internal attribute without `[Embedded]`.** Only acceptable when `[InternalsVisibleTo]` across consuming projects is impossible; otherwise users hit `CS0436`.

Avoid asking users to hand-write attributes, and avoid removing `IncludeBuildOutput=false` to reference the generator DLL itself (it drags Roslyn dependencies into consumers and causes assembly version conflicts).

### Companion Attribute Assembly

```xml
<ItemGroup>
  <ProjectReference Include="..\MyGenerator.Attributes\MyGenerator.Attributes.csproj" PrivateAssets="all" />

  <!-- Only needed if generator code references the attribute types. -->
  <None Include="$(OutputPath)MyGenerator.Attributes.dll"
        Pack="true"
        PackagePath="analyzers/dotnet/cs"
        Visible="false" />

  <None Include="$(OutputPath)MyGenerator.Attributes.dll"
        Pack="true"
        PackagePath="lib/netstandard2.0"
        Visible="true" />
</ItemGroup>
```

- Mark the attributes `[System.Diagnostics.Conditional("MY_GENERATOR_USAGES")]` so they are not emitted into consumer metadata. Consumers can then use `ExcludeAssets="runtime"` to keep the attributes DLL out of their `bin` folder.
- Inside the same solution, a consuming project must reference the attributes project as both an analyzer and a normal reference, because the generator cannot see the consumer's references:

```xml
<ProjectReference Include="..\MyGenerator\MyGenerator.csproj" OutputItemType="Analyzer" ReferenceOutputAssembly="false" />
<ProjectReference Include="..\MyGenerator.Attributes\MyGenerator.Attributes.csproj" OutputItemType="Analyzer" ReferenceOutputAssembly="true" />
```

## Version-Specific Analyzer Folders

The .NET 6+ SDK loads the highest `analyzers/dotnet/roslyn<major.minor>/cs` folder the running compiler supports. Use this only when there is a real need to light up newer Roslyn APIs while preserving older SDK support; it multiplies project, test, and CI work.

- One generator project per Roslyn version, sharing source files (for example through a shared `.targets` import) and a `RoslynApiVersion` property that drives the `Microsoft.CodeAnalysis.CSharp` version.
- Give every flavor the same `AssemblyName` and `RootNamespace`.
- Gate newer features with `DefineConstants` (for example `INTERCEPTORS`) and `#if`.
- A separate pack-only project (`Compile Remove="**/*.cs"`, `ProjectReference ... ReferenceOutputAssembly="false"`) collects each flavor's output:

```xml
<ItemGroup>
  <None Include="$(OutputPath)..\..\MyGenerator.Roslyn4_4\$(AssemblyName).dll"
        Pack="true"
        PackagePath="analyzers/dotnet/roslyn4.4/cs"
        Visible="false" />
  <None Include="$(OutputPath)..\..\MyGenerator.Roslyn4_11\$(AssemblyName).dll"
        Pack="true"
        PackagePath="analyzers/dotnet/roslyn4.11/cs"
        Visible="false" />
</ItemGroup>
```

Adjust the relative output paths to the repository's layout (for example artifacts output). Pack companion analyzer-time DLLs into every version folder.

## Checks

- The generator DLL is under an analyzer path, not only `lib/`.
- `IncludeBuildOutput=false` prevents normal consumer references to the generator DLL.
- The Roslyn package version matches the intended minimum SDK.
- Companion runtime types are available under `lib/<tfm>` when generated public APIs expose them.
- `.props`/`.targets` are under `build/` (and `buildTransitive/` if needed) and named after the package ID.
- Package tests install the built `.nupkg`, not only the project reference.
