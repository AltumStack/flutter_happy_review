/// Possible outcomes of the pre-dialog interaction.
enum PreDialogResult {
  /// The user indicated they are enjoying the app.
  positive,

  /// The user indicated they are not enjoying the app.
  negative,

  /// The user chose to be reminded later.
  remindLater,

  /// The user dismissed the dialog without choosing.
  dismissed,
}
