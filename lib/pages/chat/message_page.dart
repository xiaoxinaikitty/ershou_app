import 'package:flutter/material.dart';
import 'dart:developer' as developer;
import '../../network/api.dart';
import '../../network/http_util.dart';
import '../../models/user_message.dart';

class MessagePage extends StatefulWidget {
  final int productId;
  final int receiverId;
  final String? productTitle;
  final String? receiverName;
  final String? productImage;

  const MessagePage({
    Key? key,
    required this.productId,
    required this.receiverId,
    this.productTitle,
    this.receiverName,
    this.productImage,
  }) : super(key: key);

  @override
  State<MessagePage> createState() => _MessagePageState();
}

class _MessagePageState extends State<MessagePage> {
  final TextEditingController _messageController = TextEditingController();
  final ScrollController _scrollController = ScrollController();
  final List<UserMessage> _messages = [];
  bool _isLoading = true;
  String _errorMessage = '';
  int? _conversationId;

  @override
  void initState() {
    super.initState();
    _fetchMessages();
  }

  @override
  void dispose() {
    _messageController.dispose();
    _scrollController.dispose();
    super.dispose();
  }

  // 获取消息列表
  Future<void> _fetchMessages() async {
    setState(() {
      _isLoading = true;
      _errorMessage = '';
    });

    try {
      // 先尝试根据商品ID获取消息
      final response = await HttpUtil()
          .get('${Api.userMessageListByProduct}${widget.productId}');

      if (response.isSuccess && response.data != null) {
        final List<dynamic> messagesData = response.data as List<dynamic>;

        // 清空现有消息
        setState(() {
          _messages.clear();

          // 获取当前用户ID（从HttpUtil或用户状态管理中获取）
          final currentUserId = HttpUtil().getCurrentUserId();

          // 转换消息数据
          for (var messageData in messagesData) {
            // 添加当前用户ID用于判断消息发送者
            if (currentUserId != null) {
              messageData['currentUserId'] = currentUserId;
            }

            _messages.add(UserMessage.fromJson(messageData));

            // 如果消息中包含conversationId，记录它
            if (_conversationId == null &&
                messageData['conversationId'] != null) {
              _conversationId = messageData['conversationId'] as int;
            }
          }

          _isLoading = false;
        });

        // 滚动到底部
        WidgetsBinding.instance.addPostFrameCallback((_) {
          if (_scrollController.hasClients) {
            _scrollController.animateTo(
              _scrollController.position.maxScrollExtent,
              duration: const Duration(milliseconds: 300),
              curve: Curves.easeOut,
            );
          }
        });
      } else {
        setState(() {
          _isLoading = false;
          _errorMessage = response.message ?? '获取消息列表失败';
        });
      }
    } catch (e) {
      developer.log('获取消息异常: $e', name: 'MessagePage');
      setState(() {
        _isLoading = false;
        _errorMessage = '网络错误: $e';
      });
    }
  }

