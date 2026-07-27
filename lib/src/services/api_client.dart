import 'package:dio/dio.dart';
import 'package:logger/logger.dart';
import '../config/api_config.dart';

class ApiClient {
  final Dio _dio;
  final Logger _logger = Logger();

  String? _authToken;

  ApiClient({Dio? dio}) : _dio = dio ?? Dio() {
    _configureDio();
  }

  void _configureDio() {
    _dio.options = BaseOptions(
      baseUrl: ApiConfig.baseUrl,
      connectTimeout: ApiConfig.timeout,
      receiveTimeout: ApiConfig.timeout,
      sendTimeout: ApiConfig.timeout,
      contentType: 'application/json',
      headers: {
        'Accept': 'application/json',
      },
      validateStatus: (status) {
        // Don't throw on any status code - handle in methods
        return true;
      },
    );

    _dio.interceptors.add(
      InterceptorsWrapper(
        onRequest: (options, handler) {
          if (_authToken != null) {
            options.headers['Authorization'] = 'Bearer $_authToken';
          }
          // Ensure API expects JSON responses to avoid HTML redirects
          options.headers['Accept'] = options.headers['Accept'] ?? 'application/json';
          _logger.d('REQUEST: ${options.method} ${options.path}');
          return handler.next(options);
        },
        onResponse: (response, handler) {
          _logger.d(
              'RESPONSE: ${response.statusCode} ${response.requestOptions.path}');
          return handler.next(response);
        },
        onError: (error, handler) {
          _logger.e('ERROR: ${error.message}');
          return handler.next(error);
        },
      ),
    );
  }

  String _errorMessageFromResponse(Response response) {
    final data = response.data;
    if (data is Map<String, dynamic>) {
      if (data['message'] != null) {
        return data['message'].toString();
      }
      if (data['errors'] != null) {
        final errors = data['errors'];
        if (errors is Map<String, dynamic>) {
          final firstError = errors.values
              .expand((value) => value is List ? value : [value])
              .whereType<String>()
              .firstWhere((_) => true, orElse: () => 'Unknown API error');
          return firstError;
        }
        if (errors is List && errors.isNotEmpty) {
          return errors.first.toString();
        }
      }
      return data.toString();
    }

    // If API returned a list, return its first element as string.
    if (data is List && data.isNotEmpty) {
      return data.first.toString();
    }

    // If API returned an HTML page (for example: server error or debug page),
    // avoid showing large HTML blobs to users — return a concise message and log the HTML.
    if (data is String && data.isNotEmpty) {
      final trimmed = data.trimLeft();
      final lower = trimmed.length > 64 ? trimmed.substring(0, 64).toLowerCase() : trimmed.toLowerCase();
      if (lower.startsWith('<!doctype') || lower.startsWith('<html') || lower.contains('<html')) {
        // Log full HTML for debugging
        _logger.e('API returned HTML response: ${data.length} bytes');
        return 'Server error (unexpected HTML response)';
      }
      return data;
    }

    return 'Unknown API error';
  }

  void setAuthToken(String token) {
    _authToken = token;
  }

  void clearAuthToken() {
    _authToken = null;
  }

  // Authentication Endpoints
  // Login with optional auto-detection of user type
  Future<Response> login(String email, String password, {String? userType}) {
    if (userType == null || userType.isEmpty) {
      return _dio.post('/login', data: {
        'email': email,
        'password': password,
      });
    }

    // Route to correct endpoint based on user type if explicitly provided.
    final endpoint =
        userType.toLowerCase() == 'rider' ? '/rider/login' : '/user/login';
    return _dio.post(endpoint, data: {
      'email': email,
      'password': password,
      'user_type': userType,
    });
  }

  // Convenience methods for specific user types
  Future<Response> loginUser(String email, String password) {
    return _dio.post('/user/login', data: {
      'email': email,
      'password': password,
      'user_type': 'user',
    });
  }

  Future<Response> loginRider(String email, String password) {
    return _dio.post('/rider/login', data: {
      'email': email,
      'password': password,
      'user_type': 'rider',
    });
  }

  Future<Response> registerUser(dynamic data) {
    if (data is FormData) {
      final hasUserType = data.fields.any((entry) => entry.key == 'user_type');
      if (!hasUserType) {
        data.fields.add(const MapEntry('user_type', 'user'));
      }
    } else {
      data['user_type'] = data['user_type'] ?? 'user';
    }
    return _dio.post('/user/create', data: data);
  }

  Future<Response> registerRider(dynamic data) {
    if (data is FormData) {
      final hasUserType = data.fields.any((entry) => entry.key == 'user_type');
      if (!hasUserType) {
        data.fields.add(const MapEntry('user_type', 'rider'));
      }
    } else {
      data['user_type'] = 'rider';
    }
    return _dio.post('/user/create', data: data);
  }

