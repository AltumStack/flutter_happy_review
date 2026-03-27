# Architecture Overview

## System Diagram

```
Consumer App
     │
     ▼
┌─────────────────────────────────────────────────────┐
│  HappyReview.instance  (Singleton)                  │
│                                                     │
│  configure() ──► logEvent(context, eventName)       │
│                       │                             │
│                       ▼                             │
│              ┌─────────────────┐                    │
│              │ Increment Count │                    │
│              └────────┬────────┘                    │
│                       ▼                             │
│              ┌─────────────────┐                    │
│              │ Trigger Match?  │  (OR logic)        │
│              └────────┬────────┘                    │
│                       ▼                             │
│              ┌─────────────────┐                    │
│              │ Snooze Active?  │  (remind later)    │
│              └────────┬────────┘                    │
│                       ▼                             │
│              ┌─────────────────┐                    │
│              │ Prerequisites?  │  (AND logic)       │
│              └────────┬────────┘                    │
│                       ▼                             │
│              ┌─────────────────┐                    │
│              │ Platform Policy │  (safety layer)    │
│              └────────┬────────┘                    │
│                       ▼                             │
│              ┌─────────────────┐                    │
│              │ Conditions?     │  (AND logic)       │
│              └────────┬────────┘                    │
│                       ▼                             │
│              ┌─────────────────┐                    │
│              │ Execute Flow    │                    │
│              └─────────────────┘                    │
│                   │        │                        │
│          ┌────────┘        └────────┐               │
│          ▼                          ▼               │
│   ReviewDialogAdapter      Direct OS Review         │
│   (pre-dialog + feedback)  (no adapter)             │
└─────────────────────────────────────────────────────┘
         │                          │
         ▼                          ▼
  ReviewStorageAdapter        in_app_review
  (consumer-provided)         (OS native)
```

## Layer Structure

- **Public API**: `HappyReview` singleton, models, adapters, conditions (`lib/happy_review.dart` barrel)
- **Testing API**: `FakeStorageAdapter`, `FakeDialogAdapter` (`lib/testing.dart` barrel)
- **Core Logic**: `lib/src/happy_review_instance.dart` — pipeline orchestration
- **Adapters**: `lib/src/adapters/` — storage and dialog interfaces + default dialog
- **Conditions**: `lib/src/conditions/` — review condition system
- **Models**: `lib/src/models/` — data types and enums
- **Widgets**: `lib/src/widgets/` — debug panel
- **Testing Utilities**: `lib/src/testing/` — fakes for consumer tests

## Module Map

| Module | Purpose | Key Files |
|--------|---------|-----------|
| Core | Singleton + pipeline orchestration | `lib/src/happy_review_instance.dart` |
| Adapters | Storage and dialog interfaces | `lib/src/adapters/` |
| Conditions | Review gating conditions | `lib/src/conditions/` |
| Platform Policy | OS-level frequency enforcement | `lib/src/platform_policy_checker.dart` |
| Models | Data types and enums | `lib/src/models/` |
| Widgets | Debug panel | `lib/src/widgets/` |
| Testing | Fakes for consumer tests | `lib/src/testing/` |

## Key Patterns

### Singleton

`HappyReview.instance` — single instance manages all state. Configured once at app startup via `configure()`, then events are logged via `logEvent()`.

### Adapter Pattern

The library has zero external dependencies for storage or UI. Consumers inject:
- `ReviewStorageAdapter` (required) — key-value persistence interface
- `ReviewDialogAdapter` (optional) — pre-dialog and feedback UI

### Pipeline Short-Circuit

Each stage returns a specific `ReviewFlowResult` enum value on failure, preventing unnecessary evaluation of later stages.

### Debug Mode

When enabled, bypasses snooze, prerequisites, platform policy, and conditions. Only trigger matching is evaluated. The `HappyReviewDebugPanel` widget visualizes internal state.

## Storage Keys

The library writes these keys to `ReviewStorageAdapter`:

| Key | Type | Purpose |
|-----|------|---------|
| `event_count_$eventName` | int | Per-event occurrence counter |
| `prompts_shown_count` | int | Total prompts shown |
| `last_prompt_date` | DateTime | Last prompt timestamp |
| `install_date` | DateTime | First `configure()` date |
| `remind_later_date` | DateTime | Last "remind later" or dismiss timestamp |
| `platform_last_prompt` | DateTime | Last prompt for policy check |
| `platform_prompt_timestamps` | String | Comma-separated ms timestamps |
