import 'dart:io';

import 'package:flutter/cupertino.dart';
import 'package:flutter_contacts/flutter_contacts.dart';

import '../../services/haptics.dart';
import '../../services/shortcut_service.dart';
import '../../theme/app_surfaces.dart';
import '../../theme/app_text.dart';

/// Bottom composer: attached media, the tray toggle, the message field and
/// the send button with its recipient count.
class MessageComposer extends StatelessWidget {
  const MessageComposer({
    super.key,
    required this.controller,
    required this.focusNode,
    required this.trayOpen,
    required this.onToggleTray,
    required this.media,
    required this.onRemoveMedia,
    required this.recipientCount,
    required this.onSend,
    this.accessory,
  });

  final TextEditingController controller;
  final FocusNode focusNode;
  final bool trayOpen;
  final VoidCallback onToggleTray;
  final List<File> media;
  final ValueChanged<int> onRemoveMedia;
  final int recipientCount;

  /// Null while there's nothing to send.
  final VoidCallback? onSend;

  /// Shown above the field (the [PersonalizationBar]).
  final Widget? accessory;

  @override
  Widget build(BuildContext context) {
    final surfaces = context.surfaces;
    return Container(
      padding: const EdgeInsets.fromLTRB(8, 10, 12, 10),
      decoration: BoxDecoration(
        color: surfaces.card,
        border: Border(top: BorderSide(color: surfaces.hairline, width: 0.5)),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          if (accessory != null) accessory!,
          if (media.isNotEmpty)
            SizedBox(
              height: 92,
              child: ListView.separated(
                scrollDirection: Axis.horizontal,
                padding: const EdgeInsets.fromLTRB(4, 0, 4, 10),
                itemCount: media.length,
                separatorBuilder: (_, __) => const SizedBox(width: 8),
                itemBuilder: (context, index) => _MediaThumb(
                  file: media[index],
                  onRemove: () => onRemoveMedia(index),
                ),
              ),
            ),
          Row(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              _RoundIconButton(
                icon: trayOpen ? CupertinoIcons.xmark : CupertinoIcons.add,
                semanticLabel: trayOpen ? 'Close tools' : 'Open tools',
                background: trayOpen ? surfaces.accentSoft : surfaces.fill,
                color: trayOpen ? surfaces.accent : surfaces.muted,
                onPressed: onToggleTray,
              ),
              const SizedBox(width: 8),
              Expanded(
                child: CupertinoTextField(
                  controller: controller,
                  focusNode: focusNode,
                  placeholder: 'Hi {firstname}, …',
                  minLines: 1,
                  maxLines: 5,
                  textInputAction: TextInputAction.newline,
                  textCapitalization: TextCapitalization.sentences,
                  padding: const EdgeInsets.symmetric(
                    horizontal: 14,
                    vertical: 10,
                  ),
                  style: AppText.body.copyWith(color: surfaces.ink),
                  placeholderStyle: AppText.body.copyWith(
                    color: surfaces.faint,
                  ),
                  decoration: BoxDecoration(
                    color: surfaces.fill,
                    borderRadius: BorderRadius.circular(20),
                  ),
                ),
              ),
              const SizedBox(width: 8),
              _SendButton(count: recipientCount, onPressed: onSend),
            ],
          ),
        ],
      ),
    );
  }
}

class _MediaThumb extends StatelessWidget {
  const _MediaThumb({required this.file, required this.onRemove});

