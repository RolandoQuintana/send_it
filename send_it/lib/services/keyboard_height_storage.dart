/// Service to store and retrieve keyboard height globally across the app
class KeyboardHeightStorage {
  static double? _keyboardHeight;

  /// Set the keyboard height (only updates if larger than current)
  static void setKeyboardHeight(double height) {
    if (_keyboardHeight == null || height > _keyboardHeight!) {
      _keyboardHeight = height;
    }
  }

  /// Get the stored maximum keyboard height
  static double? getKeyboardHeight() {
    return _keyboardHeight;
  }

  /// Check if keyboard height has been captured
  static bool hasKeyboardHeight() {
    return _keyboardHeight != null;
  }

  /// Clear the stored keyboard height
  static void clearKeyboardHeight() {
    _keyboardHeight = null;
  }

  /// Get the current keyboard height as a string for display
  static String getKeyboardHeightString() {
    return _keyboardHeight?.toStringAsFixed(0) ?? 'Not captured';
  }
}
