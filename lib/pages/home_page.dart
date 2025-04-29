import 'package:flutter/material.dart';
import 'dart:developer' as developer;
import '../config/theme.dart';
import '../network/api.dart';
import '../network/http_util.dart';
import '../utils/cart_manager.dart'; // 引入购物车管理工具类
import 'product_detail_page.dart'; // 假设有这个页面用于查看商品详情
import 'search_page.dart'; // 导入搜索页面

class HomePage extends StatefulWidget {
  const HomePage({Key? key}) : super(key: key);

  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  final List<Map<String, dynamic>> _products = [];
  bool _isLoading = true;
  bool _isError = false;
  String _errorMessage = '';

  // 分页相关参数
  int _pageNum = 1;
  final int _pageSize = 10;
  int _totalPages = 1;
  bool _hasMoreData = true;
  bool _isLoadingMore = false;
  final ScrollController _scrollController = ScrollController();

  // 当前用户ID，用于排除自己发布的商品
  int? _currentUserId;

  @override
  void initState() {
    super.initState();
    // 设置滚动监听，用于实现上拉加载更多
    _scrollController.addListener(_scrollListener);
    _getCurrentUserId();
  }

  @override
  void dispose() {
    _scrollController.removeListener(_scrollListener);
    _scrollController.dispose();
    super.dispose();
  }

  // 滚动监听，用于实现上拉加载更多
  void _scrollListener() {
    if (_scrollController.position.pixels >=
        _scrollController.position.maxScrollExtent - 200) {
      // 距离底部200像素时触发加载更多
      if (!_isLoadingMore && _hasMoreData && !_isLoading) {
        _loadMoreProducts();
      }
    }
  }

  // 获取当前用户信息，主要是获取用户ID
  Future<void> _getCurrentUserId() async {
    try {
      final response = await HttpUtil().get(Api.userInfo);
      if (response.isSuccess && response.data != null) {
        final userInfo = response.data as Map<String, dynamic>;
        _currentUserId = userInfo['userId'] as int?;
        developer.log('获取当前用户ID成功: $_currentUserId', name: 'HomePage');
      }
    } catch (e) {
      developer.log('获取当前用户信息异常: $e', name: 'HomePage');
    } finally {
      // 无论是否获取到用户ID，都加载商品列表
      _fetchRecommendedProducts(isRefresh: true);
    }
  }

  // 获取推荐商品列表
  Future<void> _fetchRecommendedProducts({bool isRefresh = false}) async {
    if (isRefresh) {
      setState(() {
        _isLoading = true;
        _isError = false;
        _errorMessage = '';
        _pageNum = 1;
        _hasMoreData = true;
      });
    }

    try {
      // 构建查询参数
      final Map<String, dynamic> params = {
        'pageNum': _pageNum,
        'pageSize': _pageSize,
        'status': 1, // 只显示在售商品
        'sortField': 'time', // 按时间排序
        'sortOrder': 'desc', // 降序，最新的在前面
      };

      // 获取推荐商品列表
      final response = await HttpUtil().get(Api.productList, params: params);

      if (response.isSuccess && response.data != null) {
        final data = response.data as Map<String, dynamic>;
        final List<dynamic> productList = data['list'] ?? [];
        final int totalPages = data['pages'] ?? 1;
        final bool hasNext = data['hasNext'] ?? false;

        setState(() {
          if (isRefresh) {
            _products.clear();
          }

          // 添加除了自己发布以外的所有商品
          for (var product in productList) {
            final Map<String, dynamic> productData =
                product as Map<String, dynamic>;
            final int sellerId = productData['userId'] as int? ?? 0;

            // 排除自己发布的商品
            if (_currentUserId == null || sellerId != _currentUserId) {
              _products.add(productData);
            }
          }

          _totalPages = totalPages;
          _hasMoreData = hasNext;
          _isLoading = false;
          _isLoadingMore = false;
        });

        developer.log(
            '获取推荐商品列表成功: ${_products.length}条数据，当前页码: $_pageNum, 总页数: $_totalPages',
            name: 'HomePage');
      } else {
        setState(() {
          _isLoading = false;
          _isLoadingMore = false;
          _isError = isRefresh; // 只有刷新时才显示错误
          _errorMessage = response.message ?? '获取推荐商品失败';
        });
        developer.log('获取推荐商品失败: ${response.message}', name: 'HomePage');
      }
    } catch (e) {
      setState(() {
        _isLoading = false;
        _isLoadingMore = false;
        _isError = isRefresh; // 只有刷新时才显示错误
        _errorMessage = '网络错误，请稍后再试';
      });
      developer.log('获取推荐商品异常: $e', name: 'HomePage');
    }
  }

  // 加载更多商品
  Future<void> _loadMoreProducts() async {
    if (_pageNum < _totalPages) {
      setState(() {
        _pageNum++;
        _isLoadingMore = true;
      });
      await _fetchRecommendedProducts();
    } else {
      setState(() {
        _hasMoreData = false;
      });
    }
  }

