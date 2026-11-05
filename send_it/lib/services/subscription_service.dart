import 'dart:io';

import 'package:flutter/foundation.dart';
import 'package:purchases_flutter/purchases_flutter.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../constants/subscription_constants.dart';

/// What the App Store receipt says about the user's first install.
enum ReceiptStatus { grandfathered, notGrandfathered, unresolved }

enum ProAccessSource {
  none,
  entitlement,
  grandfathered,
}

/// Single source of truth for Sent It pro access (entitlement + grandfathering).
class SubscriptionService extends ChangeNotifier {
  SubscriptionService._();

  static final SubscriptionService instance = SubscriptionService._();

  static const _grandfatherKey = 'is_grandfathered_paid_buyer';

  /// Set once the legacy local-data check has run on this install, so it
  /// never runs again (a free user's later groups must not grandfather them).
  static const legacyCheckDoneKey = 'legacy_data_check_done';

  /// The groups storage key used by the paid 1.2.0 app (see GroupStorage).
  static const _legacyGroupsKey = 'message_groups';

  static const evaluationTimeout = Duration(seconds: 5);

  bool _initialized = false;
  bool _isLoading = true;
  bool _isGrandfathered = false;
  bool _hasActiveEntitlement = false;
  bool _receiptUnresolved = true;
  bool _syncAttempted = false;
  bool _syncSucceeded = false;
  Future<void>? _syncFuture;
  CustomerInfo? _customerInfo;
  String? _errorMessage;

  bool get isLoading => _isLoading;
  bool get isGrandfathered => _isGrandfathered;
  bool get hasActiveEntitlement => _hasActiveEntitlement;
  CustomerInfo? get customerInfo => _customerInfo;
  String? get errorMessage => _errorMessage;

  /// iOS-only v1 — other platforms bypass the subscription gate.
  static bool get isSubscriptionRequired => Platform.isIOS;

  bool get hasPro {
    if (!isSubscriptionRequired) return true;
    return _hasActiveEntitlement || _isGrandfathered;
  }

  /// True while we can't tell whether a non-Pro user is a paid-era buyer
  /// (receipt version missing and nothing found locally). Such users are
  /// not paywalled; nothing is cached, so it is re-evaluated next launch.
  /// Deliberately separate from [hasPro].
  bool get isAccessUnresolved =>
      isSubscriptionRequired && !hasPro && _receiptUnresolved;

  /// Waits (bounded) for the launch-time receipt sync, so a quick Send tap
  /// doesn't paywall a paid user. On timeout the state stays unresolved.
  Future<void> waitForEvaluation({Duration timeout = evaluationTimeout}) async {
    final pending = _syncFuture;
    if (pending == null) return;
    await pending.timeout(timeout, onTimeout: () {});
  }

  ProAccessSource get accessSource {
    if (!isSubscriptionRequired) return ProAccessSource.entitlement;
    if (_isGrandfathered) return ProAccessSource.grandfathered;
    if (_hasActiveEntitlement) return ProAccessSource.entitlement;
    return ProAccessSource.none;
  }

  String get proStatusLabel => formatProStatusLabel(
        accessSource: accessSource,
        proEntitlement:
            _customerInfo?.entitlements.active[SubscriptionConstants.entitlementId],
      );

  Future<void> initialize() async {
    if (_initialized) return;
    _initialized = true;

    if (!isSubscriptionRequired) {
      _isLoading = false;
      notifyListeners();
      return;
    }

    // Must run before anything can write `message_groups`; main() awaits
    // this before runApp.
    await _loadCachedGrandfatherFlag();
    await _runLegacyDataCheck();

    final apiKey = SubscriptionConstants.revenueCatIosApiKey;
    if (apiKey.isEmpty) {
      _errorMessage = 'RevenueCat API key missing.';
      _isLoading = false;
      notifyListeners();
      return;
    }

    if (!kReleaseMode) {
      await Purchases.setLogLevel(LogLevel.debug);
      debugPrint(
        '[SubscriptionService] RevenueCat Test Store (debug) — '
        'release builds use App Store key',
      );
    }

    Purchases.addCustomerInfoUpdateListener(_onCustomerInfoUpdated);

    await Purchases.configure(
      PurchasesConfiguration(apiKey),
    );

    await refreshCustomerInfo();
  }

  Future<void> _loadCachedGrandfatherFlag() async {
    final prefs = await SharedPreferences.getInstance();
    _isGrandfathered = prefs.getBool(_grandfatherKey) ?? false;
  }

  /// First run on this install only: a `message_groups` key (even an empty
  /// list) means the paid-era app was used here.
  Future<void> _runLegacyDataCheck() async {
    final prefs = await SharedPreferences.getInstance();
    if (await runLegacyDataCheck(prefs)) _isGrandfathered = true;
  }

  /// Returns true if the user was grandfathered by this check. Always sets
  /// the marker so the check never runs twice on an install.
  @visibleForTesting
  static Future<bool> runLegacyDataCheck(SharedPreferences prefs) async {
    final grandfather = shouldGrandfatherFromLegacyData(
      checkDone: prefs.getBool(legacyCheckDoneKey) ?? false,
      hasGroupsKey: prefs.containsKey(_legacyGroupsKey),
    );
    if (grandfather) await prefs.setBool(_grandfatherKey, true);
    await prefs.setBool(legacyCheckDoneKey, true);
    return grandfather;
  }

  @visibleForTesting
  static bool shouldGrandfatherFromLegacyData({
    required bool checkDone,
    required bool hasGroupsKey,
  }) =>
      !checkDone && hasGroupsKey;

