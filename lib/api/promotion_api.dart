import '../network/http_util.dart';
import '../network/api.dart';

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

      final response =
          await HttpUtil().get(Api.promotionActive, params: params);

      if (response.isSuccess && response.data != null) {
        final List<dynamic> promotionList = response.data as List<dynamic>;
        return promotionList
            .map((item) => item as Map<String, dynamic>)
            .toList();
      }

      return [];
    } catch (e) {
      print('获取促销活动列表失败: $e');
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
