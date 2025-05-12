/// 数据摘要模型
class DataSummary {
  final int totalUsers;
  final int totalProducts;
  final int totalOrders;
  final double totalOrderAmount;
  final int activeSellUsers;
  final int activeBuyUsers;
  final int newUsersLast30Days;
  final int newProductsLast30Days;
  final int newOrdersLast30Days;
  final double newOrderAmountLast30Days;

  DataSummary({
    required this.totalUsers,
    required this.totalProducts,
    required this.totalOrders,
    required this.totalOrderAmount,
    required this.activeSellUsers,
    required this.activeBuyUsers,
    required this.newUsersLast30Days,
    required this.newProductsLast30Days,
    required this.newOrdersLast30Days,
    required this.newOrderAmountLast30Days,
  });

  factory DataSummary.fromJson(Map<String, dynamic> json) {
    return DataSummary(
      totalUsers: json['totalUsers'] ?? 0,
      totalProducts: json['totalProducts'] ?? 0,
      totalOrders: json['totalOrders'] ?? 0,
      totalOrderAmount: (json['totalOrderAmount'] ?? 0.0).toDouble(),
      activeSellUsers: json['activeSellUsers'] ?? 0,
      activeBuyUsers: json['activeBuyUsers'] ?? 0,
      newUsersLast30Days: json['newUsersLast30Days'] ?? 0,
      newProductsLast30Days: json['newProductsLast30Days'] ?? 0,
      newOrdersLast30Days: json['newOrdersLast30Days'] ?? 0,
      newOrderAmountLast30Days: (json['newOrderAmountLast30Days'] ?? 0.0).toDouble(),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'totalUsers': totalUsers,
      'totalProducts': totalProducts,
      'totalOrders': totalOrders,
      'totalOrderAmount': totalOrderAmount,
      'activeSellUsers': activeSellUsers,
      'activeBuyUsers': activeBuyUsers,
      'newUsersLast30Days': newUsersLast30Days,
      'newProductsLast30Days': newProductsLast30Days,
      'newOrdersLast30Days': newOrdersLast30Days,
      'newOrderAmountLast30Days': newOrderAmountLast30Days,
    };
  }
} 