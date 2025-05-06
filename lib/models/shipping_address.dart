class ShippingAddress {
  final int addressId;
  final int userId;
  final String shipperName;
  final String region;
  final String detail;
  final String contactPhone;
  final bool isDefault;
  final String createTime;

  ShippingAddress({
    required this.addressId,
    required this.userId,
    required this.shipperName,
    required this.region,
    required this.detail,
    required this.contactPhone,
    required this.isDefault,
    required this.createTime,
  });

  factory ShippingAddress.fromJson(Map<String, dynamic> json) {
    return ShippingAddress(
      addressId: json['addressId'] as int,
      userId: json['userId'] as int,
      shipperName: json['shipperName'] as String,
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
      'shipperName': shipperName,
      'region': region,
      'detail': detail,
      'contactPhone': contactPhone,
      'isDefault': isDefault,
      'createTime': createTime,
    };
  }
}
