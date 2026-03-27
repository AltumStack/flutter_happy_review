## 0.3.0

* **New:** Snooze mechanism — when the user chooses "remind me later" or dismisses the dialog, a configurable cooldown prevents immediate re-prompting. Configure via `remindLaterCooldown` in `configure()` (defaults to 1 day).
* **New:** Trigger counter resets on engagement — after a positive or negative response, the event counter for the matched trigger resets to zero. The user must reach `minOccurrences` again before the dialog can fire, combined with platform policy for time-based protection.
* **New:** `ReviewFlowResult.snoozed` indicates the flow was blocked by an active snooze cooldown.
* **New:** `DebugSnapshot` includes `isSnoozed` and `snoozeUntil` fields; the debug panel displays snooze state.
* **Fix:** Trigger counter is no longer reset when the OS in-app review is unavailable. Returns `ReviewFlowResult.reviewNotAvailable`. When a pre-dialog was shown, the prompt is still recorded (the user did interact); when no dialog adapter is configured, nothing is recorded.
* **Fix:** Pre-emptive snooze safety net — if the app is killed while the dialog is visible, the snooze prevents immediate re-prompting on next launch.
* **Fix:** Debug mode no longer bypasses the snooze check. It only enables logging, consistent with all other pipeline stages.
* **Breaking:** `ReviewFlowResult` has new enum values `snoozed` and `reviewNotAvailable`. Exhaustive `switch` statements must handle both.

## 0.2.0

* **Fix:** "Remind later" and "dismissed" no longer count as a shown prompt. Previously, platform policy, cooldown, and max prompts counters were incremented before the dialog was shown — burning a prompt slot even when the user didn't engage. Now, counters are only updated on positive or negative responses.
* **Breaking:** Debug mode no longer bypasses prerequisites, platform policy, or conditions. It now only enables detailed logging via `debugPrint`. Use a relaxed `PlatformPolicy` to test the dialog flow during development.
* **Fix:** `reset()` now re-records the install date after clearing storage, so `MinDaysAfterInstall` continues to work correctly after a reset.
* **Fix:** `PlatformPolicy` now includes a `macOS` field with iOS defaults. Previously macOS silently fell back to Android rules.
* **New:** `happy_review/testing.dart` exports `FakeStorageAdapter` and `FakeDialogAdapter` so consumers can test their integration without a mocking library.
* **New:** `HappyReviewDebugPanel` widget and `getDebugSnapshot()` method for inspecting internal state during development.

## 0.1.0

* Initial release.
* Event-driven triggers with configurable minimum occurrences.
* Prerequisites (AND logic) to ensure baseline engagement before triggers fire.
* Per-platform policy rules aligned with Apple and Google restrictions.
* Emotional filter pre-dialog with positive, negative, remind later, and dismiss outcomes.
* Feedback collection dialog for unsatisfied users.
* Adapter pattern for fully customizable dialog UI and storage backend.
* Built-in conditions: MinDaysAfterInstall, CooldownPeriod, MaxPromptsShown, CustomCondition.
* Debug mode for detailed logging during development.
* Kill switch to enable/disable the library at runtime.
* Query methods for event counts, prompts shown, and last prompt date.
* Callbacks for every step of the review flow.
