import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:happy_review/happy_review.dart';
import 'package:happy_review/testing.dart';
import 'package:in_app_review/in_app_review.dart';
import 'package:mocktail/mocktail.dart';

class _MockInAppReview extends Mock implements InAppReview {}

class _FakeBuildContext extends Fake implements BuildContext {}

void main() {
  late FakeStorageAdapter storage;
  late _MockInAppReview mockInAppReview;

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

  setUpAll(() {
    registerFallbackValue(_FakeBuildContext());
  });

  setUp(() {
    storage = FakeStorageAdapter();
    mockInAppReview = _MockInAppReview();
    when(() => mockInAppReview.isAvailable()).thenAnswer((_) async => true);
    when(() => mockInAppReview.requestReview()).thenAnswer((_) async {});
  });

  group('getDebugSnapshot', () {
    test('returns correct initial state', () async {
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
        enabled: true,
        debugMode: true,
      );

      final snapshot = await HappyReview.instance.getDebugSnapshot();

      expect(snapshot.enabled, isTrue);
      expect(snapshot.debugMode, isTrue);
      expect(snapshot.hasDialogAdapter, isTrue);
      expect(snapshot.promptsShown, equals(0));
      expect(snapshot.lastPromptDate, isNull);
      expect(snapshot.installDate, isNotNull);

      expect(snapshot.triggers, hasLength(1));
      expect(snapshot.triggers.first.eventName, equals('purchase'));
      expect(snapshot.triggers.first.minOccurrences, equals(3));
      expect(snapshot.triggers.first.currentCount, equals(0));
      expect(snapshot.triggers.first.isMet, isFalse);

      expect(snapshot.prerequisites, hasLength(1));
      expect(snapshot.prerequisites.first.eventName, equals('onboarding'));
      expect(snapshot.prerequisites.first.isMet, isFalse);

      expect(snapshot.platformPolicyAllows, isTrue);

      expect(snapshot.conditions, hasLength(1));
      expect(snapshot.conditions.first.name, equals('MinDaysAfterInstall'));
      expect(snapshot.conditions.first.isMet, isTrue);
    });

    testWidgets('reflects state after logEvent calls', (tester) async {
      await HappyReview.instance.configure(
        storageAdapter: storage,
        triggers: [
          const HappyTrigger(eventName: 'purchase', minOccurrences: 3),
        ],
        prerequisites: [
          const HappyTrigger(
              eventName: 'onboarding', minOccurrences: 1),
        ],
        platformPolicy: relaxedPolicy,
        dialogAdapter: FakeDialogAdapter(),
        debugMode: true,
      );
      HappyReview.instance.setInAppReviewInstance(mockInAppReview);

      await tester.pumpWidget(const MaterialApp(home: Scaffold()));
      final context = tester.element(find.byType(Scaffold));

      // Log onboarding + 2 purchases.
      await HappyReview.instance.logEvent(context, 'onboarding');
      await HappyReview.instance.logEvent(context, 'purchase');
      await HappyReview.instance.logEvent(context, 'purchase');

      final snapshot = await HappyReview.instance.getDebugSnapshot();

      expect(snapshot.triggers.first.currentCount, equals(2));
      expect(snapshot.triggers.first.isMet, isFalse);
      expect(snapshot.prerequisites.first.currentCount, equals(1));
      expect(snapshot.prerequisites.first.isMet, isTrue);
    });

    test('shows CustomCondition name', () async {
      await HappyReview.instance.configure(
        storageAdapter: storage,
        triggers: [
          const HappyTrigger(eventName: 'purchase', minOccurrences: 1),
        ],
        conditions: [
          CustomCondition(
            name: 'no_support_ticket',
            evaluate: () async => false,
          ),
        ],
        platformPolicy: relaxedPolicy,
      );

      final snapshot = await HappyReview.instance.getDebugSnapshot();

      expect(snapshot.conditions.first.name, equals('no_support_ticket'));
      expect(snapshot.conditions.first.isMet, isFalse);
    });

    test('returns no dialog adapter when none configured', () async {
      await HappyReview.instance.configure(
        storageAdapter: storage,
        triggers: [
          const HappyTrigger(eventName: 'purchase', minOccurrences: 1),
        ],
        platformPolicy: relaxedPolicy,
      );

      final snapshot = await HappyReview.instance.getDebugSnapshot();

      expect(snapshot.hasDialogAdapter, isFalse);
    });

    test('reflects disabled state', () async {
      await HappyReview.instance.configure(
        storageAdapter: storage,
        triggers: [
          const HappyTrigger(eventName: 'purchase', minOccurrences: 1),
        ],
        platformPolicy: relaxedPolicy,
        enabled: false,
      );

      final snapshot = await HappyReview.instance.getDebugSnapshot();

      expect(snapshot.enabled, isFalse);
    });
  });
}
