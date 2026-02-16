import 'package:flutter/widgets.dart';

import '../adapters/review_dialog_adapter.dart';
import '../models/feedback_result.dart';
import '../models/pre_dialog_result.dart';

/// A configurable [ReviewDialogAdapter] for testing.
///
/// Returns predetermined results without showing any UI.
/// No mocking library required.
///
/// ```dart
/// import 'package:happy_review/testing.dart';
///
/// // User always taps "Love it!":
/// final adapter = FakeDialogAdapter();
///
/// // User always taps "Not really":
/// final adapter = FakeDialogAdapter(
///   preDialogResult: PreDialogResult.negative,
///   feedbackResult: FeedbackResult(comment: 'Too slow'),
/// );
/// ```
class FakeDialogAdapter extends ReviewDialogAdapter {
  /// The result returned by [showPreDialog].
  final PreDialogResult preDialogResult;

  /// The result returned by [showFeedbackDialog].
  /// Only relevant when [preDialogResult] is [PreDialogResult.negative].
  final FeedbackResult? feedbackResult;

  FakeDialogAdapter({
    this.preDialogResult = PreDialogResult.positive,
    this.feedbackResult,
  });

  @override
  Future<PreDialogResult> showPreDialog(BuildContext context) async =>
      preDialogResult;

  @override
  Future<FeedbackResult?> showFeedbackDialog(BuildContext context) async =>
      feedbackResult;
}
