import 'package:flutter/material.dart';
import '../../models/order.dart';
import '../../network/api.dart';
import '../../network/http_util.dart';
import '../../config/theme.dart';
import '../../utils/image_url_util.dart';
import 'dart:developer' as developer;
import 'dart:math';

class WaitingShipmentPage extends StatefulWidget {
  const WaitingShipmentPage({Key? key}) : super(key: key);

  @override
  State<WaitingShipmentPage> createState() => _WaitingShipmentPageState();
}

class _WaitingShipmentPageState extends State<WaitingShipmentPage> {
  List<Order> _waitingShipmentOrders = [];
  final Map<int, String> _productImages = {};
  bool _isLoading = true;
  bool _hasError = false;
  String _errorMessage = '';

  @override
  void initState() {
    super.initState();
    _fetchWaitingShipmentOrders();
  }

  // 获取待发货订单
  Future<void> _fetchWaitingShipmentOrders() async {
    setState(() {
      _isLoading = true;
      _hasError = false;
    });

    try {
      developer.log('开始请求待发货订单列表: ${Api.waitingShipmentList}',
          name: 'WaitingShipmentPage');

      // 使用专用接口获取待发货订单列表
      final response = await HttpUtil().get(Api.waitingShipmentList);

      developer.log('待发货订单列表响应: ${response.code}, ${response.message}',
          name: 'WaitingShipmentPage');

      if (response.isSuccess && response.data != null) {
        developer.log('待发货订单数据: ${response.data}', name: 'WaitingShipmentPage');

        // 处理响应数据
        List<dynamic> ordersData = [];
        if (response.data is List) {
          ordersData = response.data as List<dynamic>;
        } else if (response.data is Map && response.data['orders'] is List) {
          ordersData = response.data['orders'] as List<dynamic>;
        }

        // 解析订单数据
        List<Order> orders = [];
        for (var orderJson in ordersData) {
          try {
            final order = Order.fromJson(orderJson);
            orders.add(order);

            // 主动为所有订单获取图片
            _fetchProductImage(order.productId);
          } catch (e) {
            developer.log('订单解析错误: $e, 订单数据: $orderJson',
                name: 'WaitingShipmentPage');
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

        setState(() {
          _waitingShipmentOrders = orders;
          _isLoading = false;
        });
      } else {
        setState(() {
          _isLoading = false;
          _hasError = true;
          _errorMessage = response.message ?? '获取待发货订单失败';
        });
      }
    } catch (e) {
      developer.log('待发货订单列表请求异常: $e', name: 'WaitingShipmentPage', error: e);

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
        developer.log('日期时间格式无法识别: $dateTimeStr', name: 'WaitingShipmentPage');
        return null;
      } catch (e) {
        developer.log('日期时间解析异常: $e, 原始值: $dateTimeStr',
            name: 'WaitingShipmentPage');
        return null;
      }
    }
  }

  // 获取商品图片
  Future<void> _fetchProductImage(int productId) async {
    try {
      developer.log('获取商品图片: productId=$productId',
          name: 'WaitingShipmentPage');

      // 记录当前处理的商品ID，以便在日志中跟踪
      final String logPrefix = '[商品ID:$productId]';
      developer.log('$logPrefix 开始获取商品图片', name: 'WaitingShipmentPage');

      // 使用商品详情接口获取单个商品信息
      final detailResponse =
          await HttpUtil().get('${Api.productDetail}$productId');

      if (detailResponse.isSuccess && detailResponse.data != null) {
        developer.log('$logPrefix 商品详情数据: ${detailResponse.data}',
            name: 'WaitingShipmentPage');

        // 从商品详情中提取mainImageUrl
        final productData = detailResponse.data as Map<String, dynamic>;
        String? imageUrl;

        if (productData.containsKey('mainImageUrl')) {
          imageUrl = productData['mainImageUrl'] as String?;
          developer.log('$logPrefix 从商品详情获取到图片: $imageUrl',
              name: 'WaitingShipmentPage');
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
              name: 'WaitingShipmentPage');
          return; // 已成功获取图片，直接返回
        }
      }

      // 方法2: 尝试通过商品图片接口获取图片
      final imageResponse = await HttpUtil().get('${Api.imageList}$productId');

      if (imageResponse.isSuccess && imageResponse.data != null) {
        developer.log('$logPrefix 商品图片列表数据: ${imageResponse.data}',
            name: 'WaitingShipmentPage');

        if (imageResponse.data is List &&
            (imageResponse.data as List).isNotEmpty) {
          final imageList = imageResponse.data as List;
          String? imageUrl;

          // 查找主图或第一张图片
          for (var image in imageList) {
            if (image is Map<String, dynamic> &&
                image.containsKey('imageUrl')) {
              if (image.containsKey('isMain') && image['isMain'] == true) {
                imageUrl = image['imageUrl'];
                break;
              } else if (imageUrl == null) {
                // 如果没有找到主图，使用第一张图片
                imageUrl = image['imageUrl'];
              }
            }
          }

          if (imageUrl != null && imageUrl.isNotEmpty) {
            final processedUrl = ImageUrlUtil.processImageUrl(imageUrl);
            if (mounted) {
              setState(() {
                _productImages[productId] = processedUrl;
              });
            }
            developer.log('$logPrefix 成功获取商品图片(图片列表): url=$processedUrl',
                name: 'WaitingShipmentPage');
            return;
          }
        }
      } else {
        developer.log('$logPrefix 获取商品图片列表失败: ${imageResponse.message}',
            name: 'WaitingShipmentPage');
      }

      // 方法3: 尝试通过商品列表接口获取商品信息
      final listResponse = await HttpUtil().get(
        Api.productList,
        params: {
          'productId': productId.toString(),
          'pageNum': '1',
          'pageSize': '1'
        },
      );

      if (listResponse.isSuccess && listResponse.data != null) {
        developer.log('$logPrefix 商品列表数据: ${listResponse.data}',
            name: 'WaitingShipmentPage');

        // 检查返回数据结构
        if (listResponse.data is Map<String, dynamic> &&
            listResponse.data['list'] is List &&
            (listResponse.data['list'] as List).isNotEmpty) {
          final productData = (listResponse.data['list'] as List).first;
          if (productData is Map<String, dynamic> &&
              productData.containsKey('mainImageUrl')) {
            final imageUrl = productData['mainImageUrl'] as String?;
            if (imageUrl != null && imageUrl.isNotEmpty) {
              final processedUrl = ImageUrlUtil.processImageUrl(imageUrl);
              if (mounted) {
                setState(() {
                  _productImages[productId] = processedUrl;
                });
              }
              developer.log('$logPrefix 成功获取商品图片(商品列表): url=$processedUrl',
                  name: 'WaitingShipmentPage');
              return;
            }
          }
        }
      } else {
        developer.log('$logPrefix 获取商品列表数据失败: ${listResponse.message}',
            name: 'WaitingShipmentPage');
      }

      developer.log('$logPrefix 无法获取商品图片，尝试所有方法均已失败',
          name: 'WaitingShipmentPage');
    } catch (e) {
      developer.log('获取商品图片异常: $e, productId=$productId',
          name: 'WaitingShipmentPage', error: e);
    }
  }

