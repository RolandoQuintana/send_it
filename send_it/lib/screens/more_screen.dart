import 'package:flutter/cupertino.dart';
import 'package:url_launcher/url_launcher.dart';

import '../constants/subscription_constants.dart';
import '../services/subscription_service.dart';
import '../services/shortcut_service.dart';

class MoreScreen extends StatefulWidget {
  const MoreScreen({super.key});

  @override
  State<MoreScreen> createState() => _MoreScreenState();
}

class _MoreScreenState extends State<MoreScreen> {
  final _subscription = SubscriptionService.instance;
  bool _isRestoring = false;

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

  String _proStatusLabel() {
    switch (_subscription.accessSource) {
      case ProAccessSource.grandfathered:
        return 'Lifetime access (original purchase)';
      case ProAccessSource.entitlement:
        final productId = _subscription.customerInfo
            ?.entitlements.active[SubscriptionConstants.entitlementId]
            ?.productIdentifier;
        if (productId?.contains('lifetime') == true) {
          return 'Lifetime Pro';
        }
        return 'Pro subscriber';
      case ProAccessSource.none:
        return 'Not subscribed';
    }
  }

  Future<void> _restorePurchases() async {
    setState(() => _isRestoring = true);
    await _subscription.restorePurchases();
    if (!mounted) return;
    setState(() => _isRestoring = false);

    if (_subscription.hasPro) {
      await showCupertinoDialog<void>(
        context: context,
        builder: (ctx) => CupertinoAlertDialog(
          title: const Text('Restored'),
          content: const Text('Your purchases have been restored.'),
          actions: [
            CupertinoDialogAction(
              child: const Text('OK'),
              onPressed: () => Navigator.pop(ctx),
            ),
          ],
        ),
      );
    } else if (_subscription.errorMessage != null) {
      await showCupertinoDialog<void>(
        context: context,
        builder: (ctx) => CupertinoAlertDialog(
          title: const Text('Restore Failed'),
          content: Text(_subscription.errorMessage!),
          actions: [
            CupertinoDialogAction(
              child: const Text('OK'),
              onPressed: () => Navigator.pop(ctx),
            ),
          ],
        ),
      );
    }
  }

  Future<void> _openUrl(String url) async {
    final uri = Uri.parse(url);
    if (await canLaunchUrl(uri)) {
      await launchUrl(uri, mode: LaunchMode.externalApplication);
    }
  }

  @override
  Widget build(BuildContext context) {
    final showSubscriptionSection = SubscriptionService.isSubscriptionRequired;

    return CupertinoPageScaffold(
      navigationBar: const CupertinoNavigationBar(
        middle: Text('More'),
      ),
      child: SafeArea(
        child: ListView(
          children: [
            const SizedBox(height: 32),
            if (showSubscriptionSection) ...[
              _SectionHeader(label: 'Subscription'),
              _SubscriptionSection(
                statusLabel: _proStatusLabel(),
                hasPro: _subscription.hasPro,
                isGrandfathered: _subscription.isGrandfathered,
                isRestoring: _isRestoring,
                onRestore: _restorePurchases,
                onManageSubscription: () => _openUrl(SubscriptionConstants.manageSubscriptionsUrl),
                onPrivacyPolicy: () => _openUrl(SubscriptionConstants.privacyPolicyUrl),
              ),
              const SizedBox(height: 24),
            ],
            const _SectionHeader(label: 'Shortcuts'),
            _ShortcutSection(context),
          ],
        ),
      ),
    );
  }
}

class _SubscriptionSection extends StatelessWidget {
  const _SubscriptionSection({
    required this.statusLabel,
    required this.hasPro,
    required this.isGrandfathered,
    required this.isRestoring,
    required this.onRestore,
    required this.onManageSubscription,
    required this.onPrivacyPolicy,
  });

  final String statusLabel;
  final bool hasPro;
  final bool isGrandfathered;
  final bool isRestoring;
  final VoidCallback onRestore;
  final VoidCallback onManageSubscription;
  final VoidCallback onPrivacyPolicy;

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16),
      decoration: BoxDecoration(
        color: const Color(0xFF1C1C1E),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Column(
        children: [
          CupertinoListTile(
            leading: Container(
              width: 32,
              height: 32,
              decoration: BoxDecoration(
                color: hasPro
                    ? const Color(0xFF0fa0ab).withOpacity(0.2)
                    : CupertinoColors.systemGrey.withOpacity(0.2),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Icon(
                hasPro ? CupertinoIcons.checkmark_seal_fill : CupertinoIcons.lock,
                color: hasPro ? const Color(0xFF0fa0ab) : CupertinoColors.systemGrey,
                size: 18,
              ),
            ),
            title: const Text('Pro Status'),
            subtitle: Text(statusLabel),
          ),
          if (hasPro && !isGrandfathered)
            CupertinoListTile(
              title: const Text('Manage Subscription'),
              trailing: const CupertinoListTileChevron(),
              onTap: onManageSubscription,
            ),
          CupertinoListTile(
            title: Text(isRestoring ? 'Restoring...' : 'Restore Purchases'),
            trailing: isRestoring
                ? const CupertinoActivityIndicator()
                : const Icon(CupertinoIcons.arrow_clockwise),
            onTap: isRestoring ? null : onRestore,
          ),
          CupertinoListTile(
            title: const Text('Privacy Policy'),
            trailing: const CupertinoListTileChevron(),
            onTap: onPrivacyPolicy,
          ),
        ],
      ),
    );
  }
}

