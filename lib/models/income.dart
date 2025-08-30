class Income {
  final String source; // may include emoji
  final double amount;
  final DateTime date;

  Income({required this.source, required this.amount, DateTime? date})
      : date = date ?? DateTime.now();
}
