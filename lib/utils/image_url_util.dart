import '../network/api.dart';
import 'dart:developer' as developer;

/// 图片URL处理工具类
/// 用于统一处理图片URL，自动替换为正确的baseUrl
class ImageUrlUtil {
  /// 处理图片URL
  /// 如果是相对路径，会自动添加baseUrl
  /// 如果是绝对路径且包含旧的localhost或固定IP，会替换为当前的baseUrl
  static String processImageUrl(String? url) {
    if (url == null || url.isEmpty) {
      return '';
    }

    // 获取当前baseUrl
    final currentBaseUrl = Api.baseUrl;
    
    // 处理相对路径
    if (url.startsWith('/')) {
      return '$currentBaseUrl$url';
    }
    
    // 处理包含localhost的URL
    if (url.contains('http://localhost:8080')) {
      return url.replaceFirst('http://localhost:8080', currentBaseUrl);
    }
    
    // 处理包含固定IP的URL (例如192.168.200.30)
    if (url.contains('192.168.200.30:8080')) {
      return url.replaceFirst('http://192.168.200.30:8080', currentBaseUrl);
    }
    
    // 其他包含固定IP的可能性
    final regExp = RegExp(r'http://192\.168\.\d+\.\d+:8080');
    if (regExp.hasMatch(url)) {
      return regExp.stringMatch(url) != null 
          ? url.replaceFirst(regExp, currentBaseUrl) 
          : url;
    }
    
    // 如果没有需要处理的情况，返回原URL
    return url;
  }

  /// 批量处理图片URL列表
  static List<String> processImageUrls(List<String> urls) {
    return urls.map((url) => processImageUrl(url)).toList();
  }
  
  /// 处理Map中的图片URL字段
  /// 用于处理商品数据中的图片URL
  static Map<String, dynamic> processProductImage(Map<String, dynamic> product) {
    if (product.containsKey('mainImageUrl')) {
      product['mainImageUrl'] = processImageUrl(product['mainImageUrl'] as String?);
    }
    
    // 处理可能存在的图片列表
    if (product.containsKey('images') && product['images'] is List) {
      final List<dynamic> images = product['images'] as List<dynamic>;
      for (var i = 0; i < images.length; i++) {
        if (images[i] is Map && images[i].containsKey('url')) {
          images[i]['url'] = processImageUrl(images[i]['url'] as String?);
        }
      }
    }
    
    return product;
  }
  
  /// 批量处理商品列表中的图片URL
  static List<Map<String, dynamic>> processProductImages(List<Map<String, dynamic>> products) {
    return products.map((product) => processProductImage(product)).toList();
  }
} 