/// API接口管理类
class Api {
  // 基础URL
  static const String baseUrl = 'http://192.168.200.30:8080';

  // 用户模块
  static const String userRegister = '/user/register'; // 用户注册
  static const String userLogin = '/user/login'; // 用户登录
  static const String adminLogin = '/user/admin'; // 管理员登录
  static const String userAddress = '/user/address'; // 添加用户地址
  static const String userInfo = '/user/info'; // 获取/修改用户信息
  static const String userPassword = '/user/password'; // 修改用户密码
  static const String userRole = '/user/role'; // 获取用户角色信息
  static const String userProducts = '/user/products'; // 获取用户发布的商品列表

  // 文件上传
  static const String fileUpload = '/file/upload'; // 文件上传

  // 商品模块
  static const String productAdd = '/product/add'; // 添加商品
  static const String productList = '/product/list'; // 分页查询商品列表
  static const String productDetail = '/product/detail/'; // 获取商品详情，需附加productId
  static const String productUpdate = '/product/update'; // 更新商品信息
  static const String productDelete = '/product/delete/'; // 删除商品，需附加productId

  // 商品收藏模块
  static const String favoriteAdd = '/product/favorite/add'; // 收藏商品
  static const String favoriteCancel =
      '/product/favorite/'; // 取消收藏，需附加productId
  static const String favoriteList = '/product/favorite/list'; // 获取收藏列表

  // 商品图片模块
  static const String imageAdd = '/product/image/add'; // 添加或批量添加商品图片
  static const String imageAddByUrl =
      '/product/image/add-by-url'; // 通过URL添加商品图片
  static const String imageDelete =
      '/product/image/'; // 删除商品图片，需附加productId/imageId

  // 商品举报模块
  static const String reportAdd = '/product/report/add'; // 举报商品
  static const String reportList =
      '/product/report/list/'; // 获取商品举报列表，需附加productId

  // 订单模块
  static const String orderCreate = '/order/create'; // 创建订单
  static const String orderList = '/order/list'; // 获取订单列表
  static const String orderCancel = '/order/cancel'; // 取消订单
  static const String orderPay = '/order/pay'; // 支付订单
  static const String orderNotifyShipment =
      '/order/notify-shipment'; // 通知收货（发货）
  static const String orderConfirmReceipt = '/order/confirm-receipt'; // 确认收货

  // 消息模块
  static const String messageSend = '/message/send'; // 发送消息
}
