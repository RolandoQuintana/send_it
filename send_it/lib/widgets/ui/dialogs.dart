import 'package:flutter/cupertino.dart';

/// One-button alert ("OK"). Replaces the copy-pasted error dialogs.
Future<void> showNotice(
  BuildContext context, {
  required String title,
  required String message,
  String action = 'OK',
}) {
  return showCupertinoDialog<void>(
    context: context,
    barrierDismissible: true,
    builder: (ctx) => CupertinoAlertDialog(
      title: Text(title),
      content: Text(message),
      actions: [
        CupertinoDialogAction(
          isDefaultAction: true,
          onPressed: () => Navigator.pop(ctx),
          child: Text(action),
        ),
      ],
    ),
  );
}

/// Two-button confirm. Resolves true only when [confirm] is tapped.
Future<bool> showConfirm(
  BuildContext context, {
  required String title,
  required String message,
  required String confirm,
  String cancel = 'Cancel',
  bool destructive = false,
}) async {
  final result = await showCupertinoDialog<bool>(
    context: context,
    builder: (ctx) => CupertinoAlertDialog(
      title: Text(title),
      content: Text(message),
      actions: [
        CupertinoDialogAction(
          onPressed: () => Navigator.pop(ctx, false),
          child: Text(cancel),
        ),
        CupertinoDialogAction(
          isDefaultAction: !destructive,
          isDestructiveAction: destructive,
          onPressed: () => Navigator.pop(ctx, true),
          child: Text(confirm),
        ),
      ],
    ),
  );
  return result == true;
}
