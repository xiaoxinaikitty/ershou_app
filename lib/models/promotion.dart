/// 营销活动模型类
class Promotion {
  final int promotionId;
  final String title;
  final String? description;
  final int promotionType;
  final String promotionTypeDesc;
  final String startTime;
  final String endTime;
  final int status;
  final String statusDesc;
  final int sortOrder;
  final String? urlLink;
  final List<PromotionImage> images;

  Promotion({
    required this.promotionId,
    required this.title,
    this.description,
    required this.promotionType,
    required this.promotionTypeDesc,
    required this.startTime,
    required this.endTime,
    required this.status,
    required this.statusDesc,
    required this.sortOrder,
    this.urlLink,
    required this.images,
  });

  factory Promotion.fromJson(Map<String, dynamic> json) {
    List<PromotionImage> imagesList = [];
    if (json['images'] != null) {
      final List<dynamic> imagesJson = json['images'] as List<dynamic>;
      imagesList = imagesJson
          .map((imageJson) =>
              PromotionImage.fromJson(imageJson as Map<String, dynamic>))
          .toList();
    }

    return Promotion(
      promotionId: json['promotionId'] as int? ?? -1,
      title: json['title'] as String? ?? '',
      description: json['description'] as String?,
      promotionType: json['promotionType'] as int? ?? 1,
      promotionTypeDesc: json['promotionTypeDesc'] as String? ?? '',
      startTime: json['startTime'] as String? ?? '',
      endTime: json['endTime'] as String? ?? '',
      status: json['status'] as int? ?? 0,
      statusDesc: json['statusDesc'] as String? ?? '',
      sortOrder: json['sortOrder'] as int? ?? 0,
      urlLink: json['urlLink'] as String?,
      images: imagesList,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'promotionId': promotionId,
      'title': title,
      'description': description,
      'promotionType': promotionType,
      'promotionTypeDesc': promotionTypeDesc,
      'startTime': startTime,
      'endTime': endTime,
      'status': status,
      'statusDesc': statusDesc,
      'sortOrder': sortOrder,
      'urlLink': urlLink,
      'images': images.map((image) => image.toJson()).toList(),
    };
  }
}

/// 营销活动图片模型类
class PromotionImage {
  final int? imageId;
  final int? promotionId;
  final String imageUrl;
  final int imageType;
  final String? imageTypeDesc;
  final int? sortOrder;

  PromotionImage({
    this.imageId,
    this.promotionId,
    required this.imageUrl,
    required this.imageType,
    this.imageTypeDesc,
    this.sortOrder,
  });

  factory PromotionImage.fromJson(Map<String, dynamic> json) {
    return PromotionImage(
      imageId: json['imageId'] as int?,
      promotionId: json['promotionId'] as int?,
      imageUrl: json['imageUrl'] as String? ?? '',
      imageType: json['imageType'] as int? ?? 1,
      imageTypeDesc: json['imageTypeDesc'] as String?,
      sortOrder: json['sortOrder'] as int?,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'imageId': imageId,
      'promotionId': promotionId,
      'imageUrl': imageUrl,
      'imageType': imageType,
      'imageTypeDesc': imageTypeDesc,
      'sortOrder': sortOrder,
    };
  }
}
