import 'amount_trend_analysis.dart';
import 'category_analysis.dart';
import 'status_analysis.dart';
import 'trend_analysis.dart';

/// 自定义分析模型
class CustomAnalysis {
  final DateTime startDate;
  final DateTime endDate;
  final int newUsers;
  final int newProducts;
  final int newOrders;
  final double orderAmount;
  final List<CategoryAnalysis> categoryAnalysis;
  final List<StatusAnalysis> productStatusAnalysis;
  final List<StatusAnalysis> orderStatusAnalysis;
  final List<TrendAnalysis> userRegisterTrend;
  final List<TrendAnalysis> productTrend;
  final List<TrendAnalysis> orderTrend;
  final List<AmountTrendAnalysis> orderAmountTrend;

  CustomAnalysis({
    required this.startDate,
    required this.endDate,
    required this.newUsers,
    required this.newProducts,
    required this.newOrders,
    required this.orderAmount,
    required this.categoryAnalysis,
    required this.productStatusAnalysis,
    required this.orderStatusAnalysis,
    required this.userRegisterTrend,
    required this.productTrend,
    required this.orderTrend,
    required this.orderAmountTrend,
  });

  factory CustomAnalysis.fromJson(Map<String, dynamic> json) {
    return CustomAnalysis(
      startDate: json['startDate'] != null 
          ? DateTime.parse(json['startDate']) 
          : DateTime.now().subtract(const Duration(days: 30)),
      endDate: json['endDate'] != null 
          ? DateTime.parse(json['endDate']) 
          : DateTime.now(),
      newUsers: json['newUsers'] ?? 0,
      newProducts: json['newProducts'] ?? 0,
      newOrders: json['newOrders'] ?? 0,
      orderAmount: (json['orderAmount'] ?? 0.0).toDouble(),
      categoryAnalysis: json['categoryAnalysis'] != null
          ? (json['categoryAnalysis'] as List)
              .map((item) => CategoryAnalysis.fromJson(item))
              .toList()
          : [],
      productStatusAnalysis: json['productStatusAnalysis'] != null
          ? (json['productStatusAnalysis'] as List)
              .map((item) => StatusAnalysis.fromJson(item))
              .toList()
          : [],
      orderStatusAnalysis: json['orderStatusAnalysis'] != null
          ? (json['orderStatusAnalysis'] as List)
              .map((item) => StatusAnalysis.fromJson(item))
              .toList()
          : [],
      userRegisterTrend: json['userRegisterTrend'] != null
          ? (json['userRegisterTrend'] as List)
              .map((item) => TrendAnalysis.fromJson(item))
              .toList()
          : [],
      productTrend: json['productTrend'] != null
          ? (json['productTrend'] as List)
              .map((item) => TrendAnalysis.fromJson(item))
              .toList()
          : [],
      orderTrend: json['orderTrend'] != null
          ? (json['orderTrend'] as List)
              .map((item) => TrendAnalysis.fromJson(item))
              .toList()
          : [],
      orderAmountTrend: json['orderAmountTrend'] != null
          ? (json['orderAmountTrend'] as List)
              .map((item) => AmountTrendAnalysis.fromJson(item))
              .toList()
          : [],
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'startDate': startDate.toIso8601String().split('T')[0],
      'endDate': endDate.toIso8601String().split('T')[0],
      'newUsers': newUsers,
      'newProducts': newProducts,
      'newOrders': newOrders,
      'orderAmount': orderAmount,
      'categoryAnalysis': categoryAnalysis.map((item) => item.toJson()).toList(),
      'productStatusAnalysis': productStatusAnalysis.map((item) => item.toJson()).toList(),
      'orderStatusAnalysis': orderStatusAnalysis.map((item) => item.toJson()).toList(),
      'userRegisterTrend': userRegisterTrend.map((item) => item.toJson()).toList(),
      'productTrend': productTrend.map((item) => item.toJson()).toList(),
      'orderTrend': orderTrend.map((item) => item.toJson()).toList(),
      'orderAmountTrend': orderAmountTrend.map((item) => item.toJson()).toList(),
    };
  }
} 