import 'dart:io';

import 'package:flutter/foundation.dart';
import 'package:posthog_flutter/posthog_flutter.dart';

import '../constants/analytics_constants.dart';

/// Where a paywall was shown from, for `paywall_viewed`.
enum PaywallTrigger { send, launch, blast, settings, firstSend }

/// Which arm of the `free-first-send` flag a user is in.
/// [unloaded] (flag not fetched, PostHog off) behaves like [off].
enum FreeFirstSendArm { on, off, unloaded }

/// Onboarding + paywall funnel events (PostHog), and the feature flags that
/// shape that funnel.
///
/// No PII: never pass names, phone numbers or message text as properties.
/// iOS-only like the paywall; a no-op elsewhere (and in tests).
class AnalyticsService {
  AnalyticsService._();

  static final AnalyticsService instance = AnalyticsService._();

  static const _freeFirstSendProperty = 'free_first_send';

  bool _enabled = false;

  /// Skipped in debug builds unless [AnalyticsConstants.enablePostHogInDebug]
  /// is on, so development never lands in the shared project.
  Future<void> initialize() async {
    if (_enabled || !Platform.isIOS) return;
    if (kDebugMode && !AnalyticsConstants.enablePostHogInDebug) {
      debugPrint('[AnalyticsService] PostHog skipped (debug build). '
          'Run with --dart-define=POSTHOG_IN_DEBUG=true to enable.');
      return;
    }
    const apiKey = AnalyticsConstants.postHogApiKey;
    if (apiKey.isEmpty) return;

    final config = PostHogConfig(apiKey)
      ..host = AnalyticsConstants.postHogHost
      ..captureApplicationLifecycleEvents = true
      ..personProfiles = PostHogPersonProfiles.identifiedOnly
      // Messages and contact names are on screen: never record them.
      ..sessionReplay = false
      ..debug = !kReleaseMode
      ..onFeatureFlags = _onFeatureFlagsLoaded;

    try {
      await Posthog().setup(config);
      // The PostHog project is shared with other apps.
      await Posthog().register('app', 'sent_it');
      _enabled = true;
      // Lets flags target Sent It only. Sent inline with flag requests; no
      // person profile is created. Not awaited: it reloads flags.
      Posthog()
          .setPersonPropertiesForFlags({
            'app': AnalyticsConstants.flagAppValue,
            if (kDebugMode && AnalyticsConstants.debugFlagTester)
              'flag_tester': 'true',
          })
          .catchError((Object e) =>
              debugPrint('[AnalyticsService] flag properties failed: $e'));
    } catch (e) {
      debugPrint('[AnalyticsService] setup failed: $e');
    }
  }

  /// Tags later events with the arm, without logging a flag exposure.
  void _onFeatureFlagsLoaded() {
    if (!_enabled) return;
    Posthog()
        .getFeatureFlagResult(
          AnalyticsConstants.freeFirstSendFlagKey,
          sendEvent: false,
        )
        .then((r) =>
            _registerArm(armFrom(enabled: r?.enabled, variant: r?.variant)))
        .catchError((Object _) {});
  }

  /// The user's arm of `free-first-send`. Logs a `$feature_flag_called`
  /// exposure, so only call it where the flag changes what happens.
  Future<FreeFirstSendArm> freeFirstSendArm() async {
    if (kDebugMode && AnalyticsConstants.debugFreeFirstSend) {
      return FreeFirstSendArm.on;
    }
    if (!_enabled) return FreeFirstSendArm.unloaded;
    try {
      final result = await Posthog()
          .getFeatureFlagResult(AnalyticsConstants.freeFirstSendFlagKey);
      final arm = armFrom(enabled: result?.enabled, variant: result?.variant);
      _registerArm(arm);
      return arm;
    } catch (e) {
      debugPrint('[AnalyticsService] flag read failed: $e');
      return FreeFirstSendArm.unloaded;
    }
  }

  /// Maps a flag result to an arm. A missing result is [unloaded]; a
  /// boolean `true` or the `test` variant is [on]; anything else is [off].
  static FreeFirstSendArm armFrom({
    required bool? enabled,
    required String? variant,
  }) {
    if (enabled == null) return FreeFirstSendArm.unloaded;
    if (!enabled) return FreeFirstSendArm.off;
    if (variant == null || variant == 'test') return FreeFirstSendArm.on;
    return FreeFirstSendArm.off;
  }

  void _registerArm(FreeFirstSendArm arm) {
    if (!_enabled || arm == FreeFirstSendArm.unloaded) return;
    Posthog()
        .register(_freeFirstSendProperty, arm.name)
        .catchError((Object _) {});
  }

  void onboardingWelcomeViewed() => _capture('onboarding_welcome_viewed');

  void firstGroupCreated({required int recipientCount}) =>
      _capture('first_group_created', {'recipient_count': recipientCount});

  /// Every valid Send tap (message and recipients present), Pro or not.
  /// [freeFirstSend] is the arm that applied; null when the flag wasn't
  /// read (e.g. Pro users), leaving the registered super property in place.
  void sendTapped({
    required int recipientCount,
    required bool hasMedia,
    required bool isFirstSend,
    required bool hasPro,
    FreeFirstSendArm? freeFirstSend,
    required bool paywallSkipped,
  }) =>
      _capture('send_tapped', {
        'recipient_count': recipientCount,
        'has_media': hasMedia,
        'is_first_send': isFirstSend,
        'has_pro': hasPro,
        if (freeFirstSend != null) _freeFirstSendProperty: freeFirstSend.name,
        'paywall_skipped': paywallSkipped,
      });

  void firstSendCompleted({
    required int sent,
    required int cancelled,
    required int failed,
    required bool wasFree,
  }) =>
      _capture('first_send_completed', {
        'sent_count': sent,
        'cancelled_count': cancelled,
        'failed_count': failed,
        'was_free': wasFree,
      });

  void paywallViewed(PaywallTrigger trigger, {FreeFirstSendArm? arm}) =>
      _capture('paywall_viewed', {
        'trigger': _snake(trigger.name),
        if (arm != null) _freeFirstSendProperty: arm.name,
      });

  void purchaseCompleted({String? productId}) => _capture(
        'purchase_completed',
        {if (productId != null) 'package': productId},
      );

  void restoreCompleted({String? productId}) => _capture(
        'restore_completed',
        {if (productId != null) 'package': productId},
      );

  /// The native rating prompt was requested; iOS may still not show it.
  void reviewPromptRequested({required int successfulSends}) => _capture(
        'review_prompt_requested',
        {'successful_sends': successfulSends},
      );

  void reviewLinkOpened() => _capture('review_link_opened');

  void _capture(String event, [Map<String, Object> properties = const {}]) {
    if (!_enabled) return;
    Posthog().capture(eventName: event, properties: properties);
  }

  static String _snake(String camel) => camel.replaceAllMapped(
        RegExp('[A-Z]'),
        (m) => '_${m[0]!.toLowerCase()}',
      );
}
