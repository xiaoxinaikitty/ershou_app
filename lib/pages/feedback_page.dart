import 'package:flutter/material.dart';
import 'dart:developer' as developer;
import '../config/theme.dart';
import '../models/feedback.dart' as feedback_model;
import '../services/feedback_service.dart';
import 'feedback_detail_page.dart';
import 'dart:io';
import 'package:image_picker/image_picker.dart';
import '../network/http_util.dart';

class FeedbackPage extends StatefulWidget {
  const FeedbackPage({Key? key}) : super(key: key);

  @override
  State<FeedbackPage> createState() => _FeedbackPageState();
}

class _FeedbackPageState extends State<FeedbackPage> {
  final FeedbackService _feedbackService = FeedbackService();
  List<feedback_model.Feedback> _feedbacks = [];
  bool _isLoading = true;
  bool _isError = false;
  String _errorMessage = '';
  int _currentPage = 1;
  bool _hasMore = true;
  bool _isLoadingMore = false;
  int _retryCount = 0;
  final int _maxRetries = 2;

  final ScrollController _scrollController = ScrollController();
  final ImagePicker _picker = ImagePicker();

  @override
  void initState() {
    super.initState();
    _loadFeedbacks();
    _scrollController.addListener(_scrollListener);
  }

  @override
  void dispose() {
    _scrollController.removeListener(_scrollListener);
    _scrollController.dispose();
    super.dispose();
  }

  void _scrollListener() {
    if (_scrollController.position.pixels >=
            _scrollController.position.maxScrollExtent - 200 &&
        !_isLoading &&
        !_isLoadingMore &&
        _hasMore) {
      _loadMoreFeedbacks();
    }
  }

  Future<void> _loadFeedbacks() async {
    setState(() {
      _isLoading = true;
      _isError = false;
      _errorMessage = '';
      _currentPage = 1;
      _hasMore = true;
    });

    try {
      final feedbacks = await _feedbackService.getUserFeedbacks(
        pageNum: _currentPage,
        pageSize: 10,
      );
      if (mounted) {
        setState(() {
          _feedbacks = feedbacks;
          _isLoading = false;
          _hasMore = feedbacks.length >= 10;
          _retryCount = 0; // 成功后重置重试次数
        });
      }
    } catch (e) {
      developer.log('加载反馈列表异常: $e', name: 'FeedbackPage', error: e);

      if (_retryCount < _maxRetries) {
        _retryCount++;
        developer.log('自动重试加载反馈列表，第$_retryCount次', name: 'FeedbackPage');
        await Future.delayed(const Duration(seconds: 1));
        _loadFeedbacks();
      } else {
        if (mounted) {
          setState(() {
            _isLoading = false;
            _isError = true;
            _errorMessage = '加载反馈列表失败，请重试';
          });
        }
      }
    }
  }

