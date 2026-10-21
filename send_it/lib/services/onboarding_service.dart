import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// First-run progress: the welcome screen, the first group, the first
/// prefilled message and the first successful send (after which the launch
/// gate applies whenever the user isn't Pro).
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

  bool get hasSeenWelcome => _hasSeenWelcome;
  bool get hasCreatedFirstGroup => _hasCreatedFirstGroup;
  bool get hasUsedFirstMessagePrefill => _hasUsedFirstMessagePrefill;
  bool get hasCompletedFirstSend => _hasCompletedFirstSend;

  /// Whether the "one message per person" note has been shown before a send.
  bool get hasSeenSendExplainer => _hasSeenSendExplainer;

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

  /// Records a batch with at least one sent message. Once set, the launch
  /// gate locks the app whenever the user isn't Pro (e.g. a lapsed trial).
  Future<void> markFirstSendCompleted() async {
    if (_hasCompletedFirstSend) return;
    _hasCompletedFirstSend = true;
    notifyListeners();
    await _set(hasCompletedFirstSendKey);
  }

  Future<void> _set(String key) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(key, true);
  }
}
