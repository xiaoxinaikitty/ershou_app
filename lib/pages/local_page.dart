import 'package:flutter/material.dart';
import '../config/theme.dart';
import '../network/api.dart';
import '../network/http_util.dart';
import '../utils/cart_manager.dart';
import 'product_detail_page.dart';
import 'dart:developer' as developer;

class LocalPage extends StatefulWidget {
  const LocalPage({Key? key}) : super(key: key);

  @override
  State<LocalPage> createState() => _LocalPageState();
}

class _LocalPageState extends State<LocalPage> {
  final List<String> _tabs = ['推荐', '最新', '附近'];
  String _currentLocation = '北京市';

  // 城市列表
  final List<String> _cities = [
    '北京市',
    '上海市',
    '广州市',
    '深圳市',
    '杭州市',
    '南京市',
    '成都市',
    '重庆市',
    '武汉市',
    '西安市',
    '天津市',
    '苏州市',
    '郑州市',
    '长沙市',
    '东莞市',
    '沈阳市',
    '青岛市',
    '合肥市',
    '佛山市',
    '宁波市'
  ];

  // 商品列表相关状态
  final List<Map<String, dynamic>> _recommendedProducts = [];
  final List<Map<String, dynamic>> _newestProducts = [];
  bool _isLoading = true;
  bool _isNewestLoading = true;
  bool _isError = false;
  bool _isNewestError = false;
  String _errorMessage = '';
  String _newestErrorMessage = '';
  int _pageNum = 1;
  int _newestPageNum = 1;
  final int _pageSize = 10;
  int _totalPages = 1;
  int _newestTotalPages = 1;
  bool _hasMoreData = true;
  bool _hasMoreNewestData = true;
  bool _isLoadingMore = false;
  bool _isLoadingMoreNewest = false;
  final ScrollController _scrollController = ScrollController();
  final ScrollController _newestScrollController = ScrollController();
  int? _currentUserId;

  @override
  void initState() {
    super.initState();
    _scrollController.addListener(_scrollListener);
    _newestScrollController.addListener(_newestScrollListener);
    _getCurrentUserId();
  }

  @override
  void dispose() {
    _scrollController.removeListener(_scrollListener);
    _newestScrollController.removeListener(_newestScrollListener);
    _scrollController.dispose();
    _newestScrollController.dispose();
    super.dispose();
  }

  void _scrollListener() {
    if (!_scrollController.hasClients) return;

    final maxScroll = _scrollController.position.maxScrollExtent;
    final currentScroll = _scrollController.position.pixels;
    final remainingDistance = maxScroll - currentScroll;

    developer.log(
        '推荐页滚动: 当前=${currentScroll.toInt()}, 最大=$maxScroll, 剩余=$remainingDistance',
        name: 'LocalPage');

    if (remainingDistance < 200) {
      if (!_isLoadingMore && _hasMoreData && !_isLoading) {
        developer.log('触发加载更多推荐商品，当前页码: $_pageNum', name: 'LocalPage');
        _loadMoreProducts();
      }
    }
  }

  void _newestScrollListener() {
    if (!_newestScrollController.hasClients) return;

    final maxScroll = _newestScrollController.position.maxScrollExtent;
    final currentScroll = _newestScrollController.position.pixels;
    final remainingDistance = maxScroll - currentScroll;

    developer.log(
        '最新页滚动: 当前=${currentScroll.toInt()}, 最大=$maxScroll, 剩余=$remainingDistance',
        name: 'LocalPage');

    if (remainingDistance < 200) {
      if (!_isLoadingMoreNewest && _hasMoreNewestData && !_isNewestLoading) {
        developer.log('触发加载更多最新商品，当前页码: $_newestPageNum', name: 'LocalPage');
        _loadMoreNewestProducts();
      }
    }
  }

