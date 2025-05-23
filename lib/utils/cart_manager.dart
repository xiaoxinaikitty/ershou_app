import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';
import 'dart:developer' as developer;
import 'image_url_util.dart'; // 引入图片URL处理工具类

class CartManager {
  static const String _cartKey = 'user_cart_items';

  // 获取购物车中的所有商品
  static Future<List<Map<String, dynamic>>> getCartItems() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final String? cartJson = prefs.getString(_cartKey);

      if (cartJson == null || cartJson.isEmpty) {
        return [];
      }

      final List<dynamic> cartList = json.decode(cartJson);
      final List<Map<String, dynamic>> cartItems = List<Map<String, dynamic>>.from(cartList);
      
      // 更新所有商品的图片URL
      for (var item in cartItems) {
        if (item.containsKey('mainImageUrl')) {
          item['mainImageUrl'] = ImageUrlUtil.processImageUrl(item['mainImageUrl'] as String?);
        }
      }
      
      return cartItems;
    } catch (e) {
      developer.log('获取购物车数据异常: $e', name: 'CartManager');
      return [];
    }
  }

  // 将商品添加到购物车
  static Future<bool> addToCart(Map<String, dynamic> product) async {
    try {
      final List<Map<String, dynamic>> cartItems = await getCartItems();

      // 查找购物车中是否已存在该商品
      int existingIndex = cartItems
          .indexWhere((item) => item['productId'] == product['productId']);

      if (existingIndex >= 0) {
        // 如果已存在，增加数量
        cartItems[existingIndex]['quantity'] =
            (cartItems[existingIndex]['quantity'] as int) + 1;
      } else {
        // 如果不存在，添加到购物车，默认数量为1
        String mainImageUrl = ImageUrlUtil.processImageUrl(product['mainImageUrl'] as String?);
        developer.log('处理后的图片URL: $mainImageUrl', name: 'CartManager');

        final Map<String, dynamic> cartItem = {
          'productId': product['productId'],
          'title': product['title'],
          'price': product['price'],
          'mainImageUrl': mainImageUrl,
          'quantity': 1,
          'sellerId': product['sellerId'] ?? product['userId'] ?? 1,
        };
        cartItems.add(cartItem);
        developer.log('添加商品到购物车: ${product['productId']}, 图片URL: $mainImageUrl, 卖家ID: ${cartItem['sellerId']}',
            name: 'CartManager');
      }

      // 保存更新后的购物车
      final result = await _saveCartItems(cartItems);
      return result;
    } catch (e) {
      developer.log('添加商品到购物车异常: $e', name: 'CartManager');
      return false;
    }
  }

  // 更新购物车中商品的数量
  static Future<bool> updateQuantity(int productId, int newQuantity) async {
    try {
      final List<Map<String, dynamic>> cartItems = await getCartItems();

      int index =
          cartItems.indexWhere((item) => item['productId'] == productId);
      if (index >= 0) {
        if (newQuantity <= 0) {
          // 如果数量小于等于0，从购物车移除
          cartItems.removeAt(index);
        } else {
          // 更新数量
          cartItems[index]['quantity'] = newQuantity;
        }
        return await _saveCartItems(cartItems);
      }
      return false;
    } catch (e) {
      developer.log('更新购物车商品数量异常: $e', name: 'CartManager');
      return false;
    }
  }

  // 更新购物车中商品的图片URL
  static Future<bool> updateImageUrl(int productId, String imageUrl) async {
    try {
      final List<Map<String, dynamic>> cartItems = await getCartItems();
      int index =
          cartItems.indexWhere((item) => item['productId'] == productId);

      if (index >= 0) {
        // 使用图片处理工具类处理URL
        imageUrl = ImageUrlUtil.processImageUrl(imageUrl);
        
        cartItems[index]['mainImageUrl'] = imageUrl;
        developer.log('更新商品图片URL: $productId, $imageUrl', name: 'CartManager');
        return await _saveCartItems(cartItems);
      }
      return false;
    } catch (e) {
      developer.log('更新商品图片URL异常: $e', name: 'CartManager');
      return false;
    }
  }

  // 从购物车中移除商品
  static Future<bool> removeFromCart(int productId) async {
    try {
      final List<Map<String, dynamic>> cartItems = await getCartItems();

      int index =
          cartItems.indexWhere((item) => item['productId'] == productId);
      if (index >= 0) {
        cartItems.removeAt(index);
        return await _saveCartItems(cartItems);
      }
      return false;
    } catch (e) {
      developer.log('从购物车移除商品异常: $e', name: 'CartManager');
      return false;
    }
  }

  // 清空购物车
  static Future<bool> clearCart() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      return await prefs.remove(_cartKey);
    } catch (e) {
      developer.log('清空购物车异常: $e', name: 'CartManager');
      return false;
    }
  }

  // 保存购物车数据到SharedPreferences
  static Future<bool> _saveCartItems(
      List<Map<String, dynamic>> cartItems) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final String cartJson = json.encode(cartItems);
      return await prefs.setString(_cartKey, cartJson);
    } catch (e) {
      developer.log('保存购物车数据异常: $e', name: 'CartManager');
      return false;
    }
  }

  // 获取购物车中商品的总数量
  static Future<int> getCartItemCount() async {
    try {
      final List<Map<String, dynamic>> cartItems = await getCartItems();
      int count = 0;
      for (var item in cartItems) {
        count += (item['quantity'] as int? ?? 0);
      }
      developer.log('购物车商品总数: $count', name: 'CartManager');
      return count;
    } catch (e) {
      developer.log('获取购物车商品总数异常: $e', name: 'CartManager');
      return 0; // 出错时返回0
    }
  }

  // 计算购物车中商品的总价
  static Future<double> getCartTotalPrice() async {
    final List<Map<String, dynamic>> cartItems = await getCartItems();
    double total = 0;
    for (var item in cartItems) {
      total += (item['price'] as double) * (item['quantity'] as int);
    }
    return total;
  }
}
