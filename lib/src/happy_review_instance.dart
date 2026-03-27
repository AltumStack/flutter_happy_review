import 'package:flutter/widgets.dart';
import 'package:in_app_review/in_app_review.dart';

import 'adapters/review_dialog_adapter.dart';
import 'adapters/review_storage_adapter.dart';
import 'conditions/cooldown_period.dart';
import 'conditions/custom_condition.dart';
import 'conditions/min_days_after_install.dart';
import 'conditions/max_prompts_shown.dart';
import 'conditions/review_condition.dart';
import 'models/debug_snapshot.dart';
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
  List<HappyTrigger> _prerequisites = [];
  List<ReviewCondition> _conditions = [];
  PlatformPolicy _platformPolicy = const PlatformPolicy();
  ReviewDialogAdapter? _dialogAdapter;
  late ReviewStorageAdapter _storageAdapter;
  bool _configured = false;
  bool _enabled = true;
  bool _debugMode = false;
  bool _isFlowInProgress = false;
  Duration _remindLaterCooldown = const Duration(days: 1);
  InAppReview _inAppReview = InAppReview.instance;

  /// Overrides the [InAppReview] instance used internally.
  ///
  /// This is exposed only for testing purposes.
  /// Whether a review flow is currently being executed.
  ///
  /// This is exposed only for testing purposes.
  @visibleForTesting
  bool get isFlowInProgress => _isFlowInProgress;

  @visibleForTesting
  // ignore: use_setters_to_change_properties
  void setInAppReviewInstance(InAppReview instance) =>
      _inAppReview = instance;

  // -- Callbacks --

  VoidCallback? _onPreDialogShown;
  VoidCallback? _onPreDialogPositive;
  VoidCallback? _onPreDialogNegative;
  VoidCallback? _onPreDialogRemindLater;
  VoidCallback? _onPreDialogDismissed;
  VoidCallback? _onReviewRequested;
  FeedbackCallback? _onFeedbackSubmitted;

  /// Configures the library. Call this once during app initialization.
  ///
  /// - [triggers]: Events that can activate the review flow (OR logic —
  ///   any single trigger is enough).
  /// - [prerequisites]: Events that must ALL have occurred before any
  ///   trigger can activate (AND logic). Useful for requiring baseline
  ///   engagement (e.g., onboarding completed).
  /// - [conditions]: Additional rules that must pass (optional).
  /// - [platformPolicy]: Per-platform frequency rules (optional, has defaults).
  /// - [dialogAdapter]: Controls the pre-dialog and feedback UI (optional).
  ///   If `null`, the OS review is requested directly when triggers fire.
  /// - [storageAdapter]: Where to persist state. You must provide an
  ///   implementation of [ReviewStorageAdapter].
  /// - [enabled]: Whether the library is active. Set to `false` to disable
  ///   all review flows (e.g., via remote config). Defaults to `true`.
  /// - [debugMode]: When `true`, enables detailed logging via [debugPrint]
  ///   so you can observe the full pipeline during development.
  /// - [remindLaterCooldown]: How long to wait before showing the review
  ///   flow again after the user chose "remind me later" or dismissed the
  ///   dialog. Defaults to one day.
  Future<void> configure({
    required List<HappyTrigger> triggers,
    List<HappyTrigger> prerequisites = const [],
    List<ReviewCondition> conditions = const [],
    PlatformPolicy platformPolicy = const PlatformPolicy(),
    ReviewDialogAdapter? dialogAdapter,
    required ReviewStorageAdapter storageAdapter,
    bool enabled = true,
    bool debugMode = false,
    Duration remindLaterCooldown = const Duration(days: 1),
    VoidCallback? onPreDialogShown,
    VoidCallback? onPreDialogPositive,
    VoidCallback? onPreDialogNegative,
    VoidCallback? onPreDialogRemindLater,
    VoidCallback? onPreDialogDismissed,
    VoidCallback? onReviewRequested,
    FeedbackCallback? onFeedbackSubmitted,
  }) async {
    _triggers = triggers;
    _prerequisites = prerequisites;
    _conditions = conditions;
    _platformPolicy = platformPolicy;
    _dialogAdapter = dialogAdapter;
    _storageAdapter = storageAdapter;
    _enabled = enabled;
    _debugMode = debugMode;
    _remindLaterCooldown = remindLaterCooldown;
    _onPreDialogShown = onPreDialogShown;
    _onPreDialogPositive = onPreDialogPositive;
    _onPreDialogNegative = onPreDialogNegative;
    _onPreDialogRemindLater = onPreDialogRemindLater;
    _onPreDialogDismissed = onPreDialogDismissed;
    _onReviewRequested = onReviewRequested;
    _onFeedbackSubmitted = onFeedbackSubmitted;
    _isFlowInProgress = false;
    _configured = true;

    // Record install date on first configure.
    await MinDaysAfterInstall.recordInstallIfNeeded(_storageAdapter);

    if (_debugMode) {
      debugPrint('[HappyReview] Configured in DEBUG mode.');
    }
  }

  /// Enables or disables the library at runtime.
  ///
  /// When disabled, [logEvent] returns [ReviewFlowResult.disabled]
  /// immediately. Useful as a remote kill switch.
  void setEnabled(bool enabled) {
    assert(_configured, 'Call HappyReview.instance.configure() first.');
    _enabled = enabled;
    if (_debugMode) {
      debugPrint('[HappyReview] Enabled: $_enabled');
    }
  }

  /// Whether the library is currently enabled.
  bool get isEnabled => _enabled;

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

    if (!_enabled) {
      _log('Disabled — ignoring event "$eventName".');
      return ReviewFlowResult.disabled;
    }

    // 1. Increment event count.
    final countKey = 'event_count_$eventName';
    final currentCount = await _storageAdapter.getInt(countKey);
    final newCount = currentCount + 1;
    await _storageAdapter.setInt(countKey, newCount);

    _log('Event "$eventName" logged ($newCount total).');

    if (_isFlowInProgress) {
      _log('Flow already in progress — skipping pipeline for "$eventName".');
      return ReviewFlowResult.flowAlreadyInProgress;
    }

    _isFlowInProgress = true;
    try {
      // 2. Check if any trigger for this event is met.
      final matchingTrigger = _triggers
          .where(
              (t) => t.eventName == eventName && newCount >= t.minOccurrences)
          .firstOrNull;

      if (matchingTrigger == null) {
        _log('No trigger matched for "$eventName".');
        return ReviewFlowResult.noTrigger;
      }

      _log('Trigger matched: ${matchingTrigger.eventName} '
          '(needs ${matchingTrigger.minOccurrences}, has $newCount).');

      // 3. Check snooze cooldown.
      final remindLaterDate =
          await _storageAdapter.getDateTime('remind_later_date');
      if (remindLaterDate != null) {
        final snoozeUntil = remindLaterDate.add(_remindLaterCooldown);
        if (DateTime.now().isBefore(snoozeUntil)) {
          _log('Snoozed until ${snoozeUntil.toIso8601String()} '
              '— skipping flow.');
          return ReviewFlowResult.snoozed;
        }
      }

      // 4. Check prerequisites (AND — all must be met).
      for (final prereq in _prerequisites) {
        final prereqCount =
            await _storageAdapter.getInt('event_count_${prereq.eventName}');
        if (prereqCount < prereq.minOccurrences) {
          _log('Prerequisite not met: "${prereq.eventName}" '
              '(needs ${prereq.minOccurrences}, has $prereqCount).');
          return ReviewFlowResult.prerequisitesNotMet;
        }
      }

      // 5. Check platform policy.
      final policyChecker = PlatformPolicyChecker(
        rules: _platformPolicy.current,
        storage: _storageAdapter,
      );
      if (!await policyChecker.canShow()) {
        _log('Blocked by platform policy.');
        return ReviewFlowResult.blockedByPlatformPolicy;
      }

      // 6. Check custom conditions.
      for (final condition in _conditions) {
        if (!await condition.evaluate(_storageAdapter)) {
          _log('Condition not met: ${condition.runtimeType}.');
          return ReviewFlowResult.conditionsNotMet;
        }
      }

      // 7. Run the review flow.
      if (!context.mounted) return ReviewFlowResult.dialogDismissed;
      // Use `await` so the finally block runs after the flow completes,
      // not immediately after _executeFlow is called.
      return await _executeFlow(context, policyChecker, eventName);
    } finally {
      _isFlowInProgress = false;
    }
  }

  // -- Query methods --

  /// Returns the current count for a given event.
  Future<int> getEventCount(String eventName) async {
    assert(_configured, 'Call HappyReview.instance.configure() first.');
    return _storageAdapter.getInt('event_count_$eventName');
  }

  /// Returns the total number of times the review flow has been shown.
  Future<int> getPromptsShownCount() async {
    assert(_configured, 'Call HappyReview.instance.configure() first.');
    return _storageAdapter.getInt('prompts_shown_count');
  }

  /// Returns the date of the last review prompt, or `null` if never shown.
  Future<DateTime?> getLastPromptDate() async {
    assert(_configured, 'Call HappyReview.instance.configure() first.');
    return _storageAdapter.getDateTime('last_prompt_date');
  }

  /// Resets all persisted state. Useful for testing or debugging.
  ///
  /// Re-records the install date so [MinDaysAfterInstall] continues
  /// to work correctly after a reset.
  Future<void> reset() async {
    assert(_configured, 'Call HappyReview.instance.configure() first.');
    await _storageAdapter.clear();
    _isFlowInProgress = false;
    await MinDaysAfterInstall.recordInstallIfNeeded(_storageAdapter);
    _log('All state reset.');
  }

  /// Returns a snapshot of the library's internal state for debugging.
  ///
  /// Resolves current counts, prerequisite status, platform policy,
  /// and condition evaluations into a single [DebugSnapshot].
  Future<DebugSnapshot> getDebugSnapshot() async {
    assert(_configured, 'Call HappyReview.instance.configure() first.');

    final triggerStatuses = <TriggerStatus>[];
    for (final t in _triggers) {
      final count = await _storageAdapter.getInt('event_count_${t.eventName}');
      triggerStatuses.add(TriggerStatus(
        eventName: t.eventName,
        minOccurrences: t.minOccurrences,
        currentCount: count,
      ));
    }

    final prereqStatuses = <TriggerStatus>[];
    for (final p in _prerequisites) {
      final count = await _storageAdapter.getInt('event_count_${p.eventName}');
      prereqStatuses.add(TriggerStatus(
        eventName: p.eventName,
        minOccurrences: p.minOccurrences,
        currentCount: count,
      ));
    }

    final policyChecker = PlatformPolicyChecker(
      rules: _platformPolicy.current,
      storage: _storageAdapter,
    );
    final policyAllows = await policyChecker.canShow();

    final conditionStatuses = <ConditionStatus>[];
    for (final c in _conditions) {
      final met = await c.evaluate(_storageAdapter);
      final name = c is CustomCondition ? c.name : c.runtimeType.toString();
      conditionStatuses.add(ConditionStatus(name: name, isMet: met));
    }

    final remindLaterDate =
        await _storageAdapter.getDateTime('remind_later_date');
    DateTime? snoozeUntil;
    bool isSnoozed = false;
    if (remindLaterDate != null) {
      snoozeUntil = remindLaterDate.add(_remindLaterCooldown);
      isSnoozed = DateTime.now().isBefore(snoozeUntil);
    }

    return DebugSnapshot(
      enabled: _enabled,
      debugMode: _debugMode,
      hasDialogAdapter: _dialogAdapter != null,
      isFlowInProgress: _isFlowInProgress,
      triggers: triggerStatuses,
      prerequisites: prereqStatuses,
      platformPolicyAllows: policyAllows,
      conditions: conditionStatuses,
      promptsShown: await _storageAdapter.getInt('prompts_shown_count'),
      lastPromptDate: await _storageAdapter.getDateTime('last_prompt_date'),
      installDate: await _storageAdapter.getDateTime('install_date'),
      isSnoozed: isSnoozed,
      snoozeUntil: isSnoozed ? snoozeUntil : null,
    );
  }

  // -- Private --

  Future<ReviewFlowResult> _executeFlow(
    BuildContext context,
    PlatformPolicyChecker policyChecker,
    String eventName,
  ) async {
    // No dialog adapter → request review directly.
    if (_dialogAdapter == null) {
      await _activateSnooze();
      final reviewed = await _requestReview();
      if (reviewed) {
        await _clearSnooze();
        await _recordPromptShown(policyChecker);
        await _resetTriggerCount(eventName);
        _onReviewRequested?.call();
        _log('OS review requested directly (no dialog adapter).');
        return ReviewFlowResult.reviewRequestedDirect;
      } else {
        // Nothing was shown to the user — don't count anything.
        _log('OS review not available (no dialog adapter).');
        return ReviewFlowResult.reviewNotAvailable;
      }
    }

    // Activate snooze before showing the dialog as a safety net.
    // If the app is killed while the dialog is visible, the snooze
    // prevents immediate re-prompting on next launch.
    await _activateSnooze();

    _onPreDialogShown?.call();
    _log('Showing pre-dialog.');

    if (!context.mounted) return ReviewFlowResult.dialogDismissed;

    final preResult = await _dialogAdapter!.showPreDialog(context);

    switch (preResult) {
      case PreDialogResult.positive:
        _onPreDialogPositive?.call();
        final reviewed = await _requestReview();
        if (reviewed) {
          await _clearSnooze();
          await _recordPromptShown(policyChecker);
          await _resetTriggerCount(eventName);
          _onReviewRequested?.call();
          _log('User positive → OS review requested.');
          return ReviewFlowResult.reviewRequested;
        } else {
          await _clearSnooze();
          await _recordPromptShown(policyChecker);
          _log('User positive but OS review not available.');
          return ReviewFlowResult.reviewNotAvailable;
        }

      case PreDialogResult.negative:
        await _clearSnooze();
        await _recordPromptShown(policyChecker);
        await _resetTriggerCount(eventName);
        _onPreDialogNegative?.call();
        _log('User negative → showing feedback dialog.');
        if (!context.mounted) return ReviewFlowResult.dialogDismissed;
        final feedback =
            await _dialogAdapter!.showFeedbackDialog(context);
        if (feedback != null) {
          _onFeedbackSubmitted?.call(feedback);
          _log('Feedback submitted: $feedback');
          return ReviewFlowResult.feedbackSubmitted;
        }
        return ReviewFlowResult.dialogDismissed;

      case PreDialogResult.remindLater:
        // Snooze already active from safety net — just fire callback.
        _onPreDialogRemindLater?.call();
        _log('User chose remind later — snoozed for '
            '${_remindLaterCooldown.inHours}h.');
        return ReviewFlowResult.remindLater;

      case PreDialogResult.dismissed:
        // Snooze already active from safety net — just fire callback.
        _onPreDialogDismissed?.call();
        _log('User dismissed pre-dialog — snoozed for '
            '${_remindLaterCooldown.inHours}h.');
        return ReviewFlowResult.dialogDismissed;
    }
  }

  Future<void> _resetTriggerCount(String eventName) async {
    await _storageAdapter.setInt('event_count_$eventName', 0);
    _log('Trigger counter reset for "$eventName".');
  }

  Future<void> _activateSnooze() async {
    await _storageAdapter.setDateTime('remind_later_date', DateTime.now());
  }

  Future<void> _clearSnooze() async {
    // Set to epoch to effectively clear; the snooze check will see it as
    // expired since epoch + any cooldown < now.
    await _storageAdapter.setDateTime(
      'remind_later_date',
      DateTime.fromMillisecondsSinceEpoch(0),
    );
  }

  Future<void> _recordPromptShown(PlatformPolicyChecker policyChecker) async {
    await policyChecker.recordPrompt();
    await CooldownPeriod.recordPrompt(_storageAdapter);
    await MaxPromptsShown.incrementCount(_storageAdapter);
  }

  /// Returns `true` if the OS review was available and requested.
  Future<bool> _requestReview() async {
    if (await _inAppReview.isAvailable()) {
      _log('Requesting OS review.');
      await _inAppReview.requestReview();
      return true;
    } else {
      _log('OS review not available on this device.');
      return false;
    }
  }

  void _log(String message) {
    if (_debugMode) {
      debugPrint('[HappyReview] $message');
    }
  }
}