  Future<void> _getCurrentUserId() async {
    try {
      final response = await HttpUtil().get(Api.userInfo);
      if (response.isSuccess && response.data != null) {
        final userInfo = response.data as Map<String, dynamic>;
        _currentUserId = userInfo['userId'] as int?;
        developer.log('获取当前用户ID成功: $_currentUserId', name: 'LocalPage');
      }
    } catch (e) {
      developer.log('获取当前用户信息异常: $e', name: 'LocalPage');
    } finally {
      _fetchRecommendedProducts(isRefresh: true);
      _fetchNewestProducts(isRefresh: true); // 添加这行来加载最新商品
    }
  }

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
      final Map<String, dynamic> params = {
        'pageNum': _pageNum,
        'pageSize': _pageSize,
        'status': 1,
        'sortField': 'time',
        'sortOrder': 'desc',
        'location': _currentLocation,
      };

      developer.log(
          '请求推荐商品列表: 页码=$_pageNum, 每页数量=$_pageSize, 位置=$_currentLocation',
          name: 'LocalPage');
      final response = await HttpUtil().get(Api.productList, params: params);

      if (response.isSuccess && response.data != null) {
        final data = response.data as Map<String, dynamic>;
        final List<dynamic> productList = data['list'] ?? [];
        final int totalPages = data['pages'] ?? 1;
        final bool hasNext = data['hasNext'] ?? false;

        developer.log(
            '获取推荐商品成功: 总条数=${productList.length}, 总页数=$totalPages, 是否有下一页=$hasNext',
            name: 'LocalPage');

        setState(() {
          if (isRefresh) {
            _recommendedProducts.clear();
          }

          for (var product in productList) {
            final Map<String, dynamic> productData =
                product as Map<String, dynamic>;
            final int sellerId = productData['userId'] as int? ?? 0;

            if (_currentUserId == null || sellerId != _currentUserId) {
              _recommendedProducts.add(productData);
            }
          }

          developer.log('添加后推荐商品总数: ${_recommendedProducts.length}',
              name: 'LocalPage');
          _totalPages = totalPages;
          _hasMoreData = hasNext;
          _isLoading = false;
          _isLoadingMore = false;
        });
      } else {
        developer.log('获取推荐商品失败: ${response.message}', name: 'LocalPage');
        setState(() {
          _isLoading = false;
          _isLoadingMore = false;
          _isError = isRefresh;
          _errorMessage = response.message ?? '获取推荐商品失败';
        });
      }
    } catch (e) {
      developer.log('获取推荐商品异常: $e', name: 'LocalPage');
      setState(() {
        _isLoading = false;
        _isLoadingMore = false;
        _isError = isRefresh;
        _errorMessage = '网络错误，请稍后再试';
      });
    }
  }

  Future<void> _loadMoreProducts() async {
    if (_isLoadingMore) return;

    if (_pageNum < _totalPages) {
      setState(() {
        _pageNum++;
        _isLoadingMore = true;
      });
      developer.log('加载更多推荐商品: 当前页码=$_pageNum, 总页数=$_totalPages',
          name: 'LocalPage');
      await _fetchRecommendedProducts();
    } else {
      setState(() {
        _hasMoreData = false;
      });
      developer.log('已经是最后一页推荐商品', name: 'LocalPage');
    }
  }

  Future<void> _fetchNewestProducts({bool isRefresh = false}) async {
    if (isRefresh) {
      setState(() {
        _isNewestLoading = true;
        _isNewestError = false;
        _newestErrorMessage = '';
        _newestPageNum = 1;
        _hasMoreNewestData = true;
      });
    }

    try {
      final Map<String, dynamic> params = {
        'pageNum': _newestPageNum,
        'pageSize': _pageSize,
        'status': 1,
        'sortField': 'time',
        'sortOrder': 'desc',
        'location': _currentLocation,
      };

      developer.log(
          '请求最新商品列表: 页码=$_newestPageNum, 每页数量=$_pageSize, 位置=$_currentLocation',
          name: 'LocalPage');
      final response = await HttpUtil().get(Api.productList, params: params);

      if (response.isSuccess && response.data != null) {
        final data = response.data as Map<String, dynamic>;
        final List<dynamic> productList = data['list'] ?? [];
        final int totalPages = data['pages'] ?? 1;
        final bool hasNext = data['hasNext'] ?? false;

        developer.log(
            '获取最新商品成功: 总条数=${productList.length}, 总页数=$totalPages, 是否有下一页=$hasNext',
            name: 'LocalPage');

        setState(() {
          if (isRefresh) {
            _newestProducts.clear();
          }

          for (var product in productList) {
            final Map<String, dynamic> productData =
                product as Map<String, dynamic>;
            final int sellerId = productData['userId'] as int? ?? 0;

            if (_currentUserId == null || sellerId != _currentUserId) {
              _newestProducts.add(productData);
            }
          }

          developer.log('添加后最新商品总数: ${_newestProducts.length}',
              name: 'LocalPage');
          _newestTotalPages = totalPages;
          _hasMoreNewestData = hasNext;
          _isNewestLoading = false;
          _isLoadingMoreNewest = false;
        });
      } else {
        developer.log('获取最新商品失败: ${response.message}', name: 'LocalPage');
        setState(() {
          _isNewestLoading = false;
          _isLoadingMoreNewest = false;
          _isNewestError = isRefresh;
          _newestErrorMessage = response.message ?? '获取最新商品失败';
        });
      }
    } catch (e) {
      developer.log('获取最新商品异常: $e', name: 'LocalPage');
      setState(() {
        _isNewestLoading = false;
        _isLoadingMoreNewest = false;
        _isNewestError = isRefresh;
        _newestErrorMessage = '网络错误，请稍后再试';
      });
    }
  }

  Future<void> _loadMoreNewestProducts() async {
    if (_isLoadingMoreNewest) return;

    if (_newestPageNum < _newestTotalPages) {
      setState(() {
        _newestPageNum++;
        _isLoadingMoreNewest = true;
      });
      developer.log('加载更多最新商品: 当前页码=$_newestPageNum, 总页数=$_newestTotalPages',
          name: 'LocalPage');
      await _fetchNewestProducts();
    } else {
      setState(() {
        _hasMoreNewestData = false;
      });
      developer.log('已经是最后一页最新商品', name: 'LocalPage');
    }
  }

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
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('网络错误，请稍后再试')),
      );
    }
  }

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
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(response.message ?? '创建订单失败')),
        );
      }
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('网络错误，请稍后再试')),
      );
    }
  }

  // 显示位置选择对话框
  void _showLocationDialog() {
    // 搜索关键词
    String searchKeyword = '';

    // 热门城市
    final List<String> hotCities = [
      '北京市',
      '上海市',
      '广州市',
      '深圳市',
      '杭州市',
      '成都市',
      '重庆市'
    ];

    showDialog(
      context: context,
      builder: (context) => StatefulBuilder(
        builder: (context, setDialogState) {
          // 根据搜索关键词过滤城市
          List<String> filteredCities = searchKeyword.isEmpty
              ? _cities
              : _cities.where((city) => city.contains(searchKeyword)).toList();

          return AlertDialog(
            title: const Text('选择城市'),
            content: Container(
              width: double.maxFinite,
              constraints: const BoxConstraints(maxHeight: 400),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // 搜索框
                  TextField(
                    decoration: const InputDecoration(
                      hintText: '搜索城市',
                      prefixIcon: Icon(Icons.search),
                      border: OutlineInputBorder(),
                      contentPadding:
                          EdgeInsets.symmetric(vertical: 0, horizontal: 10),
                    ),
                    onChanged: (value) {
                      setDialogState(() {
                        searchKeyword = value;
                      });
                    },
                  ),
                  const SizedBox(height: 16),

                  // 热门城市
                  if (searchKeyword.isEmpty) ...[
                    const Text('热门城市',
                        style: TextStyle(fontWeight: FontWeight.bold)),
                    const SizedBox(height: 8),
                    Wrap(
                      spacing: 8,
                      runSpacing: 8,
                      children: hotCities
                          .map((city) => InkWell(
                                onTap: () {
                                  setState(() {
                                    _currentLocation = city;
                                  });
                                  Navigator.of(context).pop();
                                  // 刷新商品列表
                                  _fetchRecommendedProducts(isRefresh: true);
                                  _fetchNewestProducts(isRefresh: true);
                                },
                                child: Container(
                                  padding: const EdgeInsets.symmetric(
                                      horizontal: 12, vertical: 6),
                                  decoration: BoxDecoration(
                                    color: _currentLocation == city
                                        ? AppTheme.primaryColor
                                        : Colors.grey[200],
                                    borderRadius: BorderRadius.circular(4),
                                  ),
                                  child: Text(
                                    city,
                                    style: TextStyle(
                                      color: _currentLocation == city
                                          ? Colors.white
                                          : Colors.black87,
                                    ),
                                  ),
                                ),
                              ))
                          .toList(),
                    ),
                    const SizedBox(height: 16),
                    const Text('全部城市',
                        style: TextStyle(fontWeight: FontWeight.bold)),
                    const SizedBox(height: 8),
                  ],

                  // 城市列表
                  Expanded(
                    child: ListView.builder(
                      shrinkWrap: true,
                      itemCount: filteredCities.length,
                      itemBuilder: (context, index) {
                        return ListTile(
                          dense: true,
                          title: Text(filteredCities[index]),
                          selected: _currentLocation == filteredCities[index],
                          selectedTileColor: Colors.grey[200],
                          onTap: () {
                            // 更新位置
                            setState(() {
                              _currentLocation = filteredCities[index];
                            });
                            Navigator.of(context).pop();
                            // 刷新商品列表
                            _fetchRecommendedProducts(isRefresh: true);
                            _fetchNewestProducts(isRefresh: true);
                          },
                        );
                      },
                    ),
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
            ],
          );
        },
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return DefaultTabController(
      length: _tabs.length,
      child: Scaffold(
        appBar: AppBar(
          title: Row(
            children: [
              GestureDetector(
                onTap: () {
                  _showLocationDialog();
                },
                child: Row(
                  children: [
                    Text(_currentLocation,
                        style: const TextStyle(fontWeight: FontWeight.bold)),
                    const Icon(Icons.arrow_drop_down),
                  ],
                ),
              ),
            ],
          ),
          actions: [
            IconButton(
              icon: const Icon(Icons.search),
              onPressed: () {
                // 搜索功能
              },
            ),
          ],
          bottom: TabBar(
            tabs: _tabs.map((tab) => Tab(text: tab)).toList(),
            labelColor: AppTheme.primaryColor,
            unselectedLabelColor: Colors.grey,
            indicatorColor: AppTheme.primaryColor,
          ),
        ),
        body: TabBarView(
          children: [
            _buildRecommendedTab(),
            _buildNewestTab(),
            _buildNearbyTab(),
          ],
        ),
      ),
    );
  }

  Widget _buildRecommendedTab() {
    if (_isLoading && _pageNum == 1) {
      return const Center(
        child: CircularProgressIndicator(),
      );
    }

    if (_isError && _pageNum == 1) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
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
      );
    }

    if (_recommendedProducts.isEmpty) {
      return const Center(
        child: Text('暂无推荐商品', style: TextStyle(color: Colors.grey)),
      );
    }

    return RefreshIndicator(
      onRefresh: () => _fetchRecommendedProducts(isRefresh: true),
      child: GridView.builder(
        controller: _scrollController,
        padding: const EdgeInsets.all(16.0),
        gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
          crossAxisCount: 2,
          childAspectRatio: 0.55,
          mainAxisSpacing: 10,
          crossAxisSpacing: 10,
        ),
        itemCount: _hasMoreData
            ? _recommendedProducts.length + 1
            : _recommendedProducts.length,
        itemBuilder: (context, index) {
          if (index == _recommendedProducts.length && _hasMoreData) {
            if (!_isLoadingMore) {
              Future.microtask(() => _loadMoreProducts());
            }

            return const Center(
              child: Padding(
                padding: EdgeInsets.all(16.0),
                child: CircularProgressIndicator(),
              ),
            );
          }

          return _buildProductItem(_recommendedProducts[index]);
        },
      ),
    );
  }

  Widget _buildNewestTab() {
    if (_isNewestLoading && _newestPageNum == 1) {
      return const Center(
        child: CircularProgressIndicator(),
      );
    }

    if (_isNewestError && _newestPageNum == 1) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Icons.error_outline, size: 40, color: Colors.grey),
            const SizedBox(height: 10),
            Text(_newestErrorMessage,
                style: const TextStyle(color: Colors.grey)),
            const SizedBox(height: 10),
            ElevatedButton(
              onPressed: () => _fetchNewestProducts(isRefresh: true),
              child: const Text('重新加载'),
            ),
          ],
        ),
      );
    }

    if (_newestProducts.isEmpty) {
      return const Center(
        child: Text('暂无最新商品', style: TextStyle(color: Colors.grey)),
      );
    }

    return RefreshIndicator(
      onRefresh: () => _fetchNewestProducts(isRefresh: true),
      child: GridView.builder(
        controller: _newestScrollController,
        padding: const EdgeInsets.all(16.0),
        gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
          crossAxisCount: 2,
          childAspectRatio: 0.55,
          mainAxisSpacing: 10,
          crossAxisSpacing: 10,
        ),
        itemCount: _hasMoreNewestData
            ? _newestProducts.length + 1
            : _newestProducts.length,
        itemBuilder: (context, index) {
          if (index == _newestProducts.length && _hasMoreNewestData) {
            if (!_isLoadingMoreNewest) {
              Future.microtask(() => _loadMoreNewestProducts());
            }

            return const Center(
              child: Padding(
                padding: EdgeInsets.all(16.0),
                child: CircularProgressIndicator(),
              ),
            );
          }

          return _buildProductItem(_newestProducts[index]);
        },
      ),
    );
  }

  Widget _buildNearbyTab() {
    return _buildProductList('附近商品');
  }

  Widget _buildProductItem(Map<String, dynamic> product) {
    final productId = product['productId'] as int? ?? -1;
    final title = product['title'] as String? ?? '未命名商品';
    final price = product['price'] ?? 0.0;
    final originalPrice = product['originalPrice'] ?? 0.0;
    final location = product['location'] as String? ?? '';
    final username = product['username'] as String? ?? '未知用户';

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
      margin: const EdgeInsets.all(0),
      elevation: 2,
      child: InkWell(
        onTap: () {
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (context) => ProductDetailPage(
                productId: productId,
                mainImageUrl: imageUrl,
              ),
            ),
          );
        },
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Expanded(
              flex: 3,
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
            Expanded(
              flex: 2,
              child: Padding(
                padding: const EdgeInsets.fromLTRB(8, 6, 8, 0),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      title,
                      style: const TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 14,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                    const SizedBox(height: 2),
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
                    const SizedBox(height: 2),
                    Text(
                      '$location · $username',
                      style: TextStyle(
                        color: Colors.grey[600],
                        fontSize: 10,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                    const Spacer(),
                    Padding(
                      padding: const EdgeInsets.only(bottom: 6),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
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
                          SizedBox(
                            height: 24,
                            width: 24,
                            child: IconButton(
                              icon: const Icon(Icons.shopping_cart_outlined,
                                  size: 16),
                              onPressed: () async {
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

  Widget _buildProductList(String title) {
    // 保持原有的模拟数据展示
    final products = List.generate(
      15,
      (index) => {
        'title': '$title ${index + 1}',
        'price': '¥${(index + 1) * 50 + 100}',
        'distance': '${(index % 5) + 1}km',
        'description': '这是一个本地的二手商品，品相良好，${95 - index}新',
      },
    );

    return ListView.builder(
      padding: const EdgeInsets.all(16.0),
      itemCount: products.length,
      itemBuilder: (context, index) {
        final product = products[index];
        return Card(
          margin: const EdgeInsets.only(bottom: 16.0),
          child: Padding(
            padding: const EdgeInsets.all(12.0),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Container(
                  width: 100,
                  height: 100,
                  decoration: BoxDecoration(
                    color: Colors.grey[300],
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: const Icon(
                    Icons.image,
                    color: Colors.white,
                    size: 40,
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        product['title'] as String,
                        style: const TextStyle(
                          fontWeight: FontWeight.bold,
                          fontSize: 16,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        product['description'] as String,
                        style: TextStyle(
                          color: Colors.grey[600],
                          fontSize: 12,
                        ),
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                      ),
                      const SizedBox(height: 8),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text(
                            product['price'] as String,
                            style: TextStyle(
                              color: AppTheme.primaryColor,
                              fontWeight: FontWeight.bold,
                              fontSize: 18,
                            ),
                          ),
                          Text(
                            product['distance'] as String,
                            style: TextStyle(
                              color: Colors.grey[400],
                              fontSize: 12,
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
      },
    );
  }
}
