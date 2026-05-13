import 'package:intl/intl.dart';

class Fmt {
  Fmt._();

  static final _money = NumberFormat.currency(symbol: '\$', decimalDigits: 0);
  static final _moneyDecimal = NumberFormat.currency(symbol: '\$', decimalDigits: 2);

  static String money(num value, {bool decimals = false}) =>
      decimals ? _moneyDecimal.format(value) : _money.format(value);

  static String quantity(num value, String unit) {
    final v = value == value.toInt() ? value.toInt().toString() : value.toString();
    return '$v $unit';
  }

  /// Renders timestamps relative to "today" the way the prototype does:
  /// today  → "Today · 13 May"
  /// y'day → "Yesterday · 12 May"
  /// other → "Mon · 11 May"
  static String relativeDay(DateTime date, {DateTime? now, String locale = 'en'}) {
    final n = now ?? DateTime.now();
    final today = DateTime(n.year, n.month, n.day);
    final that = DateTime(date.year, date.month, date.day);
    final diff = today.difference(that).inDays;
    final day = DateFormat('d MMM', locale).format(date);
    if (diff == 0) return 'Today · $day';
    if (diff == 1) return 'Yesterday · $day';
    if (diff > 1 && diff < 7) return '${DateFormat('EEE', locale).format(date)} · $day';
    return DateFormat('d MMM yyyy', locale).format(date);
  }

  static String time(DateTime date) => DateFormat('HH:mm').format(date);

  /// 6-digit signed coordinate readout, e.g. "-1.292100, 36.821900"
  static String gps(double lat, double lng) =>
      '${lat.toStringAsFixed(6)}, ${lng.toStringAsFixed(6)}';
}
