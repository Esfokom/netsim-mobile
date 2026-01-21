class DateFormatter {
  /// Formats a DateTime to 'YYYY-MM-DD HH:MM' format
  static String formatDate(DateTime dt) {
    return '${dt.year}-${_padZero(dt.month)}-${_padZero(dt.day)} ${_padZero(dt.hour)}:${_padZero(dt.minute)}';
  }

  /// Formats a DateTime to 'YYYY-MM-DD' format
  static String formatDateOnly(DateTime dt) {
    return '${dt.year}-${_padZero(dt.month)}-${_padZero(dt.day)}';
  }

  /// Formats a DateTime to 'HH:MM' format
  static String formatTimeOnly(DateTime dt) {
    return '${_padZero(dt.hour)}:${_padZero(dt.minute)}';
  }

  /// Formats a DateTime to 'HH:MM:SS' format
  static String formatTimeWithSeconds(DateTime dt) {
    return '${_padZero(dt.hour)}:${_padZero(dt.minute)}:${_padZero(dt.second)}';
  }

  /// Pads a number with a leading zero if it's less than 10
  static String _padZero(int v) => v.toString().padLeft(2, '0');
}
