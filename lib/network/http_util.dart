import 'package:dio/dio.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'api.dart';
import 'api_response.dart';

/// HTTP请求工具类，单例模式
class HttpUtil {
  // 单例模式
  static final HttpUtil _instance = HttpUtil._internal();
  factory HttpUtil() => _instance;
  HttpUtil._internal() {
    _init();
  }

  late Dio _dio;
  final String _tokenKey = 'token';

  // 初始化Dio
  void _init() {
    BaseOptions options = BaseOptions(
      baseUrl: Api.baseUrl,
      connectTimeout: const Duration(seconds: 15),
      receiveTimeout: const Duration(seconds: 15),
      contentType: 'application/json; charset=utf-8',
      responseType: ResponseType.json,
    );

    _dio = Dio(options);

    // 请求拦截器
    _dio.interceptors.add(InterceptorsWrapper(
      onRequest: (options, handler) async {
        // 自动添加token
        final prefs = await SharedPreferences.getInstance();
        final token = prefs.getString(_tokenKey);
        if (token != null) {
          options.headers['Authorization'] = 'Bearer $token';
        }
        return handler.next(options);
      },
      onResponse: (response, handler) {
        return handler.next(response);
      },
      onError: (DioException e, handler) {
        _handleError(e);
        return handler.next(e);
      },
    ));

    // 日志拦截器
    _dio.interceptors.add(LogInterceptor(
      request: true,
      requestHeader: true,
      requestBody: true,
      responseHeader: true,
      responseBody: true,
      error: true,
    ));
  }

  // 错误处理
  void _handleError(DioException e) {
    String errorMessage = '';

    switch (e.type) {
      case DioExceptionType.connectionTimeout:
        errorMessage = '连接超时';
        break;
      case DioExceptionType.sendTimeout:
        errorMessage = '请求超时';
        break;
      case DioExceptionType.receiveTimeout:
        errorMessage = '响应超时';
        break;
      case DioExceptionType.badResponse:
        int? statusCode = e.response?.statusCode;
        if (statusCode == 401) {
          errorMessage = '未授权，请重新登录';
          // TODO: 跳转到登录页面
        } else {
          errorMessage = '服务器错误: $statusCode';
        }
        break;
      case DioExceptionType.cancel:
        errorMessage = '请求已取消';
        break;
      default:
        errorMessage = '网络错误，请检查网络连接';
        break;
    }

    print('请求错误: $errorMessage');
  }

  // 保存Token
  Future<void> saveToken(String token) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_tokenKey, token);
  }

  // 清除Token
  Future<void> clearToken() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(_tokenKey);
  }

  // GET请求
  Future<ApiResponse<T>> get<T>(
    String path, {
    Map<String, dynamic>? params,
    T Function(dynamic json)? fromJson,
    Options? options,
  }) async {
    try {
      final response = await _dio.get(
        path,
        queryParameters: params,
        options: options,
      );
      return ApiResponse<T>.fromJson(response.data, fromJson);
    } on DioException catch (e) {
      return _handleException<T>(e);
    }
  }

  // POST请求
  Future<ApiResponse<T>> post<T>(
    String path, {
    dynamic data,
    Map<String, dynamic>? params,
    T Function(dynamic json)? fromJson,
    Options? options,
  }) async {
    try {
      final response = await _dio.post(
        path,
        data: data,
        queryParameters: params,
        options: options,
      );
      return ApiResponse<T>.fromJson(response.data, fromJson);
    } on DioException catch (e) {
      return _handleException<T>(e);
    }
  }

  // PUT请求
  Future<ApiResponse<T>> put<T>(
    String path, {
    dynamic data,
    Map<String, dynamic>? params,
    T Function(dynamic json)? fromJson,
    Options? options,
  }) async {
    try {
      final response = await _dio.put(
        path,
        data: data,
        queryParameters: params,
        options: options,
      );
      return ApiResponse<T>.fromJson(response.data, fromJson);
    } on DioException catch (e) {
      return _handleException<T>(e);
    }
  }

  // DELETE请求
  Future<ApiResponse<T>> delete<T>(
    String path, {
    dynamic data,
    Map<String, dynamic>? params,
    T Function(dynamic json)? fromJson,
    Options? options,
  }) async {
    try {
      final response = await _dio.delete(
        path,
        data: data,
        queryParameters: params,
        options: options,
      );
      return ApiResponse<T>.fromJson(response.data, fromJson);
    } on DioException catch (e) {
      return _handleException<T>(e);
    }
  }

  // 统一异常处理
  ApiResponse<T> _handleException<T>(DioException e) {
    _handleError(e);
    if (e.response != null && e.response!.data is Map<String, dynamic>) {
      try {
        return ApiResponse<T>.fromJson(e.response!.data, null);
      } catch (_) {
        return ApiResponse(code: -1, message: '服务器错误');
      }
    }
    return ApiResponse(code: -1, message: '网络错误，请检查网络连接');
  }
}
