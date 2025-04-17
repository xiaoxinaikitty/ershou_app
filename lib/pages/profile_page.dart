import 'package:flutter/material.dart';
import 'dart:developer' as developer;
import '../config/theme.dart';
import '../network/api.dart';
import '../network/http_util.dart';
import 'settings_page.dart';
import 'favorite_page.dart'; // 导入收藏页面
import 'order/pending_payment_page.dart'; // 导入待付款页面
import 'order/waiting_shipment_page.dart'; // 导入待发货页面
import 'order/order_receiving_page.dart'; // 导入待收货页面
import 'auth/login_page.dart'; // 导入登录页面

class ProfilePage extends StatefulWidget {
  const ProfilePage({Key? key}) : super(key: key);

  @override
  State<ProfilePage> createState() => _ProfilePageState();
}

class _ProfilePageState extends State<ProfilePage> {
  Map<String, dynamic>? _userInfo;
  bool _isLoading = true;
  bool _isError = false;
  String _errorMessage = '';
  int _retryCount = 0;
  final int _maxRetries = 2;

  @override
  void initState() {
    super.initState();
    _fetchUserInfo();
  }

  Future<void> _fetchUserInfo() async {
    setState(() {
      _isLoading = true;
      _isError = false;
      _errorMessage = '';
    });

    try {
      // 首先检查是否有token
      final token = await HttpUtil().getToken();
      if (token == null || token.isEmpty) {
        developer.log('获取用户信息失败: Token为空', name: 'ProfilePage');
        setState(() {
          _isLoading = false;
          _isError = true;
          _errorMessage = '您尚未登录，请先登录';
        });
        // 只有在确认没有token时才跳转到登录页
        _navigateToLogin(clearToken: false); // 避免重复清除token
        return;
      }

      developer.log('开始获取用户信息, Token存在', name: 'ProfilePage');
      final response = await HttpUtil().get(Api.userInfo);
      developer.log('用户信息响应: ${response.code}, ${response.message}',
          name: 'ProfilePage');

      if (response.isSuccess && response.data != null) {
        setState(() {
          _userInfo = response.data as Map<String, dynamic>;
          _isLoading = false;
          _retryCount = 0; // 重置重试计数
        });
        developer.log('用户信息获取成功: ${_userInfo?.toString()}',
            name: 'ProfilePage');
      } else {
        // 获取失败但有响应
        developer.log('获取用户信息失败: ${response.message}', name: 'ProfilePage');

        // 仅当服务器明确返回401未授权错误时才认为是token无效
        if (response.code == 401) {
          setState(() {
            _isLoading = false;
            _isError = true;
            _errorMessage = '登录已过期，请重新登录';
          });
          // 仅在401错误时清除token并跳转登录页
          _navigateToLogin(clearToken: true);
        } else if (_retryCount < _maxRetries) {
          // 其他错误尝试重试
          _retryCount++;
          developer.log('尝试重试获取用户信息，第$_retryCount次', name: 'ProfilePage');
          await Future.delayed(const Duration(seconds: 1));
          _fetchUserInfo();
        } else {
          // 重试次数用完，显示错误但不退出登录
          setState(() {
            _isLoading = false;
            _isError = true;
            _errorMessage = response.message ?? '获取用户信息失败，请重试';
          });
        }
      }
    } catch (e) {
      developer.log('获取用户信息异常: $e', name: 'ProfilePage', error: e);

      if (_retryCount < _maxRetries) {
        // 异常情况下也尝试重试
        _retryCount++;
        developer.log('尝试重试获取用户信息，第$_retryCount次', name: 'ProfilePage');
        await Future.delayed(const Duration(seconds: 1));
        _fetchUserInfo();
      } else {
        // 网络异常不应导致登出，只显示错误提示
        setState(() {
          _isLoading = false;
          _isError = true;
          _errorMessage = '网络错误，请稍后再试';
        });
      }
    }
  }

  // 跳转到登录页
  void _navigateToLogin({bool clearToken = true}) {
    // 使用延迟确保状态更新后再跳转
    Future.delayed(Duration.zero, () {
      if (mounted) {
        if (clearToken) {
          HttpUtil().clearToken(); // 只在指定时清除token
        }
        Navigator.of(context).pushReplacement(
          MaterialPageRoute(builder: (context) => const LoginPage()),
        );
      }
    });
  }

