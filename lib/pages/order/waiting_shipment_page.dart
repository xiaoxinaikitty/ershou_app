import 'package:flutter/material.dart';
import '../../models/order.dart';
import '../../network/api.dart';
import '../../network/http_util.dart';
import '../../config/theme.dart';
import 'dart:developer' as developer;

class WaitingShipmentPage extends StatefulWidget {
  const WaitingShipmentPage({Key? key}) : super(key: key);

  @override
  State<WaitingShipmentPage> createState() => _WaitingShipmentPageState();
}

class _WaitingShipmentPageState extends State<WaitingShipmentPage> {
  List<Order> _waitingShipmentOrders = [];
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
      developer.log('开始请求待发货订单列表: ${Api.orderList}',
          name: 'WaitingShipmentPage');

      final response = await HttpUtil().get(Api.orderList);

      developer.log('订单列表响应: ${response.code}, ${response.message}',
          name: 'WaitingShipmentPage');

      if (response.isSuccess && response.data != null) {
        developer.log('订单数据: ${response.data}', name: 'WaitingShipmentPage');

        // 处理响应数据
        List<dynamic> ordersData = [];
        if (response.data is List) {
          ordersData = response.data as List<dynamic>;
        } else if (response.data is Map && response.data['orders'] is List) {
          ordersData = response.data['orders'] as List<dynamic>;
        }

        // 解析订单数据，筛选出待发货订单(orderStatus=1)
        List<Order> orders = [];
        for (var orderJson in ordersData) {
          try {
            final order = Order.fromJson(orderJson);
            if (order.orderStatus == 1) {
              // 筛选待发货订单
              orders.add(order);
            }
          } catch (e) {
            developer.log('订单解析错误: $e, 订单数据: $orderJson',
                name: 'WaitingShipmentPage');
          }
        }

        setState(() {
          _waitingShipmentOrders = orders;
          _isLoading = false;
        });
      } else {
        setState(() {
          _isLoading = false;
          _hasError = true;
          _errorMessage = response.message ?? '获取订单失败';
        });
      }
    } catch (e) {
      developer.log('订单列表请求异常: $e', name: 'WaitingShipmentPage', error: e);

      setState(() {
        _isLoading = false;
        _hasError = true;
        _errorMessage = '网络错误，请稍后再试 ($e)';
      });
    }
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
                Text(
                  '订单号: ${order.orderNo}',
                  style: const TextStyle(
                    color: Colors.grey,
                    fontSize: 12,
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
                // 商品图片占位
                Container(
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
                            style: const TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.bold,
                              color: Colors.orange,
                            ),
                          ),
                          Column(
                            crossAxisAlignment: CrossAxisAlignment.end,
                            children: [
                              Text(
                                '下单时间: ${order.createdTime.split(' ')[0]}',
                                style: const TextStyle(
                                  color: Colors.grey,
                                  fontSize: 12,
                                ),
                              ),
                              // 移除对不存在的 paymentTime 属性的引用
                              Text(
                                '订单状态: 已付款',
                                style: const TextStyle(
                                  color: Colors.grey,
                                  fontSize: 12,
                                ),
                              ),
                            ],
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ],
            ),

            const SizedBox(height: 12),

            // 收件信息
            if (order.address != null) ...[
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: Colors.grey[100],
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        const Icon(Icons.person, size: 16, color: Colors.grey),
                        const SizedBox(width: 4),
                        Text(
                          '收货人: ${order.address!.receiverName}',
                          style: const TextStyle(fontSize: 13),
                        ),
                        const SizedBox(width: 16),
                        const Icon(Icons.phone, size: 16, color: Colors.grey),
                        const SizedBox(width: 4),
                        Text(
                          order.address!.receiverPhone,
                          style: const TextStyle(fontSize: 13),
                        ),
                      ],
                    ),
                    const SizedBox(height: 4),
                    Row(
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
              const SizedBox(height: 12),
            ],

            // 价格信息
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  '商品金额',
                  style: TextStyle(color: Colors.grey[600]),
                ),
                Text('¥${order.orderAmount.toStringAsFixed(2)}'),
              ],
            ),
            const SizedBox(height: 4),

            if (order.deliveryFee != null) ...[
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    '运费',
                    style: TextStyle(color: Colors.grey[600]),
                  ),
                  Text('¥${order.deliveryFee!.toStringAsFixed(2)}'),
                ],
              ),
              const SizedBox(height: 4),
            ],

            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text(
                  '实付款',
                  style: TextStyle(
                    fontWeight: FontWeight.bold,
                  ),
                ),
                Text(
                  '¥${order.paymentAmount.toStringAsFixed(2)}',
                  style: const TextStyle(
                    fontWeight: FontWeight.bold,
                    fontSize: 16,
                    color: Colors.orange,
                  ),
                ),
              ],
            ),

            const Divider(),

            // 备注信息
            if (order.remark != null && order.remark!.isNotEmpty) ...[
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    '备注: ',
                    style: TextStyle(
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  Expanded(
                    child: Text(
                      order.remark!,
                      style: const TextStyle(fontSize: 13),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 12),
            ],

            // 催促发货按钮
            Row(
              mainAxisAlignment: MainAxisAlignment.end,
              children: [
                ElevatedButton.icon(
                  onPressed: () => _sendReminder(order),
                  icon: const Icon(Icons.notifications_active, size: 16),
                  label: const Text('催一催'),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.orange,
                    foregroundColor: Colors.white,
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
