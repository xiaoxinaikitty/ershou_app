import 'package:flutter/material.dart';
import 'dart:developer' as developer;
import '../config/theme.dart';
import '../network/api.dart';
import '../network/http_util.dart';
import '../utils/cart_manager.dart';

class ProductDetailPage extends StatefulWidget {
  final int productId;

  const ProductDetailPage({Key? key, required this.productId})
      : super(key: key);

  @override
  State<ProductDetailPage> createState() => _ProductDetailPageState();
}

class _ProductDetailPageState extends State<ProductDetailPage> {
  bool _isLoading = true;
  bool _isError = false;
  String _errorMessage = '';
  Map<String, dynamic>? _productData;

  @override
  void initState() {
    super.initState();
    _fetchProductDetail();
  }

  // 获取商品详情
  Future<void> _fetchProductDetail() async {
    setState(() {
      _isLoading = true;
      _isError = false;
      _errorMessage = '';
    });

    try {
      final response =
          await HttpUtil().get('${Api.productDetail}${widget.productId}');

      if (response.isSuccess && response.data != null) {
        setState(() {
          _productData = response.data as Map<String, dynamic>;
          _isLoading = false;
        });
        developer.log('获取商品详情成功: ${_productData?.toString()}',
            name: 'ProductDetailPage');
      } else {
        setState(() {
          _isLoading = false;
          _isError = true;
          _errorMessage = response.message ?? '获取商品详情失败';
        });
        developer.log('获取商品详情失败: ${response.message}',
            name: 'ProductDetailPage');
      }
    } catch (e) {
      setState(() {
        _isLoading = false;
        _isError = true;
        _errorMessage = '网络错误，请稍后再试';
      });
      developer.log('获取商品详情异常: $e', name: 'ProductDetailPage');
    }
  }

