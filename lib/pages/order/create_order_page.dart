import 'dart:async';
import 'package:flutter/material.dart';
import 'dart:developer' as developer;
import 'dart:math' as math;
import '../../config/theme.dart';
import '../../network/api.dart';
import '../../network/http_util.dart';
import '../../utils/image_url_util.dart';
import '../../models/order.dart';
import '../../models/address.dart';
import 'pending_payment_page.dart';
import 'alipay_web_view_page.dart';
import 'package:dio/dio.dart';

class CreateOrderPage extends StatefulWidget {
  final int productId;
  final String productTitle;
  final double price;
  final String imageUrl;
  final int sellerId;

  const CreateOrderPage({
    Key? key,
    required this.productId,
    required this.productTitle,
    required this.price,
    required this.imageUrl,
    required this.sellerId,
  }) : super(key: key);

  @override
  State<CreateOrderPage> createState() => _CreateOrderPageState();
}

class _CreateOrderPageState extends State<CreateOrderPage> {
  bool _isLoading = true;
  bool _isSubmitting = false;
  String _errorMessage = '';
  
  // 地址相关
  List<Map<String, dynamic>> _addressList = [];
  Map<String, dynamic>? _selectedAddress;
  
  // 支付相关
  int _paymentType = 1; // 默认在线支付
  int _deliveryType = 2; // 默认快递配送
  double _deliveryFee = 5.0; // 默认运费
  String _remark = ''; // 订单备注
  
  // 倒计时相关
  int _remainingSeconds = 15 * 60; // 15分钟 = 900秒
  Timer? _timer;
  
  // 表单控制器
  final TextEditingController _remarkController = TextEditingController();

  @override
  void initState() {
    super.initState();
    _fetchAddresses();
    _startCountdown();
  }

  @override
  void dispose() {
    _timer?.cancel();
    _remarkController.dispose();
    super.dispose();
  }

