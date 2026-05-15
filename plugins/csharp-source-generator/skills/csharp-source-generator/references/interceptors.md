# Interceptors in Source Generators

Use this when designing, implementing, reviewing, or testing a source generator that emits C# interceptors with `[InterceptsLocation]`. Interceptors are a compiler feature that can replace selected ordinary method calls at compile time by adding generated source to the compilation.

Interceptors first shipped experimentally in .NET 8 and are stable in the .NET 9.0.2xx SDK and later. They still require explicit consumer opt-in through `InterceptorsNamespaces` or the compatibility alias `InterceptorsPreviewNamespaces`.

## When to Use Interceptors

Interceptors are appropriate when the generator needs to preserve existing user call sites while replacing the implementation with generated code.

Good fits include:

- Replacing reflection-heavy or AOT-unfriendly calls with source-generated implementations.
- Optimizing known calls where asking users to call a new API directly would be noisy or infeasible.
- Adapting existing public APIs while keeping source compatibility for consumers.
- Intercepting calls that can be identified precisely from syntax plus semantic analysis.

Avoid interceptors when:

- A normal generated extension method or explicit generated API is acceptable.
- The target is not an ordinary method call, such as a constructor, property, delegate invocation, operator, local function, delegate conversion, or address-of method usage.
- The generator cannot prove the replacement method has a compatible signature and accessibility at the call site.
- The package cannot arrange consumer opt-in through `InterceptorsNamespaces` or clear project configuration.
- Multiple generators might reasonably target the same call location; duplicate interception is a compile-time error.

## Implementation Recipe

1. Decide the exact call shape to intercept and the replacement API shape. Do not generate interceptors until the target method, receiver behavior, return type, parameters, and opt-in namespace are known.
2. Use `CreateSyntaxProvider` for invocation-driven discovery. Keep the predicate cheap, then confirm the target method in the transform with semantic APIs or operation analysis.
3. Call `SemanticModel.GetInterceptableLocation(invocation, cancellationToken)` for each confirmed `InvocationExpressionSyntax`. Use Roslyn's API rather than constructing the encoded data manually.
4. Convert the result to generator-owned, equatable models as early as possible. Do not carry `SemanticModel`, `InvocationExpressionSyntax`, `ISymbol`, or other Roslyn object graphs through the pipeline beyond the transform.
5. Generate a file-local `InterceptsLocationAttribute` definition in the same generated file as the usages, unless the consumer project already supplies an appropriate definition.
6. Generate interceptor methods in a namespace owned by the generator package. The namespace must be allowed by `InterceptorsNamespaces`.
7. Keep generated hint names deterministic and sort interceptors by stable keys such as file path, syntax span, target type name, and generated method name.
8. Add package configuration for opt-in when shipping through NuGet. See `configuration.md` for `.targets` examples that append `InterceptorsNamespaces`.

## Discovery Example

This pattern finds candidate `ToString()` calls, confirms they are calls to `System.Enum.ToString()`, and records the interceptable location plus the enum type name.

```csharp
IncrementalValuesProvider<CandidateInvocation> locations = context.SyntaxProvider
    .CreateSyntaxProvider(
        predicate: static (node, _) =>
            node is InvocationExpressionSyntax
            {
                Expression: MemberAccessExpressionSyntax
                {
                    Name.Identifier.ValueText: "ToString"
                }
            },
        transform: static (syntaxContext, cancellationToken) =>
            TryCreateCandidate(syntaxContext, cancellationToken))
    .Where(static candidate => candidate is not null)
    .Select(static (candidate, _) => candidate!);

private static CandidateInvocation? TryCreateCandidate(
    GeneratorSyntaxContext context,
    CancellationToken cancellationToken)
{
    if (context.Node is not InvocationExpressionSyntax invocation)
    {
        return null;
    }

    if (context.SemanticModel.GetOperation(invocation, cancellationToken) is not IInvocationOperation operation)
    {
        return null;
    }

    if (operation.TargetMethod is not
        {
            Name: "ToString",
            ContainingType:
            {
                Name: "Enum",
                ContainingNamespace:
                {
                    Name: "System",
                    ContainingNamespace.IsGlobalNamespace: true
                }
            }
        })
    {
        return null;
    }

    if (operation.Instance?.Type is not { } enumType)
    {
        return null;
    }

#pragma warning disable RSEXPERIMENTAL002
    InterceptableLocation? location = context.SemanticModel.GetInterceptableLocation(invocation, cancellationToken);
#pragma warning restore RSEXPERIMENTAL002

    return location is null
        ? null
        : new CandidateInvocation(location.Version, location.Data, location.GetDisplayLocation(), enumType.ToDisplayString());
}

private sealed record CandidateInvocation(
    int Version,
    string Data,
    string DisplayLocation,
    string EnumTypeName);
```

