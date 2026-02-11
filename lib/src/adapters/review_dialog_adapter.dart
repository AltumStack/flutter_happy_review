import 'package:flutter/widgets.dart';

import '../models/feedback_result.dart';
import '../models/pre_dialog_result.dart';

/// Contract that bridges the library's review flow with the UI layer.
///
/// Implement this to fully customize how the pre-dialog and feedback
/// dialog look and behave. The library calls these methods at the
/// right time — your implementation controls the presentation.
///
/// The library provides [DefaultReviewDialogAdapter] as a ready-to-use
/// implementation.
abstract class ReviewDialogAdapter {
  /// Shows the satisfaction pre-dialog and returns the user's choice.
  ///
  /// Return [PreDialogResult.positive] to proceed to the OS review,
  /// [PreDialogResult.negative] to show the feedback dialog,
  /// [PreDialogResult.remindLater] to skip this time without recording
  /// a prompt, or [PreDialogResult.dismissed] if the user closed
  /// without choosing.
  Future<PreDialogResult> showPreDialog(BuildContext context);

  /// Shows a feedback form after the user indicated dissatisfaction.
  ///
  /// Return a [FeedbackResult] with the collected data, or `null`
  /// if the user dismissed the form.
  Future<FeedbackResult?> showFeedbackDialog(BuildContext context);
}
