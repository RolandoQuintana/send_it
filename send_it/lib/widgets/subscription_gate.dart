import 'package:flutter/cupertino.dart';
import 'package:purchases_ui_flutter/purchases_ui_flutter.dart';

import '../services/subscription_service.dart';

/// Full-app gate: shows RC remote paywall until the user has pro access.
///
/// Access is determined automatically on launch via [SubscriptionService]:
/// active `pro` entitlement or grandfathered paid-download receipt.
/// Restore is available on the paywall and More screen if sync fails.
class SubscriptionGate extends StatefulWidget {
  const SubscriptionGate({super.key, required this.child});

  final Widget child;

  @override
  State<SubscriptionGate> createState() => _SubscriptionGateState();
}

class _SubscriptionGateState extends State<SubscriptionGate> {
  final _subscription = SubscriptionService.instance;

  @override
  void initState() {
    super.initState();
    _subscription.addListener(_onSubscriptionChanged);
  }

  @override
  void dispose() {
    _subscription.removeListener(_onSubscriptionChanged);
    super.dispose();
  }

  void _onSubscriptionChanged() {
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

    if (_subscription.hasPro) {
      return widget.child;
    }

    if (_subscription.errorMessage != null &&
        _subscription.errorMessage!.contains('API key')) {
      return CupertinoPageScaffold(
        navigationBar: const CupertinoNavigationBar(middle: Text('Sent It')),
        child: SafeArea(
          child: Padding(
            padding: const EdgeInsets.all(24),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const Icon(
                  CupertinoIcons.exclamationmark_triangle,
                  size: 48,
                  color: CupertinoColors.systemYellow,
                ),
                const SizedBox(height: 16),
                const Text(
                  'Subscription setup required',
                  textAlign: TextAlign.center,
                  style: TextStyle(fontSize: 18, fontWeight: FontWeight.w600),
                ),
                const SizedBox(height: 8),
                Text(
                  _subscription.errorMessage!,
                  textAlign: TextAlign.center,
                  style: const TextStyle(color: CupertinoColors.systemGrey),
                ),
              ],
            ),
          ),
        ),
      );
    }

    return PaywallView(
      displayCloseButton: false,
      onPurchaseCompleted: (_, __) {
        if (mounted) setState(() {});
      },
      onRestoreCompleted: (_) {
        if (mounted) setState(() {});
      },
      onDismiss: () {},
    );
  }
}
