import 'package:flutter/material.dart';
import 'dart:developer' as developer;
import '../config/theme.dart';
import '../network/api.dart';
import '../network/http_util.dart';
import '../utils/cart_manager.dart';
import '../utils/image_url_util.dart'; // 引入图片URL处理工具类
import 'chat/message_page.dart'; // 导入消息页面
import 'order/create_order_page.dart'; // 导入创建订单页面
import '../models/product_recommend.dart';
import '../services/recommendation_service.dart';
import '../widgets/product_recommendation_grid.dart';
import 'dart:async';
import '../utils/behavior_tracker.dart';

class ProductDetailPage extends StatefulWidget {
  final int productId;
  final String? mainImageUrl; // 添加主图URL参数

  const ProductDetailPage({
    Key? key,
    required this.productId,
    this.mainImageUrl, // 添加主图URL参数
  }) : super(key: key);

  @override
  State<ProductDetailPage> createState() => _ProductDetailPageState();
}

class _ProductDetailPageState extends State<ProductDetailPage> {
  bool _isLoading = true;
  bool _isError = false;
  String _errorMessage = '';
  Map<String, dynamic>? _productData;
  List<String> _imageUrls = [];
  bool _isFavorite = false; // 添加收藏状态标记

  // 相似商品推荐
  List<ProductRecommend> _similarProducts = [];
  bool _loadingSimilarProducts = false;

  // 计时器，用于记录页面停留时间
  DateTime? _enterTime;
  Timer? _stayTimeTimer;

  @override
  void initState() {
    super.initState();
    // 如果有传入的主图URL，先添加到图片列表
    if (widget.mainImageUrl != null && widget.mainImageUrl!.isNotEmpty) {
      String url = ImageUrlUtil.processImageUrl(widget.mainImageUrl);
      developer.log('处理后的主图URL: $url', name: 'ProductDetailPage');

      if (url.isNotEmpty) {
        _imageUrls.add(url);
        developer.log('添加主图URL到列表: $url', name: 'ProductDetailPage');
      }
    }
    _fetchProductDetail();
    _checkFavoriteStatus(); // 新增：检查收藏状态

    // 记录进入页面的时间
    _enterTime = DateTime.now();

    // 记录浏览行为，不包含停留时间
    _recordViewBehavior();

    // 加载相似商品推荐
    _fetchSimilarProducts();

    // 启动定期记录停留时间的计时器
    _stayTimeTimer = Timer.periodic(const Duration(seconds: 30), (timer) {
      // 每30秒更新一次停留时间
      _updateStayTime();
    });
  }

  @override
  void dispose() {
    // 页面关闭时记录最后一次停留时间
    _updateStayTime();

    // 取消计时器
    _stayTimeTimer?.cancel();

    super.dispose();
  }

  // 记录浏览行为
  Future<void> _recordViewBehavior({int? stayTime}) async {
    try {
      await RecommendationService().recordViewBehavior(
        widget.productId,
        stayTime: stayTime,
      );
      developer.log('记录浏览行为成功', name: 'ProductDetailPage');
    } catch (e) {
      developer.log('记录浏览行为异常: $e', name: 'ProductDetailPage');
    }
  }

  // 更新停留时间
  void _updateStayTime() {
    if (_enterTime != null) {
      final DateTime now = DateTime.now();
      final int stayTimeSeconds = now.difference(_enterTime!).inSeconds;

      // 更新浏览行为，包含停留时间
      _recordViewBehavior(stayTime: stayTimeSeconds);

      developer.log('更新停留时间: $stayTimeSeconds秒', name: 'ProductDetailPage');
    }
  }

  // 获取相似商品推荐
  Future<void> _fetchSimilarProducts() async {
    setState(() {
      _loadingSimilarProducts = true;
    });

    try {
      final recommendations = await RecommendationService().getSimilarProducts(
        widget.productId,
        limit: 6,
      );

      setState(() {
        _similarProducts = recommendations;
        _loadingSimilarProducts = false;
      });

      developer.log('获取相似商品推荐成功: ${_similarProducts.length}条数据',
          name: 'ProductDetailPage');
    } catch (e) {
      setState(() {
        _loadingSimilarProducts = false;
      });
      developer.log('获取相似商品推荐异常: $e', name: 'ProductDetailPage');
    }
  }

