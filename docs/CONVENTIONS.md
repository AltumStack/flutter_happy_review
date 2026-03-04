# Conventions

## Code Style

- Lint rules: `package:flutter_lints/flutter.yaml` (standard Flutter)
- Run `flutter analyze` before committing — must pass with zero issues

## Architecture Patterns

- **Singleton access**: Always `HappyReview.instance`, never direct construction
- **Adapter pattern**: All external concerns (storage, UI) go through abstract interfaces
- **Zero library dependencies**: The library never depends on specific storage or UI packages
- **Pipeline short-circuit**: Each stage returns a specific `ReviewFlowResult` on failure
- **Triggers = OR logic**: Any single trigger fires the flow
- **Prerequisites/Conditions = AND logic**: All must pass

## Testing

- **Mocking**: Use `mocktail` — mocks defined in `test/mocks.dart`
- **Storage**: Use `FakeStorageAdapter` (in-memory map) — never mock storage interface methods directly
- **Dialog**: Use `FakeDialogAdapter` for predictable dialog results, `MockDialogAdapter` when verifying interactions
- **Library tests** (`test/`): Unit tests for library internals only
- **Example tests** (`example/test/`): End-to-end and integration tests replicating real app behavior
- **InAppReview**: Injectable via `@visibleForTesting setInAppReviewInstance()` — mock with `MockInAppReview`
- **Platform policy in tests**: Use relaxed policy (zero cooldown, 999 max) to avoid false test failures

## Git & PR Conventions

- **Base branch**: `develop` (all PRs target `develop`, not `main`)
- **Commit messages**: No `Co-Authored-By` lines — this is a community open-source library
- **PR assignee**: Always `AMarturelo`
- **PR project**: Always link to `Happy Review Roadmap` (#3)
- **PR labels**: Carry over from linked issue
- **PR template**: Located at `.github/PULL_REQUEST_TEMPLATE.md`

## File Organization

- `lib/happy_review.dart` — public API barrel (exports everything consumers need)
- `lib/testing.dart` — test utilities barrel (fakes for consumer tests)
- `lib/src/` — all implementation files (never import `src/` directly)
- `assets/` — Project assets (screenshots, images)
- `docs/` — CFD context documents (architecture, decisions, status)

## Naming

- Files: `snake_case.dart`
- Classes: `PascalCase`
- Conditions: Named after their behavior (`MinDaysAfterInstall`, `CooldownPeriod`)
- Storage keys: `snake_case` strings (`event_count_$eventName`, `prompts_shown_count`)
