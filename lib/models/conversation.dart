class Conversation {
  final int? conversationId;
  final int? productId;
  final String? productTitle;
  final String? productImage;
  final int? userId;
  final String? username;
  final String? userAvatar;
  final int? sellerId;
  final String? sellerUsername;
  final String? sellerAvatar;
  final String? lastMessageContent;
  final String? lastMessageTime;
  final int? unreadCount;
  final int? status; // 会话状态(0已关闭 1活跃)
  final String? createdTime;

  Conversation({
    this.conversationId,
    this.productId,
    this.productTitle,
    this.productImage,
    this.userId,
    this.username,
    this.userAvatar,
    this.sellerId,
    this.sellerUsername,
    this.sellerAvatar,
    this.lastMessageContent,
    this.lastMessageTime,
    this.unreadCount,
    this.status,
    this.createdTime,
  });

  factory Conversation.fromJson(Map<String, dynamic> json) {
    return Conversation(
      conversationId: int.tryParse(json['conversationId']?.toString() ?? ''),
      productId: int.tryParse(json['productId']?.toString() ?? ''),
      productTitle: json['productTitle'],
      productImage: json['productImage'],
      userId: int.tryParse(json['userId']?.toString() ?? ''),
      username: json['username'],
      userAvatar: json['userAvatar'],
      sellerId: int.tryParse(json['sellerId']?.toString() ?? ''),
      sellerUsername: json['sellerUsername'],
      sellerAvatar: json['sellerAvatar'],
      lastMessageContent: json['lastMessageContent'],
      lastMessageTime: json['lastMessageTime'],
      unreadCount: int.tryParse(json['unreadCount']?.toString() ?? '0'),
      status: int.tryParse(json['status']?.toString() ?? '1'),
      createdTime: json['createdTime'],
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'conversationId': conversationId,
      'productId': productId,
      'productTitle': productTitle,
      'productImage': productImage,
      'userId': userId,
      'username': username,
      'userAvatar': userAvatar,
      'sellerId': sellerId,
      'sellerUsername': sellerUsername,
      'sellerAvatar': sellerAvatar,
      'lastMessageContent': lastMessageContent,
      'lastMessageTime': lastMessageTime,
      'unreadCount': unreadCount,
      'status': status,
      'createdTime': createdTime,
    };
  }
} 