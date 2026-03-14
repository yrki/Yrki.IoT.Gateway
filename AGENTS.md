# AGENTS.md

This repository should evolve as a modern, production-quality .NET codebase.

## Intent

- Keep the project language in English for code, comments, tests, documentation, commit messages, and public API names.
- Prefer the latest stable C# and .NET language/runtime features that are appropriate for the repository.
- Optimize for maintainability, fast feedback, and safe incremental change.
- Favor choices consistent with Dave Farley's continuous delivery principles: small changes, high cohesion, low coupling, clear boundaries, and strong automated verification.

## Design Principles

- Keep methods short and focused on a single responsibility.
- Prefer composition over inheritance.
- Separate domain logic from I/O, framework code, serial port access, and timing concerns.
- Design for testability first: isolate side effects behind small interfaces.
- Make invalid states hard to represent.
- Prefer explicit names over clever code.
- Remove dead code, commented-out code, and temporary debugging output unless there is a clear short-term reason to keep it.

## Architecture

- Keep a thin outer layer for hardware, serial communication, configuration, and runtime wiring.
- Keep parsing, protocol handling, validation, and message processing in pure units that can be tested without devices.
- Introduce small abstractions around `SerialPort`, clocks, delays, and background execution when needed for deterministic tests.
- Use dependency injection through constructors for non-trivial collaborators.
- Avoid static mutable state.

## Coding Style

- Use nullable reference types and treat warnings as design feedback.
- Prefer async/await and cancellation-aware APIs for I/O and long-running operations.
- Prefer immutable models and `readonly` fields where practical.
- Use guard clauses and early returns to keep control flow simple.
- Keep classes small. Split responsibilities instead of growing large service classes.
- Comments should explain intent or constraints, not restate the code.

## Testing

- Add or update unit tests for every behavior change.
- Use descriptive test names in the format `Shall_open_a_file`.
- Structure tests with explicit `// Arrange`, `// Act`, and `// Assert` sections.
- Keep unit tests deterministic, isolated, and fast.
- Prefer pure unit tests over integration tests when validating logic.
- Add integration tests only where hardware, protocol boundaries, or adapter behavior justify them.
- Mock only true boundaries. Prefer fakes or simple test doubles over heavy mocking.

## Change Strategy

- Make the smallest safe change that improves the design.
- Refactor opportunistically when touching code, but keep changes incremental.
- Preserve backward compatibility unless the task explicitly allows breaking changes.
- When introducing new abstractions, ensure they remove coupling or improve testability rather than adding ceremony.

## Practical Guidance For This Repository

- Keep sample application code separate from reusable library code.
- Avoid embedding protocol parsing directly inside serial port loops.
- Move byte parsing and frame assembly into dedicated, testable components.
- Ensure long-running listeners can stop cleanly via `CancellationToken`.
- Dispose `IDisposable` resources deterministically.
