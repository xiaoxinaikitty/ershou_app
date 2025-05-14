import 'package:flutter/material.dart';
import '../../models/order.dart';
import '../../network/api.dart';
import '../../network/http_util.dart';
import '../../config/theme.dart';
import '../../utils/image_url_util.dart'; // 导入图片URL处理工具
import 'dart:developer' as developer; // 添加开发日志工具
import 'dart:math'; // 添加dart:math库

class PendingPaymentPage extends StatefulWidget {
  const PendingPaymentPage({Key? key}) : super(key: key);

  @override
  State<PendingPaymentPage> createState() => _PendingPaymentPageState();
}

class _PendingPaymentPageState extends State<PendingPaymentPage> {
  List<Order> _pendingOrders = [];
  // 用于存储商品图片的映射，key为productId
  final Map<int, String> _productImages = {};
  bool _isLoading = true;
  bool _hasError = false;
  String _errorMessage = '';

  @override
  void initState() {
    super.initState();
    _fetchPendingOrders();
  }

  // 获取待付款订单
  Future<void> _fetchPendingOrders() async {
    setState(() {
      _isLoading = true;
      _hasError = false;
    });

    try {
      // 添加日志记录API请求开始
      developer.log('开始请求待付款订单列表: ${Api.pendingPaymentList}',
          name: 'PendingPaymentPage');

      // 使用新的专用接口获取待付款订单列表
      final response = await HttpUtil().get(Api.pendingPaymentList);

      // 添加日志记录API响应
      developer.log('待付款订单列表响应: ${response.code}, ${response.message}',
          name: 'PendingPaymentPage');

      if (response.isSuccess && response.data != null) {
        // 尝试解析数据之前记录数据格式
        developer.log('待付款订单数据: ${response.data}', name: 'PendingPaymentPage');

        // 当response.data不是列表时提供保护
        List<dynamic> ordersData = [];
        if (response.data is List) {
          ordersData = response.data as List<dynamic>;
        } else if (response.data is Map && response.data['orders'] is List) {
          // 如果数据被包装在orders字段中
          ordersData = response.data['orders'] as List<dynamic>;
        }

        // 安全地解析每个订单对象
        List<Order> orders = [];
        for (var orderJson in ordersData) {
          try {
            final order = Order.fromJson(orderJson);
            orders.add(order);

            // 主动为所有订单获取图片
            _fetchProductImage(order.productId);
          } catch (e) {
            developer.log('订单解析错误: $e, 订单数据: $orderJson',
                name: 'PendingPaymentPage');
          }
        }

        // 按照下单时间（createdTime）降序排序订单，最新的订单排在前面
        orders.sort((a, b) {
          // 解析下单时间，转换为DateTime进行比较
          DateTime? timeA = _parseDateTime(a.createdTime);
          DateTime? timeB = _parseDateTime(b.createdTime);

          // 如果日期解析出错，使用当前时间作为备用
          timeA ??= DateTime.now();
          timeB ??= DateTime.now();

          // 降序排列，最新的在前面
          return timeB.compareTo(timeA);
        });

        // 记录排序后的订单顺序
        if (orders.isNotEmpty) {
          developer.log(
              '订单已按照下单时间降序排列，第一个订单时间: ${orders.first.createdTime}，最后一个订单时间: ${orders.last.createdTime}',
              name: 'PendingPaymentPage');
        }

        setState(() {
          _pendingOrders = orders;
          _isLoading = false;
        });
      } else {
        setState(() {
          _isLoading = false;
          _hasError = true;
          _errorMessage = response.message ?? '获取待付款订单失败';
        });
      }
    } catch (e) {
      // 记录详细的错误信息
      developer.log('待付款订单列表请求异常: $e', name: 'PendingPaymentPage', error: e);

      setState(() {
        _isLoading = false;
        _hasError = true;
        _errorMessage = '网络错误，请稍后再试 ($e)';
      });
    }
  }

