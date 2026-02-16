import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:happy_review/happy_review.dart';
import 'package:happy_review/testing.dart';

void main() {
  late FakeStorageAdapter storage;

  const relaxedPolicy = PlatformPolicy(
    android: PlatformRules(
      cooldown: Duration.zero,
      maxPrompts: 999,
      maxPromptsPeriod: Duration(days: 365),
    ),
    ios: PlatformRules(
      cooldown: Duration.zero,
      maxPrompts: 999,
      maxPromptsPeriod: Duration(days: 365),
    ),
    macOS: PlatformRules(
      cooldown: Duration.zero,
      maxPrompts: 999,
      maxPromptsPeriod: Duration(days: 365),
    ),
  );

  setUp(() {
    storage = FakeStorageAdapter();
  });

  group('HappyReviewDebugPanel', () {
    testWidgets('renders debug info after loading', (tester) async {
      await HappyReview.instance.configure(
        storageAdapter: storage,
        triggers: [
          const HappyTrigger(eventName: 'purchase', minOccurrences: 3),
        ],
        prerequisites: [
          const HappyTrigger(
              eventName: 'onboarding', minOccurrences: 1),
        ],
        conditions: [
          const MinDaysAfterInstall(days: 0),
        ],
        platformPolicy: relaxedPolicy,
        dialogAdapter: FakeDialogAdapter(),
        debugMode: true,
      );

      await tester.pumpWidget(
        const MaterialApp(home: Scaffold(body: HappyReviewDebugPanel())),
      );

      // Initially shows loading.
      expect(find.byType(CircularProgressIndicator), findsOneWidget);

      // Wait for snapshot to load.
      await tester.pumpAndSettle();

      expect(find.text('Happy Review Debug'), findsOneWidget);
      expect(find.text('Yes'), findsOneWidget); // enabled
      expect(find.text('On'), findsOneWidget); // debug mode
      expect(find.text('Configured'), findsOneWidget); // dialog adapter
      expect(find.text('0'), findsOneWidget); // prompts shown
      expect(find.text('Never'), findsOneWidget); // last prompt
      expect(find.text('purchase'), findsOneWidget); // trigger name
      expect(find.text('0/3'), findsOneWidget); // trigger count
      expect(find.text('onboarding'), findsOneWidget); // prerequisite
      expect(find.text('0/1'), findsOneWidget); // prerequisite count
      expect(find.text('Allows'), findsOneWidget); // platform policy
      expect(find.text('MinDaysAfterInstall'), findsOneWidget); // condition
      expect(find.text('Pass'), findsOneWidget); // condition status
    });

    testWidgets('refresh button reloads snapshot', (tester) async {
      await HappyReview.instance.configure(
        storageAdapter: storage,
        triggers: [
          const HappyTrigger(eventName: 'purchase', minOccurrences: 3),
        ],
        platformPolicy: relaxedPolicy,
        debugMode: true,
      );

      await tester.pumpWidget(
        const MaterialApp(home: Scaffold(body: HappyReviewDebugPanel())),
      );
      await tester.pumpAndSettle();

      expect(find.text('0/3'), findsOneWidget);

      // Simulate an event outside the widget.
      await storage.setInt('event_count_purchase', 2);

      // Tap refresh.
      await tester.tap(find.byIcon(Icons.refresh));
      await tester.pumpAndSettle();

      expect(find.text('2/3'), findsOneWidget);
    });

    testWidgets('shows disabled state', (tester) async {
      await HappyReview.instance.configure(
        storageAdapter: storage,
        triggers: [
          const HappyTrigger(eventName: 'purchase', minOccurrences: 1),
        ],
        platformPolicy: relaxedPolicy,
        enabled: false,
      );

      await tester.pumpWidget(
        const MaterialApp(home: Scaffold(body: HappyReviewDebugPanel())),
      );
      await tester.pumpAndSettle();

      expect(find.text('No'), findsOneWidget); // disabled
      expect(find.text('None (direct review)'), findsOneWidget); // no adapter
    });
  });
}
