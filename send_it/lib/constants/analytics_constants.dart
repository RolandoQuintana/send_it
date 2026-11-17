/// PostHog project "Scroll Less" (shared; events carry `app: sent_it`).
class AnalyticsConstants {
  AnalyticsConstants._();

  /// Public project token (`phc_...`), safe in client code. Override with
  /// `--dart-define=POSTHOG_API_KEY=...`; an empty value turns analytics off.
  static const postHogApiKey = String.fromEnvironment(
    'POSTHOG_API_KEY',
    defaultValue: 'phc_y7VBbEdEsMoXDMh9tUWLL6Z0at8UoTOAPy4uGYUJrI7',
  );

  static const postHogHost = 'https://us.i.posthog.com';

  /// Debug builds stay out of PostHog. Flip to true (or pass
  /// `--dart-define=POSTHOG_IN_DEBUG=true`) to test events locally.
  static const enablePostHogInDebug =
      bool.fromEnvironment('POSTHOG_IN_DEBUG');

  /// PostHog flag: one free regular Send before the paywall.
  static const freeFirstSendFlagKey = 'free-first-send';

  /// Sent with every flag request as person property `app`, so flags can
  /// target Sent It only (the project is shared with Scroll Less).
  static const flagAppValue = 'sent_it';

  /// Debug-only: force the free first send on without PostHog.
  /// Ignored in release builds. `--dart-define=DEBUG_FREE_FIRST_SEND=true`
  static const debugFreeFirstSend = bool.fromEnvironment(
    'DEBUG_FREE_FIRST_SEND',
  );

  /// Debug-only: send person property `flag_tester: true` with flag
  /// requests, so a flag condition can target only this test install.
  /// Needs `POSTHOG_IN_DEBUG=true`. Ignored in release builds.
  /// `--dart-define=POSTHOG_FLAG_TESTER=true`
  static const debugFlagTester = bool.fromEnvironment('POSTHOG_FLAG_TESTER');
}
