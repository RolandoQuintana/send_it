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

  group('formatProStatusLabel', () {
    EntitlementInfo buildEntitlement({
      String productIdentifier = 'sent_it_annual',
      String periodType = 'NORMAL',
      String? expirationDate,
    }) {
      return EntitlementInfo.fromJson({
        'identifier': 'pro',
        'isActive': true,
        'willRenew': true,
        'latestPurchaseDate': '2026-01-01T00:00:00Z',
        'originalPurchaseDate': '2026-01-01T00:00:00Z',
        'productIdentifier': productIdentifier,
        'isSandbox': false,
        if (periodType != 'NORMAL') 'periodType': periodType,
        if (expirationDate != null) 'expirationDate': expirationDate,
      });
    }

    test('grandfathered returns lifetime access label', () {
      expect(
        SubscriptionService.formatProStatusLabel(
          accessSource: ProAccessSource.grandfathered,
        ),
        'Lifetime access (original purchase)',
      );
    });

    test('none returns not subscribed', () {
      expect(
        SubscriptionService.formatProStatusLabel(accessSource: ProAccessSource.none),
        'Not subscribed',
      );
    });

    test('trial entitlement returns formatted end date', () {
      final entitlement = buildEntitlement(
        periodType: 'TRIAL',
        expirationDate: '2026-01-30T12:00:00Z',
      );
      expect(
        SubscriptionService.formatProStatusLabel(
          accessSource: ProAccessSource.entitlement,
          proEntitlement: entitlement,
        ),
        'Free trial — ends Jan 30, 2026',
      );
    });

    test('trial entitlement without expiration returns free trial', () {
      final entitlement = buildEntitlement(periodType: 'TRIAL');
      expect(
        SubscriptionService.formatProStatusLabel(
          accessSource: ProAccessSource.entitlement,
          proEntitlement: entitlement,
        ),
        'Free trial',
      );
    });

    test('paid annual entitlement returns pro subscriber', () {
      final entitlement = buildEntitlement();
      expect(
        SubscriptionService.formatProStatusLabel(
          accessSource: ProAccessSource.entitlement,
          proEntitlement: entitlement,
        ),
        'Pro subscriber',
      );
    });

    test('lifetime entitlement returns lifetime pro', () {
      final entitlement = buildEntitlement(productIdentifier: 'sent_it_lifetime');
      expect(
        SubscriptionService.formatProStatusLabel(
          accessSource: ProAccessSource.entitlement,
          proEntitlement: entitlement,
        ),
        'Lifetime Pro',
      );
    });
  });
}
