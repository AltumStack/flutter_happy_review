# ADR-005: GitHub Workflow Conventions

## Status

Accepted

## Date

2026-03-04 (updated 2026-03-27)

## Context

As the project matures with more issues, PRs, and releases, we need consistent GitHub workflows so that any contributor (human or AI) can create issues, branches, and PRs that follow the same standards. Without documented conventions, PRs get created with missing labels, no project board link, or inconsistent branch names.

## Decision

### Tooling: GitHub CLI (`gh`)

All GitHub operations (issues, PRs, project board management) are performed via GitHub CLI (`gh`). The CLI is authenticated in the development environment and must be used instead of the web UI for reproducibility.

**Key commands:**

```bash
# Issues
gh issue create --title "..." --label "feature,tier-1" --assignee "AMarturelo" --body "..."
gh issue list --state open --limit 10
gh issue edit <number> --add-project "Happy Review Roadmap"

# Pull requests
gh pr create --base develop --title "..." --assignee AMarturelo --label "feature,tier-1" --body "..."
gh pr list --state open

# Project board — move issue to "In Progress"
# Requires resolving project, item, field, and option IDs:
PROJECT_NUM=3  # Happy Review Roadmap
ITEM_ID=$(gh project item-list $PROJECT_NUM --owner AltumStack --format json | ...)
gh project item-edit --project-id "$PROJECT_NODE_ID" --id "$ITEM_ID" \
  --field-id "$STATUS_FIELD_ID" --single-select-option-id "$IN_PROGRESS_OPTION_ID"
```

**Project board identifiers (AltumStack org):**

| Resource | Value |
|----------|-------|
| Project name | Happy Review Roadmap |
| Project number | 3 |
| Owner | AltumStack |

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

### Commit Messages

Follow [Conventional Commits](https://www.conventionalcommits.org/):

| Prefix | Use for |
|--------|---------|
| `feat:` | New feature or functionality |
| `fix:` | Bug fix |
| `refactor:` | Code restructuring without behavior change |
| `docs:` | Documentation only |
| `test:` | Adding or updating tests |
| `chore:` | Maintenance (CI, deps, tooling) |

Include the issue number in the subject when applicable: `feat: snooze mechanism (#30)`.

**No `Co-Authored-By` lines** — this is a community open-source library.

### PR Template

Located at `.github/PULL_REQUEST_TEMPLATE.md`. Every PR must fill in:

1. **Summary** — 1-3 bullet points describing the change
2. **Type of change** — checkbox selection (bug fix, feature, breaking, refactor, docs)
3. **Checklist** — tests pass, analysis clean, CHANGELOG updated, README if public API changed

### PR Metadata

| Field | Rule | `gh` flag |
|-------|------|-----------|
| **Assignee** | Always `AMarturelo` | `--assignee AMarturelo` |
| **Project** | Always link to `Happy Review Roadmap` (#3) | `gh issue edit --add-project` or PR body |
| **Labels** | Carry over from linked issue | `--label "feature,tier-1"` |
| **Base branch** | `develop` (never `main`) | `--base develop` |
| **Linked issue** | Use `Closes #N` in PR body for auto-close | Include in `--body` |

### Branch Naming

| Prefix | Use for |
|--------|---------|
| `fix/` | Bug fixes (e.g., `fix/concurrent-flow-guard`) |
| `feature/` | New features (e.g., `feature/bottom-sheet-dialog`) |
| `release/` | Release candidates (e.g., `release/0.2.1`) |
| `chore/` | Maintenance tasks (e.g., `chore/rename-docs-dir`) |

### Issue → PR → Merge Flow

1. `gh issue create` with type + tier labels and assignee
2. `gh issue edit <N> --add-project "Happy Review Roadmap"` and move to "In Progress"
3. `git checkout -b <prefix>/<name> develop`
4. Implement, then `gh pr create --base develop` with template, labels, assignee, and `Closes #N`
5. CI must pass: `flutter analyze`, `flutter test`, `dart pub publish --dry-run`
6. Merge to `develop`; issue auto-closes via `Closes #N`

### Release Flow

1. `git checkout -b release/x.y.z develop`
2. Bump version in `pubspec.yaml`, update CHANGELOG and README
3. `gh pr create --base master` with release labels
4. Merge to `master`, tag (`git tag vx.y.z`), push tag, publish to pub.dev

### CI Checks

All PRs must pass before merge:

| Check | Command |
|-------|---------|
| Lint | `flutter analyze` |
| Tests | `flutter test` |
| Publish readiness | `dart pub publish --dry-run` |

## Alternatives Considered

1. **No formal conventions** — Rejected because inconsistency increases friction and causes rework
2. **GitHub issue templates** — Considered but deferred; the current issue volume doesn't justify the overhead yet. Can be added later when more external contributors join
3. **Automated label enforcement via GitHub Actions** — Considered but deferred for the same reason; manual discipline is sufficient at current scale
4. **Web UI instead of `gh` CLI** — Rejected because CLI operations are scriptable, reproducible by AI agents, and faster for repetitive metadata tasks

## Consequences

- Every PR follows a predictable structure that any contributor can replicate
- `gh` CLI ensures all GitHub operations are reproducible and scriptable
- Project board stays accurate because issues are always linked and moved via CLI
- Labels enable filtering and prioritization across issues and PRs
- CI validates code quality and publish-readiness before merge
- AI agents can execute the full issue-to-PR workflow without web UI access
- Small overhead per PR (~2 minutes to fill metadata) but prevents rework from missing information
