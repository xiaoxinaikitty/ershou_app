/// 成色分析模型
class ConditionAnalysis {
  final int condition;
  final String conditionDesc;
  final int count;
  final double percentage;

  ConditionAnalysis({
    required this.condition,
    required this.conditionDesc,
    required this.count,
    required this.percentage,
  });

  factory ConditionAnalysis.fromJson(Map<String, dynamic> json) {
    return ConditionAnalysis(
      condition: json['condition'] ?? 0,
      conditionDesc: json['conditionDesc'] ?? '',
      count: json['count'] ?? 0,
      percentage: (json['percentage'] ?? 0.0).toDouble(),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'condition': condition,
      'conditionDesc': conditionDesc,
      'count': count,
      'percentage': percentage,
    };
  }
} 