  final File file;
  final VoidCallback onRemove;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: 82,
      height: 82,
      child: Stack(
        children: [
          ClipRSuperellipse(
            borderRadius: BorderRadius.circular(AppRadii.md),
            child: Image.file(file, width: 82, height: 82, fit: BoxFit.cover),
          ),
          Positioned(
            top: 4,
            right: 4,
            child: Semantics(
              button: true,
              label: 'Remove attachment',
              child: GestureDetector(
                onTap: () {
                  Haptics.primary();
                  onRemove();
                },
                child: Container(
                  padding: const EdgeInsets.all(4),
                  // Scrim over a photo, so fixed rather than themed.
                  decoration: const BoxDecoration(
                    color: Color(0x99000000),
                    shape: BoxShape.circle,
                  ),
                  child: const Icon(
                    CupertinoIcons.xmark,
                    color: Color(0xFFFFFFFF),
                    size: 14,
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _RoundIconButton extends StatelessWidget {
  const _RoundIconButton({
    required this.icon,
    required this.semanticLabel,
    required this.background,
    required this.color,
    required this.onPressed,
  });

  final IconData icon;
  final String semanticLabel;
  final Color background;
  final Color color;
  final VoidCallback onPressed;

  @override
  Widget build(BuildContext context) {
    return CupertinoButton(
      padding: EdgeInsets.zero,
      minimumSize: const Size(44, 44),
      onPressed: () {
        Haptics.selection();
        onPressed();
      },
      child: Container(
        width: 38,
        height: 38,
        decoration: BoxDecoration(color: background, shape: BoxShape.circle),
        child: Icon(icon, size: 20, color: color, semanticLabel: semanticLabel),
      ),
    );
  }
}

/// Paper plane in a teal circle, with how many people will get it.
class _SendButton extends StatelessWidget {
  const _SendButton({required this.count, required this.onPressed});

  final int count;
  final VoidCallback? onPressed;

  @override
  Widget build(BuildContext context) {
    final surfaces = context.surfaces;
    final enabled = onPressed != null;
    return Semantics(
      button: true,
      enabled: enabled,
      label: 'Send to $count ${count == 1 ? 'person' : 'people'}',
      child: CupertinoButton(
        padding: EdgeInsets.zero,
        minimumSize: const Size(44, 44),
        onPressed: enabled
            ? () {
                Haptics.primary();
                onPressed!();
              }
            : null,
        child: SizedBox(
          width: 44,
          height: 44,
          child: Stack(
            clipBehavior: Clip.none,
            children: [
              Positioned(
                left: 3,
                top: 3,
                child: Container(
                  width: 38,
                  height: 38,
                  decoration: BoxDecoration(
                    color: enabled ? surfaces.accentFill : surfaces.fill,
                    shape: BoxShape.circle,
                  ),
                  child: Icon(
                    CupertinoIcons.paperplane_fill,
                    size: 18,
                    color: enabled ? surfaces.onAccent : surfaces.faint,
                  ),
                ),
              ),
              if (count > 0)
                Positioned(
                  right: -4,
                  top: -6,
                  child: ExcludeSemantics(
                    child: Container(
                      constraints:
                          const BoxConstraints(minWidth: 20, minHeight: 20),
                      padding: const EdgeInsets.symmetric(horizontal: 5),
                      alignment: Alignment.center,
                      decoration: ShapeDecoration(
                        color: surfaces.ink,
                        shape: StadiumBorder(
                          side: BorderSide(color: surfaces.card, width: 2),
                        ),
                      ),
                      child: Text(
                        '$count',
                        // Capped so the badge can't cover the button; the
                        // count is also in the button's semantics label.
                        textScaler: MediaQuery.textScalerOf(context)
                            .clamp(maxScaleFactor: 1.3),
                        style: AppText.caption.copyWith(
                          color: surfaces.card,
                          fontWeight: FontWeight.w700,
                          height: 1.2,
                        ),
                      ),
                    ),
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }
}

/// Tools under the composer: Gallery, Variables and (when enabled) Blast.
class ActionTray extends StatelessWidget {
  const ActionTray({
    super.key,
    required this.blastEnabled,
    required this.onGallery,
    required this.onVariables,
    required this.onBlast,
  });

  final bool blastEnabled;
  final VoidCallback onGallery;
  final VoidCallback onVariables;
  final VoidCallback onBlast;

  @override
  Widget build(BuildContext context) {
    final surfaces = context.surfaces;
    return Container(
      color: surfaces.card,
      padding: const EdgeInsets.fromLTRB(20, 6, 20, 18),
      child: Row(
        children: [
          _TrayAction(
            icon: CupertinoIcons.photo_fill,
            label: 'Gallery',
            onTap: onGallery,
          ),
          const SizedBox(width: 20),
          _TrayAction(
            icon: CupertinoIcons.textformat_abc,
            label: 'Variables',
            onTap: onVariables,
          ),
          if (blastEnabled) ...[
            const SizedBox(width: 20),
            _TrayAction(
              icon: CupertinoIcons.bolt_fill,
              label: 'Blast',
              onTap: onBlast,
            ),
          ],
        ],
      ),
    );
  }
}

class _TrayAction extends StatelessWidget {
  const _TrayAction({
    required this.icon,
    required this.label,
    required this.onTap,
  });

  final IconData icon;
  final String label;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final surfaces = context.surfaces;
    return Semantics(
      button: true,
      label: label,
      child: GestureDetector(
        behavior: HitTestBehavior.opaque,
        onTap: () {
          Haptics.primary();
          onTap();
        },
        child: ExcludeSemantics(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                width: 56,
                height: 56,
                decoration: ShapeDecoration(
                  color: surfaces.accentSoft,
                  shape: RoundedSuperellipseBorder(
                    borderRadius: BorderRadius.circular(AppRadii.md),
                  ),
                ),
                child: Icon(icon, color: surfaces.accent, size: 24),
              ),
              const SizedBox(height: 6),
              Text(
                label,
                style: AppText.footnote.copyWith(
                  color: surfaces.ink,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

/// Variables you can drop into the message; stays open so you can add
/// several.
class VariablesPanel extends StatelessWidget {
  const VariablesPanel({
    super.key,
    required this.onBack,
    required this.onInsert,
  });

  final VoidCallback onBack;
  final ValueChanged<String> onInsert;

  static const _variables = [
    (variable: '{firstname}', description: 'First name', example: 'John'),
  ];

  @override
  Widget build(BuildContext context) {
    final surfaces = context.surfaces;
    return ConstrainedBox(
      constraints: const BoxConstraints(maxHeight: 240),
      child: Container(
        color: surfaces.card,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(4, 0, 16, 0),
              child: Row(
                children: [
                  CupertinoButton(
                    padding: EdgeInsets.zero,
                    minimumSize: const Size(44, 44),
                    onPressed: () {
                      Haptics.selection();
                      onBack();
                    },
                    child: Icon(
                      CupertinoIcons.chevron_back,
                      size: 20,
                      color: surfaces.accent,
                      semanticLabel: 'Back to tools',
                    ),
                  ),
                  Text(
                    'Variables',
                    style: AppText.headline.copyWith(color: surfaces.ink),
                  ),
                  const Spacer(),
                  Text(
                    'Tap to insert',
                    style: AppText.footnote.copyWith(color: surfaces.muted),
                  ),
                ],
              ),
            ),
            Flexible(
              child: ListView(
                shrinkWrap: true,
                padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
                children: [
                  for (final v in _variables)
                    _VariableItem(
                      variable: v.variable,
                      description: v.description,
                      example: v.example,
                      onTap: () => onInsert(v.variable),
                    ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _VariableItem extends StatelessWidget {
  const _VariableItem({
    required this.variable,
    required this.description,
    required this.example,
    required this.onTap,
  });

  final String variable;
  final String description;
  final String example;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final surfaces = context.surfaces;
    return Semantics(
      button: true,
      label: 'Insert $description',
      child: GestureDetector(
        onTap: () {
          Haptics.selection();
          onTap();
        },
        child: Container(
          margin: const EdgeInsets.only(bottom: 8),
          padding: const EdgeInsets.all(12),
          decoration: ShapeDecoration(
            color: surfaces.fill,
            shape: RoundedSuperellipseBorder(
              borderRadius: BorderRadius.circular(AppRadii.md),
            ),
          ),
          child: ExcludeSemantics(
            child: Row(
              children: [
                Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                  decoration: ShapeDecoration(
                    color: surfaces.accentSoft,
                    shape: RoundedSuperellipseBorder(
                      borderRadius: BorderRadius.circular(6),
                    ),
                  ),
                  child: Text(
                    variable,
                    style: AppText.footnote.copyWith(
                      color: surfaces.accent,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        description,
                        style: AppText.subhead.copyWith(
                          color: surfaces.ink,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                      Text(
                        'e.g. $example',
                        style: AppText.footnote.copyWith(
                          color: surfaces.muted,
                        ),
                      ),
                    ],
                  ),
                ),
                Icon(
                  CupertinoIcons.plus_circle_fill,
                  color: surfaces.accent,
                  size: 22,
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

/// Above the field: with `{firstname}` in the message, a live preview of
/// what the first recipient gets (tap for everyone's); without it, a
/// one-tap chip that inserts it.
class PersonalizationBar extends StatelessWidget {
  const PersonalizationBar({
    super.key,
    required this.message,
    required this.recipients,
    required this.onInsertFirstName,
  });

  final String message;

  /// Selected recipients, in list order.
  final List<Contact> recipients;
  final VoidCallback onInsertFirstName;

  static const _token = '{firstname}';

  @override
  Widget build(BuildContext context) {
    final surfaces = context.surfaces;

    // Without the token everyone gets the same text, so there's nothing
    // to preview; offer the chip instead.
    if (!message.contains(_token) || recipients.isEmpty) {
      return Padding(
        padding: const EdgeInsets.fromLTRB(4, 0, 4, 8),
        child: Row(
          children: [
            Semantics(
              button: true,
              label: 'Insert first name',
              child: GestureDetector(
                onTap: () {
                  Haptics.selection();
                  onInsertFirstName();
                },
                child: ExcludeSemantics(
                  child: Container(
                    constraints: const BoxConstraints(minHeight: 32),
                    padding: const EdgeInsets.symmetric(
                      horizontal: 10,
                      vertical: 6,
                    ),
                    decoration: ShapeDecoration(
                      color: surfaces.accentSoft,
                      shape: const StadiumBorder(),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(
                          CupertinoIcons.add,
                          size: 14,
                          color: surfaces.accent,
                        ),
                        const SizedBox(width: 4),
                        Text(
                          'First name',
                          style: AppText.footnote.copyWith(
                            color: surfaces.accent,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ),
            const SizedBox(width: 10),
            Expanded(
              child: Text(
                "Add each person's name",
                style: AppText.footnote.copyWith(color: surfaces.muted),
              ),
            ),
          ],
        ),
      );
    }

    final first = recipients.first;
    final preview = ShortcutService.personalizeMessage(message, first);
    final name = first.displayName.trim().split(' ').first;

    return Semantics(
      button: true,
      label: '$name will get: $preview. Show every message',
      child: GestureDetector(
        behavior: HitTestBehavior.opaque,
        onTap: () {
          Haptics.selection();
          showPersonalizedPreviews(
            context,
            message: message,
            recipients: recipients,
          );
        },
        child: ExcludeSemantics(
          child: Padding(
            padding: const EdgeInsets.fromLTRB(8, 0, 4, 8),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Expanded(
                  child: Text.rich(
                    TextSpan(
                      children: [
                        TextSpan(
                          text: '$name will get: ',
                          style: TextStyle(
                            color: surfaces.ink,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                        TextSpan(text: preview),
                      ],
                    ),
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                    style: AppText.footnote.copyWith(color: surfaces.muted),
                  ),
                ),
                const SizedBox(width: 8),
                Text(
                  recipients.length > 1 ? 'See all' : 'Preview',
                  style: AppText.footnote.copyWith(
                    color: surfaces.accent,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

/// Every recipient's rendered message, before sending.
Future<void> showPersonalizedPreviews(
  BuildContext context, {
  required String message,
  required List<Contact> recipients,
}) {
  return showCupertinoModalPopup<void>(
    context: context,
    builder: (context) {
      final surfaces = context.surfaces;
      return Container(
        constraints: BoxConstraints(
          maxHeight: MediaQuery.sizeOf(context).height * 0.75,
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
                padding: const EdgeInsets.fromLTRB(20, 20, 8, 8),
                child: Row(
                  children: [
                    Expanded(
                      child: Text(
                        'What each person gets',
                        style: AppText.headline.copyWith(color: surfaces.ink),
                      ),
                    ),
                    CupertinoButton(
                      padding: const EdgeInsets.symmetric(horizontal: 12),
                      minimumSize: const Size(44, 44),
                      onPressed: () => Navigator.pop(context),
                      child: Text(
                        'Done',
                        style: AppText.body.copyWith(
                          color: surfaces.accent,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              Flexible(
                child: ListView.separated(
                  shrinkWrap: true,
                  padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
                  itemCount: recipients.length,
                  separatorBuilder: (_, __) => const SizedBox(height: 12),
                  itemBuilder: (context, index) {
                    final contact = recipients[index];
                    return Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Padding(
                          padding: const EdgeInsets.only(left: 4, bottom: 4),
                          child: Text(
                            contact.displayName,
                            style: AppText.footnote.copyWith(
                              color: surfaces.muted,
                            ),
                          ),
                        ),
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 14,
                            vertical: 10,
                          ),
                          decoration: BoxDecoration(
                            color: surfaces.accentFill,
                            borderRadius: BorderRadius.circular(18),
                          ),
                          child: Text(
                            ShortcutService.personalizeMessage(
                              message,
                              contact,
                            ),
                            style: AppText.body.copyWith(
                              color: surfaces.onAccent,
                            ),
                          ),
                        ),
                      ],
                    );
                  },
                ),
              ),
            ],
          ),
        ),
      );
    },
  );
}
