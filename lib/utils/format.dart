import 'package:intl/intl.dart';

import '../models/currency.dart';

class Format {
  static String money(num amount, {String symbol = '£'}) {
    final currency = Currencies.bySymbol(symbol);
    final f = NumberFormat.currency(symbol: '', decimalDigits: 2);
    final formattedAmount = f.format(amount).trim();
    final separator = (currency?.separateSymbolAndAmount ?? false) ? ' ' : '';

    if (currency?.symbolPosition == CurrencySymbolPosition.afterAmount) {
      return '$formattedAmount$separator$symbol';
    }

    final isNegative = formattedAmount.startsWith('-');
    final unsignedAmount =
        isNegative ? formattedAmount.substring(1) : formattedAmount;
    final sign = isNegative ? '-' : '';
    return '$sign$symbol$separator$unsignedAmount';
  }

  static String dayMonth(DateTime value) {
    final f = DateFormat('d MMMM');
    return f.format(value);
  }
}
