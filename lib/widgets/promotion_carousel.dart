import 'package:flutter/material.dart';
import 'package:carousel_slider/carousel_slider.dart';
import 'package:smooth_page_indicator/smooth_page_indicator.dart';
import 'dart:developer' as developer;
import 'dart:io';

import '../models/promotion.dart';
import '../api/promotion_api.dart';
import '../utils/image_url_util.dart';
import '../network/api.dart';

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

      developer.log('开始获取轮播图数据', name: 'PromotionCarousel');
      
      // 获取活动列表
      final promotionsData = await PromotionApi.getActivePromotions(limit: 5);

      developer.log('原始活动数据: ${promotionsData.length}个', name: 'PromotionCarousel');
      
      // 解析数据
      final promotions =
          promotionsData.map((data) => Promotion.fromJson(data)).toList();

      developer.log('解析后的活动: ${promotions.length}个', name: 'PromotionCarousel');
      
      // 记录每个活动的图片情况
      for (int i = 0; i < promotions.length; i++) {
        final promo = promotions[i];
        final carouselImages = promo.images.where((img) => img.imageType == 1).toList();
        developer.log('活动[$i] "${promo.title}": 共${promo.images.length}张图片，其中${carouselImages.length}张是轮播图', 
            name: 'PromotionCarousel');
        
        // 输出每张轮播图的URL
        for (int j = 0; j < carouselImages.length; j++) {
          developer.log('  轮播图[$j] URL: ${carouselImages[j].imageUrl}', 
              name: 'PromotionCarousel');
        }
      }

      // 筛选出有轮播图的活动
      final filteredPromotions = promotions.where((promo) {
        // 检查是否有图片，并且至少有一张是轮播图类型
        return promo.images.isNotEmpty &&
            promo.images.any((image) => image.imageType == 1);
      }).toList();

      developer.log('筛选后的活动: ${filteredPromotions.length}个有轮播图', 
          name: 'PromotionCarousel');

      if (mounted) {
        setState(() {
          _promotions = filteredPromotions;
          _isLoading = false;
        });

        // 如果没有轮播图数据，发送通知
        if (filteredPromotions.isEmpty && !_hasNotifiedEmpty) {
          _hasNotifiedEmpty = true;
          developer.log('没有轮播图数据，发送空通知', name: 'PromotionCarousel');
          Future.microtask(() {
            const CarouselEmptyNotification().dispatch(context);
          });
        }
      }
    } catch (e) {
      developer.log('获取促销活动异常: $e', name: 'PromotionCarousel');
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

    // 诊断当前轮播图状态
    _diagnosticCarouselItems();

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
                developer.log('跳转到: ${promotion.urlLink}', name: 'PromotionCarousel');
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
    // 使用ImageUrlUtil处理图片URL，确保与当前baseUrl一致
    String processedImageUrl = ImageUrlUtil.processImageUrl(imageUrl);
    
    // 添加一个标记指示是否是备用图片
    bool isUsingBackupImage = false;
    
    // 使用本地备用图片路径 - 在应用资源中应该包含这个图片
    const String backupImageAsset = 'assets/images/placeholder_promotion.png';
    
    developer.log('尝试加载轮播图: $processedImageUrl', name: 'PromotionCarousel');

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
            // 图片 - 使用FadeInImage支持渐变加载和本地占位图
            isUsingBackupImage 
              ? Image.asset(
                  backupImageAsset,
                  fit: BoxFit.cover,
                  width: double.infinity,
                  errorBuilder: (context, error, stackTrace) {
                    // 如果连备用图都加载失败，则显示纯色占位符
                    developer.log('备用图片也加载失败: $error', name: 'PromotionCarousel');
                    return Container(
                      color: Colors.grey[300],
                      width: double.infinity,
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          const Icon(Icons.image_not_supported, size: 40, color: Colors.grey),
                          const SizedBox(height: 8),
                          Text(title, 
                            style: const TextStyle(color: Colors.grey), 
                            textAlign: TextAlign.center,
                          ),
                        ],
                      ),
                    );
                  },
                )
              : FutureBuilder<bool>(
                  // 尝试预检图片是否可访问
                  future: _checkImageUrl(processedImageUrl),
                  builder: (context, snapshot) {
                    if (snapshot.connectionState == ConnectionState.waiting) {
                      return Container(
                        color: Colors.grey[200],
                        child: const Center(child: CircularProgressIndicator())
                      );
                    }
                    
                    final bool isImageAvailable = snapshot.data ?? false;
                    
                    if (!isImageAvailable) {
                      developer.log('预检图片不可用，使用备用图: $processedImageUrl', 
                          name: 'PromotionCarousel');
                      
                      // 如果图片不可用，使用备用图
                      return Image.asset(
                        backupImageAsset,
                        fit: BoxFit.cover,
                        width: double.infinity,
                        errorBuilder: (context, error, stackTrace) {
                          // 如果备用图也加载失败，显示纯色占位符
                          return Container(
                            color: Colors.grey[300],
                            child: const Center(
                              child: Icon(Icons.image_not_supported, size: 40, color: Colors.grey),
                            ),
                          );
                        },
                      );
                    }
                    
                    // 如果图片可用，使用网络图片
                    return Image.network(
                      processedImageUrl,
                      fit: BoxFit.cover,
                      width: double.infinity,
                      errorBuilder: (context, error, stackTrace) {
                        developer.log('轮播图加载错误: $error, URL: $processedImageUrl', 
                            name: 'PromotionCarousel');
                        // 发生错误时改用备用图
                        return Image.asset(
                          backupImageAsset,
                          fit: BoxFit.cover,
                          width: double.infinity,
                          errorBuilder: (context, error, stackTrace) {
                            // 备用图也失败时显示纯色占位符
                            return Container(
                              color: Colors.grey[300],
                              child: const Center(
                                child: Icon(Icons.image_not_supported, size: 40, color: Colors.grey),
                              ),
                            );
                          },
                        );
                      },
                      loadingBuilder: (context, child, loadingProgress) {
                        if (loadingProgress == null) return child;
                        return Container(
                          color: Colors.grey[200],
                          child: Center(
                            child: CircularProgressIndicator(
                              value: loadingProgress.expectedTotalBytes != null
                                  ? loadingProgress.cumulativeBytesLoaded /
                                      (loadingProgress.expectedTotalBytes ?? 1)
                                  : null,
                            ),
                          ),
                        );
                      },
                    );
                  }
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

  // 预检图片URL是否可访问
  Future<bool> _checkImageUrl(String url) async {
    try {
      developer.log('预检图片URL: $url', name: 'PromotionCarousel');
      
      // 使用简单的HEAD请求检查图片是否存在
      final Uri uri = Uri.parse(url);
      final client = HttpClient();
      
      try {
        final request = await client.headUrl(uri);
        final response = await request.close();
        final bool exists = response.statusCode == 200;
        developer.log('图片预检结果: ${exists ? "可用" : "不可用"} (状态码: ${response.statusCode})', 
            name: 'PromotionCarousel');
        client.close();
        return exists;
      } on SocketException {
        // 如果出现网络错误，可能是服务器不支持HEAD请求
        // 尝试GET请求获取部分数据
        developer.log('HEAD请求失败，尝试GET请求', name: 'PromotionCarousel');
        final request = await client.getUrl(uri);
        // 设置一个范围，只获取图片的前几个字节
        request.headers.set('Range', 'bytes=0-1024');
        final response = await request.close();
        final bool exists = response.statusCode == 200 || response.statusCode == 206;
        developer.log('图片GET预检结果: ${exists ? "可用" : "不可用"} (状态码: ${response.statusCode})', 
            name: 'PromotionCarousel');
        client.close();
        return exists;
      }
    } catch (e) {
      developer.log('图片预检异常: $e', name: 'PromotionCarousel');
      return false;
    }
  }

  // 诊断轮播图数据，帮助调试URL问题
  void _diagnosticCarouselItems() {
    developer.log('===== 轮播图诊断开始 =====', name: 'PromotionCarousel');
    developer.log('当前baseUrl: ${Api.baseUrl}', name: 'PromotionCarousel');
    developer.log('促销活动数量: ${_promotions.length}', name: 'PromotionCarousel');
    
    int totalCarouselImages = 0;
    
    for (int i = 0; i < _promotions.length; i++) {
      final promo = _promotions[i];
      final carouselImages = promo.images.where((img) => img.imageType == 1).toList();
      totalCarouselImages += carouselImages.length;
      
      developer.log('活动[$i] "${promo.title}": 轮播图${carouselImages.length}张', 
          name: 'PromotionCarousel');
      
      for (int j = 0; j < carouselImages.length; j++) {
        final String originalUrl = carouselImages[j].imageUrl;
        final String processedUrl = ImageUrlUtil.processImageUrl(originalUrl);
        
        developer.log('  轮播图[$j] 原始URL: $originalUrl', name: 'PromotionCarousel');
        developer.log('  轮播图[$j] 处理后URL: $processedUrl', name: 'PromotionCarousel');
        
        // 检查URL是否包含当前baseUrl
        if (!processedUrl.contains(Uri.parse(Api.baseUrl).host)) {
          developer.log('  ⚠️ 警告: URL不包含当前host(${Uri.parse(Api.baseUrl).host})',
              name: 'PromotionCarousel');
        }
      }
    }
    
    developer.log('轮播图总数: $totalCarouselImages', name: 'PromotionCarousel');
    developer.log('===== 轮播图诊断结束 =====', name: 'PromotionCarousel');
  }
}
