import 'dart:async';
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'image_url_util.dart';
import 'cart_manager.dart';
import 'dart:developer' as developer;

/// 图片检查工具类
/// 用于检测和修复应用中的图片URL
class ImageChecker {
  // 上次检查的时间戳
  static const String _lastCheckKey = 'last_image_check_timestamp';
  
  /// 检查应用中的图片，确保所有图片URL使用正确的baseUrl
  static Future<void> checkAndFixImages() async {
    try {
      // 检查距离上次检查是否已经过了一小时
      final prefs = await SharedPreferences.getInstance();
      final int lastCheck = prefs.getInt(_lastCheckKey) ?? 0;
      final int now = DateTime.now().millisecondsSinceEpoch;
      
      // 如果距离上次检查不足1小时，则跳过检查
      if (now - lastCheck < 3600000) { // 3600000毫秒 = 1小时
        developer.log('距离上次图片检查不足1小时，跳过检查', name: 'ImageChecker');
        return;
      }
      
      developer.log('开始检查图片URL', name: 'ImageChecker');
      
      // 检查并修复购物车中的图片URL
      await _checkAndFixCartImages();
      
      // 更新最后检查时间
      await prefs.setInt(_lastCheckKey, now);
      
      developer.log('图片URL检查完成', name: 'ImageChecker');
    } catch (e) {
      developer.log('图片检查异常: $e', name: 'ImageChecker');
    }
  }
  
  /// 检查并修复购物车中的图片URL
  static Future<void> _checkAndFixCartImages() async {
    try {
      final cartItems = await CartManager.getCartItems();
      var hasChanges = false;
      
      for (var item in cartItems) {
        if (item.containsKey('mainImageUrl') && item['mainImageUrl'] != null) {
          final String oldUrl = item['mainImageUrl'] as String;
          final String newUrl = ImageUrlUtil.processImageUrl(oldUrl);
          
          // 如果URL需要更新
          if (oldUrl != newUrl) {
            developer.log('修复购物车商品图片: ${item['productId']}, 从 $oldUrl 到 $newUrl', 
                name: 'ImageChecker');
            await CartManager.updateImageUrl(item['productId'] as int, newUrl);
            hasChanges = true;
          }
        }
      }
      
      if (hasChanges) {
        developer.log('购物车图片已更新', name: 'ImageChecker');
      } else {
        developer.log('购物车中没有需要修复的图片', name: 'ImageChecker');
      }
    } catch (e) {
      developer.log('检查购物车图片异常: $e', name: 'ImageChecker');
    }
  }
  
  /// 初始化并在应用启动时进行检查
  static Future<void> initialize() async {
    // 延迟执行检查，确保应用已完全启动
    Timer(const Duration(seconds: 2), () {
      checkAndFixImages();
    });
  }
} 