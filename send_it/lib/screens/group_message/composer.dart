import 'dart:io';

import 'package:flutter/cupertino.dart';

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
                onTap: onRemove,
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
      onPressed: onPressed,
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
        onPressed: onPressed,
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
        onTap: onTap,
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
                    onPressed: onBack,
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
        onTap: onTap,
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
