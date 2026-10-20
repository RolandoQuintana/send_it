import 'package:flutter/cupertino.dart';

/// Raw palette. Widgets should read [AppSurfaces] via `context.surfaces`
/// so they follow light and dark; reach for these only when building
/// tokens.
///
/// Neutrals are Scroll Less's warm palette. Contrast ratios (WCAG) are
/// noted against the surface each color is meant to sit on and are
/// asserted in `test/theme/contrast_test.dart`.
abstract final class AppColors {
  // Brand teal. The identity color (icon, avatars, large glyphs). White on
  // it is 3.1:1: fine for icons and large text, too weak for small labels,
  // so filled controls and teal text use [tealDeep] / [tealOnDark].
  static const Color brand = Color(0xFF0FA0AB);

  // Light teal tones. [tealDeep] carries white at 5.7:1 and reads as text
  // on shell 4.9:1, panel 5.7:1, fill 4.8:1.
  static const Color tealDeep = Color(0xFF087079);
  static const Color tealSoft = Color(0xFFDCEEEE);

  // Dark teal tones. [tealOnDark] is for text and glyphs (shell 9.8:1,
  // panel 8.2:1); [tealDarkFill] is deep so buttons don't glow (white
  // 5.1:1); [tealDarkSoft] is the wash behind teal text (7.2:1).
  static const Color tealOnDark = Color(0xFF6FCBD2);
  static const Color tealDarkFill = Color(0xFF0D7880);
  static const Color tealDarkSoft = Color(0xFF1E3133);

  static const Color onTeal = Color(0xFFFDFCFA);

  // Warm neutrals (light). Ink on panel 14.7:1, muted on panel 5.6:1 and
  // on shell 4.9:1. Faint is a step darker than Scroll Less's so it holds
  // 3:1 on shell, panel and fill; still tertiary and disabled only.
  static const Color shell = Color(0xFFF2EBE3);
  static const Color panel = Color(0xFFFFFCF8);
  static const Color fill = Color(0xFFEFE7DE);
  static const Color border = Color(0xFFE0D6CB);
  static const Color n300 = Color(0xFFD0C4B6);
  static const Color faint = Color(0xFF8A837B);
  static const Color muted = Color(0xFF6B6560);
  static const Color ink = Color(0xFF2A2622);

  /// Warm brown used at low alpha for every light-mode shadow, so depth
  /// never looks grey on the warm neutrals.
  static const Color shadow = Color(0xFF3B2A1A);

  // Warm charcoal (dark), never pure black. Depth comes from lightness:
  // shell → panel → raised each step lighter. Ink on panel 12.3:1, muted
  // 5.7:1, faint 3.5:1 (lifted from Scroll Less's to clear 3:1 on fill;
  // tertiary only).
  static const Color dShell = Color(0xFF161413);
  static const Color dPanel = Color(0xFF272421);
  static const Color dFill = Color(0xFF2F2B28);
  static const Color dRaised = Color(0xFF36322F);
  static const Color dBorder = Color(0xFF3B3734);
  static const Color dEdge = Color(0x0FFFF4E8);
  static const Color dFaint = Color(0xFF7E7872);
  static const Color dMuted = Color(0xFFA39C95);
  static const Color dInk = Color(0xFFEBE5DE);

  // Status (light): text tone on its soft wash.
  static const Color success = Color(0xFF4C6741);
  static const Color successSoft = Color(0xFFEAF0E2);
  static const Color warning = Color(0xFF94580A);
  static const Color warningSoft = Color(0xFFFAF0DA);
  static const Color danger = Color(0xFFB7171A);
  static const Color dangerSoft = Color(0xFFFBF0EF);
  static const Color dangerBorder = Color(0xFFE3C6C3);

  // Status (dark): lifted tones on deep washes.
  static const Color dSuccess = Color(0xFFA3C495);
  static const Color dSuccessSoft = Color(0xFF243020);
  static const Color dWarning = Color(0xFFE2B866);
  static const Color dWarningSoft = Color(0xFF3A2E18);
  static const Color dDanger = Color(0xFFF08A80);
  static const Color dDangerSoft = Color(0xFF3B201E);
  static const Color dDangerBorder = Color(0xFF5E2D29);
}
