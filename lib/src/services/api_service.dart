import 'package:dio/dio.dart';
import 'api_client.dart';
import 'api_response.dart';
import '../config/api_config.dart';

/// High-level API service that wraps ApiClient and provides standardized responses
class ApiService {
  final ApiClient apiClient;

  ApiService({required this.apiClient});

  // ==================== AUTHENTICATION ====================

  Future<ApiResponse> loginUser(String email, String password) async {
    try {
      final response = await apiClient.login(email, password);
      final apiResp = ApiResponse.fromDioResponse(response);

      if (apiResp.success && apiResp.data != null) {
        final token = apiResp.data?['token'] ?? response.data?['token'];
        if (token != null) {
          apiClient.setAuthToken(token);
        }
      }
      return apiResp;
    } on DioException catch (e) {
      return ApiResponse.fromError(e);
    } catch (e) {
      return ApiResponse(
        success: false,
        message: 'Unexpected error: ${e.toString()}',
      );
    }
  }

  Future<ApiResponse> registerUser(Map<String, dynamic> data) async {
    try {
      final response = await apiClient.register(data);
      return ApiResponse.fromDioResponse(response);
    } on DioException catch (e) {
      return ApiResponse.fromError(e);
    } catch (e) {
      return ApiResponse(
        success: false,
        message: 'Unexpected error: ${e.toString()}',
      );
    }
  }

  Future<ApiResponse> logout() async {
    try {
      final response = await apiClient.logout();
      apiClient.clearAuthToken();
      return ApiResponse.fromDioResponse(response);
    } on DioException catch (e) {
      return ApiResponse.fromError(e);
    } catch (e) {
      return ApiResponse(
        success: false,
        message: 'Unexpected error: ${e.toString()}',
      );
    }
  }

  // ==================== JOBS ====================

  Future<ApiResponse> getAvailableJobs({
    required double latitude,
    required double longitude,
    int radius = 10,
  }) async {
    try {
      final response = await apiClient.getRiderJobs(
        latitude: latitude,
        longitude: longitude,
        radius: radius,
      );
      return ApiResponse.fromDioResponse(response);
    } on DioException catch (e) {
      return ApiResponse.fromError(e);
    } catch (e) {
      return ApiResponse(
        success: false,
        message: 'Unexpected error: ${e.toString()}',
      );
    }
  }

  Future<ApiResponse> createJob(Map<String, dynamic> jobData) async {
    try {
      final response = await apiClient.createJob(jobData);
      return ApiResponse.fromDioResponse(response);
    } on DioException catch (e) {
      return ApiResponse.fromError(e);
    } catch (e) {
      return ApiResponse(
        success: false,
        message: 'Unexpected error: ${e.toString()}',
      );
    }
  }

  Future<ApiResponse> getJobDetails(String jobId) async {
    try {
      final response = await apiClient.getJobDetails(jobId);
      return ApiResponse.fromDioResponse(response);
    } on DioException catch (e) {
      return ApiResponse.fromError(e);
    } catch (e) {
      return ApiResponse(
        success: false,
        message: 'Unexpected error: ${e.toString()}',
      );
    }
  }

  // ==================== RIDERS ====================

  Future<ApiResponse> getRiderProfile(String riderId) async {
    try {
      final response = await apiClient.getRiderProfile(riderId);
      return ApiResponse.fromDioResponse(response);
    } on DioException catch (e) {
      return ApiResponse.fromError(e);
    } catch (e) {
      return ApiResponse(
        success: false,
        message: 'Unexpected error: ${e.toString()}',
      );
    }
  }

  Future<ApiResponse> updateRiderProfile(String riderProfileId, Map<String, dynamic> data) async {
    try {
      final response = await apiClient.updateRiderProfile(riderProfileId, data);
      return ApiResponse.fromDioResponse(response);
    } on DioException catch (e) {
      return ApiResponse.fromError(e);
    } catch (e) {
      return ApiResponse(
        success: false,
        message: 'Unexpected error: ${e.toString()}',
      );
    }
  }

  // ==================== WALLET ====================

  Future<ApiResponse> getWallet() async {
    try {
      final response = await apiClient.getWallet();
      return ApiResponse.fromDioResponse(response);
    } on DioException catch (e) {
      return ApiResponse.fromError(e);
    } catch (e) {
      return ApiResponse(
        success: false,
        message: 'Unexpected error: ${e.toString()}',
      );
    }
  }

  Future<ApiResponse> withdraw(
    double amount,
    Map<String, String> bankDetails,
  ) async {
    try {
      final response = await apiClient.withdraw(amount, bankDetails);
      return ApiResponse.fromDioResponse(response);
    } on DioException catch (e) {
      return ApiResponse.fromError(e);
    } catch (e) {
      return ApiResponse(
        success: false,
        message: 'Unexpected error: ${e.toString()}',
      );
    }
  }

  // ==================== UTILITY ====================

  /// Set API environment and base URL
  void setEnvironment(String baseUrl) {
    // This allows dynamic URL changes if needed
  }

  /// Get current API base URL
  String getCurrentApiUrl() {
    return ApiConfig.baseUrl;
  }
}
