/// 趋势分析模型
class TrendAnalysis {
  final DateTime date;
  final int count;

  TrendAnalysis({
    required this.date,
    required this.count,
  });

  factory TrendAnalysis.fromJson(Map<String, dynamic> json) {
    return TrendAnalysis(
      date: json['date'] != null 
          ? DateTime.parse(json['date']) 
          : DateTime.now(),
      count: json['count'] ?? 0,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'date': date.toIso8601String().split('T')[0],
      'count': count,
    };
  }
} 