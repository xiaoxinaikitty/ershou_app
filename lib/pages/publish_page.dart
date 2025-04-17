import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../config/theme.dart';
import '../network/api.dart';
import '../network/http_util.dart';
import '../widgets/primary_button.dart';
import 'package:image_picker/image_picker.dart';
import 'dart:io';
import 'dart:developer' as developer;

class PublishPage extends StatefulWidget {
  const PublishPage({Key? key}) : super(key: key);

  @override
  State<PublishPage> createState() => _PublishPageState();
}

class _PublishPageState extends State<PublishPage> {
  final _formKey = GlobalKey<FormState>();
  final _titleController = TextEditingController();
  final _priceController = TextEditingController();
  final _originalPriceController = TextEditingController();
  final _descriptionController = TextEditingController();
  String _selectedCategory = '手机数码';
  int _conditionLevel = 9; // 默认9成新
  String _location = '北京市';

  bool _isLoading = false;
  final List<String> _categories = [
    '手机数码',
    '电脑办公',
    '家用电器',
    '运动户外',
    '服饰鞋包',
    '母婴玩具',
    '生活用品',
    '其他'
  ];

  final List<Map<String, dynamic>> _imageList = [];
  final ImagePicker _picker = ImagePicker();

  @override
  void initState() {
    super.initState();
    // 在页面初始化时检查是否有丢失的数据
    _retrieveLostData();
  }

  // 检索因为应用被系统杀死可能丢失的图片数据
  Future<void> _retrieveLostData() async {
    try {
      final LostDataResponse response = await _picker.retrieveLostData();
      if (response.isEmpty) {
        return;
      }

      final List<XFile>? files = response.files;
      if (files != null && files.isNotEmpty) {
        for (final XFile file in files) {
          _processPickedImage(file);
        }
      } else if (response.file != null) {
        _processPickedImage(response.file!);
      }
    } catch (e) {
      print('检索丢失数据时发生错误: $e');
    }
  }

