class Income {
  final String source; // may include emoji
  final double amount;
  final DateTime date;

  Income({required this.source, required this.amount, DateTime? date})
      : date = date ?? DateTime.now();

  Map<String, dynamic> toJson() => {
        'source': source,
        'amount': amount,
        'date': date.toIso8601String(),
      };

  factory Income.fromJson(Map<String, dynamic> json) => Income(
        source: json['source'] as String,
        amount: (json['amount'] as num).toDouble(),
        date:
            DateTime.tryParse(json['date'] as String? ?? '') ?? DateTime.now(),
      );
}