  Future<void> _loadMoreFeedbacks() async {
    if (_isLoadingMore || !_hasMore) return;

    setState(() {
      _isLoadingMore = true;
    });

    try {
      final nextPage = _currentPage + 1;
      final moreFeedbacks = await _feedbackService.getUserFeedbacks(
        pageNum: nextPage,
        pageSize: 10,
      );

      if (mounted) {
        setState(() {
          if (moreFeedbacks.isNotEmpty) {
            _feedbacks.addAll(moreFeedbacks);
            _currentPage = nextPage;
            _hasMore = moreFeedbacks.length >= 10;
          } else {
            _hasMore = false;
          }
          _isLoadingMore = false;
        });
      }
    } catch (e) {
      developer.log('加载更多反馈异常: $e', name: 'FeedbackPage', error: e);
      if (mounted) {
        setState(() {
          _isLoadingMore = false;
        });
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: const Text('加载更多反馈失败，请重试'),
            action: SnackBarAction(
              label: '重试',
              onPressed: _loadMoreFeedbacks,
            ),
          ),
        );
      }
    }
  }

  Future<void> _refreshFeedbacks() async {
    _currentPage = 1;
    return _loadFeedbacks();
  }

  void _showCreateFeedbackDialog() {
    final TextEditingController titleController = TextEditingController();
    final TextEditingController contentController = TextEditingController();
    final TextEditingController contactController = TextEditingController();

    // 存储选择的图片
    List<XFile> selectedImages = [];
    int selectedFeedbackType = 1; // 默认为功能建议类型

    // 反馈类型选项
    final List<Map<String, dynamic>> feedbackTypes = [
      {'value': 1, 'label': '功能建议'},
      {'value': 2, 'label': '体验问题'},
      {'value': 3, 'label': '商品相关'},
      {'value': 4, 'label': '物流相关'},
      {'value': 5, 'label': '其他'},
    ];

    // 选择图片的方法
    Future<void> pickImages() async {
      try {
        final List<XFile>? images = await _picker.pickMultiImage(
          maxWidth: 1200,
          maxHeight: 1200,
          imageQuality: 85,
        );

        if (images != null && images.isNotEmpty) {
          if (selectedImages.length + images.length > 3) {
            // 提示用户最多只能选择3张图片
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(content: Text('最多只能上传3张图片')),
            );
            // 只添加能添加的数量
            int canAddCount = 3 - selectedImages.length;
            if (canAddCount > 0) {
              selectedImagesSetState(() {
                selectedImages.addAll(images.take(canAddCount));
              });
            }
          } else {
            selectedImagesSetState(() {
              selectedImages.addAll(images);
            });
          }
        }
      } catch (e) {
        developer.log('选择图片异常: $e', name: 'FeedbackPage', error: e);
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('选择图片失败，请重试')),
        );
      }
    }

    // 提交反馈的方法
    Future<void> submitFeedback() async {
      final title = titleController.text.trim();
      final content = contentController.text.trim();
      final contact = contactController.text.trim();

      if (title.isEmpty) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('请输入反馈标题')),
        );
        return;
      }

      if (content.isEmpty) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('请输入反馈内容')),
        );
        return;
      }

      Navigator.of(context).pop();

      // 显示加载中
      showDialog(
        context: context,
        barrierDismissible: false,
        builder: (BuildContext context) {
          return const AlertDialog(
            content: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                CircularProgressIndicator(),
                SizedBox(height: 16),
                Text('提交中...'),
              ],
            ),
          );
        },
      );

      try {
        // 处理图片上传
        List<String> imageUrls = [];
        if (selectedImages.isNotEmpty) {
          // 显示上传图片进度
          Navigator.of(context).pop(); // 关闭之前的加载对话框
          showDialog(
            context: context,
            barrierDismissible: false,
            builder: (BuildContext context) {
              return AlertDialog(
                content: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const CircularProgressIndicator(),
                    const SizedBox(height: 16),
                    Text('正在上传图片 (0/${selectedImages.length})'),
                  ],
                ),
              );
            },
          );

          // 逐个上传图片
          for (int i = 0; i < selectedImages.length; i++) {
            final File imageFile = File(selectedImages[i].path);

            // 更新上传进度对话框
            if (mounted) {
              Navigator.of(context).pop();
              showDialog(
                context: context,
                barrierDismissible: false,
                builder: (BuildContext context) {
                  return AlertDialog(
                    content: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        const CircularProgressIndicator(),
                        const SizedBox(height: 16),
                        Text('正在上传图片 (${i + 1}/${selectedImages.length})'),
                      ],
                    ),
                  );
                },
              );
            }

            // 上传图片
            final uploadResponse = await HttpUtil().uploadFile(
              imageFile,
              onSendProgress: (sent, total) {
                developer.log('图片上传进度: $sent/$total', name: 'FeedbackPage');
              },
            );

            if (uploadResponse.isSuccess && uploadResponse.data != null) {
              final String imageUrl = uploadResponse.data!['fileUrl'];
              imageUrls.add(imageUrl);
            } else {
              if (mounted) {
                Navigator.of(context).pop(); // 关闭加载对话框
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(content: Text('图片上传失败: ${uploadResponse.message}')),
                );
              }
              return;
            }
          }

          if (mounted) {
            Navigator.of(context).pop(); // 关闭上传进度对话框

            // 重新显示提交中对话框
            showDialog(
              context: context,
              barrierDismissible: false,
              builder: (BuildContext context) {
                return const AlertDialog(
                  content: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      CircularProgressIndicator(),
                      SizedBox(height: 16),
                      Text('提交反馈中...'),
                    ],
                  ),
                );
              },
            );
          }
        }

        // 提交反馈
        final result = await _feedbackService.submitFeedback(
          title: title,
          content: content,
          contactInfo: contact.isNotEmpty ? contact : null,
          feedbackType: selectedFeedbackType,
          images: imageUrls.isNotEmpty ? imageUrls.join(',') : null,
        );

        if (mounted) {
          Navigator.of(context).pop(); // 关闭加载对话框

          if (result) {
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(content: Text('反馈提交成功')),
            );
            _loadFeedbacks(); // 重新加载反馈列表
          } else {
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(content: Text('反馈提交失败，请重试')),
            );
          }
        }
      } catch (e) {
        if (mounted) {
          Navigator.of(context).pop(); // 关闭加载对话框
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('提交失败，请稍后重试')),
          );
        }
      }
    }

    showDialog(
      context: context,
      builder: (BuildContext context) {
        return StatefulBuilder(
          builder: (context, setState) {
            // 设置能够更新选中图片列表的setState
            selectedImagesSetState = setState;

            return AlertDialog(
              title: const Text('提交反馈'),
              content: SingleChildScrollView(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // 反馈类型选择
                    DropdownButtonFormField<int>(
                      value: selectedFeedbackType,
                      decoration: const InputDecoration(
                        labelText: '反馈类型',
                        border: OutlineInputBorder(),
                      ),
                      items: feedbackTypes.map((type) {
                        return DropdownMenuItem<int>(
                          value: type['value'],
                          child: Text(type['label']),
                        );
                      }).toList(),
                      onChanged: (value) {
                        setState(() {
                          selectedFeedbackType = value!;
                        });
                      },
                    ),
                    const SizedBox(height: 16),
                    // 标题输入
                    TextField(
                      controller: titleController,
                      decoration: const InputDecoration(
                        labelText: '标题',
                        hintText: '请输入反馈标题',
                        border: OutlineInputBorder(),
                      ),
                    ),
                    const SizedBox(height: 16),
                    // 内容输入
                    TextField(
                      controller: contentController,
                      decoration: const InputDecoration(
                        labelText: '内容',
                        hintText: '请详细描述您的问题或建议',
                        border: OutlineInputBorder(),
                      ),
                      maxLines: 5,
                    ),
                    const SizedBox(height: 16),
                    // 联系方式输入
                    TextField(
                      controller: contactController,
                      decoration: const InputDecoration(
                        labelText: '联系方式（选填）',
                        hintText: '电话或邮箱',
                        border: OutlineInputBorder(),
                      ),
                    ),
                    const SizedBox(height: 16),
                    // 图片选择部分
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            const Text(
                              '添加图片（选填，最多3张）：',
                              style: TextStyle(
                                fontSize: 14,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                            const SizedBox(width: 8),
                            Text(
                              '${selectedImages.length}/3',
                              style: TextStyle(
                                fontSize: 14,
                                color: Colors.grey[600],
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 8),
                        // 添加图片按钮
                        if (selectedImages.length < 3)
                          OutlinedButton.icon(
                            onPressed: pickImages,
                            icon: const Icon(Icons.add_photo_alternate),
                            label: const Text('选择图片'),
                            style: OutlinedButton.styleFrom(
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(8),
                              ),
                            ),
                          ),
                        const SizedBox(height: 12),
                        // 图片预览区
                        if (selectedImages.isNotEmpty)
                          Container(
                            constraints: const BoxConstraints(
                              maxHeight: 120,
                            ),
                            width: double.infinity,
                            child: GridView.builder(
                              gridDelegate:
                                  const SliverGridDelegateWithFixedCrossAxisCount(
                                crossAxisCount: 3,
                                crossAxisSpacing: 8,
                                mainAxisSpacing: 8,
                                childAspectRatio: 1,
                              ),
                              shrinkWrap: true,
                              itemCount: selectedImages.length,
                              itemBuilder: (context, index) {
                                return Stack(
                                  children: [
                                    Container(
                                      width: double.infinity,
                                      height: double.infinity,
                                      decoration: BoxDecoration(
                                        borderRadius: BorderRadius.circular(8),
                                        image: DecorationImage(
                                          image: FileImage(
                                              File(selectedImages[index].path)),
                                          fit: BoxFit.cover,
                                        ),
                                      ),
                                    ),
                                    Positioned(
                                      top: 0,
                                      right: 0,
                                      child: GestureDetector(
                                        onTap: () {
                                          selectedImagesSetState(() {
                                            selectedImages.removeAt(index);
                                          });
                                        },
                                        child: Container(
                                          padding: const EdgeInsets.all(4),
                                          decoration: const BoxDecoration(
                                            color: Colors.red,
                                            shape: BoxShape.circle,
                                          ),
                                          child: const Icon(
                                            Icons.close,
                                            color: Colors.white,
                                            size: 16,
                                          ),
                                        ),
                                      ),
                                    ),
                                  ],
                                );
                              },
                            ),
                          ),
                      ],
                    ),
                  ],
                ),
              ),
              actions: [
                TextButton(
                  onPressed: () => Navigator.of(context).pop(),
                  child: const Text('取消'),
                ),
                TextButton(
                  onPressed: submitFeedback,
                  child: const Text('提交'),
                ),
              ],
            );
          },
        );
      },
    );
  }

  // 用于在图片选择器状态更新时使用
  late StateSetter selectedImagesSetState;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('用户反馈'),
        elevation: 0,
      ),
      body: Column(
        children: [
          // 列表占据大部分空间
          Expanded(
            child: _isLoading && _currentPage == 1
                ? const Center(child: CircularProgressIndicator())
                : _isError && _feedbacks.isEmpty
                    ? Center(
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
                              onPressed: _loadFeedbacks,
                              child: const Text('重新加载'),
                            ),
                          ],
                        ),
                      )
                    : _feedbacks.isEmpty
                        ? Center(
                            child: Column(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                const Icon(
                                  Icons.feedback_outlined,
                                  size: 60,
                                  color: Colors.grey,
                                ),
                                const SizedBox(height: 16),
                                const Text(
                                  '您还没有提交过反馈',
                                  style: TextStyle(
                                    fontSize: 16,
                                    color: Colors.grey,
                                  ),
                                ),
                              ],
                            ),
                          )
                        : RefreshIndicator(
                            onRefresh: _refreshFeedbacks,
                            child: ListView.builder(
                              controller: _scrollController,
                              itemCount: _feedbacks.length + (_hasMore ? 1 : 0),
                              padding: const EdgeInsets.all(16),
                              itemBuilder: (context, index) {
                                if (index == _feedbacks.length) {
                                  return _buildLoadingMoreIndicator();
                                }
                                final feedback = _feedbacks[index];
                                return _buildFeedbackCard(feedback);
                              },
                            ),
                          ),
          ),

          // 底部提交按钮区域
          Container(
            width: double.infinity,
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            decoration: BoxDecoration(
              color: Colors.white,
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.05),
                  offset: const Offset(0, -1),
                  blurRadius: 5,
                ),
              ],
            ),
            child: ElevatedButton(
              onPressed: _showCreateFeedbackDialog,
              style: ElevatedButton.styleFrom(
                backgroundColor: AppTheme.primaryColor,
                padding: const EdgeInsets.symmetric(vertical: 12),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(8),
                ),
              ),
              child: const Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.add, color: Colors.white),
                  SizedBox(width: 8),
                  Text(
                    '提交新反馈',
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                      color: Colors.white,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildLoadingMoreIndicator() {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 16),
      child: Center(
        child: _isLoadingMore
            ? const CircularProgressIndicator()
            : TextButton(
                onPressed: _loadMoreFeedbacks,
                child: const Text('加载更多'),
              ),
      ),
    );
  }

  Widget _buildFeedbackCard(feedback_model.Feedback feedback) {
    // 格式化日期
    String formattedDate = '未知时间';
    if (feedback.createdTime != null) {
      try {
        final dateTime = DateTime.parse(feedback.createdTime!);
        formattedDate =
            '${dateTime.year}-${dateTime.month.toString().padLeft(2, '0')}-${dateTime.day.toString().padLeft(2, '0')} ${dateTime.hour.toString().padLeft(2, '0')}:${dateTime.minute.toString().padLeft(2, '0')}';
      } catch (e) {
        developer.log('日期解析错误: $e', name: 'FeedbackPage');
      }
    }

    // 确定状态和状态颜色
    String status = feedback.statusDesc ?? '等待回复';
    Color statusColor = Colors.orange;

    if (feedback.status == 2) {
      // 已处理
      statusColor = Colors.green;
    } else if (feedback.status == 1) {
      // 处理中
      statusColor = Colors.blue;
    }

    return Card(
      margin: const EdgeInsets.only(bottom: 16),
      elevation: 2,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
      ),
      child: InkWell(
        onTap: () {
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (context) =>
                  FeedbackDetailPage(feedbackId: feedback.feedbackId!),
            ),
          ).then((_) => _loadFeedbacks());
        },
        borderRadius: BorderRadius.circular(12),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Expanded(
                    child: Text(
                      feedback.feedbackTitle,
                      style: const TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 8,
                      vertical: 4,
                    ),
                    decoration: BoxDecoration(
                      color: statusColor.withOpacity(0.1),
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(
                        color: statusColor,
                        width: 1,
                      ),
                    ),
                    child: Text(
                      status,
                      style: TextStyle(
                        fontSize: 12,
                        color: statusColor,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 8),
              Text(
                feedback.feedbackContent,
                style: TextStyle(
                  fontSize: 14,
                  color: Colors.grey[700],
                ),
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
              ),
              const SizedBox(height: 16),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    formattedDate,
                    style: TextStyle(
                      fontSize: 12,
                      color: Colors.grey[500],
                    ),
                  ),
                  const Icon(
                    Icons.arrow_forward_ios,
                    size: 14,
                    color: Colors.grey,
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}
