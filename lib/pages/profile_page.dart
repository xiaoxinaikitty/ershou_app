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
import 'my_posts_page.dart'; // 导入我的发布页面
import 'wallet_page.dart'; // 导入钱包页面
import 'cart_page.dart'; // 导入购物车页面
import 'package:image_picker/image_picker.dart';
import 'dart:io';
import './address_management_page.dart' as address; // 使用别名导入地址管理页面
import './shipping_address_page.dart'; // 导入发货地址管理页面

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
  final ImagePicker _picker = ImagePicker();
  bool _isUploadingAvatar = false;

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
        final userInfo = response.data as Map<String, dynamic>;

        // 获取用户发布的商品数量（使用新接口）
        final Map<String, dynamic> params = {
          'pageNum': 1,
          'pageSize': 1, // 只需要获取总数，不需要具体数据
        };

        // 使用新的专用接口获取用户发布的商品
        final productsResponse =
            await HttpUtil().get(Api.myProductList, params: params);
        int postCount = 0;
        if (productsResponse.isSuccess && productsResponse.data != null) {
          final data = productsResponse.data as Map<String, dynamic>;
          // 从响应中获取总数量
          postCount = data['total'] as int? ?? 0;
        }

        // 获取收藏数量
        final favoritesResponse = await HttpUtil().get(Api.favoriteList);
        int favoriteCount = 0;
        if (favoritesResponse.isSuccess && favoritesResponse.data != null) {
          final List<dynamic> favoriteList = favoritesResponse.data;
          favoriteCount = favoriteList.length;
        }

        setState(() {
          _userInfo = userInfo;
          _userInfo?['postCount'] = postCount; // 添加发布数量到用户信息中
          _userInfo?['favoriteCount'] = favoriteCount; // 添加收藏数量到用户信息中
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

  // 上传头像
  Future<void> _uploadAvatar() async {
    try {
      final XFile? image = await _picker.pickImage(
        source: ImageSource.gallery,
        maxWidth: 800,
        maxHeight: 800,
        imageQuality: 85,
      );

      if (image != null) {
        setState(() {
          _isUploadingAvatar = true;
        });

        final File imageFile = File(image.path);
        final uploadResponse = await HttpUtil().uploadFile(
          imageFile,
          onSendProgress: (sent, total) {
            developer.log('头像上传进度: $sent/$total', name: 'ProfilePage');
          },
        );

        if (uploadResponse.isSuccess && uploadResponse.data != null) {
          final String imageUrl = uploadResponse.data!['fileUrl'];

          // 更新用户头像
          final updateResponse = await HttpUtil().put(
            Api.userInfo,
            data: {
              'avatar': imageUrl,
            },
          );

          if (updateResponse.isSuccess) {
            setState(() {
              _userInfo?['avatar'] = imageUrl;
            });
            if (mounted) {
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text('头像更新成功')),
              );
            }
          } else {
            if (mounted) {
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(content: Text(updateResponse.message ?? '头像更新失败')),
              );
            }
          }
        } else {
          if (mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(content: Text(uploadResponse.message ?? '头像上传失败')),
            );
          }
        }
      }
    } catch (e) {
      developer.log('上传头像异常: $e', name: 'ProfilePage');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('上传头像失败，请重试')),
        );
      }
    } finally {
      if (mounted) {
        setState(() {
          _isUploadingAvatar = false;
        });
      }
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
            icon: const Icon(Icons.shopping_cart_outlined),
            onPressed: () {
              // 跳转到购物车页面
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) => const CartPage(),
                ),
              );
            },
          ),
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
    final postCount = _userInfo?['postCount']?.toString() ?? '0';
    final favoriteCount = _userInfo?['favoriteCount']?.toString() ?? '0';
    final avatarUrl = _userInfo?['avatar'];

    // 处理头像URL
    String? processedAvatarUrl;
    if (avatarUrl != null) {
      if (avatarUrl.startsWith('http')) {
        // 如果URL包含localhost，替换为服务器地址
        if (avatarUrl.contains('localhost')) {
          processedAvatarUrl =
              avatarUrl.replaceAll('localhost:8080', '192.168.200.30:8080');
        } else {
          processedAvatarUrl = avatarUrl;
        }
      } else if (avatarUrl.startsWith('/')) {
        // 如果是相对路径，添加服务器地址
        processedAvatarUrl = '${Api.baseUrl}$avatarUrl';
      } else {
        // 如果是文件名，添加服务器地址和图片目录
        processedAvatarUrl = '${Api.baseUrl}/images/$avatarUrl';
      }
    }

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
              GestureDetector(
                onTap: _isUploadingAvatar ? null : _uploadAvatar,
                child: Stack(
                  children: [
                    CircleAvatar(
                      radius: 36,
                      backgroundColor: AppTheme.secondaryColor,
                      backgroundImage: processedAvatarUrl != null
                          ? NetworkImage(processedAvatarUrl)
                          : null,
                      child: processedAvatarUrl == null
                          ? Icon(
                              Icons.person,
                              size: 36,
                              color: AppTheme.primaryColor,
                            )
                          : null,
                    ),
                    if (_isUploadingAvatar)
                      Positioned.fill(
                        child: Container(
                          decoration: BoxDecoration(
                            color: Colors.black.withOpacity(0.5),
                            shape: BoxShape.circle,
                          ),
                          child: const Center(
                            child: CircularProgressIndicator(
                              color: Colors.white,
                            ),
                          ),
                        ),
                      ),
                  ],
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
          const SizedBox(height: 16),
          // 统计数据
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceAround,
            children: [
              _buildStatItem('发布', postCount),
              _buildStatItem('收藏', favoriteCount),
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
              _buildFunctionItem(Icons.shopping_cart, '购物车'),
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
        } else if (title == '我的发布') {
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (context) => const MyPostsPage(),
            ),
          );
        } else if (title == '我的钱包') {
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (context) => const WalletPage(),
            ),
          );
        } else if (title == '购物车') {
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (context) => const CartPage(),
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
          _buildFeatureItem(Icons.location_on, '我的收货地址'),
          const Divider(height: 1),
          _buildFeatureItem(Icons.local_shipping, '我的发货地址'),
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
        if (title == '我的收货地址') {
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (context) => const address.AddressManagementPage(),
            ),
          );
        } else if (title == '我的发货地址') {
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (context) => const ShippingAddressPage(),
            ),
          );
        }
      },
    );
  }
}
