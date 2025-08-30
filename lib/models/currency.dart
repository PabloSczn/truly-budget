class Currency {
  final String code;
  final String symbol;
  const Currency(this.code, this.symbol);
}

class Currencies {
  static const list = <Currency>[
    Currency('GBP', '£'),
    Currency('EUR', '€'),
    Currency('USD', '\$'),
    Currency('JPY', '¥'),
    Currency('INR', '₹'),
  ];

  static Currency byCode(String code) =>
      list.firstWhere((c) => c.code == code, orElse: () => list.first);
}
