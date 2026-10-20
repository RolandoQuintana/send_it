import 'package:flutter/cupertino.dart';
import 'package:purchases_ui_flutter/purchases_ui_flutter.dart';

import '../services/subscription_service.dart';
import '../theme/app_surfaces.dart';
import '../theme/app_text.dart';

/// Full-app gate: shows RC remote paywall until the user has pro access.
///
/// Access is determined automatically on launch via [SubscriptionService]:
/// active `pro` entitlement or grandfathered paid-download receipt.
/// Restore is available on the paywall if sync fails.
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
