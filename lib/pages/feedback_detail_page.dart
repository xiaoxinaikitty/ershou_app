import 'package:flutter/material.dart';
import 'dart:developer' as developer;
import '../config/theme.dart';
import '../models/feedback.dart' as feedback_model;
import '../services/feedback_service.dart';

class FeedbackDetailPage extends StatefulWidget {
  final int feedbackId;

  const FeedbackDetailPage({
    Key? key,
    required this.feedbackId,
  }) : super(key: key);

  @override
  State<FeedbackDetailPage> createState() => _FeedbackDetailPageState();
}

class _FeedbackDetailPageState extends State<FeedbackDetailPage> {
  final FeedbackService _feedbackService = FeedbackService();
  feedback_model.Feedback? _feedback;
  bool _isLoading = true;
  bool _isError = false;
  String _errorMessage = '';

  @override
  void initState() {
    super.initState();
    _loadFeedbackDetail();
  }

  Future<void> _loadFeedbackDetail() async {
    setState(() {
      _isLoading = true;
      _isError = false;
      _errorMessage = '';
    });

    try {
      final feedback =
          await _feedbackService.getFeedbackDetail(widget.feedbackId);

      if (mounted) {
        setState(() {
          _feedback = feedback;
          _isLoading = false;
          if (feedback == null) {
            _isError = true;
            _errorMessage = '找不到该反馈信息';
          }
        });
      }
    } catch (e) {
      developer.log('加载反馈详情异常: $e', name: 'FeedbackDetailPage', error: e);
      if (mounted) {
        setState(() {
          _isLoading = false;
          _isError = true;
          _errorMessage = '加载反馈详情失败，请重试';
        });
      }
    }
  }

  // 格式化日期
  String _formatDate(String? dateString) {
    if (dateString == null) return '未知时间';

    try {
      final dateTime = DateTime.parse(dateString);
      return '${dateTime.year}-${dateTime.month.toString().padLeft(2, '0')}-${dateTime.day.toString().padLeft(2, '0')} ${dateTime.hour.toString().padLeft(2, '0')}:${dateTime.minute.toString().padLeft(2, '0')}';
    } catch (e) {
      developer.log('日期解析错误: $e', name: 'FeedbackDetailPage');
      return '未知时间';
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('反馈详情'),
        elevation: 0,
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : _isError
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
                        onPressed: _loadFeedbackDetail,
                        child: const Text('重新加载'),
                      ),
                    ],
                  ),
                )
              : SingleChildScrollView(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // 反馈信息卡片
                      _buildFeedbackCard(),

                      const SizedBox(height: 16),

                      // 回复信息卡片（如果有回复）
                      if (_feedback?.adminReply != null &&
                          _feedback!.adminReply!.isNotEmpty)
                        _buildReplyCard(),
                    ],
                  ),
                ),
    );
  }

  Widget _buildFeedbackCard() {
    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
      ),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                const Icon(Icons.feedback_outlined, color: Colors.blue),
                const SizedBox(width: 8),
                const Text(
                  '我的反馈',
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const Spacer(),
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 8,
                    vertical: 4,
                  ),
                  decoration: BoxDecoration(
                    color: _feedback?.adminReply != null &&
                            _feedback!.adminReply!.isNotEmpty
                        ? Colors.green.withOpacity(0.1)
                        : Colors.orange.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(
                      color: _feedback?.adminReply != null &&
                              _feedback!.adminReply!.isNotEmpty
                          ? Colors.green
                          : Colors.orange,
                      width: 1,
                    ),
                  ),
                  child: Text(
                    _feedback?.adminReply != null &&
                            _feedback!.adminReply!.isNotEmpty
                        ? '已回复'
                        : '等待回复',
                    style: TextStyle(
                      fontSize: 12,
                      color: _feedback?.adminReply != null &&
                              _feedback!.adminReply!.isNotEmpty
                          ? Colors.green
                          : Colors.orange,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              ],
            ),
            const Divider(height: 24),
            // 显示反馈类型
            if (_feedback?.feedbackTypeDesc != null)
              Container(
                margin: const EdgeInsets.only(bottom: 8),
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                decoration: BoxDecoration(
                  color: Colors.blue.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Text(
                  _feedback!.feedbackTypeDesc!,
                  style: const TextStyle(
                    fontSize: 12,
                    color: Colors.blue,
                  ),
                ),
              ),
            Text(
              _feedback?.feedbackTitle ?? '',
              style: const TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              _formatDate(_feedback?.createdTime),
              style: TextStyle(
                fontSize: 14,
                color: Colors.grey[600],
              ),
            ),
            const SizedBox(height: 16),
            Text(
              _feedback?.feedbackContent ?? '',
              style: const TextStyle(
                fontSize: 16,
              ),
            ),
            // 如果有图片则显示
            if (_feedback?.images != null && _feedback!.images!.isNotEmpty) ...[
              const SizedBox(height: 16),
              const Divider(),
              const SizedBox(height: 8),
              const Text(
                '附带图片:',
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 8),
              _buildImageGrid(_feedback!.images!),
            ],
            if (_feedback?.contactInfo != null &&
                _feedback!.contactInfo!.isNotEmpty) ...[
              const SizedBox(height: 16),
              const Divider(),
              const SizedBox(height: 8),
              Row(
                children: [
                  const Icon(Icons.contact_mail, size: 16, color: Colors.grey),
                  const SizedBox(width: 8),
                  Text(
                    '联系方式: ${_feedback!.contactInfo}',
                    style: TextStyle(
                      fontSize: 14,
                      color: Colors.grey[600],
                    ),
                  ),
                ],
              ),
            ],
          ],
        ),
      ),
    );
  }

  // 显示图片网格
  Widget _buildImageGrid(String imagesStr) {
    List<String> images = imagesStr.split(',');
    return GridView.builder(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 3,
        crossAxisSpacing: 8,
        mainAxisSpacing: 8,
      ),
      itemCount: images.length,
      itemBuilder: (context, index) {
        return GestureDetector(
          onTap: () {
            // 点击查看大图
            showDialog(
              context: context,
              builder: (_) => Dialog(
                child: Image.network(
                  images[index],
                  fit: BoxFit.contain,
                ),
              ),
            );
          },
          child: Container(
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(8),
              image: DecorationImage(
                image: NetworkImage(images[index]),
                fit: BoxFit.cover,
              ),
            ),
          ),
        );
      },
    );
  }

  Widget _buildReplyCard() {
    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
      ),
      color: Colors.blue.withOpacity(0.05),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                const Icon(Icons.support_agent, color: Colors.blue),
                const SizedBox(width: 8),
                const Text(
                  '官方回复',
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    color: Colors.blue,
                  ),
                ),
                const Spacer(),
                Text(
                  _formatDate(_feedback?.replyTime),
                  style: TextStyle(
                    fontSize: 14,
                    color: Colors.grey[600],
                  ),
                ),
              ],
            ),
            const Divider(height: 24),
            Text(
              _feedback?.adminReply ?? '',
              style: const TextStyle(
                fontSize: 16,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
