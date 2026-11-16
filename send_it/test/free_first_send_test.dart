import 'package:flutter_test/flutter_test.dart';
import 'package:send_it/services/analytics_service.dart';
import 'package:send_it/services/onboarding_service.dart';
import 'package:send_it/widgets/subscription_gate.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  group('AnalyticsService.armFrom', () {
    FreeFirstSendArm arm(bool? enabled, [String? variant]) =>
        AnalyticsService.armFrom(enabled: enabled, variant: variant);

    test('no result is unloaded', () {
      expect(arm(null), FreeFirstSendArm.unloaded);
    });

    test('boolean flag maps to on/off', () {
      expect(arm(true), FreeFirstSendArm.on);
      expect(arm(false), FreeFirstSendArm.off);
    });

    test('only the test variant is on', () {
      expect(arm(true, 'test'), FreeFirstSendArm.on);
      expect(arm(true, 'control'), FreeFirstSendArm.off);
      expect(arm(true, 'something-else'), FreeFirstSendArm.off);
    });
  });

  group('SubscriptionGate.freeFirstSendAllowed', () {
    bool allowed({
      bool subscriptionRequired = true,
      bool hasPro = false,
      bool hasCompletedFirstSend = false,
      FreeFirstSendArm arm = FreeFirstSendArm.on,
    }) =>
        SubscriptionGate.freeFirstSendAllowed(
          subscriptionRequired: subscriptionRequired,
          hasPro: hasPro,
          hasCompletedFirstSend: hasCompletedFirstSend,
          arm: arm,
        );

    test('non-Pro first send with the flag on is free', () {
      expect(allowed(), isTrue);
    });

    test('flag off or unloaded keeps the paywall', () {
      expect(allowed(arm: FreeFirstSendArm.off), isFalse);
      expect(allowed(arm: FreeFirstSendArm.unloaded), isFalse);
    });

    test('only the first send is free', () {
      expect(allowed(hasCompletedFirstSend: true), isFalse);
    });

    test('Pro users and non-gated platforms never need it', () {
      expect(allowed(hasPro: true), isFalse);
      expect(allowed(subscriptionRequired: false), isFalse);
    });
  });

  group('free first send, then the launch gate', () {
    test('after the free send the app stays unlocked but Send is paywalled',
        () {
      expect(
        SubscriptionGate.isLocked(
          subscriptionRequired: true,
          hasPro: false,
          hasCompletedFirstSend: true,
          usedFreeFirstSend: true,
        ),
        isFalse,
      );
      expect(
        SubscriptionGate.needsPaywallToSend(
          subscriptionRequired: true,
          hasPro: false,
          accessUnresolved: false,
        ),
        isTrue,
      );
    });

    test('without the free send a lapsed user is still locked', () {
      expect(
        SubscriptionGate.isLocked(
          subscriptionRequired: true,
          hasPro: false,
          hasCompletedFirstSend: true,
        ),
        isTrue,
      );
    });
  });

  group('OnboardingService free first send', () {
    test('is remembered across launches', () async {
      SharedPreferences.setMockInitialValues({});
      final first = OnboardingService.forTesting();
      await first.initialize();
      expect(first.hasUsedFreeFirstSend, isFalse);

      await first.markFreeFirstSendUsed();
      await first.markFirstSendCompleted();
      expect(first.hasUsedFreeFirstSend, isTrue);

      final next = OnboardingService.forTesting();
      await next.initialize();
      expect(next.hasUsedFreeFirstSend, isTrue);
      expect(next.hasCompletedFirstSend, isTrue);
    });

    test('the gate already sees the exemption when the send is marked',
        () async {
      SharedPreferences.setMockInitialValues({});
      final service = OnboardingService.forTesting();
      await service.initialize();

      bool? lockedOnNotify;
      service.addListener(() {
        lockedOnNotify = SubscriptionGate.isLocked(
          subscriptionRequired: true,
          hasPro: false,
          hasCompletedFirstSend: service.hasCompletedFirstSend,
          usedFreeFirstSend: service.hasUsedFreeFirstSend,
        );
      });
      await service.markFreeFirstSendUsed();
      await service.markFirstSendCompleted();

      expect(lockedOnNotify, isFalse);
    });

    test('existing users start without the exemption', () async {
      SharedPreferences.setMockInitialValues({'message_groups': <String>[]});
      final service = OnboardingService.forTesting();
      await service.initialize();
      expect(service.hasUsedFreeFirstSend, isFalse);
    });
  });
}
