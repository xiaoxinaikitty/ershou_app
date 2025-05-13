import 'dart:async';
import '../api/recommendation_api.dart';
import '../models/product_recommend.dart';
import 'dart:developer' as developer;

/// 推荐服务类，用于管理推荐相关的业务逻辑
class RecommendationService {
  // 单例模式
  static final RecommendationService _instance =
      RecommendationService._internal();
  factory RecommendationService() => _instance;
  RecommendationService._internal();

  // 推荐缓存
  Map<String, List<ProductRecommend>> _recommendationCache = {};

  // 缓存有效期（分钟）
  static const int _cacheExpirationMinutes = 10;

  // 缓存时间戳
  Map<String, DateTime> _cacheTimes = {};

  // 记录用户浏览行为
  Future<void> recordViewBehavior(int productId, {int? stayTime}) async {
    await RecommendationApi.recordBehavior(
      productId: productId,
      behaviorType: 1, // 1-浏览
      stayTime: stayTime,
    );
  }

  // 记录用户收藏行为
  Future<void> recordFavoriteBehavior(int productId) async {
    await RecommendationApi.recordBehavior(
      productId: productId,
      behaviorType: 2, // 2-收藏
    );
  }

  // 记录用户加购行为
  Future<void> recordCartBehavior(int productId) async {
    await RecommendationApi.recordBehavior(
      productId: productId,
      behaviorType: 3, // 3-加购
    );
  }

  // 记录用户购买行为
  Future<void> recordPurchaseBehavior(int productId) async {
    await RecommendationApi.recordBehavior(
      productId: productId,
      behaviorType: 4, // 4-购买
    );
  }

  // 记录用户评价行为
  Future<void> recordRatingBehavior(int productId) async {
    await RecommendationApi.recordBehavior(
      productId: productId,
      behaviorType: 5, // 5-评价
    );
  }

  // 获取相似商品推荐
  Future<List<ProductRecommend>> getSimilarProducts(int productId,
      {int? limit}) async {
    final String cacheKey = 'similar_$productId';

    // 检查缓存是否有效
    if (_isCacheValid(cacheKey)) {
      developer.log('从缓存获取相似商品推荐', name: 'RecommendationService');
      return _recommendationCache[cacheKey]!;
    }

    // 从API获取数据
    final List<ProductRecommend> recommendations =
        await RecommendationApi.getSimilarProducts(productId, limit: limit);

    // 更新缓存
    _updateCache(cacheKey, recommendations);

    return recommendations;
  }

  // 获取个性化推荐
  Future<List<ProductRecommend>> getPersonalizedRecommendations(
      {int? limit}) async {
    const String cacheKey = 'personalized';

    // 个性化推荐不使用缓存，每次都从服务器获取最新数据
    final List<ProductRecommend> recommendations =
        await RecommendationApi.getPersonalizedRecommendations(limit: limit);

    return recommendations;
  }

  // 获取热门推荐
  Future<List<ProductRecommend>> getHotRecommendations({int? limit}) async {
    const String cacheKey = 'hot';

    // 检查缓存是否有效
    if (_isCacheValid(cacheKey)) {
      developer.log('从缓存获取热门推荐', name: 'RecommendationService');
      return _recommendationCache[cacheKey]!;
    }

    // 从API获取数据
    final List<ProductRecommend> recommendations =
        await RecommendationApi.getHotRecommendations(limit: limit);

    // 更新缓存
    _updateCache(cacheKey, recommendations);

    return recommendations;
  }

  // 记录推荐点击
  Future<void> recordRecommendationClick(
      int productId, int recommendationType) async {
    await RecommendationApi.recordRecommendationClick(
      productId: productId,
      type: recommendationType,
    );
  }

  // 检查缓存是否有效
  bool _isCacheValid(String cacheKey) {
    if (!_recommendationCache.containsKey(cacheKey) ||
        !_cacheTimes.containsKey(cacheKey)) {
      return false;
    }

    final DateTime cacheTime = _cacheTimes[cacheKey]!;
    final DateTime now = DateTime.now();

    // 检查缓存是否过期
    return now.difference(cacheTime).inMinutes < _cacheExpirationMinutes;
  }

  // 更新缓存
  void _updateCache(String cacheKey, List<ProductRecommend> data) {
    _recommendationCache[cacheKey] = data;
    _cacheTimes[cacheKey] = DateTime.now();
  }

  // 清除缓存
  void clearCache() {
    _recommendationCache.clear();
    _cacheTimes.clear();
  }
}
