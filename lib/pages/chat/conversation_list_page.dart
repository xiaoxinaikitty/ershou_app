import 'package:flutter/material.dart';
import 'dart:developer' as developer;
import '../../network/api.dart';
import '../../network/http_util.dart';
import '../../models/conversation.dart';
import 'message_page.dart';

class ConversationListPage extends StatefulWidget {
  const ConversationListPage({Key? key}) : super(key: key);

  @override
  State<ConversationListPage> createState() => _ConversationListPageState();
}

class _ConversationListPageState extends State<ConversationListPage> with SingleTickerProviderStateMixin {
  late TabController _tabController;
  List<Conversation> _buyerConversations = [];
  List<Conversation> _sellerConversations = [];
  bool _isBuyerLoading = true;
  bool _isSellerLoading = true;
  String _buyerErrorMessage = '';
  String _sellerErrorMessage = '';
  int _totalUnreadCount = 0;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
    _fetchBuyerConversations();
    _fetchSellerConversations();
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  // 获取买家会话列表
  Future<void> _fetchBuyerConversations() async {
    setState(() {
      _isBuyerLoading = true;
      _buyerErrorMessage = '';
    });

    try {
      final response = await HttpUtil().get(Api.userConversations);

      if (response.isSuccess && response.data != null) {
        final List<dynamic> conversationsData = response.data as List<dynamic>;
        setState(() {
          _buyerConversations = conversationsData
              .map((data) => Conversation.fromJson(data))
              .toList();
          _isBuyerLoading = false;

          // 计算未读消息总数
          _updateTotalUnreadCount();
        });
      } else {
        setState(() {
          _isBuyerLoading = false;
          _buyerErrorMessage = response.message ?? '获取会话列表失败';
        });
      }
    } catch (e) {
      developer.log('获取买家会话异常: $e', name: 'ConversationListPage');
      setState(() {
        _isBuyerLoading = false;
        _buyerErrorMessage = '网络错误: $e';
      });
    }
  }

  // 获取卖家会话列表
  Future<void> _fetchSellerConversations() async {
    setState(() {
      _isSellerLoading = true;
      _sellerErrorMessage = '';
    });

    try {
      final response = await HttpUtil().get(Api.sellerConversations);

      if (response.isSuccess && response.data != null) {
        final List<dynamic> conversationsData = response.data as List<dynamic>;
        setState(() {
          _sellerConversations = conversationsData
              .map((data) => Conversation.fromJson(data))
              .toList();
          _isSellerLoading = false;

          // 计算未读消息总数
          _updateTotalUnreadCount();
        });
      } else {
        setState(() {
          _isSellerLoading = false;
          _sellerErrorMessage = response.message ?? '获取会话列表失败';
        });
      }
    } catch (e) {
      developer.log('获取卖家会话异常: $e', name: 'ConversationListPage');
      setState(() {
        _isSellerLoading = false;
        _sellerErrorMessage = '网络错误: $e';
      });
    }
  }

  // 计算未读消息总数
  void _updateTotalUnreadCount() {
    int buyerUnread = _buyerConversations.fold(0, (sum, conv) => sum + (conv.unreadCount ?? 0));
    int sellerUnread = _sellerConversations.fold(0, (sum, conv) => sum + (conv.unreadCount ?? 0));
    setState(() {
      _totalUnreadCount = buyerUnread + sellerUnread;
    });
  }

  // 标记会话为已读
  Future<void> _markConversationAsRead(Conversation conversation) async {
    try {
      if (conversation.conversationId != null) {
        await HttpUtil().post('${Api.markConversationRead}${conversation.conversationId}');
        // 不更新UI，等待进入消息页面后刷新
      }
    } catch (e) {
      developer.log('标记会话已读异常: $e', name: 'ConversationListPage');
    }
  }

