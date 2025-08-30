class YearMonth {
  final int year;
  final int month; // 1-12
  const YearMonth(this.year, this.month);

  String get key => '$year-${month.toString().padLeft(2, '0')}';
  String get label => '${_monthName(month)} $year';

  static String labelFromKey(String key) {
    final parts = key.split('-');
    final y = int.parse(parts[0]);
    final m = int.parse(parts[1]);
    return YearMonth(y, m).label;
  }

  static String _monthName(int m) {
    const names = [
      'January',
      'February',
      'March',
      'April',
      'May',
      'June',
      'July',
      'August',
      'September',
      'October',
      'November',
      'December'
    ];
    return names[m - 1];
  }
}
