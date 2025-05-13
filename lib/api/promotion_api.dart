import '../network/http_util.dart';
import '../network/api.dart';
import '../utils/image_url_util.dart';
import 'dart:developer' as developer;

class PromotionApi {
  /// 获取当前有效的促销活动列表
  /// [limit] 可选，限制返回的活动数量
  static Future<List<Map<String, dynamic>>> getActivePromotions(
      {int? limit}) async {
    try {
      Map<String, dynamic>? params;
      if (limit != null) {
        params = {'limit': limit};
      }

      developer.log('开始获取促销活动列表', name: 'PromotionApi');
      final response =
          await HttpUtil().get(Api.promotionActive, params: params);

      if (response.isSuccess && response.data != null) {
        final List<dynamic> promotionList = response.data as List<dynamic>;
        
        // 处理每个活动中的图片URL
        final List<Map<String, dynamic>> processedPromotions = [];
        for (var item in promotionList) {
          final Map<String, dynamic> promotion = item as Map<String, dynamic>;
          
          // 处理活动中的图片URL
          if (promotion.containsKey('images') && promotion['images'] is List) {
            final List<dynamic> images = promotion['images'] as List<dynamic>;
            for (var i = 0; i < images.length; i++) {
              if (images[i] is Map && images[i].containsKey('imageUrl')) {
                final String originalUrl = images[i]['imageUrl'] as String? ?? '';
                final String processedUrl = ImageUrlUtil.processImageUrl(originalUrl);
                images[i]['imageUrl'] = processedUrl;
                
                developer.log('处理活动图片URL: $originalUrl -> $processedUrl', 
                    name: 'PromotionApi');
              }
            }
          }
          
          processedPromotions.add(promotion);
        }
        
        developer.log('获取到 ${processedPromotions.length} 个促销活动', 
            name: 'PromotionApi');
        return processedPromotions;
      }

      developer.log('获取促销活动列表失败: ${response.message}', name: 'PromotionApi');
      return [];
    } catch (e) {
      developer.log('获取促销活动列表异常: $e', name: 'PromotionApi');
      return [];
    }
  }

  /// 获取促销活动详情
  /// [promotionId] 活动ID
  static Future<Map<String, dynamic>?> getPromotionDetail(
      int promotionId) async {
    try {
      final response =
          await HttpUtil().get('${Api.promotionDetail}/$promotionId');

      if (response.isSuccess && response.data != null) {
        return response.data as Map<String, dynamic>;
      }

      return null;
    } catch (e) {
      print('获取促销活动详情失败: $e');
      return null;
    }
  }
}