  // 处理选择的图片文件
  Future<void> _processPickedImage(XFile image) async {
    try {
      final File imageFile = File(image.path);
      final fileSize = await imageFile.length();
      final fileName = image.name;
      final filePath = image.path;

      // 控制台打印图片信息
      print('选择的图片信息:');
      print('文件名: $fileName');
      print('文件路径: $filePath');
      print('文件大小: ${(fileSize / 1024).toStringAsFixed(2)} KB');
      print('文件类型: ${fileName.split('.').last}');

      setState(() {
        _imageList.add({
          'url': image.path,
          'name': fileName,
          'size': fileSize,
          'file': imageFile,
        });
      });
    } catch (e) {
      print('处理图片时出错: $e');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('处理图片时出错: $e')),
        );
      }
    }
  }

  @override
  void dispose() {
    _titleController.dispose();
    _priceController.dispose();
    _originalPriceController.dispose();
    _descriptionController.dispose();
    super.dispose();
  }

  Future<void> _publishProduct() async {
    if (!_formKey.currentState!.validate()) {
      return;
    }

    if (_imageList.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('请至少上传一张商品图片')),
      );
      return;
    }

    setState(() {
      _isLoading = true;
    });

    try {
      final response = await HttpUtil().post(
        Api.productAdd,
        data: {
          'title': _titleController.text,
          'price': double.parse(_priceController.text),
          'originalPrice': double.parse(_originalPriceController.text),
          'description': _descriptionController.text,
          'categoryId': _categories.indexOf(_selectedCategory) + 1,
          'conditionLevel': _conditionLevel,
          'location': _location,
        },
      );

      if (response.isSuccess) {
        // 发布成功，可以上传图片
        final productId = response.data['productId'];

        // 上传图片逻辑（简化示例）
        // 对于每张图片，调用图片上传接口
        // for (var imageData in _imageList) {
        //   await uploadImage(productId, imageData);
        // }

        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('商品发布成功')),
        );

        // 清空表单
        _resetForm();
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(response.message ?? '发布失败')),
        );
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('网络错误，请稍后再试')),
      );
    } finally {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  void _resetForm() {
    _titleController.clear();
    _priceController.clear();
    _originalPriceController.clear();
    _descriptionController.clear();
    setState(() {
      _selectedCategory = '手机数码';
      _conditionLevel = 9;
      _imageList.clear();
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title:
            const Text('发布二手商品', style: TextStyle(fontWeight: FontWeight.bold)),
        elevation: 0,
      ),
      body: Form(
        key: _formKey,
        child: ListView(
          padding: const EdgeInsets.all(16.0),
          children: [
            // 图片上传区域
            _buildImageUploadSection(),
            const SizedBox(height: 20),

            // 商品标题
            TextFormField(
              controller: _titleController,
              decoration: const InputDecoration(
                labelText: '商品标题',
                hintText: '请输入商品标题（15字以内）',
                border: OutlineInputBorder(),
              ),
              maxLength: 15,
              validator: (value) {
                if (value == null || value.isEmpty) {
                  return '请输入商品标题';
                }
                return null;
              },
            ),
            const SizedBox(height: 16),

            // 价格区域
            Row(
              children: [
                // 现价
                Expanded(
                  child: TextFormField(
                    controller: _priceController,
                    decoration: const InputDecoration(
                      labelText: '现价(元)',
                      border: OutlineInputBorder(),
                      prefixText: '¥',
                    ),
                    keyboardType: TextInputType.number,
                    validator: (value) {
                      if (value == null || value.isEmpty) {
                        return '请输入价格';
                      }
                      if (double.tryParse(value) == null) {
                        return '请输入有效价格';
                      }
                      return null;
                    },
                  ),
                ),
                const SizedBox(width: 16),
                // 原价
                Expanded(
                  child: TextFormField(
                    controller: _originalPriceController,
                    decoration: const InputDecoration(
                      labelText: '原价(元)',
                      border: OutlineInputBorder(),
                      prefixText: '¥',
                    ),
                    keyboardType: TextInputType.number,
                    validator: (value) {
                      if (value == null || value.isEmpty) {
                        return '请输入原价';
                      }
                      if (double.tryParse(value) == null) {
                        return '请输入有效原价';
                      }
                      return null;
                    },
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),

            // 分类选择
            DropdownButtonFormField<String>(
              decoration: const InputDecoration(
                labelText: '商品分类',
                border: OutlineInputBorder(),
              ),
              value: _selectedCategory,
              items: _categories.map((category) {
                return DropdownMenuItem(
                  value: category,
                  child: Text(category),
                );
              }).toList(),
              onChanged: (value) {
                setState(() {
                  _selectedCategory = value!;
                });
              },
              validator: (value) {
                if (value == null || value.isEmpty) {
                  return '请选择商品分类';
                }
                return null;
              },
            ),
            const SizedBox(height: 16),

            // 新旧程度
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('新旧程度: $_conditionLevel成新'),
                Slider(
                  value: _conditionLevel.toDouble(),
                  min: 1,
                  max: 10,
                  divisions: 9,
                  label: '$_conditionLevel成新',
                  activeColor: AppTheme.primaryColor,
                  onChanged: (value) {
                    setState(() {
                      _conditionLevel = value.round();
                    });
                  },
                ),
              ],
            ),
            const SizedBox(height: 16),

            // 商品描述
            TextFormField(
              controller: _descriptionController,
              decoration: const InputDecoration(
                labelText: '商品描述',
                hintText: '请详细描述您的商品，如成色、使用感受等',
                border: OutlineInputBorder(),
                alignLabelWithHint: true,
              ),
              maxLines: 5,
              validator: (value) {
                if (value == null || value.isEmpty) {
                  return '请输入商品描述';
                }
                return null;
              },
            ),
            const SizedBox(height: 16),

            // 发布位置
            ListTile(
              leading: const Icon(Icons.location_on_outlined),
              title: const Text('发布位置'),
              subtitle: Text(_location),
              onTap: () {
                // 位置选择功能
              },
            ),
            const SizedBox(height: 32),

            // 发布按钮
            PrimaryButton(
              text: '发布商品',
              onPressed: _publishProduct,
              isLoading: _isLoading,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildImageUploadSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          '上传商品图片',
          style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
        ),
        const SizedBox(height: 8),
        const Text(
          '请上传清晰的实物图片，最多9张',
          style: TextStyle(color: Colors.grey, fontSize: 12),
        ),
        const SizedBox(height: 12),
        GridView.builder(
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
            crossAxisCount: 3,
            crossAxisSpacing: 10,
            mainAxisSpacing: 10,
          ),
          itemCount: _imageList.length + 1, // +1 为添加按钮
          itemBuilder: (context, index) {
            if (index == _imageList.length) {
              // 添加图片按钮
              return InkWell(
                onTap: _addImage,
                child: Container(
                  decoration: BoxDecoration(
                    color: Colors.grey[200],
                    borderRadius: BorderRadius.circular(4),
                  ),
                  child: const Icon(
                    Icons.add_a_photo,
                    color: Colors.grey,
                  ),
                ),
              );
            } else {
              // 已上传的图片
              return Stack(
                children: [
                  Container(
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(4),
                    ),
                    clipBehavior: Clip.antiAlias,
                    child: _imageList[index]['url'].startsWith('/')
                        ? Image.file(
                            File(_imageList[index]['url']),
                            width: double.infinity,
                            height: double.infinity,
                            fit: BoxFit.cover,
                          )
                        : const Center(
                            child: Icon(Icons.image, color: Colors.white),
                          ),
                  ),
                  Positioned(
                    right: 0,
                    top: 0,
                    child: InkWell(
                      onTap: () => _removeImage(index),
                      child: Container(
                        padding: const EdgeInsets.all(2),
                        decoration: const BoxDecoration(
                          color: Colors.red,
                          shape: BoxShape.circle,
                        ),
                        child: const Icon(
                          Icons.close,
                          size: 16,
                          color: Colors.white,
                        ),
                      ),
                    ),
                  ),
                ],
              );
            }
          },
        ),
      ],
    );
  }

  void _addImage() async {
    // 使用image_picker打开图库选择图片
    if (_imageList.length < 9) {
      try {
        // 使用更安全的调用方式
        final XFile? image = await _picker.pickImage(
          source: ImageSource.gallery,
          maxWidth: 1800,
          maxHeight: 1800,
          imageQuality: 85,
        );

        if (image != null) {
          await _processPickedImage(image);
        }
      } on PlatformException catch (e) {
        print('PlatformException: ${e.code}, ${e.message}, ${e.details}');
        String errorMessage = '选择图片时出错';

        // 更详细的错误提示
        if (e.code == 'photo_access_denied') {
          errorMessage = '无法访问相册，请检查应用权限设置';
        } else if (e.code == 'camera_access_denied') {
          errorMessage = '无法访问相机，请检查应用权限设置';
        } else {
          errorMessage = '选择图片时出错: ${e.message}';
        }

        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(errorMessage)),
        );
      } catch (e) {
        print('选择图片时出错: $e');
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('选择图片时出错: $e')),
        );
      }
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('最多只能上传9张图片')),
      );
    }
  }

  void _removeImage(int index) {
    setState(() {
      _imageList.removeAt(index);
    });
  }
}
