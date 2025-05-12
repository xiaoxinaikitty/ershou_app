/// 金额趋势分析模型
class AmountTrendAnalysis {
  final DateTime date;
  final double amount;
  final int count;

  AmountTrendAnalysis({
    required this.date,
    required this.amount,
    required this.count,
  });

  factory AmountTrendAnalysis.fromJson(Map<String, dynamic> json) {
    return AmountTrendAnalysis(
      date: json['date'] != null 
          ? DateTime.parse(json['date']) 
          : DateTime.now(),
      amount: (json['amount'] ?? 0.0).toDouble(),
      count: json['count'] ?? 0,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'date': date.toIso8601String().split('T')[0],
      'amount': amount,
      'count': count,
    };
  }
} 