If the referenced Roslyn package no longer marks the API experimental, omit the pragma. Keep compatibility choices explicit rather than suppressing warnings blindly across the whole generator.

## Generated Code Shape

Generated interceptor files should define the attribute and the interceptor method together. Prefer file-local declarations so multiple generators can safely emit their own definitions without type conflicts.

```csharp
// <auto-generated/>
#nullable enable

namespace System.Runtime.CompilerServices
{
    [global::System.Diagnostics.Conditional("DEBUG")]
    [global::System.AttributeUsage(global::System.AttributeTargets.Method, AllowMultiple = true)]
    sealed file class InterceptsLocationAttribute : global::System.Attribute
    {
        public InterceptsLocationAttribute(int version, string data)
        {
        }
    }
}

namespace MyGeneratorPackage.Generated
{
    static file class EnumInterceptors
    {
        [global::System.Runtime.CompilerServices.InterceptsLocation(1, "encoded-location-data")] // Program.cs(10,24)
        public static string MyEnumToString(this global::System.Enum value)
            => global::MyApp.MyEnumExtensions.ToStringFast((global::MyApp.MyEnum)value);
    }
}
```

The `version` and `data` arguments are opaque location data. Do not generate them by string manipulation. Use `GetInterceptableLocation` so Roslyn owns the encoding.

## Signature and Accessibility Rules

- Interceptors can replace ordinary method calls, including ordinary instance calls, static calls, conditional-access calls, and pointer member-access calls when the compiler considers them interceptable.
- The interceptor must be accessible at the original call site. File-local interceptor types are allowed to intercept calls in other files and help avoid polluting lookup.
- Instance method interception normally uses a static interceptor method whose first parameter represents the receiver, similar to a classic extension method in reduced form.
- Return type, parameter types, `ref` kinds, `this` receiver behavior, `scoped`, and `[UnscopedRef]` capabilities must be compatible with the original method.
- Method names, parameter names, default values, and `params` modifiers do not need to match.
- Generic interceptors cannot be declared in generic containing types. If the interceptor method is generic, its type parameters receive type arguments from the original containing types and method from outermost to innermost.
- If more than one interceptor targets the same source location, compilation fails.

## Configuration

Consumer projects must opt in to namespaces that contain interceptors.

```xml
<InterceptorsNamespaces>$(InterceptorsNamespaces);MyGeneratorPackage.Generated</InterceptorsNamespaces>
```

`InterceptorsPreviewNamespaces` is a compatibility alias. When both properties are set, the compiler concatenates them. Package authors can use a `.targets` file to append the generator-owned namespace when a generator-specific opt-in property is enabled.

## Diagnostics and Editor Experience

- Treat unsupported call shapes and invalid targets as diagnosable data when the generator can identify them precisely.
- Expect some interceptor diagnostics to appear only in command-line builds, not always in the IDE.
- Use integration and package tests to prove behavior. Snapshot tests alone can show generated source but cannot prove that the compiler performed the substitution.
- Analyzers can use `SemanticModel.GetInterceptorMethod(invocation, cancellationToken)` to inspect whether a call is intercepted when that API is available in the supported Roslyn version.

## Testing Checklist

- Snapshot the generated interceptor source, including stable hint names and sorted `[InterceptsLocation]` attributes.
- Add an integration test where the original call site remains unchanged and runtime behavior proves the interceptor method was used.
- Add a package test that restores the built `.nupkg` from a local source and verifies `.targets` configuration enables the interceptor namespace.
- Test disabled configuration or missing opt-in so the generator degrades predictably.
- Test at least one invalid or unsupported target and assert diagnostics when the generator reports them.
- Test signature mismatch, duplicate interception, or inaccessible interceptor behavior when the generator can create those scenarios intentionally.

## Review Checklist

- The use case justifies replacing existing calls instead of generating an explicit API.
- The syntax predicate is selective and semantic validation confirms the exact target method.
- Interceptable locations come from Roslyn APIs, not handcrafted location encoding.
- Pipeline outputs are generator-owned values with stable equality.
- The generated namespace is owned by the package and is included in `InterceptorsNamespaces`.
- Attribute definitions are file-local or otherwise proven conflict-free.
- Generated methods satisfy signature, receiver, generic, nullability, and accessibility rules.
- Tests include generated source, real compiler substitution, NuGet configuration, and at least one negative case.

## References

- [Roslyn interceptor design](https://github.com/dotnet/roslyn/blob/main/docs/features/interceptors.md)
- [Andrew Lock, source generator interceptors case study](https://andrewlock.net/creating-a-source-generator-part-11-implementing-an-interceptor-with-a-source-generator/)