  // 开始倒计时
  void _startCountdown() {
    _timer = Timer.periodic(const Duration(seconds: 1), (timer) {
      setState(() {
        if (_remainingSeconds > 0) {
          _remainingSeconds--;
        } else {
          _timer?.cancel();
          // 倒计时结束，提示用户
          if (mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(
                content: Text('订单已超时，请重新下单'),
                backgroundColor: Colors.red,
              ),
            );
            // 返回上一页
            Navigator.of(context).pop();
          }
        }
      });
    });
  }

  // 格式化倒计时时间
  String _formatCountdown() {
    int minutes = _remainingSeconds ~/ 60;
    int seconds = _remainingSeconds % 60;
    return '${minutes.toString().padLeft(2, '0')}:${seconds.toString().padLeft(2, '0')}';
  }

  // 获取用户的收货地址列表
  Future<void> _fetchAddresses() async {
    setState(() {
      _isLoading = true;
      _errorMessage = '';
    });

    try {
      final response = await HttpUtil().get(Api.userAddressList);

      if (response.isSuccess && response.data != null) {
        final List<dynamic> addressData = response.data;
        
        setState(() {
          _addressList = addressData.map((item) => item as Map<String, dynamic>).toList();
          
          // 如果有地址，默认选择第一个
          if (_addressList.isNotEmpty) {
            _selectedAddress = _addressList.first;
          }
          
          _isLoading = false;
        });
        
        developer.log('获取地址列表成功: ${_addressList.length}', name: 'CreateOrderPage');
      } else {
        setState(() {
          _isLoading = false;
          _errorMessage = response.message ?? '获取地址列表失败';
        });
        
        developer.log('获取地址列表失败: ${response.message}', name: 'CreateOrderPage');
      }
    } catch (e) {
      setState(() {
        _isLoading = false;
        _errorMessage = '网络错误，请稍后再试';
      });
      
      developer.log('获取地址列表异常: $e', name: 'CreateOrderPage');
    }
  }

  // 创建订单
  Future<void> _createOrder() async {
    // 验证用户是否选择了地址 - 仅对线下交易强制验证
    if (_paymentType == 2 && _selectedAddress == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('线下交易必须选择收货地址'),
          backgroundColor: Colors.red,
        ),
      );
      return;
    }

    setState(() {
      _isSubmitting = true;
      _errorMessage = '';
    });

    try {
      // 构建订单数据
      final Map<String, dynamic> orderData = {
        'productId': widget.productId,
        'paymentType': _paymentType,
        'deliveryType': _deliveryType,
        'remark': _remark,
        'price': widget.price,
        'deliveryFee': _deliveryFee,
        'sellerId': widget.sellerId,
      };
      
      // 仅当选择了地址时才添加地址ID
      if (_selectedAddress != null) {
        orderData['addressId'] = _selectedAddress!['id'];
      }

      developer.log('创建订单请求数据: $orderData', name: 'CreateOrderPage');

      // 调用创建订单API
      final response = await HttpUtil().post(Api.orderCreate, data: orderData);

      if (!mounted) return;

      setState(() {
        _isSubmitting = false;
      });

      if (response.isSuccess) {
        final Map<String, dynamic> orderResult = response.data as Map<String, dynamic>;
        final orderId = orderResult['orderId'];
        
        developer.log('创建订单成功，订单ID: $orderId', name: 'CreateOrderPage');
        
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('下单成功'),
              backgroundColor: Colors.green,
            ),
          );
          
          // 如果选择的是支付宝支付，则调用支付宝支付接口
          if (_paymentType == 1) { // 在线支付
            // 调用支付宝支付接口
            try {
              developer.log('请求支付宝支付，订单ID: $orderId', name: 'CreateOrderPage');
              // 修改接口调用，使用dio直接获取HTML内容，而不是通过ApiResponse
              final dio = Dio();
              dio.options.baseUrl = Api.baseUrl;
              dio.options.contentType = 'text/html';
              dio.options.responseType = ResponseType.plain;
              
              // 获取token并设置请求头
              final token = await HttpUtil().getToken();
              if (token != null && token.isNotEmpty) {
                dio.options.headers['Authorization'] = 'Bearer $token';
              }
              
              // 直接请求HTML内容
              final payResponse = await dio.get('${Api.alipayPay}?orderId=$orderId');
              
              if (payResponse.statusCode == 200) {
                final String payHtml = payResponse.data as String;
                
                // 记录支付表单HTML内容，便于调试
                developer.log('支付表单HTML: ${payHtml.substring(0, math.min(100, payHtml.length))}...', name: 'CreateOrderPage');
                
                // 跳转到支付WebView页面
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) => AlipayWebViewPage(payHtml: payHtml),
                  ),
                );
                return;
              } else {
                // 支付请求失败，跳转到待付款页面
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: Text('支付请求失败：状态码 ${payResponse.statusCode}'),
                    backgroundColor: Colors.red,
                  ),
                );
                
                Navigator.pushReplacement(
                  context,
                  MaterialPageRoute(builder: (context) => const PendingPaymentPage()),
                );
              }
            } catch (e) {
              developer.log('支付宝支付请求异常: $e', name: 'CreateOrderPage');
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(
                  content: Text('支付请求异常: $e'),
                  backgroundColor: Colors.red,
                ),
              );
              
              // 出现异常时，跳转到待付款订单列表页面
              Navigator.pushReplacement(
                context,
                MaterialPageRoute(builder: (context) => const PendingPaymentPage()),
              );
            }
          } else {
            // 如果不是在线支付，跳转到待付款订单列表页面
            Navigator.pushReplacement(
              context,
              MaterialPageRoute(builder: (context) => const PendingPaymentPage()),
            );
          }
        }
      } else {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(response.message ?? '创建订单失败'),
              backgroundColor: Colors.red,
            ),
          );
        }
        
        developer.log('创建订单失败: ${response.message}', name: 'CreateOrderPage');
      }
    } catch (e) {
      setState(() {
        _isSubmitting = false;
      });
      
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('创建订单异常: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
      
      developer.log('创建订单异常: $e', name: 'CreateOrderPage');
    }
  }

  @override
  Widget build(BuildContext context) {
    // 处理图片URL
    String imageUrl = ImageUrlUtil.processImageUrl(widget.imageUrl);
    
    if (_isLoading) {
      return Scaffold(
        appBar: AppBar(
          title: const Text('填写订单'),
          elevation: 0,
        ),
        body: const Center(
          child: CircularProgressIndicator(),
        ),
      );
    }

    return Scaffold(
      appBar: AppBar(
        title: const Text('填写订单'),
        elevation: 0,
        actions: [
          // 倒计时显示
          Center(
            child: Padding(
              padding: const EdgeInsets.only(right: 16.0),
              child: Text(
                _formatCountdown(),
                style: const TextStyle(
                  color: Colors.red,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
          ),
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // 错误信息
            if (_errorMessage.isNotEmpty)
              Container(
                padding: const EdgeInsets.all(8.0),
                margin: const EdgeInsets.only(bottom: 16.0),
                decoration: BoxDecoration(
                  color: Colors.red.shade50,
                  borderRadius: BorderRadius.circular(4.0),
                ),
                child: Row(
                  children: [
                    const Icon(Icons.error, color: Colors.red),
                    const SizedBox(width: 8.0),
                    Expanded(
                      child: Text(
                        _errorMessage,
                        style: const TextStyle(color: Colors.red),
                      ),
                    ),
                  ],
                ),
              ),

            // 商品信息卡片
            Card(
              margin: const EdgeInsets.only(bottom: 16.0),
              child: Padding(
                padding: const EdgeInsets.all(12.0),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // 商品图片
                    ClipRRect(
                      borderRadius: BorderRadius.circular(4.0),
                      child: imageUrl.isNotEmpty
                          ? Image.network(
                              imageUrl,
                              width: 80,
                              height: 80,
                              fit: BoxFit.cover,
                              errorBuilder: (context, error, stackTrace) {
                                return Container(
                                  width: 80,
                                  height: 80,
                                  color: Colors.grey[300],
                                  child: const Icon(
                                    Icons.image_not_supported,
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
                                color: Colors.white,
                              ),
                            ),
                    ),
                    
                    const SizedBox(width: 12.0),
                    
                    // 商品信息
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            widget.productTitle,
                            style: const TextStyle(
                              fontWeight: FontWeight.bold,
                              fontSize: 16.0,
                            ),
                            maxLines: 2,
                            overflow: TextOverflow.ellipsis,
                          ),
                          const SizedBox(height: 8.0),
                          Text(
                            '¥${widget.price.toStringAsFixed(2)}',
                            style: TextStyle(
                              color: AppTheme.primaryColor,
                              fontWeight: FontWeight.bold,
                              fontSize: 18.0,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ),
            
            // 收货地址选择卡片
            Card(
              margin: const EdgeInsets.only(bottom: 16),
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        const Text(
                          '收货地址',
                          style: TextStyle(
                            fontWeight: FontWeight.bold,
                            fontSize: 16,
                          ),
                        ),
                        TextButton.icon(
                          icon: const Icon(Icons.add, size: 16),
                          label: const Text('新增地址'),
                          onPressed: () {
                            // 跳转到地址管理页面
                            Navigator.pushNamed(context, '/address-management')
                                .then((_) => _fetchAddresses());
                          },
                        ),
                      ],
                    ),
                    const SizedBox(height: 8),
                    if (_addressList.isEmpty)
                      const Text(
                        '您还没有添加收货地址',
                        style: TextStyle(color: Colors.grey),
                      )
                    else
                      Column(
                        children: _addressList.map((address) {
                          final bool isSelected = _selectedAddress == address;
                          
                          return InkWell(
                            onTap: () {
                              setState(() {
                                _selectedAddress = address;
                              });
                            },
                            child: Container(
                              padding: const EdgeInsets.symmetric(vertical: 12),
                              decoration: BoxDecoration(
                                border: Border(
                                  bottom: BorderSide(
                                    color: Colors.grey[200]!,
                                    width: 1,
                                  ),
                                ),
                              ),
                              child: Row(
                                children: [
                                  Icon(
                                    isSelected
                                        ? Icons.check_circle
                                        : Icons.circle_outlined,
                                    color: isSelected
                                        ? AppTheme.primaryColor
                                        : Colors.grey,
                                    size: 20,
                                  ),
                                  const SizedBox(width: 12),
                                  Expanded(
                                    child: Column(
                                      crossAxisAlignment: CrossAxisAlignment.start,
                                      children: [
                                        Row(
                                          children: [
                                            Text(
                                              address['consignee'] ?? '',
                                              style: const TextStyle(
                                                fontWeight: FontWeight.bold,
                                              ),
                                            ),
                                            const SizedBox(width: 8),
                                            Text(
                                              address['contactPhone'] ?? '',
                                              style: const TextStyle(
                                                color: Colors.grey,
                                              ),
                                            ),
                                          ],
                                        ),
                                        const SizedBox(height: 4),
                                        Text(
                                          '${address['region'] ?? ''} ${address['detail'] ?? ''}',
                                          style: const TextStyle(
                                            color: Colors.grey,
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          );
                        }).toList(),
                      ),
                  ],
                ),
              ),
            ),
            
            // 支付方式卡片
            Card(
              margin: const EdgeInsets.only(bottom: 16),
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      '支付方式',
                      style: TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 16,
                      ),
                    ),
                    const SizedBox(height: 12),
                    _buildPaymentOption(
                      icon: Icons.payment,
                      title: '在线支付',
                      value: 1,
                      groupValue: _paymentType,
                    ),
                    _buildPaymentOption(
                      icon: Icons.attach_money,
                      title: '货到付款',
                      value: 2,
                      groupValue: _paymentType,
                    ),
                  ],
                ),
              ),
            ),
            
            // 配送方式卡片
            Card(
              margin: const EdgeInsets.only(bottom: 16),
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      '配送方式',
                      style: TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 16,
                      ),
                    ),
                    const SizedBox(height: 12),
                    _buildDeliveryOption(
                      icon: Icons.store,
                      title: '上门自提',
                      subtitle: '不收取运费',
                      value: 1,
                      groupValue: _deliveryType,
                    ),
                    _buildDeliveryOption(
                      icon: Icons.local_shipping,
                      title: '快递配送',
                      subtitle: '¥${_deliveryFee.toStringAsFixed(2)}',
                      value: 2,
                      groupValue: _deliveryType,
                    ),
                  ],
                ),
              ),
            ),
            
            // 订单备注卡片
            Card(
              margin: const EdgeInsets.only(bottom: 16),
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      '订单备注',
                      style: TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 16,
                      ),
                    ),
                    const SizedBox(height: 12),
                    TextField(
                      controller: _remarkController,
                      decoration: const InputDecoration(
                        hintText: '请输入订单备注(选填)',
                        border: OutlineInputBorder(),
                        contentPadding: EdgeInsets.all(12),
                      ),
                      maxLines: 2,
                      onChanged: (value) {
                        setState(() {
                          _remark = value;
                        });
                      },
                    ),
                  ],
                ),
              ),
            ),
            
            // 订单金额汇总
            Card(
              margin: const EdgeInsets.only(bottom: 16),
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      '订单金额',
                      style: TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 16,
                      ),
                    ),
                    const SizedBox(height: 12),
                    _buildOrderAmountRow('商品金额', '¥${widget.price.toStringAsFixed(2)}'),
                    _buildOrderAmountRow('运费', '¥${_deliveryFee.toStringAsFixed(2)}'),
                    const Divider(height: 24),
                    _buildOrderAmountRow(
                      '应付金额',
                      '¥${(widget.price + _deliveryFee).toStringAsFixed(2)}',
                      isTotal: true,
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
      bottomNavigationBar: _buildBottomBar(),
    );
  }

  // 支付方式选项
  Widget _buildPaymentOption({
    required IconData icon,
    required String title,
    required int value,
    required int groupValue,
  }) {
    return InkWell(
      onTap: () {
        setState(() {
          _paymentType = value;
        });
      },
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 8.0),
        child: Row(
          children: [
            Icon(icon, color: Colors.grey),
            const SizedBox(width: 12),
            Text(title),
            const Spacer(),
            Radio<int>(
              value: value,
              groupValue: groupValue,
              onChanged: (v) {
                if (v != null) {
                  setState(() {
                    _paymentType = v;
                  });
                }
              },
              activeColor: AppTheme.primaryColor,
            ),
          ],
        ),
      ),
    );
  }

  // 配送方式选项
  Widget _buildDeliveryOption({
    required IconData icon,
    required String title,
    required String subtitle,
    required int value,
    required int groupValue,
  }) {
    return InkWell(
      onTap: () {
        setState(() {
          _deliveryType = value;
          // 如果选择自提，则运费为0
          _deliveryFee = value == 1 ? 0.0 : 5.0;
        });
      },
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 8.0),
        child: Row(
          children: [
            Icon(icon, color: Colors.grey),
            const SizedBox(width: 12),
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(title),
                Text(
                  subtitle,
                  style: const TextStyle(color: Colors.grey, fontSize: 12),
                ),
              ],
            ),
            const Spacer(),
            Radio<int>(
              value: value,
              groupValue: groupValue,
              onChanged: (v) {
                if (v != null) {
                  setState(() {
                    _deliveryType = v;
                    // 如果选择自提，则运费为0
                    _deliveryFee = v == 1 ? 0.0 : 5.0;
                  });
                }
              },
              activeColor: AppTheme.primaryColor,
            ),
          ],
        ),
      ),
    );
  }

  // 订单金额行
  Widget _buildOrderAmountRow(String label, String amount, {bool isTotal = false}) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4.0),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(label),
          Text(
            amount,
            style: TextStyle(
              color: isTotal ? AppTheme.primaryColor : Colors.black,
              fontWeight: isTotal ? FontWeight.bold : FontWeight.normal,
              fontSize: isTotal ? 18 : 14,
            ),
          ),
        ],
      ),
    );
  }

  // 底部支付栏
  Widget _buildBottomBar() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
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
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text('应付金额:'),
              Text(
                '¥${(widget.price + _deliveryFee).toStringAsFixed(2)}',
                style: TextStyle(
                  color: AppTheme.primaryColor,
                  fontWeight: FontWeight.bold,
                  fontSize: 18,
                ),
              ),
            ],
          ),
          ElevatedButton(
            onPressed: _isSubmitting ? null : _createOrder,
            style: ElevatedButton.styleFrom(
              backgroundColor: AppTheme.primaryColor,
              padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
            ),
            child: _isSubmitting
                ? const SizedBox(
                    width: 20,
                    height: 20,
                    child: CircularProgressIndicator(
                      strokeWidth: 2,
                      valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                    ),
                  )
                : const Text(
                    '立即支付',
                    style: TextStyle(fontSize: 16),
                  ),
          ),
        ],
      ),
    );
  }
} 