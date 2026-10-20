import 'package:flutter/cupertino.dart';

import '../../theme/app_surfaces.dart';
import '../../theme/app_text.dart';
import '../../widgets/ui/avatar.dart';
import '../../widgets/ui/buttons.dart';

/// What happened to one recipient in a batch.
enum SendOutcome {
  /// The compose sheet reported "sent".
  sent,

  /// Cancelled in the compose sheet, or never reached after "Stop".
  skipped,

  /// No phone number, or the platform call failed.
  failed,
}

typedef RecipientResult = ({String name, SendOutcome outcome});

/// Results of one send loop, in recipient order.
class SendSummary {
  const SendSummary(this.results);

  final List<RecipientResult> results;

  int count(SendOutcome outcome) =>
      results.where((r) => r.outcome == outcome).length;

  int get sentCount => count(SendOutcome.sent);
  int get skippedCount => count(SendOutcome.skipped);
  int get failedCount => count(SendOutcome.failed);

  String get headline {
    final n = sentCount;
    return 'Sent to $n ${n == 1 ? 'person' : 'people'} 🎉';
  }
}

/// Shows the batch results. With [continueLabel] (the first send for a
/// non-Pro user) the sheet can't be swiped away: its one button leads on to
/// the paywall. Resolves when the sheet closes.
Future<void> showSendResults(
  BuildContext context, {
  required SendSummary summary,
  String? continueLabel,
}) {
  return showCupertinoModalPopup<void>(
    context: context,
    barrierDismissible: continueLabel == null,
    builder: (_) => SendResultsSheet(
      summary: summary,
      buttonLabel: continueLabel ?? 'Done',
      dismissible: continueLabel == null,
    ),
  );
}

class SendResultsSheet extends StatelessWidget {
  const SendResultsSheet({
    super.key,
    required this.summary,
    required this.buttonLabel,
    this.dismissible = true,
  });

  final SendSummary summary;
  final String buttonLabel;

  /// False when the button is the only way on (to the paywall).
  final bool dismissible;

  @override
  Widget build(BuildContext context) {
    final surfaces = context.surfaces;
    final notSent = [
      if (summary.skippedCount > 0) '${summary.skippedCount} skipped',
      if (summary.failedCount > 0) '${summary.failedCount} failed',
    ];

    return PopScope(
      canPop: dismissible,
      child: Container(
        constraints: BoxConstraints(
          maxHeight: MediaQuery.sizeOf(context).height * 0.85,
        ),
        decoration: BoxDecoration(
          color: surfaces.background,
          borderRadius: const BorderRadius.vertical(
            top: Radius.circular(AppRadii.lg),
          ),
        ),
        child: SafeArea(
          top: false,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Padding(
                padding: const EdgeInsets.fromLTRB(24, 28, 24, 4),
                child: Text(
                  summary.headline,
                  textAlign: TextAlign.center,
                  style: AppText.title2.copyWith(color: surfaces.ink),
                ),
              ),
              Padding(
                padding: const EdgeInsets.fromLTRB(24, 0, 24, 16),
                child: Text(
                  notSent.isEmpty
                      ? 'Everyone got their own text.'
                      : 'Each got their own text · ${notSent.join(' · ')}',
                  textAlign: TextAlign.center,
                  style: AppText.subhead.copyWith(color: surfaces.muted),
                ),
              ),
              Flexible(
                child: Container(
                  margin: const EdgeInsets.symmetric(horizontal: 16),
                  decoration: surfaces.cardDecoration(),
                  child: ListView.separated(
                    shrinkWrap: true,
                    padding: EdgeInsets.zero,
                    itemCount: summary.results.length,
                    separatorBuilder: (_, __) => Padding(
                      padding: const EdgeInsets.only(left: 64),
                      child: Container(height: 0.5, color: surfaces.hairline),
                    ),
                    itemBuilder: (context, index) =>
                        _ResultRow(result: summary.results[index]),
                  ),
                ),
              ),
              Padding(
                padding: const EdgeInsets.fromLTRB(16, 16, 16, 12),
                child: PrimaryButton(
                  label: buttonLabel,
                  expand: true,
                  onPressed: () => Navigator.pop(context),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _ResultRow extends StatelessWidget {
  const _ResultRow({required this.result});

  final RecipientResult result;

  @override
  Widget build(BuildContext context) {
    final surfaces = context.surfaces;
    final (icon, label, color) = switch (result.outcome) {
      SendOutcome.sent => (
          CupertinoIcons.checkmark_circle_fill,
          'Sent',
          surfaces.success,
        ),
      SendOutcome.skipped => (
          CupertinoIcons.minus_circle_fill,
          'Skipped',
          surfaces.muted,
        ),
      SendOutcome.failed => (
          CupertinoIcons.exclamationmark_circle_fill,
          'Failed',
          surfaces.danger,
        ),
    };

    return MergeSemantics(
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
        child: Row(
          children: [
            InitialAvatar(result.name, size: 36),
            const SizedBox(width: 12),
            Expanded(
              child: Text(
                result.name,
                style: AppText.body.copyWith(color: surfaces.ink),
              ),
            ),
            const SizedBox(width: 8),
            Icon(icon, size: 18, color: color),
            const SizedBox(width: 4),
            Text(
              label,
              style: AppText.footnote.copyWith(
                color: color,
                fontWeight: FontWeight.w600,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
