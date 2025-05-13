import 'dart:developer' as developer;
import '../services/recommendation_service.dart';

/// 行为追踪工具类，用于记录用户与商品的交互行为
class BehaviorTracker {
  // 私有构造函数
  BehaviorTracker._();

  /// 记录加购行为
  static Future<void> trackAddToCart(int productId) async {
    try {
      await RecommendationService().recordCartBehavior(productId);
      developer.log('成功记录加购行为: 商品ID=$productId', name: 'BehaviorTracker');
    } catch (e) {
      developer.log('记录加购行为异常: $e', name: 'BehaviorTracker');
    }
  }

  /// 记录购买行为
  static Future<void> trackPurchase(int productId) async {
    try {
      await RecommendationService().recordPurchaseBehavior(productId);
      developer.log('成功记录购买行为: 商品ID=$productId', name: 'BehaviorTracker');
    } catch (e) {
      developer.log('记录购买行为异常: $e', name: 'BehaviorTracker');
    }
  }

  /// 记录评价行为
  static Future<void> trackRating(int productId) async {
    try {
      await RecommendationService().recordRatingBehavior(productId);
      developer.log('成功记录评价行为: 商品ID=$productId', name: 'BehaviorTracker');
    } catch (e) {
      developer.log('记录评价行为异常: $e', name: 'BehaviorTracker');
    }
  }
}
