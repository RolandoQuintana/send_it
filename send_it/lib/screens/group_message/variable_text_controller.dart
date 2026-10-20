import 'package:flutter/cupertino.dart';

import '../../theme/app_surfaces.dart';

/// Message field controller that draws `{firstname}` as a chip and treats
/// it as one unit: a tap inside it selects the whole token, so typing or
/// deleting replaces it at once. The text itself is unchanged, so
/// [ShortcutService.personalizeMessage] still sees the raw token.
class VariableTextController extends TextEditingController {
  VariableTextController({super.text});

  static const firstName = '{firstname}';
  static final _token = RegExp(RegExp.escape(firstName));

  @override
  set value(TextEditingValue newValue) {
    super.value = snapSelectionToToken(previous: value, next: newValue);
  }

  /// A collapsed cursor moved strictly inside a token (with the text
  /// unchanged, i.e. a tap) selects the token.
  @visibleForTesting
  static TextEditingValue snapSelectionToToken({
    required TextEditingValue previous,
    required TextEditingValue next,
  }) {
    final selection = next.selection;
    if (next.text != previous.text ||
        !selection.isValid ||
        !selection.isCollapsed) {
      return next;
    }
    for (final match in _token.allMatches(next.text)) {
      if (selection.baseOffset > match.start &&
          selection.baseOffset < match.end) {
        return next.copyWith(
          selection: TextSelection(
            baseOffset: match.start,
            extentOffset: match.end,
          ),
        );
      }
    }
    return next;
  }

  @override
  TextSpan buildTextSpan({
    required BuildContext context,
    TextStyle? style,
    required bool withComposing,
  }) {
    final composing = withComposing && value.isComposingRangeValid;
    if (composing || !text.contains(firstName)) {
      return super.buildTextSpan(
        context: context,
        style: style,
        withComposing: withComposing,
      );
    }

    final surfaces = context.surfaces;
    final chipStyle = (style ?? const TextStyle()).copyWith(
      color: surfaces.accent,
      fontWeight: FontWeight.w600,
      background: Paint()..color = surfaces.accentSoft,
    );

    final children = <TextSpan>[];
    var last = 0;
    for (final match in _token.allMatches(text)) {
      if (match.start > last) {
        children.add(TextSpan(text: text.substring(last, match.start)));
      }
      children.add(TextSpan(text: match[0], style: chipStyle));
      last = match.end;
    }
    if (last < text.length) children.add(TextSpan(text: text.substring(last)));
    return TextSpan(style: style, children: children);
  }
}
