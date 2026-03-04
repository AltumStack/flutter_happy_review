# Tech Stack

## Language & Framework

| Technology | Version | Notes |
|-----------|---------|-------|
| Dart SDK | ^3.9.2 | |
| Flutter | >=1.17.0 | Minimum supported version |

## Dependencies

| Package | Version | Purpose |
|---------|---------|---------|
| `in_app_review` | ^2.0.10 | OS-native review prompt invocation |

## Dev Dependencies

| Package | Version | Purpose |
|---------|---------|---------|
| `flutter_test` | SDK | Testing framework |
| `flutter_lints` | ^5.0.0 | Lint rules (standard Flutter) |
| `mocktail` | ^1.0.4 | Mocking framework for tests |

## Supported Platforms

| Platform | Policy Defaults |
|----------|----------------|
| iOS | 120-day cooldown, 3 prompts/365 days |
| Android | 60-day cooldown, 3 prompts/365 days |
| macOS | Same as iOS |

## CI/CD

| Tool | Purpose |
|------|---------|
| GitHub Actions | CI pipeline (`code-coverage.yml`) |
| Codecov | Coverage reporting |

## Example App Additional Dependencies

| Package | Version | Purpose |
|---------|---------|---------|
| `shared_preferences` | ^2.3.4 | Example `ReviewStorageAdapter` implementation |
