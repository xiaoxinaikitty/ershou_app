import 'package:flutter/material.dart';
import '../../../models/order.dart';
import '../../../network/api.dart';
import '../../../network/http_util.dart';
import '../../../config/theme.dart';
import 'dart:developer' as developer;

class LogisticsDetailPage extends StatefulWidget {
  final int orderId;
  final String? deliveryCompany;
  final String? trackingNumber;

  const LogisticsDetailPage({
    Key? key,
    required this.orderId,
    this.deliveryCompany,
    this.trackingNumber,
  }) : super(key: key);

  @override
  State<LogisticsDetailPage> createState() => _LogisticsDetailPageState();
}

class _LogisticsDetailPageState extends State<LogisticsDetailPage> {
  bool _isLoading = true;
  bool _hasError = false;
  String _errorMessage = '';

  // 物流详情数据
  String? _deliveryCompany;
  String? _trackingNumber;
  String? _receiverName;
  String? _receiverPhone;
  String? _receiverAddress;
  List<Map<String, dynamic>> _logisticsTraces = [];

  @override
  void initState() {
    super.initState();
    _fetchLogisticsDetails();
  }

  Future<void> _fetchLogisticsDetails() async {
    setState(() {
      _isLoading = true;
      _hasError = false;
    });

    try {
      // 设置初始值
      if (widget.deliveryCompany != null) {
        _deliveryCompany = widget.deliveryCompany;
      }
      if (widget.trackingNumber != null) {
        _trackingNumber = widget.trackingNumber;
      }

      developer.log('开始请求物流信息: 订单ID ${widget.orderId}',
          name: 'LogisticsDetailPage');

      // 这里应该是调用物流查询API，由于API可能未实现，使用模拟数据
      // final response = await HttpUtil().get('${Api.orderLogistics}/${widget.orderId}');

      // 模拟网络请求延迟
      await Future.delayed(const Duration(seconds: 1));

      // 模拟物流数据
      final mockData = {
        'deliveryCompany': _deliveryCompany ?? '京东物流',
        'trackingNumber': _trackingNumber ?? 'JD${10000000 + widget.orderId}',
        'receiverInfo': {
          'name': '张三',
          'phone': '138****8000',
          'address': '北京市海淀区中关村大街1号',
        },
        'traces': [
          {
            'time': '2025-04-15 15:30:00',
            'content': '您的快件已被签收，感谢使用京东物流，期待再次为您服务。',
            'status': 'delivered'
          },
          {
            'time': '2025-04-15 09:25:36',
            'content': '快件正在派送中，请您准备签收，如有问题请联系快递员13800138000。',
            'status': 'delivering'
          },
          {
            'time': '2025-04-15 07:15:22',
            'content': '快件已到达北京市海淀区中关村派送点。',
            'status': 'transit'
          },
          {
            'time': '2025-04-14 22:30:15',
            'content': '快件已到达北京市分拣中心。',
            'status': 'transit'
          },
          {
            'time': '2025-04-14 18:25:40',
            'content': '快件已从上海市转运中心发出。',
            'status': 'transit'
          },
          {
            'time': '2025-04-14 15:10:05',
            'content': '卖家已发货，并成功揽件。',
            'status': 'pickup'
          }
        ]
      };

      // 解析数据
      _deliveryCompany = mockData['deliveryCompany'] as String;
      _trackingNumber = mockData['trackingNumber'] as String;

      final receiverInfo = mockData['receiverInfo'] as Map<String, dynamic>;
      _receiverName = receiverInfo['name'] as String;
      _receiverPhone = receiverInfo['phone'] as String;
      _receiverAddress = receiverInfo['address'] as String;

      _logisticsTraces = (mockData['traces'] as List)
          .map((trace) => trace as Map<String, dynamic>)
          .toList();

      setState(() {
        _isLoading = false;
      });

      /*
      // 实际API调用逻辑
      if (response.isSuccess && response.data != null) {
        final logisticsData = response.data as Map<String, dynamic>;
        
        _deliveryCompany = logisticsData['deliveryCompany'] as String;
        _trackingNumber = logisticsData['trackingNumber'] as String;
        
        final receiverInfo = logisticsData['receiverInfo'] as Map<String, dynamic>;
        _receiverName = receiverInfo['name'] as String;
        _receiverPhone = receiverInfo['phone'] as String;
        _receiverAddress = receiverInfo['address'] as String;
        
        _logisticsTraces = (logisticsData['traces'] as List)
            .map((trace) => trace as Map<String, dynamic>)
            .toList();

        setState(() {
          _isLoading = false;
        });
      } else {
        setState(() {
          _isLoading = false;
          _hasError = true;
          _errorMessage = response.message ?? '获取物流信息失败';
        });
      }
      */
    } catch (e) {
      developer.log('获取物流信息异常: $e', name: 'LogisticsDetailPage', error: e);

      setState(() {
        _isLoading = false;
        _hasError = true;
        _errorMessage = '网络错误，请稍后再试 ($e)';
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title:
            const Text('物流详情', style: TextStyle(fontWeight: FontWeight.bold)),
        elevation: 0.5,
      ),
      backgroundColor: Colors.white,
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : _hasError
              ? _buildErrorView()
              : _buildLogisticsDetails(),
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
            onPressed: _fetchLogisticsDetails,
            child: const Text('重新加载'),
          ),
        ],
      ),
    );
  }

  Widget _buildLogisticsDetails() {
    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        // 物流信息卡片
        Card(
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
          elevation: 1,
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // 快递公司和单号
                Row(
                  children: [
                    const Icon(Icons.local_shipping,
                        color: Colors.blue, size: 20),
                    const SizedBox(width: 8),
                    Text(
                      '$_deliveryCompany: $_trackingNumber',
                      style: const TextStyle(fontWeight: FontWeight.bold),
                    ),
                    const Spacer(),
                    OutlinedButton(
                      onPressed: () {
                        // 复制单号到剪贴板
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(content: Text('已复制运单号到剪贴板')),
                        );
                      },
                      style: OutlinedButton.styleFrom(
                        minimumSize: Size.zero,
                        padding: const EdgeInsets.symmetric(
                            horizontal: 8, vertical: 4),
                        side: const BorderSide(color: Colors.blue),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                      ),
                      child: const Text('复制单号', style: TextStyle(fontSize: 12)),
                    ),
                  ],
                ),
                const Divider(height: 24),

                // 收件人信息
                Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Icon(Icons.person_outline,
                        color: Colors.grey, size: 20),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text('收件人: $_receiverName ($_receiverPhone)'),
                          const SizedBox(height: 4),
                          Text(
                            '收货地址: $_receiverAddress',
                            style: TextStyle(
                                color: Colors.grey[600], fontSize: 13),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),

        const SizedBox(height: 16),

        // 物流跟踪信息
        const Text(
          '物流跟踪',
          style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
        ),
        const SizedBox(height: 12),

        // 物流轨迹时间线
        _buildLogisticsTimeline(),
      ],
    );
  }

  Widget _buildLogisticsTimeline() {
    return ListView.builder(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      itemCount: _logisticsTraces.length,
      itemBuilder: (context, index) {
        final trace = _logisticsTraces[index];
        final isFirst = index == 0;
        final isLast = index == _logisticsTraces.length - 1;

        // 根据物流状态设置不同颜色
        Color statusColor;
        switch (trace['status']) {
          case 'delivered':
            statusColor = Colors.green;
            break;
          case 'delivering':
            statusColor = Colors.blue;
            break;
          case 'pickup':
            statusColor = Colors.orange;
            break;
          default:
            statusColor = Colors.grey;
        }

        return Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // 时间线
            Column(
              children: [
                Container(
                  width: 60,
                  padding: const EdgeInsets.only(top: 2),
                  child: Text(
                    trace['time'].toString().split(' ')[0],
                    style: TextStyle(
                      fontSize: 12,
                      color: isFirst ? statusColor : Colors.grey,
                    ),
                    textAlign: TextAlign.center,
                  ),
                ),
                Container(
                  width: 60,
                  padding: const EdgeInsets.only(top: 2),
                  child: Text(
                    trace['time'].toString().split(' ')[1],
                    style: TextStyle(
                      fontSize: 12,
                      color: isFirst ? statusColor : Colors.grey,
                    ),
                    textAlign: TextAlign.center,
                  ),
                ),
              ],
            ),

            // 中间连接线和圆点
            Column(
              children: [
                // 上半部分连接线
                if (!isFirst)
                  Container(
                    width: 1,
                    height: 20,
                    color: Colors.grey[300],
                  ),

                // 状态节点
                Container(
                  margin: const EdgeInsets.symmetric(vertical: 4),
                  width: 12,
                  height: 12,
                  decoration: BoxDecoration(
                    color: isFirst ? statusColor : Colors.grey[400],
                    shape: BoxShape.circle,
                  ),
                ),

                // 下半部分连接线
                if (!isLast)
                  Expanded(
                    child: Container(
                      width: 1,
                      height: 40,
                      color: Colors.grey[300],
                    ),
                  ),
              ],
            ),

            const SizedBox(width: 12),

            // 物流详情
            Expanded(
              child: Container(
                margin: EdgeInsets.only(bottom: isLast ? 0 : 20),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      trace['content'] as String,
                      style: TextStyle(
                        color: isFirst ? statusColor : Colors.black87,
                        fontWeight:
                            isFirst ? FontWeight.bold : FontWeight.normal,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ],
        );
      },
    );
  }
}
