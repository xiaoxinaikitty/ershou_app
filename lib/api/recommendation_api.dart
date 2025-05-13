import '../network/api.dart';
import '../network/http_util.dart';
import '../models/product_recommend.dart';
import 'dart:developer' as developer;

/// 推荐API封装类
class RecommendationApi {
  static const String _baseUrl = '/api/recommendation';

  // 记录用户行为
  static Future<bool> recordBehavior({
    required int productId,
    required int behaviorType,
    int? stayTime,
  }) async {
    try {
      final response = await HttpUtil().post(
        '$_baseUrl/behavior',
        data: {
          'productId': productId,
          'behaviorType': behaviorType,
          'stayTime': stayTime,
        },
      );

      if (response.isSuccess && response.data != null) {
        return response.data as bool? ?? false;
      }

      developer.log('记录用户行为失败: ${response.message}', name: 'RecommendationApi');
      return false;
    } catch (e) {
      developer.log('记录用户行为异常: $e', name: 'RecommendationApi');
      return false;
    }
  }

  // 获取相似商品推荐
  static Future<List<ProductRecommend>> getSimilarProducts(int productId,
      {int? limit}) async {
    try {
      Map<String, dynamic>? params;
      if (limit != null) {
        params = {'limit': limit};
      }

      final response = await HttpUtil().get(
        '$_baseUrl/similar/$productId',
        params: params,
      );

      if (response.isSuccess && response.data != null) {
        final List<dynamic> data = response.data as List<dynamic>;
        return data.map((item) => ProductRecommend.fromJson(item)).toList();
      }

      developer.log('获取相似商品推荐失败: ${response.message}',
          name: 'RecommendationApi');
      return [];
    } catch (e) {
      developer.log('获取相似商品推荐异常: $e', name: 'RecommendationApi');
      return [];
    }
  }

  // 获取个性化推荐
  static Future<List<ProductRecommend>> getPersonalizedRecommendations(
      {int? limit}) async {
    try {
      Map<String, dynamic>? params;
      if (limit != null) {
        params = {'limit': limit};
      }

      final response = await HttpUtil().get(
        '$_baseUrl/personalized',
        params: params,
      );

      if (response.isSuccess && response.data != null) {
        final List<dynamic> data = response.data as List<dynamic>;
        return data.map((item) => ProductRecommend.fromJson(item)).toList();
      }

      developer.log('获取个性化推荐失败: ${response.message}',
          name: 'RecommendationApi');
      return [];
    } catch (e) {
      developer.log('获取个性化推荐异常: $e', name: 'RecommendationApi');
      return [];
    }
  }

  // 获取热门推荐
  static Future<List<ProductRecommend>> getHotRecommendations(
      {int? limit}) async {
    try {
      Map<String, dynamic>? params;
      if (limit != null) {
        params = {'limit': limit};
      }

      final response = await HttpUtil().get(
        '$_baseUrl/hot',
        params: params,
      );

      if (response.isSuccess && response.data != null) {
        final List<dynamic> data = response.data as List<dynamic>;
        return data.map((item) => ProductRecommend.fromJson(item)).toList();
      }

      developer.log('获取热门推荐失败: ${response.message}', name: 'RecommendationApi');
      return [];
    } catch (e) {
      developer.log('获取热门推荐异常: $e', name: 'RecommendationApi');
      return [];
    }
  }

  // 记录推荐点击
  static Future<bool> recordRecommendationClick({
    required int productId,
    required int type,
  }) async {
    try {
      final response = await HttpUtil().post(
        '$_baseUrl/click',
        params: {
          'productId': productId,
          'type': type,
        },
      );

      if (response.isSuccess && response.data != null) {
        return response.data as bool? ?? false;
      }

      developer.log('记录推荐点击失败: ${response.message}', name: 'RecommendationApi');
      return false;
    } catch (e) {
      developer.log('记录推荐点击异常: $e', name: 'RecommendationApi');
      return false;
    }
  }
}
