import 'package:flutter/cupertino.dart';

import '../constants/diagnostic_constants.dart';
import '../services/appearance_service.dart';
import '../services/blast_feature_service.dart';
import '../services/subscription_service.dart';
import '../services/shortcut_service.dart';
import '../theme/app_surfaces.dart';
import '../theme/app_text.dart';
import '../widgets/ui/buttons.dart';
import '../widgets/ui/dialogs.dart';
import '../widgets/ui/grouped_section.dart';
import '../widgets/ui/rows.dart';
import '../widgets/ui/section_header.dart';

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
      final confirmed = await showConfirm(
        context,
        title: 'Experimental Feature',
        message: BlastFeatureService.experimentalDisclaimer,
        confirm: 'Enable',
      );

      if (!confirmed) return;
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
          padding: const EdgeInsets.only(top: 24, bottom: 40),
          children: [
            if (showSubscriptionSection) ...[
              const SectionHeader('Premium'),
              _SubscriptionSection(hasPro: _subscription.hasPro),
              const SizedBox(height: 28),
            ],
            const SectionHeader('Appearance'),
            const _AppearanceSection(),
            const SizedBox(height: 28),
            const SectionHeader('Experimental'),
            GroupedSection(
              children: [
                ShortcutService.isBlastDiagnosticsEnabled
                    ? _DiagnosticShortcutSection(
                        parentContext: context,
                        isEnabled: _blastFeature.isEnabled,
                        onEnabledChanged: _onBlastToggleChanged,
                      )
                    : _ShortcutSection(
                        parentContext: context,
                        isEnabled: _blastFeature.isEnabled,
                        onEnabledChanged: _onBlastToggleChanged,
                      ),
              ],
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
    final surfaces = context.surfaces;
    return GroupedSection(
      children: [
        TappableRow(
          title: 'Premium Active',
          subtitle: 'You have full access to all features',
          leading: IconTile(
            icon: hasPro
                ? CupertinoIcons.checkmark_seal_fill
                : CupertinoIcons.lock,
            color: hasPro ? surfaces.accent : surfaces.muted,
            background: hasPro ? surfaces.accentSoft : surfaces.fill,
          ),
        ),
      ],
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

/// Header row shared by the Blast and Diagnostic Blast cards: icon,
/// title, subtitle and the on/off switch.
class _BlastHeader extends StatelessWidget {
  const _BlastHeader({
    required this.icon,
    required this.iconColor,
    required this.iconBackground,
    required this.title,
    required this.subtitle,
    required this.isEnabled,
    required this.onEnabledChanged,
  });

  final IconData icon;
  final Color iconColor;
  final Color iconBackground;
  final String title;
  final String subtitle;
  final bool isEnabled;
  final Future<void> Function(bool) onEnabledChanged;

  @override
  Widget build(BuildContext context) {
    final surfaces = context.surfaces;
    return Row(
      children: [
        IconTile(
          icon: icon,
          color: iconColor,
          background: iconBackground,
          size: 44,
        ),
        const SizedBox(width: 12),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(title,
                  style: AppText.headline.copyWith(color: surfaces.ink)),
              const SizedBox(height: 2),
              Text(
                subtitle,
                style: AppText.footnote.copyWith(color: surfaces.muted),
              ),
            ],
          ),
        ),
        CupertinoSwitch(
          value: isEnabled,
          activeTrackColor: surfaces.accentFill,
          onChanged: onEnabledChanged,
        ),
      ],
    );
  }
}

/// The experimental warning, set apart on the warning wash.
class _ExperimentalNote extends StatelessWidget {
  const _ExperimentalNote();

  @override
  Widget build(BuildContext context) {
    final surfaces = context.surfaces;
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: ShapeDecoration(
        color: surfaces.warningSoft,
        shape: RoundedSuperellipseBorder(
          borderRadius: BorderRadius.circular(AppRadii.sm),
        ),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.only(top: 1),
            child: Icon(
              CupertinoIcons.exclamationmark_triangle_fill,
              size: 16,
              color: surfaces.warning,
            ),
          ),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              BlastFeatureService.experimentalDisclaimer,
              style: AppText.footnote.copyWith(color: surfaces.warning),
            ),
          ),
        ],
      ),
    );
  }
}

class _ShortcutSection extends StatelessWidget {
  const _ShortcutSection({
    required this.parentContext,
    required this.isEnabled,
    required this.onEnabledChanged,
  });

  final BuildContext parentContext;
  final bool isEnabled;
  final Future<void> Function(bool) onEnabledChanged;

  Future<void> _onInstallTapped() async {
    final confirmed = await showConfirm(
      parentContext,
      title: 'Install Blast',
      message:
          'A share sheet will appear. Tap the Shortcuts icon to add Blast to your library.',
      confirm: 'Continue',
    );
    if (!confirmed) return;
    ShortcutService.markBlastInstalled();
    ShortcutService.openInstallPage();
  }

