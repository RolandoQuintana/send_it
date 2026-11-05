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

  /// First build number that shipped as a free download with in-app purchases.
  /// Users whose receipt says they first installed an older build (the paid
  /// era, builds 1-4) are grandfathered. Independent of release timing.
  static const firstFreemiumBuild = 7;

  /// Debug-only: pretend the receipt's first-installed build is this value.
  /// Ignored in release builds. `--dart-define=DEBUG_ORIGINAL_APP_VERSION=2`
  static const debugOriginalAppVersion =
      String.fromEnvironment('DEBUG_ORIGINAL_APP_VERSION');
}
