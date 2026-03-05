# ADR-003: Platform Policy as Independent Safety Layer

## Status

Accepted

## Date

2026-02-16

## Context

Apple and Google have strict guidelines about review prompt frequency. Apple can reject apps that prompt too frequently. Google Play has similar but less strict policies. If consumers misconfigure conditions (or skip them entirely), they risk store rejection.

## Decision

Implement `PlatformPolicyChecker` as an independent safety layer that operates regardless of user-defined conditions:

- Enforces per-platform cooldown periods and max prompts within a rolling window
- Default rules aligned with known store policies:
  - **iOS/macOS**: 120-day cooldown, max 3 prompts per 365 days
  - **Android**: 60-day cooldown, max 3 prompts per 365 days
- Consumers can override defaults via `PlatformPolicy` in `configure()`
- Platform policy is checked after prerequisites but before user conditions

The checker maintains its own storage keys (`platform_last_prompt`, `platform_prompt_timestamps`) separate from condition storage keys.

## Alternatives Considered

1. **Rely on user-defined conditions only** — Rejected because misconfiguration could lead to store rejection
2. **Hardcode platform rules without override** — Rejected because store policies evolve and some apps need flexibility
3. **Make platform policy a condition subclass** — Rejected to keep it as an independent, non-bypassable layer (except in debug mode)

## Consequences

- Consumers get store-safe defaults without configuration
- Platform policy can be relaxed for testing/development
- Debug mode bypasses platform policy for rapid iteration
- The safety layer runs independently, even if consumers define their own `CooldownPeriod` condition
