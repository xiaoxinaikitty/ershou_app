import 'package:flutter/material.dart';
import '../config/theme.dart';

class MessagePage extends StatefulWidget {
  const MessagePage({Key? key}) : super(key: key);

  @override
  State<MessagePage> createState() => _MessagePageState();
}

class _MessagePageState extends State<MessagePage> {
  // 模拟聊天数据
  final List<Map<String, dynamic>> _chatList = [
    {
      'avatar': 'assets/images/avatar1.jpg',
      'name': '李先生',
      'lastMessage': '您好，请问这个商品还在吗？',
      'time': '刚刚',
      'unread': 2,
      'online': true,
    },
    {
      'avatar': 'assets/images/avatar2.jpg',
      'name': '王女士',
      'lastMessage': '好的，那我们约定明天下午交易',
      'time': '10:30',
      'unread': 0,
      'online': false,
    },
    {
      'avatar': 'assets/images/avatar3.jpg',
      'name': '张先生',
      'lastMessage': '可以便宜一点吗？',
      'time': '昨天',
      'unread': 1,
      'online': false,
    },
    {
      'avatar': 'assets/images/avatar4.jpg',
      'name': '刘女士',
      'lastMessage': '谢谢，收到了，很满意',
      'time': '昨天',
      'unread': 0,
      'online': true,
    },
    {
      'avatar': 'assets/images/avatar5.jpg',
      'name': '赵先生',
      'lastMessage': '请问有什么颜色可选？',
      'time': '周一',
      'unread': 0,
      'online': false,
    },
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('消息', style: TextStyle(fontWeight: FontWeight.bold)),
        elevation: 0,
        actions: [
          IconButton(
            icon: const Icon(Icons.more_horiz),
            onPressed: () {
              // 显示更多操作
            },
          ),
        ],
      ),
      body: Column(
        children: [
          // 搜索框
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              decoration: BoxDecoration(
                color: Colors.grey[200],
                borderRadius: BorderRadius.circular(20),
              ),
              child: const Row(
                children: [
                  Icon(Icons.search, color: Colors.grey),
                  SizedBox(width: 8),
                  Text('搜索消息', style: TextStyle(color: Colors.grey)),
                ],
              ),
            ),
          ),

          // 系统通知
          ListTile(
            leading: Container(
              width: 40,
              height: 40,
              decoration: BoxDecoration(
                color: AppTheme.primaryColor.withOpacity(0.1),
                shape: BoxShape.circle,
              ),
              child: Icon(Icons.notifications, color: AppTheme.primaryColor),
            ),
            title: const Text('系统通知'),
            subtitle: const Text('你有一条新的系统消息'),
            trailing: Container(
              width: 20,
              height: 20,
              decoration: BoxDecoration(
                color: Colors.red,
                shape: BoxShape.circle,
              ),
              child: const Center(
                child: Text(
                  '1',
                  style: TextStyle(color: Colors.white, fontSize: 12),
                ),
              ),
            ),
            onTap: () {
              // 查看系统通知
            },
          ),

          const Divider(),

          // 聊天列表
          Expanded(
            child: ListView.separated(
              itemCount: _chatList.length,
              separatorBuilder: (context, index) => const Divider(
                indent: 72,
                height: 1,
              ),
              itemBuilder: (context, index) {
                final chat = _chatList[index];
                return ListTile(
                  leading: Stack(
                    children: [
                      CircleAvatar(
                        radius: 24,
                        backgroundColor: Colors.grey[300],
                        child: const Icon(Icons.person, color: Colors.white),
                      ),
                      if (chat['online'])
                        Positioned(
                          right: 0,
                          bottom: 0,
                          child: Container(
                            width: 12,
                            height: 12,
                            decoration: BoxDecoration(
                              color: Colors.green,
                              shape: BoxShape.circle,
                              border: Border.all(
                                color: Colors.white,
                                width: 2,
                              ),
                            ),
                          ),
                        ),
                    ],
                  ),
                  title: Text(
                    chat['name'],
                    style: const TextStyle(fontWeight: FontWeight.bold),
                  ),
                  subtitle: Text(
                    chat['lastMessage'],
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                  trailing: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    crossAxisAlignment: CrossAxisAlignment.end,
                    children: [
                      Text(
                        chat['time'],
                        style: TextStyle(
                          color: Colors.grey[500],
                          fontSize: 12,
                        ),
                      ),
                      const SizedBox(height: 4),
                      if (chat['unread'] > 0)
                        Container(
                          width: 20,
                          height: 20,
                          decoration: BoxDecoration(
                            color: Colors.red,
                            shape: BoxShape.circle,
                          ),
                          child: Center(
                            child: Text(
                              chat['unread'].toString(),
                              style: const TextStyle(
                                color: Colors.white,
                                fontSize: 12,
                              ),
                            ),
                          ),
                        ),
                    ],
                  ),
                  onTap: () {
                    // 打开聊天详情
                  },
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}
