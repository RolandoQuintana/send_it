import 'package:flutter_test/flutter_test.dart';
import 'package:purchases_flutter/purchases_flutter.dart';
import 'package:send_it/services/subscription_service.dart';

void main() {
  group('isGrandfatheredFromReceipt', () {
    final cutoff = DateTime.utc(2026, 8, 1);

  CustomerInfo buildInfo({String? originalPurchaseDate}) {
    return CustomerInfo.fromJson({
      'entitlements': {
        'all': <String, dynamic>{},
        'active': <String, dynamic>{},
        'verification': 'NOT_REQUESTED',
      },
      'activeSubscriptions': <String>[],
      'allPurchasedProductIdentifiers': <String>[],
      'latestExpirationDate': null,
      'firstSeen': '2026-01-01T00:00:00Z',
      'originalAppUserId': 'test-user',
      'requestDate': '2026-01-01T00:00:00Z',
      'originalPurchaseDate': originalPurchaseDate,
      'originalApplicationVersion': '1',
      'managementURL': null,
      'allExpirationDates': <String, dynamic>{},
      'allPurchaseDates': <String, dynamic>{},
      'nonSubscriptionTransactions': <Map<String, dynamic>>[],
      'subscriptionsByProductIdentifier': <String, dynamic>{},
    });
  }

    test('returns true when original purchase is before cutoff', () {
      final info = buildInfo(originalPurchaseDate: '2026-07-15T12:00:00Z');
      expect(
        SubscriptionService.isGrandfatheredFromReceipt(info, cutoffUtc: cutoff),
        isTrue,
      );
    });

    test('returns false when original purchase is on or after cutoff', () {
      final info = buildInfo(originalPurchaseDate: '2026-08-01T00:00:00Z');
      expect(
        SubscriptionService.isGrandfatheredFromReceipt(info, cutoffUtc: cutoff),
        isFalse,
      );
    });

    test('returns false when original purchase date is missing', () {
      final info = buildInfo();
      expect(
        SubscriptionService.isGrandfatheredFromReceipt(info, cutoffUtc: cutoff),
        isFalse,
      );
    });
  });
}
