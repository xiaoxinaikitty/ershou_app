import 'package:flutter/material.dart';
import '../models/product_recommend.dart';
import '../utils/image_url_util.dart';
import '../pages/product_detail_page.dart';
import '../services/recommendation_service.dart';
import '../network/api.dart';
import 'dart:developer' as developer;

/// 推荐商品网格组件
class ProductRecommendationGrid extends StatelessWidget {
  final List<ProductRecommend> recommendations;
  final String title;
  final bool showRecommendationType;
  final VoidCallback? onRefresh;

  const ProductRecommendationGrid({
    Key? key,
    required this.recommendations,
    required this.title,
    this.showRecommendationType = false,
    this.onRefresh,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    if (recommendations.isEmpty) {
      return const SizedBox.shrink();
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 8.0),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                title,
                style: const TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                ),
              ),
              if (onRefresh != null)
                GestureDetector(
                  onTap: onRefresh,
                  child: const Icon(Icons.refresh, color: Colors.grey),
                ),
            ],
          ),
        ),
        GridView.builder(
          padding: const EdgeInsets.symmetric(horizontal: 8.0),
          physics: const NeverScrollableScrollPhysics(),
          shrinkWrap: true,
          gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
            crossAxisCount: 2,
            childAspectRatio: 0.75,
            crossAxisSpacing: 8.0,
            mainAxisSpacing: 8.0,
          ),
          itemCount: recommendations.length,
          itemBuilder: (context, index) {
            final recommendation = recommendations[index];
            return _buildProductItem(context, recommendation);
          },
        ),
      ],
    );
  }

  Widget _buildProductItem(BuildContext context, ProductRecommend product) {
    // 确保图片URL已处理过，但再处理一次以防万一
    String imageUrl = ImageUrlUtil.processImageUrl(product.mainImage);
    
    // 检测URL是否为示例URL或无效URL
    if (imageUrl.contains('example.com') || imageUrl.isEmpty) {
      // 使用默认图片替代
      imageUrl = '${Uri.parse(Api.baseUrl).origin}/images/default_product.png';
      developer.log('检测到示例URL，使用默认图片: $imageUrl', name: 'ProductRecommendationGrid');
    } else {
      // 调试日志
      developer.log('使用有效图片URL: $imageUrl', name: 'ProductRecommendationGrid');
    }

    return GestureDetector(
      onTap: () {
        // 记录点击行为
        _recordClick(product);

        // 跳转到商品详情页
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (context) => ProductDetailPage(
              productId: product.productId,
              mainImageUrl: imageUrl,
            ),
          ),
        );
      },
      child: Card(
        clipBehavior: Clip.antiAlias,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(10.0),
        ),
        elevation: 2.0,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // 商品图片
            Expanded(
              child: Stack(
                fit: StackFit.expand,
                children: [
                  Image.network(
                    imageUrl,
                    fit: BoxFit.cover,
                    errorBuilder: (context, error, stackTrace) {
                      developer.log('图片加载失败: $error, URL: $imageUrl', name: 'ProductRecommendationGrid');
                      // 尝试使用另一个默认图片或者显示占位符
                      return Container(
                        color: Colors.grey[200],
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(Icons.image_not_supported, color: Colors.grey[400], size: 32),
                            const SizedBox(height: 4),
                            Text(
                              product.title.substring(0, product.title.length > 10 ? 10 : product.title.length),
                              style: TextStyle(color: Colors.grey[600], fontSize: 10),
                              textAlign: TextAlign.center,
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                          ],
                        ),
                      );
                    },
                    loadingBuilder: (context, child, loadingProgress) {
                      if (loadingProgress == null) return child;
                      return const Center(
                        child: CircularProgressIndicator(),
                      );
                    },
                  ),
                  // 推荐类型标签
                  if (showRecommendationType)
                    Positioned(
                      top: 0,
                      right: 0,
                      child: Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 8.0,
                          vertical: 4.0,
                        ),
                        decoration: BoxDecoration(
                          color: _getRecommendationTypeColor(
                              product.recommendationType),
                          borderRadius: const BorderRadius.only(
                            bottomLeft: Radius.circular(10.0),
                          ),
                        ),
                        child: Text(
                          product.getRecommendationTypeName(),
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 12.0,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                    ),
                ],
              ),
            ),

            // 商品信息
            Padding(
              padding: const EdgeInsets.all(8.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    product.title,
                    style: const TextStyle(
                      fontSize: 14.0,
                      fontWeight: FontWeight.bold,
                    ),
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                  ),
                  const SizedBox(height: 4.0),
                  Row(
                    children: [
                      Text(
                        '¥${product.price.toStringAsFixed(2)}',
                        style: const TextStyle(
                          fontSize: 16.0,
                          color: Colors.red,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(width: 4.0),
                      if (product.originalPrice > product.price)
                        Text(
                          '¥${product.originalPrice.toStringAsFixed(2)}',
                          style: const TextStyle(
                            fontSize: 12.0,
                            color: Colors.grey,
                            decoration: TextDecoration.lineThrough,
                          ),
                        ),
                    ],
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  // 记录推荐点击
  void _recordClick(ProductRecommend product) {
    try {
      RecommendationService().recordRecommendationClick(
        product.productId,
        product.recommendationType,
      );
    } catch (e) {
      developer.log('记录推荐点击异常: $e', name: 'ProductRecommendationGrid');
    }
  }

  // 获取推荐类型对应的颜色
  Color _getRecommendationTypeColor(int recommendationType) {
    switch (recommendationType) {
      case 1: // 相似商品
        return Colors.blue;
      case 2: // 猜你喜欢
        return Colors.purple;
      case 3: // 热门推荐
        return Colors.red;
      case 4: // 新品推荐
        return Colors.green;
      default:
        return Colors.orange;
    }
  }
}
