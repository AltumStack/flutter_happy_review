# ADR-001: Event-Driven Review Architecture

## Status

Accepted

## Date

2026-02-16

## Context

Most in-app review libraries use launch-count-based triggers (e.g., "show review after 10 app opens"). This approach is disconnected from user sentiment — a user who opened the app 10 times but had a bad experience is not a good candidate for a review prompt.

We needed an architecture that triggers review prompts at moments of genuine user satisfaction (e.g., after completing a purchase, reaching a streak milestone).

## Decision

Implement a singleton (`HappyReview.instance`) with a sequential pipeline evaluated on every `logEvent()` call:

```
logEvent() -> Increment count -> Trigger match? -> Prerequisites met? -> Platform policy OK? -> Conditions pass? -> Execute flow
```

Key design choices:
- **Triggers use OR logic**: Any single trigger firing is enough to start the flow
- **Prerequisites use AND logic**: All must be met before the flow can proceed
- **Conditions use AND logic**: All custom conditions must pass
- **Each stage short-circuits** with a specific `ReviewFlowResult` enum value

## Alternatives Considered

1. **Launch-count approach** — Rejected because it's disconnected from user sentiment
2. **Time-based approach** (show after X days) — Rejected as it doesn't correlate with satisfaction
3. **Manual trigger only** (developer calls `showReview()` directly) — Rejected because it lacks the safety layers (conditions, platform policy) that prevent over-prompting

## Consequences

- Consumers must define meaningful events in their app lifecycle
- The pipeline adds complexity but provides fine-grained control over when reviews are shown
- Debug mode can bypass all checks except trigger matching for testing
