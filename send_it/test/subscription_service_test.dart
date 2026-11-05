import 'package:flutter_test/flutter_test.dart';
import 'package:purchases_flutter/purchases_flutter.dart';
import 'package:send_it/services/subscription_service.dart';
import 'package:shared_preferences/shared_preferences.dart';

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

    ReceiptStatus check(String? v) => SubscriptionService.classifyOriginalVersion(
          buildInfo(originalApplicationVersion: v).originalApplicationVersion,
        );

    test('paid-era builds are grandfathered', () {
      for (final v in ['1', '4', '6']) {
        expect(check(v), ReceiptStatus.grandfathered, reason: v);
      }
    });

    test('first freemium build and later are not grandfathered', () {
      for (final v in ['7', '120']) {
        expect(check(v), ReceiptStatus.notGrandfathered, reason: v);
      }
    });

    test('TestFlight placeholder is not grandfathered', () {
      expect(check('1.0'), ReceiptStatus.notGrandfathered);
    });

    test('missing or empty is unresolved', () {
      expect(check(null), ReceiptStatus.unresolved);
      expect(check(''), ReceiptStatus.unresolved);
    });
  });

  group('resolveReceiptStatus', () {
    ReceiptStatus r(String? v, bool synced) =>
        SubscriptionService.resolveReceiptStatus(v, syncSucceeded: synced);

    test('null before sync or after failed sync is unresolved', () {
      expect(r(null, false), ReceiptStatus.unresolved);
      expect(r('', false), ReceiptStatus.unresolved);
    });

    test('null after successful sync is not grandfathered', () {
      expect(r(null, true), ReceiptStatus.notGrandfathered);
    });

    test('a non-null value wins regardless of sync state', () {
      expect(r('2', true), ReceiptStatus.grandfathered);
      expect(r('2', false), ReceiptStatus.grandfathered);
      expect(r('7', true), ReceiptStatus.notGrandfathered);
      expect(r('1.0', false), ReceiptStatus.notGrandfathered);
    });
  });

  group('legacy data check', () {
    Future<(bool, SharedPreferences)> run(Map<String, Object> values) async {
      SharedPreferences.setMockInitialValues(values);
      final prefs = await SharedPreferences.getInstance();
      return (await SubscriptionService.runLegacyDataCheck(prefs), prefs);
    }

    test('groups key with data grandfathers', () async {
      final (result, prefs) = await run({
        'message_groups': <String>['{}'],
      });
      expect(result, isTrue);
      expect(prefs.getBool('is_grandfathered_paid_buyer'), isTrue);
      expect(prefs.getBool(SubscriptionService.legacyCheckDoneKey), isTrue);
    });

    test('empty groups list still grandfathers', () async {
      final (result, _) = await run({'message_groups': <String>[]});
      expect(result, isTrue);
    });

    test('absent key does not grandfather but sets the marker', () async {
      final (result, prefs) = await run({});
      expect(result, isFalse);
      expect(prefs.getBool('is_grandfathered_paid_buyer'), isNull);
      expect(prefs.getBool(SubscriptionService.legacyCheckDoneKey), isTrue);
    });

    test('marker already set does not grandfather', () async {
      final (result, prefs) = await run({
        SubscriptionService.legacyCheckDoneKey: true,
        'message_groups': <String>['{}'],
      });
      expect(result, isFalse);
      expect(prefs.getBool('is_grandfathered_paid_buyer'), isNull);
    });
  });

  group('shouldSyncPurchases', () {
    bool sync({
      String? version,
      bool gf = false,
      bool pro = false,
      bool done = false,
    }) =>
        SubscriptionService.shouldSyncPurchases(
          originalVersion: version,
          isGrandfathered: gf,
          hasActiveEntitlement: pro,
          alreadyAttempted: done,
        );

    test('syncs when the version is missing', () {
      expect(sync(), isTrue);
      expect(sync(version: ''), isTrue);
    });

    test('skips when version present, grandfathered, Pro or already tried', () {
      expect(sync(version: '1.0'), isFalse);
      expect(sync(gf: true), isFalse);
      expect(sync(pro: true), isFalse);
      expect(sync(done: true), isFalse);
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