  // 获取商品详情
  Future<void> _fetchProductDetail() async {
    setState(() {
      _isLoading = true;
      _isError = false;
      _errorMessage = '';
    });

    try {
      // 获取商品详情
      final detailResponse =
          await HttpUtil().get('${Api.productDetail}${widget.productId}');

      if (detailResponse.isSuccess && detailResponse.data != null) {
        setState(() {
          _productData = detailResponse.data as Map<String, dynamic>;
        });
        developer.log('获取商品详情成功: ${_productData?.toString()}',
            name: 'ProductDetailPage');

        // 获取商品图片列表
        try {
          final imageResponse =
              await HttpUtil().get('${Api.imageList}${widget.productId}');
          developer.log('图片列表API响应: ${imageResponse.toString()}',
              name: 'ProductDetailPage');

          if (imageResponse.isSuccess && imageResponse.data != null) {
            final images = imageResponse.data as List<dynamic>;
            developer.log('解析到的图片数据: $images', name: 'ProductDetailPage');

            setState(() {
              _imageUrls = images
                  .map((img) {
                    String url = img['url'] as String? ?? '';
                    developer.log('原始图片URL: $url', name: 'ProductDetailPage');

                    // 使用工具类处理URL
                    url = ImageUrlUtil.processImageUrl(url);
                    developer.log('处理后的图片URL: $url', name: 'ProductDetailPage');

                    return url;
                  })
                  .where((url) => url.isNotEmpty)
                  .toList();
            });
          } else {
            developer.log('图片列表API失败，尝试从商品详情获取图片', name: 'ProductDetailPage');
            // 从商品详情中获取图片
            if (_productData?['mainImageUrl'] != null) {
              String url = ImageUrlUtil.processImageUrl(
                  _productData?['mainImageUrl'] as String);
              if (url.isNotEmpty) {
                _imageUrls.add(url);
              }
            }
          }

          setState(() {
            _isLoading = false;
            if (_imageUrls.isEmpty) {
              _isError = true;
              _errorMessage = '该商品暂无图片';
            }
          });
          developer.log('最终图片URL列表: $_imageUrls', name: 'ProductDetailPage');
        } catch (e) {
          setState(() {
            _isLoading = false;
            _isError = true;
            _errorMessage = '获取商品图片异常: $e';
          });
          developer.log('获取商品图片异常: $e', name: 'ProductDetailPage');
        }
      } else {
        setState(() {
          _isLoading = false;
          _isError = true;
          _errorMessage = detailResponse.message ?? '获取商品详情失败';
        });
        developer.log('获取商品详情失败: ${detailResponse.message}',
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

  // 新增：检查是否已收藏
  Future<void> _checkFavoriteStatus() async {
    try {
      final response =
          await HttpUtil().get('${Api.favoriteCheck}${widget.productId}');

      if (response.isSuccess && response.data != null) {
        final Map<String, dynamic> result =
            response.data as Map<String, dynamic>;
        setState(() {
          _isFavorite = result['isFavorite'] as bool? ?? false;
        });
        developer.log('检查收藏状态结果: $_isFavorite', name: 'ProductDetailPage');
      } else {
        developer.log('检查收藏状态失败: ${response.message}',
            name: 'ProductDetailPage');
      }
    } catch (e) {
      developer.log('检查收藏状态异常: $e', name: 'ProductDetailPage');
    }
  }

  // 添加或取消收藏
  Future<void> _addToFavorite() async {
    try {
      if (_isFavorite) {
        // 取消收藏
        final response =
            await HttpUtil().delete('${Api.favoriteCancel}${widget.productId}');

        if (!mounted) return;

        if (response.isSuccess) {
          setState(() {
            _isFavorite = false;
          });
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('已取消收藏')),
          );
        } else {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text(response.message ?? '取消收藏失败')),
          );
        }
      } else {
        // 添加收藏
        final response = await HttpUtil().post(
          Api.favoriteAdd,
          data: {'productId': widget.productId},
        );

        if (!mounted) return;

        if (response.isSuccess) {
          setState(() {
            _isFavorite = true;
          });

          // 记录收藏行为
          RecommendationService().recordFavoriteBehavior(widget.productId);

          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('已添加到收藏')),
          );
        } else {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text(response.message ?? '添加收藏失败')),
          );
        }
      }
    } catch (e) {
      developer.log('收藏操作异常: $e', name: 'ProductDetailPage');
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('网络错误，请稍后再试')),
      );
    }
  }

  // 创建订单（直接购买）
  Future<void> _createOrder() async {
    if (_productData == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('商品数据加载失败，请重试')),
      );
      return;
    }

    // 获取所需数据
    final int productId = _productData!['productId'] as int;
    final String productTitle = _productData!['title'] as String;
    final double price = _productData!['price'] as double;
    final int sellerId = _productData!['userId'] as int;

    // 获取商品图片
    String imageUrl = '';
    if (_imageUrls.isNotEmpty) {
      imageUrl = _imageUrls[0];
    } else if (_productData!['mainImageUrl'] != null) {
      imageUrl =
          ImageUrlUtil.processImageUrl(_productData!['mainImageUrl'] as String);
    }

    // 跳转到订单创建页面
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => CreateOrderPage(
          productId: productId,
          productTitle: productTitle,
          price: price,
          imageUrl: imageUrl,
          sellerId: sellerId,
        ),
      ),
    );
  }

  // 联系客服（联系商品发布者）
  void _contactSeller() {
    if (_productData == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('商品信息加载失败，请重试')),
      );
      return;
    }

    final int sellerId = _productData!['userId'] as int? ?? 0;
    final String sellerName = _productData!['username'] as String? ?? '卖家';
    final String productTitle = _productData!['title'] as String? ?? '商品详情';
    String productImage = '';

    if (_imageUrls.isNotEmpty) {
      productImage = _imageUrls[0];
    } else if (_productData!['mainImageUrl'] != null) {
      productImage = ImageUrlUtil.processImageUrl(
          _productData!['mainImageUrl'] as String?);
    }

    if (sellerId <= 0) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('无法获取卖家信息，请重试')),
      );
      return;
    }

    // 跳转到消息页面
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => MessagePage(
          productId: widget.productId,
          receiverId: sellerId,
          productTitle: productTitle,
          receiverName: sellerName,
          productImage: productImage,
        ),
      ),
    );
  }

  // 举报商品
  Future<void> _reportProduct(int reportType, String reportContent) async {
    try {
      final response = await HttpUtil().post(
        Api.reportAdd,
        data: {
          'productId': widget.productId,
          'reportType': reportType,
          'reportContent': reportContent,
        },
      );

      if (!mounted) return;

      if (response.isSuccess) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('举报成功，平台将会进行核实')),
        );
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(response.message ?? '举报失败，请稍后再试')),
        );
      }
    } catch (e) {
      developer.log('举报商品异常: $e', name: 'ProductDetailPage');
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('网络错误，请稍后再试')),
      );
    }
  }

  // 显示举报对话框
  void _showReportDialog() {
    int selectedType = 1; // 默认选择：虚假商品
    final TextEditingController contentController = TextEditingController();

    showDialog(
      context: context,
      builder: (context) {
        return StatefulBuilder(builder: (context, setState) {
          return AlertDialog(
            title: const Text('举报商品'),
            content: SingleChildScrollView(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text('请选择举报类型:'),
                  const SizedBox(height: 8),

                  // 举报类型选项
                  RadioListTile<int>(
                    title: const Text('虚假商品'),
                    value: 1,
                    groupValue: selectedType,
                    onChanged: (value) {
                      setState(() {
                        selectedType = value!;
                      });
                    },
                  ),
                  RadioListTile<int>(
                    title: const Text('违禁品'),
                    value: 2,
                    groupValue: selectedType,
                    onChanged: (value) {
                      setState(() {
                        selectedType = value!;
                      });
                    },
                  ),
                  RadioListTile<int>(
                    title: const Text('侵权'),
                    value: 3,
                    groupValue: selectedType,
                    onChanged: (value) {
                      setState(() {
                        selectedType = value!;
                      });
                    },
                  ),
                  RadioListTile<int>(
                    title: const Text('其他'),
                    value: 4,
                    groupValue: selectedType,
                    onChanged: (value) {
                      setState(() {
                        selectedType = value!;
                      });
                    },
                  ),

                  const SizedBox(height: 16),
                  const Text('举报说明:'),
                  const SizedBox(height: 8),
                  TextField(
                    controller: contentController,
                    decoration: const InputDecoration(
                      hintText: '请详细描述举报原因',
                      border: OutlineInputBorder(),
                    ),
                    maxLines: 3,
                  ),
                ],
              ),
            ),
            actions: [
              TextButton(
                onPressed: () {
                  Navigator.of(context).pop();
                },
                child: const Text('取消'),
              ),
              TextButton(
                onPressed: () {
                  if (contentController.text.trim().isEmpty) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(content: Text('请填写举报说明')),
                    );
                    return;
                  }

                  _reportProduct(selectedType, contentController.text.trim());
                  Navigator.of(context).pop();
                },
                child: const Text('提交'),
              ),
            ],
          );
        });
      },
    );
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

    return WillPopScope(
      onWillPop: () async {
        // 返回时更新购物车中的图片URL
        String currentImageUrl =
            _imageUrls.isNotEmpty ? _imageUrls[0] : widget.mainImageUrl ?? '';
        if (currentImageUrl.isNotEmpty) {
          // 确保URL是经过处理的
          currentImageUrl = ImageUrlUtil.processImageUrl(currentImageUrl);
          await CartManager.updateImageUrl(widget.productId, currentImageUrl);
        }
        Navigator.of(context).pop(currentImageUrl);
        return false;
      },
      child: Scaffold(
        appBar: AppBar(
          title: const Text('商品详情'),
          elevation: 0,
          actions: [
            IconButton(
              icon: const Icon(Icons.report_outlined),
              onPressed: () {
                _showReportDialog();
              },
              tooltip: '举报商品',
            ),
          ],
        ),
        body: SingleChildScrollView(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // 商品图片轮播
              AspectRatio(
                aspectRatio: 1,
                child: _imageUrls.isNotEmpty
                    ? PageView.builder(
                        itemCount: _imageUrls.length,
                        itemBuilder: (context, index) {
                          return Image.network(
                            _imageUrls[index],
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
                        const Icon(Icons.person, size: 16, color: Colors.grey),
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
                    const SizedBox(height: 16.0),

                    // 相似商品推荐部分
                    if (_similarProducts.isNotEmpty)
                      ProductRecommendationGrid(
                        recommendations: _similarProducts,
                        title: '相似商品推荐',
                        showRecommendationType: false,
                        onRefresh: _fetchSimilarProducts,
                      ),

                    if (_loadingSimilarProducts)
                      const Padding(
                        padding: EdgeInsets.all(16.0),
                        child: Center(child: CircularProgressIndicator()),
                      ),

                    const SizedBox(height: 50.0), // 底部空间，避免底部操作栏遮挡
                  ],
                ),
              ),
            ],
          ),
        ),

        // 底部固定操作栏
        bottomNavigationBar: Container(
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
                icon: Icon(
                  _isFavorite ? Icons.favorite : Icons.favorite_border,
                  color: _isFavorite ? Colors.red : Colors.grey,
                ),
                onPressed: _addToFavorite,
                tooltip: _isFavorite ? '取消收藏' : '收藏',
              ),
              // 客服按钮
              IconButton(
                icon: const Icon(Icons.message),
                onPressed: _contactSeller,
                tooltip: '联系客服',
                color: Colors.grey,
              ),
              const SizedBox(width: 8),
              // 加入购物车按钮
              Expanded(
                child: ElevatedButton(
                  onPressed: () async {
                    if (_productData != null) {
                      // 确保有图片URL
                      String mainImageUrl = '';
                      if (_imageUrls.isNotEmpty) {
                        mainImageUrl = _imageUrls[0]; // 使用第一张图片作为主图
                      } else if (_productData!['mainImageUrl'] != null) {
                        mainImageUrl = ImageUrlUtil.processImageUrl(
                            _productData!['mainImageUrl'] as String);
                      }

                      // 创建要添加到购物车的数据
                      final cartData = {
                        'productId': _productData!['productId'],
                        'title': _productData!['title'],
                        'price': _productData!['price'],
                        'mainImageUrl': mainImageUrl,
                      };

                      developer.log('添加到购物车的数据: $cartData',
                          name: 'ProductDetailPage');
                      final result = await CartManager.addToCart(cartData);

                      if (!mounted) return;

                      if (result) {
                        // 记录加购行为
                        await BehaviorTracker.trackAddToCart(
                            _productData!['productId'] as int);

                        // 获取更新后的购物车数量
                        final count = await CartManager.getCartItemCount();
                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(
                            content: Text('已加入购物车 (${count}件)'),
                            duration: const Duration(seconds: 2),
                          ),
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
      ),
    );
  }
}