  // 获取商品图片URL
  String? _getProductImageUrl(Order order) {
    developer.log(
        '获取商品图片URL - 订单ID: ${order.orderId}, 商品ID: ${order.productId}',
        name: 'WaitingShipmentPage');

    // 优先使用订单中的商品图片
    if (order.productImage != null && order.productImage!.isNotEmpty) {
      developer.log('使用订单中的商品图片: ${order.productImage}',
          name: 'WaitingShipmentPage');
      final processedUrl = ImageUrlUtil.processImageUrl(order.productImage);
      developer.log('处理后的订单图片URL: $processedUrl', name: 'WaitingShipmentPage');
      return processedUrl;
    }

    // 再使用从商品列表获取的图片
    if (_productImages.containsKey(order.productId)) {
      developer.log('使用从商品列表获取的图片: ${_productImages[order.productId]}',
          name: 'WaitingShipmentPage');
      return _productImages[order.productId];
    }

    developer.log(
        '订单和商品列表均无图片: orderId=${order.orderId}, productId=${order.productId}',
        name: 'WaitingShipmentPage');
    return null;
  }

  // 催促发货
  Future<void> _sendReminder(Order order) async {
    try {
      // 构建催促发货的消息数据
      Map<String, dynamic> messageData = {
        "orderId": order.orderId,
        "userId": order.userId,
        "sellerId": order.sellerId,
        "content": "亲，请尽快发货，我很期待收到宝贝！",
        "messageType": 1, // 假设1表示催促发货的消息类型
      };

      // 调用发送消息API
      final response = await HttpUtil().post(
        Api.messageSend, // 使用Api类中定义的消息发送路径
        data: messageData,
      );

      if (response.isSuccess) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('已通知卖家尽快发货')),
          );
        }
      } else {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text(response.message ?? '催促发货失败')),
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
        title: const Text('待发货', style: TextStyle(fontWeight: FontWeight.bold)),
        elevation: 0.5,
      ),
      backgroundColor: AppTheme.backgroundColor,
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : _hasError
              ? _buildErrorView()
              : _waitingShipmentOrders.isEmpty
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
            onPressed: _fetchWaitingShipmentOrders,
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
            Icons.local_shipping_outlined,
            size: 80,
            color: Colors.grey,
          ),
          const SizedBox(height: 16),
          const Text(
            '暂无待发货订单',
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
      onRefresh: _fetchWaitingShipmentOrders,
      child: ListView.builder(
        padding: const EdgeInsets.all(12),
        itemCount: _waitingShipmentOrders.length,
        itemBuilder: (context, index) {
          final order = _waitingShipmentOrders[index];
          return _buildOrderCard(order);
        },
      ),
    );
  }

  Widget _buildOrderCard(Order order) {
    // 获取商品图片URL
    final imageUrl = _getProductImageUrl(order);

    // 订单创建时间
    String formattedCreatedTime = '下单时间: ${order.createdTime}';
    if (order.payTime != null && order.payTime!.isNotEmpty) {
      formattedCreatedTime = '付款时间: ${order.payTime}';
    }

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
                    color: Colors.orange.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: const Text(
                    '待发货',
                    style: TextStyle(
                      color: Colors.orange,
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
                // 商品图片
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
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
                                    name: 'WaitingShipmentPage');
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
                                  color: Colors.grey[100],
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
                              decoration: BoxDecoration(
                                color: Colors.grey[200],
                                borderRadius: BorderRadius.circular(8),
                              ),
                              child: const Icon(
                                Icons.image,
                                color: Colors.grey,
                              ),
                            ),
                    ),
                    // 图片来源提示（仅调试使用）
                    const SizedBox(height: 4),
                    SizedBox(
                      width: 80,
                      child: Text(
                        order.productImage != null &&
                                order.productImage!.isNotEmpty
                            ? '订单图片'
                            : imageUrl != null
                                ? '商品图片'
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
                      // 商品标题
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
                      // 创建时间
                      Text(
                        formattedCreatedTime,
                        style: TextStyle(
                          fontSize: 12,
                          color: Colors.grey[600],
                        ),
                      ),
                      const SizedBox(height: 4),
                      // 收货地址，如果有的话
                      if (order.address != null)
                        Row(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const Icon(Icons.location_on,
                                size: 16, color: Colors.grey),
                            const SizedBox(width: 4),
                            Expanded(
                              child: Text(
                                '${order.address!.province} ${order.address!.city} ${order.address!.district} ${order.address!.detailAddress}',
                                style: const TextStyle(fontSize: 13),
                                maxLines: 2,
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
            const SizedBox(height: 12),

            // 价格信息
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Expanded(
                  child: Text(
                    '实付金额',
                    style: TextStyle(color: Colors.grey[600]),
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
                Text(
                  '¥${order.paymentAmount.toStringAsFixed(2)}',
                  style: const TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                    color: Colors.red,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),

            // 操作按钮区
            Row(
              mainAxisAlignment: MainAxisAlignment.end,
              children: [
                OutlinedButton(
                  onPressed: () => _sendReminder(order),
                  style: OutlinedButton.styleFrom(
                    foregroundColor: Theme.of(context).primaryColor,
                    side: BorderSide(color: Theme.of(context).primaryColor),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(20),
                    ),
                  ),
                  child: const Text('催促发货'),
                ),
                const SizedBox(width: 12),
                ElevatedButton(
                  onPressed: () {
                    // 跳转到订单详情页
                    /*Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (context) => OrderDetailPage(orderId: order.orderId),
                      ),
                    );*/
                  },
                  style: ElevatedButton.styleFrom(
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(20),
                    ),
                  ),
                  child: const Text('查看详情'),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
