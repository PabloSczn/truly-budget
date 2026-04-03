class YearPickerOptions {
  static const int _bufferYears = 100;

  static List<int> fromMonthKeys(
    Iterable<String> monthKeys, {
    required int selectedYear,
  }) {
    return build(
      selectedYear: selectedYear,
      extraYears: parsedYearsFromMonthKeys(monthKeys),
    );
  }

  static List<int> build({
    required int selectedYear,
    Iterable<int> extraYears = const [],
  }) {
    final anchorYears = <int>{DateTime.now().year, selectedYear, ...extraYears};
    var minYear = anchorYears.first;
    var maxYear = anchorYears.first;

    for (final year in anchorYears.skip(1)) {
      if (year < minYear) minYear = year;
      if (year > maxYear) maxYear = year;
    }

    minYear -= _bufferYears;
    maxYear += _bufferYears;

    return List<int>.generate(
      maxYear - minYear + 1,
      (index) => minYear + index,
      growable: false,
    );
  }

  static List<int> parsedYearsFromMonthKeys(Iterable<String> monthKeys) {
    final years = <int>{};
    for (final key in monthKeys) {
      final parts = key.split('-');
      if (parts.isEmpty) continue;
      final year = int.tryParse(parts.first);
      if (year != null) years.add(year);
    }
    final sortedYears = years.toList()..sort();
    return sortedYears;
  }
}
