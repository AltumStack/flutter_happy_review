## 0.2.0

* **Fix:** "Remind later" and "dismissed" no longer count as a shown prompt. Previously, platform policy, cooldown, and max prompts counters were incremented before the dialog was shown — burning a prompt slot even when the user didn't engage. Now, counters are only updated on positive or negative responses.

## 0.1.0

* Initial release.
* Event-driven triggers with configurable minimum occurrences.
* Prerequisites (AND logic) to ensure baseline engagement before triggers fire.
* Per-platform policy rules aligned with Apple and Google restrictions.
* Emotional filter pre-dialog with positive, negative, remind later, and dismiss outcomes.
* Feedback collection dialog for unsatisfied users.
* Adapter pattern for fully customizable dialog UI and storage backend.
* Built-in conditions: MinDaysAfterInstall, CooldownPeriod, MaxPromptsShown, CustomCondition.
* Debug mode to bypass policies and conditions during development.
* Kill switch to enable/disable the library at runtime.
* Query methods for event counts, prompts shown, and last prompt date.
* Callbacks for every step of the review flow.
