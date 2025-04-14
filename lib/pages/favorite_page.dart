import 'package:flutter/material.dart';
import '../config/theme.dart';
import '../network/api.dart';
import '../network/http_util.dart';

class FavoritePage extends StatefulWidget {
  const FavoritePage({Key? key}) : super(key: key);

  @override
  State<FavoritePage> createState() => _FavoritePageState();
}

class _FavoritePageState extends State<FavoritePage> {
  List<Map<String, dynamic>> _favorites = [];
  bool _isLoading = true;
  bool _hasError = false;

  @override
  void initState() {
    super.initState();
    _fetchFavorites();
  }

  // 获取收藏列表
  Future<void> _fetchFavorites() async {
    setState(() {
      _isLoading = true;
      _hasError = false;
    });

    try {
      final response = await HttpUtil().get(Api.favoriteList);

      if (response.isSuccess && response.data != null) {
        setState(() {
          _favorites = List<Map<String, dynamic>>.from(response.data);
          _isLoading = false;
        });
      } else {
        setState(() {
          _isLoading = false;
          _hasError = true;
        });

        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text(response.message ?? '获取收藏列表失败')),
          );
        }
      }
    } catch (e) {
      setState(() {
        _isLoading = false;
        _hasError = true;
      });

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('网络错误，请稍后再试')),
        );
      }
    }
  }

  // 取消收藏
  Future<void> _cancelFavorite(int productId) async {
    try {
      final response =
          await HttpUtil().delete('${Api.favoriteCancel}$productId');

      if (response.isSuccess) {
        setState(() {
          _favorites.removeWhere((item) => item['productId'] == productId);
        });

        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('取消收藏成功')),
          );
        }
      } else {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text(response.message ?? '取消收藏失败')),
          );
        }
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('网络错误，请稍后再试')),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title:
            const Text('我的收藏', style: TextStyle(fontWeight: FontWeight.bold)),
        elevation: 0,
      ),
      body: _buildBody(),
    );
  }

  Widget _buildBody() {
    if (_isLoading) {
      return const Center(child: CircularProgressIndicator());
    }

    if (_hasError) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Text('加载失败，请重试'),
            const SizedBox(height: 16),
            ElevatedButton(
              onPressed: _fetchFavorites,
              child: const Text('重新加载'),
            ),
          ],
        ),
      );
    }

    if (_favorites.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.favorite_border,
              size: 80,
              color: Colors.grey[400],
            ),
            const SizedBox(height: 16),
            Text(
              '暂无收藏商品',
              style: TextStyle(
                color: Colors.grey[600],
                fontSize: 16,
              ),
            ),
            const SizedBox(height: 24),
            ElevatedButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('去逛逛'),
            ),
          ],
        ),
      );
    }

    return RefreshIndicator(
      onRefresh: _fetchFavorites,
      child: ListView.builder(
        padding: const EdgeInsets.all(16),
        itemCount: _favorites.length,
        itemBuilder: (context, index) {
          final favorite = _favorites[index];
          return _buildFavoriteItem(favorite);
        },
      ),
    );
  }

  Widget _buildFavoriteItem(Map<String, dynamic> favorite) {
    final productId = favorite['productId'];
    final title = favorite['productTitle'] ?? '未命名商品';
    final price = favorite['productPrice']?.toString() ?? '0.00';
    final createdTime = favorite['createdTime'] ?? '';

    return Card(
      margin: const EdgeInsets.only(bottom: 16),
      child: Padding(
        padding: const EdgeInsets.all(12.0),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // 商品图片
            Container(
              width: 100,
              height: 100,
              decoration: BoxDecoration(
                color: Colors.grey[200],
                borderRadius: BorderRadius.circular(8),
              ),
              child: const Icon(
                Icons.image,
                color: Colors.white,
                size: 40,
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
                    '¥$price',
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                      color: AppTheme.primaryColor,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    '收藏时间: $createdTime',
                    style: TextStyle(
                      fontSize: 12,
                      color: Colors.grey[600],
                    ),
                  ),
                  const SizedBox(height: 12),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.end,
                    children: [
                      OutlinedButton(
                        onPressed: () {
                          // 跳转到商品详情页面 (暂不实现)
                        },
                        style: OutlinedButton.styleFrom(
                          foregroundColor: AppTheme.primaryColor,
                          side: BorderSide(color: AppTheme.primaryColor),
                        ),
                        child: const Text('查看详情'),
                      ),
                      const SizedBox(width: 12),
                      OutlinedButton(
                        onPressed: () => _cancelFavorite(productId),
                        style: OutlinedButton.styleFrom(
                          foregroundColor: Colors.grey,
                          side: const BorderSide(color: Colors.grey),
                        ),
                        child: const Text('取消收藏'),
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
}
