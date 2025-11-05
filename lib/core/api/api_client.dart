import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

/// API 响应模型
class ApiResponse<T> {
  final bool success;
  final T? data;
  final String? message;
  final String? error;

  ApiResponse({
    required this.success,
    this.data,
    this.message,
    this.error,
  });

  factory ApiResponse.fromJson(
    Map<String, dynamic> json,
    T Function(dynamic)? fromJsonT,
  ) {
    return ApiResponse(
      success: json['success'] ?? false,
      data: json['data'] != null && fromJsonT != null
          ? fromJsonT(json['data'])
          : json['data'] as T?,
      message: json['message'] as String?,
      error: json['error'] as String?,
    );
  }
}

/// API 客户端
class ApiClient {
  final Dio _dio;
  final String baseUrl;

  ApiClient({
    required this.baseUrl,
    Duration? timeout,
  }) : _dio = Dio(BaseOptions(
          baseUrl: baseUrl,
          connectTimeout: timeout ?? const Duration(seconds: 5), // 缩短连接超时
          receiveTimeout: timeout ?? const Duration(seconds: 10),
          headers: {
            'Content-Type': 'application/json',
          },
        ));

  /// GET 请求（带重试机制）
  Future<ApiResponse<T>> get<T>(
    String path, {
    Map<String, dynamic>? queryParameters,
    T Function(dynamic)? fromJsonT,
    int retryCount = 2, // 默认重试2次
  }) async {
    int attempts = 0;
    
    while (attempts <= retryCount) {
      try {
        final response = await _dio.get(path, queryParameters: queryParameters);
        
        // 打印响应信息用于调试（仅在成功时）
        if (attempts == 0) {
          print('API GET $path 响应状态: ${response.statusCode}');
        }
        
        // 检查响应格式
        if (response.data is Map<String, dynamic>) {
          final data = response.data as Map<String, dynamic>;
          // 如果响应已经是包装格式 {success, data, ...}
          if (data.containsKey('success')) {
            return ApiResponse.fromJson(data, fromJsonT);
          } else {
            // 如果响应直接是数据，包装它
            return ApiResponse<T>(
              success: true,
              data: fromJsonT != null ? fromJsonT(data) : data as T,
            );
          }
        } else {
          // 如果响应不是 Map，直接包装
          return ApiResponse<T>(
            success: true,
            data: fromJsonT != null ? fromJsonT(response.data) : response.data as T,
          );
        }
      } on DioException catch (e) {
        attempts++;
        
        // 如果是连接错误且还有重试次数，等待后重试
        if (e.type == DioExceptionType.connectionError && attempts <= retryCount) {
          print('API GET $path 连接失败，${attempts}/${retryCount + 1} 次尝试，等待重试...');
          await Future.delayed(Duration(milliseconds: 500 * attempts)); // 递增等待时间
          continue;
        }
        
        // 最后一次尝试或非连接错误，返回错误
        if (attempts > retryCount) {
          print('API GET $path 错误（已重试 $attempts 次）: ${e.message}');
          print('错误类型: ${e.type}');
        }
        
        return ApiResponse<T>(
          success: false,
          error: e.message ?? '未知错误',
        );
      } catch (e, stackTrace) {
        attempts++;
        if (attempts > retryCount) {
          print('API GET $path 异常: $e');
          print('堆栈跟踪: $stackTrace');
        }
        return ApiResponse<T>(
          success: false,
          error: e.toString(),
        );
      }
    }
    
    // 理论上不会到这里
    return ApiResponse<T>(
      success: false,
      error: '请求失败',
    );
  }

  /// POST 请求
  Future<ApiResponse<T>> post<T>(
    String path, {
    dynamic data,
    Map<String, dynamic>? queryParameters,
    T Function(dynamic)? fromJsonT,
  }) async {
    try {
      final response = await _dio.post(
        path,
        data: data,
        queryParameters: queryParameters,
      );
      return ApiResponse.fromJson(response.data, fromJsonT);
    } on DioException catch (e) {
      return ApiResponse(
        success: false,
        error: e.message,
      );
    }
  }

  /// PUT 请求
  Future<ApiResponse<T>> put<T>(
    String path, {
    dynamic data,
    Map<String, dynamic>? queryParameters,
    T Function(dynamic)? fromJsonT,
  }) async {
    try {
      final response = await _dio.put(
        path,
        data: data,
        queryParameters: queryParameters,
      );
      return ApiResponse.fromJson(response.data, fromJsonT);
    } on DioException catch (e) {
      return ApiResponse(
        success: false,
        error: e.message,
      );
    }
  }

  /// DELETE 请求
  Future<ApiResponse<T>> delete<T>(
    String path, {
    Map<String, dynamic>? queryParameters,
    T Function(dynamic)? fromJsonT,
  }) async {
    try {
      final response = await _dio.delete(
        path,
        queryParameters: queryParameters,
      );
      return ApiResponse.fromJson(response.data, fromJsonT);
    } on DioException catch (e) {
      return ApiResponse(
        success: false,
        error: e.message,
      );
    }
  }
}

/// API 客户端 Provider
final apiClientProvider = Provider<ApiClient>((ref) {
  return ApiClient(
    baseUrl: 'http://localhost:3001/api',
  );
});
