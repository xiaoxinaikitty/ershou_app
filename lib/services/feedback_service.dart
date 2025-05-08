import 'dart:developer' as developer;
import '../models/feedback.dart';
import '../network/api.dart';
import '../network/http_util.dart';

class FeedbackService {
  // 获取当前用户的反馈列表
  Future<List<Feedback>> getUserFeedbacks({
    int pageNum = 1,
    int pageSize = 20,
    int? status,
  }) async {
    try {
      final Map<String, dynamic> params = {
        'pageNum': pageNum,
        'pageSize': pageSize,
      };

      if (status != null) {
        params['status'] = status;
      }

      developer.log('获取用户反馈列表参数: $params', name: 'FeedbackService');

      final response = await HttpUtil().get(
        Api.feedbackListByUser,
        params: params,
      );

      developer.log(
          '获取用户反馈列表响应: ${response.code}, ${response.message}, 原始数据: ${response.data}',
          name: 'FeedbackService');

      if (response.isSuccess && response.data != null) {
        // 如果返回的是分页对象
        if (response.data is Map<String, dynamic> &&
            response.data.containsKey('list')) {
          final Map<String, dynamic> pageData = response.data;
          final List<dynamic> feedbacksJson = pageData['list'];
          developer.log('解析分页数据，获取到${feedbacksJson.length}条反馈',
              name: 'FeedbackService');
          return feedbacksJson.map((json) => Feedback.fromJson(json)).toList();
        }
        // 如果直接返回列表
        else if (response.data is List) {
          final List<dynamic> feedbacksJson = response.data;
          developer.log('直接获取到${feedbacksJson.length}条反馈',
              name: 'FeedbackService');
          return feedbacksJson.map((json) => Feedback.fromJson(json)).toList();
        }
        // 如果返回的格式不符合预期
        else {
          developer.log('返回的数据格式不符合预期: ${response.data.runtimeType}',
              name: 'FeedbackService');
          return [];
        }
      } else {
        developer.log('获取用户反馈列表失败: ${response.message}',
            name: 'FeedbackService');
        return [];
      }
    } catch (e) {
      developer.log('获取用户反馈列表异常: $e', name: 'FeedbackService', error: e);
      return [];
    }
  }

  // 获取反馈详情
  Future<Feedback?> getFeedbackDetail(int feedbackId) async {
    try {
      final response = await HttpUtil().get('${Api.feedbackDetail}$feedbackId');
      developer.log('获取反馈详情响应: ${response.code}, ${response.message}',
          name: 'FeedbackService');

      if (response.isSuccess && response.data != null) {
        return Feedback.fromJson(response.data);
      } else {
        developer.log('获取反馈详情失败: ${response.message}', name: 'FeedbackService');
        return null;
      }
    } catch (e) {
      developer.log('获取反馈详情异常: $e', name: 'FeedbackService', error: e);
      return null;
    }
  }

  // 提交反馈
  Future<bool> submitFeedback({
    required String title,
    required String content,
    String? contactInfo,
    int feedbackType = 1, // 默认为功能建议类型
    String? images, // 图片URL，多个以逗号分隔
  }) async {
    try {
      final data = {
        'feedbackTitle': title,
        'feedbackContent': content,
        'feedbackType': feedbackType,
      };

      if (contactInfo != null && contactInfo.isNotEmpty) {
        data['contactInfo'] = contactInfo;
      }

      if (images != null && images.isNotEmpty) {
        data['images'] = images;
      }

      final response = await HttpUtil().post(Api.feedbackAdd, data: data);
      developer.log('提交反馈响应: ${response.code}, ${response.message}',
          name: 'FeedbackService');

      if (response.isSuccess) {
        return true;
      } else {
        developer.log('提交反馈失败: ${response.message}', name: 'FeedbackService');
        return false;
      }
    } catch (e) {
      developer.log('提交反馈异常: $e', name: 'FeedbackService', error: e);
      return false;
    }
  }
}
