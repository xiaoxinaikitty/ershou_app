import 'package:flutter/material.dart';
import 'dart:developer' as developer;
import 'package:shared_preferences/shared_preferences.dart';
import '../config/theme.dart';
import '../network/api.dart';
import '../network/http_util.dart';
import '../utils/cart_manager.dart';
import 'product_detail_page.dart';

class SearchPage extends StatefulWidget {
  const SearchPage({Key? key}) : super(key: key);

  @override
  State<SearchPage> createState() => _SearchPageState();
}

class _SearchPageState extends State<SearchPage> {
  final TextEditingController _searchController = TextEditingController();
  final FocusNode _searchFocusNode = FocusNode();
  List<Map<String, dynamic>> _searchResults = [];
  bool _isSearching = false;
  bool _isError = false;
  String _errorMessage = '';
  String _lastSearchKeyword = '';

  // 搜索历史
  List<String> _searchHistory = [];
  static const String _searchHistoryKey = 'search_history';
  static const int _maxHistoryItems = 10;

  // 排序相关参数
  String _sortField = 'time'; // 默认按时间排序
  String _sortOrder = 'desc'; // 默认降序
  double? _minPrice;
  double? _maxPrice;
  int? _categoryId;

  // 排序选项
  final List<Map<String, dynamic>> _sortOptions = [
    {'field': 'time', 'order': 'desc', 'name': '最新上架'},
    {'field': 'price', 'order': 'asc', 'name': '价格从低到高'},
    {'field': 'price', 'order': 'desc', 'name': '价格从高到低'},
    {'field': 'view', 'order': 'desc', 'name': '浏览量最多'},
  ];

  // 分页相关参数
  int _pageNum = 1;
  final int _pageSize = 10;
  bool _hasMoreData = true;
  bool _isLoadingMore = false;
  final ScrollController _scrollController = ScrollController();

  @override
  void initState() {
    super.initState();
    // 设置滚动监听，用于实现上拉加载更多
    _scrollController.addListener(_scrollListener);

    // 加载搜索历史
    _loadSearchHistory();

    // 自动聚焦搜索框
    Future.delayed(const Duration(milliseconds: 300), () {
      _searchFocusNode.requestFocus();
    });
  }

  @override
  void dispose() {
    _searchController.dispose();
    _searchFocusNode.dispose();
    _scrollController.removeListener(_scrollListener);
    _scrollController.dispose();
    super.dispose();
  }

  // 滚动监听，用于实现上拉加载更多
  void _scrollListener() {
    if (_scrollController.position.pixels >=
        _scrollController.position.maxScrollExtent - 200) {
      // 距离底部200像素时触发加载更多
      if (!_isLoadingMore &&
          _hasMoreData &&
          !_isSearching &&
          _searchResults.isNotEmpty) {
        _loadMoreSearchResults();
      }
    }
  }