  Future<Response> register(dynamic data) {
    if (data is FormData) {
      final hasUserType = data.fields.any((entry) => entry.key == 'user_type');
      if (!hasUserType) {
        data.fields.add(const MapEntry('user_type', 'rider'));
      }
    } else {
      final role = (data['user_type'] as String?)?.toLowerCase() ?? 'user';
      data['user_type'] = role;
    }
    return _dio.post('/user/create', data: data);
  }

  Future<Response> completeRiderRegistration(dynamic data) {
    return _dio.post('/riders', data: data);
  }

  Future<Response> logout() {
    return _dio.post('/user/logout');
  }

  // User Profile
  Future<Response> getUserProfile() {
    return _dio.get('/user/profile');
  }

  Future<Response> updateUserProfile(Map<String, dynamic> data) {
    // Try PUT first (RESTful update), if it fails the error handler will provide feedback
    return _dio.put('/user/profile', data: data);
  }

  Future<Response> resetPassword(String email) {
    return _dio.post('/user/reset-password', data: {'email': email});
  }

  Future<Response> verifyResetToken(String token, String newPassword) {
    return _dio.post('/user/verify-reset-token',
        data: {'token': token, 'password': newPassword});
  }

  // Jobs Endpoints
  Future<Response> createJob(Map<String, dynamic> jobData) {
    return _dio.post('/jobs', data: jobData);
  }

  Future<Response> getJobs({int page = 1, int limit = 20}) {
    return _dio.get('/jobs', queryParameters: {'page': page, 'limit': limit});
  }

  Future<Response> getJobDetails(String jobId) {
    return _dio.get('/jobs/$jobId');
  }

  Future<Response> getCustomerJobs(
      {required String userId, int page = 1, int limit = 20}) {
    return _dio.get('/my-jobs/$userId',
        queryParameters: {'page': page, 'limit': limit});
  }

  Future<Response> getRiderJobs(
      {required double latitude, required double longitude, int radius = 10}) {
    return _dio.get('/jobs/available', queryParameters: {
      'latitude': latitude,
      'longitude': longitude,
      'radius': radius,
    });
  }

  Future<Response> updateJobStatus(String jobId, String status) async {
    final response = await _dio.patch('/jobs/$jobId/status', data: {'status': status});
    if (response.statusCode != null && response.statusCode! >= 400) {
      throw Exception(_errorMessageFromResponse(response));
    }
    return response;
  }

  Future<Response> autoConfirmJob(String jobId) {
    return _dio.patch('/jobs/$jobId/auto-confirm');
  }

  Future<Response> acceptJob(String jobId) {
    return _dio.patch('/jobs/$jobId/accept');
  }

  Future<Response> cancelJob(String jobId) {
    return _dio.patch('/jobs/$jobId/cancel');
  }

  // Job Applications (Rider accepting jobs)
  Future<Response> applyForJob(String jobId, {Map<String, dynamic>? data}) {
    return _dio.post('/jobs/$jobId/applications', data: data ?? {});
  }

  Future<Response> getJobApplications(String jobId) {
    return _dio.get('/jobs/$jobId/applications');
  }

  Future<Response> updateJobApplicationStatus(
      String applicationId, String status) {
    return _dio.patch('/job-applications/$applicationId/status',
        data: {'status': status});
  }

  // Get rider's own job applications (jobs they've applied to)
  Future<Response> getRiderApplications({String? status}) {
    return _dio.get(
      '/job-applications/mine',
      queryParameters:
          status != null && status.isNotEmpty ? {'status': status} : null,
    );
  }

  /// Get the rider's latest active application (server returns single application or null)
  Future<Response> getRiderActiveApplication({String? status}) {
    return _dio.get(
      '/job-applications/mine/active',
      queryParameters:
          status != null && status.isNotEmpty ? {'status': status} : null,
    );
  }

  // Delivery/Pickup States
  Future<Response> updateDeliveryState(String jobId, String state) async {
    // Map delivery state updates to job status transitions on the API
    final response = await _dio.patch('/jobs/$jobId/status', data: {'status': state});
    if (response.statusCode != null && response.statusCode! >= 400) {
      throw Exception(_errorMessageFromResponse(response));
    }
    return response;
  }

  Future<Response> confirmDelivery(String jobId, String otp) {
    return _dio.post('/deliveries/$jobId/confirm', data: {'otp': otp});
  }

  // Rider Profile
  Future<Response> getRiderProfile(String riderId) {
    return _dio.get('/riders/$riderId');
  }