  // 进入消息详情页
  void _navigateToMessagePage(Conversation conversation) async {
    if (conversation.conversationId == null || conversation.productId == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('会话信息不完整，无法打开对话')),
      );
      return;
    }

    // 标记会话为已读
    await _markConversationAsRead(conversation);

    // 确定接收者ID（如果当前用户是买家，接收者是卖家；如果当前用户是卖家，接收者是买家）
    final currentUserId = HttpUtil().getCurrentUserId();
    final bool isCurrentUserBuyer = currentUserId == conversation.userId;
    final int receiverId = isCurrentUserBuyer
        ? conversation.sellerId ?? 0
        : conversation.userId ?? 0;
    final String receiverName = isCurrentUserBuyer
        ? conversation.sellerUsername ?? '卖家'
        : conversation.username ?? '买家';

    if (!mounted) return;

    // 导航到消息页面
    final result = await Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => MessagePage(
          productId: conversation.productId!,
          receiverId: receiverId,
          productTitle: conversation.productTitle,
          receiverName: receiverName,
          productImage: conversation.productImage,
        ),
      ),
    );

    // 如果返回后，刷新会话列表
    if (result == true || result == null) {
      _fetchBuyerConversations();
      _fetchSellerConversations();
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('我的消息'),
        elevation: 0,
        bottom: TabBar(
          controller: _tabController,
          tabs: const [
            Tab(text: '我的咨询'),
            Tab(text: '卖家消息'),
          ],
        ),
      ),
      body: TabBarView(
        controller: _tabController,
        children: [
          // 买家会话列表
          _buildConversationList(
            _buyerConversations,
            _isBuyerLoading,
            _buyerErrorMessage,
            _fetchBuyerConversations,
            '暂无咨询记录',
          ),
          
          // 卖家会话列表
          _buildConversationList(
            _sellerConversations,
            _isSellerLoading,
            _sellerErrorMessage,
            _fetchSellerConversations,
            '暂无卖家消息',
          ),
        ],
      ),
    );
  }

  Widget _buildConversationList(
    List<Conversation> conversations,
    bool isLoading,
    String errorMessage,
    VoidCallback onRefresh,
    String emptyMessage,
  ) {
    if (isLoading) {
      return const Center(
        child: CircularProgressIndicator(),
      );
    }

    if (errorMessage.isNotEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Icons.error_outline, size: 60, color: Colors.grey),
            const SizedBox(height: 16),
            Text(errorMessage, style: const TextStyle(color: Colors.grey)),
            const SizedBox(height: 24),
            ElevatedButton(
              onPressed: onRefresh,
              child: const Text('重试'),
            ),
          ],
        ),
      );
    }

    if (conversations.isEmpty) {
      return Center(
        child: Text(
          emptyMessage,
          style: const TextStyle(color: Colors.grey),
        ),
      );
    }

    return RefreshIndicator(
      onRefresh: () async {
        onRefresh();
      },
      child: ListView.builder(
        itemCount: conversations.length,
        itemBuilder: (context, index) {
          final conversation = conversations[index];
          return _buildConversationItem(conversation);
        },
      ),
    );
  }

  Widget _buildConversationItem(Conversation conversation) {
    // 检查图片URL并处理
    String? imageUrl = conversation.productImage;
    if (imageUrl != null && imageUrl.isNotEmpty) {
      if (imageUrl.startsWith('http://localhost:8080')) {
        imageUrl = imageUrl.replaceFirst(
            'http://localhost:8080', 'http://192.168.200.30:8080');
      } else if (imageUrl.startsWith('/files/')) {
        imageUrl = 'http://192.168.200.30:8080$imageUrl';
      }
    }

    // 获取当前用户ID，判断是买家还是卖家会话
    final currentUserId = HttpUtil().getCurrentUserId();
    final bool isCurrentUserBuyer = currentUserId == conversation.userId;
    
    return ListTile(
      leading: imageUrl != null && imageUrl.isNotEmpty
          ? ClipRRect(
              borderRadius: BorderRadius.circular(8),
              child: Image.network(
                imageUrl,
                width: 50,
                height: 50,
                fit: BoxFit.cover,
                errorBuilder: (context, error, stackTrace) {
                  return Container(
                    width: 50,
                    height: 50,
                    color: Colors.grey[300],
                    child: const Icon(Icons.image, color: Colors.white),
                  );
                },
              ),
            )
          : CircleAvatar(
              child: Text(
                isCurrentUserBuyer
                    ? conversation.sellerUsername?.substring(0, 1) ?? 'S'
                    : conversation.username?.substring(0, 1) ?? 'U',
              ),
            ),
      title: Row(
        children: [
          Expanded(
            child: Text(
              isCurrentUserBuyer
                  ? conversation.sellerUsername ?? '卖家'
                  : conversation.username ?? '买家',
              style: const TextStyle(fontWeight: FontWeight.bold),
            ),
          ),
          Text(
            conversation.lastMessageTime ?? '',
            style: TextStyle(
              fontSize: 12,
              color: Colors.grey[600],
            ),
          ),
        ],
      ),
      subtitle: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const SizedBox(height: 4),
          Text(
            conversation.productTitle ?? '未知商品',
            style: TextStyle(
              fontSize: 12,
              color: Colors.grey[600],
            ),
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
          const SizedBox(height: 4),
          Text(
            conversation.lastMessageContent ?? '',
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
        ],
      ),
      trailing: (conversation.unreadCount ?? 0) > 0
          ? Container(
              padding: const EdgeInsets.all(6),
              decoration: BoxDecoration(
                color: Colors.red,
                borderRadius: BorderRadius.circular(10),
              ),
              child: Text(
                '${conversation.unreadCount}',
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 12,
                ),
              ),
            )
          : null,
      onTap: () => _navigateToMessagePage(conversation),
    );
  }
} 