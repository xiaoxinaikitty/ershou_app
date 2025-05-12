import 'package:flutter/material.dart';
import 'dart:developer' as developer;
import '../config/theme.dart';
import '../network/api.dart';
import '../network/http_util.dart';
import '../utils/image_url_util.dart';
import 'product_detail_page.dart';

class FavoritePage extends StatefulWidget {
  const FavoritePage({Key? key}) : super(key: key);

  @override
  State<FavoritePage> createState() => _FavoritePageState();
}

class _FavoritePageState extends State<FavoritePage> {
  List<Map<String, dynamic>> _favorites = [];
  bool _isLoading = true;
  bool _hasError = false;
  bool _isLoadingImages = false; // 标记是否正在加载图片

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
        final List<dynamic> favoriteData = response.data as List<dynamic>;
        final List<Map<String, dynamic>> processedFavorites = [];
        
        // 打印获取到的收藏数据以便调试
        developer.log('获取收藏列表成功，总数：${favoriteData.length}', name: 'FavoritePage');
        if (favoriteData.isNotEmpty) {
          developer.log('第一个收藏项字段：${favoriteData.first.keys.join(', ')}', name: 'FavoritePage');
        }
        
        // 处理收藏数据，确保图片URL正确
        for (var favorite in favoriteData) {
          final Map<String, dynamic> favoriteMap = favorite as Map<String, dynamic>;
          developer.log('处理收藏项：ID=${favoriteMap['productId']}', name: 'FavoritePage');
          
          // 尝试从多个可能的字段名获取图片URL
          String imageUrl = favoriteMap['productImage'] as String? ??
              favoriteMap['mainImageUrl'] as String? ??
              favoriteMap['imageUrl'] as String? ??
              favoriteMap['mainImage'] as String? ??
              '';
          
          // 处理图片URL
          imageUrl = ImageUrlUtil.processImageUrl(imageUrl);
          developer.log('处理后的图片URL: $imageUrl', name: 'FavoritePage');
          
          // 更新收藏项中的图片URL
          favoriteMap['productImage'] = imageUrl;
          
          processedFavorites.add(favoriteMap);
        }
        
        setState(() {
          _favorites = processedFavorites;
          _isLoading = false;
        });
        
        // 加载缺失的图片URL
        _loadMissingImages();
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
      developer.log('获取收藏列表异常: $e', name: 'FavoritePage');
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
  
  // 加载缺失的图片
  Future<void> _loadMissingImages() async {
    if (_favorites.isEmpty) return;
    
    setState(() {
      _isLoadingImages = true;
    });
    
    try {
      // 找出所有没有图片URL的收藏项
      List<Map<String, dynamic>> missingImageItems = _favorites
          .where((item) => item['productImage'] == null || (item['productImage'] as String).isEmpty)
          .toList();
      
      developer.log('共有 ${missingImageItems.length} 个收藏项缺少图片', name: 'FavoritePage');
      
      // 为每个缺失图片的收藏项获取商品详情
      for (var item in missingImageItems) {
        final int productId = item['productId'] as int;
        
        try {
          // 获取商品详情
          final detailResponse = await HttpUtil().get('${Api.productDetail}$productId');
          
          if (detailResponse.isSuccess && detailResponse.data != null) {
            final Map<String, dynamic> productDetail = detailResponse.data as Map<String, dynamic>;
            
            // 从商品详情中获取图片URL
            String imageUrl = productDetail['mainImageUrl'] as String? ?? '';
            imageUrl = ImageUrlUtil.processImageUrl(imageUrl);
            
            developer.log('从商品详情获取到图片URL: $imageUrl, 商品ID: $productId', name: 'FavoritePage');
            
            // 如果详情中没有图片，尝试获取图片列表
            if (imageUrl.isEmpty) {
              final imageResponse = await HttpUtil().get('${Api.imageList}$productId');
              
              if (imageResponse.isSuccess && imageResponse.data != null) {
                final List<dynamic> images = imageResponse.data as List<dynamic>;
                
                if (images.isNotEmpty) {
                  String url = images.first['url'] as String? ?? '';
                  imageUrl = ImageUrlUtil.processImageUrl(url);
                  developer.log('从图片列表获取到图片URL: $imageUrl, 商品ID: $productId', name: 'FavoritePage');
                }
              }
            }
            
            // 使用共享的默认图片URL
            if (imageUrl.isEmpty) {
              imageUrl = 'https://pic.52112.com/180824/EPS-180824_327/J1EwJuHlI3_small.jpg';
              developer.log('使用默认图片URL: $imageUrl, 商品ID: $productId', name: 'FavoritePage');
            }
            
            // 更新收藏项中的图片URL
            final int index = _favorites.indexWhere((fav) => fav['productId'] == productId);
            if (index >= 0 && mounted) {
              setState(() {
                _favorites[index]['productImage'] = imageUrl;
              });
            }
          }
        } catch (e) {
          developer.log('获取商品详情异常: $e, 商品ID: $productId', name: 'FavoritePage');
        }
      }
    } catch (e) {
      developer.log('加载缺失图片异常: $e', name: 'FavoritePage');
    } finally {
      if (mounted) {
        setState(() {
          _isLoadingImages = false;
        });
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

    return Stack(
      children: [
        RefreshIndicator(
          onRefresh: _fetchFavorites,
          child: ListView.builder(
            padding: const EdgeInsets.all(16),
            itemCount: _favorites.length,
            itemBuilder: (context, index) {
              final favorite = _favorites[index];
              return _buildFavoriteItem(favorite);
            },
          ),
        ),
        
        // 加载图片时显示的加载指示器
        if (_isLoadingImages)
          Positioned(
            bottom: 16,
            right: 16,
            child: Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: Colors.black45,
                borderRadius: BorderRadius.circular(20),
              ),
              child: const SizedBox(
                width: 20,
                height: 20,
                child: CircularProgressIndicator(
                  strokeWidth: 2,
                  valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                ),
              ),
            ),
          ),
      ],
    );
  }

