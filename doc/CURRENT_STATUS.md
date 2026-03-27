# Current Project Status

Last updated: 2026-03-27

## In Progress

- [ ] Snooze mechanism and trigger counter reset (#30, PR #31) — ready for review, version bump to 0.3.0

## Recently Completed

- [x] Snooze cooldown for "remind me later" and dismiss (#30)
- [x] Trigger counter reset on engagement (positive/negative)
- [x] Handle OS review not available (`ReviewFlowResult.reviewNotAvailable`)
- [x] Pre-emptive snooze safety net for app kills during dialog
- [x] Fix debug mode — only enables logging, never bypasses pipeline stages
- [x] ADR-005 updated with GitHub CLI conventions
- [x] Rename docs/ to doc/ and add publish validation to CI
- [x] Prevent multiple dialogs when `logEvent()` is called concurrently (#28, PR #27)
- [x] Context-First Development (CFD) methodology (#26)
- [x] Debug dashboard widget and `getDebugSnapshot()` (#24)

## Open Issues

- #30 Snooze mechanism (feature, tier-1) — PR #31 open
- #4 Bottom sheet dialog variant (feature, tier-1)
- #11 Widget tests for default dialog adapters (testing, tier-2)
- #19 Ship `SharedPreferencesStorageAdapter` as companion package (enhancement, tier-2)
- #14 Theming support for default dialogs (enhancement, tier-3)

## Known Issues

- None currently tracked

## Next Priorities

1. Merge PR #31 (snooze mechanism + edge case fixes) → release 0.3.0
2. Bottom sheet dialog variant (#4) — tier-1
3. Widget tests for default dialog adapters (#11) — tier-2
4. SharedPreferencesStorageAdapter companion package (#19) — tier-2
