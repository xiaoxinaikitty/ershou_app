// 钱包账户模型类
class WalletAccount {
  final int? accountId;
  final int? userId;
  final double balance;
  final double frozenBalance;
  final String? lastUpdateTime;

  WalletAccount({
    this.accountId,
    this.userId,
    required this.balance,
    required this.frozenBalance,
    this.lastUpdateTime,
  });

  factory WalletAccount.fromJson(Map<String, dynamic> json) {
    return WalletAccount(
      accountId: json['accountId'],
      userId: json['userId'],
      balance: json['balance']?.toDouble() ?? 0.0,
      frozenBalance: json['frozenBalance']?.toDouble() ?? 0.0,
      lastUpdateTime: json['lastUpdateTime'],
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'accountId': accountId,
      'userId': userId,
      'balance': balance,
      'frozenBalance': frozenBalance,
      'lastUpdateTime': lastUpdateTime,
    };
  }
}

// 钱包交易记录模型类
class WalletTransaction {
  final int? transactionId;
  final int? accountId;
  final int transactionType;
  final double transactionAmount;
  final double beforeBalance;
  final double afterBalance;
  final String? transactionTime;
  final String? remark;

  WalletTransaction({
    this.transactionId,
    this.accountId,
    required this.transactionType,
    required this.transactionAmount,
    required this.beforeBalance,
    required this.afterBalance,
    this.transactionTime,
    this.remark,
  });

  // 获取交易类型描述
  String get transactionTypeText {
    switch (transactionType) {
      case 1:
        return '充值';
      case 2:
        return '消费';
      case 3:
        return '退款';
      case 4:
        return '其他';
      default:
        return '未知';
    }
  }

  // 获取交易金额描述（带正负号）
  String get amountText {
    if (transactionType == 1 || transactionType == 3) {
      return '+$transactionAmount';
    } else if (transactionType == 2) {
      return '-$transactionAmount';
    } else {
      return '$transactionAmount';
    }
  }

  factory WalletTransaction.fromJson(Map<String, dynamic> json) {
    return WalletTransaction(
      transactionId: json['transactionId'],
      accountId: json['accountId'],
      transactionType: json['transactionType'] ?? 4,
      transactionAmount: json['transactionAmount']?.toDouble() ?? 0.0,
      beforeBalance: json['beforeBalance']?.toDouble() ?? 0.0,
      afterBalance: json['afterBalance']?.toDouble() ?? 0.0,
      transactionTime: json['transactionTime'],
      remark: json['remark'],
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'transactionId': transactionId,
      'accountId': accountId,
      'transactionType': transactionType,
      'transactionAmount': transactionAmount,
      'beforeBalance': beforeBalance,
      'afterBalance': afterBalance,
      'transactionTime': transactionTime,
      'remark': remark,
    };
  }
}

// 交易记录分页响应模型
class TransactionPageResponse {
  final int pageNum;
  final int pageSize;
  final int total;
  final int pages;
  final bool hasPrevious;
  final bool hasNext;
  final List<WalletTransaction> list;

  TransactionPageResponse({
    required this.pageNum,
    required this.pageSize,
    required this.total,
    required this.pages,
    required this.hasPrevious,
    required this.hasNext,
    required this.list,
  });

  factory TransactionPageResponse.fromJson(Map<String, dynamic> json) {
    List<WalletTransaction> transactionList = [];
    if (json['list'] != null) {
      transactionList = List<WalletTransaction>.from(
        (json['list'] as List).map(
          (item) => WalletTransaction.fromJson(item),
        ),
      );
    }

    return TransactionPageResponse(
      pageNum: json['pageNum'] ?? 1,
      pageSize: json['pageSize'] ?? 10,
      total: json['total'] ?? 0,
      pages: json['pages'] ?? 0,
      hasPrevious: json['hasPrevious'] ?? false,
      hasNext: json['hasNext'] ?? false,
      list: transactionList,
    );
  }
}
