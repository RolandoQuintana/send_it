import 'dart:io';

import 'package:flutter/foundation.dart';
import 'package:purchases_flutter/purchases_flutter.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../constants/subscription_constants.dart';

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

  bool _initialized = false;
  bool _isLoading = true;
  bool _isGrandfathered = false;
  bool _hasActiveEntitlement = false;
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

    await _loadCachedGrandfatherFlag();

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

  Future<void> refreshCustomerInfo() async {
    if (!isSubscriptionRequired) return;

    _isLoading = true;
    _errorMessage = null;
    notifyListeners();

    try {
      final info = await Purchases.getCustomerInfo();
      await _applyCustomerInfo(info);
    } catch (e) {
      _errorMessage = e.toString();
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

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

    if (!_isGrandfathered && isGrandfatheredFromReceipt(info)) {
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

  /// Whether the user originally paid for the app before the freemium cutoff.
  @visibleForTesting
  static bool isGrandfatheredFromReceipt(
    CustomerInfo info, {
    DateTime? cutoffUtc,
  }) {
    final dateStr = info.originalPurchaseDate;
    if (dateStr == null || dateStr.isEmpty) return false;

    final purchaseDate = DateTime.parse(dateStr).toUtc();
    final cutoff = cutoffUtc ?? SubscriptionConstants.grandfatherCutoffUtc;
    return purchaseDate.isBefore(cutoff);
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
  }
}
