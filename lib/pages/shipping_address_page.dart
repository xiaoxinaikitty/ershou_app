import 'package:flutter/material.dart';
import 'dart:developer' as developer;
import '../config/theme.dart';
import '../network/api.dart';
import '../network/http_util.dart';
import '../models/shipping_address.dart';

class ShippingAddressPage extends StatefulWidget {
  const ShippingAddressPage({Key? key}) : super(key: key);

  @override
  State<ShippingAddressPage> createState() => _ShippingAddressPageState();
}

class _ShippingAddressPageState extends State<ShippingAddressPage> {
  bool _isLoading = true;
  bool _isError = false;
  String _errorMessage = '';
  List<ShippingAddress> _addresses = [];

  // 表单控制器
  final TextEditingController _shipperNameController = TextEditingController();
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
    _shipperNameController.dispose();
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
      // 使用API获取发货地址列表
      final response = await HttpUtil().get(Api.shippingAddressList);

      if (response.isSuccess && response.data != null) {
        final List<dynamic> addressData = response.data;

        setState(() {
          _addresses = addressData
              .map((item) =>
                  ShippingAddress.fromJson(item as Map<String, dynamic>))
              .toList();
          _isLoading = false;
        });

        developer.log('获取发货地址列表成功: ${_addresses.length}',
            name: 'ShippingAddressPage');
      } else {
        setState(() {
          _isLoading = false;
          _isError = true;
          _errorMessage = response.message ?? '获取发货地址列表失败';
        });

        developer.log('获取发货地址列表失败: ${response.message}',
            name: 'ShippingAddressPage');
      }
    } catch (e) {
      setState(() {
        _isLoading = false;
        _isError = true;
        _errorMessage = '网络错误，请稍后再试';
      });

      developer.log('获取发货地址列表异常: $e', name: 'ShippingAddressPage', error: e);
    }
  }

  // 添加新发货地址
  Future<void> _addAddress({
    required String shipperName,
    required String region,
    required String detail,
    required String contactPhone,
    required bool isDefault,
  }) async {
    try {
      final response = await HttpUtil().post(
        Api.shippingAddressAdd,
        data: {
          'shipperName': shipperName,
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
              content: Text('发货地址添加成功'),
              backgroundColor: Colors.green,
            ),
          );
        }
        developer.log('发货地址添加成功', name: 'ShippingAddressPage');
      } else {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(response.message ?? '发货地址添加失败'),
              backgroundColor: Colors.red,
            ),
          );
        }
        developer.log('发货地址添加失败: ${response.message}',
            name: 'ShippingAddressPage');
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('发货地址添加失败: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
      developer.log('发货地址添加异常: $e', name: 'ShippingAddressPage', error: e);
    }
  }

  // 重置表单
  void _resetForm() {
    _shipperNameController.clear();
    _regionController.clear();
    _detailController.clear();
    _contactPhoneController.clear();
  }

  // 删除发货地址
  Future<void> _deleteAddress(int addressId) async {
    try {
      final response =
          await HttpUtil().delete('${Api.shippingAddressDelete}$addressId');

      if (response.isSuccess) {
        // 删除成功后刷新列表
        await _fetchAddresses();

        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('发货地址删除成功'),
              backgroundColor: Colors.green,
            ),
          );
        }
        developer.log('发货地址删除成功', name: 'ShippingAddressPage');
      } else {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(response.message ?? '发货地址删除失败'),
              backgroundColor: Colors.red,
            ),
          );
        }
        developer.log('发货地址删除失败: ${response.message}',
            name: 'ShippingAddressPage');
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('发货地址删除失败: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
      developer.log('发货地址删除异常: $e', name: 'ShippingAddressPage', error: e);
    }
  }

  Future<void> _setDefaultAddress(int addressId) async {
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('暂不支持修改默认发货地址功能'),
          backgroundColor: Colors.orange,
        ),
      );
    }
  }

  // 显示添加发货地址对话框
  void _showAddAddressDialog() {
    bool isDefault = false;

    showDialog(
      context: context,
      builder: (context) {
        return StatefulBuilder(
          builder: (context, setState) {
            return AlertDialog(
              title: const Text('添加发货地址'),
              content: SingleChildScrollView(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    TextField(
                      controller: _shipperNameController,
                      decoration: const InputDecoration(
                        labelText: '发货人',
                        hintText: '请输入发货人姓名',
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
                    // 验证表单
                    final shipperName = _shipperNameController.text.trim();
                    final region = _regionController.text.trim();
                    final detail = _detailController.text.trim();
                    final contactPhone = _contactPhoneController.text.trim();

                    if (shipperName.isEmpty ||
                        region.isEmpty ||
                        detail.isEmpty ||
                        contactPhone.isEmpty) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(
                          content: Text('请填写完整信息'),
                          backgroundColor: Colors.red,
                        ),
                      );
                      return;
                    }

                    // 关闭对话框
                    Navigator.of(context).pop();

                    // 添加地址
                    _addAddress(
                      shipperName: shipperName,
                      region: region,
                      detail: detail,
                      contactPhone: contactPhone,
                      isDefault: isDefault,
                    );
                  },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppTheme.primaryColor,
                  ),
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
        title: const Text('发货地址管理'),
        centerTitle: true,
      ),
      body: _buildBody(),
      floatingActionButton: FloatingActionButton(
        onPressed: _showAddAddressDialog,
        backgroundColor: AppTheme.primaryColor,
        child: const Icon(Icons.add),
      ),
    );
  }

  Widget _buildBody() {
    if (_isLoading) {
      return const Center(
        child: CircularProgressIndicator(),
      );
    }

    if (_isError) {
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
              style: ElevatedButton.styleFrom(
                backgroundColor: AppTheme.primaryColor,
              ),
              child: const Text('重新加载'),
            ),
          ],
        ),
      );
    }

    if (_addresses.isEmpty) {
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
              '暂无发货地址',
              style: TextStyle(color: Colors.grey, fontSize: 16),
            ),
            const SizedBox(height: 24),
            ElevatedButton(
              onPressed: _showAddAddressDialog,
              style: ElevatedButton.styleFrom(
                backgroundColor: AppTheme.primaryColor,
              ),
              child: const Text('添加发货地址'),
            ),
          ],
        ),
      );
    }

    return ListView.builder(
      padding: const EdgeInsets.all(16),
      itemCount: _addresses.length,
      itemBuilder: (context, index) {
        final address = _addresses[index];
        return _buildAddressCard(address);
      },
    );
  }

  Widget _buildAddressCard(ShippingAddress address) {
    return Card(
      margin: const EdgeInsets.only(bottom: 16),
      elevation: 2,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
        side: address.isDefault
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
                Expanded(
                  child: Row(
                    children: [
                      Text(
                        address.shipperName,
                        style: const TextStyle(
                          fontWeight: FontWeight.bold,
                          fontSize: 16,
                        ),
                      ),
                      const SizedBox(width: 12),
                      Text(
                        address.contactPhone,
                        style: TextStyle(
                          color: Colors.grey[600],
                          fontSize: 14,
                        ),
                      ),
                    ],
                  ),
                ),
                if (address.isDefault)
                  Container(
                    padding:
                        const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                    decoration: BoxDecoration(
                      color: AppTheme.primaryColor,
                      borderRadius: BorderRadius.circular(4),
                    ),
                    child: const Text(
                      '默认',
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 12,
                      ),
                    ),
                  ),
              ],
            ),
            const SizedBox(height: 8),
            Text(
              '${address.region} ${address.detail}',
              style: const TextStyle(
                fontSize: 14,
              ),
            ),
            const SizedBox(height: 16),
            Row(
              mainAxisAlignment: MainAxisAlignment.end,
              children: [
                // 因为目前API不支持编辑功能，所以注释掉编辑按钮
                // TextButton.icon(
                //   onPressed: () {},
                //   icon: const Icon(Icons.edit, size: 18),
                //   label: const Text('编辑'),
                //   style: TextButton.styleFrom(
                //     foregroundColor: Colors.blue,
                //   ),
                // ),
                TextButton.icon(
                  onPressed: () => _deleteAddress(address.addressId),
                  icon: const Icon(Icons.delete, size: 18),
                  label: const Text('删除'),
                  style: TextButton.styleFrom(
                    foregroundColor: Colors.red,
                  ),
                ),
                if (!address.isDefault)
                  TextButton.icon(
                    onPressed: () => _setDefaultAddress(address.addressId),
                    icon: const Icon(Icons.check_circle, size: 18),
                    label: const Text('设为默认'),
                    style: TextButton.styleFrom(
                      foregroundColor: AppTheme.primaryColor,
                    ),
                  ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