  // 添加商品到收藏
  Future<void> _addToFavorite(int productId) async {
    try {
      final response = await HttpUtil().post(
        Api.favoriteAdd,
        data: {'productId': productId},
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
      developer.log('添加收藏异常: $e', name: 'HomePage');
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('网络错误，请稍后再试')),
      );
    }
  }

  // 创建订单（直接购买）
  Future<void> _createOrder(int productId) async {
    try {
      final response = await HttpUtil().post(
        Api.orderCreate,
        data: {
          'productId': productId,
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
      developer.log('创建订单异常: $e', name: 'HomePage');
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('网络错误，请稍后再试')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('闲转', style: TextStyle(fontWeight: FontWeight.bold)),
        elevation: 0,
        actions: [
          IconButton(
            icon: const Icon(Icons.search),
            onPressed: () {
              // 跳转到搜索页面
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) => const SearchPage(),
                ),
              );
            },
          ),
          IconButton(
            icon: const Icon(Icons.notifications_none),
            onPressed: () {
              // 实现通知功能
            },
          ),
        ],
      ),
      body: RefreshIndicator(
        onRefresh: () => _fetchRecommendedProducts(isRefresh: true),
        child: ListView(
          controller: _scrollController,
          padding: const EdgeInsets.all(16.0),
          children: [
            // 搜索框
            GestureDetector(
              onTap: () {
                // 点击跳转到搜索页面
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) => const SearchPage(),
                  ),
                );
              },
              child: Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                decoration: BoxDecoration(
                  color: Colors.grey[200],
                  borderRadius: BorderRadius.circular(20),
                ),
                child: const Row(
                  children: [
                    Icon(Icons.search, color: Colors.grey),
                    SizedBox(width: 8),
                    Text('搜索您想要的宝贝', style: TextStyle(color: Colors.grey)),
                  ],
                ),
              ),
            ),

            const SizedBox(height: 20),

            // 分类区域
            _buildCategorySection(),

            const SizedBox(height: 20),

            // 推荐商品区域
            _buildRecommendedProductsSection(),

            // 加载更多指示器
            if (_isLoadingMore)
              const Center(
                child: Padding(
                  padding: EdgeInsets.all(16.0),
                  child: CircularProgressIndicator(),
                ),
              ),
          ],
        ),
      ),
    );
  }

  Widget _buildCategorySection() {
    final categories = [
      {'icon': Icons.phone_android, 'name': '手机数码'},
      {'icon': Icons.laptop, 'name': '电脑办公'},
      {'icon': Icons.tv, 'name': '家用电器'},
      {'icon': Icons.directions_bike, 'name': '运动户外'},
      {'icon': Icons.watch, 'name': '服饰鞋包'},
      {'icon': Icons.child_care, 'name': '母婴玩具'},
      {'icon': Icons.local_dining, 'name': '生活用品'},
      {'icon': Icons.more_horiz, 'name': '更多分类'},
    ];

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          '分类浏览',
          style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
        ),
        const SizedBox(height: 10),
        GridView.builder(
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
            crossAxisCount: 4,
            childAspectRatio: 1.0,
            mainAxisSpacing: 10,
            crossAxisSpacing: 10,
          ),
          itemCount: categories.length,
          itemBuilder: (context, index) {
            final category = categories[index];
            return Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(
                  category['icon'] as IconData,
                  color: AppTheme.primaryColor,
                  size: 30,
                ),
                const SizedBox(height: 5),
                Text(category['name'] as String),
              ],
            );
          },
        ),
      ],
    );
  }

  Widget _buildRecommendedProductsSection() {
    if (_isLoading && _pageNum == 1) {
      return const Center(
        child: Padding(
          padding: EdgeInsets.symmetric(vertical: 20.0),
          child: CircularProgressIndicator(),
        ),
      );
    }

    if (_isError && _pageNum == 1) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.symmetric(vertical: 20.0),
          child: Column(
            children: [
              const Icon(Icons.error_outline, size: 40, color: Colors.grey),
              const SizedBox(height: 10),
              Text(_errorMessage, style: const TextStyle(color: Colors.grey)),
              const SizedBox(height: 10),
              ElevatedButton(
                onPressed: () => _fetchRecommendedProducts(isRefresh: true),
                child: const Text('重新加载'),
              ),
            ],
          ),
        ),
      );
    }

    if (_products.isEmpty) {
      return const Center(
        child: Padding(
          padding: EdgeInsets.symmetric(vertical: 20.0),
          child: Text('暂无推荐商品', style: TextStyle(color: Colors.grey)),
        ),
      );
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          '推荐商品',
          style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
        ),
        const SizedBox(height: 10),
        GridView.builder(
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
            crossAxisCount: 2,
            childAspectRatio: 0.55, // 微调长宽比
            mainAxisSpacing: 10,
            crossAxisSpacing: 10,
          ),
          itemCount: _products.length,
          itemBuilder: (context, index) {
            return _buildProductItem(_products[index]);
          },
        ),
      ],
    );
  }

  Widget _buildProductItem(Map<String, dynamic> product) {
    final productId = product['productId'] as int? ?? -1;
    final title = product['title'] as String? ?? '未命名商品';
    final price = product['price'] ?? 0.0;
    final originalPrice = product['originalPrice'] ?? 0.0;
    final location = product['location'] as String? ?? '';
    final username = product['username'] as String? ?? '未知用户';

    // 处理图片URL
    String imageUrl = product['mainImageUrl'] as String? ?? '';
    if (imageUrl.isNotEmpty) {
      if (imageUrl.startsWith('http://localhost:8080')) {
        imageUrl = imageUrl.replaceFirst(
            'http://localhost:8080', 'http://192.168.200.30:8080');
      } else if (imageUrl.startsWith('/files/')) {
        imageUrl = 'http://192.168.200.30:8080$imageUrl';
      }
    }

    return Card(
      clipBehavior: Clip.antiAlias,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(10),
      ),
      margin: const EdgeInsets.all(0), // 减少卡片外边距
      elevation: 2,
      child: InkWell(
        onTap: () {
          // 点击商品跳转到详情页
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (context) => ProductDetailPage(
                productId: productId,
                mainImageUrl: imageUrl, // 传递主图URL
              ),
            ),
          );
        },
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // 产品图片
            Expanded(
              flex: 3, // 图片占比更大
              child: AspectRatio(
                aspectRatio: 1,
                child: imageUrl.isNotEmpty
                    ? Image.network(
                        imageUrl,
                        fit: BoxFit.cover,
                        errorBuilder: (context, error, stackTrace) {
                          return Container(
                            color: Colors.grey[300],
                            child: const Icon(
                              Icons.image_not_supported,
                              size: 40,
                              color: Colors.white,
                            ),
                          );
                        },
                      )
                    : Container(
                        color: Colors.grey[300],
                        child: const Icon(
                          Icons.image,
                          size: 40,
                          color: Colors.white,
                        ),
                      ),
              ),
            ),

            // 商品信息
            Expanded(
              flex: 2, // 信息占比较小
              child: Padding(
                padding: const EdgeInsets.fromLTRB(8, 6, 8, 0), // 减少上下内边距
                child: Column(
                  mainAxisSize: MainAxisSize.min, // 使列紧凑
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // 标题
                    Text(
                      title,
                      style: const TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 14,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                    const SizedBox(height: 2), // 减少间距

                    // 价格信息
                    Row(
                      children: [
                        Text(
                          '¥${price.toStringAsFixed(2)}',
                          style: TextStyle(
                            color: AppTheme.primaryColor,
                            fontWeight: FontWeight.bold,
                            fontSize: 14,
                          ),
                        ),
                        const SizedBox(width: 4),
                        if (originalPrice > 0 && originalPrice > price)
                          Text(
                            '¥${originalPrice.toStringAsFixed(2)}',
                            style: const TextStyle(
                              decoration: TextDecoration.lineThrough,
                              color: Colors.grey,
                              fontSize: 10,
                            ),
                          ),
                      ],
                    ),
                    const SizedBox(height: 2), // 减少间距

                    // 位置和用户信息
                    Text(
                      '$location · $username',
                      style: TextStyle(
                        color: Colors.grey[600],
                        fontSize: 10,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),

                    const Spacer(), // 将按钮推到底部

                    // 操作按钮行，放在底部
                    Padding(
                      padding: const EdgeInsets.only(bottom: 6), // 底部留一点空间
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          // 收藏按钮
                          SizedBox(
                            height: 24,
                            width: 24,
                            child: IconButton(
                              icon: const Icon(Icons.favorite_border, size: 16),
                              onPressed: () => _addToFavorite(productId),
                              tooltip: '收藏',
                              padding: EdgeInsets.zero,
                              constraints: const BoxConstraints(),
                            ),
                          ),
                          // 购物车按钮
                          SizedBox(
                            height: 24,
                            width: 24,
                            child: IconButton(
                              icon: const Icon(Icons.shopping_cart_outlined,
                                  size: 16),
                              onPressed: () async {
                                // 添加商品到购物车
                                final success =
                                    await CartManager.addToCart(product);
                                if (!mounted) return;

                                if (success) {
                                  ScaffoldMessenger.of(context).showSnackBar(
                                    const SnackBar(content: Text('已加入购物车')),
                                  );
                                } else {
                                  ScaffoldMessenger.of(context).showSnackBar(
                                    const SnackBar(
                                        content: Text('加入购物车失败，请重试')),
                                  );
                                }
                              },
                              tooltip: '加入购物车',
                              padding: EdgeInsets.zero,
                              constraints: const BoxConstraints(),
                            ),
                          ),
                          // 购买按钮
                          SizedBox(
                            height: 24,
                            child: ElevatedButton(
                              onPressed: () => _createOrder(productId),
                              style: ElevatedButton.styleFrom(
                                backgroundColor: AppTheme.primaryColor,
                                padding:
                                    const EdgeInsets.symmetric(horizontal: 8),
                                minimumSize: const Size(45, 24),
                                tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                              ),
                              child: const Text(
                                '购买',
                                style: TextStyle(fontSize: 10),
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
