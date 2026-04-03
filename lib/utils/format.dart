import 'package:intl/intl.dart';

class Format {
  static String money(num amount, {String symbol = '£'}) {
    final f = NumberFormat.currency(symbol: symbol, decimalDigits: 2);
    return f.format(amount);
  }

  static String dayMonth(DateTime value) {
    final f = DateFormat('d MMMM');
    return f.format(value);
  }
}
