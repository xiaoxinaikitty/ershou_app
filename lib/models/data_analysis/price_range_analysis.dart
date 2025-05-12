/// 价格区间分析模型
class PriceRangeAnalysis {
  final String range;
  final double minPrice;
  final double maxPrice;
  final int count;
  final double percentage;

  PriceRangeAnalysis({
    required this.range,
    required this.minPrice,
    required this.maxPrice,
    required this.count,
    required this.percentage,
  });

  factory PriceRangeAnalysis.fromJson(Map<String, dynamic> json) {
    return PriceRangeAnalysis(
      range: json['range'] ?? '',
      minPrice: (json['minPrice'] ?? 0.0).toDouble(),
      maxPrice: (json['maxPrice'] ?? 0.0).toDouble(),
      count: json['count'] ?? 0,
      percentage: (json['percentage'] ?? 0.0).toDouble(),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'range': range,
      'minPrice': minPrice,
      'maxPrice': maxPrice,
      'count': count,
      'percentage': percentage,
    };
  }
} 