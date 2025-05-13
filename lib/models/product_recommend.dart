/// 推荐商品模型类
class ProductRecommend {
  final int productId;
  final String title;
  final double price;
  final double originalPrice;
  final String mainImage;
  final double score;
  final int recommendationType;

  ProductRecommend({
    required this.productId,
    required this.title,
    required this.price,
    required this.originalPrice,
    required this.mainImage,
    required this.score,
    required this.recommendationType,
  });

  /// 从JSON转换为对象
  factory ProductRecommend.fromJson(Map<String, dynamic> json) {
    return ProductRecommend(
      productId: json['productId'] as int? ?? 0,
      title: json['title'] as String? ?? '',
      price: _parseDouble(json['price']),
      originalPrice: _parseDouble(json['originalPrice']),
      mainImage: json['mainImage'] as String? ?? '',
      score: _parseDouble(json['score']),
      recommendationType: json['recommendationType'] as int? ?? 0,
    );
  }

  /// 转换为JSON
  Map<String, dynamic> toJson() {
    return {
      'productId': productId,
      'title': title,
      'price': price,
      'originalPrice': originalPrice,
      'mainImage': mainImage,
      'score': score,
      'recommendationType': recommendationType,
    };
  }

  /// 辅助方法：安全解析double类型
  static double _parseDouble(dynamic value) {
    if (value == null) return 0.0;
    if (value is double) return value;
    if (value is int) return value.toDouble();
    if (value is String) return double.tryParse(value) ?? 0.0;
    return 0.0;
  }

  /// 获取推荐类型名称
  String getRecommendationTypeName() {
    switch (recommendationType) {
      case 1:
        return '相似商品';
      case 2:
        return '猜你喜欢';
      case 3:
        return '热门推荐';
      case 4:
        return '新品推荐';
      default:
        return '推荐商品';
    }
  }
}
