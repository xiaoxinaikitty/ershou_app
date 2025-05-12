/// 分类分析模型
class CategoryAnalysis {
  final int categoryId;
  final String categoryName;
  final int count;
  final double percentage;

  CategoryAnalysis({
    required this.categoryId,
    required this.categoryName,
    required this.count,
    required this.percentage,
  });

  factory CategoryAnalysis.fromJson(Map<String, dynamic> json) {
    return CategoryAnalysis(
      categoryId: json['categoryId'] ?? 0,
      categoryName: json['categoryName'] ?? '',
      count: json['count'] ?? 0,
      percentage: (json['percentage'] ?? 0.0).toDouble(),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'categoryId': categoryId,
      'categoryName': categoryName,
      'count': count,
      'percentage': percentage,
    };
  }
} 