class Expense {
  final String note; // may include emoji
  final double amount;
  final DateTime date;

  Expense({required this.note, required this.amount, DateTime? date})
      : date = date ?? DateTime.now();
}
