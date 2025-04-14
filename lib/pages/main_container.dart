import 'package:flutter/material.dart';
import '../widgets/bottom_navigation.dart';
import 'home_page.dart';
import 'local_page.dart';
import 'message_page.dart';
import 'profile_page.dart';
import 'publish_page.dart';

class MainContainer extends StatefulWidget {
  const MainContainer({Key? key}) : super(key: key);

  @override
  State<MainContainer> createState() => _MainContainerState();
}

class _MainContainerState extends State<MainContainer> {
  int _currentIndex = 0;
  final PageController _pageController = PageController();

  // 页面列表
  final List<Widget> _pages = [
    const HomePage(),
    const LocalPage(),
    const PublishPage(),
    const MessagePage(),
    const ProfilePage(),
  ];

  @override
  void dispose() {
    _pageController.dispose();
    super.dispose();
  }

  void _onPageChanged(int index) {
    setState(() {
      _currentIndex = index;
    });
  }

  void _onTabTapped(int index) {
    // 对于发布页面，我们不使用PageView滑动，而是直接显示发布页
    if (index == 2) {
      showModalBottomSheet(
        context: context,
        isScrollControlled: true,
        builder: (context) => const PublishPage(),
      );
      return;
    }

    // 调整实际索引，因为发布页面不在PageView中
    final actualIndex = index > 2 ? index - 1 : index;

    setState(() {
      _currentIndex = index;
    });

    _pageController.jumpToPage(actualIndex);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: PageView(
        controller: _pageController,
        children: [
          _pages[0], // 首页
          _pages[1], // 同城
          // 发布页不在PageView中，而是通过模态框显示
          _pages[3], // 消息
          _pages[4], // 个人中心
        ],
        onPageChanged: (index) {
          // 调整索引，跳过发布页面索引
          _onPageChanged(index < 2 ? index : index + 1);
        },
        physics: const NeverScrollableScrollPhysics(), // 禁用滑动，使用底部导航栏切换
      ),
      bottomNavigationBar: BottomNavigation(
        currentIndex: _currentIndex,
        onTap: _onTabTapped,
      ),
    );
  }
}
