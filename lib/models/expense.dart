class Expense {
  final String note;
  final double amount;
  final String emoji;
  final DateTime date;

  Expense({
    required this.note,
    required this.amount,
    String? emoji,
    DateTime? date,
  })  : emoji = emoji ?? '🧾',
        date = date ?? DateTime.now();
}
