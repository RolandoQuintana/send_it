import 'package:flutter/cupertino.dart';

/// iOS text styles in SF Pro (sizes and tracking from Apple's HIG). Nothing
/// under 12pt. Styles carry no color, so text inherits `ink` from the
/// theme; pass `surfaces.muted` etc. with `copyWith` where needed.
abstract final class AppText {
  // Flutter maps these names to SF Pro Text / Display on iOS.
  static const String _text = 'CupertinoSystemText';
  static const String _display = 'CupertinoSystemDisplay';

  static const TextStyle largeTitle = TextStyle(
    fontFamily: _display,
    fontSize: 34,
    fontWeight: FontWeight.w700,
    letterSpacing: 0.37,
    height: 1.2,
  );

  static const TextStyle title1 = TextStyle(
    fontFamily: _display,
    fontSize: 28,
    fontWeight: FontWeight.w700,
    letterSpacing: 0.36,
    height: 1.2,
  );

  static const TextStyle title2 = TextStyle(
    fontFamily: _display,
    fontSize: 22,
    fontWeight: FontWeight.w700,
    letterSpacing: -0.26,
    height: 1.25,
  );

  static const TextStyle title3 = TextStyle(
    fontFamily: _display,
    fontSize: 20,
    fontWeight: FontWeight.w600,
    letterSpacing: -0.45,
    height: 1.25,
  );

  static const TextStyle headline = TextStyle(
    fontFamily: _text,
    fontSize: 17,
    fontWeight: FontWeight.w600,
    letterSpacing: -0.43,
    height: 1.3,
  );

  static const TextStyle body = TextStyle(
    fontFamily: _text,
    fontSize: 17,
    fontWeight: FontWeight.w400,
    letterSpacing: -0.43,
    height: 1.3,
  );

  static const TextStyle callout = TextStyle(
    fontFamily: _text,
    fontSize: 16,
    fontWeight: FontWeight.w400,
    letterSpacing: -0.31,
    height: 1.3,
  );

  static const TextStyle subhead = TextStyle(
    fontFamily: _text,
    fontSize: 15,
    fontWeight: FontWeight.w400,
    letterSpacing: -0.23,
    height: 1.35,
  );

  static const TextStyle footnote = TextStyle(
    fontFamily: _text,
    fontSize: 13,
    fontWeight: FontWeight.w400,
    letterSpacing: -0.08,
    height: 1.35,
  );

  static const TextStyle caption = TextStyle(
    fontFamily: _text,
    fontSize: 12,
    fontWeight: FontWeight.w400,
    letterSpacing: 0,
    height: 1.35,
  );

  /// Uppercase grouped-section header (apply `.toUpperCase()` to the text).
  static const TextStyle sectionHeader = TextStyle(
    fontFamily: _text,
    fontSize: 13,
    fontWeight: FontWeight.w500,
    letterSpacing: 0.2,
    height: 1.35,
  );
}
