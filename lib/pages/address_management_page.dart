import 'package:flutter/material.dart';
import 'dart:developer' as developer;
import '../config/theme.dart';
import '../network/api.dart';
import '../network/http_util.dart';

class AddressManagementPage extends StatefulWidget {
  const AddressManagementPage({Key? key}) : super(key: key);

  @override
  State<AddressManagementPage> createState() => _AddressManagementPageState();
}

class _AddressManagementPageState extends State<AddressManagementPage> {
  bool _isLoading = true;
  bool _isError = false;
  String _errorMessage = '';
  List<Map<String, dynamic>> _addresses = [];

  // 表单控制器
  final TextEditingController _consigneeController = TextEditingController();
  final TextEditingController _regionController = TextEditingController();
  final TextEditingController _detailController = TextEditingController();
  final TextEditingController _contactPhoneController = TextEditingController();

  @override
  void initState() {
    super.initState();
    _fetchAddresses();
  }

  @override
  void dispose() {
    _consigneeController.dispose();
    _regionController.dispose();
    _detailController.dispose();
    _contactPhoneController.dispose();
    super.dispose();
  }

  Future<void> _fetchAddresses() async {
    setState(() {
      _isLoading = true;
      _isError = false;
      _errorMessage = '';
    });

    try {
      // 使用真实的API获取地址列表
      final response = await HttpUtil().get(Api.userAddressList);

      if (response.isSuccess && response.data != null) {
        final List<dynamic> addressData = response.data;

        setState(() {
          _addresses =
              addressData.map((item) => item as Map<String, dynamic>).toList();
          _isLoading = false;
        });

        developer.log('获取地址列表成功: ${_addresses.length}',
            name: 'AddressManagementPage');
      } else {
        setState(() {
          _isLoading = false;
          _isError = true;
          _errorMessage = response.message ?? '获取地址列表失败';
        });

        developer.log('获取地址列表失败: ${response.message}',
            name: 'AddressManagementPage');
      }
    } catch (e) {
      setState(() {
        _isLoading = false;
        _isError = true;
        _errorMessage = '网络错误，请稍后再试';
      });

      developer.log('获取地址列表异常: $e', name: 'AddressManagementPage', error: e);
    }
  }

