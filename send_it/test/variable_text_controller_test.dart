import 'package:flutter/cupertino.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:send_it/screens/group_message/variable_text_controller.dart';

void main() {
  const text = 'Hey {firstname}!';

  TextEditingValue at(int offset, [String t = text]) => TextEditingValue(
        text: t,
        selection: TextSelection.collapsed(offset: offset),
      );

  test('a tap inside the token selects the whole token', () {
    final controller = VariableTextController(text: text);
    controller.value = at(8);
    expect(controller.selection,
        const TextSelection(baseOffset: 4, extentOffset: 15));
  });

  test('a cursor at the token edges is left alone', () {
    final controller = VariableTextController(text: text);
    controller.value = at(4);
    expect(controller.selection, const TextSelection.collapsed(offset: 4));
    controller.value = at(15);
    expect(controller.selection, const TextSelection.collapsed(offset: 15));
  });

  test('typing is never snapped', () {
    final controller = VariableTextController(text: 'Hey {firstname');
    controller.value = at(15, 'Hey {firstname}');
    expect(controller.selection, const TextSelection.collapsed(offset: 15));
  });

  testWidgets('renders the token as its own span without changing the text',
      (tester) async {
    final controller = VariableTextController(text: text);
    late TextSpan span;
    await tester.pumpWidget(CupertinoApp(
      home: Builder(builder: (context) {
        span = controller.buildTextSpan(
          context: context,
          withComposing: false,
        );
        return const SizedBox();
      }),
    ));

    expect(span.toPlainText(), text);
    final tokenSpan = span.children!.whereType<TextSpan>().singleWhere(
          (s) => s.text == VariableTextController.firstName,
        );
    expect(tokenSpan.style?.background, isNotNull);
  });
}
