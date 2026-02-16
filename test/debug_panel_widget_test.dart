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

    testWidgets('shows met triggers and prerequisites in green',
        (tester) async {
      await HappyReview.instance.configure(
        storageAdapter: storage,
        triggers: [
          const HappyTrigger(eventName: 'purchase', minOccurrences: 2),
        ],
        prerequisites: [
          const HappyTrigger(
              eventName: 'onboarding', minOccurrences: 1),
        ],
        platformPolicy: relaxedPolicy,
        debugMode: true,
      );

      // Simulate counts that satisfy both.
      await storage.setInt('event_count_purchase', 5);
      await storage.setInt('event_count_onboarding', 1);

      await tester.pumpWidget(
        const MaterialApp(home: Scaffold(body: HappyReviewDebugPanel())),
      );
      await tester.pumpAndSettle();

      expect(find.text('5/2'), findsOneWidget); // trigger met
      expect(find.text('1/1'), findsOneWidget); // prerequisite met
    });

    testWidgets('shows blocked platform policy', (tester) async {
      // Policy with very long cooldown that will block.
      const blockingPolicy = PlatformPolicy(
        android: PlatformRules(
          cooldown: Duration(days: 9999),
          maxPrompts: 999,
          maxPromptsPeriod: Duration(days: 365),
        ),
        ios: PlatformRules(
          cooldown: Duration(days: 9999),
          maxPrompts: 999,
          maxPromptsPeriod: Duration(days: 365),
        ),
        macOS: PlatformRules(
          cooldown: Duration(days: 9999),
          maxPrompts: 999,
          maxPromptsPeriod: Duration(days: 365),
        ),
      );

      await HappyReview.instance.configure(
        storageAdapter: storage,
        triggers: [
          const HappyTrigger(eventName: 'purchase', minOccurrences: 1),
        ],
        platformPolicy: blockingPolicy,
        debugMode: true,
      );

      // Record a prompt so cooldown kicks in.
      await storage.setDateTime('platform_last_prompt', DateTime.now());

      await tester.pumpWidget(
        const MaterialApp(home: Scaffold(body: HappyReviewDebugPanel())),
      );
      await tester.pumpAndSettle();

      expect(find.text('Blocked'), findsOneWidget);
    });

    testWidgets('shows failing condition', (tester) async {
      await HappyReview.instance.configure(
        storageAdapter: storage,
        triggers: [
          const HappyTrigger(eventName: 'purchase', minOccurrences: 1),
        ],
        conditions: [
          CustomCondition(
            name: 'always_fails',
            evaluate: () async => false,
          ),
        ],
        platformPolicy: relaxedPolicy,
        debugMode: true,
      );

      await tester.pumpWidget(
        const MaterialApp(home: Scaffold(body: HappyReviewDebugPanel())),
      );
      await tester.pumpAndSettle();

      expect(find.text('always_fails'), findsOneWidget);
      expect(find.text('Fail'), findsOneWidget);
    });

    testWidgets('shows last prompt date and prompts count when present',
        (tester) async {
      await HappyReview.instance.configure(
        storageAdapter: storage,
        triggers: [
          const HappyTrigger(eventName: 'purchase', minOccurrences: 1),
        ],
        platformPolicy: relaxedPolicy,
        debugMode: true,
      );

      await storage.setInt('prompts_shown_count', 3);
      await storage.setDateTime('last_prompt_date', DateTime(2026, 1, 15));

      await tester.pumpWidget(
        const MaterialApp(home: Scaffold(body: HappyReviewDebugPanel())),
      );
      await tester.pumpAndSettle();

      expect(find.text('3'), findsOneWidget); // prompts shown
      expect(find.textContaining('2026'), findsWidgets); // last prompt date
    });

    testWidgets('shows debug mode off', (tester) async {
      await HappyReview.instance.configure(
        storageAdapter: storage,
        triggers: [
          const HappyTrigger(eventName: 'purchase', minOccurrences: 1),
        ],
        platformPolicy: relaxedPolicy,
        debugMode: false,
      );

      await tester.pumpWidget(
        const MaterialApp(home: Scaffold(body: HappyReviewDebugPanel())),
      );
      await tester.pumpAndSettle();

      expect(find.text('Off'), findsOneWidget); // debug mode off
    });

    testWidgets('renders without triggers, prerequisites, or conditions',
        (tester) async {
      await HappyReview.instance.configure(
        storageAdapter: storage,
        triggers: [],
        platformPolicy: relaxedPolicy,
      );

      await tester.pumpWidget(
        const MaterialApp(home: Scaffold(body: HappyReviewDebugPanel())),
      );
      await tester.pumpAndSettle();

      expect(find.text('Happy Review Debug'), findsOneWidget);
      // No sections for triggers/prerequisites/conditions.
      expect(find.text('Triggers (OR)'), findsNothing);
      expect(find.text('Prerequisites (AND)'), findsNothing);
      expect(find.text('Conditions'), findsNothing);
    });
  });
}