  // 添加新地址
  Future<void> _addAddress({
    required String consignee,
    required String region,
    required String detail,
    required String contactPhone,
    required bool isDefault,
  }) async {
    try {
      final response = await HttpUtil().post(
        Api.userAddressByUser,
        data: {
          'consignee': consignee,
          'region': region,
          'detail': detail,
          'contactPhone': contactPhone,
          'isDefault': isDefault,
        },
      );

      if (response.isSuccess) {
        // 添加成功后刷新列表
        await _fetchAddresses();
        // 清空表单
        _resetForm();

        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('地址添加成功'),
              backgroundColor: Colors.green,
            ),
          );
        }
        developer.log('地址添加成功', name: 'AddressManagementPage');
      } else {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(response.message ?? '地址添加失败'),
              backgroundColor: Colors.red,
            ),
          );
        }
        developer.log('地址添加失败: ${response.message}',
            name: 'AddressManagementPage');
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('地址添加失败: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
      developer.log('地址添加异常: $e', name: 'AddressManagementPage', error: e);
    }
  }

  // 重置表单
  void _resetForm() {
    _consigneeController.clear();
    _regionController.clear();
    _detailController.clear();
    _contactPhoneController.clear();
  }

  // 当前API不支持删除地址和设置默认地址的操作，保留方法以备后续实现
  Future<void> _deleteAddress(int addressId) async {
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('暂不支持删除地址功能'),
          backgroundColor: Colors.orange,
        ),
      );
    }
  }

  Future<void> _setDefaultAddress(int addressId) async {
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('暂不支持修改默认地址功能'),
          backgroundColor: Colors.orange,
        ),
      );
    }
  }

  // 显示添加地址对话框
  void _showAddAddressDialog() {
    bool isDefault = false;

    showDialog(
      context: context,
      builder: (context) {
        return StatefulBuilder(
          builder: (context, setState) {
            return AlertDialog(
              title: const Text('添加收货地址'),
              content: SingleChildScrollView(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    TextField(
                      controller: _consigneeController,
                      decoration: const InputDecoration(
                        labelText: '收货人',
                        hintText: '请输入收货人姓名',
                      ),
                    ),
                    const SizedBox(height: 12),
                    TextField(
                      controller: _regionController,
                      decoration: const InputDecoration(
                        labelText: '所在地区',
                        hintText: '请输入所在地区',
                      ),
                    ),
                    const SizedBox(height: 12),
                    TextField(
                      controller: _detailController,
                      decoration: const InputDecoration(
                        labelText: '详细地址',
                        hintText: '请输入详细地址',
                      ),
                      maxLines: 2,
                    ),
                    const SizedBox(height: 12),
                    TextField(
                      controller: _contactPhoneController,
                      decoration: const InputDecoration(
                        labelText: '联系电话',
                        hintText: '请输入联系电话',
                      ),
                      keyboardType: TextInputType.phone,
                    ),
                    const SizedBox(height: 16),
                    Row(
                      children: [
                        const Text('设为默认地址'),
                        const Spacer(),
                        Switch(
                          value: isDefault,
                          activeColor: AppTheme.primaryColor,
                          onChanged: (value) {
                            setState(() {
                              isDefault = value;
                            });
                          },
                        ),
                      ],
                    ),
                  ],
                ),
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
                    // 表单验证
                    if (_consigneeController.text.trim().isEmpty) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(content: Text('请输入收货人姓名')),
                      );
                      return;
                    }
                    if (_regionController.text.trim().isEmpty) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(content: Text('请输入所在地区')),
                      );
                      return;
                    }
                    if (_detailController.text.trim().isEmpty) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(content: Text('请输入详细地址')),
                      );
                      return;
                    }
                    if (_contactPhoneController.text.trim().isEmpty) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(content: Text('请输入联系电话')),
                      );
                      return;
                    }

                    // 电话号码格式验证
                    final phoneRegExp = RegExp(r'^1[3-9]\d{9}$');
                    if (!phoneRegExp
                        .hasMatch(_contactPhoneController.text.trim())) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(content: Text('请输入有效的手机号码')),
                      );
                      return;
                    }

                    // 关闭对话框
                    Navigator.of(context).pop();

                    // 添加地址
                    _addAddress(
                      consignee: _consigneeController.text.trim(),
                      region: _regionController.text.trim(),
                      detail: _detailController.text.trim(),
                      contactPhone: _contactPhoneController.text.trim(),
                      isDefault: isDefault,
                    );
                  },
                  child: const Text('确定'),
                ),
              ],
            );
          },
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title:
            const Text('地址管理', style: TextStyle(fontWeight: FontWeight.bold)),
        elevation: 0,
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : _isError
              ? _buildErrorView()
              : _addresses.isEmpty
                  ? _buildEmptyView()
                  : _buildAddressList(),
      floatingActionButton: FloatingActionButton(
        onPressed: _showAddAddressDialog,
        backgroundColor: AppTheme.primaryColor,
        child: const Icon(Icons.add),
      ),
    );
  }

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
            onPressed: _fetchAddresses,
            child: const Text('重新加载'),
          ),
        ],
      ),
    );
  }

  Widget _buildEmptyView() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const Icon(
            Icons.location_off,
            size: 60,
            color: Colors.grey,
          ),
          const SizedBox(height: 16),
          const Text(
            '暂无收货地址',
            style: TextStyle(color: Colors.grey),
          ),
          const SizedBox(height: 24),
          ElevatedButton(
            onPressed: _showAddAddressDialog,
            child: const Text('添加收货地址'),
          ),
        ],
      ),
    );
  }

  Widget _buildAddressList() {
    return ListView.builder(
      padding: const EdgeInsets.all(16),
      itemCount: _addresses.length,
      itemBuilder: (context, index) {
        final address = _addresses[index];
        final bool isDefault = address['isDefault'] ?? false;

        return Card(
          margin: const EdgeInsets.only(bottom: 16),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
            side: isDefault
                ? BorderSide(color: AppTheme.primaryColor, width: 2)
                : BorderSide.none,
          ),
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Text(
                      address['consignee'] ?? '',
                      style: const TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(width: 8),
                    Text(
                      address['contactPhone'] ?? '',
                      style: TextStyle(color: Colors.grey[600]),
                    ),
                    const Spacer(),
                    if (isDefault)
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 8,
                          vertical: 2,
                        ),
                        decoration: BoxDecoration(
                          color: AppTheme.primaryColor.withOpacity(0.1),
                          borderRadius: BorderRadius.circular(4),
                          border: Border.all(
                            color: AppTheme.primaryColor,
                            width: 1,
                          ),
                        ),
                        child: Text(
                          '默认',
                          style: TextStyle(
                            fontSize: 12,
                            color: AppTheme.primaryColor,
                          ),
                        ),
                      ),
                  ],
                ),
                const SizedBox(height: 8),
                Text(
                  '${address['region'] ?? ''} ${address['detail'] ?? ''}',
                  style: TextStyle(
                    color: Colors.grey[800],
                    height: 1.4,
                  ),
                ),
                const SizedBox(height: 16),
                Row(
                  mainAxisAlignment: MainAxisAlignment.end,
                  children: [
                    // 注意：目前API不支持这些操作，所以禁用
                    Text(
                      '暂不支持编辑和删除功能',
                      style: TextStyle(
                        fontSize: 12,
                        color: Colors.grey[600],
                        fontStyle: FontStyle.italic,
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        );
      },
    );
  }
}
