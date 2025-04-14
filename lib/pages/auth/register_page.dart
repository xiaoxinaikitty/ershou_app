import 'package:flutter/material.dart';
import 'package:flutter/gestures.dart';
import '../../config/theme.dart';
import '../../network/api.dart';
import '../../network/http_util.dart';
import '../../widgets/input_field.dart';
import '../../widgets/primary_button.dart';
import 'login_page.dart';

class RegisterPage extends StatefulWidget {
  const RegisterPage({Key? key}) : super(key: key);

  @override
  State<RegisterPage> createState() => _RegisterPageState();
}

class _RegisterPageState extends State<RegisterPage> {
  final TextEditingController _usernameController = TextEditingController();
  final TextEditingController _phoneController = TextEditingController();
  final TextEditingController _passwordController = TextEditingController();
  final TextEditingController _confirmPasswordController =
      TextEditingController();
  final _formKey = GlobalKey<FormState>();
  bool _isLoading = false;
  bool _agreeToTerms = false;
  String _errorMessage = '';

  @override
  void dispose() {
    _usernameController.dispose();
    _phoneController.dispose();
    _passwordController.dispose();
    _confirmPasswordController.dispose();
    super.dispose();
  }

  // 用户注册
  Future<void> _register() async {
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
      final response = await HttpUtil().post(
        Api.userRegister,
        data: {
          'username': _usernameController.text,
          'phone': _phoneController.text,
          'password': _passwordController.text,
        },
      );

      if (response.isSuccess) {
        // 注册成功，显示提示并自动跳转到登录页
        if (!mounted) return;

        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('注册成功，请登录')),
        );

        Navigator.pushReplacement(
          context,
          MaterialPageRoute(builder: (context) => const LoginPage()),
        );
      } else {
        setState(() {
          _errorMessage = response.message ?? '注册失败，请稍后再试';
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
        title: const Text('注册账号', style: TextStyle(color: AppTheme.textColor)),
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(24.0),
          child: Form(
            key: _formKey,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // 欢迎文字
                const Text(
                  '创建账号',
                  style: AppTheme.headingStyle,
                ),
                const SizedBox(height: 8),
                const Text(
                  '请填写以下信息完成注册',
                  style: AppTheme.subtitleStyle,
                ),
                const SizedBox(height: 32),

                // 用户名输入框
                InputField(
                  hintText: '用户名',
                  prefixIcon: Icons.person_outline,
                  controller: _usernameController,
                  validator: (value) {
                    if (value == null || value.isEmpty) {
                      return '请输入用户名';
                    }
                    if (value.length < 3) {
                      return '用户名至少需要3个字符';
                    }
                    return null;
                  },
                ),
                const SizedBox(height: 16),

                // 手机号输入框
                InputField(
                  hintText: '手机号',
                  prefixIcon: Icons.phone_android,
                  keyboardType: TextInputType.phone,
                  controller: _phoneController,
                  validator: (value) {
                    if (value == null || value.isEmpty) {
                      return '请输入手机号';
                    }
                    if (value.length != 11 ||
                        !RegExp(r'^1\d{10}$').hasMatch(value)) {
                      return '请输入有效的手机号码';
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
                    if (value.length < 6) {
                      return '密码至少需要6个字符';
                    }
                    return null;
                  },
                ),
                const SizedBox(height: 16),

                // 确认密码输入框
                InputField(
                  hintText: '确认密码',
                  prefixIcon: Icons.lock_outline,
                  obscureText: true,
                  controller: _confirmPasswordController,
                  validator: (value) {
                    if (value == null || value.isEmpty) {
                      return '请再次输入密码';
                    }
                    if (value != _passwordController.text) {
                      return '两次输入的密码不一致';
                    }
                    return null;
                  },
                ),

                // 显示错误信息
                if (_errorMessage.isNotEmpty)
                  Padding(
                    padding: const EdgeInsets.only(top: 16.0),
                    child: Text(
                      _errorMessage,
                      style: const TextStyle(color: Colors.red, fontSize: 14),
                    ),
                  ),

                const SizedBox(height: 24),

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

                const SizedBox(height: 32),

                // 注册按钮
                PrimaryButton(
                  text: '注册',
                  onPressed: _register,
                  isLoading: _isLoading,
                ),

                const SizedBox(height: 24),

                // 登录入口
                Center(
                  child: RichText(
                    text: TextSpan(
                      text: '已有账号？',
                      style: const TextStyle(color: AppTheme.textColor),
                      children: [
                        TextSpan(
                          text: ' 立即登录',
                          style: const TextStyle(
                            color: AppTheme.primaryColor,
                            fontWeight: FontWeight.bold,
                          ),
                          recognizer: TapGestureRecognizer()
                            ..onTap = () {
                              Navigator.pushReplacement(
                                context,
                                MaterialPageRoute(
                                  builder: (context) => const LoginPage(),
                                ),
                              );
                            },
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