  // 解析日期时间字符串为DateTime对象
  DateTime? _parseDateTime(String dateTimeStr) {
    try {
      // 尝试解析标准格式的日期时间
      return DateTime.parse(dateTimeStr);
    } catch (e) {
      try {
        // 如果标准格式解析失败，尝试解析常见的自定义格式
        // "yyyy-MM-dd HH:mm:ss" 格式
        final parts = dateTimeStr.split(' ');
        if (parts.length == 2) {
          final dateParts = parts[0].split('-');
          final timeParts = parts[1].split(':');

          if (dateParts.length == 3 && timeParts.length >= 2) {
            return DateTime(
              int.parse(dateParts[0]), // 年
              int.parse(dateParts[1]), // 月
              int.parse(dateParts[2]), // 日
              int.parse(timeParts[0]), // 时
              int.parse(timeParts[1]), // 分
              timeParts.length > 2 ? int.parse(timeParts[2]) : 0, // 秒
            );
          }
        }
        developer.log('日期时间格式无法识别: $dateTimeStr', name: 'PendingPaymentPage');
        return null;
      } catch (e) {
        developer.log('日期时间解析异常: $e, 原始值: $dateTimeStr',
            name: 'PendingPaymentPage');
        return null;
      }
    }
  }

  // 获取商品图片
  Future<void> _fetchProductImage(int productId) async {
    try {
      developer.log('获取商品图片: productId=$productId', name: 'PendingPaymentPage');

      // 记录当前处理的商品ID，以便在日志中跟踪
      final String logPrefix = '[商品ID:$productId]';
      developer.log('$logPrefix 开始获取商品图片', name: 'PendingPaymentPage');

      // 方法1: 直接使用商品详情接口获取单个商品信息
      final detailResponse =
          await HttpUtil().get('${Api.productDetail}$productId');

      if (detailResponse.isSuccess && detailResponse.data != null) {
        developer.log('$logPrefix 商品详情数据: ${detailResponse.data}',
            name: 'PendingPaymentPage');

        // 从商品详情中提取mainImageUrl
        final productData = detailResponse.data as Map<String, dynamic>;
        String? imageUrl;

        if (productData.containsKey('mainImageUrl')) {
          imageUrl = productData['mainImageUrl'] as String?;
          developer.log('$logPrefix 从商品详情获取到图片: $imageUrl',
              name: 'PendingPaymentPage');
        }

        // 如果从商品详情找到图片URL
        if (imageUrl != null && imageUrl.isNotEmpty) {
          final processedUrl = ImageUrlUtil.processImageUrl(imageUrl);
          if (mounted) {
            setState(() {
              _productImages[productId] = processedUrl;
            });
          }
          developer.log('$logPrefix 成功获取商品图片(详情): url=$processedUrl',
              name: 'PendingPaymentPage');
          return; // 已成功获取图片，直接返回
        }
      } else {
        developer.log('$logPrefix 获取商品详情失败: ${detailResponse.message}',
            name: 'PendingPaymentPage');
      }

      // 方法2: 尝试使用商品列表接口获取
      // 注意：使用了严格的过滤，确保只返回指定ID的商品
      final listResponse = await HttpUtil().get(
        Api.productList,
        params: {
          'productId': productId.toString(),
          'pageNum': '1',
          'pageSize': '10'
        },
      );

      if (listResponse.isSuccess && listResponse.data != null) {
        developer.log('$logPrefix 商品列表数据: ${listResponse.data}',
            name: 'PendingPaymentPage');

        // 检查返回数据结构并查找指定ID的商品
        if (listResponse.data is Map<String, dynamic> &&
            listResponse.data['list'] is List) {
          final productList = listResponse.data['list'] as List;

          // 过滤出指定ID的商品
          final matchingProducts = productList
              .where((item) =>
                  item is Map<String, dynamic> &&
                  item['productId'] == productId)
              .toList();

          if (matchingProducts.isNotEmpty) {
            final specificProduct =
                matchingProducts.first as Map<String, dynamic>;
            developer.log('$logPrefix 从列表中找到指定商品: $specificProduct',
                name: 'PendingPaymentPage');

            // 获取图片URL
            String? imageUrl;
            if (specificProduct.containsKey('mainImageUrl')) {
              imageUrl = specificProduct['mainImageUrl'] as String?;
              developer.log('$logPrefix 从列表获取到图片: $imageUrl',
                  name: 'PendingPaymentPage');
            }

            if (imageUrl != null && imageUrl.isNotEmpty) {
              final processedUrl = ImageUrlUtil.processImageUrl(imageUrl);
              if (mounted) {
                setState(() {
                  _productImages[productId] = processedUrl;
                });
              }
              developer.log('$logPrefix 成功获取商品图片(列表): url=$processedUrl',
                  name: 'PendingPaymentPage');
              return; // 已成功获取图片，直接返回
            }
          } else {
            developer.log('$logPrefix 在商品列表中未找到指定ID的商品',
                name: 'PendingPaymentPage');
          }
        }
      }

      // 方法3: 尝试从推荐接口获取
      _fetchProductImageFromRecommendation(productId);
    } catch (e) {
      developer.log('获取商品图片异常: $e', name: 'PendingPaymentPage', error: e);
      // 出错时尝试备用方法
      _fetchProductImageFromRecommendation(productId);
    }
  }