class _SectionHeader extends StatelessWidget {
  final String label;
  const _SectionHeader({required this.label});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 0, 16, 8),
      child: Text(
        label.toUpperCase(),
        style: const TextStyle(
          color: CupertinoColors.systemGrey,
          fontSize: 13,
          fontWeight: FontWeight.w500,
          letterSpacing: 0.5,
        ),
      ),
    );
  }
}

class _ShortcutSection extends StatelessWidget {
  final BuildContext parentContext;
  const _ShortcutSection(this.parentContext);

  void _onInstallTapped() {
    showCupertinoDialog(
      context: parentContext,
      builder: (ctx) => CupertinoAlertDialog(
        title: const Text('Install Blast'),
        content: const Text(
          'A share sheet will appear. Tap the Shortcuts icon to add Blast to your library.',
        ),
        actions: [
          CupertinoDialogAction(
            child: const Text('Cancel'),
            onPressed: () => Navigator.pop(ctx),
          ),
          CupertinoDialogAction(
            isDefaultAction: true,
            child: const Text('Continue'),
            onPressed: () {
              Navigator.pop(ctx);
              ShortcutService.markBlastInstalled();
              ShortcutService.openInstallPage();
            },
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16),
      decoration: BoxDecoration(
        color: const Color(0xFF1C1C1E),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Column(
        children: [
          Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Container(
                      width: 44,
                      height: 44,
                      decoration: BoxDecoration(
                        color: const Color(0xFF0fa0ab),
                        borderRadius: BorderRadius.circular(10),
                      ),
                      child: const Icon(
                        CupertinoIcons.bolt_fill,
                        color: CupertinoColors.white,
                        size: 22,
                      ),
                    ),
                    const SizedBox(width: 12),
                    const Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Sent It Blast',
                            style: TextStyle(
                              color: CupertinoColors.white,
                              fontSize: 16,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                          Text(
                            'Apple Shortcut',
                            style: TextStyle(
                              color: CupertinoColors.systemGrey,
                              fontSize: 13,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 16),
                const Text(
                  'Send individual messages to your entire group with a single tap — no confirm-per-person required.',
                  style: TextStyle(
                    color: CupertinoColors.systemGrey,
                    fontSize: 14,
                    height: 1.4,
                  ),
                ),
                const SizedBox(height: 20),
                _HowItWorksList(),
                const SizedBox(height: 20),
                SizedBox(
                  width: double.infinity,
                  child: CupertinoButton(
                    color: const Color(0xFF0fa0ab),
                    borderRadius: BorderRadius.circular(10),
                    onPressed: _onInstallTapped,
                    child: const Text(
                      'Install Shortcut',
                      style: TextStyle(
                        fontWeight: FontWeight.w600,
                        color: CupertinoColors.white,
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _HowItWorksList extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    const steps = [
      (icon: CupertinoIcons.pencil, text: 'Compose your message in Send It'),
      (icon: CupertinoIcons.bolt, text: 'Tap "Blast" in the + menu'),
      (icon: CupertinoIcons.arrow_right_circle, text: 'The Shortcuts app opens automatically'),
      (icon: CupertinoIcons.checkmark_circle, text: 'Each contact gets an individual message — no tapping through'),
    ];

    return Column(
      children: steps
          .asMap()
          .entries
          .map(
            (entry) => Padding(
              padding: const EdgeInsets.only(bottom: 10),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Container(
                    width: 24,
                    height: 24,
                    decoration: BoxDecoration(
                      color: const Color(0xFF0fa0ab).withOpacity(0.15),
                      shape: BoxShape.circle,
                    ),
                    child: Center(
                      child: Text(
                        '${entry.key + 1}',
                        style: const TextStyle(
                          color: Color(0xFF0fa0ab),
                          fontSize: 12,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Padding(
                      padding: const EdgeInsets.only(top: 3),
                      child: Text(
                        entry.value.text,
                        style: const TextStyle(
                          color: CupertinoColors.white,
                          fontSize: 14,
                          height: 1.3,
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          )
          .toList(),
    );
  }
}