  Future<Response> getMyRiderProfile() {
    return _dio.get('/rider/me');
  }

  Future<Response> updateRiderProfile(String riderProfileId, Map<String, dynamic> data) {
    return _dio.put('/riders/$riderProfileId', data: data);
  }

  Future<Response> updateRiderBankDetails(String riderProfileId, Map<String, dynamic> data) {
    return _dio.patch('/riders/$riderProfileId/bank', data: data);
  }

  Future<Response> submitKYC(Map<String, dynamic> kycData) {
    return _dio.post('/riders/kyc', data: kycData);
  }

  Future<Response> getKYCStatus() {
    return _dio.get('/riders/kyc/status');
  }

  // Reviews & Ratings
  Future<Response> rateRider(String jobId, double rating, String? review) async {
    final response = await _dio.post('/reviews', data: {
      'job_id': jobId,
      'score': rating,
      'review': review,
    });
    if (response.statusCode != null && response.statusCode! >= 400) {
      throw Exception(_errorMessageFromResponse(response));
    }
    return response;
  }

  Future<Response> getRiderRatings(String riderId) {
    return _dio.get('/riders/$riderId/ratings');
  }

  // Escrow/Payment
  Future<Response> holdPayment(String jobId, double amount) {
    return _dio.post('/escrow/hold', data: {'job_id': jobId, 'amount': amount});
  }

  Future<Response> releasePayment(String jobId) {
    return _dio.post('/escrow/release', data: {'job_id': jobId});
  }

  Future<Response> refundPayment(String jobId, String reason) {
    return _dio
        .post('/escrow/refund', data: {'job_id': jobId, 'reason': reason});
  }

  // Generic HTTP Methods (for use with FormData and file uploads)
  Future<Response> post(
    String path, {
    dynamic data,
    Map<String, dynamic>? queryParameters,
    void Function(int, int)? onProgress,
    Options? options,
  }) {
    final requestOptions = options ?? Options();
    if (data is FormData) {
      requestOptions.contentType = 'multipart/form-data';
    }
    return _dio.post(
      path,
      data: data,
      queryParameters: queryParameters,
      onSendProgress: onProgress,
      options: requestOptions,
    );
  }

  Future<Response> get(
    String path, {
    Map<String, dynamic>? queryParameters,
  }) {
    return _dio.get(path, queryParameters: queryParameters);
  }

  Future<Response> patch(
    String path, {
    dynamic data,
    Map<String, dynamic>? queryParameters,
  }) {
    return _dio.patch(path, data: data, queryParameters: queryParameters);
  }

  Future<Response> put(
    String path, {
    dynamic data,
    Map<String, dynamic>? queryParameters,
  }) {
    return _dio.put(path, data: data, queryParameters: queryParameters);
  }

  // Escrow Endpoints
  Future<Response> refundEscrow(String jobId, String reason) {
    return _dio
        .post('/escrow/refund', data: {'job_id': jobId, 'reason': reason});
  }

  // Wallet Endpoints
  Future<Response> getWallet() {
    return _dio.get('/wallet/me');
  }

  Future<Response> getTransactions({int page = 1, int limit = 20}) {
    return _dio.get('/wallet/transactions',
        queryParameters: {'page': page, 'per_page': limit});
  }

  Future<Response> withdraw(double amount, Map<String, String> bankDetails) {
    return _dio.post('/wallet/withdraw', data: {
      'amount': amount,
      ...bankDetails,
    });
  }

  Future<Response> topUp(double amount) {
    return _dio.post('/wallet/topup', data: {
      'amount': amount,
      'purpose': 'topup',
    });
  }

  Future<Response> debitWallet(double amount, {String purpose = 'job_payment', String? jobId}) {
    return _dio.post('/wallet/debit', data: {
      'amount': amount,
      'purpose': purpose,
      if (jobId != null) 'job_id': jobId,
    });
  }

  // Messages/Chat
  Future<Response> getChatMessages(String userId,
      {int page = 1, int limit = 50}) {
    return _dio.get('/messages/$userId',
        queryParameters: {'page': page, 'limit': limit});
  }

  Future<Response> sendMessage(String receiverId, String message) {
    return _dio.post('/messages',
        data: {'receiver_id': receiverId, 'message': message});
  }

  Future<Response> getChatThreads() {
    return _dio.get('/messages/threads');
  }

  // Notifications
  Future<Response> getNotifications({int page = 1, int limit = 20}) {
    return _dio
        .get('/notifications', queryParameters: {'page': page, 'per_page': limit});
  }

  Future<Response> markNotificationAsRead(String notificationId) {
    return _dio.patch('/notifications/$notificationId/read');
  }
}
