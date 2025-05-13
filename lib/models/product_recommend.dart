import '../utils/image_url_util.dart';
import 'dart:developer' as developer;

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
    // 获取原始图片URL
    String mainImageUrl = json['mainImage'] as String? ?? '';
    developer.log('ProductRecommend解析前图片URL: $mainImageUrl', name: 'ProductRecommend');
    
    // 检测是否为空或为示例URL
    if (mainImageUrl.isEmpty || mainImageUrl.contains('example.com')) {
      // 使用相对路径替代
      mainImageUrl = '/images/product_${json['productId'] ?? 'default'}.jpg';
      developer.log('检测到空URL或示例URL，使用默认图片路径: $mainImageUrl', name: 'ProductRecommend');
    }
    
    // 处理图片URL
    mainImageUrl = ImageUrlUtil.processImageUrl(mainImageUrl);
    developer.log('ProductRecommend解析后图片URL: $mainImageUrl', name: 'ProductRecommend');
    
    return ProductRecommend(
      productId: json['productId'] as int? ?? 0,
      title: json['title'] as String? ?? '',
      price: _parseDouble(json['price']),
      originalPrice: _parseDouble(json['originalPrice']),
      mainImage: mainImageUrl,
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
