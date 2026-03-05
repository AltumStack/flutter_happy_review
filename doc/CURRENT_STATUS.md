# Current Project Status

Last updated: 2026-03-04

## In Progress

- [ ] Implementing Context-First Development (CFD) methodology
  - Structuring docs/, decisions/, and slash commands
  - Restructuring CLAUDE.md as Level 0 index

## Recently Completed

- [x] Prevent multiple dialogs when `logEvent()` is called concurrently
- [x] Debug dashboard widget and `getDebugSnapshot()` (#24)
- [x] Export test utilities (`FakeStorageAdapter`, `FakeDialogAdapter`) (#23)
- [x] macOS platform policy support (#22)
- [x] Fix triggers firing repeatedly after threshold (#21)
- [x] CocoaPods integration for macOS example

## Open Issues

- #19 Ship `SharedPreferencesStorageAdapter` as companion package (enhancement, tier-2)
- #14 Theming support for default dialogs (enhancement, tier-3)
- #11 Widget tests for default dialog adapters (testing, tier-2)
- #4 Bottom sheet dialog variant (feature, tier-1)

## Known Issues

- None currently tracked

## Next Priorities

1. Complete CFD implementation
2. Bottom sheet dialog variant (#4) — tier-1
3. Widget tests for default dialog adapters (#11) — tier-2
4. SharedPreferencesStorageAdapter companion package (#19) — tier-2