  void _logout() async {
    try {
      await HttpUtil().clearToken();
      if (!mounted) return;
      Navigator.of(context).pushReplacementNamed('/login');
    } catch (e) {
      developer.log('退出登录异常: $e', name: 'ProfilePage');
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('退出登录失败')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return const Scaffold(
        body: Center(child: CircularProgressIndicator()),
      );
    }

    if (_isError) {
      return Scaffold(
        appBar: AppBar(
          title:
              const Text('个人中心', style: TextStyle(fontWeight: FontWeight.bold)),
          elevation: 0,
        ),
        body: Center(
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
                textAlign: TextAlign.center,
                style: const TextStyle(color: Colors.grey),
              ),
              const SizedBox(height: 24),
              ElevatedButton(
                onPressed: _fetchUserInfo,
                child: const Text('重新加载'),
              ),
              const SizedBox(height: 12),
              TextButton(
                onPressed: () {
                  Navigator.of(context).pushReplacement(
                    MaterialPageRoute(builder: (context) => const LoginPage()),
                  );
                },
                child: const Text('去登录'),
              ),
            ],
          ),
        ),
      );
    }

    return Scaffold(
      appBar: AppBar(
        title:
            const Text('个人中心', style: TextStyle(fontWeight: FontWeight.bold)),
        elevation: 0,
        actions: [
          IconButton(
            icon: const Icon(Icons.settings_outlined),
            onPressed: () {
              // 跳转到设置页面
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) => const SettingsPage(),
                ),
              );
            },
          ),
        ],
      ),
      body: SingleChildScrollView(
        child: Column(
          children: [
            // 用户信息卡片
            _buildUserInfoCard(),

            const SizedBox(height: 16),

            // 功能菜单区
            _buildFunctionMenus(),

            const SizedBox(height: 16),

            // 我的订单区
            _buildMyOrders(),

            const SizedBox(height: 16),

            // 更多功能区
            _buildMoreFeatures(),

            const SizedBox(height: 32),

            // 退出登录按钮
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: _logout,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.white,
                    foregroundColor: Colors.red,
                    side: const BorderSide(color: Colors.red),
                    padding: const EdgeInsets.symmetric(vertical: 12),
                  ),
                  child: const Text('退出登录'),
                ),
              ),
            ),
            const SizedBox(height: 32),
          ],
        ),
      ),
    );
  }

  Widget _buildUserInfoCard() {
    final username = _userInfo?['username'] ?? '用户';
    final phone = _userInfo?['phone'] ?? '未设置手机号';

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      margin: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 10,
            offset: const Offset(0, 5),
          ),
        ],
      ),
      child: Column(
        children: [
          Row(
            children: [
              // 头像
              CircleAvatar(
                radius: 36,
                backgroundColor: AppTheme.secondaryColor,
                child: Icon(
                  Icons.person,
                  size: 36,
                  color: AppTheme.primaryColor,
                ),
              ),
              const SizedBox(width: 16),
              // 用户信息
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      username,
                      style: const TextStyle(
                        fontSize: 20,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      phone,
                      style: TextStyle(
                        fontSize: 14,
                        color: Colors.grey[600],
                      ),
                    ),
                  ],
                ),
              ),
              // 编辑按钮
              IconButton(
                icon: const Icon(Icons.edit),
                onPressed: () {
                  // 编辑个人资料
                },
              ),
            ],
          ),
          const SizedBox(height: 16),
          // 统计数据
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceAround,
            children: [
              _buildStatItem('发布', '12'),
              _buildStatItem('收藏', '36'),
              _buildStatItem('关注', '48'),
              _buildStatItem('粉丝', '25'),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildStatItem(String title, String count) {
    return Column(
      children: [
        Text(
          count,
          style: const TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.bold,
          ),
        ),
        const SizedBox(height: 4),
        Text(
          title,
          style: TextStyle(
            fontSize: 14,
            color: Colors.grey[600],
          ),
        ),
      ],
    );
  }

  Widget _buildFunctionMenus() {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            '我的功能',
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 16),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceAround,
            children: [
              _buildFunctionItem(Icons.list_alt, '我的发布'),
              _buildFunctionItem(Icons.favorite, '我的收藏'),
              _buildFunctionItem(Icons.history, '浏览记录'),
              _buildFunctionItem(Icons.wallet, '我的钱包'),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildFunctionItem(IconData icon, String title) {
    return GestureDetector(
      onTap: () {
        if (title == '我的收藏') {
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (context) => const FavoritePage(),
            ),
          );
        } else {
          // 处理其他点击事件
        }
      },
      child: Column(
        children: [
          Container(
            width: 50,
            height: 50,
            decoration: BoxDecoration(
              color: AppTheme.secondaryColor.withOpacity(0.2),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Icon(
              icon,
              color: AppTheme.primaryColor,
            ),
          ),
          const SizedBox(height: 8),
          Text(title),
        ],
      ),
    );
  }

  Widget _buildMyOrders() {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text(
                '我的订单',
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                ),
              ),
              GestureDetector(
                onTap: () {
                  // 查看全部订单
                },
                child: Row(
                  children: [
                    Text(
                      '查看全部',
                      style: TextStyle(
                        fontSize: 14,
                        color: Colors.grey[600],
                      ),
                    ),
                    Icon(
                      Icons.chevron_right,
                      size: 18,
                      color: Colors.grey[600],
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceAround,
            children: [
              _buildOrderItem(Icons.payment, '待付款'),
              _buildOrderItem(Icons.local_shipping, '待发货'),
              _buildOrderItem(Icons.inventory_2, '待收货'),
              _buildOrderItem(Icons.rate_review, '待评价'),
              _buildOrderItem(Icons.support_agent, '售后'),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildOrderItem(IconData icon, String title) {
    return GestureDetector(
      onTap: () {
        // 处理点击事件
        if (title == '待付款') {
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (context) => const PendingPaymentPage(),
            ),
          );
        } else if (title == '待发货') {
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (context) => const WaitingShipmentPage(),
            ),
          );
        } else if (title == '待收货') {
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (context) => const OrderReceivingPage(),
            ),
          );
        }
      },
      child: Column(
        children: [
          Icon(
            icon,
            size: 24,
            color: AppTheme.primaryColor,
          ),
          const SizedBox(height: 8),
          Text(
            title,
            style: const TextStyle(fontSize: 12),
          ),
        ],
      ),
    );
  }

  Widget _buildMoreFeatures() {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Column(
        children: [
          _buildFeatureItem(Icons.location_on, '我的地址'),
          const Divider(height: 1),
          _buildFeatureItem(Icons.support, '联系客服'),
          const Divider(height: 1),
          _buildFeatureItem(Icons.help_outline, '帮助中心'),
          const Divider(height: 1),
          _buildFeatureItem(Icons.info_outline, '关于闲转'),
        ],
      ),
    );
  }

  Widget _buildFeatureItem(IconData icon, String title) {
    return ListTile(
      leading: Icon(icon, color: Colors.grey[600]),
      title: Text(title),
      trailing: Icon(Icons.chevron_right, color: Colors.grey[400]),
      onTap: () {
        // 处理点击事件
      },
    );
  }
}
