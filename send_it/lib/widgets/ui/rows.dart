import 'package:flutter/cupertino.dart';

import '../../theme/app_surfaces.dart';
import '../../theme/app_text.dart';
import 'avatar.dart';

/// Tappable row with a leading widget, title, optional subtitle and
/// trailing widget. Highlights while pressed.
class TappableRow extends StatefulWidget {
  const TappableRow({
    super.key,
    required this.title,
    this.subtitle,
    this.leading,
    this.trailing,
    this.onTap,
    this.semanticsSelected,
  });

  final String title;
  final String? subtitle;
  final Widget? leading;
  final Widget? trailing;
  final VoidCallback? onTap;

  /// Announced to VoiceOver when the row is a toggle.
  final bool? semanticsSelected;

  @override
  State<TappableRow> createState() => _TappableRowState();
}

class _TappableRowState extends State<TappableRow> {
  bool _pressed = false;

  void _setPressed(bool value) {
    if (widget.onTap == null || _pressed == value) return;
    setState(() => _pressed = value);
  }

  @override
  Widget build(BuildContext context) {
    final surfaces = context.surfaces;
    return Semantics(
      button: widget.onTap != null,
      selected: widget.semanticsSelected,
      child: GestureDetector(
        behavior: HitTestBehavior.opaque,
        onTap: widget.onTap,
        onTapDown: (_) => _setPressed(true),
        onTapUp: (_) => _setPressed(false),
        onTapCancel: () => _setPressed(false),
        child: Container(
          color: _pressed ? surfaces.fill : null,
          constraints: const BoxConstraints(minHeight: 60),
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
          child: Row(
            children: [
              if (widget.leading != null) ...[
                widget.leading!,
                const SizedBox(width: 12),
              ],
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      widget.title,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: AppText.body.copyWith(color: surfaces.ink),
                    ),
                    if (widget.subtitle != null &&
                        widget.subtitle!.isNotEmpty) ...[
                      const SizedBox(height: 2),
                      Text(
                        widget.subtitle!,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: AppText.footnote.copyWith(color: surfaces.muted),
                      ),
                    ],
                  ],
                ),
              ),
              if (widget.trailing != null) ...[
                const SizedBox(width: 12),
                widget.trailing!,
              ],
            ],
          ),
        ),
      ),
    );
  }
}

/// A contact you can include or exclude: avatar, name, detail and a
/// check. Tapping anywhere on the row toggles it.
class SelectableContactRow extends StatelessWidget {
  const SelectableContactRow({
    super.key,
    required this.name,
    required this.selected,
    required this.onChanged,
    this.detail,
    this.badge,
  });

  final String name;
  final String? detail;
  final bool selected;
  final ValueChanged<bool> onChanged;

  /// Small pill before the check (e.g. which field a search matched).
  final String? badge;

  @override
  Widget build(BuildContext context) {
    return TappableRow(
      title: name.trim().isEmpty ? 'No name' : name,
      subtitle: detail,
      leading: InitialAvatar(name),
      semanticsSelected: selected,
      onTap: () => onChanged(!selected),
      trailing: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          if (badge != null && badge!.isNotEmpty) ...[
            SoftPill(badge!),
            const SizedBox(width: 10),
          ],
          SelectionCheck(selected: selected),
        ],
      ),
    );
  }
}

/// Round check: teal-filled with a tick when on, a hairline ring when off.
class SelectionCheck extends StatelessWidget {
  const SelectionCheck({super.key, required this.selected, this.size = 24});

  final bool selected;
  final double size;

  @override
  Widget build(BuildContext context) {
    final surfaces = context.surfaces;
    return AnimatedContainer(
      duration: const Duration(milliseconds: 150),
      width: size,
      height: size,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        color: selected ? surfaces.accentFill : null,
        border: selected ? null : Border.all(color: surfaces.faint, width: 1.5),
      ),
      child: selected
          ? Icon(
              CupertinoIcons.checkmark,
              size: size * 0.6,
              color: surfaces.onAccent,
            )
          : null,
    );
  }
}

/// Small rounded label on the teal wash.
class SoftPill extends StatelessWidget {
  const SoftPill(this.label, {super.key});

  final String label;

  @override
  Widget build(BuildContext context) {
    final surfaces = context.surfaces;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
      decoration: ShapeDecoration(
        color: surfaces.accentSoft,
        shape: const StadiumBorder(),
      ),
      child: Text(
        label,
        style: AppText.caption.copyWith(
          color: surfaces.accent,
          fontWeight: FontWeight.w600,
        ),
      ),
    );
  }
}

/// Rounded-square icon badge used at the start of settings rows.
class IconTile extends StatelessWidget {
  const IconTile({
    super.key,
    required this.icon,
    required this.color,
    required this.background,
    this.size = 36,
  });

  final IconData icon;
  final Color color;
  final Color background;
  final double size;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: size,
      height: size,
      decoration: ShapeDecoration(
        color: background,
        shape: RoundedSuperellipseBorder(
          borderRadius: BorderRadius.circular(AppRadii.sm),
        ),
      ),
      child: Icon(icon, color: color, size: size * 0.55),
    );
  }
}
