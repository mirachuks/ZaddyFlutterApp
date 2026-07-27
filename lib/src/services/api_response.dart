import 'package:dio/dio.dart';

/// Unified API Response wrapper
class ApiResponse<T> {
  final bool success;
  final T? data;
  final String? message;
  final int? statusCode;
  final Map<String, dynamic>? errors;

  ApiResponse({
    required this.success,
    this.data,
    this.message,
    this.statusCode,
    this.errors,
  });

  factory ApiResponse.fromDioResponse(Response response) {
    try {
      final responseData = response.data as Map<String, dynamic>?;
      final isSuccess = response.statusCode != null &&
          response.statusCode! >= 200 &&
          response.statusCode! < 300;

      dynamic extractedData;
      if (isSuccess) {
        extractedData = responseData?['data'];
      } else {
        extractedData = null;
      }

      return ApiResponse(
        success: isSuccess,
        data: extractedData,
        message: responseData?['message'] as String?,
        statusCode: response.statusCode,
        errors: responseData?['errors'] as Map<String, dynamic>?,
      );
    } catch (e) {
      return ApiResponse(
        success: false,
        message: 'Failed to parse response',
        statusCode: response.statusCode,
      );
    }
  }

  factory ApiResponse.fromError(DioException error) {
    String message = 'An error occurred';

    if (error.response != null) {
      final data = error.response?.data as Map<String, dynamic>?;
      message = data?['message'] ?? error.message ?? message;
    } else {
      switch (error.type) {
        case DioExceptionType.connectionTimeout:
          message = 'Connection timeout. Please check your internet.';
          break;
        case DioExceptionType.receiveTimeout:
          message = 'Request timeout. Please try again.';
          break;
        case DioExceptionType.sendTimeout:
          message = 'Send timeout. Please try again.';
          break;
        case DioExceptionType.connectionError:
          message = 'Connection error. Please check your internet.';
          break;
        default:
          message = error.message ?? 'An error occurred';
      }
    }

    return ApiResponse(
      success: false,
      message: message,
      statusCode: error.response?.statusCode,
      errors: (error.response?.data as Map<String, dynamic>?)?['errors'],
    );
  }
}
