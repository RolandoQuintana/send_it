import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// First-run progress: the welcome screen, the first group, the first
/// prefilled message and the first successful send (which turns on the
/// hard paywall for non-Pro users).
class OnboardingService extends ChangeNotifier {
  OnboardingService._();

  static final OnboardingService instance = OnboardingService._();

  @visibleForTesting
  factory OnboardingService.forTesting() => OnboardingService._();

  static const hasSeenWelcomeKey = 'onboarding_has_seen_welcome';
  static const hasCreatedFirstGroupKey = 'onboarding_has_created_first_group';
  static const hasUsedFirstMessagePrefillKey =
      'onboarding_has_used_first_message_prefill';
  static const hasCompletedFirstSendKey = 'onboarding_has_completed_first_send';
  static const hasSeenSendExplainerKey = 'onboarding_has_seen_send_explainer';

  bool _initialized = false;
  bool _hasSeenWelcome = false;
  bool _hasCreatedFirstGroup = false;
  bool _hasUsedFirstMessagePrefill = false;
  bool _hasCompletedFirstSend = false;
  bool _hasSeenSendExplainer = false;
  int? _firstSendCount;

  bool get hasSeenWelcome => _hasSeenWelcome;
  bool get hasCreatedFirstGroup => _hasCreatedFirstGroup;
  bool get hasUsedFirstMessagePrefill => _hasUsedFirstMessagePrefill;
  bool get hasCompletedFirstSend => _hasCompletedFirstSend;

  /// Whether the "one message per person" note has been shown before a send.
  bool get hasSeenSendExplainer => _hasSeenSendExplainer;

  /// How many people the first batch reached, set only in the session the
  /// first send happened in (so the paywall can point back to it).
  int? get firstSendCount => _firstSendCount;

  /// Call before [AppearanceService.initialize]: an empty store is how a
  /// fresh install is told apart from an existing user. Only an existing
  /// user's store is written to here, so that check still holds after.
  Future<void> initialize() async {
    if (_initialized) return;
    _initialized = true;

    final prefs = await SharedPreferences.getInstance();
    final existingUser =
        prefs.getKeys().isNotEmpty && !prefs.containsKey(hasSeenWelcomeKey);

    if (existingUser) {
      // Returning users skip the first-run UI. Their first send still
      // counts, as for anyone else.
      _hasSeenWelcome = true;
      _hasCreatedFirstGroup = true;
      _hasUsedFirstMessagePrefill = true;
      _hasSeenSendExplainer = true;
      await prefs.setBool(hasSeenWelcomeKey, true);
      await prefs.setBool(hasSeenSendExplainerKey, true);
      await prefs.setBool(hasCreatedFirstGroupKey, true);
      await prefs.setBool(hasUsedFirstMessagePrefillKey, true);
    } else {
      _hasSeenWelcome = prefs.getBool(hasSeenWelcomeKey) ?? false;
      _hasCreatedFirstGroup = prefs.getBool(hasCreatedFirstGroupKey) ?? false;
      _hasUsedFirstMessagePrefill =
          prefs.getBool(hasUsedFirstMessagePrefillKey) ?? false;
      _hasSeenSendExplainer = prefs.getBool(hasSeenSendExplainerKey) ?? false;
    }
    _hasCompletedFirstSend = prefs.getBool(hasCompletedFirstSendKey) ?? false;

    notifyListeners();
  }

  Future<void> markWelcomeSeen() async {
    if (_hasSeenWelcome) return;
    _hasSeenWelcome = true;
    notifyListeners();
    await _set(hasSeenWelcomeKey);
  }

  /// True the first time it's called, false after.
  Future<bool> markFirstGroupCreated() async {
    if (_hasCreatedFirstGroup) return false;
    _hasCreatedFirstGroup = true;
    await _set(hasCreatedFirstGroupKey);
    return true;
  }

  /// True only for the very first compose, then never again.
  Future<bool> consumeFirstMessagePrefill() async {
    if (_hasUsedFirstMessagePrefill) return false;
    _hasUsedFirstMessagePrefill = true;
    await _set(hasUsedFirstMessagePrefillKey);
    return true;
  }

  Future<void> markSendExplainerSeen() async {
    if (_hasSeenSendExplainer) return;
    _hasSeenSendExplainer = true;
    await _set(hasSeenSendExplainerKey);
  }

  /// Records a batch with at least one sent message. Once set, non-Pro
  /// users are gated on every launch. Saved right away (so killing the app
  /// on the success sheet doesn't skip the paywall), but listeners hear
  /// about it from [presentPaywall], after the success sheet.
  Future<void> markFirstSendCompleted({required int sentCount}) async {
    if (_hasCompletedFirstSend) return;
    _hasCompletedFirstSend = true;
    _firstSendCount = sentCount;
    await _set(hasCompletedFirstSendKey);
  }

  /// Lets [SubscriptionGate] swap the app for the paywall.
  void presentPaywall() => notifyListeners();

  Future<void> _set(String key) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(key, true);
  }
}
