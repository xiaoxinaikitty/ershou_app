import 'package:flutter/material.dart';
import 'dart:developer' as developer;
import '../models/wallet.dart';
import '../services/wallet_service.dart';
import '../config/theme.dart';
import '../network/http_util.dart';
import 'payment_password_page.dart'; // 导入支付密码页面

class WalletPage extends StatefulWidget {
  const WalletPage({Key? key}) : super(key: key);

  @override
  State<WalletPage> createState() => _WalletPageState();
}

class _WalletPageState extends State<WalletPage>
    with SingleTickerProviderStateMixin {
  final WalletService _walletService = WalletService();

  // 钱包信息
  WalletAccount? _walletAccount;
  bool _isLoading = true;
  bool _hasError = false;
  String _errorMessage = '';

  // 交易记录
  List<WalletTransaction> _transactions = [];
  bool _isLoadingTransactions = false;
  bool _hasTransactionError = false;
  String _transactionErrorMessage = '';
  int _currentPage = 1;
  final int _pageSize = 10;
  bool _hasMoreTransactions = true;

  // 用于实现顶部栏渐变效果
  late ScrollController _scrollController;
  double _scrollOffset = 0;

  // Tab控制器
  late TabController _tabController;

  @override
  void initState() {
    super.initState();
    _scrollController = ScrollController()
      ..addListener(() {
        setState(() {
          _scrollOffset = _scrollController.offset;
        });
      });

    _tabController = TabController(length: 2, vsync: this);
    _fetchWalletInfo();
  }

  @override
  void dispose() {
    _scrollController.dispose();
    _tabController.dispose();
    super.dispose();
  }

  // 获取钱包信息
  Future<void> _fetchWalletInfo() async {
    setState(() {
      _isLoading = true;
      _hasError = false;
      _errorMessage = '';
    });

    try {
      // 获取当前用户信息
      final userInfo = await _getUserInfo();
      if (userInfo == null || userInfo['userId'] == null) {
        setState(() {
          _isLoading = false;
          _hasError = true;
          _errorMessage = '无法获取用户信息';
        });
        return;
      }

      final userId = userInfo['userId'];

      // 获取钱包信息
      final wallet = await _walletService.getWalletInfo(userId);

      if (wallet != null) {
        setState(() {
          _walletAccount = wallet;
          _isLoading = false;
        });

        // 加载交易记录
        _fetchTransactions();
      } else {
        // 钱包不存在，尝试创建钱包
        final newWallet = await _walletService.createWallet(userId);
        if (newWallet != null) {
          setState(() {
            _walletAccount = newWallet;
            _isLoading = false;
          });
        } else {
          setState(() {
            _isLoading = false;
            _hasError = true;
            _errorMessage = '无法创建钱包';
          });
        }
      }
    } catch (e) {
      developer.log('获取钱包信息异常: $e', name: 'WalletPage');
      setState(() {
        _isLoading = false;
        _hasError = true;
        _errorMessage = '网络错误，请稍后再试';
      });
    }
  }

  // 获取用户信息
  Future<Map<String, dynamic>?> _getUserInfo() async {
    try {
      final response = await HttpUtil().get('/user/info');
      if (response.isSuccess && response.data != null) {
        return response.data as Map<String, dynamic>;
      }
      return null;
    } catch (e) {
      developer.log('获取用户信息异常: $e', name: 'WalletPage');
      return null;
    }
  }

  // 获取交易记录
  Future<void> _fetchTransactions({bool isRefresh = false}) async {
    if (_walletAccount == null || _walletAccount!.accountId == null) {
      return;
    }

    if (isRefresh) {
      setState(() {
        _currentPage = 1;
        _hasMoreTransactions = true;
      });
    }

    if (!_hasMoreTransactions && !isRefresh) {
      return;
    }

    setState(() {
      _isLoadingTransactions = true;
      _hasTransactionError = false;
    });

    try {
      final transactions = await _walletService.getTransactionList(
        accountId: _walletAccount!.accountId!,
        pageNum: _currentPage,
        pageSize: _pageSize,
      );

      if (transactions != null) {
        setState(() {
          if (isRefresh) {
            _transactions = transactions.list;
          } else {
            _transactions.addAll(transactions.list);
          }
          _hasMoreTransactions = transactions.hasNext;
          _currentPage++;
          _isLoadingTransactions = false;
        });
      } else {
        setState(() {
          _isLoadingTransactions = false;
          _hasTransactionError = true;
          _transactionErrorMessage = '获取交易记录失败';
        });
      }
    } catch (e) {
      developer.log('获取交易记录异常: $e', name: 'WalletPage');
      setState(() {
        _isLoadingTransactions = false;
        _hasTransactionError = true;
        _transactionErrorMessage = '网络错误，请稍后再试';
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    // 构建页面
    return Scaffold(
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : _hasError
              ? _buildErrorView()
              : _buildWalletView(),
    );
  }

  // 错误视图
  Widget _buildErrorView() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const Icon(
            Icons.error_outline,
            size: 60,
            color: Colors.grey,
          ),
          const SizedBox(height: 16),
          Text(
            _errorMessage,
            textAlign: TextAlign.center,
            style: const TextStyle(color: Colors.grey),
          ),
          const SizedBox(height: 24),
          ElevatedButton(
            onPressed: _fetchWalletInfo,
            child: const Text('重新加载'),
          ),
        ],
      ),
    );
  }

  // 钱包视图
  Widget _buildWalletView() {
    return NestedScrollView(
      controller: _scrollController,
      headerSliverBuilder: (context, innerBoxIsScrolled) {
        return [
          SliverAppBar(
            expandedHeight: 200,
            floating: false,
            pinned: true,
            backgroundColor: AppTheme.primaryColor,
            flexibleSpace: FlexibleSpaceBar(
              title: Text(
                _scrollOffset > 120 ? '我的钱包' : '',
                style: const TextStyle(
                  color: Colors.white,
                  fontWeight: FontWeight.bold,
                ),
              ),
              background: _buildWalletHeader(),
            ),
            bottom: TabBar(
              controller: _tabController,
              indicatorColor: Colors.white,
              tabs: const [
                Tab(text: '交易记录'),
                Tab(text: '钱包管理'),
              ],
            ),
          ),
        ];
      },
      body: TabBarView(
        controller: _tabController,
        children: [
          _buildTransactionsTab(),
          _buildWalletManagementTab(),
        ],
      ),
    );
  }

  // 钱包头部信息
  Widget _buildWalletHeader() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            AppTheme.primaryColor,
            AppTheme.primaryColor.withOpacity(0.8),
          ],
        ),
      ),
      child: SafeArea(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              '账户余额',
              style: TextStyle(
                color: Colors.white70,
                fontSize: 14,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              '¥ ${_walletAccount?.balance.toStringAsFixed(2) ?? '0.00'}',
              style: const TextStyle(
                color: Colors.white,
                fontSize: 32,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 16),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      '冻结金额',
                      style: TextStyle(
                        color: Colors.white70,
                        fontSize: 12,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      '¥ ${_walletAccount?.frozenBalance.toStringAsFixed(2) ?? '0.00'}',
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ],
                ),
                Row(
                  children: [
                    _buildActionButton('充值', Icons.add),
                    const SizedBox(width: 16),
                    _buildActionButton('提现', Icons.arrow_upward),
                  ],
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  // 快捷操作按钮
  Widget _buildActionButton(String text, IconData icon) {
    return InkWell(
      onTap: () {
        // 处理点击事件
        if (text == '充值') {
          _showRechargeDialog();
        } else if (text == '提现') {
          _showWithdrawDialog();
        }
      },
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        decoration: BoxDecoration(
          color: Colors.white.withOpacity(0.2),
          borderRadius: BorderRadius.circular(20),
        ),
        child: Row(
          children: [
            Icon(icon, color: Colors.white, size: 16),
            const SizedBox(width: 4),
            Text(
              text,
              style: const TextStyle(
                color: Colors.white,
                fontSize: 14,
              ),
            ),
          ],
        ),
      ),
    );
  }

  // 交易记录选项卡
  Widget _buildTransactionsTab() {
    if (_isLoadingTransactions && _transactions.isEmpty) {
      return const Center(child: CircularProgressIndicator());
    }

    if (_hasTransactionError && _transactions.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(
              Icons.error_outline,
              size: 60,
              color: Colors.grey,
            ),
            const SizedBox(height: 16),
            Text(
              _transactionErrorMessage,
              textAlign: TextAlign.center,
              style: const TextStyle(color: Colors.grey),
            ),
            const SizedBox(height: 24),
            ElevatedButton(
              onPressed: () => _fetchTransactions(isRefresh: true),
              child: const Text('重新加载'),
            ),
          ],
        ),
      );
    }

    if (_transactions.isEmpty) {
      return const Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.account_balance_wallet,
              size: 60,
              color: Colors.grey,
            ),
            SizedBox(height: 16),
            Text(
              '暂无交易记录',
              style: TextStyle(
                color: Colors.grey,
                fontSize: 16,
              ),
            ),
          ],
        ),
      );
    }

    return RefreshIndicator(
      onRefresh: () => _fetchTransactions(isRefresh: true),
      child: ListView.builder(
        padding: const EdgeInsets.all(16),
        itemCount: _transactions.length + (_hasMoreTransactions ? 1 : 0),
        itemBuilder: (context, index) {
          if (index == _transactions.length) {
            return _buildLoadMoreIndicator();
          }

          final transaction = _transactions[index];
          return _buildTransactionItem(transaction);
        },
      ),
    );
  }

  // 加载更多指示器
  Widget _buildLoadMoreIndicator() {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 16),
      alignment: Alignment.center,
      child: _isLoadingTransactions
          ? const CircularProgressIndicator()
          : TextButton(
              onPressed: () => _fetchTransactions(),
              child: const Text('加载更多'),
            ),
    );
  }

  // 交易记录项
  Widget _buildTransactionItem(WalletTransaction transaction) {
    // 根据交易类型设置不同的颜色和图标
    IconData iconData;
    Color iconColor;

    switch (transaction.transactionType) {
      case 1: // 充值
        iconData = Icons.add_circle;
        iconColor = Colors.green;
        break;
      case 2: // 消费
        iconData = Icons.remove_circle;
        iconColor = Colors.red;
        break;
      case 3: // 退款
        iconData = Icons.refresh;
        iconColor = Colors.orange;
        break;
      default: // 其他
        iconData = Icons.swap_horiz;
        iconColor = Colors.blue;
    }

    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      child: ListTile(
        leading: CircleAvatar(
          backgroundColor: iconColor.withOpacity(0.1),
          child: Icon(iconData, color: iconColor),
        ),
        title: Text(
          transaction.remark ?? transaction.transactionTypeText,
          style: const TextStyle(
            fontWeight: FontWeight.bold,
          ),
        ),
        subtitle: Text(
          transaction.transactionTime ?? '未知时间',
          style: TextStyle(
            color: Colors.grey[600],
            fontSize: 12,
          ),
        ),
        trailing: Text(
          transaction.amountText,
          style: TextStyle(
            color: transaction.transactionType == 1 ||
                    transaction.transactionType == 3
                ? Colors.green
                : Colors.red,
            fontWeight: FontWeight.bold,
            fontSize: 16,
          ),
        ),
      ),
    );
  }

  // 钱包管理选项卡
  Widget _buildWalletManagementTab() {
    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        // 账户信息卡片
        Card(
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  '账户信息',
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 16),
                _buildInfoItem('账户ID', '${_walletAccount?.accountId ?? '未知'}'),
                _buildInfoItem('用户ID', '${_walletAccount?.userId ?? '未知'}'),
                _buildInfoItem('最后更新', _walletAccount?.lastUpdateTime ?? '未知'),
              ],
            ),
          ),
        ),
        const SizedBox(height: 16),

        // 钱包功能卡片
        Card(
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  '钱包功能',
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 16),
                _buildFunctionItem('充值', Icons.add_circle_outline, () {
                  _showRechargeDialog();
                }),
                const Divider(),
                _buildFunctionItem('提现', Icons.remove_circle_outline, () {
                  _showWithdrawDialog();
                }),
                const Divider(),
                _buildFunctionItem('交易明细', Icons.receipt_long, () {
                  _tabController.animateTo(0); // 切换到交易记录选项卡
                }),
              ],
            ),
          ),
        ),
        const SizedBox(height: 16),

        // 安全与设置卡片
        Card(
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  '安全与设置',
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 16),
                _buildFunctionItem('设置支付密码', Icons.lock_outline, () {
                  // 处理设置支付密码
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (context) => const PaymentPasswordPage(),
                    ),
                  );
                }),
                const Divider(),
                _buildFunctionItem('银行卡管理', Icons.credit_card, () {
                  // 处理银行卡管理
                }),
                const Divider(),
                _buildFunctionItem('账户安全', Icons.security, () {
                  // 处理账户安全
                }),
              ],
            ),
          ),
        ),
      ],
    );
  }

  // 账户信息项
  Widget _buildInfoItem(String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            label,
            style: TextStyle(
              color: Colors.grey[600],
            ),
          ),
          Text(
            value,
            style: const TextStyle(
              fontWeight: FontWeight.bold,
            ),
          ),
        ],
      ),
    );
  }

  // 功能项
  Widget _buildFunctionItem(String title, IconData icon, VoidCallback onTap) {
    return InkWell(
      onTap: onTap,
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 12),
        child: Row(
          children: [
            Icon(icon, color: AppTheme.primaryColor),
            const SizedBox(width: 16),
            Text(
              title,
              style: const TextStyle(
                fontSize: 16,
              ),
            ),
            const Spacer(),
            const Icon(Icons.chevron_right, color: Colors.grey),
          ],
        ),
      ),
    );
  }

  // 显示充值对话框
  void _showRechargeDialog() {
    final TextEditingController amountController = TextEditingController();

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('充值'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(
              controller: amountController,
              keyboardType: TextInputType.number,
              decoration: const InputDecoration(
                labelText: '充值金额',
                prefixText: '¥ ',
                border: OutlineInputBorder(),
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () {
              Navigator.of(context).pop();
            },
            child: const Text('取消'),
          ),
          ElevatedButton(
            onPressed: () {
              final amount = double.tryParse(amountController.text);
              if (amount != null && amount > 0) {
                _processRecharge(amount);
                Navigator.of(context).pop();
              }
            },
            child: const Text('确认'),
          ),
        ],
      ),
    );
  }

  // 处理充值
  Future<void> _processRecharge(double amount) async {
    if (_walletAccount == null || _walletAccount!.accountId == null) {
      return;
    }

    final double beforeBalance = _walletAccount!.balance;
    final double afterBalance = beforeBalance + amount;

    // 1. 更新钱包余额
    final updatedWallet = await _walletService.updateWallet(
      accountId: _walletAccount!.accountId!,
      balance: afterBalance,
    );

    if (updatedWallet != null) {
      // 2. 创建交易记录
      await _walletService.createTransaction(
        accountId: _walletAccount!.accountId!,
        transactionType: 1, // 充值
        transactionAmount: amount,
        beforeBalance: beforeBalance,
        afterBalance: afterBalance,
        remark: '用户充值',
      );

      // 3. 更新本地钱包信息
      setState(() {
        _walletAccount = updatedWallet;
      });

      // 4. 刷新交易记录
      _fetchTransactions(isRefresh: true);

      // 5. 显示成功提示
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('充值成功，金额：¥$amount')),
        );
      }
    } else {
      // 显示错误提示
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('充值失败，请稍后再试')),
        );
      }
    }
  }

  // 显示提现对话框
  void _showWithdrawDialog() {
    final TextEditingController amountController = TextEditingController();

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('提现'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(
              controller: amountController,
              keyboardType: TextInputType.number,
              decoration: const InputDecoration(
                labelText: '提现金额',
                prefixText: '¥ ',
                border: OutlineInputBorder(),
              ),
            ),
            const SizedBox(height: 8),
            Text(
              '可提现金额：¥${_walletAccount?.balance.toStringAsFixed(2) ?? '0.00'}',
              style: TextStyle(
                color: Colors.grey[600],
                fontSize: 12,
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () {
              Navigator.of(context).pop();
            },
            child: const Text('取消'),
          ),
          ElevatedButton(
            onPressed: () {
              final amount = double.tryParse(amountController.text);
              if (amount != null && amount > 0) {
                if (_walletAccount != null &&
                    amount <= _walletAccount!.balance) {
                  _processWithdraw(amount);
                  Navigator.of(context).pop();
                } else {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text('余额不足')),
                  );
                }
              }
            },
            child: const Text('确认'),
          ),
        ],
      ),
    );
  }

  // 处理提现
  Future<void> _processWithdraw(double amount) async {
    if (_walletAccount == null || _walletAccount!.accountId == null) {
      return;
    }

    final double beforeBalance = _walletAccount!.balance;
    final double afterBalance = beforeBalance - amount;

    // 1. 更新钱包余额
    final updatedWallet = await _walletService.updateWallet(
      accountId: _walletAccount!.accountId!,
      balance: afterBalance,
    );

    if (updatedWallet != null) {
      // 2. 创建交易记录
      await _walletService.createTransaction(
        accountId: _walletAccount!.accountId!,
        transactionType: 2, // 消费（提现）
        transactionAmount: amount,
        beforeBalance: beforeBalance,
        afterBalance: afterBalance,
        remark: '用户提现',
      );

      // 3. 更新本地钱包信息
      setState(() {
        _walletAccount = updatedWallet;
      });

      // 4. 刷新交易记录
      _fetchTransactions(isRefresh: true);

      // 5. 显示成功提示
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('提现申请成功，金额：¥$amount')),
        );
      }
    } else {
      // 显示错误提示
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('提现失败，请稍后再试')),
        );
      }
    }
  }
}
