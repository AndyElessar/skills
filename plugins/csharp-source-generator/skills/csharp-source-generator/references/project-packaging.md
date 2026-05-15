# Project Packaging

Use this when creating or reviewing source generator project files, analyzer NuGet packages, companion attribute assemblies, or generator runtime dependencies.

## Minimal Analyzer Project

```xml
<Project Sdk="Microsoft.NET.Sdk">
  <PropertyGroup>
    <TargetFramework>netstandard2.0</TargetFramework>
    <IsPackable>true</IsPackable>
    <IsRoslynComponent>true</IsRoslynComponent>
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

## Generator Dependencies

- Roslyn packages should be `PrivateAssets="all"`; do not ship compiler assemblies with the analyzer package.
- Pin `Microsoft.CodeAnalysis.CSharp` to the lowest version whose APIs the generator actually requires, and treat that version as the package's minimum supported consumer SDK (`4.4` ≈ .NET 7 SDK, `4.8` ≈ .NET 8, `4.11` ≈ .NET 9, `4.14` ≈ .NET 10). Bumping it forces every consumer to upgrade their SDK and is a breaking change for the generator package.
- Analyzer runtime dependencies are not loaded from normal package references. If the generator needs a helper DLL at analyzer runtime, pack that DLL beside the generator under `analyzers/dotnet/cs` or the version-specific analyzer folder.
- Consumer runtime dependencies are different. If generated user code exposes or calls a runtime type, that type must be available to the consuming project through a normal `lib/<tfm>` assembly or ordinary package dependency.
- Use `GeneratePathProperty="true"` when a package DLL must be explicitly copied into the analyzer layout.

## PolySharp and Modern CSharp

Generator projects often target `netstandard2.0` for broad compiler host compatibility. Use PolySharp when the generator implementation needs records or other modern C# features while staying on `netstandard2.0`.

```xml
<PackageReference Include="PolySharp" PrivateAssets="all" />
```

Keep PolySharp private and follow the repository's central package versioning pattern.

## Companion Attribute Assembly

Use a companion runtime or attributes assembly when marker attributes or helper types are part of the consumer API.

```xml
<ItemGroup>
  <ProjectReference Include="..\MyGenerator.Attributes\MyGenerator.Attributes.csproj" PrivateAssets="all" />

  <None Include="$(OutputPath)MyGenerator.Attributes.dll"
        Pack="true"
        PackagePath="analyzers/dotnet/cs"
        Visible="false" />

  <None Include="$(OutputPath)MyGenerator.Attributes.dll"
        Pack="true"
        PackagePath="lib\netstandard2.0"
        Visible="true" />
</ItemGroup>
```

## Version-Specific Analyzer Folders

Use version-specific analyzer folders only when there is a real need to light up newer Roslyn APIs while preserving older SDK support.

```xml
<ItemGroup>
  <None Include="$(OutputPath)..\..\MyGenerator.Roslyn4_04\$(AssemblyName).dll"
        Pack="true"
        PackagePath="analyzers/dotnet/roslyn4.4/cs"
        Visible="false" />
  <None Include="$(OutputPath)..\..\MyGenerator.Roslyn4_11\$(AssemblyName).dll"
        Pack="true"
        PackagePath="analyzers/dotnet/roslyn4.11/cs"
        Visible="false" />
</ItemGroup>
```

## Checks

- The generator DLL is under an analyzer path, not only `lib/`.
- `IncludeBuildOutput=false` prevents normal consumer references to the generator DLL.
- Companion runtime types are available under `lib/<tfm>` when generated public APIs expose them.
- Package tests install the built `.nupkg`, not only the project reference.
