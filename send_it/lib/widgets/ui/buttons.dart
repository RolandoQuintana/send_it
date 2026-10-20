import 'package:flutter/cupertino.dart';

import '../../theme/app_surfaces.dart';
import '../../theme/app_text.dart';

/// Filled teal button for the one primary action on a screen.
class PrimaryButton extends StatelessWidget {
  const PrimaryButton({
    super.key,
    required this.label,
    required this.onPressed,
    this.icon,
    this.expand = false,
  });

  final String label;
  final VoidCallback? onPressed;
  final IconData? icon;

  /// Stretch to the available width.
  final bool expand;

  @override
  Widget build(BuildContext context) {
    final surfaces = context.surfaces;
    final enabled = onPressed != null;
    final foreground = enabled ? surfaces.onAccent : surfaces.faint;

    final button = CupertinoButton(
      onPressed: onPressed,
      padding: const EdgeInsets.symmetric(horizontal: 24),
      minimumSize: const Size(64, 50),
      color: enabled ? surfaces.accentFill : surfaces.fill,
      disabledColor: surfaces.fill,
      borderRadius: BorderRadius.circular(AppRadii.md),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          if (icon != null) ...[
            Icon(icon, size: 20, color: foreground),
            const SizedBox(width: 8),
          ],
          Text(label, style: AppText.headline.copyWith(color: foreground)),
        ],
      ),
    );

    return expand ? SizedBox(width: double.infinity, child: button) : button;
  }
}

/// Text-only teal button (secondary actions, nav bar actions).
class TextActionButton extends StatelessWidget {
  const TextActionButton({
    super.key,
    required this.label,
    required this.onPressed,
    this.bold = false,
  });

  final String label;
  final VoidCallback? onPressed;
  final bool bold;

  @override
  Widget build(BuildContext context) {
    final surfaces = context.surfaces;
    return CupertinoButton(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 8),
      minimumSize: const Size(44, 44),
      onPressed: onPressed,
      child: Text(
        label,
        style: AppText.body.copyWith(
          color: onPressed == null ? surfaces.faint : surfaces.accent,
          fontWeight: bold ? FontWeight.w600 : FontWeight.w400,
        ),
      ),
    );
  }
}

/// Icon-only nav bar button with a 44pt target.
class NavIconButton extends StatelessWidget {
  const NavIconButton({
    super.key,
    required this.icon,
    required this.onPressed,
    required this.semanticLabel,
    this.color,
  });

  final IconData icon;
  final VoidCallback? onPressed;
  final String semanticLabel;
  final Color? color;

  @override
  Widget build(BuildContext context) {
    return CupertinoButton(
      padding: EdgeInsets.zero,
      minimumSize: const Size(44, 44),
      onPressed: onPressed,
      child: Icon(
        icon,
        color: color ?? context.surfaces.accent,
        semanticLabel: semanticLabel,
      ),
    );
  }
}
