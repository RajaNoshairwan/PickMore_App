import 'package:intl/intl.dart';

class Formatters {
  static final _currency =
  NumberFormat.currency(symbol: 'Rs. ', decimalDigits: 0);
  static final _date = DateFormat('dd MMM yyyy, hh:mm a');

  static String price(num v) => _currency.format(v);
  static String date(DateTime? d) => d == null ? '' : _date.format(d);

  /// "Rs. 1,199" without decimals everywhere.
  static String rupee(num v) => 'Rs. ${v.toStringAsFixed(0)}';
}