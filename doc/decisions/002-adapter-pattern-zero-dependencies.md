# ADR-002: Adapter Pattern for Zero Dependencies

## Status

Accepted

## Date

2026-02-16

## Context

Flutter packages that depend on specific storage solutions (SharedPreferences, Hive, etc.) force consumers into those dependencies. This creates version conflicts, increases package size, and limits flexibility.

Similarly, hardcoding dialog UI prevents consumers from matching their app's design language.

## Decision

Use abstract adapter interfaces that consumers implement:

- **`ReviewStorageAdapter`** (required) — abstract key-value persistence interface with methods for `int`, `bool`, `DateTime`, and `String` types
- **`ReviewDialogAdapter`** (optional) — abstract interface for pre-dialog and feedback UI

The library ships with:
- `DefaultReviewDialogAdapter` — a Material Design implementation consumers can use out of the box
- `FakeStorageAdapter` and `FakeDialogAdapter` — test utilities exported via `testing.dart`

If no `ReviewDialogAdapter` is provided, the library requests the OS review directly (no emotional filter).

## Alternatives Considered

1. **Depend on SharedPreferences directly** — Rejected to avoid forcing a specific storage dependency
2. **Use a plugin system** — Rejected as overly complex for two simple interfaces
3. **Accept raw callbacks instead of interfaces** — Rejected because structured interfaces provide better type safety and testability

## Consequences

- Consumers must write a small adapter (typically 10-20 lines wrapping their storage solution)
- The library has exactly one runtime dependency: `in_app_review`
- Testing is straightforward with the provided fakes
- The example app demonstrates a `SharedPreferencesStorageAdapter` implementation as reference
