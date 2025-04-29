import 'package:flutter/material.dart';
import 'dart:developer' as developer;
import '../config/theme.dart';
import '../network/api.dart';
import '../network/http_util.dart';
import '../utils/cart_manager.dart';
import 'product_detail_page.dart';

class CartPage extends StatefulWidget {
  const CartPage({Key? key}) : super(key: key);

  @override
  State<CartPage> createState() => _CartPageState();
}

class _CartPageState extends State<CartPage> {
  List<Map<String, dynamic>> _cartItems = [];
  bool _isLoading = true;
  bool _isError = false;
  String _errorMessage = '';
  double _totalPrice = 0;

  @override
  void initState() {
    super.initState();
    _fetchCartItems();
  }

  // 获取购物车数据
  Future<void> _fetchCartItems() async {
    setState(() {
      _isLoading = true;
      _isError = false;
      _errorMessage = '';
    });

    try {
      // 使用CartManager获取购物车数据
      await Future.delayed(const Duration(milliseconds: 300)); // 短暂延迟以显示加载效果
      final cartItems = await CartManager.getCartItems();
      final totalPrice = await CartManager.getCartTotalPrice();

      setState(() {
        _cartItems = cartItems;
        _totalPrice = totalPrice;
        _isLoading = false;
      });

      developer.log('获取购物车数据成功: ${_cartItems.length}个商品', name: 'CartPage');
    } catch (e) {
      developer.log('获取购物车数据异常: $e', name: 'CartPage');
      setState(() {
        _isLoading = false;
        _isError = true;
        _errorMessage = '加载购物车失败，请稍后重试';
      });
    }
  }

