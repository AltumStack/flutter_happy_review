/// Data collected from the feedback dialog when a user
/// indicates dissatisfaction.
class FeedbackResult {
  /// Free-form comment from the user.
  final String? comment;

  /// Selected category (e.g., "Performance", "Design").
  final String? category;

  /// Email provided by the user for follow-up.
  final String? contactEmail;

  const FeedbackResult({
    this.comment,
    this.category,
    this.contactEmail,
  });

  @override
  String toString() =>
      'FeedbackResult(comment: $comment, category: $category, contactEmail: $contactEmail)';
}
