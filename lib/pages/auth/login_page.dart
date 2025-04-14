import 'package:flutter/material.dart';
import 'package:flutter/gestures.dart';
import '../../config/theme.dart';
import '../../network/api.dart';
import '../../network/http_util.dart';
import '../../widgets/input_field.dart';
import '../../widgets/primary_button.dart';
import 'register_page.dart';

class LoginPage extends StatefulWidget {
  const LoginPage({Key? key}) : super(key: key);

  @override
  State<LoginPage> createState() => _LoginPageState();
}

class _LoginPageState extends State<LoginPage> {
  final TextEditingController _usernameController = TextEditingController();
  final TextEditingController _passwordController = TextEditingController();
  final _formKey = GlobalKey<FormState>();
  bool _isLoading = false;
  bool _rememberPassword = false;
  bool _agreeToTerms = false;
  String _errorMessage = '';

  @override
  void dispose() {
    _usernameController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  // 用户登录
  Future<void> _login() async {
    // 验证表单
    if (!_formKey.currentState!.validate()) {
      return;
    }

    // 检查是否同意用户协议
    if (!_agreeToTerms) {
      setState(() {
        _errorMessage = '请阅读并同意用户协议';
      });
      return;
    }

    setState(() {
      _isLoading = true;
      _errorMessage = '';
    });

    try {
      final response = await HttpUtil().post<String>(
        Api.userLogin,
        data: {
          'username': _usernameController.text,
          'password': _passwordController.text,
        },
      );

      if (response.isSuccess && response.data != null) {
        // 登录成功，保存token
        await HttpUtil().saveToken(response.data!);

        // 登录成功后跳转到主页
        if (!mounted) return;
        Navigator.pushReplacementNamed(context, '/home');
      } else {
        setState(() {
          _errorMessage = response.message ?? '登录失败，请检查用户名和密码';
        });
      }
    } catch (e) {
      setState(() {
        _errorMessage = '网络错误，请稍后再试';
      });
    } finally {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: AppTheme.textColor),
          onPressed: () => Navigator.pop(context),
        ),
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(24.0),
          child: Form(
            key: _formKey,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                // Logo图标
                Center(
                  child: Container(
                    width: 80,
                    height: 80,
                    decoration: BoxDecoration(
                      color: AppTheme.secondaryColor,
                      borderRadius: BorderRadius.circular(15),
                    ),
                    alignment: Alignment.center,
                    child: const Text(
                      '闲转',
                      style: TextStyle(
                        fontSize: 28,
                        fontWeight: FontWeight.bold,
                        color: AppTheme.primaryColor,
                      ),
                    ),
                  ),
                ),
                const SizedBox(height: 24),

                // 欢迎文字
                const Text(
                  '欢迎来到闲转',
                  style: AppTheme.headingStyle,
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 8),
                const Text(
                  '闲置物品，一键转让',
                  style: AppTheme.subtitleStyle,
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 32),

                // 用户名输入框
                InputField(
                  hintText: '手机号/账号',
                  prefixIcon: Icons.person_outline,
                  controller: _usernameController,
                  validator: (value) {
                    if (value == null || value.isEmpty) {
                      return '请输入账号';
                    }
                    return null;
                  },
                ),
                const SizedBox(height: 16),

                // 密码输入框
                InputField(
                  hintText: '密码',
                  prefixIcon: Icons.lock_outline,
                  obscureText: true,
                  controller: _passwordController,
                  validator: (value) {
                    if (value == null || value.isEmpty) {
                      return '请输入密码';
                    }
                    return null;
                  },
                ),

                // 显示错误信息
                if (_errorMessage.isNotEmpty)
                  Padding(
                    padding: const EdgeInsets.only(top: 8.0),
                    child: Text(
                      _errorMessage,
                      style: const TextStyle(color: Colors.red, fontSize: 14),
                    ),
                  ),

                // 记住密码和忘记密码
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Row(
                      children: [
                        Checkbox(
                          value: _rememberPassword,
                          onChanged: (value) {
                            setState(() {
                              _rememberPassword = value!;
                            });
                          },
                          activeColor: AppTheme.primaryColor,
                        ),
                        const Text('记住密码'),
                      ],
                    ),
                    TextButton(
                      onPressed: () {
                        // 实现忘记密码的逻辑
                      },
                      child: const Text(
                        '忘记密码?',
                        style: TextStyle(color: AppTheme.primaryColor),
                      ),
                    ),
                  ],
                ),

                const SizedBox(height: 24),

                // 登录按钮
                PrimaryButton(
                  text: '登录',
                  onPressed: _login,
                  isLoading: _isLoading,
                ),

                const SizedBox(height: 16),

                // 用户协议
                Row(
                  children: [
                    Checkbox(
                      value: _agreeToTerms,
                      onChanged: (value) {
                        setState(() {
                          _agreeToTerms = value!;
                        });
                      },
                      activeColor: AppTheme.primaryColor,
                    ),
                    Expanded(
                      child: RichText(
                        text: TextSpan(
                          text: '我已阅读并同意 ',
                          style: const TextStyle(color: AppTheme.subtitleColor),
                          children: [
                            TextSpan(
                              text: '用户协议',
                              style:
                                  const TextStyle(color: AppTheme.primaryColor),
                              recognizer: TapGestureRecognizer()
                                ..onTap = () {
                                  // 显示用户协议
                                },
                            ),
                            const TextSpan(
                              text: ' 和 ',
                              style: TextStyle(color: AppTheme.subtitleColor),
                            ),
                            TextSpan(
                              text: '隐私政策',
                              style:
                                  const TextStyle(color: AppTheme.primaryColor),
                              recognizer: TapGestureRecognizer()
                                ..onTap = () {
                                  // 显示隐私政策
                                },
                            ),
                          ],
                        ),
                      ),
                    ),
                  ],
                ),

                const SizedBox(height: 24),

                // 注册入口
                RichText(
                  text: TextSpan(
                    text: '没有账号？',
                    style: const TextStyle(color: AppTheme.textColor),
                    children: [
                      TextSpan(
                        text: ' 立即注册',
                        style: const TextStyle(
                          color: AppTheme.primaryColor,
                          fontWeight: FontWeight.bold,
                        ),
                        recognizer: TapGestureRecognizer()
                          ..onTap = () {
                            Navigator.push(
                              context,
                              MaterialPageRoute(
                                builder: (context) => const RegisterPage(),
                              ),
                            );
                          },
                      ),
                    ],
                  ),
                ),

                const SizedBox(height: 32),

                // 其他登录方式
                const Text(
                  '─ 其他登录方式 ─',
                  style: AppTheme.subtitleStyle,
                ),
                const SizedBox(height: 16),
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    _buildSocialLoginButton(Icons.wechat, Colors.green),
                    const SizedBox(width: 24),
                    _buildSocialLoginButton(Icons.phone_android, Colors.blue),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildSocialLoginButton(IconData icon, Color color) {
    return InkWell(
      onTap: () {
        // 处理社交媒体登录
      },
      child: Container(
        width: 50,
        height: 50,
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(25),
          border: Border.all(color: Colors.grey.shade300),
        ),
        child: Icon(icon, color: color, size: 28),
      ),
    );
  }
}
