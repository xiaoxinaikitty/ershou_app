import 'package:flutter/material.dart';
import '../config/theme.dart';
import '../network/api.dart';
import '../network/http_util.dart';
import 'auth/login_page.dart';

class SettingsPage extends StatefulWidget {
  const SettingsPage({Key? key}) : super(key: key);

  @override
  State<SettingsPage> createState() => _SettingsPageState();
}

class _SettingsPageState extends State<SettingsPage> {
  Map<String, dynamic>? _userInfo;
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _fetchUserInfo();
  }

  Future<void> _fetchUserInfo() async {
    try {
      final response = await HttpUtil().get(Api.userInfo);

      if (response.isSuccess && response.data != null) {
        setState(() {
          _userInfo = response.data as Map<String, dynamic>;
          _isLoading = false;
        });
      } else {
        setState(() {
          _isLoading = false;
        });

        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('获取用户信息失败')),
          );
        }
      }
    } catch (e) {
      setState(() {
        _isLoading = false;
      });

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('网络错误，请稍后再试')),
        );
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

    return Scaffold(
      appBar: AppBar(
        title: const Text('设置', style: TextStyle(fontWeight: FontWeight.bold)),
        elevation: 0,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // 个人信息卡片
            _buildUserInfoCard(),

            const SizedBox(height: 24),

            // 账户安全设置
            _buildSectionTitle('账户与安全'),
            _buildSettingsItem(
              icon: Icons.lock_outline,
              title: '修改密码',
              onTap: () => _showChangePasswordDialog(context),
            ),
            _buildSettingsItem(
              icon: Icons.admin_panel_settings_outlined,
              title: '切换管理员登录',
              onTap: () => _showAdminLoginDialog(context),
            ),

            const SizedBox(height: 16),

            // 地址管理设置
            _buildSectionTitle('收货地址'),
            _buildSettingsItem(
              icon: Icons.location_on_outlined,
              title: '地址管理',
              onTap: () => _navigateToAddressManagement(context),
            ),

            const SizedBox(height: 16),

            // 通用设置
            _buildSectionTitle('通用'),
            _buildSettingsItem(
              icon: Icons.notifications_none,
              title: '通知设置',
              onTap: () {},
            ),
            _buildSettingsItem(
              icon: Icons.language_outlined,
              title: '语言设置',
              onTap: () {},
            ),
            _buildSettingsItem(
              icon: Icons.privacy_tip_outlined,
              title: '隐私政策',
              onTap: () {},
            ),
            _buildSettingsItem(
              icon: Icons.help_outline,
              title: '帮助中心',
              onTap: () {},
            ),
            _buildSettingsItem(
              icon: Icons.info_outline,
              title: '关于闲转',
              onTap: () {},
            ),

            const SizedBox(height: 32),

            // 退出登录按钮
            SizedBox(
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
          ],
        ),
      ),
    );
  }

  Widget _buildUserInfoCard() {
    final username = _userInfo?['username'] ?? '用户';
    final phone = _userInfo?['phone'] ?? '未设置手机号';
    final email = _userInfo?['email'] ?? '未设置邮箱';

    return Card(
      elevation: 1,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: InkWell(
        onTap: () => _navigateToUserInfoEdit(context),
        borderRadius: BorderRadius.circular(12),
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Row(
            children: [
              // 头像
              CircleAvatar(
                radius: 30,
                backgroundColor: AppTheme.secondaryColor,
                child: Icon(
                  Icons.person,
                  size: 30,
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
                        fontSize: 18,
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
                    if (email != '未设置邮箱')
                      Text(
                        email,
                        style: TextStyle(
                          fontSize: 14,
                          color: Colors.grey[600],
                        ),
                      ),
                  ],
                ),
              ),
              // 编辑图标
              const Icon(Icons.arrow_forward_ios, size: 16, color: Colors.grey),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildSectionTitle(String title) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8.0),
      child: Text(
        title,
        style: const TextStyle(
          fontSize: 16,
          fontWeight: FontWeight.bold,
          color: AppTheme.textColor,
        ),
      ),
    );
  }

  Widget _buildSettingsItem({
    required IconData icon,
    required String title,
    String? subtitle,
    required VoidCallback onTap,
  }) {
    return Card(
      elevation: 0,
      margin: const EdgeInsets.only(bottom: 8),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
        side: BorderSide(color: Colors.grey.shade200),
      ),
      child: ListTile(
        leading: Icon(icon, color: AppTheme.primaryColor),
        title: Text(title),
        subtitle: subtitle != null ? Text(subtitle) : null,
        trailing: const Icon(Icons.arrow_forward_ios, size: 16),
        onTap: onTap,
      ),
    );
  }

  void _showChangePasswordDialog(BuildContext context) {
    final oldPasswordController = TextEditingController();
    final newPasswordController = TextEditingController();
    final confirmPasswordController = TextEditingController();
    final formKey = GlobalKey<FormState>();
    bool isLoading = false;

    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) {
        return StatefulBuilder(
          builder: (context, setState) {
            return AlertDialog(
              title: const Text('修改密码'),
              content: Form(
                key: formKey,
                child: SingleChildScrollView(
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      TextFormField(
                        controller: oldPasswordController,
                        decoration: const InputDecoration(
                          labelText: '当前密码',
                          border: OutlineInputBorder(),
                        ),
                        obscureText: true,
                        validator: (value) {
                          if (value == null || value.isEmpty) {
                            return '请输入当前密码';
                          }
                          return null;
                        },
                      ),
                      const SizedBox(height: 16),
                      TextFormField(
                        controller: newPasswordController,
                        decoration: const InputDecoration(
                          labelText: '新密码',
                          border: OutlineInputBorder(),
                        ),
                        obscureText: true,
                        validator: (value) {
                          if (value == null || value.isEmpty) {
                            return '请输入新密码';
                          }
                          if (value.length < 6) {
                            return '密码长度不能小于6位';
                          }
                          return null;
                        },
                      ),
                      const SizedBox(height: 16),
                      TextFormField(
                        controller: confirmPasswordController,
                        decoration: const InputDecoration(
                          labelText: '确认新密码',
                          border: OutlineInputBorder(),
                        ),
                        obscureText: true,
                        validator: (value) {
                          if (value == null || value.isEmpty) {
                            return '请确认新密码';
                          }
                          if (value != newPasswordController.text) {
                            return '两次密码输入不一致';
                          }
                          return null;
                        },
                      ),
                    ],
                  ),
                ),
              ),
              actions: [
                TextButton(
                  onPressed: () => Navigator.pop(context),
                  child: const Text('取消'),
                ),
                ElevatedButton(
                  onPressed: isLoading
                      ? null
                      : () async {
                          if (formKey.currentState!.validate()) {
                            setState(() {
                              isLoading = true;
                            });

                            try {
                              final response = await HttpUtil().put(
                                Api.userPassword,
                                data: {
                                  'oldPassword': oldPasswordController.text,
                                  'newPassword': newPasswordController.text,
                                },
                              );

                              if (response.isSuccess) {
                                if (!context.mounted) return;
                                Navigator.pop(context);
                                ScaffoldMessenger.of(context).showSnackBar(
                                  const SnackBar(content: Text('密码修改成功')),
                                );
                              } else {
                                if (!context.mounted) return;
                                ScaffoldMessenger.of(context).showSnackBar(
                                  SnackBar(
                                      content:
                                          Text(response.message ?? '密码修改失败')),
                                );
                              }
                            } catch (e) {
                              if (!context.mounted) return;
                              ScaffoldMessenger.of(context).showSnackBar(
                                const SnackBar(content: Text('网络错误，请稍后再试')),
                              );
                            } finally {
                              if (mounted) {
                                setState(() {
                                  isLoading = false;
                                });
                              }
                            }
                          }
                        },
                  child: isLoading
                      ? const SizedBox(
                          height: 20,
                          width: 20,
                          child: CircularProgressIndicator(strokeWidth: 2),
                        )
                      : const Text('确认修改'),
                ),
              ],
            );
          },
        );
      },
    );
  }

  void _showAdminLoginDialog(BuildContext context) {
    final usernameController = TextEditingController();
    final passwordController = TextEditingController();
    final formKey = GlobalKey<FormState>();
    bool isLoading = false;

    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) {
        return StatefulBuilder(
          builder: (context, setState) {
            return AlertDialog(
              title: const Text('管理员登录'),
              content: Form(
                key: formKey,
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    TextFormField(
                      controller: usernameController,
                      decoration: const InputDecoration(
                        labelText: '管理员账号',
                        border: OutlineInputBorder(),
                      ),
                      validator: (value) {
                        if (value == null || value.isEmpty) {
                          return '请输入管理员账号';
                        }
                        return null;
                      },
                    ),
                    const SizedBox(height: 16),
                    TextFormField(
                      controller: passwordController,
                      decoration: const InputDecoration(
                        labelText: '密码',
                        border: OutlineInputBorder(),
                      ),
                      obscureText: true,
                      validator: (value) {
                        if (value == null || value.isEmpty) {
                          return '请输入密码';
                        }
                        return null;
                      },
                    ),
                  ],
                ),
              ),
              actions: [
                TextButton(
                  onPressed: () => Navigator.pop(context),
                  child: const Text('取消'),
                ),
                ElevatedButton(
                  onPressed: isLoading
                      ? null
                      : () async {
                          if (formKey.currentState!.validate()) {
                            setState(() {
                              isLoading = true;
                            });

                            try {
                              final response = await HttpUtil().post(
                                Api.adminLogin,
                                data: {
                                  'username': usernameController.text,
                                  'password': passwordController.text,
                                },
                              );

                              if (response.isSuccess) {
                                final token = response.data['token'] as String;
                                await HttpUtil().saveToken(token);

                                if (!context.mounted) return;
                                Navigator.pop(context);
                                ScaffoldMessenger.of(context).showSnackBar(
                                  const SnackBar(content: Text('管理员登录成功')),
                                );

                                // 重新获取用户信息以更新UI
                                _fetchUserInfo();
                              } else {
                                if (!context.mounted) return;
                                ScaffoldMessenger.of(context).showSnackBar(
                                  SnackBar(
                                      content:
                                          Text(response.message ?? '管理员登录失败')),
                                );
                              }
                            } catch (e) {
                              if (!context.mounted) return;
                              ScaffoldMessenger.of(context).showSnackBar(
                                const SnackBar(content: Text('网络错误，请稍后再试')),
                              );
                            } finally {
                              if (mounted) {
                                setState(() {
                                  isLoading = false;
                                });
                              }
                            }
                          }
                        },
                  child: isLoading
                      ? const SizedBox(
                          height: 20,
                          width: 20,
                          child: CircularProgressIndicator(strokeWidth: 2),
                        )
                      : const Text('登录'),
                ),
              ],
            );
          },
        );
      },
    );
  }

  void _navigateToUserInfoEdit(BuildContext context) {
    // 这里将在后续步骤中实现用户信息编辑功能
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => UserInfoEditPage(userInfo: _userInfo!),
      ),
    ).then((_) {
      // 编辑完成后刷新用户信息
      _fetchUserInfo();
    });
  }

  void _navigateToAddressManagement(BuildContext context) {
    // 这里将在后续步骤中实现地址管理功能
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => const AddressManagementPage(),
      ),
    );
  }

  void _logout() async {
    try {
      await HttpUtil().clearToken();
      if (!mounted) return;
      Navigator.of(context).pushNamedAndRemoveUntil('/login', (route) => false);
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('退出登录失败')),
      );
    }
  }
}

// 占位类，稍后实现
class UserInfoEditPage extends StatefulWidget {
  final Map<String, dynamic> userInfo;

  const UserInfoEditPage({Key? key, required this.userInfo}) : super(key: key);

  @override
  State<UserInfoEditPage> createState() => _UserInfoEditPageState();
}

class _UserInfoEditPageState extends State<UserInfoEditPage> {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('编辑个人资料'),
      ),
      body: const Center(
        child: Text('编辑个人资料功能将在后续步骤中实现'),
      ),
    );
  }
}

// 占位类，稍后实现
class AddressManagementPage extends StatefulWidget {
  const AddressManagementPage({Key? key}) : super(key: key);

  @override
  State<AddressManagementPage> createState() => _AddressManagementPageState();
}

class _AddressManagementPageState extends State<AddressManagementPage> {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('地址管理'),
      ),
      body: const Center(
        child: Text('地址管理功能将在后续步骤中实现'),
      ),
    );
  }
}
