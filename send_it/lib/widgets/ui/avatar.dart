import 'package:flutter/cupertino.dart';

import '../../theme/app_surfaces.dart';
import '../../theme/app_text.dart';

/// Initial in a teal-wash circle, for contacts and groups.
class InitialAvatar extends StatelessWidget {
  const InitialAvatar(this.name, {super.key, this.size = 40});

  final String name;
  final double size;

  /// First visible character, or `?` for blank names (contacts with no
  /// display name used to crash `name[0]`).
  static String initialOf(String name) {
    final trimmed = name.trim();
    if (trimmed.isEmpty) return '?';
    return trimmed.characters.first.toUpperCase();
  }

  @override
  Widget build(BuildContext context) {
    final surfaces = context.surfaces;
    return Container(
      width: size,
      height: size,
      alignment: Alignment.center,
      decoration: BoxDecoration(
        color: surfaces.accentSoft,
        shape: BoxShape.circle,
      ),
      // The initial is a glyph sized to its circle, like an icon, so it
      // doesn't follow Dynamic Type (the name next to it does).
      child: Text(
        initialOf(name),
        textScaler: TextScaler.noScaling,
        style: AppText.headline.copyWith(
          color: surfaces.accent,
          fontSize: size * 0.42,
        ),
      ),
    );
  }
}
