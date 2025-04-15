import 'package:flutter/material.dart';
import '../../models/order.dart';
import '../../network/api.dart';
import '../../network/http_util.dart';
import '../../config/theme.dart';
import 'dart:developer' as developer; // 添加开发日志工具

class PendingPaymentPage extends StatefulWidget {
  const PendingPaymentPage({Key? key}) : super(key: key);

  @override
  State<PendingPaymentPage> createState() => _PendingPaymentPageState();
}

class _PendingPaymentPageState extends State<PendingPaymentPage> {
  List<Order> _pendingOrders = [];
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
      developer.log('开始请求订单列表: ${Api.orderList}', name: 'PendingPaymentPage');

      final response = await HttpUtil().get(Api.orderList);

      // 添加日志记录API响应
      developer.log('订单列表响应: ${response.code}, ${response.message}',
          name: 'PendingPaymentPage');

      if (response.isSuccess && response.data != null) {
        // 尝试解析数据之前记录数据格式
        developer.log('订单数据: ${response.data}', name: 'PendingPaymentPage');

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
            if (order.orderStatus == 0) {
              // 筛选待付款订单
              orders.add(order);
            }
          } catch (e) {
            developer.log('订单解析错误: $e, 订单数据: $orderJson',
                name: 'PendingPaymentPage');
          }
        }

        setState(() {
          _pendingOrders = orders;
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
      // 记录详细的错误信息
      developer.log('订单列表请求异常: $e', name: 'PendingPaymentPage', error: e);

      setState(() {
        _isLoading = false;
        _hasError = true;
        _errorMessage = '网络错误，请稍后再试 ($e)';
      });
    }
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
                            style: TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.bold,
                              color: AppTheme.primaryColor,
                            ),
                          ),
                          Text(
                            '下单时间: ${order.createdTime.split(' ')[0]}',
                            style: const TextStyle(
                              color: Colors.grey,
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

            const SizedBox(height: 12),

            // 商品单价信息
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

            // 总价信息
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
            Row(
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
          ],
        ),
      ),
    );
  }
}
