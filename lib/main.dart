import 'package:ershou_app/network/http_util.dart';
import 'package:ershou_app/pages/auth/login_page.dart';
import 'package:flutter/material.dart';
import 'config/theme.dart';
import 'network/api.dart';
import 'pages/auth/register_page.dart';

void main() {
  // 确保 Flutter 框架完全初始化
  WidgetsFlutterBinding.ensureInitialized();
  // 初始化 HttpUtil（单例模式，只需执行一次）
  HttpUtil();

  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: '闲转',
      theme: AppTheme.theme,
      initialRoute: '/login',
      routes: {
        '/login': (context) => const LoginPage(),
        '/register': (context) => const RegisterPage(),
        '/home': (context) => const HomePage(),
      },
      debugShowCheckedModeBanner: false,
    );
  }
}

class HomePage extends StatefulWidget {
  const HomePage({super.key});

  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  Map<String, dynamic>? _userInfo;
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _fetchUserInfo();
  }

  // 获取用户信息
  Future<void> _fetchUserInfo() async {
    try {
      final response = await HttpUtil().get(Api.userInfo);

      if (response.isSuccess && response.data != null) {
        setState(() {
          _userInfo = response.data as Map<String, dynamic>;
          _isLoading = false;
        });
      } else {
        _showErrorMessage('获取用户信息失败');
      }
    } catch (e) {
      _showErrorMessage('网络错误，请稍后再试');
    }
  }

  void _showErrorMessage(String message) {
    setState(() {
      _isLoading = false;
    });

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(message)),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('闲转'),
        actions: [
          IconButton(
            icon: const Icon(Icons.logout),
            onPressed: () async {
              await HttpUtil().clearToken();
              if (!mounted) return;
              Navigator.of(context).pushReplacementNamed('/login');
            },
          ),
        ],
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : _userInfo == null
              ? const Center(child: Text('暂无数据'))
              : Padding(
                  padding: const EdgeInsets.all(16.0),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        '欢迎回来，${_userInfo!['username'] ?? '用户'}',
                        style: Theme.of(context).textTheme.headlineMedium,
                      ),
                      const SizedBox(height: 16),
                      Card(
                        child: ListTile(
                          leading: const Icon(Icons.person),
                          title: Text('用户ID: ${_userInfo!['userId'] ?? ''}'),
                        ),
                      ),
                      Card(
                        child: ListTile(
                          leading: const Icon(Icons.phone),
                          title: Text('电话: ${_userInfo!['phone'] ?? ''}'),
                        ),
                      ),
                      Card(
                        child: ListTile(
                          leading: const Icon(Icons.email),
                          title: Text('邮箱: ${_userInfo!['email'] ?? ''}'),
                        ),
                      ),
                    ],
                  ),
                ),
    );
  }
}
