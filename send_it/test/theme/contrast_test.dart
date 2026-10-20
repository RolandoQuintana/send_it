import 'dart:math' as math;

import 'package:flutter/cupertino.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:send_it/theme/app_surfaces.dart';
import 'package:send_it/theme/app_theme.dart';

double _contrast(Color a, Color b) {
  final la = a.computeLuminance();
  final lb = b.computeLuminance();
  return (math.max(la, lb) + 0.05) / (math.min(la, lb) + 0.05);
}

void main() {
  for (final s in [AppSurfaces.light, AppSurfaces.dark]) {
    group('${s.brightness.name} tokens', () {
      // Body-size text: WCAG AA 4.5:1.
      final text = <String, (Color, Color)>{
        'ink on background': (s.ink, s.background),
        'ink on card': (s.ink, s.card),
        'muted on background': (s.muted, s.background),
        'muted on card': (s.muted, s.card),
        'muted on fill': (s.muted, s.fill),
        'accent on background': (s.accent, s.background),
        'accent on card': (s.accent, s.card),
        'accent on accentSoft': (s.accent, s.accentSoft),
        'onAccent on accentFill': (s.onAccent, s.accentFill),
        'danger on card': (s.danger, s.card),
        'warning on warningSoft': (s.warning, s.warningSoft),
        'success on successSoft': (s.success, s.successSoft),
      };
      text.forEach((name, pair) {
        test('$name ≥ 4.5:1', () {
          expect(_contrast(pair.$1, pair.$2), greaterThanOrEqualTo(4.5));
        });
      });

      // Icons, large glyphs and tertiary text: 3:1.
      test('white on brand teal ≥ 3:1 (avatars, icons)', () {
        expect(
          _contrast(const Color(0xFFFFFFFF), s.brand),
          greaterThanOrEqualTo(3),
        );
      });
      final tertiary = {
        'background': s.background,
        'card': s.card,
        'fill': s.fill,
      };
      tertiary.forEach((name, bg) {
        test('faint on $name ≥ 3:1', () {
          expect(_contrast(s.faint, bg), greaterThanOrEqualTo(3));
        });
      });
    });
  }

  testWidgets('context.surfaces follows the theme brightness', (tester) async {
    late AppSurfaces light;
    late AppSurfaces dark;
    Widget probe(Brightness b, void Function(AppSurfaces) out) {
      return CupertinoApp(
        theme: AppTheme.cupertino(brightness: b),
        home: Builder(builder: (context) {
          out(context.surfaces);
          return const SizedBox();
        }),
      );
    }

    await tester.pumpWidget(probe(Brightness.light, (s) => light = s));
    await tester.pumpWidget(probe(Brightness.dark, (s) => dark = s));
    expect(light, same(AppSurfaces.light));
    expect(dark, same(AppSurfaces.dark));
  });

  testWidgets('filled button label passes 4.5:1 in both themes',
      (tester) async {
    for (final b in Brightness.values) {
      late CupertinoThemeData theme;
      await tester.pumpWidget(CupertinoApp(
        theme: AppTheme.cupertino(brightness: b),
        home: Builder(builder: (context) {
          theme = CupertinoTheme.of(context);
          return const SizedBox();
        }),
      ));
      expect(
        _contrast(theme.primaryColor, theme.primaryContrastingColor),
        greaterThanOrEqualTo(4.5),
        reason: b.name,
      );
    }
  });
}
