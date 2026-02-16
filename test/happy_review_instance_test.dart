import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:happy_review/happy_review.dart';
import 'package:mocktail/mocktail.dart';

import 'mocks.dart';

void main() {
  late FakeStorageAdapter storage;
  late MockDialogAdapter dialogAdapter;
  late MockInAppReview mockInAppReview;

  // Relaxed platform policy so it never blocks in tests.
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
  );

  setUpAll(() {
    registerFallbackValue(MockBuildContext());
  });

  setUp(() {
    storage = FakeStorageAdapter();
    dialogAdapter = MockDialogAdapter();
    mockInAppReview = MockInAppReview();

    // Default: InAppReview is available and requestReview succeeds.
    when(() => mockInAppReview.isAvailable())
        .thenAnswer((_) async => true);
    when(() => mockInAppReview.requestReview())
        .thenAnswer((_) async {});

    HappyReview.instance.setInAppReviewInstance(mockInAppReview);
  });

  /// Helper to configure HappyReview with common defaults for testing.
  Future<void> configureWith({
    List<HappyTrigger> triggers = const [],
    List<HappyTrigger> prerequisites = const [],
    List<ReviewCondition> conditions = const [],
    ReviewDialogAdapter? dialog,
    bool enabled = true,
    bool debugMode = true,
    PlatformPolicy platformPolicy = relaxedPolicy,
    VoidCallback? onPreDialogShown,
    VoidCallback? onPreDialogPositive,
    VoidCallback? onPreDialogNegative,
    VoidCallback? onPreDialogRemindLater,
    VoidCallback? onPreDialogDismissed,
    VoidCallback? onReviewRequested,
    FeedbackCallback? onFeedbackSubmitted,
  }) async {
    await HappyReview.instance.configure(
      storageAdapter: storage,
      triggers: triggers,
      prerequisites: prerequisites,
      conditions: conditions,
      dialogAdapter: dialog,
      enabled: enabled,
      debugMode: debugMode,
      platformPolicy: platformPolicy,
      onPreDialogShown: onPreDialogShown,
      onPreDialogPositive: onPreDialogPositive,
      onPreDialogNegative: onPreDialogNegative,
      onPreDialogRemindLater: onPreDialogRemindLater,
      onPreDialogDismissed: onPreDialogDismissed,
      onReviewRequested: onReviewRequested,
      onFeedbackSubmitted: onFeedbackSubmitted,
    );
  }

  group('Kill switch', () {
    testWidgets(
      'Given the library is disabled, '
      'When logEvent is called, '
      'Then returns disabled',
      (tester) async {
        // Given
        await configureWith(
          enabled: false,
          triggers: [
            const HappyTrigger(eventName: 'test', minOccurrences: 1),
          ],
        );

        await tester.pumpWidget(const MaterialApp(home: Scaffold()));
        final context = tester.element(find.byType(Scaffold));

        // When
        final result =
            await HappyReview.instance.logEvent(context, 'test');

        // Then
        expect(result, equals(ReviewFlowResult.disabled));
      },
    );

    testWidgets(
      'Given the library is enabled then disabled at runtime, '
      'When logEvent is called, '
      'Then returns disabled',
      (tester) async {
        // Given
        await configureWith(
          enabled: true,
          triggers: [
            const HappyTrigger(eventName: 'test', minOccurrences: 1),
          ],
        );
        HappyReview.instance.setEnabled(false);

        await tester.pumpWidget(const MaterialApp(home: Scaffold()));
        final context = tester.element(find.byType(Scaffold));

        // When
        final result =
            await HappyReview.instance.logEvent(context, 'test');

        // Then
        expect(result, equals(ReviewFlowResult.disabled));
        expect(HappyReview.instance.isEnabled, isFalse);
      },
    );
  });

  group('Trigger matching', () {
    testWidgets(
      'Given no trigger matches the event, '
      'When logEvent is called, '
      'Then returns noTrigger',
      (tester) async {
        // Given
        await configureWith(
          triggers: [
            const HappyTrigger(
                eventName: 'purchase', minOccurrences: 3),
          ],
        );

        await tester.pumpWidget(const MaterialApp(home: Scaffold()));
        final context = tester.element(find.byType(Scaffold));

        // When
        final result = await HappyReview.instance
            .logEvent(context, 'unknown_event');

        // Then
        expect(result, equals(ReviewFlowResult.noTrigger));
      },
    );

    testWidgets(
      'Given trigger requires 3 occurrences and only 1 has happened, '
      'When logEvent is called, '
      'Then returns noTrigger',
      (tester) async {
        // Given
        await configureWith(
          triggers: [
            const HappyTrigger(
                eventName: 'purchase', minOccurrences: 3),
          ],
        );

        await tester.pumpWidget(const MaterialApp(home: Scaffold()));
        final context = tester.element(find.byType(Scaffold));

        // When
        final result = await HappyReview.instance
            .logEvent(context, 'purchase');

        // Then
        expect(result, equals(ReviewFlowResult.noTrigger));
      },
    );

    testWidgets(
      'Given trigger requires 2 occurrences and event count reaches 2, '
      'When logEvent is called, '
      'Then trigger activates',
      (tester) async {
        // Given
        await configureWith(
          triggers: [
            const HappyTrigger(
                eventName: 'purchase', minOccurrences: 2),
          ],
        );
        // Pre-seed 1 occurrence.
        await storage.setInt('event_count_purchase', 1);

        await tester.pumpWidget(const MaterialApp(home: Scaffold()));
        final context = tester.element(find.byType(Scaffold));

        // When (this is the 2nd occurrence)
        final result = await HappyReview.instance
            .logEvent(context, 'purchase');

        // Then — in debug mode with no dialog adapter → direct review
        expect(result, equals(ReviewFlowResult.reviewRequestedDirect));
      },
    );
  });

  group('Prerequisites', () {
    testWidgets(
      'Given prerequisite is not met, '
      'When logEvent triggers, '
      'Then returns prerequisitesNotMet',
      (tester) async {
        // Given
        await configureWith(
          debugMode: false,
          triggers: [
            const HappyTrigger(
                eventName: 'purchase', minOccurrences: 1),
          ],
          prerequisites: [
            const HappyTrigger(
                eventName: 'onboarding', minOccurrences: 1),
          ],
        );

        await tester.pumpWidget(const MaterialApp(home: Scaffold()));
        final context = tester.element(find.byType(Scaffold));

        // When
        final result = await HappyReview.instance
            .logEvent(context, 'purchase');

        // Then
        expect(result, equals(ReviewFlowResult.prerequisitesNotMet));
      },
    );

    testWidgets(
      'Given prerequisite is met, '
      'When logEvent triggers, '
      'Then flow continues past prerequisites and shows dialog',
      (tester) async {
        // Given
        when(() => dialogAdapter.showPreDialog(any()))
            .thenAnswer((_) async => PreDialogResult.dismissed);

        await configureWith(
          debugMode: false,
          triggers: [
            const HappyTrigger(
                eventName: 'purchase', minOccurrences: 1),
          ],
          prerequisites: [
            const HappyTrigger(
                eventName: 'onboarding', minOccurrences: 1),
          ],
          dialog: dialogAdapter,
        );
        await storage.setInt('event_count_onboarding', 1);

        await tester.pumpWidget(const MaterialApp(home: Scaffold()));
        final context = tester.element(find.byType(Scaffold));

        // When
        final result = await HappyReview.instance
            .logEvent(context, 'purchase');

        // Then — passes prerequisites and reaches dialog
        expect(result, equals(ReviewFlowResult.dialogDismissed));
        verify(() => dialogAdapter.showPreDialog(any())).called(1);
      },
    );

    testWidgets(
      'Given debug mode is on and prerequisite is not met, '
      'When logEvent triggers, '
      'Then prerequisites are skipped',
      (tester) async {
        // Given
        await configureWith(
          debugMode: true,
          triggers: [
            const HappyTrigger(
                eventName: 'purchase', minOccurrences: 1),
          ],
          prerequisites: [
            const HappyTrigger(
                eventName: 'onboarding', minOccurrences: 1),
          ],
        );

        await tester.pumpWidget(const MaterialApp(home: Scaffold()));
        final context = tester.element(find.byType(Scaffold));

        // When
        final result = await HappyReview.instance
            .logEvent(context, 'purchase');

        // Then — debug mode bypasses prerequisites
        expect(result, equals(ReviewFlowResult.reviewRequestedDirect));
      },
    );
  });

  group('Platform policy', () {
    testWidgets(
      'Given platform policy cooldown has not elapsed, '
      'When logEvent triggers, '
      'Then returns blockedByPlatformPolicy',
      (tester) async {
        // Given
        await configureWith(
          debugMode: false,
          triggers: [
            const HappyTrigger(
                eventName: 'purchase', minOccurrences: 1),
          ],
          platformPolicy: const PlatformPolicy(
            android: PlatformRules(
              cooldown: Duration(days: 60),
              maxPrompts: 999,
              maxPromptsPeriod: Duration(days: 365),
            ),
            ios: PlatformRules(
              cooldown: Duration(days: 60),
              maxPrompts: 999,
              maxPromptsPeriod: Duration(days: 365),
            ),
          ),
        );
        // Simulate a recent prompt.
        await storage.setDateTime(
          'platform_last_prompt',
          DateTime.now().subtract(const Duration(days: 5)),
        );

        await tester.pumpWidget(const MaterialApp(home: Scaffold()));
        final context = tester.element(find.byType(Scaffold));

        // When
        final result = await HappyReview.instance
            .logEvent(context, 'purchase');

        // Then
        expect(
            result, equals(ReviewFlowResult.blockedByPlatformPolicy));
      },
    );

    testWidgets(
      'Given debug mode is on and platform policy would block, '
      'When logEvent triggers, '
      'Then platform policy is bypassed',
      (tester) async {
        // Given
        await configureWith(
          debugMode: true,
          triggers: [
            const HappyTrigger(
                eventName: 'purchase', minOccurrences: 1),
          ],
          platformPolicy: const PlatformPolicy(
            android: PlatformRules(
              cooldown: Duration(days: 60),
              maxPrompts: 999,
              maxPromptsPeriod: Duration(days: 365),
            ),
            ios: PlatformRules(
              cooldown: Duration(days: 60),
              maxPrompts: 999,
              maxPromptsPeriod: Duration(days: 365),
            ),
          ),
        );
        await storage.setDateTime(
          'platform_last_prompt',
          DateTime.now(),
        );

        await tester.pumpWidget(const MaterialApp(home: Scaffold()));
        final context = tester.element(find.byType(Scaffold));

        // When
        final result = await HappyReview.instance
            .logEvent(context, 'purchase');

        // Then
        expect(result, equals(ReviewFlowResult.reviewRequestedDirect));
      },
    );
  });

  group('Conditions', () {
    testWidgets(
      'Given a condition returns false, '
      'When logEvent triggers, '
      'Then returns conditionsNotMet',
      (tester) async {
        // Given
        await configureWith(
          debugMode: false,
          triggers: [
            const HappyTrigger(
                eventName: 'purchase', minOccurrences: 1),
          ],
          conditions: [
            CustomCondition(
              name: 'failing_condition',
              evaluate: () async => false,
            ),
          ],
        );

        await tester.pumpWidget(const MaterialApp(home: Scaffold()));
        final context = tester.element(find.byType(Scaffold));

        // When
        final result = await HappyReview.instance
            .logEvent(context, 'purchase');

        // Then
        expect(result, equals(ReviewFlowResult.conditionsNotMet));
      },
    );

    testWidgets(
      'Given debug mode is on and a condition would fail, '
      'When logEvent triggers, '
      'Then conditions are bypassed',
      (tester) async {
        // Given
        await configureWith(
          debugMode: true,
          triggers: [
            const HappyTrigger(
                eventName: 'purchase', minOccurrences: 1),
          ],
          conditions: [
            CustomCondition(
              name: 'failing_condition',
              evaluate: () async => false,
            ),
          ],
        );

        await tester.pumpWidget(const MaterialApp(home: Scaffold()));
        final context = tester.element(find.byType(Scaffold));

        // When
        final result = await HappyReview.instance
            .logEvent(context, 'purchase');

        // Then
        expect(result, equals(ReviewFlowResult.reviewRequestedDirect));
      },
    );
  });

  group('Review flow - no dialog adapter', () {
    testWidgets(
      'Given no dialog adapter is configured, '
      'When trigger activates, '
      'Then returns reviewRequestedDirect',
      (tester) async {
        // Given
        await configureWith(
          triggers: [
            const HappyTrigger(
                eventName: 'purchase', minOccurrences: 1),
          ],
          dialog: null,
        );

        await tester.pumpWidget(const MaterialApp(home: Scaffold()));
        final context = tester.element(find.byType(Scaffold));

        // When
        final result = await HappyReview.instance
            .logEvent(context, 'purchase');

        // Then
        expect(result, equals(ReviewFlowResult.reviewRequestedDirect));
      },
    );

    testWidgets(
      'Given no dialog adapter, '
      'When trigger activates, '
      'Then onReviewRequested callback is called',
      (tester) async {
        // Given
        var callbackCalled = false;
        await configureWith(
          triggers: [
            const HappyTrigger(
                eventName: 'purchase', minOccurrences: 1),
          ],
          dialog: null,
          onReviewRequested: () => callbackCalled = true,
        );

        await tester.pumpWidget(const MaterialApp(home: Scaffold()));
        final context = tester.element(find.byType(Scaffold));

        // When
        await HappyReview.instance.logEvent(context, 'purchase');

        // Then
        expect(callbackCalled, isTrue);
      },
    );
  });

  group('Review flow - pre-dialog positive', () {
    testWidgets(
      'Given user responds positively to pre-dialog, '
      'When the flow completes, '
      'Then returns reviewRequested',
      (tester) async {
        // Given
        when(() => dialogAdapter.showPreDialog(any()))
            .thenAnswer((_) async => PreDialogResult.positive);

        await configureWith(
          triggers: [
            const HappyTrigger(
                eventName: 'purchase', minOccurrences: 1),
          ],
          dialog: dialogAdapter,
        );

        await tester.pumpWidget(const MaterialApp(home: Scaffold()));
        final context = tester.element(find.byType(Scaffold));

        // When
        final result = await HappyReview.instance
            .logEvent(context, 'purchase');

        // Then
        expect(result, equals(ReviewFlowResult.reviewRequested));
        verify(() => dialogAdapter.showPreDialog(any())).called(1);
      },
    );

    testWidgets(
      'Given user responds positively, '
      'When the flow completes, '
      'Then onPreDialogPositive and onReviewRequested callbacks are called',
      (tester) async {
        // Given
        var positiveCalled = false;
        var reviewCalled = false;

        when(() => dialogAdapter.showPreDialog(any()))
            .thenAnswer((_) async => PreDialogResult.positive);

        await configureWith(
          triggers: [
            const HappyTrigger(
                eventName: 'purchase', minOccurrences: 1),
          ],
          dialog: dialogAdapter,
          onPreDialogPositive: () => positiveCalled = true,
          onReviewRequested: () => reviewCalled = true,
        );

        await tester.pumpWidget(const MaterialApp(home: Scaffold()));
        final context = tester.element(find.byType(Scaffold));

        // When
        await HappyReview.instance.logEvent(context, 'purchase');

        // Then
        expect(positiveCalled, isTrue);
        expect(reviewCalled, isTrue);
      },
    );
  });

  group('Review flow - pre-dialog negative', () {
    testWidgets(
      'Given user responds negatively and submits feedback, '
      'When the flow completes, '
      'Then returns feedbackSubmitted',
      (tester) async {
        // Given
        const feedback = FeedbackResult(
          comment: 'Slow loading',
          category: 'Performance',
        );

        when(() => dialogAdapter.showPreDialog(any()))
            .thenAnswer((_) async => PreDialogResult.negative);
        when(() => dialogAdapter.showFeedbackDialog(any()))
            .thenAnswer((_) async => feedback);

        await configureWith(
          triggers: [
            const HappyTrigger(
                eventName: 'purchase', minOccurrences: 1),
          ],
          dialog: dialogAdapter,
        );

        await tester.pumpWidget(const MaterialApp(home: Scaffold()));
        final context = tester.element(find.byType(Scaffold));

        // When
        final result = await HappyReview.instance
            .logEvent(context, 'purchase');

        // Then
        expect(result, equals(ReviewFlowResult.feedbackSubmitted));
        verify(() => dialogAdapter.showFeedbackDialog(any())).called(1);
      },
    );

    testWidgets(
      'Given user responds negatively and submits feedback, '
      'When the flow completes, '
      'Then onFeedbackSubmitted callback is called with feedback data',
      (tester) async {
        // Given
        FeedbackResult? receivedFeedback;
        const feedback = FeedbackResult(
          comment: 'Bug on checkout',
          category: 'Features',
          contactEmail: 'user@example.com',
        );

        when(() => dialogAdapter.showPreDialog(any()))
            .thenAnswer((_) async => PreDialogResult.negative);
        when(() => dialogAdapter.showFeedbackDialog(any()))
            .thenAnswer((_) async => feedback);

        await configureWith(
          triggers: [
            const HappyTrigger(
                eventName: 'purchase', minOccurrences: 1),
          ],
          dialog: dialogAdapter,
          onFeedbackSubmitted: (f) => receivedFeedback = f,
        );

        await tester.pumpWidget(const MaterialApp(home: Scaffold()));
        final context = tester.element(find.byType(Scaffold));

        // When
        await HappyReview.instance.logEvent(context, 'purchase');

        // Then
        expect(receivedFeedback, isNotNull);
        expect(receivedFeedback!.comment, equals('Bug on checkout'));
        expect(receivedFeedback!.category, equals('Features'));
        expect(
            receivedFeedback!.contactEmail, equals('user@example.com'));
      },
    );

    testWidgets(
      'Given user responds negatively but dismisses feedback dialog, '
      'When the flow completes, '
      'Then returns dialogDismissed',
      (tester) async {
        // Given
        when(() => dialogAdapter.showPreDialog(any()))
            .thenAnswer((_) async => PreDialogResult.negative);
        when(() => dialogAdapter.showFeedbackDialog(any()))
            .thenAnswer((_) async => null);

        await configureWith(
          triggers: [
            const HappyTrigger(
                eventName: 'purchase', minOccurrences: 1),
          ],
          dialog: dialogAdapter,
        );

        await tester.pumpWidget(const MaterialApp(home: Scaffold()));
        final context = tester.element(find.byType(Scaffold));

        // When
        final result = await HappyReview.instance
            .logEvent(context, 'purchase');

        // Then
        expect(result, equals(ReviewFlowResult.dialogDismissed));
      },
    );
  });

  group('Review flow - pre-dialog remind later', () {
    testWidgets(
      'Given user chooses remind later, '
      'When the flow completes, '
      'Then returns remindLater',
      (tester) async {
        // Given
        when(() => dialogAdapter.showPreDialog(any()))
            .thenAnswer((_) async => PreDialogResult.remindLater);

        await configureWith(
          triggers: [
            const HappyTrigger(
                eventName: 'purchase', minOccurrences: 1),
          ],
          dialog: dialogAdapter,
        );

        await tester.pumpWidget(const MaterialApp(home: Scaffold()));
        final context = tester.element(find.byType(Scaffold));

        // When
        final result = await HappyReview.instance
            .logEvent(context, 'purchase');

        // Then
        expect(result, equals(ReviewFlowResult.remindLater));
      },
    );

    testWidgets(
      'Given user chooses remind later, '
      'When the flow completes, '
      'Then onPreDialogRemindLater callback is called',
      (tester) async {
        // Given
        var callbackCalled = false;

        when(() => dialogAdapter.showPreDialog(any()))
            .thenAnswer((_) async => PreDialogResult.remindLater);

        await configureWith(
          triggers: [
            const HappyTrigger(
                eventName: 'purchase', minOccurrences: 1),
          ],
          dialog: dialogAdapter,
          onPreDialogRemindLater: () => callbackCalled = true,
        );

        await tester.pumpWidget(const MaterialApp(home: Scaffold()));
        final context = tester.element(find.byType(Scaffold));

        // When
        await HappyReview.instance.logEvent(context, 'purchase');

        // Then
        expect(callbackCalled, isTrue);
      },
    );

    testWidgets(
      'Given user chooses remind later, '
      'When the flow completes, '
      'Then neither review nor feedback dialog is shown',
      (tester) async {
        // Given
        when(() => dialogAdapter.showPreDialog(any()))
            .thenAnswer((_) async => PreDialogResult.remindLater);

        await configureWith(
          triggers: [
            const HappyTrigger(
                eventName: 'purchase', minOccurrences: 1),
          ],
          dialog: dialogAdapter,
        );

        await tester.pumpWidget(const MaterialApp(home: Scaffold()));
        final context = tester.element(find.byType(Scaffold));

        // When
        await HappyReview.instance.logEvent(context, 'purchase');

        // Then
        verifyNever(() => dialogAdapter.showFeedbackDialog(any()));
      },
    );
  });

  group('Review flow - pre-dialog dismissed', () {
    testWidgets(
      'Given user dismisses the pre-dialog, '
      'When the flow completes, '
      'Then returns dialogDismissed',
      (tester) async {
        // Given
        when(() => dialogAdapter.showPreDialog(any()))
            .thenAnswer((_) async => PreDialogResult.dismissed);

        await configureWith(
          triggers: [
            const HappyTrigger(
                eventName: 'purchase', minOccurrences: 1),
          ],
          dialog: dialogAdapter,
        );

        await tester.pumpWidget(const MaterialApp(home: Scaffold()));
        final context = tester.element(find.byType(Scaffold));

        // When
        final result = await HappyReview.instance
            .logEvent(context, 'purchase');

        // Then
        expect(result, equals(ReviewFlowResult.dialogDismissed));
      },
    );

    testWidgets(
      'Given user dismisses the pre-dialog, '
      'When the flow completes, '
      'Then onPreDialogDismissed callback is called',
      (tester) async {
        // Given
        var callbackCalled = false;

        when(() => dialogAdapter.showPreDialog(any()))
            .thenAnswer((_) async => PreDialogResult.dismissed);

        await configureWith(
          triggers: [
            const HappyTrigger(
                eventName: 'purchase', minOccurrences: 1),
          ],
          dialog: dialogAdapter,
          onPreDialogDismissed: () => callbackCalled = true,
        );

        await tester.pumpWidget(const MaterialApp(home: Scaffold()));
        final context = tester.element(find.byType(Scaffold));

        // When
        await HappyReview.instance.logEvent(context, 'purchase');

        // Then
        expect(callbackCalled, isTrue);
      },
    );
  });

  group('Event counting', () {
    testWidgets(
      'Given logEvent is called multiple times, '
      'When getEventCount is called, '
      'Then returns the correct accumulated count',
      (tester) async {
        // Given
        await configureWith(
          triggers: [
            const HappyTrigger(
                eventName: 'purchase', minOccurrences: 99),
          ],
        );

        await tester.pumpWidget(const MaterialApp(home: Scaffold()));
        final context = tester.element(find.byType(Scaffold));

        // When
        await HappyReview.instance.logEvent(context, 'purchase');
        await HappyReview.instance.logEvent(context, 'purchase');
        await HappyReview.instance.logEvent(context, 'purchase');

        // Then
        final count =
            await HappyReview.instance.getEventCount('purchase');
        expect(count, equals(3));
      },
    );

    testWidgets(
      'Given events have been logged, '
      'When reset is called, '
      'Then all counts are cleared',
      (tester) async {
        // Given
        await configureWith(
          triggers: [
            const HappyTrigger(
                eventName: 'purchase', minOccurrences: 99),
          ],
        );

        await tester.pumpWidget(const MaterialApp(home: Scaffold()));
        final context = tester.element(find.byType(Scaffold));

        await HappyReview.instance.logEvent(context, 'purchase');
        await HappyReview.instance.logEvent(context, 'purchase');

        // When
        await HappyReview.instance.reset();

        // Then
        final count =
            await HappyReview.instance.getEventCount('purchase');
        expect(count, equals(0));
      },
    );
  });

  group('Query methods', () {
    test(
      'Given prompts have been recorded in storage, '
      'When getPromptsShownCount is called, '
      'Then returns the stored count',
      () async {
        // Given
        await configureWith();
        await storage.setInt('prompts_shown_count', 5);

        // When
        final count =
            await HappyReview.instance.getPromptsShownCount();

        // Then
        expect(count, equals(5));
      },
    );

    test(
      'Given a prompt date has been recorded in storage, '
      'When getLastPromptDate is called, '
      'Then returns the stored date',
      () async {
        // Given
        await configureWith();
        final date = DateTime(2025, 6, 15);
        await storage.setDateTime('last_prompt_date', date);

        // When
        final result =
            await HappyReview.instance.getLastPromptDate();

        // Then
        expect(result, equals(date));
      },
    );

    test(
      'Given no prompt date has been recorded, '
      'When getLastPromptDate is called, '
      'Then returns null',
      () async {
        // Given
        await configureWith();

        // When
        final result =
            await HappyReview.instance.getLastPromptDate();

        // Then
        expect(result, isNull);
      },
    );
  });

  group('onPreDialogShown callback', () {
    testWidgets(
      'Given a dialog adapter is configured, '
      'When the pre-dialog is about to be shown, '
      'Then onPreDialogShown callback is called',
      (tester) async {
        // Given
        var callbackCalled = false;

        when(() => dialogAdapter.showPreDialog(any()))
            .thenAnswer((_) async => PreDialogResult.dismissed);

        await configureWith(
          triggers: [
            const HappyTrigger(
                eventName: 'purchase', minOccurrences: 1),
          ],
          dialog: dialogAdapter,
          onPreDialogShown: () => callbackCalled = true,
        );

        await tester.pumpWidget(const MaterialApp(home: Scaffold()));
        final context = tester.element(find.byType(Scaffold));

        // When
        await HappyReview.instance.logEvent(context, 'purchase');

        // Then
        expect(callbackCalled, isTrue);
      },
    );
  });

  group('Prompt recording', () {
    testWidgets(
      'Given user responds positively, '
      'When the flow completes, '
      'Then prompt counters are incremented',
      (tester) async {
        // Given
        when(() => dialogAdapter.showPreDialog(any()))
            .thenAnswer((_) async => PreDialogResult.positive);

        await configureWith(
          triggers: [
            const HappyTrigger(
                eventName: 'purchase', minOccurrences: 1),
          ],
          dialog: dialogAdapter,
        );

        await tester.pumpWidget(const MaterialApp(home: Scaffold()));
        final context = tester.element(find.byType(Scaffold));

        // When
        await HappyReview.instance.logEvent(context, 'purchase');

        // Then
        final promptsShown =
            await HappyReview.instance.getPromptsShownCount();
        final lastDate =
            await HappyReview.instance.getLastPromptDate();
        expect(promptsShown, equals(1));
        expect(lastDate, isNotNull);
      },
    );

    testWidgets(
      'Given user responds negatively, '
      'When the flow completes, '
      'Then prompt counters are incremented',
      (tester) async {
        // Given
        when(() => dialogAdapter.showPreDialog(any()))
            .thenAnswer((_) async => PreDialogResult.negative);
        when(() => dialogAdapter.showFeedbackDialog(any()))
            .thenAnswer((_) async =>
                const FeedbackResult(comment: 'Bad'));

        await configureWith(
          triggers: [
            const HappyTrigger(
                eventName: 'purchase', minOccurrences: 1),
          ],
          dialog: dialogAdapter,
        );

        await tester.pumpWidget(const MaterialApp(home: Scaffold()));
        final context = tester.element(find.byType(Scaffold));

        // When
        await HappyReview.instance.logEvent(context, 'purchase');

        // Then
        final promptsShown =
            await HappyReview.instance.getPromptsShownCount();
        final lastDate =
            await HappyReview.instance.getLastPromptDate();
        expect(promptsShown, equals(1));
        expect(lastDate, isNotNull);
      },
    );

    testWidgets(
      'Given user chooses remind later, '
      'When the flow completes, '
      'Then prompt counters are NOT incremented',
      (tester) async {
        // Given
        when(() => dialogAdapter.showPreDialog(any()))
            .thenAnswer((_) async => PreDialogResult.remindLater);

        await configureWith(
          triggers: [
            const HappyTrigger(
                eventName: 'purchase', minOccurrences: 1),
          ],
          dialog: dialogAdapter,
        );

        await tester.pumpWidget(const MaterialApp(home: Scaffold()));
        final context = tester.element(find.byType(Scaffold));

        // When
        await HappyReview.instance.logEvent(context, 'purchase');

        // Then
        final promptsShown =
            await HappyReview.instance.getPromptsShownCount();
        final lastDate =
            await HappyReview.instance.getLastPromptDate();
        expect(promptsShown, equals(0));
        expect(lastDate, isNull);
      },
    );

    testWidgets(
      'Given user dismisses the pre-dialog, '
      'When the flow completes, '
      'Then prompt counters are NOT incremented',
      (tester) async {
        // Given
        when(() => dialogAdapter.showPreDialog(any()))
            .thenAnswer((_) async => PreDialogResult.dismissed);

        await configureWith(
          triggers: [
            const HappyTrigger(
                eventName: 'purchase', minOccurrences: 1),
          ],
          dialog: dialogAdapter,
        );

        await tester.pumpWidget(const MaterialApp(home: Scaffold()));
        final context = tester.element(find.byType(Scaffold));

        // When
        await HappyReview.instance.logEvent(context, 'purchase');

        // Then
        final promptsShown =
            await HappyReview.instance.getPromptsShownCount();
        final lastDate =
            await HappyReview.instance.getLastPromptDate();
        expect(promptsShown, equals(0));
        expect(lastDate, isNull);
      },
    );

    testWidgets(
      'Given no dialog adapter is configured, '
      'When trigger activates, '
      'Then prompt counters are incremented',
      (tester) async {
        // Given
        await configureWith(
          triggers: [
            const HappyTrigger(
                eventName: 'purchase', minOccurrences: 1),
          ],
          dialog: null,
        );

        await tester.pumpWidget(const MaterialApp(home: Scaffold()));
        final context = tester.element(find.byType(Scaffold));

        // When
        await HappyReview.instance.logEvent(context, 'purchase');

        // Then
        final promptsShown =
            await HappyReview.instance.getPromptsShownCount();
        final lastDate =
            await HappyReview.instance.getLastPromptDate();
        expect(promptsShown, equals(1));
        expect(lastDate, isNotNull);
      },
    );
  });
}
