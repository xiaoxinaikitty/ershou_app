import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'dart:developer' as developer;
import '../services/wallet_service.dart';
import '../config/theme.dart';
import '../network/http_util.dart';

class PaymentPasswordPage extends StatefulWidget {
  const PaymentPasswordPage({Key? key}) : super(key: key);

  @override
  State<PaymentPasswordPage> createState() => _PaymentPasswordPageState();
}

class _PaymentPasswordPageState extends State<PaymentPasswordPage>
    with SingleTickerProviderStateMixin {
  final WalletService _walletService = WalletService();
  late TabController _tabController;

  // 当前用户ID
  int? _userId;
  bool _isLoading = false;

  // 设置密码相关
  final TextEditingController _passwordController = TextEditingController();
  final TextEditingController _confirmPasswordController =
      TextEditingController();
  final TextEditingController _oldPasswordController = TextEditingController();
  bool _hasPassword = false; // 是否已设置过支付密码

  // 重置密码相关
  final TextEditingController _verificationCodeController =
      TextEditingController();
  final TextEditingController _newPasswordController = TextEditingController();
  final TextEditingController _confirmNewPasswordController =
      TextEditingController();
  bool _isSendingCode = false;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
    _loadUserInfo();
  }

  @override
  void dispose() {
    _tabController.dispose();
    _passwordController.dispose();
    _confirmPasswordController.dispose();
    _oldPasswordController.dispose();
    _verificationCodeController.dispose();
    _newPasswordController.dispose();
    _confirmNewPasswordController.dispose();
    super.dispose();
  }

  // 加载用户信息
  Future<void> _loadUserInfo() async {
    try {
      final userInfo = await _getUserInfo();
      if (userInfo != null && userInfo['userId'] != null) {
        setState(() {
          _userId = userInfo['userId'];
        });

        // 验证是否已设置支付密码
        await _checkHasPaymentPassword();
      }
    } catch (e) {
      developer.log('加载用户信息异常: $e', name: 'PaymentPasswordPage');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('获取用户信息失败，请稍后再试')),
        );
      }
    }
  }

  // 获取用户信息
  Future<Map<String, dynamic>?> _getUserInfo() async {
    try {
      final response = await HttpUtil().get('/user/info');
      if (response.isSuccess && response.data != null) {
        return response.data as Map<String, dynamic>;
      }
      return null;
    } catch (e) {
      developer.log('获取用户信息异常: $e', name: 'PaymentPasswordPage');
      return null;
    }
  }

  // 检查是否已设置支付密码
  Future<void> _checkHasPaymentPassword() async {
    if (_userId == null) return;

    try {
      // 尝试验证空密码，如果返回用户未设置支付密码的错误，说明尚未设置密码
      final response = await _walletService.verifyPaymentPassword(
        userId: _userId!,
        paymentPassword: '',
      );

      setState(() {
        // 错误码40400表示用户未设置支付密码
        _hasPassword = response.code != 40400;
      });
    } catch (e) {
      developer.log('检查支付密码状态异常: $e', name: 'PaymentPasswordPage');
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('支付密码设置'),
        backgroundColor: AppTheme.primaryColor,
        bottom: TabBar(
          controller: _tabController,
          indicatorColor: Colors.white,
          tabs: const [
            Tab(text: '设置/修改密码'),
            Tab(text: '重置密码'),
          ],
        ),
      ),
      body: TabBarView(
        controller: _tabController,
        children: [
          _buildSetPasswordTab(),
          _buildResetPasswordTab(),
        ],
      ),
    );
  }

  // 设置密码选项卡
  Widget _buildSetPasswordTab() {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Card(
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    _hasPassword ? '修改支付密码' : '设置支付密码',
                    style: const TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    _hasPassword
                        ? '修改支付密码需要先验证原密码，新密码长度为6-20位'
                        : '首次设置支付密码，密码长度为6-20位',
                    style: TextStyle(
                      fontSize: 14,
                      color: Colors.grey[600],
                    ),
                  ),
                  const SizedBox(height: 24),

                  // 原密码输入框（仅在修改密码时显示）
                  if (_hasPassword) ...[
                    TextField(
                      controller: _oldPasswordController,
                      decoration: const InputDecoration(
                        labelText: '原支付密码',
                        border: OutlineInputBorder(),
                        prefixIcon: Icon(Icons.lock_outline),
                      ),
                      obscureText: true,
                      keyboardType: TextInputType.number,
                      inputFormatters: [
                        FilteringTextInputFormatter.digitsOnly,
                        LengthLimitingTextInputFormatter(20),
                      ],
                    ),
                    const SizedBox(height: 16),
                  ],

                  // 新密码输入框
                  TextField(
                    controller: _passwordController,
                    decoration: const InputDecoration(
                      labelText: '新支付密码',
                      helperText: '请输入6-20位数字密码',
                      border: OutlineInputBorder(),
                      prefixIcon: Icon(Icons.lock_outline),
                    ),
                    obscureText: true,
                    keyboardType: TextInputType.number,
                    inputFormatters: [
                      FilteringTextInputFormatter.digitsOnly,
                      LengthLimitingTextInputFormatter(20),
                    ],
                  ),
                  const SizedBox(height: 16),

                  // 确认新密码输入框
                  TextField(
                    controller: _confirmPasswordController,
                    decoration: const InputDecoration(
                      labelText: '确认新支付密码',
                      border: OutlineInputBorder(),
                      prefixIcon: Icon(Icons.lock_outline),
                    ),
                    obscureText: true,
                    keyboardType: TextInputType.number,
                    inputFormatters: [
                      FilteringTextInputFormatter.digitsOnly,
                      LengthLimitingTextInputFormatter(20),
                    ],
                  ),
                  const SizedBox(height: 24),

                  // 提交按钮
                  _isLoading
                      ? const Center(child: CircularProgressIndicator())
                      : SizedBox(
                          width: double.infinity,
                          child: ElevatedButton(
                            onPressed: _handleSetPassword,
                            style: ElevatedButton.styleFrom(
                              backgroundColor: AppTheme.primaryColor,
                              padding: const EdgeInsets.symmetric(vertical: 12),
                            ),
                            child: Text(
                              _hasPassword ? '修改密码' : '设置密码',
                              style: const TextStyle(fontSize: 16),
                            ),
                          ),
                        ),
                ],
              ),
            ),
          ),

          const SizedBox(height: 24),

          // 支付密码安全提示
          Card(
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    '安全提示',
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 16),
                  _buildSecurityTip('支付密码用于钱包相关操作，如提现、支付等。'),
                  _buildSecurityTip('请勿设置与登录密码相同的支付密码。'),
                  _buildSecurityTip('请定期修改支付密码以保证账户安全。'),
                  _buildSecurityTip('如忘记支付密码，可通过绑定的手机或邮箱重置。'),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  // 重置密码选项卡
  Widget _buildResetPasswordTab() {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Card(
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    '重置支付密码',
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    '通过验证码重置支付密码，验证码将发送到您绑定的手机或邮箱',
                    style: TextStyle(
                      fontSize: 14,
                      color: Colors.grey[600],
                    ),
                  ),
                  const SizedBox(height: 24),

                  // 验证码输入框
                  Row(
                    children: [
                      Expanded(
                        child: TextField(
                          controller: _verificationCodeController,
                          decoration: const InputDecoration(
                            labelText: '验证码',
                            border: OutlineInputBorder(),
                            prefixIcon: Icon(Icons.security),
                          ),
                          keyboardType: TextInputType.number,
                          inputFormatters: [
                            FilteringTextInputFormatter.digitsOnly,
                            LengthLimitingTextInputFormatter(6),
                          ],
                        ),
                      ),
                      const SizedBox(width: 16),
                      SizedBox(
                        width: 120,
                        child: ElevatedButton(
                          onPressed: _isSendingCode ? null : _handleSendCode,
                          style: ElevatedButton.styleFrom(
                            padding: const EdgeInsets.symmetric(vertical: 14),
                          ),
                          child: Text(_isSendingCode ? '发送中...' : '获取验证码'),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),

                  // 新密码输入框
                  TextField(
                    controller: _newPasswordController,
                    decoration: const InputDecoration(
                      labelText: '新支付密码',
                      helperText: '请输入6-20位数字密码',
                      border: OutlineInputBorder(),
                      prefixIcon: Icon(Icons.lock_outline),
                    ),
                    obscureText: true,
                    keyboardType: TextInputType.number,
                    inputFormatters: [
                      FilteringTextInputFormatter.digitsOnly,
                      LengthLimitingTextInputFormatter(20),
                    ],
                  ),
                  const SizedBox(height: 16),

                  // 确认新密码输入框
                  TextField(
                    controller: _confirmNewPasswordController,
                    decoration: const InputDecoration(
                      labelText: '确认新支付密码',
                      border: OutlineInputBorder(),
                      prefixIcon: Icon(Icons.lock_outline),
                    ),
                    obscureText: true,
                    keyboardType: TextInputType.number,
                    inputFormatters: [
                      FilteringTextInputFormatter.digitsOnly,
                      LengthLimitingTextInputFormatter(20),
                    ],
                  ),
                  const SizedBox(height: 24),

                  // 提交按钮
                  _isLoading
                      ? const Center(child: CircularProgressIndicator())
                      : SizedBox(
                          width: double.infinity,
                          child: ElevatedButton(
                            onPressed: _handleResetPassword,
                            style: ElevatedButton.styleFrom(
                              backgroundColor: AppTheme.primaryColor,
                              padding: const EdgeInsets.symmetric(vertical: 12),
                            ),
                            child: const Text(
                              '重置密码',
                              style: TextStyle(fontSize: 16),
                            ),
                          ),
                        ),
                ],
              ),
            ),
          ),

          const SizedBox(height: 24),

          // 重置密码说明
          Card(
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    '重置说明',
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 16),
                  _buildSecurityTip('验证码有效期为5分钟。'),
                  _buildSecurityTip('必须绑定手机号或邮箱才能重置支付密码。'),
                  _buildSecurityTip('重置密码后，原密码将立即失效。'),
                  _buildSecurityTip('如遇重置问题，请联系客服协助处理。'),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  // 安全提示项
  Widget _buildSecurityTip(String tip) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(Icons.info_outline, size: 16, color: Colors.grey[600]),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              tip,
              style: TextStyle(
                fontSize: 14,
                color: Colors.grey[600],
              ),
            ),
          ),
        ],
      ),
    );
  }

  // 处理设置密码
  void _handleSetPassword() async {
    if (_userId == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('获取用户信息失败，请重试')),
      );
      return;
    }

    // 验证输入
    final password = _passwordController.text;
    final confirmPassword = _confirmPasswordController.text;

    if (password.isEmpty || password.length < 6) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('请输入6-20位的支付密码')),
      );
      return;
    }

    if (password != confirmPassword) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('两次输入的密码不一致')),
      );
      return;
    }

    // 如果是修改密码，需要验证原密码
    if (_hasPassword) {
      final oldPassword = _oldPasswordController.text;
      if (oldPassword.isEmpty) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('请输入原支付密码')),
        );
        return;
      }
    }

    setState(() {
      _isLoading = true;
    });

    try {
      final response = await _walletService.setPaymentPassword(
        userId: _userId!,
        paymentPassword: password,
        oldPaymentPassword: _hasPassword ? _oldPasswordController.text : null,
      );

      setState(() {
        _isLoading = false;
      });

      if (response.isSuccess) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(_hasPassword ? '支付密码修改成功' : '支付密码设置成功')),
        );

        // 清空输入框
        _passwordController.clear();
        _confirmPasswordController.clear();
        _oldPasswordController.clear();

        // 更新状态
        setState(() {
          _hasPassword = true;
        });
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(response.message ?? '操作失败，请重试')),
        );
      }
    } catch (e) {
      setState(() {
        _isLoading = false;
      });

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('网络异常，请稍后再试')),
      );
    }
  }

  // 处理发送验证码
  void _handleSendCode() async {
    if (_userId == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('获取用户信息失败，请重试')),
      );
      return;
    }

    setState(() {
      _isSendingCode = true;
    });

    try {
      final response =
          await _walletService.sendResetPaymentPasswordCode(_userId!);

      if (response.isSuccess) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('验证码已发送，请查收')),
        );
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(response.message ?? '发送验证码失败，请重试')),
        );
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('网络异常，请稍后再试')),
      );
    } finally {
      setState(() {
        _isSendingCode = false;
      });
    }
  }

  // 处理重置密码
  void _handleResetPassword() async {
    if (_userId == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('获取用户信息失败，请重试')),
      );
      return;
    }

    // 验证输入
    final code = _verificationCodeController.text;
    final newPassword = _newPasswordController.text;
    final confirmNewPassword = _confirmNewPasswordController.text;

    if (code.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('请输入验证码')),
      );
      return;
    }

    if (newPassword.isEmpty || newPassword.length < 6) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('请输入6-20位的支付密码')),
      );
      return;
    }

    if (newPassword != confirmNewPassword) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('两次输入的密码不一致')),
      );
      return;
    }

    setState(() {
      _isLoading = true;
    });

    try {
      final response = await _walletService.resetPaymentPassword(
        userId: _userId!,
        newPaymentPassword: newPassword,
        verificationCode: code,
      );

      setState(() {
        _isLoading = false;
      });

      if (response.isSuccess) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('支付密码重置成功')),
        );

        // 清空输入框
        _verificationCodeController.clear();
        _newPasswordController.clear();
        _confirmNewPasswordController.clear();

        // 更新状态
        setState(() {
          _hasPassword = true;
        });

        // 切换到第一个选项卡
        _tabController.animateTo(0);
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(response.message ?? '重置失败，请重试')),
        );
      }
    } catch (e) {
      setState(() {
        _isLoading = false;
      });

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('网络异常，请稍后再试')),
      );
    }
  }
}
