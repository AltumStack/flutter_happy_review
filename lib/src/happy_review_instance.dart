import 'package:flutter/widgets.dart';
import 'package:in_app_review/in_app_review.dart';

import 'adapters/review_dialog_adapter.dart';
import 'adapters/review_storage_adapter.dart';
import 'adapters/shared_preferences_storage_adapter.dart';
import 'conditions/cooldown_period.dart';
import 'conditions/min_days_after_install.dart';
import 'conditions/max_prompts_shown.dart';
import 'conditions/review_condition.dart';
import 'models/feedback_result.dart';
import 'models/happy_trigger.dart';
import 'models/platform_policy.dart';
import 'models/pre_dialog_result.dart';
import 'models/review_flow_result.dart';
import 'platform_policy_checker.dart';

/// Callback signature for feedback submission.
typedef FeedbackCallback = void Function(FeedbackResult feedback);

/// The main entry point for the happy_review library.
///
/// Configure once at app startup, then call [logEvent] whenever
/// a user completes a happy-path action.
///
/// ```dart
/// HappyReview.instance.configure(
///   triggers: [
///     HappyTrigger(eventName: 'purchase_completed', minOccurrences: 3),
///   ],
///   dialogAdapter: DefaultReviewDialogAdapter(),
/// );
///
/// // Later, after a successful purchase:
/// await HappyReview.instance.logEvent(context, 'purchase_completed');
/// ```
class HappyReview {
  static final HappyReview _instance = HappyReview._internal();

  /// The singleton instance.
  static HappyReview get instance => _instance;

  HappyReview._internal();

  // -- Configuration --

  List<HappyTrigger> _triggers = [];
  List<ReviewCondition> _conditions = [];
  PlatformPolicy _platformPolicy = const PlatformPolicy();
  ReviewDialogAdapter? _dialogAdapter;
  late ReviewStorageAdapter _storageAdapter;
  bool _configured = false;

  // -- Callbacks --

  VoidCallback? _onPreDialogShown;
  VoidCallback? _onPreDialogPositive;
  VoidCallback? _onPreDialogNegative;
  VoidCallback? _onPreDialogDismissed;
  VoidCallback? _onReviewRequested;
  FeedbackCallback? _onFeedbackSubmitted;

  /// Configures the library. Call this once during app initialization.
  ///
  /// - [triggers]: Events that can activate the review flow.
  /// - [conditions]: Additional rules that must pass (optional).
  /// - [platformPolicy]: Per-platform frequency rules (optional, has defaults).
  /// - [dialogAdapter]: Controls the pre-dialog and feedback UI (optional).
  ///   If `null`, the OS review is requested directly when triggers fire.
  /// - [storageAdapter]: Where to persist state (optional, defaults to
  ///   SharedPreferences).
  Future<void> configure({
    required List<HappyTrigger> triggers,
    List<ReviewCondition> conditions = const [],
    PlatformPolicy platformPolicy = const PlatformPolicy(),
    ReviewDialogAdapter? dialogAdapter,
    ReviewStorageAdapter? storageAdapter,
    VoidCallback? onPreDialogShown,
    VoidCallback? onPreDialogPositive,
    VoidCallback? onPreDialogNegative,
    VoidCallback? onPreDialogDismissed,
    VoidCallback? onReviewRequested,
    FeedbackCallback? onFeedbackSubmitted,
  }) async {
    _triggers = triggers;
    _conditions = conditions;
    _platformPolicy = platformPolicy;
    _dialogAdapter = dialogAdapter;
    _storageAdapter = storageAdapter ?? SharedPreferencesStorageAdapter();
    _onPreDialogShown = onPreDialogShown;
    _onPreDialogPositive = onPreDialogPositive;
    _onPreDialogNegative = onPreDialogNegative;
    _onPreDialogDismissed = onPreDialogDismissed;
    _onReviewRequested = onReviewRequested;
    _onFeedbackSubmitted = onFeedbackSubmitted;
    _configured = true;

    // Record install date on first configure.
    await MinDaysAfterInstall.recordInstallIfNeeded(_storageAdapter);
  }

  /// Records an event and evaluates whether to start the review flow.
  ///
  /// Call this after the user completes a happy-path action.
  /// [context] is required to show dialogs if the flow activates.
  ///
  /// Returns a [ReviewFlowResult] indicating what happened.
  Future<ReviewFlowResult> logEvent(
    BuildContext context,
    String eventName,
  ) async {
    assert(_configured, 'Call HappyReview.instance.configure() first.');

    // 1. Increment event count.
    final countKey = 'event_count_$eventName';
    final currentCount = await _storageAdapter.getInt(countKey);
    final newCount = currentCount + 1;
    await _storageAdapter.setInt(countKey, newCount);

    // 2. Check if any trigger for this event is met.
    final matchingTrigger = _triggers
        .where((t) => t.eventName == eventName && newCount >= t.minOccurrences)
        .firstOrNull;

    if (matchingTrigger == null) return ReviewFlowResult.noTrigger;

    // 3. Check platform policy.
    final policyChecker = PlatformPolicyChecker(
      rules: _platformPolicy.current,
      storage: _storageAdapter,
    );
    if (!await policyChecker.canShow()) {
      return ReviewFlowResult.blockedByPlatformPolicy;
    }

    // 4. Check custom conditions.
    for (final condition in _conditions) {
      if (!await condition.evaluate(_storageAdapter)) {
        return ReviewFlowResult.conditionsNotMet;
      }
    }

    // 5. Run the review flow.
    if (!context.mounted) return ReviewFlowResult.dialogDismissed;
    return _executeFlow(context, policyChecker);
  }

  /// Resets all persisted state. Useful for testing or debugging.
  Future<void> reset() async {
    assert(_configured, 'Call HappyReview.instance.configure() first.');
    await _storageAdapter.clear();
  }

  Future<ReviewFlowResult> _executeFlow(
    BuildContext context,
    PlatformPolicyChecker policyChecker,
  ) async {
    // Record that a prompt was shown.
    await policyChecker.recordPrompt();
    await CooldownPeriod.recordPrompt(_storageAdapter);
    await MaxPromptsShown.incrementCount(_storageAdapter);

    // No dialog adapter → request review directly.
    if (_dialogAdapter == null) {
      await _requestReview();
      _onReviewRequested?.call();
      return ReviewFlowResult.reviewRequestedDirect;
    }

    // Show pre-dialog.
    _onPreDialogShown?.call();

    if (!context.mounted) return ReviewFlowResult.dialogDismissed;

    final preResult = await _dialogAdapter!.showPreDialog(context);

    switch (preResult) {
      case PreDialogResult.positive:
        _onPreDialogPositive?.call();
        await _requestReview();
        _onReviewRequested?.call();
        return ReviewFlowResult.reviewRequested;

      case PreDialogResult.negative:
        _onPreDialogNegative?.call();
        if (!context.mounted) return ReviewFlowResult.dialogDismissed;
        final feedback =
            await _dialogAdapter!.showFeedbackDialog(context);
        if (feedback != null) {
          _onFeedbackSubmitted?.call(feedback);
          return ReviewFlowResult.feedbackSubmitted;
        }
        return ReviewFlowResult.dialogDismissed;

      case PreDialogResult.dismissed:
        _onPreDialogDismissed?.call();
        return ReviewFlowResult.dialogDismissed;
    }
  }

  Future<void> _requestReview() async {
    final inAppReview = InAppReview.instance;
    if (await inAppReview.isAvailable()) {
      await inAppReview.requestReview();
    }
  }
}