  // 添加商品到收藏
  Future<void> _addToFavorite() async {
    try {
      final response = await HttpUtil().post(
        Api.favoriteAdd,
        data: {'productId': widget.productId},
      );

      if (!mounted) return;

      if (response.isSuccess) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('已添加到收藏')),
        );
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(response.message ?? '添加收藏失败')),
        );
      }
    } catch (e) {
      developer.log('添加收藏异常: $e', name: 'ProductDetailPage');
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('网络错误，请稍后再试')),
      );
    }
  }

  // 创建订单（直接购买）
  Future<void> _createOrder() async {
    try {
      final response = await HttpUtil().post(
        Api.orderCreate,
        data: {
          'productId': widget.productId,
          'quantity': 1,
        },
      );

      if (!mounted) return;

      if (response.isSuccess) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('订单创建成功，前往支付')),
        );
        // TODO: 跳转到订单支付页面
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(response.message ?? '创建订单失败')),
        );
      }
    } catch (e) {
      developer.log('创建订单异常: $e', name: 'ProductDetailPage');
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('网络错误，请稍后再试')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return Scaffold(
        appBar: AppBar(
          title: const Text('商品详情'),
          elevation: 0,
        ),
        body: const Center(
          child: CircularProgressIndicator(),
        ),
      );
    }

    if (_isError) {
      return Scaffold(
        appBar: AppBar(
          title: const Text('商品详情'),
          elevation: 0,
        ),
        body: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Icon(Icons.error_outline, size: 60, color: Colors.grey),
              const SizedBox(height: 16),
              Text(_errorMessage, style: const TextStyle(color: Colors.grey)),
              const SizedBox(height: 24),
              ElevatedButton(
                onPressed: _fetchProductDetail,
                child: const Text('重新加载'),
              ),
            ],
          ),
        ),
      );
    }

    // 提取商品数据
    final title = _productData?['title'] as String? ?? '未命名商品';
    final price = _productData?['price'] ?? 0.0;
    final originalPrice = _productData?['originalPrice'] ?? 0.0;
    final description = _productData?['description'] as String? ?? '暂无描述';
    final conditionLevel = _productData?['conditionLevel'] as int? ?? 0;
    final location = _productData?['location'] as String? ?? '';
    final username = _productData?['username'] as String? ?? '未知用户';
    final createdTime = _productData?['createdTime'] as String? ?? '';
    final viewCount = _productData?['viewCount'] as int? ?? 0;

    // 处理图片URL
    List<String> imageUrls = [];
    if (_productData?['images'] != null) {
      final images = _productData?['images'] as List<dynamic>;
      imageUrls = images
          .map((img) {
            String url = img['url'] as String? ?? '';
            if (url.startsWith('http://localhost:8080')) {
              url = url.replaceFirst(
                  'http://localhost:8080', 'http://192.168.200.30:8080');
            } else if (url.startsWith('/files/')) {
              url = 'http://192.168.200.30:8080$url';
            }
            return url;
          })
          .toList()
          .cast<String>();
    } else if (_productData?['mainImageUrl'] != null) {
      String url = _productData?['mainImageUrl'] as String;
      if (url.startsWith('http://localhost:8080')) {
        url = url.replaceFirst(
            'http://localhost:8080', 'http://192.168.200.30:8080');
      } else if (url.startsWith('/files/')) {
        url = 'http://192.168.200.30:8080$url';
      }
      imageUrls.add(url);
    }

    return Scaffold(
      appBar: AppBar(
        title: const Text('商品详情'),
        elevation: 0,
        actions: [
          IconButton(
            icon: const Icon(Icons.share),
            onPressed: () {
              // 分享功能
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text('分享功能开发中')),
              );
            },
          ),
        ],
      ),
      body: Column(
        children: [
          // 主体内容（可滚动）
          Expanded(
            child: SingleChildScrollView(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // 商品图片轮播
                  AspectRatio(
                    aspectRatio: 1,
                    child: imageUrls.isNotEmpty
                        ? PageView.builder(
                            itemCount: imageUrls.length,
                            itemBuilder: (context, index) {
                              return Image.network(
                                imageUrls[index],
                                fit: BoxFit.cover,
                                errorBuilder: (context, error, stackTrace) {
                                  return Container(
                                    color: Colors.grey[300],
                                    child: const Icon(
                                      Icons.image_not_supported,
                                      size: 60,
                                      color: Colors.white,
                                    ),
                                  );
                                },
                              );
                            },
                          )
                        : Container(
                            color: Colors.grey[300],
                            child: const Icon(
                              Icons.image,
                              size: 60,
                              color: Colors.white,
                            ),
                          ),
                  ),

                  // 商品基本信息
                  Padding(
                    padding: const EdgeInsets.all(16.0),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            Expanded(
                              child: Text(
                                title,
                                style: const TextStyle(
                                  fontSize: 20,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 8),
                        Row(
                          children: [
                            Text(
                              '¥${price.toStringAsFixed(2)}',
                              style: TextStyle(
                                color: AppTheme.primaryColor,
                                fontWeight: FontWeight.bold,
                                fontSize: 24,
                              ),
                            ),
                            const SizedBox(width: 8),
                            if (originalPrice > 0 && originalPrice > price)
                              Text(
                                '¥${originalPrice.toStringAsFixed(2)}',
                                style: const TextStyle(
                                  decoration: TextDecoration.lineThrough,
                                  color: Colors.grey,
                                  fontSize: 16,
                                ),
                              ),
                          ],
                        ),
                        const SizedBox(height: 16),
                        Row(
                          children: [
                            const Icon(Icons.location_on,
                                size: 16, color: Colors.grey),
                            const SizedBox(width: 4),
                            Text(
                              location,
                              style: const TextStyle(color: Colors.grey),
                            ),
                            const Spacer(),
                            const Icon(Icons.remove_red_eye,
                                size: 16, color: Colors.grey),
                            const SizedBox(width: 4),
                            Text(
                              '$viewCount浏览',
                              style: const TextStyle(color: Colors.grey),
                            ),
                          ],
                        ),
                        const SizedBox(height: 8),
                        Row(
                          children: [
                            const Icon(Icons.access_time,
                                size: 16, color: Colors.grey),
                            const SizedBox(width: 4),
                            Text(
                              '发布时间: $createdTime',
                              style: const TextStyle(color: Colors.grey),
                            ),
                          ],
                        ),
                        const SizedBox(height: 8),
                        Row(
                          children: [
                            const Icon(Icons.person,
                                size: 16, color: Colors.grey),
                            const SizedBox(width: 4),
                            Text(
                              '发布者: $username',
                              style: const TextStyle(color: Colors.grey),
                            ),
                          ],
                        ),
                        const SizedBox(height: 16),
                        const Divider(),
                        const SizedBox(height: 16),

                        // 商品成色
                        Row(
                          children: [
                            const Text(
                              '商品成色: ',
                              style: TextStyle(
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                            Text('$conditionLevel成新'),
                          ],
                        ),
                        const SizedBox(height: 16),

                        // 商品描述
                        const Text(
                          '商品描述',
                          style: TextStyle(
                            fontWeight: FontWeight.bold,
                            fontSize: 16,
                          ),
                        ),
                        const SizedBox(height: 8),
                        Text(
                          description,
                          style: const TextStyle(
                            fontSize: 14,
                          ),
                        ),
                        const SizedBox(height: 100), // 底部留空，避免被底部按钮遮挡
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),

          // 底部固定操作栏
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            decoration: BoxDecoration(
              color: Colors.white,
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.05),
                  blurRadius: 10,
                  offset: const Offset(0, -5),
                ),
              ],
            ),
            child: Row(
              children: [
                // 收藏按钮
                IconButton(
                  icon: const Icon(Icons.favorite_border),
                  onPressed: _addToFavorite,
                  tooltip: '收藏',
                  color: Colors.grey,
                ),
                // 客服按钮
                IconButton(
                  icon: const Icon(Icons.message),
                  onPressed: () {
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(content: Text('联系客服功能开发中')),
                    );
                  },
                  tooltip: '联系客服',
                  color: Colors.grey,
                ),
                const SizedBox(width: 8),
                // 加入购物车按钮
                Expanded(
                  child: ElevatedButton(
                    onPressed: () async {
                      if (_productData != null) {
                        final result =
                            await CartManager.addToCart(_productData!);
                        if (!mounted) return;

                        if (result) {
                          ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(content: Text('已加入购物车')),
                          );

                          // 通知底部导航栏更新购物车数量
                          if (context.mounted) {
                            ScaffoldMessenger.of(context).hideCurrentSnackBar();
                            Navigator.pushNamed(context, '/');
                          }
                        } else {
                          ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(content: Text('加入购物车失败，请重试')),
                          );
                        }
                      } else {
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(content: Text('商品数据加载失败，请重试')),
                        );
                      }
                    },
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.orange,
                    ),
                    child: const Text('加入购物车'),
                  ),
                ),
                const SizedBox(width: 8),
                // 立即购买按钮
                Expanded(
                  child: ElevatedButton(
                    onPressed: _createOrder,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppTheme.primaryColor,
                    ),
                    child: const Text('立即购买'),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
