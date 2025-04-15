import 'package:flutter/material.dart';
import '../../models/order.dart';
import '../../network/api.dart';
import '../../network/http_util.dart';
import '../../config/theme.dart';
import 'dart:developer' as developer;

class OrderReceivingPage extends StatefulWidget {
  const OrderReceivingPage({Key? key}) : super(key: key);

  @override
  State<OrderReceivingPage> createState() => _OrderReceivingPageState();
}

class _OrderReceivingPageState extends State<OrderReceivingPage> {
  List<Order> _receivingOrders = [];
  bool _isLoading = true;
  bool _hasError = false;
  String _errorMessage = '';

  @override
  void initState() {
    super.initState();
    _fetchReceivingOrders();
  }

  // 获取待收货订单
  Future<void> _fetchReceivingOrders() async {
    setState(() {
      _isLoading = true;
      _hasError = false;
    });

    try {
      developer.log('开始请求待收货订单列表: ${Api.orderList}',
          name: 'OrderReceivingPage');

      final response = await HttpUtil().get(Api.orderList);

      developer.log('订单列表响应: ${response.code}, ${response.message}',
          name: 'OrderReceivingPage');

      if (response.isSuccess && response.data != null) {
        developer.log('订单数据: ${response.data}', name: 'OrderReceivingPage');

        // 处理响应数据
        List<dynamic> ordersData = [];
        if (response.data is List) {
          ordersData = response.data as List<dynamic>;
        } else if (response.data is Map && response.data['orders'] is List) {
          ordersData = response.data['orders'] as List<dynamic>;
        }

        // 解析订单数据，筛选出待收货订单(orderStatus=2)
        List<Order> orders = [];
        for (var orderJson in ordersData) {
          try {
            final order = Order.fromJson(orderJson);
            if (order.orderStatus == 2) {
              // 筛选待收货订单
              orders.add(order);
            }
          } catch (e) {
            developer.log('订单解析错误: $e, 订单数据: $orderJson',
                name: 'OrderReceivingPage');
          }
        }

        setState(() {
          _receivingOrders = orders;
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
      developer.log('订单列表请求异常: $e', name: 'OrderReceivingPage', error: e);

      setState(() {
        _isLoading = false;
        _hasError = true;
        _errorMessage = '网络错误，请稍后再试 ($e)';
      });
    }
  }

  // 确认收货
  Future<void> _confirmReceipt(Order order) async {
    try {
      // 构建确认收货的请求数据
      Map<String, dynamic> confirmData = {
        "orderId": order.orderId,
        "userId": order.userId,
      };

      // 调用确认收货API
      final response = await HttpUtil().put(
        Api.orderConfirmReceipt,
        data: confirmData,
      );

      if (response.isSuccess) {
        // 成功确认收货后，刷新订单列表
        _fetchReceivingOrders();

        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('已确认收货')),
          );
        }
      } else {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text(response.message ?? '确认收货失败')),
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
        title: const Text('待收货', style: TextStyle(fontWeight: FontWeight.bold)),
        elevation: 0.5,
      ),
      backgroundColor: AppTheme.backgroundColor,
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : _hasError
              ? _buildErrorView()
              : _receivingOrders.isEmpty
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
            onPressed: _fetchReceivingOrders,
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
            Icons.inventory_2_outlined,
            size: 80,
            color: Colors.grey,
          ),
          const SizedBox(height: 16),
          const Text(
            '暂无待收货订单',
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
      onRefresh: _fetchReceivingOrders,
      child: ListView.builder(
        padding: const EdgeInsets.all(12),
        itemCount: _receivingOrders.length,
        itemBuilder: (context, index) {
          final order = _receivingOrders[index];
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
                GestureDetector(
                  onTap: () {
                    // 点击跳转到物流详情页面
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(content: Text('正在查询物流信息...')),
                    );
                    // 这里可以添加跳转到物流详情页的逻辑
                    // Navigator.push(
                    //   context,
                    //   MaterialPageRoute(
                    //     builder: (context) => LogisticsDetailPage(orderId: order.orderId),
                    //   ),
                    // );
                  },
                  child: Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 8,
                      vertical: 2,
                    ),
                    decoration: BoxDecoration(
                      color: Colors.blue.withOpacity(0.1),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Row(
                      children: const [
                        Icon(Icons.local_shipping,
                            size: 14, color: Colors.blue),
                        SizedBox(width: 4),
                        Text(
                          '待收货',
                          style: TextStyle(
                            color: Colors.blue,
                            fontSize: 12,
                          ),
                        ),
                      ],
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
                              color: Colors.blue,
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
                              Text(
                                '订单状态: 待收货',
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
                    color: Colors.blue,
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

            // 确认收货按钮
            Row(
              mainAxisAlignment: MainAxisAlignment.end,
              children: [
                ElevatedButton(
                  onPressed: () => _confirmReceipt(order),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.blue,
                    foregroundColor: Colors.white,
                  ),
                  child: const Text('确认收货'),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
