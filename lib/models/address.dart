class Address {
  final int addressId;
  final int userId;
  final String consignee;
  final String region;
  final String detail;
  final String contactPhone;
  final bool isDefault;
  final String createTime;

  Address({
    required this.addressId,
    required this.userId,
    required this.consignee,
    required this.region,
    required this.detail,
    required this.contactPhone,
    required this.isDefault,
    required this.createTime,
  });

  factory Address.fromJson(Map<String, dynamic> json) {
    return Address(
      addressId: json['addressId'] as int,
      userId: json['userId'] as int,
      consignee: json['consignee'] as String,
      region: json['region'] as String,
      detail: json['detail'] as String,
      contactPhone: json['contactPhone'] as String,
      isDefault: json['isDefault'] as bool,
      createTime: json['createTime'] as String,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'addressId': addressId,
      'userId': userId,
      'consignee': consignee,
      'region': region,
      'detail': detail,
      'contactPhone': contactPhone,
      'isDefault': isDefault,
      'createTime': createTime,
    };
  }
}
