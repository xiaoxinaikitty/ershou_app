/// 热门商品模型
class HotProduct {
  final int productId;
  final String title;
  final String? mainImageUrl;
  final double price;
  final int viewCount;
  final int favoriteCount;
  final int soldCount;
  final double hotScore;

  HotProduct({
    required this.productId,
    required this.title,
    this.mainImageUrl,
    required this.price,
    required this.viewCount,
    required this.favoriteCount,
    required this.soldCount,
    required this.hotScore,
  });

  factory HotProduct.fromJson(Map<String, dynamic> json) {
    return HotProduct(
      productId: json['productId'] ?? 0,
      title: json['title'] ?? '',
      mainImageUrl: json['mainImageUrl'],
      price: (json['price'] ?? 0.0).toDouble(),
      viewCount: json['viewCount'] ?? 0,
      favoriteCount: json['favoriteCount'] ?? 0,
      soldCount: json['soldCount'] ?? 0,
      hotScore: (json['hotScore'] ?? 0.0).toDouble(),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'productId': productId,
      'title': title,
      'mainImageUrl': mainImageUrl,
      'price': price,
      'viewCount': viewCount,
      'favoriteCount': favoriteCount,
      'soldCount': soldCount,
      'hotScore': hotScore,
    };
  }
} 