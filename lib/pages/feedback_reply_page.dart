import 'package:flutter/material.dart';
import 'dart:developer' as developer;
import '../models/feedback.dart' as feedback_model;
import '../services/feedback_service.dart';
import 'feedback_detail_page.dart';

class FeedbackReplyPage extends StatefulWidget {
  const FeedbackReplyPage({Key? key}) : super(key: key);

  @override
  State<FeedbackReplyPage> createState() => _FeedbackReplyPageState();
}

class _FeedbackReplyPageState extends State<FeedbackReplyPage> {
  final FeedbackService _feedbackService = FeedbackService();
  List<feedback_model.Feedback> _repliedFeedbacks = [];
  bool _isLoading = true;
  bool _isError = false;
  String _errorMessage = '';
  int _currentPage = 1;
  bool _hasMore = true;
  bool _isLoadingMore = false;

  final ScrollController _scrollController = ScrollController();

  @override
  void initState() {
    super.initState();
    _loadRepliedFeedbacks();
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
      _loadMoreRepliedFeedbacks();
    }
  }

  Future<void> _loadRepliedFeedbacks() async {
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
        status: 2, // 只获取已处理的反馈
      );

      if (mounted) {
        setState(() {
          _repliedFeedbacks = feedbacks.where((f) => f.adminReply != null).toList();
          _isLoading = false;
          _hasMore = feedbacks.length >= 10;
        });
      }
    } catch (e) {
      developer.log('加载回复列表异常: $e', name: 'FeedbackReplyPage', error: e);
      if (mounted) {
        setState(() {
          _isLoading = false;
          _isError = true;
          _errorMessage = '加载回复列表失败，请重试';
        });
      }
    }
  }

  Future<void> _loadMoreRepliedFeedbacks() async {
    if (_isLoadingMore || !_hasMore) return;

    setState(() {
      _isLoadingMore = true;
    });

    try {
      final nextPage = _currentPage + 1;
      final moreFeedbacks = await _feedbackService.getUserFeedbacks(
        pageNum: nextPage,
        pageSize: 10,
        status: 2, // 只获取已处理的反馈
      );

      if (mounted) {
        setState(() {
          final newRepliedFeedbacks = moreFeedbacks.where((f) => f.adminReply != null).toList();
          _repliedFeedbacks.addAll(newRepliedFeedbacks);
          _currentPage = nextPage;
          _hasMore = moreFeedbacks.length >= 10;
          _isLoadingMore = false;
        });
      }
    } catch (e) {
      developer.log('加载更多回复异常: $e', name: 'FeedbackReplyPage', error: e);
      if (mounted) {
        setState(() {
          _isLoadingMore = false;
        });
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: const Text('加载更多回复失败，请重试'),
            action: SnackBarAction(
              label: '重试',
              onPressed: _loadMoreRepliedFeedbacks,
            ),
          ),
        );
      }
    }
  }

  Future<void> _refreshRepliedFeedbacks() async {
    _currentPage = 1;
    return _loadRepliedFeedbacks();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('管理员回复'),
        elevation: 0,
      ),
      body: _isLoading && _currentPage == 1
          ? const Center(child: CircularProgressIndicator())
          : _isError && _repliedFeedbacks.isEmpty
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
                        onPressed: _loadRepliedFeedbacks,
                        child: const Text('重新加载'),
                      ),
                    ],
                  ),
                )
              : _repliedFeedbacks.isEmpty
                  ? Center(
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          const Icon(
                            Icons.message_outlined,
                            size: 60,
                            color: Colors.grey,
                          ),
                          const SizedBox(height: 16),
                          const Text(
                            '暂无管理员回复',
                            style: TextStyle(
                              fontSize: 16,
                              color: Colors.grey,
                            ),
                          ),
                        ],
                      ),
                    )
                  : RefreshIndicator(
                      onRefresh: _refreshRepliedFeedbacks,
                      child: ListView.builder(
                        controller: _scrollController,
                        itemCount: _repliedFeedbacks.length + (_hasMore ? 1 : 0),
                        padding: const EdgeInsets.all(16),
                        itemBuilder: (context, index) {
                          if (index == _repliedFeedbacks.length) {
                            return _buildLoadingMoreIndicator();
                          }
                          final feedback = _repliedFeedbacks[index];
                          return _buildReplyCard(feedback);
                        },
                      ),
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
                onPressed: _loadMoreRepliedFeedbacks,
                child: const Text('加载更多'),
              ),
      ),
    );
  }

  Widget _buildReplyCard(feedback_model.Feedback feedback) {
    // 格式化日期
    String formattedDate = '未知时间';
    if (feedback.replyTime != null) {
      try {
        final dateTime = DateTime.parse(feedback.replyTime!);
        formattedDate =
            '${dateTime.year}-${dateTime.month.toString().padLeft(2, '0')}-${dateTime.day.toString().padLeft(2, '0')} ${dateTime.hour.toString().padLeft(2, '0')}:${dateTime.minute.toString().padLeft(2, '0')}';
      } catch (e) {
        developer.log('日期解析错误: $e', name: 'FeedbackReplyPage');
      }
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
          ).then((_) => _refreshRepliedFeedbacks());
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
                      color: Colors.green.withOpacity(0.1),
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(
                        color: Colors.green,
                        width: 1,
                      ),
                    ),
                    child: const Text(
                      '已回复',
                      style: TextStyle(
                        fontSize: 12,
                        color: Colors.green,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 12),
              Text(
                '管理员回复：',
                style: TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.bold,
                  color: Colors.grey[700],
                ),
              ),
              const SizedBox(height: 4),
              Text(
                feedback.adminReply ?? '',
                style: TextStyle(
                  fontSize: 14,
                  color: Colors.grey[700],
                ),
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
              ),
              const SizedBox(height: 12),
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