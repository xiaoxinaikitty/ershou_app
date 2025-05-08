class Feedback {
  final int? feedbackId;
  final int? userId;
  final String? username;
  final int? feedbackType;
  final String? feedbackTypeDesc;
  final String feedbackTitle;
  final String feedbackContent;
  final String? contactInfo;
  final String? images;
  final int? status;
  final String? statusDesc;
  final int? priorityLevel;
  final String? priorityLevelDesc;
  final String? adminReply;
  final String? replyTime;
  final String? createdTime;

  Feedback({
    this.feedbackId,
    this.userId,
    this.username,
    this.feedbackType,
    this.feedbackTypeDesc,
    required this.feedbackTitle,
    required this.feedbackContent,
    this.contactInfo,
    this.images,
    this.status,
    this.statusDesc,
    this.priorityLevel,
    this.priorityLevelDesc,
    this.adminReply,
    this.replyTime,
    this.createdTime,
  });

  factory Feedback.fromJson(Map<String, dynamic> json) {
    return Feedback(
      feedbackId: json['feedbackId'],
      userId: json['userId'],
      username: json['username'],
      feedbackType: json['feedbackType'],
      feedbackTypeDesc: json['feedbackTypeDesc'],
      feedbackTitle: json['feedbackTitle'] ?? '',
      feedbackContent: json['feedbackContent'] ?? '',
      contactInfo: json['contactInfo'],
      images: json['images'],
      status: json['status'],
      statusDesc: json['statusDesc'],
      priorityLevel: json['priorityLevel'],
      priorityLevelDesc: json['priorityLevelDesc'],
      adminReply: json['adminReply'],
      replyTime: json['replyTime'],
      createdTime: json['createdTime'],
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'feedbackId': feedbackId,
      'userId': userId,
      'username': username,
      'feedbackType': feedbackType,
      'feedbackTypeDesc': feedbackTypeDesc,
      'feedbackTitle': feedbackTitle,
      'feedbackContent': feedbackContent,
      'contactInfo': contactInfo,
      'images': images,
      'status': status,
      'statusDesc': statusDesc,
      'priorityLevel': priorityLevel,
      'priorityLevelDesc': priorityLevelDesc,
      'adminReply': adminReply,
      'replyTime': replyTime,
      'createdTime': createdTime,
    };
  }
}
