import 'package:flutter/cupertino.dart';

import 'app_surfaces.dart';
import 'app_text.dart';

/// Builds the app's [CupertinoThemeData].
///
/// Pass a [Brightness] to force light or dark; pass null to follow the
/// system. Colors are [CupertinoDynamicColor]s, so either way they resolve
/// to the matching [AppSurfaces] tokens.
abstract final class AppTheme {
  static CupertinoThemeData cupertino({Brightness? brightness}) {
    const l = AppSurfaces.light;
    const d = AppSurfaces.dark;

    final ink = CupertinoDynamicColor.withBrightness(
      color: l.ink,
      darkColor: d.ink,
    );
    final accent = CupertinoDynamicColor.withBrightness(
      color: l.accent,
      darkColor: d.accent,
    );

    return CupertinoThemeData(
      brightness: brightness,
      // Cupertino uses primaryColor both for tinted text and for
      // `CupertinoButton.filled`, so it gets the text-safe teal; its
      // contrasting color keeps filled-button labels at 4.5:1 or above.
      primaryColor: accent,
      primaryContrastingColor: CupertinoDynamicColor.withBrightness(
        color: l.onAccent,
        darkColor: d.background,
      ),
      scaffoldBackgroundColor: CupertinoDynamicColor.withBrightness(
        color: l.background,
        darkColor: d.background,
      ),
      // Slightly translucent so the nav bar blurs content beneath it.
      barBackgroundColor: CupertinoDynamicColor.withBrightness(
        color: l.background.withValues(alpha: 0.92),
        darkColor: d.background.withValues(alpha: 0.92),
      ),
      textTheme: CupertinoTextThemeData(
        primaryColor: accent,
        textStyle: AppText.body.copyWith(color: ink),
        actionTextStyle: AppText.body.copyWith(color: accent),
        navTitleTextStyle: AppText.headline.copyWith(color: ink),
        navLargeTitleTextStyle: AppText.largeTitle.copyWith(color: ink),
      ),
    );
  }
}