  // 发送消息
  Future<void> _sendMessage() async {
    final message = _messageController.text.trim();
    if (message.isEmpty) return;

    _messageController.clear();

    try {
      final response = await HttpUtil().post(
        Api.userMessageSend,
        data: {
          'productId': widget.productId,
          'receiverId': widget.receiverId,
          'content': message,
        },
      );

      if (response.isSuccess && response.data != null) {
        // 发送成功，将新消息添加到列表
        final messageData = response.data;

        // 获取当前用户ID
        final currentUserId = HttpUtil().getCurrentUserId();
        if (currentUserId != null) {
          messageData['currentUserId'] = currentUserId;
        }

        // 设置为当前用户发送的消息
        messageData['isSender'] = true;

        final newMessage = UserMessage.fromJson(messageData);
        setState(() {
          _messages.add(newMessage);
        });

        // 如果是第一条消息，可能获取到了会话ID
        if (_conversationId == null &&
            response.data['conversationId'] != null) {
          _conversationId = response.data['conversationId'] as int;
        }

        // 滚动到底部
        WidgetsBinding.instance.addPostFrameCallback((_) {
          if (_scrollController.hasClients) {
            _scrollController.animateTo(
              _scrollController.position.maxScrollExtent,
              duration: const Duration(milliseconds: 300),
              curve: Curves.easeOut,
            );
          }
        });
      } else {
        if (!mounted) return;
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(response.message ?? '发送消息失败')),
        );
      }
    } catch (e) {
      developer.log('发送消息异常: $e', name: 'MessagePage');
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('发送消息失败: $e')),
      );
    }
  }

  // 将消息标记为已读
  Future<void> _markMessagesAsRead() async {
    // 如果有会话ID，标记整个会话为已读
    if (_conversationId != null) {
      try {
        await HttpUtil().post('${Api.markConversationRead}$_conversationId');
        // 不需要UI反馈，静默处理
      } catch (e) {
        developer.log('标记会话已读异常: $e', name: 'MessagePage');
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final title = widget.receiverName ?? '客服';
    final subtitle = widget.productTitle ?? '商品详情';

    return Scaffold(
      appBar: AppBar(
        title: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(title, style: const TextStyle(fontSize: 16)),
            Text(subtitle,
                style: const TextStyle(fontSize: 12, color: Colors.white70),
                overflow: TextOverflow.ellipsis),
          ],
        ),
        elevation: 0,
      ),
      body: Column(
        children: [
          // 商品信息卡片（可选）
          if (widget.productImage != null && widget.productImage!.isNotEmpty)
            Container(
              padding: const EdgeInsets.all(8.0),
              color: Colors.grey[100],
              child: Row(
                children: [
                  ClipRRect(
                    borderRadius: BorderRadius.circular(4),
                    child: Image.network(
                      widget.productImage!,
                      width: 40,
                      height: 40,
                      fit: BoxFit.cover,
                      errorBuilder: (context, error, stackTrace) {
                        return Container(
                          width: 40,
                          height: 40,
                          color: Colors.grey[300],
                          child: const Icon(Icons.image, color: Colors.white),
                        );
                      },
                    ),
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      subtitle,
                      style: const TextStyle(fontSize: 12),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                ],
              ),
            ),

          // 消息列表
          Expanded(
            child: _isLoading
                ? const Center(child: CircularProgressIndicator())
                : _errorMessage.isNotEmpty
                    ? Center(
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Text(_errorMessage,
                                style: const TextStyle(color: Colors.grey)),
                            const SizedBox(height: 16),
                            ElevatedButton(
                              onPressed: _fetchMessages,
                              child: const Text('重新加载'),
                            ),
                          ],
                        ),
                      )
                    : _messages.isEmpty
                        ? const Center(child: Text('暂无消息，发送消息开始聊天'))
                        : ListView.builder(
                            controller: _scrollController,
                            padding: const EdgeInsets.all(10),
                            itemCount: _messages.length,
                            itemBuilder: (context, index) {
                              final message = _messages[index];
                              final isCurrentUser = message.isSender;

                              return Padding(
                                padding: const EdgeInsets.only(bottom: 8.0),
                                child: Row(
                                  mainAxisAlignment: isCurrentUser
                                      ? MainAxisAlignment.end
                                      : MainAxisAlignment.start,
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    if (!isCurrentUser) ...[
                                      CircleAvatar(
                                        radius: 16,
                                        backgroundImage: message.senderAvatar !=
                                                    null &&
                                                message.senderAvatar!.isNotEmpty
                                            ? NetworkImage(
                                                message.senderAvatar!)
                                            : null,
                                        child: message.senderAvatar == null ||
                                                message.senderAvatar!.isEmpty
                                            ? Text(message.senderUsername?[0] ??
                                                '?')
                                            : null,
                                      ),
                                      const SizedBox(width: 8),
                                    ],
                                    Flexible(
                                      child: Container(
                                        padding: const EdgeInsets.symmetric(
                                            horizontal: 12, vertical: 8),
                                        decoration: BoxDecoration(
                                          color: isCurrentUser
                                              ? Colors.blue[100]
                                              : Colors.grey[200],
                                          borderRadius:
                                              BorderRadius.circular(16),
                                        ),
                                        child: Column(
                                          crossAxisAlignment:
                                              CrossAxisAlignment.start,
                                          children: [
                                            Text(
                                              message.content,
                                              style:
                                                  const TextStyle(fontSize: 14),
                                            ),
                                            const SizedBox(height: 4),
                                            Text(
                                              message.createdTime ?? '',
                                              style: TextStyle(
                                                fontSize: 10,
                                                color: Colors.grey[600],
                                              ),
                                            ),
                                          ],
                                        ),
                                      ),
                                    ),
                                    if (isCurrentUser) ...[
                                      const SizedBox(width: 8),
                                      CircleAvatar(
                                        radius: 16,
                                        backgroundImage: message.senderAvatar !=
                                                    null &&
                                                message.senderAvatar!.isNotEmpty
                                            ? NetworkImage(
                                                message.senderAvatar!)
                                            : null,
                                        child: message.senderAvatar == null ||
                                                message.senderAvatar!.isEmpty
                                            ? Text(message.senderUsername?[0] ??
                                                '?')
                                            : null,
                                      ),
                                    ],
                                  ],
                                ),
                              );
                            },
                          ),
          ),

          // 底部输入框
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
            decoration: BoxDecoration(
              color: Colors.white,
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.05),
                  blurRadius: 4,
                  offset: const Offset(0, -1),
                ),
              ],
            ),
            child: Row(
              children: [
                Expanded(
                  child: TextField(
                    controller: _messageController,
                    decoration: const InputDecoration(
                      hintText: '输入消息...',
                      contentPadding:
                          EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.all(Radius.circular(20)),
                        borderSide: BorderSide.none,
                      ),
                      filled: true,
                      fillColor: Color(0xFFF0F0F0),
                    ),
                    textInputAction: TextInputAction.send,
                    onSubmitted: (_) => _sendMessage(),
                  ),
                ),
                IconButton(
                  icon: const Icon(Icons.send),
                  color: Theme.of(context).primaryColor,
                  onPressed: _sendMessage,
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
