import 'package:flutter/cupertino.dart';
import 'package:purchases_ui_flutter/purchases_ui_flutter.dart';

import '../services/analytics_service.dart';
import '../services/onboarding_service.dart';
import '../services/subscription_service.dart';
import '../theme/app_surfaces.dart';
import '../theme/app_text.dart';

/// Full-app launch gate. Non-Pro users pay at their first Send tap (see
/// [needsPaywallToSend]); this catches anyone who has sent before but lost
/// Pro: a lapsed trial or subscription, or a free send under an older build.
///
/// Access is determined automatically on launch via [SubscriptionService]:
/// active `pro` entitlement or grandfathered paid-download receipt.
/// Restore is available on the paywall if sync fails.
class SubscriptionGate extends StatefulWidget {
  const SubscriptionGate({super.key, required this.child});

  final Widget child;

  /// Whether the paywall replaces the app.
  static bool isLocked({
    required bool subscriptionRequired,
    required bool hasPro,
    required bool hasCompletedFirstSend,
  }) =>
      subscriptionRequired && !hasPro && hasCompletedFirstSend;

  /// Whether tapping Send must show the paywall first.
  static bool needsPaywallToSend({
    required bool subscriptionRequired,
    required bool hasPro,
  }) =>
      subscriptionRequired && !hasPro;

  @override
  State<SubscriptionGate> createState() => _SubscriptionGateState();
}

class _SubscriptionGateState extends State<SubscriptionGate> {
  final _subscription = SubscriptionService.instance;
  final _onboarding = OnboardingService.instance;
  bool _loggedPaywallView = false;

  @override
  void initState() {
    super.initState();
    _subscription.addListener(_onChanged);
    _onboarding.addListener(_onChanged);
  }

  @override
  void dispose() {
    _subscription.removeListener(_onChanged);
    _onboarding.removeListener(_onChanged);
    super.dispose();
  }

  void _onChanged() {
    if (mounted) setState(() {});
  }

  @override
  Widget build(BuildContext context) {
    if (!SubscriptionService.isSubscriptionRequired) {
      return widget.child;
    }

    if (_subscription.isLoading) {
      return const CupertinoPageScaffold(
        child: Center(child: CupertinoActivityIndicator()),
      );
    }

    final locked = SubscriptionGate.isLocked(
      subscriptionRequired: SubscriptionService.isSubscriptionRequired,
      hasPro: _subscription.hasPro,
      hasCompletedFirstSend: _onboarding.hasCompletedFirstSend,
    );
    if (!locked) {
      _loggedPaywallView = false;
      return widget.child;
    }

    if (_subscription.errorMessage != null &&
        _subscription.errorMessage!.contains('API key')) {
      final surfaces = context.surfaces;
      return CupertinoPageScaffold(
        navigationBar: const CupertinoNavigationBar(middle: Text('Sent It')),
        child: SafeArea(
          child: Padding(
            padding: const EdgeInsets.all(24),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(
                  CupertinoIcons.exclamationmark_triangle_fill,
                  size: 48,
                  color: surfaces.warning,
                ),
                const SizedBox(height: 16),
                Text(
                  'Subscription setup required',
                  textAlign: TextAlign.center,
                  style: AppText.title3.copyWith(color: surfaces.ink),
                ),
                const SizedBox(height: 8),
                Text(
                  _subscription.errorMessage!,
                  textAlign: TextAlign.center,
                  style: AppText.subhead.copyWith(color: surfaces.muted),
                ),
              ],
            ),
          ),
        ),
      );
    }

    if (!_loggedPaywallView) {
      _loggedPaywallView = true;
      AnalyticsService.instance.paywallViewed(PaywallTrigger.launch);
    }

    return PaywallView(
      displayCloseButton: false,
      onPurchaseCompleted: (_, transaction) {
        AnalyticsService.instance
            .purchaseCompleted(productId: transaction.productIdentifier);
        if (mounted) setState(() {});
      },
      onRestoreCompleted: (info) {
        AnalyticsService.instance.restoreCompleted(
          productId:
              info.entitlements.active.values.firstOrNull?.productIdentifier,
        );
        if (mounted) setState(() {});
      },
      onDismiss: () {},
    );
  }
}
