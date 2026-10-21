import 'package:flutter_test/flutter_test.dart';
import 'package:send_it/services/onboarding_service.dart';
import 'package:send_it/widgets/subscription_gate.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  group('OnboardingService', () {
    test('fresh install starts with every step to do', () async {
      SharedPreferences.setMockInitialValues({});
      final service = OnboardingService.forTesting();
      await service.initialize();

      expect(service.hasSeenWelcome, isFalse);
      expect(service.hasCreatedFirstGroup, isFalse);
      expect(service.hasUsedFirstMessagePrefill, isFalse);
      expect(service.hasCompletedFirstSend, isFalse);
      // Nothing written, so AppearanceService still sees a fresh install.
      final prefs = await SharedPreferences.getInstance();
      expect(prefs.getKeys(), isEmpty);
    });

    test('existing user skips the first-run UI but not the first send',
        () async {
      SharedPreferences.setMockInitialValues({'message_groups': <String>[]});
      final service = OnboardingService.forTesting();
      await service.initialize();

      expect(service.hasSeenWelcome, isTrue);
      expect(service.hasCreatedFirstGroup, isTrue);
      expect(service.hasUsedFirstMessagePrefill, isTrue);
      expect(service.hasSeenSendExplainer, isTrue);
      expect(service.hasCompletedFirstSend, isFalse);
    });

    test('a new user is not mistaken for an existing one next launch',
        () async {
      SharedPreferences.setMockInitialValues({});
      final first = OnboardingService.forTesting();
      await first.initialize();
      await first.markWelcomeSeen();

      final second = OnboardingService.forTesting();
      await second.initialize();
      expect(second.hasSeenWelcome, isTrue);
      expect(second.hasUsedFirstMessagePrefill, isFalse);
    });

    test('the send explainer is shown until confirmed once', () async {
      SharedPreferences.setMockInitialValues({});
      final service = OnboardingService.forTesting();
      await service.initialize();
      expect(service.hasSeenSendExplainer, isFalse);

      await service.markSendExplainerSeen();
      final relaunched = OnboardingService.forTesting();
      await relaunched.initialize();
      expect(relaunched.hasSeenSendExplainer, isTrue);
    });

    test('the prefill and first-group flags fire once', () async {
      SharedPreferences.setMockInitialValues({});
      final service = OnboardingService.forTesting();
      await service.initialize();

      expect(await service.consumeFirstMessagePrefill(), isTrue);
      expect(await service.consumeFirstMessagePrefill(), isFalse);
      expect(await service.markFirstGroupCreated(), isTrue);
      expect(await service.markFirstGroupCreated(), isFalse);
    });

    test('first send persists and notifies listeners', () async {
      SharedPreferences.setMockInitialValues({});
      final service = OnboardingService.forTesting();
      await service.initialize();
      var notified = 0;
      service.addListener(() => notified++);

      await service.markFirstSendCompleted();
      expect(service.hasCompletedFirstSend, isTrue);
      expect(notified, 1);

      final relaunched = OnboardingService.forTesting();
      await relaunched.initialize();
      expect(relaunched.hasCompletedFirstSend, isTrue);
    });
  });

  group('SubscriptionGate.isLocked', () {
    bool locked({
      bool required = true,
      bool hasPro = false,
      bool firstSend = false,
    }) =>
        SubscriptionGate.isLocked(
          subscriptionRequired: required,
          hasPro: hasPro,
          hasCompletedFirstSend: firstSend,
        );

    test('a new non-Pro user gets in to make their first send', () {
      expect(locked(), isFalse);
    });

    test('after the first send a non-Pro user is gated', () {
      expect(locked(firstSend: true), isTrue);
    });

    test('Pro and grandfathered users are never gated', () {
      expect(locked(hasPro: true, firstSend: true), isFalse);
    });

    test('platforms without subscriptions are never gated', () {
      expect(locked(required: false, firstSend: true), isFalse);
    });
  });

  group('SubscriptionGate.needsPaywallToSend', () {
    test('a non-Pro user sees the paywall at Send', () {
      expect(
        SubscriptionGate.needsPaywallToSend(
          subscriptionRequired: true,
          hasPro: false,
        ),
        isTrue,
      );
    });

    test('Pro and grandfathered users send straight away', () {
      expect(
        SubscriptionGate.needsPaywallToSend(
          subscriptionRequired: true,
          hasPro: true,
        ),
        isFalse,
      );
    });

    test('platforms without subscriptions never see it', () {
      expect(
        SubscriptionGate.needsPaywallToSend(
          subscriptionRequired: false,
          hasPro: false,
        ),
        isFalse,
      );
    });
  });
}
