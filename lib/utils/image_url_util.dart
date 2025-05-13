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
    
    // 记录处理前的URL
    developer.log('处理前的图片URL: $url', name: 'ImageUrlUtil');
    
    // 处理相对路径
    if (url.startsWith('/')) {
      final processed = '$currentBaseUrl$url';
      developer.log('处理后的图片URL(相对路径): $processed', name: 'ImageUrlUtil');
      return processed;
    }
    
    // 从currentBaseUrl中提取当前使用的host部分
    String currentHost = currentBaseUrl;
    if (currentBaseUrl.startsWith('http://')) {
      currentHost = currentBaseUrl.substring(7); // 去掉http://
    } else if (currentBaseUrl.startsWith('https://')) {
      currentHost = currentBaseUrl.substring(8); // 去掉https://
    }
    
    // 通用的替换逻辑 - 替换任何IP或域名
    // 正则表达式匹配形如 http://192.168.0.103:8080 的协议+域名或IP+端口
    final RegExp regExp = RegExp(r'(https?://)([^/]+)');
    if (regExp.hasMatch(url)) {
      final match = regExp.firstMatch(url);
      if (match != null) {
        final String oldProtocolAndHost = url.substring(match.start, match.end);
        developer.log('找到需要替换的URL部分: $oldProtocolAndHost', name: 'ImageUrlUtil');
        
        // 替换为当前baseUrl
        String processed = url.replaceFirst(oldProtocolAndHost, currentBaseUrl);
        
        // 避免处理后的URL有多余的斜杠
        processed = processed.replaceAll('///', '//').replaceAll('//', '//');
        
        developer.log('处理后的图片URL(替换域名): $processed', name: 'ImageUrlUtil');
        return processed;
      }
    }
    
    // 如果以上替换都不适用，直接返回原URL
    developer.log('未能处理图片URL，返回原始值: $url', name: 'ImageUrlUtil');
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