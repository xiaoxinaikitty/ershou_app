/// API接口管理类
class Api {
  // 基础URL
  static const String baseUrl = 'http://192.168.0.103:8080';

  // 用户模块
  static const String userRegister = '/user/register'; // 用户注册
  static const String userLogin = '/user/login'; // 用户登录
  static const String adminLogin = '/user/admin'; // 管理员登录
  static const String userAddress = '/user/address'; // 添加用户地址
  static const String userAddressByUser =
      '/user/address/addByUser'; // 根据用户ID添加地址
  static const String userAddressList = '/user/address/list'; // 获取用户地址列表
  static const String userAddressDelete =
      '/user/address/delete/'; // 删除收货地址，需附加addressId
  static const String userInfo = '/user/info'; // 获取/修改用户信息
  static const String userPassword = '/user/password'; // 修改用户密码
  static const String userRole = '/user/role'; // 获取用户角色信息
  static const String userProducts = '/user/products'; // 获取用户发布的商品列表

  // 发货地址模块
  static const String shippingAddressAdd = '/shipping/address/add'; // 添加发货地址
  static const String shippingAddressList =
      '/shipping/address/list'; // 获取发货地址列表
  static const String shippingAddressDelete =
      '/shipping/address/delete/'; // 删除发货地址，需附加addressId

  // 文件上传
  static const String fileUpload = '/file/upload'; // 文件上传

  // 商品模块
  static const String productAdd = '/product/add'; // 添加商品
  static const String productList = '/product/list'; // 分页查询商品列表
  static const String productDetail = '/product/detail/'; // 获取商品详情，需附加productId
  static const String productUpdate = '/product/update'; // 更新商品信息
  static const String productDelete = '/product/delete/'; // 删除商品，需附加productId
  static const String productLocationAdd = '/product/location/add'; // 添加商品位置信息
  static const String myProductList = '/product/my-list'; // 用户发布商品列表
  static const String productSearch = '/product/search'; // 搜索商品

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
  static const String imageList =
      '/product/image/list/'; // 获取商品图片列表，需附加productId

  // 商品举报模块
  static const String reportAdd = '/product/report/add'; // 举报商品
  static const String reportList =
      '/product/report/list/'; // 获取商品举报列表，需附加productId

  // 订单模块
  static const String orderCreate = '/order/create'; // 创建订单
  static const String orderList = '/order/list'; // 获取订单列表
  static const String orderCancel = '/order/cancel/'; // 取消订单，需附加orderId
  static const String orderPay = '/order/pay/'; // 支付订单，需附加orderId
  static const String orderDetail = '/order/detail/'; // 获取订单详情，需附加orderId
  static const String orderNotifyShipment = '/order/notify-shipment'; // 通知发货
  static const String orderConfirmReceipt = '/order/confirm-receipt'; // 确认收货

  // 订单消息模块
  static const String messageSend = '/message/send'; // 发送订单消息

  // 用户消息模块 (联系客服)
  static const String userMessageSend = '/user/message/send'; // 发送用户消息
  static const String userMessageListByProduct =
      '/user/message/list/product/'; // 获取商品相关消息列表，需附加productId
  static const String userMessageListByConversation =
      '/user/message/list/conversation/'; // 获取会话消息列表，需附加conversationId
  static const String userConversations =
      '/user/message/conversations/user'; // 获取用户的会话列表
  static const String sellerConversations =
      '/user/message/conversations/seller'; // 获取卖家的会话列表
  static const String markMessageRead =
      '/user/message/read/'; // 标记消息为已读，需附加messageId
  static const String markConversationRead =
      '/user/message/read/conversation/'; // 标记会话为已读，需附加conversationId
  static const String closeConversation =
      '/user/message/close/'; // 关闭会话，需附加conversationId

  // 钱包模块
  static const String walletCreate = '/api/wallet/create'; // 创建钱包账户
  static const String walletInfo = '/api/wallet/info'; // 查询钱包账户信息
  static const String walletUpdate = '/api/wallet/update'; // 更新钱包账户余额
  static const String walletFreeze = '/api/wallet/freeze'; // 冻结/解冻钱包账户余额
  static const String walletTransactionCreate =
      '/api/wallet/transaction/create'; // 创建钱包交易记录
  static const String walletTransactionList =
      '/api/wallet/transaction/list'; // 查询钱包交易记录列表

  // 支付密码模块
  static const String paymentPasswordSet =
      '/api/wallet/payment-password/set'; // 设置支付密码
  static const String paymentPasswordVerify =
      '/api/wallet/payment-password/verify'; // 验证支付密码
  static const String paymentPasswordSendResetCode =
      '/api/wallet/payment-password/send-reset-code'; // 发送重置支付密码验证码
  static const String paymentPasswordReset =
      '/api/wallet/payment-password/reset'; // 重置支付密码

  // 用户反馈模块
  static const String feedbackAdd = '/feedback/submit'; // 添加用户反馈
  static const String feedbackList = '/feedback/list'; // 获取用户反馈列表
  static const String feedbackDetail =
      '/feedback/detail/'; // 获取反馈详情，需附加feedbackId
  static const String feedbackListByUser = '/feedback/my-list'; // 获取当前用户的反馈列表
}