  @override
  Widget build(BuildContext context) {
    final surfaces = context.surfaces;
    return Padding(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _BlastHeader(
            icon: CupertinoIcons.bolt_fill,
            iconColor: isEnabled ? surfaces.onAccent : surfaces.muted,
            iconBackground: isEnabled ? surfaces.accentFill : surfaces.fill,
            title: 'Sent It Blast',
            subtitle: 'Apple Shortcut',
            isEnabled: isEnabled,
            onEnabledChanged: onEnabledChanged,
          ),
          const SizedBox(height: 16),
          Text(
            'Send individual messages to your entire group with a single tap — no confirm-per-person required.',
            style: AppText.subhead.copyWith(color: surfaces.muted),
          ),
          const SizedBox(height: 12),
          const _ExperimentalNote(),
          if (isEnabled) ...[
            const SizedBox(height: 20),
            const _HowItWorksList(),
            const SizedBox(height: 16),
            PrimaryButton(
              label: 'Install Shortcut',
              icon: CupertinoIcons.arrow_down_circle_fill,
              expand: true,
              onPressed: _onInstallTapped,
            ),
          ],
        ],
      ),
    );
  }
}

class _DiagnosticShortcutSection extends StatelessWidget {
  const _DiagnosticShortcutSection({
    required this.parentContext,
    required this.isEnabled,
    required this.onEnabledChanged,
  });

  final BuildContext parentContext;
  final bool isEnabled;
  final Future<void> Function(bool) onEnabledChanged;

  Future<void> _onInstallTapped() async {
    final confirmed = await showConfirm(
      parentContext,
      title: 'Install Diagnostic Blast',
      message:
          'A share sheet will appear. Tap the Shortcuts icon to add the diagnostic shortcut to your library.',
      confirm: 'Continue',
    );
    if (!confirmed) return;
    ShortcutService.markBlastInstalled();
    ShortcutService.openDiagnosticInstallPage();
  }

  void _showShareLogsHelp() {
    showNotice(
      parentContext,
      title: 'Share Logs',
      message: 'After your blast:\n\n'
          '1. Open the Files app\n'
          '2. Search for ${DiagnosticConstants.diagnosticLogFileName}\n'
          '3. Long-press the file → Share → send to the developer\n\n'
          'The file is created automatically — no setup needed.\n\n'
          'If Shortcuts shows an error, screenshot it too.',
    );
  }

  @override
  Widget build(BuildContext context) {
    final surfaces = context.surfaces;
    return Padding(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _BlastHeader(
            icon: CupertinoIcons.ant_fill,
            iconColor: surfaces.warning,
            iconBackground: surfaces.warningSoft,
            title: 'Diagnostic Blast (TestFlight)',
            subtitle: 'Logging build',
            isEnabled: isEnabled,
            onEnabledChanged: onEnabledChanged,
          ),
          const SizedBox(height: 16),
          Text(
            'This build logs each send to ${DiagnosticConstants.diagnosticLogFileName} '
            '(created automatically in Files). After your blast, search for that file '
            'in the Files app and share it with us.',
            style: AppText.subhead.copyWith(color: surfaces.muted),
          ),
          const SizedBox(height: 12),
          const _ExperimentalNote(),
          if (isEnabled) ...[
            const SizedBox(height: 20),
            PrimaryButton(
              label: 'Install Diagnostic Blast',
              expand: true,
              onPressed: _onInstallTapped,
            ),
            const SizedBox(height: 4),
            Center(
              child: TextActionButton(
                label: 'How to Share Logs',
                bold: true,
                onPressed: _showShareLogsHelp,
              ),
            ),
          ],
        ],
      ),
    );
  }
}

class _HowItWorksList extends StatelessWidget {
  const _HowItWorksList();

  static const _steps = [
    'Compose your message in Send It',
    'Tap "Blast" in the + menu',
    'The Shortcuts app opens automatically',
    'Each contact gets an individual message — no tapping through',
  ];

  @override
  Widget build(BuildContext context) {
    final surfaces = context.surfaces;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'How it works',
          style: AppText.subhead.copyWith(
            color: surfaces.ink,
            fontWeight: FontWeight.w600,
          ),
        ),
        const SizedBox(height: 10),
        for (var i = 0; i < _steps.length; i++)
          Padding(
            padding: const EdgeInsets.only(bottom: 10),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Container(
                  width: 24,
                  height: 24,
                  alignment: Alignment.center,
                  decoration: BoxDecoration(
                    color: surfaces.accentSoft,
                    shape: BoxShape.circle,
                  ),
                  child: Text(
                    '${i + 1}',
                    style: AppText.caption.copyWith(
                      color: surfaces.accent,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: Padding(
                    padding: const EdgeInsets.only(top: 2),
                    child: Text(
                      _steps[i],
                      style: AppText.subhead.copyWith(color: surfaces.ink),
                    ),
                  ),
                ),
              ],
            ),
          ),
      ],
    );
  }
}