  // 加载搜索历史
  Future<void> _loadSearchHistory() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final List<String>? history = prefs.getStringList(_searchHistoryKey);
      if (history != null) {
        setState(() {
          _searchHistory = history;
        });
      }
    } catch (e) {
      developer.log('加载搜索历史异常: $e', name: 'SearchPage');
    }
  }

  // 保存搜索历史
  Future<void> _saveSearchHistory(String keyword) async {
    if (keyword.trim().isEmpty) return;

    try {
      // 移除已存在的相同关键词
      _searchHistory.remove(keyword);

      // 添加到历史记录的最前面
      _searchHistory.insert(0, keyword);

      // 限制历史记录数量
      if (_searchHistory.length > _maxHistoryItems) {
        _searchHistory = _searchHistory.sublist(0, _maxHistoryItems);
      }

      // 保存到本地存储
      final prefs = await SharedPreferences.getInstance();
      await prefs.setStringList(_searchHistoryKey, _searchHistory);
    } catch (e) {
      developer.log('保存搜索历史异常: $e', name: 'SearchPage');
    }
  }

  // 清除搜索历史
  Future<void> _clearSearchHistory() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.remove(_searchHistoryKey);

      setState(() {
        _searchHistory = [];
      });
    } catch (e) {
      developer.log('清除搜索历史异常: $e', name: 'SearchPage');
    }
  }

  // 搜索商品
  Future<void> _searchProducts(String keyword, {bool isRefresh = true}) async {
    // 如果搜索关键词为空，清空结果并返回
    if (keyword.trim().isEmpty) {
      setState(() {
        _searchResults = [];
        _isSearching = false;
        _isError = false;
      });
      return;
    }

    // 保存当前搜索关键词
    _lastSearchKeyword = keyword;

    if (isRefresh) {
      setState(() {
        _pageNum = 1;
        _isSearching = true;
        _isError = false;
        _errorMessage = '';
        _hasMoreData = true;
      });
    }

    try {
      // 构建查询参数
      final Map<String, dynamic> params = {
        'keyword': keyword,
        'pageNum': _pageNum,
        'pageSize': _pageSize,
        'status': 1, // 只显示在售商品
        'sortField': _sortField,
        'sortOrder': _sortOrder,
      };

      // 添加可选参数
      if (_minPrice != null) {
        params['minPrice'] = _minPrice;
      }

      if (_maxPrice != null) {
        params['maxPrice'] = _maxPrice;
      }

      if (_categoryId != null) {
        params['categoryId'] = _categoryId;
      }

      // 使用productList接口而不是productSearch接口，因为它支持关键词搜索
      final response = await HttpUtil().get(Api.productList, params: params);

      if (response.isSuccess && response.data != null) {
        final data = response.data as Map<String, dynamic>;
        final List<dynamic> productList = data['list'] ?? [];
        final bool hasNext = data['hasNext'] ?? false;
        final int total = data['total'] as int? ?? 0;

        setState(() {
          if (isRefresh) {
            _searchResults = List<Map<String, dynamic>>.from(productList);
          } else {
            _searchResults.addAll(List<Map<String, dynamic>>.from(productList));
          }

          _hasMoreData = hasNext;
          _isSearching = false;
          _isLoadingMore = false;
        });

        developer.log(
            '搜索商品成功，关键词: $keyword, 找到: $total个结果, 当前显示: ${_searchResults.length}个',
            name: 'SearchPage');
      } else {
        setState(() {
          if (isRefresh) {
            _searchResults = [];
          }
          _isSearching = false;
          _isLoadingMore = false;
          _isError = true;
          _errorMessage = response.message ?? '搜索商品失败';
        });

        developer.log('搜索商品失败: ${response.message}', name: 'SearchPage');
      }
    } catch (e) {
      setState(() {
        if (isRefresh) {
          _searchResults = [];
        }
        _isSearching = false;
        _isLoadingMore = false;
        _isError = true;
        _errorMessage = '网络错误，请稍后再试';
      });

      developer.log('搜索商品异常: $e', name: 'SearchPage');
    }
  }

  // 加载更多搜索结果
  Future<void> _loadMoreSearchResults() async {
    if (_lastSearchKeyword.isEmpty) return;

    setState(() {
      _pageNum++;
      _isLoadingMore = true;
    });

    await _searchProducts(_lastSearchKeyword, isRefresh: false);
  }

  // 处理搜索提交
  void _handleSearch() {
    final keyword = _searchController.text.trim();
    if (keyword.isNotEmpty) {
      _saveSearchHistory(keyword);
      _searchProducts(keyword);
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
      developer.log('添加收藏异常: $e', name: 'SearchPage');
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
        title: TextField(
          controller: _searchController,
          focusNode: _searchFocusNode,
          decoration: InputDecoration(
            hintText: '搜索您想要的宝贝',
            hintStyle: const TextStyle(color: Colors.grey),
            border: InputBorder.none,
            contentPadding: const EdgeInsets.symmetric(vertical: 15),
            isDense: true,
            suffixIcon: _searchController.text.isNotEmpty
                ? IconButton(
                    icon: const Icon(Icons.clear),
                    onPressed: () {
                      setState(() {
                        _searchController.clear();
                        _searchResults = [];
                      });
                      _searchFocusNode.requestFocus();
                    },
                  )
                : null,
          ),
          textInputAction: TextInputAction.search,
          onSubmitted: (_) => _handleSearch(),
          onChanged: (value) {
            setState(() {});
          },
        ),
        actions: [
          TextButton(
            onPressed: _handleSearch,
            child: const Text('搜索'),
          ),
        ],
      ),
      body: Column(
        children: [
          // 筛选和排序栏
          if (_searchResults.isNotEmpty)
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              decoration: BoxDecoration(
                color: Colors.white,
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.05),
                    blurRadius: 2,
                    offset: const Offset(0, 2),
                  ),
                ],
              ),
              child: Row(
                children: [
                  // 价格筛选
                  InkWell(
                    onTap: _showPriceFilterDialog,
                    child: Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 12, vertical: 6),
                      decoration: BoxDecoration(
                        border: Border.all(color: Colors.grey[300]!),
                        borderRadius: BorderRadius.circular(4),
                      ),
                      child: Row(
                        children: [
                          Text(
                            _minPrice != null || _maxPrice != null
                                ? '价格筛选'
                                : '价格',
                            style: TextStyle(
                              color: (_minPrice != null || _maxPrice != null)
                                  ? AppTheme.primaryColor
                                  : Colors.black87,
                              fontSize: 14,
                            ),
                          ),
                          const Icon(Icons.arrow_drop_down, size: 16),
                        ],
                      ),
                    ),
                  ),
                  const SizedBox(width: 12),
                  // 排序选择
                  InkWell(
                    onTap: _showSortOptionsDialog,
                    child: Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 12, vertical: 6),
                      decoration: BoxDecoration(
                        border: Border.all(color: Colors.grey[300]!),
                        borderRadius: BorderRadius.circular(4),
                      ),
                      child: Row(
                        children: [
                          Text(
                            _getSortOptionName(),
                            style: TextStyle(
                              color:
                                  (_sortField != 'time' || _sortOrder != 'desc')
                                      ? AppTheme.primaryColor
                                      : Colors.black87,
                              fontSize: 14,
                            ),
                          ),
                          const Icon(Icons.arrow_drop_down, size: 16),
                        ],
                      ),
                    ),
                  ),
                  const Spacer(),
                  // 重置筛选
                  if (_minPrice != null ||
                      _maxPrice != null ||
                      _sortField != 'time' ||
                      _sortOrder != 'desc')
                    TextButton(
                      onPressed: _resetFilters,
                      child: const Text('重置', style: TextStyle(fontSize: 14)),
                    ),
                ],
              ),
            ),

          // 搜索结果内容
          Expanded(
            child: _buildSearchResults(),
          ),
        ],
      ),
    );
  }

  Widget _buildSearchResults() {
    if (_isSearching && _searchResults.isEmpty) {
      // 首次搜索加载中
      return const Center(
        child: CircularProgressIndicator(),
      );
    }

    if (_isError) {
      // 搜索出错
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Icons.error_outline, size: 60, color: Colors.grey),
            const SizedBox(height: 16),
            Text(_errorMessage, style: const TextStyle(color: Colors.grey)),
            const SizedBox(height: 24),
            ElevatedButton(
              onPressed: () => _searchProducts(_lastSearchKeyword),
              child: const Text('重新搜索'),
            ),
          ],
        ),
      );
    }

    if (_searchController.text.isEmpty) {
      // 未输入关键词，显示搜索历史
      return _buildSearchHistoryView();
    }

    if (_searchResults.isEmpty && !_isSearching) {
      // 无搜索结果
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Icons.search_off, size: 60, color: Colors.grey),
            const SizedBox(height: 16),
            Text('没有找到与"${_searchController.text}"相关的商品',
                style: const TextStyle(color: Colors.grey)),
          ],
        ),
      );
    }

    // 显示搜索结果列表
    return RefreshIndicator(
      onRefresh: () => _searchProducts(_lastSearchKeyword),
      child: ListView(
        controller: _scrollController,
        padding: const EdgeInsets.all(16),
        children: [
          // 搜索结果网格
          GridView.builder(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
              crossAxisCount: 2,
              childAspectRatio: 0.55, // 微调长宽比
              mainAxisSpacing: 10,
              crossAxisSpacing: 10,
            ),
            itemCount: _searchResults.length,
            itemBuilder: (context, index) {
              return _buildProductItem(_searchResults[index]);
            },
          ),

          // 加载更多指示器
          if (_isLoadingMore)
            const Center(
              child: Padding(
                padding: EdgeInsets.all(16.0),
                child: CircularProgressIndicator(),
              ),
            ),

          // 没有更多数据提示
          if (!_hasMoreData && _searchResults.isNotEmpty)
            const Padding(
              padding: EdgeInsets.all(16.0),
              child: Center(
                child: Text('没有更多数据了', style: TextStyle(color: Colors.grey)),
              ),
            ),
        ],
      ),
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
              builder: (context) => ProductDetailPage(productId: productId),
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
                              onPressed: () {
                                // 跳转到商品详情页
                                Navigator.push(
                                  context,
                                  MaterialPageRoute(
                                    builder: (context) =>
                                        ProductDetailPage(productId: productId),
                                  ),
                                );
                              },
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

  // 构建搜索历史视图
  Widget _buildSearchHistoryView() {
    if (_searchHistory.isEmpty) {
      return const Center(
        child: Text('暂无搜索历史', style: TextStyle(color: Colors.grey)),
      );
    }

    return Padding(
      padding: const EdgeInsets.all(16.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text(
                '搜索历史',
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                ),
              ),
              GestureDetector(
                onTap: () {
                  showDialog(
                    context: context,
                    builder: (context) => AlertDialog(
                      title: const Text('清除搜索历史'),
                      content: const Text('确定要清除所有搜索历史吗？'),
                      actions: [
                        TextButton(
                          onPressed: () => Navigator.of(context).pop(),
                          child: const Text('取消'),
                        ),
                        TextButton(
                          onPressed: () {
                            _clearSearchHistory();
                            Navigator.of(context).pop();
                          },
                          child: const Text('确定',
                              style: TextStyle(color: Colors.red)),
                        ),
                      ],
                    ),
                  );
                },
                child: const Text(
                  '清除',
                  style: TextStyle(color: Colors.grey),
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: _searchHistory.map((keyword) {
              return GestureDetector(
                onTap: () {
                  _searchController.text = keyword;
                  _handleSearch();
                },
                child: Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                  decoration: BoxDecoration(
                    color: Colors.grey[200],
                    borderRadius: BorderRadius.circular(16),
                  ),
                  child: Text(keyword),
                ),
              );
            }).toList(),
          ),
        ],
      ),
    );
  }

  // 获取当前排序选项的名称
  String _getSortOptionName() {
    for (var option in _sortOptions) {
      if (option['field'] == _sortField && option['order'] == _sortOrder) {
        return option['name'];
      }
    }
    return '最新上架';
  }

  // 显示排序选项对话框
  void _showSortOptionsDialog() {
    showModalBottomSheet(
      context: context,
      builder: (context) => Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            padding: const EdgeInsets.symmetric(vertical: 16),
            alignment: Alignment.center,
            child: const Text(
              '排序方式',
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
          const Divider(height: 1),
          ListView.separated(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            itemCount: _sortOptions.length,
            separatorBuilder: (context, index) => const Divider(height: 1),
            itemBuilder: (context, index) {
              final option = _sortOptions[index];
              final isSelected = option['field'] == _sortField &&
                  option['order'] == _sortOrder;

              return ListTile(
                title: Text(
                  option['name'],
                  style: TextStyle(
                    color: isSelected ? AppTheme.primaryColor : Colors.black87,
                    fontWeight:
                        isSelected ? FontWeight.bold : FontWeight.normal,
                  ),
                ),
                trailing: isSelected
                    ? Icon(Icons.check, color: AppTheme.primaryColor)
                    : null,
                onTap: () {
                  Navigator.pop(context);
                  setState(() {
                    _sortField = option['field'];
                    _sortOrder = option['order'];
                  });
                  if (_lastSearchKeyword.isNotEmpty) {
                    _searchProducts(_lastSearchKeyword);
                  }
                },
              );
            },
          ),
        ],
      ),
    );
  }

  // 显示价格筛选对话框
  void _showPriceFilterDialog() {
    final minController = TextEditingController(
      text: _minPrice?.toString() ?? '',
    );
    final maxController = TextEditingController(
      text: _maxPrice?.toString() ?? '',
    );

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('价格区间'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Row(
              children: [
                Expanded(
                  child: TextField(
                    controller: minController,
                    keyboardType: TextInputType.number,
                    decoration: const InputDecoration(
                      hintText: '最低价',
                      prefixText: '¥',
                      isDense: true,
                    ),
                  ),
                ),
                const Padding(
                  padding: EdgeInsets.symmetric(horizontal: 8),
                  child: Text('-'),
                ),
                Expanded(
                  child: TextField(
                    controller: maxController,
                    keyboardType: TextInputType.number,
                    decoration: const InputDecoration(
                      hintText: '最高价',
                      prefixText: '¥',
                      isDense: true,
                    ),
                  ),
                ),
              ],
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('取消'),
          ),
          TextButton(
            onPressed: () {
              Navigator.pop(context);

              // 解析价格输入
              double? minPrice;
              double? maxPrice;

              if (minController.text.isNotEmpty) {
                minPrice = double.tryParse(minController.text);
              }

              if (maxController.text.isNotEmpty) {
                maxPrice = double.tryParse(maxController.text);
              }

              // 如果最低价高于最高价，则交换
              if (minPrice != null && maxPrice != null && minPrice > maxPrice) {
                final temp = minPrice;
                minPrice = maxPrice;
                maxPrice = temp;
              }

              setState(() {
                _minPrice = minPrice;
                _maxPrice = maxPrice;
              });

              if (_lastSearchKeyword.isNotEmpty) {
                _searchProducts(_lastSearchKeyword);
              }
            },
            child: const Text('确定'),
          ),
        ],
      ),
    );
  }

  // 重置过滤条件
  void _resetFilters() {
    setState(() {
      _sortField = 'time';
      _sortOrder = 'desc';
      _minPrice = null;
      _maxPrice = null;
      _categoryId = null;
    });

    if (_lastSearchKeyword.isNotEmpty) {
      _searchProducts(_lastSearchKeyword);
    }
  }
}
