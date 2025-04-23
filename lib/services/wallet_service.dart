import 'dart:developer' as developer;
import '../network/api.dart';
import '../network/http_util.dart';
import '../models/wallet.dart';
import '../network/api_response.dart';

/// 钱包服务类
class WalletService {
  final HttpUtil _httpUtil = HttpUtil();

  /// 查询钱包账户信息
  Future<WalletAccount?> getWalletInfo(int userId) async {
    try {
      final response = await _httpUtil.get(
        Api.walletInfo,
        params: {'userId': userId},
        fromJson: (json) => WalletAccount.fromJson(json),
      );

      if (response.isSuccess && response.data != null) {
        return response.data;
      } else {
        developer.log('获取钱包信息失败: ${response.message}', name: 'WalletService');
        return null;
      }
    } catch (e) {
      developer.log('获取钱包信息异常: $e', name: 'WalletService');
      return null;
    }
  }

  /// 创建钱包账户
  Future<WalletAccount?> createWallet(int userId) async {
    try {
      final response = await _httpUtil.post(
        Api.walletCreate,
        data: {'userId': userId},
        fromJson: (json) => WalletAccount.fromJson(json),
      );

      if (response.isSuccess && response.data != null) {
        return response.data;
      } else {
        developer.log('创建钱包账户失败: ${response.message}', name: 'WalletService');
        return null;
      }
    } catch (e) {
      developer.log('创建钱包账户异常: $e', name: 'WalletService');
      return null;
    }
  }

  /// 获取钱包交易记录
  Future<TransactionPageResponse?> getTransactionList({
    required int accountId,
    String? startTime,
    String? endTime,
    int? transactionType,
    int pageNum = 1,
    int pageSize = 10,
  }) async {
    try {
      Map<String, dynamic> params = {
        'accountId': accountId,
        'pageNum': pageNum,
        'pageSize': pageSize,
      };

      if (startTime != null) params['startTime'] = startTime;
      if (endTime != null) params['endTime'] = endTime;
      if (transactionType != null) params['transactionType'] = transactionType;

      final response = await _httpUtil.get(
        Api.walletTransactionList,
        params: params,
        fromJson: (json) => TransactionPageResponse.fromJson(json),
      );

      if (response.isSuccess && response.data != null) {
        return response.data;
      } else {
        developer.log('获取交易记录失败: ${response.message}', name: 'WalletService');
        return null;
      }
    } catch (e) {
      developer.log('获取交易记录异常: $e', name: 'WalletService');
      return null;
    }
  }

  /// 创建钱包交易记录
  Future<WalletTransaction?> createTransaction({
    required int accountId,
    required int transactionType,
    required double transactionAmount,
    required double beforeBalance,
    required double afterBalance,
    String? remark,
  }) async {
    try {
      final Map<String, dynamic> data = {
        'accountId': accountId,
        'transactionType': transactionType,
        'transactionAmount': transactionAmount,
        'beforeBalance': beforeBalance,
        'afterBalance': afterBalance,
      };

      if (remark != null) data['remark'] = remark;

      final response = await _httpUtil.post(
        Api.walletTransactionCreate,
        data: data,
        fromJson: (json) => WalletTransaction.fromJson(json),
      );

      if (response.isSuccess && response.data != null) {
        return response.data;
      } else {
        developer.log('创建交易记录失败: ${response.message}', name: 'WalletService');
        return null;
      }
    } catch (e) {
      developer.log('创建交易记录异常: $e', name: 'WalletService');
      return null;
    }
  }

  /// 更新钱包余额
  Future<WalletAccount?> updateWallet({
    required int accountId,
    double? balance,
    double? frozenBalance,
  }) async {
    try {
      final Map<String, dynamic> data = {'accountId': accountId};

      if (balance != null) data['balance'] = balance;
      if (frozenBalance != null) data['frozenBalance'] = frozenBalance;

      final response = await _httpUtil.put(
        Api.walletUpdate,
        data: data,
        fromJson: (json) => WalletAccount.fromJson(json),
      );

      if (response.isSuccess && response.data != null) {
        return response.data;
      } else {
        developer.log('更新钱包余额失败: ${response.message}', name: 'WalletService');
        return null;
      }
    } catch (e) {
      developer.log('更新钱包余额异常: $e', name: 'WalletService');
      return null;
    }
  }

  /// 冻结或解冻钱包余额
  Future<WalletAccount?> freezeWallet({
    required int accountId,
    required int operationType, // 1-冻结，2-解冻
    required double amount,
  }) async {
    try {
      final response = await _httpUtil.put(
        Api.walletFreeze,
        data: {
          'accountId': accountId,
          'operationType': operationType,
          'amount': amount,
        },
        fromJson: (json) => WalletAccount.fromJson(json),
      );

      if (response.isSuccess && response.data != null) {
        return response.data;
      } else {
        developer.log('冻结/解冻钱包余额失败: ${response.message}',
            name: 'WalletService');
        return null;
      }
    } catch (e) {
      developer.log('冻结/解冻钱包余额异常: $e', name: 'WalletService');
      return null;
    }
  }

  /// 设置或修改支付密码
  Future<ApiResponse> setPaymentPassword({
    required int userId,
    required String paymentPassword,
    String? oldPaymentPassword,
  }) async {
    try {
      final Map<String, dynamic> data = {
        'userId': userId,
        'paymentPassword': paymentPassword,
      };

      if (oldPaymentPassword != null) {
        data['oldPaymentPassword'] = oldPaymentPassword;
      }

      final response = await _httpUtil.post(
        Api.paymentPasswordSet,
        data: data,
      );

      return response;
    } catch (e) {
      developer.log('设置支付密码异常: $e', name: 'WalletService');
      return ApiResponse(code: -1, message: '网络异常，请稍后再试');
    }
  }

  /// 验证支付密码
  Future<ApiResponse> verifyPaymentPassword({
    required int userId,
    required String paymentPassword,
  }) async {
    try {
      final response = await _httpUtil.post(
        Api.paymentPasswordVerify,
        data: {
          'userId': userId,
          'paymentPassword': paymentPassword,
        },
      );

      return response;
    } catch (e) {
      developer.log('验证支付密码异常: $e', name: 'WalletService');
      return ApiResponse(code: -1, message: '网络异常，请稍后再试');
    }
  }

  /// 发送重置支付密码验证码
  Future<ApiResponse> sendResetPaymentPasswordCode(int userId) async {
    try {
      final response = await _httpUtil.get(
        Api.paymentPasswordSendResetCode,
        params: {'userId': userId},
      );

      return response;
    } catch (e) {
      developer.log('发送验证码异常: $e', name: 'WalletService');
      return ApiResponse(code: -1, message: '网络异常，请稍后再试');
    }
  }

  /// 通过验证码重置支付密码
  Future<ApiResponse> resetPaymentPassword({
    required int userId,
    required String newPaymentPassword,
    required String verificationCode,
  }) async {
    try {
      final response = await _httpUtil.post(
        Api.paymentPasswordReset,
        data: {
          'userId': userId,
          'newPaymentPassword': newPaymentPassword,
          'verificationCode': verificationCode,
        },
      );

      return response;
    } catch (e) {
      developer.log('重置支付密码异常: $e', name: 'WalletService');
      return ApiResponse(code: -1, message: '网络异常，请稍后再试');
    }
  }
}
