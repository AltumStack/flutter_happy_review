# ADR-005: GitHub Workflow Conventions

## Status

Accepted

## Date

2026-03-04

## Context

As the project matures with more issues, PRs, and releases, we need consistent GitHub workflows so that any contributor (human or AI) can create issues, branches, and PRs that follow the same standards. Without documented conventions, PRs get created with missing labels, no project board link, or inconsistent branch names.

## Decision

### Labels

Use a two-dimensional labeling system:

**Type labels** (what kind of work):

| Label | Use for |
|-------|---------|
| `bug` | Something broken |
| `feature` | New functionality |
| `enhancement` | Improvement to existing feature |
| `documentation` | Docs-only changes |
| `testing` | Test coverage and utilities |
| `dx` | Developer experience improvements |

**Impact labels** (priority tier):

| Label | Meaning |
|-------|---------|
| `tier-1` | High impact — address in next release |
| `tier-2` | Medium impact — plan for upcoming work |
| `tier-3` | Nice to have — backlog |

Every issue and PR must have at least one type label and one tier label. PRs inherit labels from their linked issue.

### PR Template

Located at `.github/PULL_REQUEST_TEMPLATE.md`. Every PR must fill in:

1. **Summary** — 1-3 bullet points describing the change
2. **Type of change** — checkbox selection (bug fix, feature, breaking, refactor, docs)
3. **Checklist** — tests pass, analysis clean, CHANGELOG updated, README if public API changed

### PR Metadata

| Field | Rule |
|-------|------|
| **Assignee** | Always `AMarturelo` |
| **Project** | Always link to `Happy Review Roadmap` (#3) |
| **Labels** | Carry over from linked issue |
| **Base branch** | `develop` (never `main`) |
| **Linked issue** | Use `Closes #N` in PR body for auto-close |

### Branch Naming

| Prefix | Use for |
|--------|---------|
| `fix/` | Bug fixes (e.g., `fix/concurrent-flow-guard`) |
| `feature/` | New features (e.g., `feature/bottom-sheet-dialog`) |
| `release/` | Release candidates (e.g., `release/0.2.1`) |
| `chore/` | Maintenance tasks (e.g., `chore/rename-docs-dir`) |

### Issue → PR → Merge Flow

1. Create issue with type + tier labels
2. Move issue to "In Progress" on project board
3. Create branch from `develop` with appropriate prefix
4. Open PR targeting `develop` with template filled, labels, assignee, and project linked
5. CI must pass: `flutter analyze`, `flutter test`, `dart pub publish --dry-run`
6. Merge to `develop`; issue auto-closes via `Closes #N`

### Release Flow

1. Create `release/x.y.z` branch from `develop`
2. Bump version in `pubspec.yaml`, update CHANGELOG and README
3. Open PR targeting `master` with release labels
4. Merge to `master`, tag, and publish to pub.dev

## Alternatives Considered

1. **No formal conventions** — Rejected because inconsistency increases friction and causes rework
2. **GitHub issue templates** — Considered but deferred; the current issue volume doesn't justify the overhead yet. Can be added later when more external contributors join
3. **Automated label enforcement via GitHub Actions** — Considered but deferred for the same reason; manual discipline is sufficient at current scale

## Consequences

- Every PR follows a predictable structure that any contributor can replicate
- Project board stays accurate because issues are always linked
- Labels enable filtering and prioritization across issues and PRs
- CI validates code quality and publish-readiness before merge
- Small overhead per PR (~2 minutes to fill metadata) but prevents rework from missing information
