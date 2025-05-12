/// 用户活跃分析模型
class UserActiveAnalysis {
  final int userId;
  final String username;
  final int productCount;
  final int orderCount;
  final int favoriteCount;
  final double activityScore;

  UserActiveAnalysis({
    required this.userId,
    required this.username,
    required this.productCount,
    required this.orderCount,
    required this.favoriteCount,
    required this.activityScore,
  });

  factory UserActiveAnalysis.fromJson(Map<String, dynamic> json) {
    return UserActiveAnalysis(
      userId: json['userId'] ?? 0,
      username: json['username'] ?? '',
      productCount: json['productCount'] ?? 0,
      orderCount: json['orderCount'] ?? 0,
      favoriteCount: json['favoriteCount'] ?? 0,
      activityScore: (json['activityScore'] ?? 0.0).toDouble(),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'userId': userId,
      'username': username,
      'productCount': productCount,
      'orderCount': orderCount,
      'favoriteCount': favoriteCount,
      'activityScore': activityScore,
    };
  }
} 