  // 更新商品数量
  void _updateQuantity(int index, int newQuantity) async {
    if (newQuantity <= 0) {
      _showDeleteConfirmDialog(index);
    } else {
      final productId = _cartItems[index]['productId'] as int;
      final success = await CartManager.updateQuantity(productId, newQuantity);

      if (success) {
        setState(() {
          _cartItems[index]['quantity'] = newQuantity;
          _updateTotalPrice();
        });
      } else {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('更新数量失败，请重试')),
          );
        }
      }
    }
  }

  // 从购物车移除商品
  void _removeFromCart(int index) async {
    final productId = _cartItems[index]['productId'] as int;
    final success = await CartManager.removeFromCart(productId);

    if (success) {
      setState(() {
        _cartItems.removeAt(index);
        _updateTotalPrice();
      });

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('商品已从购物车移除')),
        );
      }
    } else {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('移除商品失败，请重试')),
        );
      }
    }
  }

  // 更新总价
  void _updateTotalPrice() {
    double total = 0;
    for (var item in _cartItems) {
      total += (item['price'] as double) * (item['quantity'] as int);
    }
    setState(() {
      _totalPrice = total;
    });
  }

  // 确认删除对话框
  void _showDeleteConfirmDialog(int index) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('确认移除'),
        content: const Text('确定要将此商品从购物车中移除吗？'),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('取消'),
          ),
          TextButton(
            onPressed: () {
              Navigator.of(context).pop();
              _removeFromCart(index);
            },
            child: const Text('确定', style: TextStyle(color: Colors.red)),
          ),
        ],
      ),
    );
  }

  // 创建订单
  Future<void> _createOrder() async {
    if (_cartItems.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('购物车为空，请添加商品')),
      );
      return;
    }

    // 实际项目中，应该调用创建订单的API
    // await HttpUtil().post(Api.createOrder, data: { 'products': _cartItems });

    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('订单创建功能开发中')),
    );
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return Scaffold(
        appBar: AppBar(
          title:
              const Text('购物车', style: TextStyle(fontWeight: FontWeight.bold)),
          elevation: 0,
        ),
        body: const Center(child: CircularProgressIndicator()),
      );
    }

    if (_isError) {
      return Scaffold(
        appBar: AppBar(
          title:
              const Text('购物车', style: TextStyle(fontWeight: FontWeight.bold)),
          elevation: 0,
        ),
        body: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Icon(Icons.error_outline, size: 60, color: Colors.grey),
              const SizedBox(height: 16),
              Text(
                _errorMessage,
                style: const TextStyle(color: Colors.grey),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 24),
              ElevatedButton(
                onPressed: _fetchCartItems,
                child: const Text('重新加载'),
              ),
            ],
          ),
        ),
      );
    }

    if (_cartItems.isEmpty) {
      return Scaffold(
        appBar: AppBar(
          title:
              const Text('购物车', style: TextStyle(fontWeight: FontWeight.bold)),
          elevation: 0,
        ),
        body: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Icon(Icons.shopping_cart, size: 70, color: Colors.grey),
              const SizedBox(height: 16),
              const Text(
                '购物车空空如也',
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  color: Colors.grey,
                ),
              ),
              const SizedBox(height: 8),
              const Text(
                '去添加一些商品吧',
                style: TextStyle(color: Colors.grey),
              ),
              const SizedBox(height: 24),
              ElevatedButton(
                onPressed: () {
                  Navigator.of(context).pop(); // 返回首页
                },
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppTheme.primaryColor,
                  padding:
                      const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
                ),
                child: const Text('去购物'),
              ),
            ],
          ),
        ),
      );
    }

    return Scaffold(
      appBar: AppBar(
        title: const Text('购物车', style: TextStyle(fontWeight: FontWeight.bold)),
        elevation: 0,
      ),
      body: Column(
        children: [
          // 商品列表
          Expanded(
            child: ListView.builder(
              padding: const EdgeInsets.all(16),
              itemCount: _cartItems.length,
              itemBuilder: (context, index) {
                return _buildCartItem(index);
              },
            ),
          ),

          // 底部结算栏
          Container(
            padding: const EdgeInsets.all(16),
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
                // 总价
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      const Text('总计'),
                      Text(
                        '¥${_totalPrice.toStringAsFixed(2)}',
                        style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                          color: AppTheme.primaryColor,
                        ),
                      ),
                    ],
                  ),
                ),
                // 结算按钮
                ElevatedButton(
                  onPressed: _createOrder,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppTheme.primaryColor,
                    padding: const EdgeInsets.symmetric(
                        horizontal: 24, vertical: 12),
                  ),
                  child: const Text('结算(${0})'),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildCartItem(int index) {
    final item = _cartItems[index];
    final productId = item['productId'] as int? ?? -1;
    final title = item['title'] as String? ?? '未命名商品';
    final price = item['price'] ?? 0.0;
    final quantity = item['quantity'] as int? ?? 1;

    // 处理图片URL
    String imageUrl = item['mainImageUrl'] as String? ?? '';
    developer.log('原始图片URL: $imageUrl', name: 'CartPage');

    if (imageUrl.isNotEmpty) {
      if (imageUrl.startsWith('http://localhost:8080')) {
        imageUrl = imageUrl.replaceFirst(
            'http://localhost:8080', 'http://192.168.200.30:8080');
        developer.log('转换后的图片URL: $imageUrl', name: 'CartPage');
      } else if (imageUrl.startsWith('/files/')) {
        imageUrl = 'http://192.168.200.30:8080$imageUrl';
        developer.log('转换后的图片URL: $imageUrl', name: 'CartPage');
      } else if (!imageUrl.startsWith('http')) {
        developer.log('无效的图片URL格式: $imageUrl', name: 'CartPage');
        imageUrl = ''; // 重置为空的URL
      }
    }

    // 如果图片URL为空，尝试从商品详情获取
    if (imageUrl.isEmpty) {
      _fetchProductImage(productId).then((url) {
        if (url.isNotEmpty) {
          setState(() {
            _cartItems[index]['mainImageUrl'] = url;
            imageUrl = url; // 更新当前显示的图片URL
          });
          // 更新购物车中的图片URL
          CartManager.updateImageUrl(productId, url);
        }
      });
    }

    return Card(
      margin: const EdgeInsets.symmetric(vertical: 8),
      child: InkWell(
        onTap: () {
          // 点击商品跳转到详情页，传递当前图片URL
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (context) => ProductDetailPage(
                productId: productId,
                mainImageUrl: imageUrl,
              ),
            ),
          ).then((value) {
            // 从详情页返回时，更新购物车中的图片URL
            if (value != null && value is String) {
              setState(() {
                _cartItems[index]['mainImageUrl'] = value;
              });
            }
          });
        },
        child: Padding(
          padding: const EdgeInsets.all(8.0),
          child: Row(
            children: [
              // 商品图片
              ClipRRect(
                borderRadius: BorderRadius.circular(8),
                child: imageUrl.isNotEmpty
                    ? Image.network(
                        imageUrl,
                        width: 80,
                        height: 80,
                        fit: BoxFit.cover,
                        errorBuilder: (context, error, stackTrace) {
                          developer.log('图片加载失败: $error', name: 'CartPage');
                          return Container(
                            width: 80,
                            height: 80,
                            color: Colors.grey[300],
                            child: const Icon(
                              Icons.image_not_supported,
                              size: 30,
                              color: Colors.white,
                            ),
                          );
                        },
                      )
                    : Container(
                        width: 80,
                        height: 80,
                        color: Colors.grey[300],
                        child: const Icon(
                          Icons.image,
                          size: 30,
                          color: Colors.white,
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
                        fontWeight: FontWeight.bold,
                        fontSize: 16,
                      ),
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                    ),
                    const SizedBox(height: 4),
                    Text(
                      '¥${price.toStringAsFixed(2)}',
                      style: TextStyle(
                        color: AppTheme.primaryColor,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 8),

                    // 数量调整
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Row(
                          children: [
                            // 减少按钮
                            InkWell(
                              onTap: () => _updateQuantity(index, quantity - 1),
                              child: Container(
                                padding: const EdgeInsets.all(4),
                                decoration: BoxDecoration(
                                  border: Border.all(color: Colors.grey),
                                  borderRadius: BorderRadius.circular(4),
                                ),
                                child: const Icon(Icons.remove, size: 16),
                              ),
                            ),
                            // 数量显示
                            Container(
                              padding:
                                  const EdgeInsets.symmetric(horizontal: 12),
                              child: Text(
                                quantity.toString(),
                                style: const TextStyle(fontSize: 16),
                              ),
                            ),
                            // 增加按钮
                            InkWell(
                              onTap: () => _updateQuantity(index, quantity + 1),
                              child: Container(
                                padding: const EdgeInsets.all(4),
                                decoration: BoxDecoration(
                                  border: Border.all(color: Colors.grey),
                                  borderRadius: BorderRadius.circular(4),
                                ),
                                child: const Icon(Icons.add, size: 16),
                              ),
                            ),
                          ],
                        ),
                        // 删除按钮
                        IconButton(
                          onPressed: () => _showDeleteConfirmDialog(index),
                          icon: const Icon(Icons.delete_outline),
                          color: Colors.grey,
                          padding: EdgeInsets.zero,
                          constraints: const BoxConstraints(),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  // 从商品详情获取图片
  Future<String> _fetchProductImage(int productId) async {
    try {
      final response = await HttpUtil().get('${Api.productDetail}$productId');
      if (response.isSuccess && response.data != null) {
        String imageUrl = response.data['mainImageUrl'] as String? ?? '';
        if (imageUrl.isNotEmpty) {
          if (imageUrl.startsWith('http://localhost:8080')) {
            imageUrl = imageUrl.replaceFirst(
                'http://localhost:8080', 'http://192.168.200.30:8080');
          } else if (imageUrl.startsWith('/files/')) {
            imageUrl = 'http://192.168.200.30:8080$imageUrl';
          }
          developer.log('从商品详情获取到图片URL: $imageUrl', name: 'CartPage');
          return imageUrl;
        }
      }
    } catch (e) {
      developer.log('获取商品图片异常: $e', name: 'CartPage');
    }
    return '';
  }
}
