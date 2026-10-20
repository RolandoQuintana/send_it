import 'package:flutter/cupertino.dart';

import 'app_colors.dart';

/// Corner radii. Use with [RoundedSuperellipseBorder] for iOS-style
/// continuous corners.
abstract final class AppRadii {
  static const double sm = 10;
  static const double md = 14;
  static const double lg = 22;
  static const double xl = 28;
}

/// Theme-aware tokens for everything the app draws. Read via
/// `context.surfaces`, which picks [light] or [dark] from the current
/// Cupertino brightness.
@immutable
class AppSurfaces {
  const AppSurfaces({
    required this.brightness,
    required this.background,
    required this.card,
    required this.raisedFill,
    required this.fill,
    required this.hairline,
    required this.cardEdge,
    required this.ink,
    required this.muted,
    required this.faint,
    required this.brand,
    required this.accent,
    required this.accentFill,
    required this.onAccent,
    required this.accentSoft,
    required this.shadowColor,
    required this.success,
    required this.successSoft,
    required this.warning,
    required this.warningSoft,
    required this.danger,
    required this.dangerSoft,
    required this.dangerBorder,
  });

  final Brightness brightness;

  /// Page shell behind everything.
  final Color background;

  /// Cards, grouped sections, sheets.
  final Color card;

  /// Surface that sits above [card] (segmented thumbs, popovers).
  final Color raisedFill;

  /// Quiet fill for inputs, tracks, chips and inset wells.
  final Color fill;
  final Color hairline;

  /// Rim drawn around cards; carries depth in dark where shadows vanish.
  final Color cardEdge;

  final Color ink;
  final Color muted;

  /// Tertiary text and inactive glyphs only (about 3:1).
  final Color faint;

  /// Brand teal, unchanged across themes: avatars, icon-like glyphs and
  /// large fills. Not for small text.
  final Color brand;

  /// Teal for text, links and selected glyphs.
  final Color accent;

  /// Background of filled controls (buttons, FAB, switch track); [onAccent]
  /// sits on it.
  final Color accentFill;
  final Color onAccent;

  /// Pale teal wash for selected rows, chips and pills.
  final Color accentSoft;
  final Color shadowColor;

  final Color success;
  final Color successSoft;
  final Color warning;
  final Color warningSoft;
  final Color danger;
  final Color dangerSoft;
  final Color dangerBorder;

  bool get isDark => brightness == Brightness.dark;

  static const light = AppSurfaces(
    brightness: Brightness.light,
    background: AppColors.shell,
    card: AppColors.panel,
    raisedFill: AppColors.panel,
    fill: AppColors.fill,
    hairline: AppColors.border,
    cardEdge: Color(0x00000000),
    ink: AppColors.ink,
    muted: AppColors.muted,
    faint: AppColors.faint,
    brand: AppColors.brand,
    accent: AppColors.tealDeep,
    accentFill: AppColors.tealDeep,
    onAccent: AppColors.onTeal,
    accentSoft: AppColors.tealSoft,
    shadowColor: AppColors.shadow,
    success: AppColors.success,
    successSoft: AppColors.successSoft,
    warning: AppColors.warning,
    warningSoft: AppColors.warningSoft,
    danger: AppColors.danger,
    dangerSoft: AppColors.dangerSoft,
    dangerBorder: AppColors.dangerBorder,
  );

  static const dark = AppSurfaces(
    brightness: Brightness.dark,
    background: AppColors.dShell,
    card: AppColors.dPanel,
    raisedFill: AppColors.dRaised,
    fill: AppColors.dFill,
    hairline: AppColors.dBorder,
    cardEdge: AppColors.dEdge,
    ink: AppColors.dInk,
    muted: AppColors.dMuted,
    faint: AppColors.dFaint,
    brand: AppColors.brand,
    accent: AppColors.tealOnDark,
    accentFill: AppColors.tealDarkFill,
    onAccent: AppColors.onTeal,
    accentSoft: AppColors.tealDarkSoft,
    shadowColor: Color(0xFF000000),
    success: AppColors.dSuccess,
    successSoft: AppColors.dSuccessSoft,
    warning: AppColors.dWarning,
    warningSoft: AppColors.dWarningSoft,
    danger: AppColors.dDanger,
    dangerSoft: AppColors.dDangerSoft,
    dangerBorder: AppColors.dDangerBorder,
  );

  static AppSurfaces of(Brightness brightness) =>
      brightness == Brightness.dark ? dark : light;

  /// Resting depth for cards and tiles: a tight contact shadow plus a soft,
  /// wide ambient one.
  List<BoxShadow> get raised => [
        BoxShadow(
          color: shadowColor.withValues(alpha: 0.05),
          blurRadius: 2,
          offset: const Offset(0, 1),
        ),
        BoxShadow(
          color: shadowColor.withValues(alpha: 0.07),
          blurRadius: 24,
          offset: const Offset(0, 8),
        ),
      ];

  /// Depth for chrome that floats over content (FAB, composer, overlays).
  List<BoxShadow> get floating => [
        BoxShadow(
          color: shadowColor.withValues(alpha: 0.06),
          blurRadius: 3,
          offset: const Offset(0, 1),
        ),
        BoxShadow(
          color: shadowColor.withValues(alpha: 0.12),
          blurRadius: 40,
          offset: const Offset(0, 14),
        ),
      ];

  /// Continuous-corner card with resting depth.
  ShapeDecoration cardDecoration({
    double radius = AppRadii.lg,
    Color? color,
  }) {
    return ShapeDecoration(
      color: color ?? card,
      shape: RoundedSuperellipseBorder(
        borderRadius: BorderRadius.circular(radius),
        side: BorderSide(color: cardEdge, width: 0.5),
      ),
      shadows: raised,
    );
  }
}

extension AppSurfacesContext on BuildContext {
  /// Tokens for the current brightness (the app's theme, or the platform's
  /// when the theme follows the system).
  AppSurfaces get surfaces =>
      AppSurfaces.of(CupertinoTheme.brightnessOf(this));
}
