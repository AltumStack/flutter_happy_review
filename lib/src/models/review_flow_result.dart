/// Outcome of calling [HappyReview.logEvent].
enum ReviewFlowResult {
  /// The library is disabled via [HappyReview.setEnabled] or the
  /// `enabled` parameter in [HappyReview.configure].
  disabled,

  /// No trigger matched for this event.
  noTrigger,

  /// A trigger matched but one or more prerequisites were not met.
  prerequisitesNotMet,

  /// A trigger matched but platform policy prevented showing.
  blockedByPlatformPolicy,

  /// A trigger matched but one or more conditions were not met.
  conditionsNotMet,

  /// The pre-dialog was shown and the user responded positively.
  /// The OS in-app review was requested.
  reviewRequested,

  /// The pre-dialog was shown and the user responded negatively.
  /// The feedback dialog was displayed.
  feedbackSubmitted,

  /// The pre-dialog was shown and the user chose "remind me later".
  remindLater,

  /// The pre-dialog was shown and the user dismissed it.
  dialogDismissed,

  /// No dialog adapter was configured; the OS review was requested directly.
  reviewRequestedDirect,
}
