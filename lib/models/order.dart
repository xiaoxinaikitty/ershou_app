class Order {
  final int orderId;
  final String orderNo;
  final int userId;
  final int sellerId;
  final int productId;
  final String productTitle;
  final double orderAmount;
  final double paymentAmount;
  final int orderStatus; // 0=待付款，1=已付款，2=已发货，3=已收货，4=已取消
  final int paymentType;
  final int? deliveryType;
  final double? deliveryFee;
  final String? remark;
  final String createdTime;
  final String? payTime; // 支付时间
  final String? productImage; // 商品图片
  final String? alipayNo; // 支付宝交易号
  final Address? address;

  Order({
    required this.orderId,
    required this.orderNo,
    required this.userId,
    required this.sellerId,
    required this.productId,
    required this.productTitle,
    required this.orderAmount,
    required this.paymentAmount,
    required this.orderStatus,
    required this.paymentType,
    this.deliveryType,
    this.deliveryFee,
    this.remark,
    required this.createdTime,
    this.payTime,
    this.productImage,
    this.alipayNo,
    this.address,
  });

  factory Order.fromJson(Map<String, dynamic> json) {
    // 安全地解析数值，避免类型转换错误
    int parseIntSafely(dynamic value, {int defaultValue = 0}) {
      if (value == null) return defaultValue;
      if (value is int) return value;
      if (value is String) {
        return int.tryParse(value) ?? defaultValue;
      }
      return defaultValue;
    }

    double parseDoubleSafely(dynamic value, {double defaultValue = 0.0}) {
      if (value == null) return defaultValue;
      if (value is double) return value;
      if (value is int) return value.toDouble();
      if (value is String) {
        return double.tryParse(value) ?? defaultValue;
      }
      return defaultValue;
    }

    String parseStringSafely(dynamic value, {String defaultValue = ''}) {
      if (value == null) return defaultValue;
      return value.toString();
    }

    return Order(
      orderId: parseIntSafely(json['orderId']),
      orderNo: parseStringSafely(json['orderNo']),
      userId: parseIntSafely(json['userId']),
      sellerId: parseIntSafely(json['sellerId']),
      productId: parseIntSafely(json['productId']),
      productTitle: parseStringSafely(json['productTitle']),
      orderAmount: parseDoubleSafely(json['orderAmount']),
      paymentAmount: parseDoubleSafely(json['paymentAmount']),
      orderStatus: parseIntSafely(json['orderStatus']),
      paymentType: parseIntSafely(json['paymentType']),
      deliveryType: json['deliveryType'] != null
          ? parseIntSafely(json['deliveryType'])
          : null,
      deliveryFee: json['deliveryFee'] != null
          ? parseDoubleSafely(json['deliveryFee'])
          : null,
      remark: json['remark']?.toString(),
      createdTime: parseStringSafely(json['createdTime'], defaultValue: '未知时间'),
      payTime: json['payTime']?.toString(),
      productImage: json['productImage']?.toString() ??
          json['productImageUrl']?.toString(),
      alipayNo:
          json['alipayNo']?.toString() ?? json['paymentTradeNo']?.toString(),
      address: json['address'] != null
          ? Address.fromJson(json['address'] as Map<String, dynamic>)
          : null,
    );
  }
}

class Address {
  final String receiverName;
  final String receiverPhone;
  final String province;
  final String city;
  final String district;
  final String detailAddress;

  Address({
    required this.receiverName,
    required this.receiverPhone,
    required this.province,
    required this.city,
    required this.district,
    required this.detailAddress,
  });

  factory Address.fromJson(Map<String, dynamic> json) {
    return Address(
      receiverName: json['receiverName'] ?? '',
      receiverPhone: json['receiverPhone'] ?? '',
      province: json['province'] ?? '',
      city: json['city'] ?? '',
      district: json['district'] ?? '',
      detailAddress: json['detailAddress'] ?? '',
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'receiverName': receiverName,
      'receiverPhone': receiverPhone,
      'province': province,
      'city': city,
      'district': district,
      'detailAddress': detailAddress,
    };
  }
}
