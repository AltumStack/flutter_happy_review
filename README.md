# Happy Review
[![codecov](https://codecov.io/gh/AltumStack/flutter_happy_review/graph/badge.svg?token=P5G36QKKTP)](https://codecov.io/gh/AltumStack/flutter_happy_review)

## The Problem

Most apps request reviews based on how many times the app was opened. This is a bad practice:

- Opening the app doesn't mean enjoying it.
- You interrupt without context — the user hasn't accomplished anything yet.
- You actively generate negative reviews from annoyed users.
- You waste limited OS-level review invocations (Apple caps at 3/year).

## The Solution

Happy Review replaces the launch counter with an **event-driven** approach:

1. **Triggers** fire when the user completes a happy-path action (purchase, workout, delivery).
2. **Prerequisites** ensure baseline engagement before any trigger can activate (AND logic).
3. **Platform Policy** enforces per-platform frequency rules aligned with Apple/Google restrictions.
4. **Conditions** add business-level guards (days since install, cooldowns, custom logic).
5. **Emotional Filter** shows a pre-dialog ("Are you enjoying the app?") that routes satisfied users
   to the OS review and captures feedback from unsatisfied users — privately.

```text
logEvent() -> Trigger met? -> Prerequisites OK? -> Platform policy OK? -> Conditions pass?
                                                                              |
                                                                       Pre-dialog shown
                                                                      /       |        \
                                                                Positive   Later    Negative
                                                                   |         |          |
                                                            OS Review    Skip      Feedback form
```

## Use Cases

Happy Review is flexible enough to support any review-prompting strategy — from sophisticated
event-driven flows to the simplest launch-count approach.

### E-Commerce — Review after successful purchases

Ask for a review after the user has completed multiple purchases, ensuring they've experienced your
core value proposition.

```dart
await HappyReview.instance.configure(
  storageAdapter: myStorage,
  triggers: [
    const HappyTrigger(eventName: 'purchase_completed', minOccurrences: 3),
  ],
  prerequisites: [
    const HappyTrigger(eventName: 'onboarding_finished', minOccurrences: 1),
  ],
  dialogAdapter: DefaultReviewDialogAdapter(),
);

// After a successful purchase:
await HappyReview.instance.logEvent(context, 'purchase_completed');
```

### Fitness / Health — Review after achieving a streak

Trigger the review when the user has proven consistency and is most engaged.

```dart
await HappyReview.instance.configure(
  storageAdapter: myStorage,
  triggers: [
    const HappyTrigger(eventName: 'workout_completed', minOccurrences: 10),
    const HappyTrigger(eventName: 'streak_7_days', minOccurrences: 1),
  ],
  conditions: [
    const MinDaysAfterInstall(days: 14),
    const CooldownPeriod(days: 90),
  ],
  dialogAdapter: DefaultReviewDialogAdapter(
    preDialogConfig: const DefaultPreDialogConfig(
      title: 'Crushing your goals!',
      positiveLabel: 'Rate us!',
      negativeLabel: 'Could be better',
    ),
  ),
);
```

### Delivery / Logistics — Review after a successful delivery

The user just received their order — peak satisfaction.

```dart
await HappyReview.instance.configure(
  storageAdapter: myStorage,
  triggers: [
    const HappyTrigger(eventName: 'delivery_confirmed', minOccurrences: 2),
  ],
  conditions: [
    const MinDaysAfterInstall(days: 7),
    const MaxPromptsShown(maxPrompts: 3),
    CustomCondition(
      name: 'no_recent_complaint',
      evaluate: () async => !(await supportRepo.hasOpenTicket()),
    ),
  ],
  dialogAdapter: DefaultReviewDialogAdapter(),
);
```

### SaaS / Productivity — Review after completing a key workflow

Ask after the user has created content, exported a report, or hit a milestone.

```dart
await HappyReview.instance.configure(
  storageAdapter: myStorage,
  triggers: [
    const HappyTrigger(eventName: 'report_exported', minOccurrences: 5),
    const HappyTrigger(eventName: 'project_completed', minOccurrences: 1),
  ],
  prerequisites: [
    const HappyTrigger(eventName: 'profile_setup', minOccurrences: 1),
  ],
  dialogAdapter: DefaultReviewDialogAdapter(
    preDialogConfig: const DefaultPreDialogConfig(
      title: 'How is your experience?',
      positiveLabel: 'Great!',
      negativeLabel: 'Not great',
      remindLaterLabel: 'Ask me later',
    ),
  ),
);
```

### Gaming — Review after winning or reaching a level

Capture the dopamine hit right when the player is most excited.

```dart
await HappyReview.instance.configure(
  storageAdapter: myStorage,
  triggers: [
    const HappyTrigger(eventName: 'level_completed', minOccurrences: 10),
    const HappyTrigger(eventName: 'boss_defeated', minOccurrences: 1),
  ],
  conditions: [
    const MinDaysAfterInstall(days: 3),
    const CooldownPeriod(days: 60),
  ],
  dialogAdapter: DefaultReviewDialogAdapter(),
);
```

### Education — Review after completing a course module

The student just passed a test or finished a chapter — sense of accomplishment.

```dart
await HappyReview.instance.configure(
  storageAdapter: myStorage,
  triggers: [
    const HappyTrigger(eventName: 'module_completed', minOccurrences: 3),
    const HappyTrigger(eventName: 'certificate_earned', minOccurrences: 1),
  ],
  dialogAdapter: DefaultReviewDialogAdapter(
    preDialogConfig: const DefaultPreDialogConfig(
      title: 'Congrats on your progress!',
      positiveLabel: 'Love learning here!',
      negativeLabel: 'Needs improvement',
    ),
  ),
);
```

### Direct OS review — No emotional filter

Skip the pre-dialog entirely and request the OS review directly when triggers fire. Useful when
you've already validated satisfaction through other means.

```dart
await HappyReview.instance.configure(
  storageAdapter: myStorage,
  triggers: [
    const HappyTrigger(eventName: 'nps_score_9_or_10', minOccurrences: 1),
  ],
  // No dialogAdapter → OS review is requested directly.
);
```

### Simple launch count (advanced_in_app_review style)

If you still prefer the launch-count approach (e.g., ask after 5 app opens), Happy Review supports
it — though we recommend event-driven triggers for better results.

```dart
await HappyReview.instance.configure(
  storageAdapter: myStorage,
  triggers: [
    const HappyTrigger(eventName: 'app_opened', minOccurrences: 5),
  ],
  // No dialogAdapter, no conditions — just launch count + OS review.
);

// Call on every app start:
await HappyReview.instance.logEvent(context, 'app_opened');
```

### Remote kill switch with Firebase Remote Config

Disable review prompts instantly without deploying a new version.

```dart
final remoteConfig = FirebaseRemoteConfig.instance;
await remoteConfig.fetchAndActivate();

await HappyReview.instance.configure(
  storageAdapter: myStorage,
  enabled: remoteConfig.getBool('enable_review_prompt'),
  triggers: [
    const HappyTrigger(eventName: 'purchase_completed', minOccurrences: 3),
  ],
  dialogAdapter: DefaultReviewDialogAdapter(),
);

// Or toggle at runtime:
HappyReview.instance.setEnabled(remoteConfig.getBool('enable_review_prompt'));
```

## Installation

```yaml
dependencies:
  happy_review: ^0.1.0
```

## Platform Support

| Android | iOS | macOS |
|:-------:|:---:|:-----:|
|    ✅    |  ✅  |   ✅   |

## Quick Start

```dart
import 'package:happy_review/happy_review.dart';

// 1. Configure once at app startup.
await HappyReview.instance.configure(
  storageAdapter: MyStorageAdapter(), // You provide the implementation.
  triggers: [
    const HappyTrigger(eventName: 'purchase_completed', minOccurrences: 3),
  ],
  dialogAdapter: DefaultReviewDialogAdapter(),
);

// 2. Log events after happy-path actions.
await HappyReview.instance.logEvent(context, 'purchase_completed');
```

That's it. After 3 purchases, the pre-dialog appears. If the user responds positively, the OS review
is requested. If negatively, a feedback form is shown.

## Configuration

### Triggers

Define which events can activate the review flow (OR logic — any single trigger is enough):

```dart
triggers: [
  const HappyTrigger(eventName: 'purchase_completed', minOccurrences: 3),
  const HappyTrigger(eventName: 'streak_reached', minOccurrences: 1),
]
```

### Prerequisites

Events that must ALL have occurred before any trigger can fire (AND logic):

```dart
prerequisites: [
  // User must finish onboarding before any review flow can start.
  const HappyTrigger(eventName: 'onboarding_finished', minOccurrences: 1),
  // User must have used the app at least 5 times.
  const HappyTrigger(eventName: 'app_session', minOccurrences: 5),
]
```

This is useful for ensuring baseline engagement. Triggers are OR ("any of these can activate"),
prerequisites are AND ("all of these must be true first").

### Conditions

Add business rules that must all pass before the flow starts:

```dart
conditions: [
  // Wait at least 7 days after first launch.
  const MinDaysAfterInstall(days: 7),

  // Don't show more than 3 times total.
  const MaxPromptsShown(maxPrompts: 3),

  // Custom logic — anything you need.
  CustomCondition(
    name: 'no_recent_support_ticket',
    evaluate: () async => !(await supportRepo.hasRecentTicket()),
  ),
]
```

Built-in conditions:

| Condition             | Description                                     |
|-----------------------|-------------------------------------------------|
| `MinDaysAfterInstall` | Minimum days since first library initialization |
| `CooldownPeriod`      | Minimum days since the last prompt was shown    |
| `MaxPromptsShown`     | Maximum total prompts allowed                   |
| `CustomCondition`     | Arbitrary async logic via callback              |

### Platform Policy

Per-platform frequency rules that act as a safety layer aligned with OS restrictions:

```dart
platformPolicy: const PlatformPolicy(
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
onPreDialogRemindLater: () => analytics.log('user_remind_later'),
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
  preDialogConfig: const DefaultPreDialogConfig(
    title: 'Enjoying our app?',
    positiveLabel: 'Love it!',
    negativeLabel: 'Not really',
    remindLaterLabel: 'Maybe later', // Set to null to hide this button.
  ),
  feedbackConfig: const DefaultFeedbackDialogConfig(
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
    final result = await showModalBottomSheet<bool>(
      context: context,
      builder: (_) => MySatisfactionSheet(),
    );
    if (result == null) return PreDialogResult.dismissed;
    return result ? PreDialogResult.positive : PreDialogResult.negative;
  }

  @override
  Future<FeedbackResult?> showFeedbackDialog(BuildContext context) async {
    return Navigator.of(context).push<FeedbackResult>(
      MaterialPageRoute(builder: (_) => MyFeedbackScreen()),
    );
  }
}
```

**Option 3: No adapter (direct review)**

Omit `dialogAdapter` to skip the pre-dialog and request the OS review directly when triggers fire.

### Storage Adapter

Controls where event counts and internal state are persisted. This is a **required** parameter — the
library has zero opinion on your storage layer.

Implement `ReviewStorageAdapter` with your preferred backend:

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

The [example app](example/) includes a `SharedPreferencesStorageAdapter` you can use as reference or
copy directly into your project.

## Debug Mode

Enable debug mode during development to test the full dialog flow without OS restrictions:

```dart
await HappyReview.instance.configure(
  storageAdapter: myStorageAdapter,
  debugMode: true, // Bypasses platform policy and conditions.
  // ...
);
```

In debug mode:

- Platform policy checks are bypassed.
- All conditions are skipped.
- Prerequisites are bypassed.
- Detailed logs are printed via `debugPrint`.

## Kill Switch

Disable the library at runtime without redeploying (e.g., via remote config):

```dart
// At configure time:
await HappyReview.instance.configure(
  storageAdapter: myStorageAdapter,
  enabled: false, // All logEvent calls return ReviewFlowResult.disabled.
  // ...
);

// Or toggle at runtime:
HappyReview.instance.setEnabled(remoteConfig.getBool('enable_review_prompt'));
```

## Query State

Inspect internal state without triggering the review flow:

```dart
// How many times has this event been logged?
final count = await HappyReview.instance.getEventCount('purchase_completed');

// How many times has the review prompt been shown?
final prompts = await HappyReview.instance.getPromptsShownCount();

// When was the last prompt shown?
final lastDate = await HappyReview.instance.getLastPromptDate();
```

## Return Values

`logEvent` returns a `ReviewFlowResult` so you know exactly what happened:

| Result                    | Meaning                                         |
|---------------------------|-------------------------------------------------|
| `disabled`                | Library is disabled via kill switch             |
| `noTrigger`               | No trigger matched for this event               |
| `prerequisitesNotMet`     | One or more prerequisites are not satisfied     |
| `blockedByPlatformPolicy` | Platform frequency limit reached                |
| `conditionsNotMet`        | A condition returned false                      |
| `reviewRequested`         | User was happy; OS review requested             |
| `reviewRequestedDirect`   | No dialog adapter; OS review requested directly |
| `feedbackSubmitted`       | User was unhappy; feedback collected            |
| `remindLater`             | User chose to be reminded later                 |
| `dialogDismissed`         | User dismissed without choosing                 |

## Full Example

See the [example app](example/) for a complete working demo that simulates an e-commerce happy flow
with prerequisites, debug mode, and kill switch.

## Contributing

Contributions are welcome! Please open an issue or submit a pull request
on [GitHub](https://github.com/AltumStack/flutter_happy_review).

## License

MIT