  // 从推荐接口获取商品图片 (备用方法)
  Future<void> _fetchProductImageFromRecommendation(int productId) async {
    try {
      final String logPrefix = '[商品ID:$productId]';
      developer.log('$logPrefix 尝试从推荐接口获取商品图片', name: 'PendingPaymentPage');

      // 使用推荐模块的相似商品接口
      final response = await HttpUtil()
          .get('${Api.recommendSimilar}/$productId', params: {'limit': '5'});

      if (response.isSuccess &&
          response.data != null &&
          response.data is List &&
          (response.data as List).isNotEmpty) {
        // 查找匹配当前商品ID的推荐项
        final recommendations = response.data as List;

        // 首先查找完全匹配的商品
        var matchingItem = recommendations.firstWhere(
          (item) =>
              item is Map<String, dynamic> && item['productId'] == productId,
          orElse: () => null,
        );

        // 如果没有找到完全匹配的，使用第一个推荐商品
        if (matchingItem == null && recommendations.isNotEmpty) {
          matchingItem = recommendations.first;
        }

        if (matchingItem != null && matchingItem is Map<String, dynamic>) {
          final recommendData = matchingItem;

          if (recommendData.containsKey('mainImage')) {
            String? imageUrl = recommendData['mainImage'] as String?;

            if (imageUrl != null && imageUrl.isNotEmpty) {
              final processedUrl = ImageUrlUtil.processImageUrl(imageUrl);
              if (mounted) {
                setState(() {
                  _productImages[productId] = processedUrl;
                });
              }
              developer.log('$logPrefix 成功从推荐接口获取商品图片: url=$processedUrl',
                  name: 'PendingPaymentPage');
              return;
            }
          }
        }
      }

      developer.log('$logPrefix 从推荐接口获取商品图片失败', name: 'PendingPaymentPage');
    } catch (e) {
      developer.log('从推荐接口获取商品图片异常: $e', name: 'PendingPaymentPage', error: e);
    }
  }

  // 获取商品图片URL
  String? _getProductImageUrl(Order order) {
    developer.log(
        '获取商品图片URL - 订单ID: ${order.orderId}, 商品ID: ${order.productId}',
        name: 'PendingPaymentPage');

    // 优先使用订单中的商品图片
    if (order.productImage != null && order.productImage!.isNotEmpty) {
      developer.log('使用订单中的商品图片: ${order.productImage}',
          name: 'PendingPaymentPage');
      final processedUrl = ImageUrlUtil.processImageUrl(order.productImage);
      developer.log('处理后的订单图片URL: $processedUrl', name: 'PendingPaymentPage');
      return processedUrl;
    }

    // 再使用从商品列表获取的图片
    if (_productImages.containsKey(order.productId)) {
      developer.log('使用从商品列表获取的图片: ${_productImages[order.productId]}',
          name: 'PendingPaymentPage');
      return _productImages[order.productId];
    }

    developer.log(
        '订单和商品列表均无图片: orderId=${order.orderId}, productId=${order.productId}',
        name: 'PendingPaymentPage');
    return null;
  }

