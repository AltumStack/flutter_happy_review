/// Possible outcomes of the pre-dialog interaction.
enum PreDialogResult {
  /// The user indicated they are enjoying the app.
  positive,

  /// The user indicated they are not enjoying the app.
  negative,

  /// The user dismissed the dialog without choosing.
  dismissed,
}
