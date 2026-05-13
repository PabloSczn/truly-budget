enum CurrencySymbolPosition {
  beforeAmount,
  afterAmount,
}

class Currency {
  final String code;
  final String symbol;
  final String name;
  final CurrencySymbolPosition symbolPosition;
  final bool separateSymbolAndAmount;

  const Currency(
    this.code,
    this.symbol, {
    this.name = '',
    this.symbolPosition = CurrencySymbolPosition.beforeAmount,
    this.separateSymbolAndAmount = false,
  });

  String get displayName => name.isEmpty ? code : name;
}

class Currencies {
  static const list = <Currency>[
    Currency('GBP', '£', name: 'British pound'),
    Currency(
      'EUR',
      '€',
      name: 'Euro',
      symbolPosition: CurrencySymbolPosition.afterAmount,
    ),
    Currency('USD', r'$', name: 'US dollar'),
    Currency('JPY', '¥', name: 'Japanese yen'),
    Currency('INR', '₹', name: 'Indian rupee'),
    Currency('ARS', r'$', name: 'Argentine peso'),
    Currency('BOB', 'Bs', name: 'Bolivian boliviano'),
    Currency(
      'BRL',
      r'R$',
      name: 'Brazilian real',
      separateSymbolAndAmount: true,
    ),
    Currency('CLP', r'$', name: 'Chilean peso'),
    Currency('COP', r'$', name: 'Colombian peso'),
    Currency('PEN', 'S/', name: 'Peruvian sol'),
    Currency('PYG', 'Gs', name: 'Paraguayan guarani'),
    Currency('UYU', r'$', name: 'Uruguayan peso'),
  ];

  static Currency byCode(String code) =>
      list.firstWhere((c) => c.code == code.toUpperCase(),
          orElse: () => list.first);

  static Currency? bySymbol(String symbol) {
    for (final currency in list) {
      if (currency.symbol == symbol) return currency;
    }
    return null;
  }
}
