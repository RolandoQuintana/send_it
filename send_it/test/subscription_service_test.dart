import 'package:flutter_test/flutter_test.dart';
import 'package:purchases_flutter/purchases_flutter.dart';
import 'package:send_it/services/subscription_service.dart';

void main() {
  group('isGrandfatheredFromReceipt', () {
    CustomerInfo buildInfo({String? originalApplicationVersion}) {
      return CustomerInfo.fromJson({
        'entitlements': const {
          'all': <String, dynamic>{},
          'active': <String, dynamic>{},
          'verification': 'NOT_REQUESTED',
        },
        'activeSubscriptions': const <String>[],
        'allPurchasedProductIdentifiers': const <String>[],
        'latestExpirationDate': null,
        'firstSeen': '2026-01-01T00:00:00Z',
        'originalAppUserId': 'test-user',
        'requestDate': '2026-01-01T00:00:00Z',
        'originalPurchaseDate': null,
        'originalApplicationVersion': originalApplicationVersion,
        'managementURL': null,
        'allExpirationDates': const <String, dynamic>{},
        'allPurchaseDates': const <String, dynamic>{},
        'nonSubscriptionTransactions': const <Map<String, dynamic>>[],
        'subscriptionsByProductIdentifier': const <String, dynamic>{},
      });
    }

    bool check(String? v) => SubscriptionService.isGrandfatheredFromReceipt(
          buildInfo(originalApplicationVersion: v),
        );

    test('paid-era builds are grandfathered', () {
      expect(check('1'), isTrue);
      expect(check('2'), isTrue);
      expect(check('4'), isTrue);
    });

    test('first freemium build and later are not grandfathered', () {
      expect(check('7'), isFalse);
      expect(check('8'), isFalse);
      expect(check('120'), isFalse);
    });

    test('TestFlight placeholder, missing and garbage are not grandfathered',
        () {
      expect(check('1.0'), isFalse);
      expect(check(null), isFalse);
      expect(check(''), isFalse);
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
