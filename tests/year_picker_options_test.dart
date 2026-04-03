import 'package:flutter_test/flutter_test.dart';
import 'package:truly_budget/utils/year_picker_options.dart';

void main() {
  test('build includes a wide scrollable range around selected year', () {
    final nowYear = DateTime.now().year;
    final years = YearPickerOptions.build(selectedYear: nowYear);

    expect(years.first, nowYear - 100);
    expect(years.last, nowYear + 100);
    expect(years, contains(nowYear));
  });

  test('fromMonthKeys expands to include stored years outside the current year',
      () {
    final nowYear = DateTime.now().year;
    final olderYear = nowYear - 42;
    final futureYear = nowYear + 114;
    final years = YearPickerOptions.fromMonthKeys(
      ['$olderYear-03', '$futureYear-11', 'bad-key'],
      selectedYear: nowYear,
    );

    expect(years.first, olderYear - 100);
    expect(years.last, futureYear + 100);
    expect(years, containsAll([olderYear, nowYear, futureYear]));
  });
}
