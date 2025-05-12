import 'package:ershou_app/models/data_analysis/amount_trend_analysis.dart';
import 'package:ershou_app/models/data_analysis/category_analysis.dart';
import 'package:ershou_app/models/data_analysis/condition_analysis.dart';
import 'package:ershou_app/models/data_analysis/custom_analysis.dart';
import 'package:ershou_app/models/data_analysis/data_summary.dart';
import 'package:ershou_app/models/data_analysis/hot_product.dart';
import 'package:ershou_app/models/data_analysis/price_range_analysis.dart';
import 'package:ershou_app/models/data_analysis/status_analysis.dart';
import 'package:ershou_app/models/data_analysis/trend_analysis.dart';
import 'package:ershou_app/models/data_analysis/user_active_analysis.dart';
import 'package:ershou_app/network/api.dart';
import 'package:ershou_app/network/http_util.dart';

/// 数据分析服务类
class DataAnalysisService {
  /// 获取数据摘要
  static Future<DataSummary> getDataSummary() async {
    final response = await HttpUtil.get(Api.dataSummary);
    return DataSummary.fromJson(response.data);
  }

  /// 获取商品分类统计
  static Future<List<CategoryAnalysis>> getProductCategoryAnalysis() async {
    final response = await HttpUtil.get(Api.dataProductCategory);
    return (response.data as List)
        .map((item) => CategoryAnalysis.fromJson(item))
        .toList();
  }

  /// 获取商品价格区间统计
  static Future<List<PriceRangeAnalysis>> getProductPriceRangeAnalysis() async {
    final response = await HttpUtil.get(Api.dataProductPriceRange);
    return (response.data as List)
        .map((item) => PriceRangeAnalysis.fromJson(item))
        .toList();
  }

  /// 获取商品成色统计
  static Future<List<ConditionAnalysis>> getProductConditionAnalysis() async {
    final response = await HttpUtil.get(Api.dataProductCondition);
    return (response.data as List)
        .map((item) => ConditionAnalysis.fromJson(item))
        .toList();
  }

  /// 获取商品状态统计
  static Future<List<StatusAnalysis>> getProductStatusAnalysis() async {
    final response = await HttpUtil.get(Api.dataProductStatus);
    return (response.data as List)
        .map((item) => StatusAnalysis.fromJson(item))
        .toList();
  }

  /// 获取商品发布趋势
  static Future<List<TrendAnalysis>> getProductTrend({int days = 30}) async {
    final response = await HttpUtil.get(
      Api.dataProductTrend,
      params: {'days': days},
    );
    return (response.data as List)
        .map((item) => TrendAnalysis.fromJson(item))
        .toList();
  }

  /// 获取用户注册趋势
  static Future<List<TrendAnalysis>> getUserRegisterTrend({int days = 30}) async {
    final response = await HttpUtil.get(
      Api.dataUserRegisterTrend,
      params: {'days': days},
    );
    return (response.data as List)
        .map((item) => TrendAnalysis.fromJson(item))
        .toList();
  }

  /// 获取订单趋势
  static Future<List<TrendAnalysis>> getOrderTrend({int days = 30}) async {
    final response = await HttpUtil.get(
      Api.dataOrderTrend,
      params: {'days': days},
    );
    return (response.data as List)
        .map((item) => TrendAnalysis.fromJson(item))
        .toList();
  }

  /// 获取订单金额趋势
  static Future<List<AmountTrendAnalysis>> getOrderAmountTrend({int days = 30}) async {
    final response = await HttpUtil.get(
      Api.dataOrderAmountTrend,
      params: {'days': days},
    );
    return (response.data as List)
        .map((item) => AmountTrendAnalysis.fromJson(item))
        .toList();
  }

  /// 获取订单状态统计
  static Future<List<StatusAnalysis>> getOrderStatusAnalysis() async {
    final response = await HttpUtil.get(Api.dataOrderStatus);
    return (response.data as List)
        .map((item) => StatusAnalysis.fromJson(item))
        .toList();
  }

  /// 获取活跃用户统计
  static Future<List<UserActiveAnalysis>> getUserActiveAnalysis({int days = 30}) async {
    final response = await HttpUtil.get(
      Api.dataUserActive,
      params: {'days': days},
    );
    return (response.data as List)
        .map((item) => UserActiveAnalysis.fromJson(item))
        .toList();
  }

  /// 获取热门商品
  static Future<List<HotProduct>> getHotProducts({int limit = 10}) async {
    final response = await HttpUtil.get(
      Api.dataProductHot,
      params: {'limit': limit},
    );
    return (response.data as List)
        .map((item) => HotProduct.fromJson(item))
        .toList();
  }

  /// 获取自定义日期范围数据分析
  static Future<CustomAnalysis> getCustomAnalysis({
    required DateTime startDate,
    required DateTime endDate,
  }) async {
    final response = await HttpUtil.get(
      Api.dataCustom,
      params: {
        'startDate': startDate.toIso8601String().split('T')[0],
        'endDate': endDate.toIso8601String().split('T')[0],
      },
    );
    return CustomAnalysis.fromJson(response.data);
  }
} 