  // 支付订单
  Future<void> _payOrder(Order order) async {
    try {
      // 构建支付参数
      Map<String, dynamic> payData = {
        "orderId": order.orderId,
        "userId": order.userId,
        "paymentType": order.paymentType,
        "paymentChannel": 1, // 默认使用支付宝
        "transactionNo": "ALI${DateTime.now().millisecondsSinceEpoch}"
      };

      final response = await HttpUtil().put(Api.orderPay, data: payData);

      if (response.isSuccess) {
        // 支付成功，刷新订单列表
        _fetchPendingOrders();

        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('支付成功')),
          );
        }
      } else {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text(response.message ?? '支付失败')),
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

  // 取消订单
  Future<void> _cancelOrder(Order order) async {
    try {
      // 构建取消订单参数
      Map<String, dynamic> cancelData = {
        "orderId": order.orderId,
        "remark": "用户主动取消订单"
      };

      final response = await HttpUtil().put(Api.orderCancel, data: cancelData);

      if (response.isSuccess) {
        // 取消成功，刷新订单列表
        _fetchPendingOrders();

        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('订单已取消')),
          );
        }
      } else {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text(response.message ?? '取消订单失败')),
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
        title: const Text('待付款', style: TextStyle(fontWeight: FontWeight.bold)),
        elevation: 0.5,
      ),
      backgroundColor: AppTheme.backgroundColor,
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : _hasError
              ? _buildErrorView()
              : _pendingOrders.isEmpty
                  ? _buildEmptyView()
                  : _buildOrderList(),
    );
  }

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
            style: const TextStyle(color: Colors.grey),
          ),
          const SizedBox(height: 16),
          ElevatedButton(
            onPressed: _fetchPendingOrders,
            child: const Text('重新加载'),
          ),
        ],
      ),
    );
  }

  Widget _buildEmptyView() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const Icon(
            Icons.receipt_long,
            size: 80,
            color: Colors.grey,
          ),
          const SizedBox(height: 16),
          const Text(
            '暂无待付款订单',
            style: TextStyle(
              fontSize: 16,
              color: Colors.grey,
              fontWeight: FontWeight.w500,
            ),
          ),
          const SizedBox(height: 8),
          const Text(
            '您可以去商城浏览更多商品',
            style: TextStyle(color: Colors.grey),
          ),
          const SizedBox(height: 24),
          ElevatedButton(
            onPressed: () {
              Navigator.pop(context);
            },
            child: const Text('去购物'),
          ),
        ],
      ),
    );
  }

  Widget _buildOrderList() {
    return RefreshIndicator(
      onRefresh: _fetchPendingOrders,
      child: ListView.builder(
        padding: const EdgeInsets.all(12),
        itemCount: _pendingOrders.length,
        itemBuilder: (context, index) {
          final order = _pendingOrders[index];
          return _buildOrderCard(order);
        },
      ),
    );
  }

  Widget _buildOrderCard(Order order) {
    // 获取商品图片URL
    final imageUrl = _getProductImageUrl(order);

    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      elevation: 1,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
      ),
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // 订单头部信息
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Expanded(
                  child: Text(
                    '订单号: ${order.orderNo}',
                    style: const TextStyle(
                      color: Colors.grey,
                      fontSize: 12,
                    ),
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 8,
                    vertical: 2,
                  ),
                  decoration: BoxDecoration(
                    color: AppTheme.primaryColor.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Text(
                    '待付款',
                    style: TextStyle(
                      color: AppTheme.primaryColor,
                      fontSize: 12,
                    ),
                  ),
                ),
              ],
            ),
            const Divider(),

            // 商品信息
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // 商品图片部分 - 重写以修复括号问题
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // 商品图片
                    ClipRRect(
                      borderRadius: BorderRadius.circular(8),
                      child: imageUrl != null && imageUrl.isNotEmpty
                          ? Image.network(
                              imageUrl,
                              width: 80,
                              height: 80,
                              fit: BoxFit.cover,
                              errorBuilder: (context, error, stackTrace) {
                                developer.log('图片加载错误: $error',
                                    name: 'PendingPaymentPage');
                                return Container(
                                  width: 80,
                                  height: 80,
                                  color: Colors.grey[200],
                                  child: const Column(
                                    mainAxisAlignment: MainAxisAlignment.center,
                                    children: [
                                      Icon(Icons.broken_image,
                                          color: Colors.grey),
                                      SizedBox(height: 4),
                                      Text(
                                        '加载失败',
                                        style: TextStyle(
                                          fontSize: 10,
                                          color: Colors.grey,
                                        ),
                                      ),
                                    ],
                                  ),
                                );
                              },
                              loadingBuilder:
                                  (context, child, loadingProgress) {
                                if (loadingProgress == null) return child;
                                return Container(
                                  width: 80,
                                  height: 80,
                                  color: Colors.grey[200],
                                  child: const Center(
                                    child: CircularProgressIndicator(
                                      strokeWidth: 2,
                                    ),
                                  ),
                                );
                              },
                            )
                          : Container(
                              width: 80,
                              height: 80,
                              color: Colors.grey[200],
                              child: const Column(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  Icon(Icons.image, color: Colors.grey),
                                  SizedBox(height: 4),
                                  Text(
                                    '暂无图片',
                                    style: TextStyle(
                                      fontSize: 10,
                                      color: Colors.grey,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                    ),
                    // 调试信息
                    SizedBox(
                      width: 80,
                      child: Text(
                        order.productImage != null &&
                                order.productImage!.isNotEmpty
                            ? '订单图片'
                            : imageUrl != null && imageUrl.isNotEmpty
                                ? '列表图片'
                                : '无图片',
                        style: const TextStyle(fontSize: 8, color: Colors.grey),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        textAlign: TextAlign.center,
                      ),
                    ),
                  ],
                ),
                const SizedBox(width: 12),
                // 商品详情
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisAlignment: MainAxisAlignment.start,
                    children: [
                      Text(
                        order.productTitle,
                        style: const TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.w500,
                        ),
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                      ),
                      const SizedBox(height: 8),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text(
                            '¥${order.paymentAmount.toStringAsFixed(2)}',
                            style: TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.bold,
                              color: AppTheme.primaryColor,
                            ),
                          ),
                          Expanded(
                            child: Text(
                              '下单时间: ${order.createdTime.split(' ')[0]}',
                              style: const TextStyle(
                                color: Colors.grey,
                                fontSize: 12,
                              ),
                              overflow: TextOverflow.ellipsis,
                              textAlign: TextAlign.end,
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ],
            ),

            const SizedBox(height: 12),

            // 商品单价信息
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Expanded(
                  child: Text(
                    '商品金额',
                    style: TextStyle(color: Colors.grey[600]),
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
                Text('¥${order.orderAmount.toStringAsFixed(2)}'),
              ],
            ),
            const SizedBox(height: 4),

            if (order.deliveryFee != null) ...[
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Expanded(
                    child: Text(
                      '运费',
                      style: TextStyle(color: Colors.grey[600]),
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                  Text('¥${order.deliveryFee!.toStringAsFixed(2)}'),
                ],
              ),
              const SizedBox(height: 4),
            ],

            // 总价信息
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Expanded(
                  child: Text(
                    '实付款',
                    style: TextStyle(
                      fontWeight: FontWeight.bold,
                    ),
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
                Text(
                  '¥${order.paymentAmount.toStringAsFixed(2)}',
                  style: TextStyle(
                    fontWeight: FontWeight.bold,
                    fontSize: 16,
                    color: AppTheme.primaryColor,
                  ),
                ),
              ],
            ),

            const Divider(),

            // 按钮组
            SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              child: Row(
                mainAxisAlignment: MainAxisAlignment.end,
                children: [
                  OutlinedButton(
                    onPressed: () => _cancelOrder(order),
                    style: OutlinedButton.styleFrom(
                      side: BorderSide(color: Colors.grey[300]!),
                    ),
                    child: const Text(
                      '取消订单',
                      style: TextStyle(color: Colors.black54),
                    ),
                  ),
                  const SizedBox(width: 12),
                  ElevatedButton(
                    onPressed: () => _payOrder(order),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppTheme.primaryColor,
                    ),
                    child: const Text('去支付'),
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
