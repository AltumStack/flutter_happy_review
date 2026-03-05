# Project: Happy_Review

## What This Project Does

Flutter package that replaces launch-count-based in-app review prompts with an event-driven approach. Triggers review dialogs at moments of user satisfaction (e.g., after a purchase or workout streak). Published as `happy_review` on pub.dev by AltumStack.

## Architecture

@doc/ARCHITECTURE.md

## Tech Stack

@doc/STACK.md

## Conventions

@doc/CONVENTIONS.md

## Current Status

@doc/CURRENT_STATUS.md

## Key Decisions

@doc/decisions/_index.md

## Build & Run

All commands run from the `happy_review/` directory (the Flutter package root).

```bash
# Install dependencies
flutter pub get

# Run all tests
flutter test

# Run a single test file
flutter test test/happy_review_instance_test.dart

# Run tests with coverage (used in CI)
flutter test --coverage

# Analyze code (lint)
flutter analyze
```

The example app is at `happy_review/example/` and can be run with `flutter run` from that directory.

## Critical Rules

- Never add external storage dependencies to the library — use the adapter pattern (see ADR-002)
- All PRs target `develop`, never `main`
- No `Co-Authored-By` lines in commits — this is a community open-source library
- Library tests (`test/`) are for library internals only; example tests (`example/test/`) are for end-to-end scenarios
- Update `doc/CURRENT_STATUS.md` at the end of every work session
- Document significant technical decisions as ADRs in `doc/decisions/`

## Repository Structure Note

The Git repository root is `happy_review/` (not the top-level project directory). The `.git` directory, `.github/`, and `pubspec.yaml` all live inside `happy_review/`.
