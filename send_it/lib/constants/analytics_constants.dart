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
}