  Future<void> refreshCustomerInfo() async {
    if (!isSubscriptionRequired) return;

    _isLoading = true;
    _errorMessage = null;
    notifyListeners();

    try {
      final info = await Purchases.getCustomerInfo();
      await _applyCustomerInfo(info);
      _startSyncIfNeeded(info);
    } catch (e) {
      _errorMessage = e.toString();
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  /// Receipt version is nil until purchases are synced with RevenueCat.
  /// Syncs once per launch, in the background (not awaited here).
  void _startSyncIfNeeded(CustomerInfo info) {
    if (!shouldSyncPurchases(
      originalVersion: effectiveOriginalVersion(info),
      isGrandfathered: _isGrandfathered,
      hasActiveEntitlement: _hasActiveEntitlement,
      alreadyAttempted: _syncAttempted,
    )) {
      return;
    }
    _syncAttempted = true;
    _syncFuture = () async {
      try {
        await Purchases.syncPurchases();
        final synced = await Purchases.getCustomerInfo();
        _syncSucceeded = true;
        await _applyCustomerInfo(synced);
        notifyListeners();
      } catch (e) {
        debugPrint('[SubscriptionService] syncPurchases failed: $e');
      }
    }();
  }

  @visibleForTesting
  static bool shouldSyncPurchases({
    required String? originalVersion,
    required bool isGrandfathered,
    required bool hasActiveEntitlement,
    required bool alreadyAttempted,
  }) =>
      !alreadyAttempted &&
      !isGrandfathered &&
      !hasActiveEntitlement &&
      (originalVersion == null || originalVersion.isEmpty);

  Future<void> restorePurchases() async {
    if (!isSubscriptionRequired) return;

    _isLoading = true;
    _errorMessage = null;
    notifyListeners();

    try {
      final info = await Purchases.restorePurchases();
      await _applyCustomerInfo(info);
    } catch (e) {
      _errorMessage = e.toString();
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  void _onCustomerInfoUpdated(CustomerInfo info) {
    _applyCustomerInfo(info);
  }

  Future<void> _applyCustomerInfo(CustomerInfo info) async {
    _customerInfo = info;
    _hasActiveEntitlement =
        info.entitlements.active.containsKey(SubscriptionConstants.entitlementId);

    final status = resolveReceiptStatus(
      effectiveOriginalVersion(info),
      syncSucceeded: _syncSucceeded,
    );
    _receiptUnresolved = status == ReceiptStatus.unresolved;
    if (!_isGrandfathered && status == ReceiptStatus.grandfathered) {
      await _cacheGrandfatherFlag(true);
    }

    notifyListeners();
  }

  /// Human-readable Pro status for More screen.
  @visibleForTesting
  static String formatProStatusLabel({
    required ProAccessSource accessSource,
    EntitlementInfo? proEntitlement,
  }) {
    switch (accessSource) {
      case ProAccessSource.grandfathered:
        return 'Lifetime access (original purchase)';
      case ProAccessSource.none:
        return 'Not subscribed';
      case ProAccessSource.entitlement:
        if (proEntitlement == null) return 'Pro subscriber';
        if (proEntitlement.periodType == PeriodType.trial) {
          final end = _formatExpirationDate(proEntitlement.expirationDate);
          return end != null ? 'Free trial — ends $end' : 'Free trial';
        }
        if (proEntitlement.productIdentifier.contains('lifetime')) {
          return 'Lifetime Pro';
        }
        return 'Pro subscriber';
    }
  }

  static String? _formatExpirationDate(String? iso) {
    if (iso == null || iso.isEmpty) return null;
    final dt = DateTime.parse(iso).toLocal();
    const months = [
      'Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun',
      'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec',
    ];
    return '${months[dt.month - 1]} ${dt.day}, ${dt.year}';
  }

  /// The receipt's first-installed build, with the debug override applied.
  @visibleForTesting
  static String? effectiveOriginalVersion(CustomerInfo info) {
    const override = SubscriptionConstants.debugOriginalAppVersion;
    return kDebugMode && override.isNotEmpty
        ? override
        : info.originalApplicationVersion;
  }

  /// A non-empty version always wins. A missing one is unresolved until a
  /// sync has succeeded; after that it is a definite "not grandfathered"
  /// (normal paywall, Restore available). Never cached.
  @visibleForTesting
  static ReceiptStatus resolveReceiptStatus(
    String? version, {
    required bool syncSucceeded,
  }) {
    final status = classifyOriginalVersion(version);
    if (status == ReceiptStatus.unresolved && syncSucceeded) {
      return ReceiptStatus.notGrandfathered;
    }
    return status;
  }

  /// iOS reports the build number of the first install. TestFlight/sandbox
  /// receipts report "1.0", which does not parse, so testers are not
  /// grandfathered. Null or empty means not synced yet: unresolved.
  @visibleForTesting
  static ReceiptStatus classifyOriginalVersion(
    String? version, {
    int firstFreemiumBuild = SubscriptionConstants.firstFreemiumBuild,
  }) {
    if (version == null || version.isEmpty) return ReceiptStatus.unresolved;
    final firstBuild = int.tryParse(version);
    return firstBuild != null && firstBuild < firstFreemiumBuild
        ? ReceiptStatus.grandfathered
        : ReceiptStatus.notGrandfathered;
  }

  Future<void> _cacheGrandfatherFlag(bool value) async {
    _isGrandfathered = value;
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(_grandfatherKey, value);
  }

  @visibleForTesting
  static Future<void> clearLocalStateForTests() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(_grandfatherKey);
    await prefs.remove(legacyCheckDoneKey);
  }
}
