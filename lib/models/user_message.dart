class UserMessage {
  final int? messageId;
  final int? productId;
  final String? productTitle;
  final String? productImage;
  final int? senderId;
  final String? senderUsername;
  final String? senderAvatar;
  final int? receiverId;
  final String? receiverUsername;
  final String? receiverAvatar;
  final String content;
  final String? imageUrl;
  final int? isRead;
  final String? createdTime;
  final bool isSender; // 是否为当前用户发送的消息

  UserMessage({
    this.messageId,
    this.productId,
    this.productTitle,
    this.productImage,
    this.senderId,
    this.senderUsername,
    this.senderAvatar,
    this.receiverId,
    this.receiverUsername,
    this.receiverAvatar,
    required this.content,
    this.imageUrl,
    this.isRead,
    this.createdTime,
    required this.isSender,
  });

  factory UserMessage.fromJson(Map<String, dynamic> json) {
    // 从本地存储或接口获取当前用户ID，这里简化处理
    final currentUserId =
        int.tryParse(json['currentUserId']?.toString() ?? '') ?? 0;
    final senderId = int.tryParse(json['senderId']?.toString() ?? '') ?? 0;

    return UserMessage(
      messageId: int.tryParse(json['messageId']?.toString() ?? ''),
      productId: int.tryParse(json['productId']?.toString() ?? ''),
      productTitle: json['productTitle'],
      productImage: json['productImage'],
      senderId: senderId,
      senderUsername: json['senderUsername'],
      senderAvatar: json['senderAvatar'],
      receiverId: int.tryParse(json['receiverId']?.toString() ?? ''),
      receiverUsername: json['receiverUsername'],
      receiverAvatar: json['receiverAvatar'],
      content: json['content'] ?? '',
      imageUrl: json['imageUrl'],
      isRead: int.tryParse(json['isRead']?.toString() ?? ''),
      createdTime: json['createdTime'],
      // 判断是否为当前用户发送的消息
      isSender: currentUserId > 0
          ? currentUserId == senderId
          : json['isSender'] ?? false,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'messageId': messageId,
      'productId': productId,
      'productTitle': productTitle,
      'productImage': productImage,
      'senderId': senderId,
      'senderUsername': senderUsername,
      'senderAvatar': senderAvatar,
      'receiverId': receiverId,
      'receiverUsername': receiverUsername,
      'receiverAvatar': receiverAvatar,
      'content': content,
      'imageUrl': imageUrl,
      'isRead': isRead,
      'createdTime': createdTime,
      'isSender': isSender,
    };
  }
}
