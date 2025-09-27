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

  Map<String, dynamic> toJson() => {
        'note': note,
        'amount': amount,
        'emoji': emoji,
        'date': date.toIso8601String(),
      };

  factory Expense.fromJson(Map<String, dynamic> json) => Expense(
        note: json['note'] as String,
        amount: (json['amount'] as num).toDouble(),
        emoji: json['emoji'] as String? ?? '🧾',
        date:
            DateTime.tryParse(json['date'] as String? ?? '') ?? DateTime.now(),
      );
}