  Widget _buildFavoriteItem(Map<String, dynamic> favorite) {
    final productId = favorite['productId'];
    final title = favorite['productTitle'] ?? '未命名商品';
    final price = favorite['productPrice']?.toString() ?? '0.00';
    final createdTime = favorite['createdTime'] ?? '';
    
    // 检查多个可能的图片字段，与my_posts_page保持一致
    String imageUrl = favorite['productImage'] as String? ??
        favorite['mainImageUrl'] as String? ??
        favorite['imageUrl'] as String? ??
        favorite['mainImage'] as String? ??
        '';
    
    // 默认显示商品图片
    if (imageUrl.isEmpty) {
      imageUrl = 'https://pic.52112.com/180824/EPS-180824_327/J1EwJuHlI3_small.jpg';
    }
    
    // 处理图片URL
    imageUrl = ImageUrlUtil.processImageUrl(imageUrl);
    
    // 更新收藏项中的图片URL，确保其他地方使用时是正确的
    favorite['productImage'] = imageUrl;
    
    developer.log('收藏项(ID=$productId)图片URL: $imageUrl', name: 'FavoritePage');

    return Card(
      margin: const EdgeInsets.only(bottom: 16),
      child: Padding(
        padding: const EdgeInsets.all(12.0),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // 商品图片
            ClipRRect(
              borderRadius: BorderRadius.circular(8),
              child: SizedBox(
                width: 80,
                height: 80,
                child: imageUrl.isNotEmpty
                  ? Image.network(
                      imageUrl,
                      fit: BoxFit.cover,
                      errorBuilder: (context, error, stackTrace) {
                        developer.log('图片加载失败: $error, URL: $imageUrl',
                            name: 'FavoritePage');
                        return Container(
                          color: Colors.grey[200],
                          child: const Icon(
                            Icons.image_not_supported,
                            color: Colors.white,
                            size: 30,
                          ),
                        );
                      },
                    )
                  : Container(
                      color: Colors.grey[200],
                      child: const Icon(
                        Icons.image,
                        color: Colors.white,
                        size: 30,
                      ),
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
                      fontSize: 14,
                      fontWeight: FontWeight.bold,
                    ),
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                  ),
                  const SizedBox(height: 4),
                  Text(
                    '¥$price',
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                      color: AppTheme.primaryColor,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    '收藏时间: $createdTime',
                    style: TextStyle(
                      fontSize: 12,
                      color: Colors.grey[600],
                    ),
                  ),
                  const SizedBox(height: 8),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.end,
                    children: [
                      OutlinedButton(
                        onPressed: () {
                          // 跳转到商品详情页面
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
                        style: OutlinedButton.styleFrom(
                          foregroundColor: AppTheme.primaryColor,
                          side: BorderSide(color: AppTheme.primaryColor),
                          padding: const EdgeInsets.symmetric(
                              horizontal: 8, vertical: 4),
                          minimumSize: const Size(0, 30),
                        ),
                        child:
                            const Text('查看详情', style: TextStyle(fontSize: 12)),
                      ),
                      const SizedBox(width: 8),
                      OutlinedButton(
                        onPressed: () => _cancelFavorite(productId),
                        style: OutlinedButton.styleFrom(
                          foregroundColor: Colors.grey,
                          side: const BorderSide(color: Colors.grey),
                          padding: const EdgeInsets.symmetric(
                              horizontal: 8, vertical: 4),
                          minimumSize: const Size(0, 30),
                        ),
                        child:
                            const Text('取消收藏', style: TextStyle(fontSize: 12)),
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
