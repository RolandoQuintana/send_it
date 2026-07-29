/// Compile-time flags for TestFlight blast diagnostics builds.
///
/// Enable on TestFlight archive only:
/// `fvm flutter build ipa --dart-define=BLAST_DIAGNOSTICS=true`
class DiagnosticConstants {
  DiagnosticConstants._();

  static const bool blastDiagnosticsEnabled = bool.fromEnvironment(
    'BLAST_DIAGNOSTICS',
    defaultValue: false,
  );

  static const String diagnosticShortcutName = 'Sent It Blast (Diagnostic)';

  static const String diagnosticLogFileName = 'Sent_It_Blast.txt';

  static const String diagnosticShortcutAsset =
      'assets/sent_it_blast_diagnostic.shortcut';
}
