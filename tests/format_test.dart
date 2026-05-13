import 'package:flutter_test/flutter_test.dart';
import 'package:truly_budget/models/currency.dart';
import 'package:truly_budget/utils/format.dart';

void main() {
  group('Format.money', () {
    test('places euro symbols after the amount', () {
      expect(Format.money(10, symbol: '€'), '10.00€');
      expect(Format.money(-10, symbol: '€'), '-10.00€');
    });

    test('keeps prefix currencies before the amount', () {
      expect(Format.money(10, symbol: '£'), '£10.00');
      expect(Format.money(-10, symbol: '£'), '-£10.00');
      expect(Format.money(10, symbol: 'S/'), 'S/10.00');
    });

    test('supports currencies that separate the symbol and amount', () {
      expect(Format.money(10, symbol: r'R$'), r'R$ 10.00');
    });
  });

  group('Currencies', () {
    test('includes South American currency symbols', () {
      expect(Currencies.byCode('PEN').symbol, 'S/');
      expect(Currencies.byCode('BRL').symbol, r'R$');
      expect(Currencies.byCode('ARS').symbol, r'$');
    });
  });
}
