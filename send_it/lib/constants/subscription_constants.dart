import 'package:flutter/foundation.dart';

/// RevenueCat and grandfathering constants for Sent It IAP.
class SubscriptionConstants {
  SubscriptionConstants._();

  static const entitlementId = 'pro';

  static const privacyPolicyUrl =
      'https://www.termsfeed.com/live/707a5825-ae79-4e86-9ddc-edeeaeba78a9';

  /// Interim Apple standard EULA until TermsFeed doc is created for App Review.
  static const termsOfUseUrl =
      'https://www.apple.com/legal/internet-services/itunes/dev/stdeula/';

  static const manageSubscriptionsUrl =
      'https://apps.apple.com/account/subscriptions';

  /// App Store SDK key (`appl_...`) — used in release builds only.
  static const iosApiKey = String.fromEnvironment(
    'RC_IOS_API_KEY',
    defaultValue: 'appl_YeCBAZIYgrTUCaNNWIBOnooYZoT',
  );

  /// RevenueCat Test Store key (`test_...`) — debug/profile simulator iteration.
  static const iosTestStoreApiKey = String.fromEnvironment(
    'RC_IOS_TEST_API_KEY',
    defaultValue: 'test_DpfhiPObXBCBTUPTQItSVSfrbFf',
  );

  /// Debug uses Test Store (no ASC/StoreKit). Release uses App Store key.
  static String get revenueCatIosApiKey =>
      kReleaseMode ? iosApiKey : iosTestStoreApiKey;

  /// UTC instant when the app price changed to free in App Store Connect.
  /// Users who originally purchased before this date are grandfathered.
  /// Set at release: `--dart-define=GRANDFATHER_CUTOFF_ISO=2026-08-01T00:00:00.000Z`
  static DateTime get grandfatherCutoffUtc {
    const iso = String.fromEnvironment(
      'GRANDFATHER_CUTOFF_ISO',
      defaultValue: '2099-01-01T00:00:00.000Z',
    );
    return DateTime.parse(iso).toUtc();
  }
}
