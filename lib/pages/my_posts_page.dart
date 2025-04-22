import 'package:flutter/material.dart';
import 'dart:developer' as developer;
import '../config/theme.dart';
import '../network/api.dart';
import '../network/http_util.dart';
import 'publish_page.dart'; // 导入发布页面用于编辑功能

class MyPostsPage extends StatefulWidget {
  const MyPostsPage({Key? key}) : super(key: key);

  @override
  State<MyPostsPage> createState() => _MyPostsPageState();
}

class _MyPostsPageState extends State<MyPostsPage> {
  final List<Map<String, dynamic>> _posts = [];
  bool _isLoading = true;
  bool _isError = false;
  String _errorMessage = '';
  bool _isDeleteLoading = false;

  // 分页相关参数
  int _pageNum = 1;
  final int _pageSize = 10;
  int _totalPages = 1;
  bool _hasMoreData = true;
  bool _isLoadingMore = false;
  final ScrollController _scrollController = ScrollController();

  // 用户ID
  int? _userId;

  @override
  void initState() {
    super.initState();
    // 设置滚动监听，用于实现上拉加载更多
    _scrollController.addListener(_scrollListener);
    _getUserInfo();
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
        _loadMorePosts();
      }
    }
  }

  // 首先获取用户信息
  Future<void> _getUserInfo() async {
    try {
      final response = await HttpUtil().get(Api.userInfo);

      if (response.isSuccess && response.data != null) {
        final userInfo = response.data as Map<String, dynamic>;
        _userId = userInfo['userId'] as int?;
        developer.log('获取用户ID成功: $_userId', name: 'MyPostsPage');

        // 获取到用户ID后，再获取商品列表
        _fetchMyPosts(isRefresh: true);
      } else {
        setState(() {
          _isLoading = false;
          _isError = true;
          _errorMessage = '获取用户信息失败，请重新登录后再试';
        });
      }
    } catch (e) {
      setState(() {
        _isLoading = false;
        _isError = true;
        _errorMessage = '网络错误，请稍后再试';
      });
      developer.log('获取用户信息异常: $e', name: 'MyPostsPage');
    }
  }

  // 获取我的发布列表
  Future<void> _fetchMyPosts({bool isRefresh = false}) async {
    if (_userId == null) {
      setState(() {
        _isLoading = false;
        _isError = true;
        _errorMessage = '获取用户信息失败，请重新登录后再试';
      });
      return;
    }

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
        'userId': _userId, // 添加userId作为查询参数
      };

      // 发送请求获取用户已发布的商品
      final response = await HttpUtil().get(Api.productList, params: params);

      if (response.isSuccess && response.data != null) {
        final data = response.data as Map<String, dynamic>;
        final List<dynamic> productList = data['list'] ?? [];
        final int totalPages = data['pages'] ?? 1;
        final bool hasNext = data['hasNext'] ?? false;

        setState(() {
          if (isRefresh) {
            _posts.clear();
          }

          for (var product in productList) {
            _posts.add(product as Map<String, dynamic>);
          }

          _totalPages = totalPages;
          _hasMoreData = hasNext;
          _isLoading = false;
          _isLoadingMore = false;
        });

        developer.log(
            '获取我的发布列表成功: ${_posts.length}条数据，当前页码: $_pageNum, 总页数: $_totalPages, 是否还有更多: $_hasMoreData',
            name: 'MyPostsPage');
      } else {
        setState(() {
          _isLoading = false;
          _isLoadingMore = false;
          _isError = isRefresh; // 只有刷新时才显示错误
          _errorMessage = response.message ?? '获取发布列表失败';
        });
        developer.log('获取我的发布列表失败: ${response.message}', name: 'MyPostsPage');
      }
    } catch (e) {
      setState(() {
        _isLoading = false;
        _isLoadingMore = false;
        _isError = isRefresh; // 只有刷新时才显示错误
        _errorMessage = '网络错误，请稍后再试';
      });
      developer.log('获取我的发布列表异常: $e', name: 'MyPostsPage');
    }
  }

  // 加载更多商品
  Future<void> _loadMorePosts() async {
    if (_pageNum < _totalPages) {
      setState(() {
        _pageNum++;
        _isLoadingMore = true;
      });
      await _fetchMyPosts();
    } else {
      setState(() {
        _hasMoreData = false;
      });
    }
  }

  // 刷新数据
  Future<void> _refreshPosts() async {
    setState(() {
      _pageNum = 1;
      _hasMoreData = true;
    });
    return _fetchMyPosts(isRefresh: true);
  }

  // 删除发布的商品
  Future<void> _deletePost(int productId, int index) async {
    setState(() {
      _isDeleteLoading = true;
    });

    try {
      final response =
          await HttpUtil().delete('${Api.productDelete}$productId');

      if (response.isSuccess) {
        setState(() {
          _posts.removeAt(index);
          _isDeleteLoading = false;
        });

        if (!mounted) return;
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('商品删除成功')),
        );
        developer.log('删除商品成功: $productId', name: 'MyPostsPage');
      } else {
        setState(() {
          _isDeleteLoading = false;
        });

        if (!mounted) return;
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(response.message ?? '删除失败')),
        );
        developer.log('删除商品失败: ${response.message}', name: 'MyPostsPage');
      }
    } catch (e) {
      setState(() {
        _isDeleteLoading = false;
      });

      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('网络错误，请稍后再试')),
      );
      developer.log('删除商品异常: $e', name: 'MyPostsPage');
    }
  }

  // 确认删除对话框
  void _showDeleteConfirmDialog(int productId, int index) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('确认删除'),
        content: const Text('确定要删除这个商品吗？此操作不可撤销。'),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('取消'),
          ),
          TextButton(
            onPressed: () {
              Navigator.of(context).pop();
              _deletePost(productId, index);
            },
            child: const Text('确定删除', style: TextStyle(color: Colors.red)),
          ),
        ],
      ),
    );
  }

  // 编辑商品
  void _editProduct(Map<String, dynamic> product) {
    // 导航到发布页面，并传入商品信息
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => PublishPage(
          product: product, // 传入商品信息用于编辑
        ),
      ),
    ).then((value) {
      // 编辑完成后刷新列表
      if (value == true) {
        _refreshPosts();
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title:
            const Text('我的发布', style: TextStyle(fontWeight: FontWeight.bold)),
        elevation: 0,
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : _isError
              ? _buildErrorView()
              : _posts.isEmpty
                  ? _buildEmptyView()
                  : _buildPostsList(),
    );
  }

  // 构建错误视图
  Widget _buildErrorView() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const Icon(
            Icons.error_outline,
            size: 60,
            color: Colors.grey,
          ),
          const SizedBox(height: 16),
          Text(
            _errorMessage,
            textAlign: TextAlign.center,
            style: const TextStyle(color: Colors.grey),
          ),
          const SizedBox(height: 24),
          ElevatedButton(
            onPressed: () => _fetchMyPosts(isRefresh: true),
            child: const Text('重新加载'),
          ),
        ],
      ),
    );
  }

  // 构建空数据视图
  Widget _buildEmptyView() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const Icon(
            Icons.inbox,
            size: 80,
            color: Colors.grey,
          ),
          const SizedBox(height: 16),
          const Text(
            '您还没有发布任何商品',
            style: TextStyle(
              fontSize: 16,
              color: Colors.grey,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 8),
          const Text(
            '去发布一个二手商品吧',
            style: TextStyle(color: Colors.grey),
          ),
          const SizedBox(height: 24),
          ElevatedButton(
            onPressed: () {
              // 导航到发布页面
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) => const PublishPage(),
                ),
              ).then((value) {
                // 发布完成后刷新列表
                if (value == true) {
                  _refreshPosts();
                }
              });
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: AppTheme.primaryColor,
              padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
            ),
            child: const Text('去发布'),
          ),
        ],
      ),
    );
  }

  // 构建商品列表
  Widget _buildPostsList() {
    return RefreshIndicator(
      onRefresh: _refreshPosts,
      child: ListView.builder(
        controller: _scrollController,
        padding: const EdgeInsets.all(16),
        itemCount: _posts.length + (_hasMoreData ? 1 : 0),
        itemBuilder: (context, index) {
          if (index == _posts.length) {
            // 加载更多指示器
            return const Center(
              child: Padding(
                padding: EdgeInsets.symmetric(vertical: 16),
                child: CircularProgressIndicator(),
              ),
            );
          }

          final post = _posts[index];
          return _buildPostItem(post, index);
        },
      ),
    );
  }

  // 构建商品项
  Widget _buildPostItem(Map<String, dynamic> post, int index) {
    final productId = post['productId'] as int? ?? -1;
    final title = post['title'] as String? ?? '未命名商品';
    final price = post['price'] ?? 0.0;
    // 使用主图URL，检查多个可能的字段名
    String imageUrl = post['mainImageUrl'] as String? ??
        post['imageUrl'] as String? ??
        post['mainImage'] as String? ??
        '';

    // 处理图片URL，将localhost替换为正确的服务器地址
    if (imageUrl.isNotEmpty) {
      if (imageUrl.startsWith('http://localhost:8080')) {
        imageUrl = imageUrl.replaceFirst(
            'http://localhost:8080', 'http://192.168.200.30:8080');
      } else if (imageUrl.startsWith('/files/')) {
        imageUrl = 'http://192.168.200.30:8080$imageUrl';
      }
      developer.log('处理后的图片URL: $imageUrl', name: 'MyPostsPage');
    }

    final status = post['status'] as int? ?? 1;
    final String statusText = _getStatusText(status);
    final createdTime = post['createdTime'] as String? ?? '未知时间';

    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(8),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 5,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        children: [
          // 商品信息
          Padding(
            padding: const EdgeInsets.all(12),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // 商品图片
                ClipRRect(
                  borderRadius: BorderRadius.circular(8),
                  child: imageUrl.isNotEmpty
                      ? Image.network(
                          imageUrl,
                          width: 100,
                          height: 100,
                          fit: BoxFit.cover,
                          errorBuilder: (context, error, stackTrace) {
                            developer.log('图片加载失败: $error, URL: $imageUrl',
                                name: 'MyPostsPage');
                            return Container(
                              width: 100,
                              height: 100,
                              color: Colors.grey[200],
                              child: const Icon(
                                Icons.image_not_supported_outlined,
                                color: Colors.grey,
                              ),
                            );
                          },
                        )
                      : Container(
                          width: 100,
                          height: 100,
                          color: Colors.grey[200],
                          child: const Icon(
                            Icons.image_outlined,
                            color: Colors.grey,
                          ),
                        ),
                ),
                const SizedBox(width: 12),
                // 商品信息
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        title,
                        style: const TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                        ),
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                      ),
                      const SizedBox(height: 8),
                      Text(
                        '¥${price.toStringAsFixed(2)}',
                        style: TextStyle(
                          fontSize: 16,
                          color: AppTheme.primaryColor,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: 8),
                      Row(
                        children: [
                          Container(
                            padding: const EdgeInsets.symmetric(
                                horizontal: 6, vertical: 2),
                            decoration: BoxDecoration(
                              color: _getStatusColor(status),
                              borderRadius: BorderRadius.circular(4),
                            ),
                            child: Text(
                              statusText,
                              style: const TextStyle(
                                  fontSize: 12, color: Colors.white),
                            ),
                          ),
                          const SizedBox(width: 8),
                          Expanded(
                            child: Text(
                              createdTime,
                              style: const TextStyle(
                                  fontSize: 12, color: Colors.grey),
                              overflow: TextOverflow.ellipsis,
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
          // 操作按钮
          Container(
            decoration: BoxDecoration(
              border: Border(
                top: BorderSide(color: Colors.grey[200]!),
              ),
            ),
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.end,
              children: [
                TextButton(
                  onPressed: () {
                    // 查看商品详情
                    // TODO: 实现商品详情页导航
                    // Navigator.pushNamed(context, '/product_detail', arguments: productId);
                  },
                  child: const Text('查看详情'),
                ),
                const SizedBox(width: 8),
                TextButton(
                  onPressed: status != 0
                      ? () {
                          // 编辑商品
                          _editProduct(post);
                        }
                      : null,
                  child: const Text('编辑'),
                ),
                const SizedBox(width: 8),
                TextButton(
                  onPressed: () => _showDeleteConfirmDialog(productId, index),
                  style: TextButton.styleFrom(foregroundColor: Colors.red),
                  child: const Text('删除'),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  // 获取状态文本
  String _getStatusText(int status) {
    switch (status) {
      case 0:
        return '已下架';
      case 1:
        return '在售中';
      case 2:
        return '已售出';
      case 3:
        return '交易中';
      default:
        return '未知状态';
    }
  }

  // 获取状态颜色
  Color _getStatusColor(int status) {
    switch (status) {
      case 0:
        return Colors.grey;
      case 1:
        return Colors.green;
      case 2:
        return Colors.orange;
      case 3:
        return Colors.blue;
      default:
        return Colors.grey;
    }
  }
}
