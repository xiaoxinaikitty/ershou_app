import '../network/api.dart';
import '../network/http_util.dart';
import '../models/product_recommend.dart';
import '../utils/image_url_util.dart';
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

  // 处理图片URL的辅助方法
  static List<ProductRecommend> _processRecommendations(List<dynamic> data) {
    // 记录原始数据的第一项用于调试
    if (data.isNotEmpty && data[0] is Map<String, dynamic>) {
      developer.log('原始推荐数据样例: ${data[0]}', name: 'RecommendationApi');
    }
    
    // 处理每个推荐项的图片URL
    final recommendations = data.map((item) {
      if (item is Map<String, dynamic>) {
        if (item.containsKey('mainImage')) {
          String mainImageUrl = item['mainImage'] as String? ?? '';
          developer.log('处理前的推荐图片: $mainImageUrl', name: 'RecommendationApi');
          
          // 检测是否为示例URL
          if (mainImageUrl.contains('example.com') || mainImageUrl.isEmpty) {
            // 使用一个合理的资源路径代替
            String replacementUrl = '/images/product_${item['productId'] ?? 'default'}.jpg';
            developer.log('检测到示例URL，准备使用默认图片路径: $replacementUrl', name: 'RecommendationApi');
            item['mainImage'] = replacementUrl;
          } else {
            // 处理图片URL
            mainImageUrl = ImageUrlUtil.processImageUrl(mainImageUrl);
            item['mainImage'] = mainImageUrl;
            developer.log('处理后的推荐图片: $mainImageUrl', name: 'RecommendationApi');
          }
        } else {
          // 如果没有mainImage字段，添加一个默认路径
          item['mainImage'] = '/images/default_product.png';
          developer.log('推荐项缺少mainImage字段，添加默认路径', name: 'RecommendationApi');
        }
      }
      return ProductRecommend.fromJson(item);
    }).toList();
    
    return recommendations;
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
        return _processRecommendations(data);
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
        return _processRecommendations(data);
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
        return _processRecommendations(data);
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
