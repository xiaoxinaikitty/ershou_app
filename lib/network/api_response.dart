/// API响应模型类
class ApiResponse<T> {
  final int code;
  final T? data;
  final String? message;

  ApiResponse({required this.code, this.data, this.message});

  factory ApiResponse.fromJson(
      Map<String, dynamic> json, T Function(dynamic json)? fromJsonT) {
    return ApiResponse(
      code: json['code'] as int,
      data:
          json.containsKey('data') && json['data'] != null && fromJsonT != null
              ? fromJsonT(json['data'])
              : json['data'],
      message: json['message'] as String?,
    );
  }

  bool get isSuccess => code == 0;
}
