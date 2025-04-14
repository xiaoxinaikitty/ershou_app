import 'package:flutter/material.dart';
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
  List<Map<String, dynamic>> _addresses = [];

  @override
  void initState() {
    super.initState();
    _fetchAddresses();
  }

  Future<void> _fetchAddresses() async {
    setState(() {
      _isLoading = true;
    });

    try {
      // 假设有获取地址列表的API
      // final response = await HttpUtil().get(Api.userAddressList);

      // 由于API暂未提供，先使用模拟数据
      await Future.delayed(const Duration(seconds: 1));
      final mockAddresses = [
        {
          'id': 1,
          'name': '张三',
          'phone': '13800138000',
          'province': '北京市',
          'city': '北京市',
          'district': '海淀区',
          'detailAddress': '中关村大街1号',
          'isDefault': true,
        },
        {
          'id': 2,
          'name': '李四',
          'phone': '13900139000',
          'province': '上海市',
          'city': '上海市',
          'district': '徐汇区',
          'detailAddress': '漕河泾开发区',
          'isDefault': false,
        },
      ];

      setState(() {
        _addresses = mockAddresses;
        _isLoading = false;
      });

      /*
      if (response.isSuccess && response.data != null) {
        setState(() {
          _addresses = (response.data as List).cast<Map<String, dynamic>>();
          _isLoading = false;
        });
      } else {
        setState(() {
          _isLoading = false;
        });
        
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('获取地址列表失败')),
          );
        }
      }
      */
    } catch (e) {
      setState(() {
        _isLoading = false;
      });

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('网络错误，请稍后再试')),
        );
      }
    }
  }

  Future<void> _deleteAddress(int addressId) async {
    try {
      // 假设有删除地址的API
      // final response = await HttpUtil().delete('${Api.userAddress}/$addressId');

      // 由于API暂未提供，先使用模拟数据
      await Future.delayed(const Duration(milliseconds: 500));

      setState(() {
        _addresses.removeWhere((address) => address['id'] == addressId);
      });

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('地址删除成功')),
        );
      }

      /*
      if (response.isSuccess) {
        setState(() {
          _addresses.removeWhere((address) => address['id'] == addressId);
        });
        
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('地址删除成功')),
          );
        }
      } else {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text(response.message ?? '删除失败')),
          );
        }
      }
      */
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('网络错误，请稍后再试')),
        );
      }
    }
  }

  Future<void> _setDefaultAddress(int addressId) async {
    try {
      // 假设有设置默认地址的API
      // final response = await HttpUtil().put('${Api.userAddress}/default/$addressId');

      // 由于API暂未提供，先使用模拟数据
      await Future.delayed(const Duration(milliseconds: 500));

      setState(() {
        for (var address in _addresses) {
          address['isDefault'] = address['id'] == addressId;
        }
      });

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('默认地址设置成功')),
        );
      }

      /*
      if (response.isSuccess) {
        setState(() {
          for (var address in _addresses) {
            address['isDefault'] = address['id'] == addressId;
          }
        });
        
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('默认地址设置成功')),
          );
        }
      } else {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text(response.message ?? '设置失败')),
          );
        }
      }
      */
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('网络错误，请稍后再试')),
        );
      }
    }
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
          : _addresses.isEmpty
              ? _buildEmptyView()
              : _buildAddressList(),
      floatingActionButton: FloatingActionButton(
        onPressed: () {
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (context) => const AddressEditPage(),
            ),
          ).then((value) {
            if (value == true) {
              _fetchAddresses();
            }
          });
        },
        backgroundColor: AppTheme.primaryColor,
        child: const Icon(Icons.add),
      ),
    );
  }

  Widget _buildEmptyView() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.location_off,
            size: 64,
            color: Colors.grey[400],
          ),
          const SizedBox(height: 16),
          Text(
            '暂无收货地址',
            style: TextStyle(
              fontSize: 16,
              color: Colors.grey[600],
            ),
          ),
          const SizedBox(height: 24),
          ElevatedButton(
            onPressed: () {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) => const AddressEditPage(),
                ),
              ).then((value) {
                if (value == true) {
                  _fetchAddresses();
                }
              });
            },
            child: const Text('添加地址'),
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
        final isDefault = address['isDefault'] as bool;

        return Card(
          margin: const EdgeInsets.only(bottom: 16),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
            side: BorderSide(
                color: isDefault ? AppTheme.primaryColor : Colors.transparent),
          ),
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // 姓名和电话
                Row(
                  children: [
                    Text(
                      address['name'] as String,
                      style: const TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 16,
                      ),
                    ),
                    const SizedBox(width: 12),
                    Text(
                      address['phone'] as String,
                      style: TextStyle(color: Colors.grey[700]),
                    ),
                  ],
                ),
                const SizedBox(height: 8),

                // 地址
                Text(
                  '${address['province']} ${address['city']} ${address['district']} ${address['detailAddress']}',
                  style: TextStyle(color: Colors.grey[700]),
                ),
                const SizedBox(height: 16),

                // 底部操作栏
                Row(
                  children: [
                    // 默认地址标记
                    if (isDefault)
                      Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 8, vertical: 2),
                        decoration: BoxDecoration(
                          color: AppTheme.primaryColor.withOpacity(0.1),
                          borderRadius: BorderRadius.circular(4),
                        ),
                        child: Row(
                          children: [
                            Icon(
                              Icons.check_circle,
                              size: 14,
                              color: AppTheme.primaryColor,
                            ),
                            const SizedBox(width: 4),
                            Text(
                              '默认地址',
                              style: TextStyle(
                                fontSize: 12,
                                color: AppTheme.primaryColor,
                              ),
                            ),
                          ],
                        ),
                      )
                    else
                      TextButton(
                        onPressed: () =>
                            _setDefaultAddress(address['id'] as int),
                        style: TextButton.styleFrom(
                          padding: const EdgeInsets.symmetric(horizontal: 8),
                          minimumSize: Size.zero,
                          tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                        ),
                        child: const Text('设为默认'),
                      ),

                    const Spacer(),

                    // 编辑按钮
                    TextButton(
                      onPressed: () {
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (context) =>
                                AddressEditPage(address: address),
                          ),
                        ).then((value) {
                          if (value == true) {
                            _fetchAddresses();
                          }
                        });
                      },
                      style: TextButton.styleFrom(
                        padding: const EdgeInsets.symmetric(horizontal: 8),
                        minimumSize: Size.zero,
                        tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                      ),
                      child: const Text('编辑'),
                    ),

                    const SizedBox(width: 16),

                    // 删除按钮
                    TextButton(
                      onPressed: () {
                        showDialog(
                          context: context,
                          builder: (context) => AlertDialog(
                            title: const Text('删除地址'),
                            content: const Text('确定要删除这个地址吗？'),
                            actions: [
                              TextButton(
                                onPressed: () => Navigator.pop(context),
                                child: const Text('取消'),
                              ),
                              TextButton(
                                onPressed: () {
                                  Navigator.pop(context);
                                  _deleteAddress(address['id'] as int);
                                },
                                child: const Text('确定',
                                    style: TextStyle(color: Colors.red)),
                              ),
                            ],
                          ),
                        );
                      },
                      style: TextButton.styleFrom(
                        padding: const EdgeInsets.symmetric(horizontal: 8),
                        minimumSize: Size.zero,
                        tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                        foregroundColor: Colors.red,
                      ),
                      child: const Text('删除'),
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

class AddressEditPage extends StatefulWidget {
  final Map<String, dynamic>? address;

  const AddressEditPage({Key? key, this.address}) : super(key: key);

  @override
  State<AddressEditPage> createState() => _AddressEditPageState();
}

class _AddressEditPageState extends State<AddressEditPage> {
  final _formKey = GlobalKey<FormState>();
  late final TextEditingController _nameController;
  late final TextEditingController _phoneController;
  late final TextEditingController _provinceController;
  late final TextEditingController _cityController;
  late final TextEditingController _districtController;
  late final TextEditingController _detailAddressController;
  bool _isDefault = false;
  bool _isLoading = false;

  @override
  void initState() {
    super.initState();

    // 初始化控制器，如果是编辑模式则填充现有地址信息
    final address = widget.address;
    _nameController =
        TextEditingController(text: address?['name'] as String? ?? '');
    _phoneController =
        TextEditingController(text: address?['phone'] as String? ?? '');
    _provinceController =
        TextEditingController(text: address?['province'] as String? ?? '');
    _cityController =
        TextEditingController(text: address?['city'] as String? ?? '');
    _districtController =
        TextEditingController(text: address?['district'] as String? ?? '');
    _detailAddressController =
        TextEditingController(text: address?['detailAddress'] as String? ?? '');
    _isDefault = address?['isDefault'] as bool? ?? false;
  }

  @override
  void dispose() {
    _nameController.dispose();
    _phoneController.dispose();
    _provinceController.dispose();
    _cityController.dispose();
    _districtController.dispose();
    _detailAddressController.dispose();
    super.dispose();
  }

  Future<void> _saveAddress() async {
    if (!_formKey.currentState!.validate()) {
      return;
    }

    setState(() {
      _isLoading = true;
    });

    try {
      final addressData = {
        'name': _nameController.text,
        'phone': _phoneController.text,
        'province': _provinceController.text,
        'city': _cityController.text,
        'district': _districtController.text,
        'detailAddress': _detailAddressController.text,
        'isDefault': _isDefault,
      };

      if (widget.address != null) {
        addressData['id'] = widget.address!['id'];
      }

      // 假设有保存地址的API
      // final response = await HttpUtil().post(Api.userAddress, data: addressData);

      // 由于API暂未提供，先使用模拟数据
      await Future.delayed(const Duration(seconds: 1));

      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('地址${widget.address != null ? "修改" : "添加"}成功')),
      );
      Navigator.pop(context, true);

      /*
      if (response.isSuccess) {
        if (!mounted) return;
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('地址${widget.address != null ? "修改" : "添加"}成功')),
        );
        Navigator.pop(context, true);
      } else {
        setState(() {
          _isLoading = false;
        });
        
        if (!mounted) return;
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(response.message ?? '保存失败')),
        );
      }
      */
    } catch (e) {
      setState(() {
        _isLoading = false;
      });

      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('网络错误，请稍后再试')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final isEdit = widget.address != null;

    return Scaffold(
      appBar: AppBar(
        title: Text(
          isEdit ? '编辑收货地址' : '新增收货地址',
          style: const TextStyle(fontWeight: FontWeight.bold),
        ),
        elevation: 0,
      ),
      body: Form(
        key: _formKey,
        child: ListView(
          padding: const EdgeInsets.all(16),
          children: [
            // 收货人
            TextFormField(
              controller: _nameController,
              decoration: const InputDecoration(
                labelText: '收货人',
                hintText: '请输入收货人姓名',
                border: OutlineInputBorder(),
              ),
              validator: (value) {
                if (value == null || value.isEmpty) {
                  return '请输入收货人姓名';
                }
                return null;
              },
            ),
            const SizedBox(height: 16),

            // 手机号码
            TextFormField(
              controller: _phoneController,
              decoration: const InputDecoration(
                labelText: '手机号码',
                hintText: '请输入手机号码',
                border: OutlineInputBorder(),
              ),
              keyboardType: TextInputType.phone,
              validator: (value) {
                if (value == null || value.isEmpty) {
                  return '请输入手机号码';
                }
                if (value.length != 11 ||
                    !RegExp(r'^1\d{10}$').hasMatch(value)) {
                  return '请输入有效的手机号码';
                }
                return null;
              },
            ),
            const SizedBox(height: 16),

            // 省份
            TextFormField(
              controller: _provinceController,
              decoration: const InputDecoration(
                labelText: '省份',
                hintText: '请输入省份',
                border: OutlineInputBorder(),
              ),
              validator: (value) {
                if (value == null || value.isEmpty) {
                  return '请输入省份';
                }
                return null;
              },
            ),
            const SizedBox(height: 16),

            // 城市
            TextFormField(
              controller: _cityController,
              decoration: const InputDecoration(
                labelText: '城市',
                hintText: '请输入城市',
                border: OutlineInputBorder(),
              ),
              validator: (value) {
                if (value == null || value.isEmpty) {
                  return '请输入城市';
                }
                return null;
              },
            ),
            const SizedBox(height: 16),

            // 区/县
            TextFormField(
              controller: _districtController,
              decoration: const InputDecoration(
                labelText: '区/县',
                hintText: '请输入区/县',
                border: OutlineInputBorder(),
              ),
              validator: (value) {
                if (value == null || value.isEmpty) {
                  return '请输入区/县';
                }
                return null;
              },
            ),
            const SizedBox(height: 16),

            // 详细地址
            TextFormField(
              controller: _detailAddressController,
              decoration: const InputDecoration(
                labelText: '详细地址',
                hintText: '请输入详细地址，如街道、小区、门牌号等',
                border: OutlineInputBorder(),
              ),
              maxLines: 2,
              validator: (value) {
                if (value == null || value.isEmpty) {
                  return '请输入详细地址';
                }
                return null;
              },
            ),
            const SizedBox(height: 24),

            // 设为默认地址
            Row(
              children: [
                Checkbox(
                  value: _isDefault,
                  activeColor: AppTheme.primaryColor,
                  onChanged: (value) {
                    if (value != null) {
                      setState(() {
                        _isDefault = value;
                      });
                    }
                  },
                ),
                const Text('设为默认收货地址'),
              ],
            ),
            const SizedBox(height: 32),

            // 保存按钮
            SizedBox(
              width: double.infinity,
              height: 48,
              child: ElevatedButton(
                onPressed: _isLoading ? null : _saveAddress,
                child: _isLoading
                    ? const SizedBox(
                        height: 20,
                        width: 20,
                        child: CircularProgressIndicator(
                            strokeWidth: 2, color: Colors.white),
                      )
                    : const Text('保存'),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
