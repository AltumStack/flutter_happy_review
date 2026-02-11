# Happy Review

A strategic in-app review library for Flutter that triggers review prompts at **proven moments of user satisfaction**, not arbitrary launch counts.

## The Problem

Most apps request reviews based on how many times the app was opened. This is a bad practice:

- Opening the app doesn't mean enjoying it.
- You interrupt without context — the user hasn't accomplished anything yet.
- You actively generate negative reviews from annoyed users.
- You waste limited OS-level review invocations (Apple caps at 3/year).

## The Solution

Happy Review replaces the launch counter with an **event-driven** approach:

1. **Triggers** fire when the user completes a happy-path action (purchase, workout, delivery).
2. **Platform Policy** enforces per-platform frequency rules aligned with Apple/Google restrictions.
3. **Conditions** add business-level guards (days since install, cooldowns, custom logic).
4. **Emotional Filter** shows a pre-dialog ("Are you enjoying the app?") that routes satisfied users to the OS review and captures feedback from unsatisfied users — privately.

```text
logEvent() -> Trigger met? -> Platform policy OK? -> Conditions pass?
                                                          |
                                                    Pre-dialog shown
                                                     /           \
                                                Positive      Negative
                                                   |              |
                                            OS In-App Review   Feedback form
```

## Installation

```yaml
dependencies:
  happy_review: ^0.1.0
```

## Quick Start

```dart
import 'package:happy_review/happy_review.dart';

// 1. Configure once at app startup.
await HappyReview.instance.configure(
  triggers: [
    HappyTrigger(eventName: 'purchase_completed', minOccurrences: 3),
  ],
  dialogAdapter: DefaultReviewDialogAdapter(),
);

// 2. Log events after happy-path actions.
await HappyReview.instance.logEvent(context, 'purchase_completed');
```

That's it. After 3 purchases, the pre-dialog appears. If the user responds positively, the OS review is requested. If negatively, a feedback form is shown.

## Configuration

### Triggers

Define which events can activate the review flow:

```dart
triggers: [
  HappyTrigger(eventName: 'purchase_completed', minOccurrences: 3),
  HappyTrigger(eventName: 'onboarding_finished', minOccurrences: 1),
  HappyTrigger(eventName: 'streak_reached', minOccurrences: 1),
]
```

### Conditions

Add business rules that must all pass before the flow starts:

```dart
conditions: [
  // Wait at least 7 days after first launch.
  MinDaysAfterInstall(days: 7),

  // Don't show more than 3 times total.
  MaxPromptsShown(maxPrompts: 3),

  // Custom logic — anything you need.
  CustomCondition(
    name: 'no_recent_support_ticket',
    evaluate: () async => !(await supportRepo.hasRecentTicket()),
  ),
]
```

Built-in conditions:

| Condition | Description |
| --- | --- |
| `MinDaysAfterInstall` | Minimum days since first library initialization |
| `CooldownPeriod` | Minimum days since the last prompt was shown |
| `MaxPromptsShown` | Maximum total prompts allowed |
| `CustomCondition` | Arbitrary async logic via callback |

### Platform Policy

Per-platform frequency rules that act as a safety layer aligned with OS restrictions:

```dart
platformPolicy: PlatformPolicy(
  ios: PlatformRules(
    cooldown: Duration(days: 120),
    maxPrompts: 3,
    maxPromptsPeriod: Duration(days: 365),
  ),
  android: PlatformRules(
    cooldown: Duration(days: 60),
    maxPrompts: 3,
    maxPromptsPeriod: Duration(days: 365),
  ),
)
```

Sensible defaults are applied if you don't specify a policy.

### Callbacks

React to every step of the review flow:

```dart
onPreDialogShown: () => analytics.log('pre_dialog_shown'),
onPreDialogPositive: () => analytics.log('user_happy'),
onPreDialogNegative: () => analytics.log('user_unhappy'),
onPreDialogDismissed: () => analytics.log('dialog_dismissed'),
onReviewRequested: () => analytics.log('os_review_requested'),
onFeedbackSubmitted: (feedback) => sendToBackend(feedback),
```

## Adapters

Happy Review uses adapters so you control **how** things look and **where** state is stored.

### Dialog Adapter

Controls the pre-dialog and feedback UI.

**Option 1: Default adapter with config**

```dart
dialogAdapter: DefaultReviewDialogAdapter(
  preDialogConfig: DefaultPreDialogConfig(
    title: 'Enjoying our app?',
    positiveLabel: 'Love it!',
    negativeLabel: 'Not really',
  ),
  feedbackConfig: DefaultFeedbackDialogConfig(
    title: 'What could we improve?',
    categories: ['Performance', 'Design', 'Features'],
    showContactOption: true,
  ),
)
```

**Option 2: Fully custom UI**

Implement `ReviewDialogAdapter` to use your own widgets:

```dart
class MyReviewDialogAdapter extends ReviewDialogAdapter {
  @override
  Future<PreDialogResult> showPreDialog(BuildContext context) async {
    // Show your own bottom sheet, full-screen dialog, etc.
    final result = await showModalBottomSheet<bool>(
      context: context,
      builder: (_) => MySatisfactionSheet(),
    );
    if (result == null) return PreDialogResult.dismissed;
    return result ? PreDialogResult.positive : PreDialogResult.negative;
  }

  @override
  Future<FeedbackResult?> showFeedbackDialog(BuildContext context) async {
    // Navigate to your own feedback screen.
    return Navigator.of(context).push<FeedbackResult>(
      MaterialPageRoute(builder: (_) => MyFeedbackScreen()),
    );
  }
}
```

**Option 3: No adapter (direct review)**

Omit `dialogAdapter` to skip the pre-dialog and request the OS review directly when triggers fire.

### Storage Adapter

Controls where event counts and internal state are persisted.

**Default:** `SharedPreferencesStorageAdapter` (no extra dependencies).

**Custom:** Implement `ReviewStorageAdapter`:

```dart
class HiveStorageAdapter extends ReviewStorageAdapter {
  final Box _box;
  HiveStorageAdapter(this._box);

  @override
  Future<int> getInt(String key, {int defaultValue = 0}) async =>
      _box.get(key, defaultValue: defaultValue);

  @override
  Future<void> setInt(String key, int value) => _box.put(key, value);

  // ... implement remaining methods
}
```

Then pass it:

```dart
storageAdapter: HiveStorageAdapter(Hive.box('reviews'))
```

## Return Values

`logEvent` returns a `ReviewFlowResult` so you know exactly what happened:

| Result | Meaning |
| --- | --- |
| `noTrigger` | No trigger matched for this event |
| `blockedByPlatformPolicy` | Platform frequency limit reached |
| `conditionsNotMet` | A condition returned false |
| `reviewRequested` | User was happy; OS review requested |
| `reviewRequestedDirect` | No dialog adapter; OS review requested directly |
| `feedbackSubmitted` | User was unhappy; feedback collected |
| `dialogDismissed` | User dismissed without choosing |

## Full Example

See the [example app](example/) for a complete working demo that simulates an e-commerce happy flow.

## License

MIT
