import 'package:dio/dio.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'dart:developer' as developer;
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
  String? _cachedToken; // 添加缓存Token，避免频繁读取SharedPreferences

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
        final token = await getToken();
        developer.log('使用Token: $token', name: 'HttpUtil');

        if (token != null && token.isNotEmpty) {
          options.headers['Authorization'] = 'Bearer $token';
          developer.log('添加Authorization头: Bearer $token', name: 'HttpUtil');
        } else {
          developer.log('警告: 请求未携带Token', name: 'HttpUtil');
        }

        // 记录完整的请求头信息，方便调试
        developer.log('请求URL: ${options.uri}', name: 'HttpUtil');
        developer.log('请求方法: ${options.method}', name: 'HttpUtil');
        developer.log('请求头: ${options.headers}', name: 'HttpUtil');

        return handler.next(options);
      },
      onResponse: (response, handler) {
        developer.log('响应状态码: ${response.statusCode}', name: 'HttpUtil');
        return handler.next(response);
      },
      onError: (DioException e, handler) {
        // 详细记录错误信息
        if (e.response != null) {
          developer.log(
              '请求失败: ${e.response?.statusCode} - ${e.response?.statusMessage}',
              name: 'HttpUtil');
          developer.log('错误响应头: ${e.response?.headers}', name: 'HttpUtil');
          developer.log('错误响应体: ${e.response?.data}', name: 'HttpUtil');
        }
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

  // 获取Token，优先从缓存获取 (公开方法)
  Future<String?> getToken() async {
    if (_cachedToken != null) {
      return _cachedToken;
    }

    try {
      final prefs = await SharedPreferences.getInstance();
      _cachedToken = prefs.getString(_tokenKey);
      if (_cachedToken != null && _cachedToken!.isNotEmpty) {
        developer.log('从存储读取Token: $_cachedToken', name: 'HttpUtil');
      }
      return _cachedToken;
    } catch (e) {
      developer.log('获取Token异常: $e', name: 'HttpUtil');
      return null;
    }
  }

  // 添加带用户ID的请求路径
  String _appendUserIdToPath(String path) {
    // 检查是否是获取用户信息的API
    if (path == Api.userInfo) {
      return '$path?timestamp=${DateTime.now().millisecondsSinceEpoch}';
    }
    return path;
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
          _clearTokenAndCache(); // 清除无效Token
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

    developer.log('请求错误: $errorMessage', name: 'HttpUtil');
  }

  // 保存Token
  Future<void> saveToken(String token) async {
    try {
      // 检查token是否为空
      if (token.isEmpty) {
        developer.log('警告: 试图保存空Token', name: 'HttpUtil');
        return;
      }

      // 规范化token格式，移除可能的Bearer前缀和多余的空格
      String trimmedToken = token.trim();
      if (trimmedToken.toLowerCase().startsWith('bearer ')) {
        trimmedToken = trimmedToken.substring(7).trim();
        developer.log('Token已包含Bearer前缀，已移除', name: 'HttpUtil');
      }

      developer.log('保存处理后的Token: $trimmedToken', name: 'HttpUtil');

      final prefs = await SharedPreferences.getInstance();
      await prefs.setString(_tokenKey, trimmedToken);
      _cachedToken = trimmedToken; // 更新缓存
    } catch (e) {
      developer.log('保存Token异常: $e', name: 'HttpUtil');
    }
  }

  // 清除Token和缓存
  Future<void> clearToken() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.remove(_tokenKey);
      _cachedToken = null; // 清除缓存
      developer.log('Token已清除', name: 'HttpUtil');
    } catch (e) {
      developer.log('清除Token异常: $e', name: 'HttpUtil');
    }
  }

  // 清除Token和缓存（内部使用）
  void _clearTokenAndCache() {
    clearToken();
  }

  // GET请求
  Future<ApiResponse<T>> get<T>(
    String path, {
    Map<String, dynamic>? params,
    T Function(dynamic json)? fromJson,
    Options? options,
  }) async {
    try {
      // 处理特殊路径
      String processedPath = path;

      // 为用户信息API添加时间戳，避免缓存问题
      if (path == Api.userInfo) {
        processedPath = '$path?t=${DateTime.now().millisecondsSinceEpoch}';

        // 准备特殊的请求头
        options ??= Options();
        final token = await getToken();
        if (token != null && token.isNotEmpty) {
          // 尝试不同的token格式
          options.headers ??= {};
          options.headers!['Authorization'] = 'Bearer $token';

          // 添加额外的认证信息
          options.headers!['X-Auth-Token'] = token;

          developer.log('为/user/info接口添加特殊认证头', name: 'HttpUtil');
        }
      }

      developer.log('发送GET请求: $processedPath, 参数: $params', name: 'HttpUtil');
      final response = await _dio.get(
        processedPath,
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
      developer.log('发送POST请求: $path, 数据: $data', name: 'HttpUtil');
      final response = await _dio.post(
        path,
        data: data,
        queryParameters: params,
        options: options,
      );
      developer.log('POST响应: ${response.data}', name: 'HttpUtil');
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
