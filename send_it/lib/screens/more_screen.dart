import 'package:flutter/cupertino.dart';

import '../constants/diagnostic_constants.dart';
import '../services/appearance_service.dart';
import '../services/blast_feature_service.dart';
import '../services/subscription_service.dart';
import '../services/shortcut_service.dart';
import '../theme/app_surfaces.dart';
import '../theme/app_text.dart';

class MoreScreen extends StatefulWidget {
  const MoreScreen({super.key});

  @override
  State<MoreScreen> createState() => _MoreScreenState();
}

class _MoreScreenState extends State<MoreScreen> {
  final _subscription = SubscriptionService.instance;
  final _blastFeature = BlastFeatureService.instance;

  @override
  void initState() {
    super.initState();
    _subscription.addListener(_onSubscriptionChanged);
    _blastFeature.addListener(_onBlastFeatureChanged);
  }

  @override
  void dispose() {
    _subscription.removeListener(_onSubscriptionChanged);
    _blastFeature.removeListener(_onBlastFeatureChanged);
    super.dispose();
  }

  void _onSubscriptionChanged() {
    if (mounted) setState(() {});
  }

  void _onBlastFeatureChanged() {
    if (mounted) setState(() {});
  }

  Future<void> _onBlastToggleChanged(bool value) async {
    if (!value) {
      await _blastFeature.setEnabled(false);
      return;
    }

    if (!_blastFeature.hasAcknowledgedWarning) {
      final confirmed = await showCupertinoDialog<bool>(
        context: context,
        builder: (ctx) => CupertinoAlertDialog(
          title: const Text('Experimental Feature'),
          content: const Text(BlastFeatureService.experimentalDisclaimer),
          actions: [
            CupertinoDialogAction(
              child: const Text('Cancel'),
              onPressed: () => Navigator.pop(ctx, false),
            ),
            CupertinoDialogAction(
              isDefaultAction: true,
              child: const Text('Enable'),
              onPressed: () => Navigator.pop(ctx, true),
            ),
          ],
        ),
      );

      if (confirmed != true) return;
      await _blastFeature.acknowledgeAndEnable();
      return;
    }

    await _blastFeature.setEnabled(true);
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
              _SectionHeader(label: 'Premium'),
              _SubscriptionSection(hasPro: _subscription.hasPro),
              const SizedBox(height: 24),
            ],
            const _SectionHeader(label: 'Appearance'),
            const _AppearanceSection(),
            const SizedBox(height: 24),
            const _SectionHeader(label: 'Experimental'),
            _ExperimentalBlastSection(
              parentContext: context,
              isEnabled: _blastFeature.isEnabled,
              onEnabledChanged: _onBlastToggleChanged,
            ),
          ],
        ),
      ),
    );
  }
}

class _SubscriptionSection extends StatelessWidget {
  const _SubscriptionSection({required this.hasPro});

  final bool hasPro;

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
                hasPro
                    ? CupertinoIcons.checkmark_seal_fill
                    : CupertinoIcons.lock,
                color: hasPro
                    ? const Color(0xFF0fa0ab)
                    : CupertinoColors.systemGrey,
                size: 18,
              ),
            ),
            title: const Text('Premium Active'),
            subtitle: const Text('You have full access to all features'),
          ),
        ],
      ),
    );
  }
}

class _AppearanceSection extends StatelessWidget {
  const _AppearanceSection();

  @override
  Widget build(BuildContext context) {
    final surfaces = context.surfaces;
    final appearance = AppearanceService.instance;

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: ListenableBuilder(
        listenable: appearance,
        builder: (context, _) =>
            CupertinoSlidingSegmentedControl<AppearanceMode>(
          groupValue: appearance.mode,
          backgroundColor: surfaces.fill,
          thumbColor: surfaces.raisedFill,
          padding: const EdgeInsets.all(3),
          children: {
            for (final mode in AppearanceMode.values)
              mode: Padding(
                padding: const EdgeInsets.symmetric(vertical: 8),
                child: Text(
                  mode.label,
                  style: AppText.subhead.copyWith(
                    color: surfaces.ink,
                    fontWeight: mode == appearance.mode
                        ? FontWeight.w600
                        : FontWeight.w400,
                  ),
                ),
              ),
          },
          onValueChanged: (mode) {
            if (mode != null) appearance.setMode(mode);
          },
        ),
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

class _ExperimentalBlastSection extends StatelessWidget {
  const _ExperimentalBlastSection({
    required this.parentContext,
    required this.isEnabled,
    required this.onEnabledChanged,
  });

  final BuildContext parentContext;
  final bool isEnabled;
  final Future<void> Function(bool) onEnabledChanged;

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16),
      decoration: BoxDecoration(
        color: const Color(0xFF1C1C1E),
        borderRadius: BorderRadius.circular(12),
      ),
      child: ShortcutService.isBlastDiagnosticsEnabled
          ? _DiagnosticShortcutSection(
              parentContext,
              isEnabled: isEnabled,
              onEnabledChanged: onEnabledChanged,
            )
          : _ShortcutSection(
              parentContext,
              isEnabled: isEnabled,
              onEnabledChanged: onEnabledChanged,
            ),
    );
  }
}

