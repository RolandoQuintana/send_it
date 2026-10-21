import 'dart:io';

import 'package:gaimon/gaimon.dart';

/// App haptics (same split as Scroll Less): pick by intent, not strength.
abstract final class Haptics {
  /// Tabs, toggles, list picks.
  static void selection() => Gaimon.selection();

  /// Primary actions (CTAs).
  static void primary() => Gaimon.light();

  /// A finished job, e.g. a batch sent. Native channel, so iOS only.
  static void success() {
    if (Platform.isIOS) Gaimon.success();
  }

  /// Something needs attention: a destructive confirm, a blocked action.
  static void warning() {
    if (Platform.isIOS) Gaimon.warning();
  }
}
