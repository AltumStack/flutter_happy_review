## 0.2.1

* **Fix:** Prevent multiple dialogs from stacking when `logEvent()` is called concurrently. A new `_isFlowInProgress` guard blocks concurrent flows while still incrementing event counts.
* **New:** `ReviewFlowResult.flowAlreadyInProgress` — returned when a second `logEvent()` call arrives while a review flow is active.
* **New:** `DebugSnapshot.isFlowInProgress` field and corresponding row in `HappyReviewDebugPanel`.

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