class _ShortcutSection extends StatelessWidget {
  const _ShortcutSection(
    this.parentContext, {
    required this.isEnabled,
    required this.onEnabledChanged,
  });

  final BuildContext parentContext;
  final bool isEnabled;
  final Future<void> Function(bool) onEnabledChanged;

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
    return Padding(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              Container(
                width: 44,
                height: 44,
                decoration: BoxDecoration(
                  color: isEnabled
                      ? const Color(0xFF0fa0ab)
                      : CupertinoColors.systemGrey.withOpacity(0.2),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Icon(
                  CupertinoIcons.bolt_fill,
                  color: isEnabled
                      ? CupertinoColors.white
                      : CupertinoColors.systemGrey,
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
              CupertinoSwitch(
                value: isEnabled,
                activeColor: const Color(0xFF0fa0ab),
                onChanged: onEnabledChanged,
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
          const SizedBox(height: 12),
          const Text(
            BlastFeatureService.experimentalDisclaimer,
            style: TextStyle(
              color: CupertinoColors.systemGrey,
              fontSize: 14,
              height: 1.4,
            ),
          ),
          if (isEnabled) ...[
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
        ],
      ),
    );
  }
}

class _DiagnosticShortcutSection extends StatelessWidget {
  const _DiagnosticShortcutSection(
    this.parentContext, {
    required this.isEnabled,
    required this.onEnabledChanged,
  });

  final BuildContext parentContext;
  final bool isEnabled;
  final Future<void> Function(bool) onEnabledChanged;

  void _onInstallTapped() {
    showCupertinoDialog(
      context: parentContext,
      builder: (ctx) => CupertinoAlertDialog(
        title: const Text('Install Diagnostic Blast'),
        content: const Text(
          'A share sheet will appear. Tap the Shortcuts icon to add the diagnostic shortcut to your library.',
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
              ShortcutService.openDiagnosticInstallPage();
            },
          ),
        ],
      ),
    );
  }

  void _showShareLogsHelp() {
    showCupertinoDialog(
      context: parentContext,
      builder: (ctx) => CupertinoAlertDialog(
        title: const Text('Share Logs'),
        content: Text(
          'After your blast:\n\n'
          '1. Open the Files app\n'
          '2. Search for ${DiagnosticConstants.diagnosticLogFileName}\n'
          '3. Long-press the file → Share → send to the developer\n\n'
          'The file is created automatically — no setup needed.\n\n'
          'If Shortcuts shows an error, screenshot it too.',
        ),
        actions: [
          CupertinoDialogAction(
            child: const Text('OK'),
            onPressed: () => Navigator.pop(ctx),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              Container(
                width: 44,
                height: 44,
                decoration: BoxDecoration(
                  color: CupertinoColors.systemOrange.withOpacity(0.2),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: const Icon(
                  CupertinoIcons.ant_fill,
                  color: CupertinoColors.systemOrange,
                  size: 22,
                ),
              ),
              const SizedBox(width: 12),
              const Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Diagnostic Blast (TestFlight)',
                      style: TextStyle(
                        color: CupertinoColors.white,
                        fontSize: 16,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    Text(
                      'Logging build',
                      style: TextStyle(
                        color: CupertinoColors.systemGrey,
                        fontSize: 13,
                      ),
                    ),
                  ],
                ),
              ),
              CupertinoSwitch(
                value: isEnabled,
                activeColor: const Color(0xFF0fa0ab),
                onChanged: onEnabledChanged,
              ),
            ],
          ),
          const SizedBox(height: 16),
          Text(
            'This build logs each send to ${DiagnosticConstants.diagnosticLogFileName} '
            '(created automatically in Files). After your blast, search for that file '
            'in the Files app and share it with us.',
            style: const TextStyle(
              color: CupertinoColors.systemGrey,
              fontSize: 14,
              height: 1.4,
            ),
          ),
          const SizedBox(height: 12),
          const Text(
            BlastFeatureService.experimentalDisclaimer,
            style: TextStyle(
              color: CupertinoColors.systemGrey,
              fontSize: 14,
              height: 1.4,
            ),
          ),
          if (isEnabled) ...[
            const SizedBox(height: 20),
            SizedBox(
              width: double.infinity,
              child: CupertinoButton(
                color: const Color(0xFF0fa0ab),
                borderRadius: BorderRadius.circular(10),
                onPressed: _onInstallTapped,
                child: const Text(
                  'Install Diagnostic Blast',
                  style: TextStyle(
                    fontWeight: FontWeight.w600,
                    color: CupertinoColors.white,
                  ),
                ),
              ),
            ),
            const SizedBox(height: 12),
            SizedBox(
              width: double.infinity,
              child: CupertinoButton(
                padding: const EdgeInsets.symmetric(vertical: 12),
                onPressed: _showShareLogsHelp,
                child: const Text(
                  'How to Share Logs',
                  style: TextStyle(
                    color: Color(0xFF0fa0ab),
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
            ),
          ],
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
      (
        icon: CupertinoIcons.arrow_right_circle,
        text: 'The Shortcuts app opens automatically'
      ),
      (
        icon: CupertinoIcons.checkmark_circle,
        text: 'Each contact gets an individual message — no tapping through'
      ),
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
