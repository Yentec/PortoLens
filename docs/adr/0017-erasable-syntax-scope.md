# 0017. Scope of `erasableSyntaxOnly`

- Status: Accepted
- Date: 2026-11-12

## Context

`tsconfig.base.json` enables `erasableSyntaxOnly`. It allows only TypeScript syntax that can be
removed without emitting code, so that a file stays runnable by type stripping alone (Node.js
native type stripping, or any tool that removes types file by file). It rejects `enum`,
namespaces with runtime code, `import x = require()` and constructor parameter properties.

In `apps/api`, the rule rejects `constructor(private readonly service: Service) {}`, the idiomatic
NestJS way to declare an injected dependency. Without parameter properties, every provider,
controller and repository must declare each dependency three times: field, constructor parameter
and assignment.

The rule also gives the API no real guarantee. The API depends on legacy decorators
(`experimentalDecorators` and `emitDecoratorMetadata`, see 0002). Type stripping cannot run them,
so the API is always compiled by a real transpiler: `tsc` for the build and Oxc for Vitest. Both
handle parameter properties.

## Decision

- `erasableSyntaxOnly` stays enabled in `tsconfig.base.json` and therefore applies to `apps/web`
  and the shared `packages/*`.
- `apps/api/tsconfig.json` disables it. Constructor parameter properties are allowed there, and
  they are the preferred way to declare injected dependencies.
- The other kinds of syntax the flag rejects stay discouraged in `apps/api`: use string-literal
  unions or `as const` objects instead of `enum`, and ES modules instead of namespaces.

## Alternatives considered

- **Keep the flag everywhere and write fields explicitly**: rejected. It adds code to every
  injectable class and departs from NestJS conventions and documentation, with no runtime
  benefit.
- **Remove the flag from the base config**: rejected. In the frontend and shared packages it
  keeps the code compatible with type stripping and prevents `enum` from leaking into the shared
  contracts.

## Consequences

- NestJS classes can use `constructor(private readonly dependency: Dependency) {}`.
- The API can never run under Node.js native type stripping. That was already true because of
  its legacy decorators.
- Code moved from `apps/api` into a shared package must drop parameter properties and other
  non-erasable syntax.
- The "no `enum`" rule is no longer checked by the compiler in `apps/api`. If it needs
  enforcing, it becomes an ESLint rule (`no-restricted-syntax` on `TSEnumDeclaration`).
