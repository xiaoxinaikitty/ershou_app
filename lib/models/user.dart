class User {
  final int userId;
  final String username;
  final String? phone;
  final String? email;
  final String? avatar;
  final String? role;

  User({
    required this.userId,
    required this.username,
    this.phone,
    this.email,
    this.avatar,
    this.role,
  });

  factory User.fromJson(Map<String, dynamic> json) {
    return User(
      userId: json['userId'],
      username: json['username'],
      phone: json['phone'],
      email: json['email'],
      avatar: json['avatar'],
      role: json['role'],
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'userId': userId,
      'username': username,
      'phone': phone,
      'email': email,
      'avatar': avatar,
      'role': role,
    };
  }
}
