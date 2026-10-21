import 'dart:io';

import 'package:flutter/foundation.dart';
import 'package:posthog_flutter/posthog_flutter.dart';

import '../constants/analytics_constants.dart';

/// Where a paywall was shown from, for `paywall_viewed`.
enum PaywallTrigger { send, launch, blast, settings }

/// Onboarding + paywall funnel events (PostHog).
///
/// No PII: never pass names, phone numbers or message text as properties.
/// iOS-only like the paywall; a no-op elsewhere (and in tests).
class AnalyticsService {
  AnalyticsService._();

  static final AnalyticsService instance = AnalyticsService._();

  bool _enabled = false;

  Future<void> initialize() async {
    if (_enabled || !Platform.isIOS) return;
    const apiKey = AnalyticsConstants.postHogApiKey;
    if (apiKey.isEmpty) return;

    final config = PostHogConfig(apiKey)
      ..host = AnalyticsConstants.postHogHost
      ..captureApplicationLifecycleEvents = true
      ..personProfiles = PostHogPersonProfiles.identifiedOnly
      // Messages and contact names are on screen: never record them.
      ..sessionReplay = false
      ..debug = !kReleaseMode;

    try {
      await Posthog().setup(config);
      // The PostHog project is shared with other apps.
      await Posthog().register('app', 'sent_it');
      _enabled = true;
    } catch (e) {
      debugPrint('[AnalyticsService] setup failed: $e');
    }
  }

  void onboardingWelcomeViewed() => _capture('onboarding_welcome_viewed');

  void firstGroupCreated({required int recipientCount}) =>
      _capture('first_group_created', {'recipient_count': recipientCount});

  /// Every valid Send tap (message and recipients present), Pro or not.
  void sendTapped({
    required int recipientCount,
    required bool hasMedia,
    required bool isFirstSend,
    required bool hasPro,
  }) =>
      _capture('send_tapped', {
        'recipient_count': recipientCount,
        'has_media': hasMedia,
        'is_first_send': isFirstSend,
        'has_pro': hasPro,
      });

  void firstSendCompleted({
    required int sent,
    required int cancelled,
    required int failed,
  }) =>
      _capture('first_send_completed', {
        'sent_count': sent,
        'cancelled_count': cancelled,
        'failed_count': failed,
      });

  void paywallViewed(PaywallTrigger trigger) =>
      _capture('paywall_viewed', {'trigger': _snake(trigger.name)});

  void purchaseCompleted({String? productId}) => _capture(
        'purchase_completed',
        {if (productId != null) 'package': productId},
      );

  void restoreCompleted({String? productId}) => _capture(
        'restore_completed',
        {if (productId != null) 'package': productId},
      );

  void _capture(String event, [Map<String, Object> properties = const {}]) {
    if (!_enabled) return;
    Posthog().capture(eventName: event, properties: properties);
  }

  static String _snake(String camel) => camel.replaceAllMapped(
        RegExp('[A-Z]'),
        (m) => '_${m[0]!.toLowerCase()}',
      );
}
