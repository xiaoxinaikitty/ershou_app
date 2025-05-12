import 'package:flutter/material.dart';
import 'package:carousel_slider/carousel_slider.dart';
import 'package:smooth_page_indicator/smooth_page_indicator.dart';

import '../models/promotion.dart';
import '../api/promotion_api.dart';

// 自定义通知类，用于告知父组件轮播图为空
class CarouselEmptyNotification extends Notification {
  const CarouselEmptyNotification();
}

class PromotionCarousel extends StatefulWidget {
  const PromotionCarousel({Key? key}) : super(key: key);

  @override
  State<PromotionCarousel> createState() => _PromotionCarouselState();
}

class _PromotionCarouselState extends State<PromotionCarousel> {
  List<Promotion> _promotions = [];
  bool _isLoading = true;
  int _activeIndex = 0;
  final CarouselSliderController _carouselController =
      CarouselSliderController();
  bool _hasNotifiedEmpty = false;

  @override
  void initState() {
    super.initState();
    _fetchPromotions();
  }

  // 获取促销活动
  Future<void> _fetchPromotions() async {
    try {
      setState(() {
        _isLoading = true;
      });

      // 获取活动列表
      final promotionsData = await PromotionApi.getActivePromotions(limit: 5);

      // 解析数据
      final promotions =
          promotionsData.map((data) => Promotion.fromJson(data)).toList();

      // 筛选出有轮播图的活动
      final filteredPromotions = promotions.where((promo) {
        // 检查是否有图片，并且至少有一张是轮播图类型
        return promo.images.isNotEmpty &&
            promo.images.any((image) => image.imageType == 1);
      }).toList();

      if (mounted) {
        setState(() {
          _promotions = filteredPromotions;
          _isLoading = false;
        });

        // 如果没有轮播图数据，发送通知
        if (filteredPromotions.isEmpty && !_hasNotifiedEmpty) {
          _hasNotifiedEmpty = true;
          Future.microtask(() {
            const CarouselEmptyNotification().dispatch(context);
          });
        }
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _promotions = [];
          _isLoading = false;
        });

        // 发生错误时也发送通知
        if (!_hasNotifiedEmpty) {
          _hasNotifiedEmpty = true;
          Future.microtask(() {
            const CarouselEmptyNotification().dispatch(context);
          });
        }
      }
      print('获取促销活动失败: $e');
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return const SizedBox(
        height: 160,
        child: Center(
          child: CircularProgressIndicator(),
        ),
      );
    }

    if (_promotions.isEmpty) {
      // 如果没有活动，返回空容器
      return const SizedBox.shrink();
    }

    // 提取所有轮播图
    List<Widget> carouselItems = [];
    for (var promotion in _promotions) {
      // 从每个活动中提取轮播图
      final carouselImages =
          promotion.images.where((image) => image.imageType == 1).toList();

      for (var image in carouselImages) {
        carouselItems.add(
          GestureDetector(
            onTap: () {
              // 处理点击事件，如果有链接则跳转
              if (promotion.urlLink != null && promotion.urlLink!.isNotEmpty) {
                // 在这里实现跳转逻辑
                print('跳转到: ${promotion.urlLink}');
                // 可以根据链接格式决定跳转到不同的页面
              }
            },
            child: _buildCarouselItem(image.imageUrl, promotion.title),
          ),
        );
      }
    }

    return Column(
      children: [
        CarouselSlider(
          carouselController: _carouselController,
          options: CarouselOptions(
            height: 160.0,
            aspectRatio: 16 / 9,
            viewportFraction: 0.9,
            initialPage: 0,
            enableInfiniteScroll: carouselItems.length > 1,
            reverse: false,
            autoPlay: carouselItems.length > 1,
            autoPlayInterval: const Duration(seconds: 5),
            autoPlayAnimationDuration: const Duration(milliseconds: 800),
            autoPlayCurve: Curves.fastOutSlowIn,
            enlargeCenterPage: true,
            scrollDirection: Axis.horizontal,
            onPageChanged: (index, reason) {
              // 更新指示器位置
              if (mounted) {
                setState(() {
                  _activeIndex = index;
                });
              }
            },
          ),
          items: carouselItems,
        ),
        if (carouselItems.length > 1)
          Padding(
            padding: const EdgeInsets.only(top: 8.0),
            child: AnimatedSmoothIndicator(
              activeIndex: _activeIndex,
              count: carouselItems.length,
              effect: const WormEffect(
                dotWidth: 8.0,
                dotHeight: 8.0,
                activeDotColor: Colors.blue,
                dotColor: Colors.grey,
              ),
            ),
          ),
      ],
    );
  }

  Widget _buildCarouselItem(String imageUrl, String title) {
    String processedImageUrl = imageUrl;
    if (imageUrl.startsWith('http://localhost:8080')) {
      processedImageUrl = imageUrl.replaceFirst(
          'http://localhost:8080', 'http://192.168.200.30:8080');
    }

    return Container(
      width: MediaQuery.of(context).size.width,
      margin: const EdgeInsets.symmetric(horizontal: 5.0),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(10.0),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.2),
            spreadRadius: 1,
            blurRadius: 5,
            offset: const Offset(0, 3),
          ),
        ],
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(10.0),
        child: Stack(
          children: [
            // 图片
            Image.network(
              processedImageUrl,
              fit: BoxFit.cover,
              width: double.infinity,
              errorBuilder: (context, error, stackTrace) {
                return Container(
                  color: Colors.grey[200],
                  child: const Center(
                    child: Icon(Icons.error_outline, size: 40),
                  ),
                );
              },
            ),

            // 底部标题栏
            Positioned(
              bottom: 0,
              left: 0,
              right: 0,
              child: Container(
                padding: const EdgeInsets.symmetric(
                  vertical: 8.0,
                  horizontal: 16.0,
                ),
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.bottomCenter,
                    end: Alignment.topCenter,
                    colors: [
                      Colors.black.withOpacity(0.7),
                      Colors.transparent,
                    ],
                  ),
                ),
                child: Text(
                  title,
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 16.0,
                    fontWeight: FontWeight.bold,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
