import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:happy_review/happy_review.dart';
import 'package:in_app_review/in_app_review.dart';
import 'package:mocktail/mocktail.dart';

class _MockDialogAdapter extends Mock implements ReviewDialogAdapter {}

class _MockInAppReview extends Mock implements InAppReview {}

class _FakeBuildContext extends Fake implements BuildContext {}

/// In-memory [ReviewStorageAdapter] for testing.
class _FakeStorageAdapter extends ReviewStorageAdapter {
  final Map<String, dynamic> _store = {};

  @override
  Future<int> getInt(String key, {int defaultValue = 0}) async =>
      (_store[key] as int?) ?? defaultValue;

  @override
  Future<void> setInt(String key, int value) async => _store[key] = value;

  @override
  Future<bool> getBool(String key, {bool defaultValue = false}) async =>
      (_store[key] as bool?) ?? defaultValue;

  @override
  Future<void> setBool(String key, bool value) async => _store[key] = value;

  @override
  Future<DateTime?> getDateTime(String key) async =>
      _store[key] as DateTime?;

  @override
  Future<void> setDateTime(String key, DateTime value) async =>
      _store[key] = value;

  @override
  Future<String?> getString(String key) async => _store[key] as String?;

  @override
  Future<void> setString(String key, String value) async =>
      _store[key] = value;

  @override
  Future<void> clear() async => _store.clear();
}

/// End-to-end tests that replicate the example app's exact configuration
/// to verify the full pipeline behaves as expected.
void main() {
  late _FakeStorageAdapter storage;
  late _MockDialogAdapter dialogAdapter;
  late _MockInAppReview mockInAppReview;

  setUpAll(() {
    registerFallbackValue(_FakeBuildContext());
  });

  setUp(() {
    storage = _FakeStorageAdapter();
    dialogAdapter = _MockDialogAdapter();
    mockInAppReview = _MockInAppReview();

    when(() => mockInAppReview.isAvailable())
        .thenAnswer((_) async => true);
    when(() => mockInAppReview.requestReview()).thenAnswer((_) async {});
  });

  group('Example app scenario', () {
    Future<void> configureWithExampleAppSettings() async {
      await HappyReview.instance.configure(
        storageAdapter: storage,
        triggers: [
          const HappyTrigger(
              eventName: 'purchase_completed', minOccurrences: 3),
        ],
        prerequisites: [
          const HappyTrigger(
              eventName: 'onboarding_finished', minOccurrences: 1),
        ],
        conditions: [
          const MinDaysAfterInstall(days: 0),
        ],
        platformPolicy: const PlatformPolicy(
          android: PlatformRules(
            cooldown: Duration(seconds: 10),
            maxPrompts: 99,
            maxPromptsPeriod: Duration(days: 365),
          ),
          ios: PlatformRules(
            cooldown: Duration(seconds: 10),
            maxPrompts: 99,
            maxPromptsPeriod: Duration(days: 365),
          ),
        ),
        dialogAdapter: dialogAdapter,
        debugMode: true,
      );
      HappyReview.instance.setInAppReviewInstance(mockInAppReview);
    }

    testWidgets(
      'onboarding then 3 purchases shows pre-dialog on the 3rd purchase',
      (tester) async {
        when(() => dialogAdapter.showPreDialog(any()))
            .thenAnswer((_) async => PreDialogResult.positive);

        await configureWithExampleAppSettings();
        await tester.pumpWidget(const MaterialApp(home: Scaffold()));
        final context = tester.element(find.byType(Scaffold));

        // Onboarding — no trigger configured for this event.
        final onboardResult = await HappyReview.instance
            .logEvent(context, 'onboarding_finished');
        expect(onboardResult, equals(ReviewFlowResult.noTrigger));

        // Purchase 1 — trigger not yet met (needs 3).
        final purchase1 = await HappyReview.instance
            .logEvent(context, 'purchase_completed');
        expect(purchase1, equals(ReviewFlowResult.noTrigger));

        // Purchase 2 — still not enough.
        final purchase2 = await HappyReview.instance
            .logEvent(context, 'purchase_completed');
        expect(purchase2, equals(ReviewFlowResult.noTrigger));

        // Purchase 3 — trigger fires, dialog shown, user positive → review.
        final purchase3 = await HappyReview.instance
            .logEvent(context, 'purchase_completed');
        expect(purchase3, equals(ReviewFlowResult.reviewRequested));

        verify(() => dialogAdapter.showPreDialog(any())).called(1);
        verify(() => mockInAppReview.requestReview()).called(1);
      },
    );

    testWidgets(
      'purchases without onboarding returns prerequisitesNotMet',
      (tester) async {
        await configureWithExampleAppSettings();
        await tester.pumpWidget(const MaterialApp(home: Scaffold()));
        final context = tester.element(find.byType(Scaffold));

        // 3 purchases without onboarding.
        await HappyReview.instance.logEvent(context, 'purchase_completed');
        await HappyReview.instance.logEvent(context, 'purchase_completed');
        final result = await HappyReview.instance
            .logEvent(context, 'purchase_completed');

        expect(result, equals(ReviewFlowResult.prerequisitesNotMet));
        verifyNever(() => dialogAdapter.showPreDialog(any()));
      },
    );

    testWidgets(
      'after positive response, subsequent purchases are blocked by '
      'platform policy cooldown',
      (tester) async {
        when(() => dialogAdapter.showPreDialog(any()))
            .thenAnswer((_) async => PreDialogResult.positive);

        await configureWithExampleAppSettings();
        await tester.pumpWidget(const MaterialApp(home: Scaffold()));
        final context = tester.element(find.byType(Scaffold));

        // Complete the full flow: onboarding + 3 purchases.
        await HappyReview.instance
            .logEvent(context, 'onboarding_finished');
        await HappyReview.instance
            .logEvent(context, 'purchase_completed');
        await HappyReview.instance
            .logEvent(context, 'purchase_completed');
        final firstFlow = await HappyReview.instance
            .logEvent(context, 'purchase_completed');
        expect(firstFlow, equals(ReviewFlowResult.reviewRequested));

        // Consume the call from the first flow.
        verify(() => mockInAppReview.requestReview()).called(1);

        // Immediate 4th purchase — blocked by platform policy cooldown.
        final fourthPurchase = await HappyReview.instance
            .logEvent(context, 'purchase_completed');
        expect(
            fourthPurchase, equals(ReviewFlowResult.blockedByPlatformPolicy));

        // No additional review request was made.
        verifyNever(() => mockInAppReview.requestReview());
      },
    );
  });
}
