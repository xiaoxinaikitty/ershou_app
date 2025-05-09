import 'package:ershou_app/network/http_util.dart';
import 'package:ershou_app/pages/auth/login_page.dart';
import 'package:flutter/material.dart';
import 'config/theme.dart';
import 'network/api.dart';
import 'pages/auth/register_page.dart';
import 'pages/main_container.dart';
import 'pages/address_management_page.dart';
import 'pages/order/create_order_page.dart';
import 'pages/order/pending_payment_page.dart';

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
        '/home': (context) => const MainContainer(), // 更新为MainContainer
        '/address-management': (context) => const AddressManagementPage(),
        '/pending-payment': (context) => const PendingPaymentPage(),
      },
      debugShowCheckedModeBanner: false,
    );
  }
}
