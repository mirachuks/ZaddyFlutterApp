import 'package:shared_preferences/shared_preferences.dart';
import 'api_client.dart';
import '../models/index.dart';
import '../utils/form_data_utils.dart';

class AuthService {
  final ApiClient apiClient;
  final SharedPreferences preferences;

  AuthService({required this.apiClient, required this.preferences});

  Future<AuthResponse> login(String email, String password, {String? userType}) async {
    try {
      final response = await apiClient.login(email, password, userType: userType);

      // Check if response is successful
      if (response.statusCode != 200) {
        final message = response.data is Map ? response.data['message'] : 'Login failed';
        throw Exception(message ?? 'Login failed with status ${response.statusCode}');
      }

      // Handle different response formats
      var token = response.data['token'];
      var userData = response.data['user'];
      
      // If not found at top level, try 'data' wrapper
      if ((token == null || token.isEmpty) && response.data['data'] is Map) {
        final wrapped = response.data['data'] as Map;
        token = wrapped['token'] ?? token;
        userData = wrapped['user'] ?? userData;
      }
      
      if (token == null || token.isEmpty) {
        throw Exception('No authentication token received from API. Response: ${response.data}');
      }

      if (userData == null) {
        throw Exception('Invalid response format from server. Response: ${response.data}');
      }

      // Parse user data from Laravel response
      // Handle phone field - API may use 'phone', 'mobile_number', or 'mobile'
      String phoneValue = userData['phone'] ?? userData['mobile_number'] ?? userData['mobile'] ?? '';
      
      final riderProfile = userData['rider_profile'] ?? userData['riderProfile'];
      final user = User(
        id: userData['id']?.toString() ?? '',
        email: userData['email'] ?? email ?? '',
        firstName: userData['first_name'] ?? userData['firstName'] ?? '',
        lastName: userData['last_name'] ?? userData['lastName'] ?? '',
        phone: phoneValue,
        userType: (userData['user_type'] ?? 'user').toLowerCase() == 'rider' 
            ? UserType.rider 
            : UserType.customer,
        kycStatus: userData['kyc_status'] != null 
            ? (userData['kyc_status'].toString().toLowerCase() == 'approved' ? KYCStatus.approved : userData['kyc_status'].toString().toLowerCase() == 'rejected' ? KYCStatus.rejected : KYCStatus.pending)
            : KYCStatus.pending,
        isVerified: userData['is_verified'] == 1 || userData['is_verified'] == true || userData['is_verified'].toString().toLowerCase() == 'yes',
        riderProfileId: riderProfile is Map<String, dynamic> ? riderProfile['id']?.toString() : null,
        riderProfileStatus: riderProfile is Map<String, dynamic> ? riderProfile['status']?.toString() : null,
        createdAt: DateTime.tryParse(userData['created_at'] ?? '') ?? DateTime.now(),
        updatedAt: DateTime.tryParse(userData['updated_at'] ?? '') ?? DateTime.now(),
      );

      final authData = AuthResponse(token: token, user: user);
      
      // Save token
      apiClient.setAuthToken(authData.token);
      await preferences.setString('auth_token', authData.token);
      
      // Save user data
      await _saveUser(authData.user);
      
      return authData;
    } catch (e) {
      rethrow;
    }
  }

  Future<AuthResponse> register(Map<String, dynamic> data) async {
    try {
      final requestData = await FormDataUtils.prepareFormData(data);
      final response = await apiClient.register(requestData);
      
      // Check if response is successful
      if (response.statusCode != 200 && response.statusCode != 201) {
        final message = response.data is Map ? response.data['message'] : 'Registration failed';
        throw Exception(message ?? 'Registration failed with status ${response.statusCode}');
      }

      // Handle different response formats
      var token = response.data['token'];
      var userData = response.data['user'];
      
      // If not found at top level, try 'data' wrapper
      if ((token == null || token.isEmpty) && response.data['data'] is Map) {
        final wrapped = response.data['data'] as Map;
        token = wrapped['token'] ?? token;
        userData = wrapped['user'] ?? userData;
      }

      if (token == null || token.isEmpty) {
        throw Exception('No authentication token received from API. Response: ${response.data}');
      }

      if (userData == null) {
        throw Exception('Invalid response format from server. Response: ${response.data}');
      }

      // Parse user data from Laravel response
      // Handle phone field - API may use 'phone', 'mobile_number', or 'mobile'
      String phoneValue = userData['phone'] ?? userData['mobile_number'] ?? userData['mobile'] ?? (data['phone'] as String?) ?? (data['mobile_number'] as String?) ?? '';
      
      final riderProfile = userData['rider_profile'] ?? userData['riderProfile'];
      final user = User(
        id: userData['id']?.toString() ?? '',
        email: userData['email'] ?? (data['email'] as String?) ?? '',
        firstName: userData['first_name'] ?? userData['firstName'] ?? (data['first_name'] as String?) ?? '',
        lastName: userData['last_name'] ?? userData['lastName'] ?? (data['last_name'] as String?) ?? '',
        phone: phoneValue,
        userType: (userData['user_type'] ?? 'user').toLowerCase() == 'rider' 
            ? UserType.rider 
            : UserType.customer,
        kycStatus: userData['kyc_status'] != null 
            ? (userData['kyc_status'].toString().toLowerCase() == 'approved' ? KYCStatus.approved : userData['kyc_status'].toString().toLowerCase() == 'rejected' ? KYCStatus.rejected : KYCStatus.pending)
            : KYCStatus.pending,
        isVerified: userData['is_verified'] == 1 || userData['is_verified'] == true || userData['is_verified'].toString().toLowerCase() == 'yes',
        riderProfileId: riderProfile is Map<String, dynamic> ? riderProfile['id']?.toString() : null,
        riderProfileStatus: riderProfile is Map<String, dynamic> ? riderProfile['status']?.toString() : null,
        createdAt: DateTime.tryParse(userData['created_at'] ?? '') ?? DateTime.now(),
        updatedAt: DateTime.tryParse(userData['updated_at'] ?? '') ?? DateTime.now(),
      );

      final authData = AuthResponse(token: token, user: user);
      
      apiClient.setAuthToken(authData.token);
      await preferences.setString('auth_token', authData.token);
      await _saveUser(authData.user);
      
      return authData;
    } catch (e) {
      rethrow;
    }
  }

  Future<void> logout() async {
    try {
      await apiClient.logout();
    } finally {
      apiClient.clearAuthToken();
      await preferences.remove('auth_token');
      await preferences.remove('user_data');
    }
  }

  Future<void> resetPassword(String email) async {
    await apiClient.resetPassword(email);
  }

  Future<void> confirmPasswordReset(String token, String newPassword) async {
    await apiClient.verifyResetToken(token, newPassword);
  }

  Future<void> _saveUser(User user) async {
    await preferences.setString('user_data', _userToJson(user));
  }

  User? getStoredUser() {
    final userJson = preferences.getString('user_data');
    if (userJson == null) return null;
    return _userFromJson(userJson);
  }

  String? getStoredToken() {
    return preferences.getString('auth_token');
  }

  Future<void> initializeAuth() async {
    final token = getStoredToken();
    if (token != null) {
      apiClient.setAuthToken(token);
    }
  }

  Future<void> setUserRole(String role) async {
    await preferences.setString('user_role', role);
    if (role == 'customer') {
      // Reset rider registration on customer switch
      await preferences.remove('rider_registration_completed');
    }
  }

  String? getUserRole() {
    return preferences.getString('user_role');
  }

  Future<void> markRiderRegistrationComplete() async {
    await preferences.setBool('rider_registration_completed', true);
  }

  bool isRiderRegistrationComplete() {
    return preferences.getBool('rider_registration_completed') ?? false;
  }

  Future<void> clearRiderRegistration() async {
    await preferences.remove('rider_registration_completed');
  }

  String _userToJson(User user) {
    // Store essential user data with role indicator
    return '${user.id}|${user.email}|${user.firstName}|${user.lastName}|${user.phone}|${user.userType == UserType.rider ? 'rider' : 'customer'}|${user.kycStatus?.toString().split('.').last ?? 'pending'}|${user.isVerified}|${user.riderProfileId ?? ''}|${user.riderProfileStatus ?? ''}';
  }

  User? _userFromJson(String json) {
    // Parse stored user data
    try {
      final parts = json.split('|');
      if (parts.length < 6) return null;
      
      final userType = parts[5] == 'rider' ? UserType.rider : UserType.customer;
      final kycStatusStr = parts.length > 6 ? parts[6] : 'pending';
      final isVerified = parts.length > 7 ? parts[7] == 'true' : false;
      final riderProfileId = parts.length > 8 ? parts[8] : null;
      final riderProfileStatus = parts.length > 9 ? parts[9] : null;
      
      // Convert string to KYCStatus enum
      KYCStatus? kycStatus;
      if (kycStatusStr == 'approved') {
        kycStatus = KYCStatus.approved;
      } else if (kycStatusStr == 'rejected') {
        kycStatus = KYCStatus.rejected;
      } else {
        kycStatus = KYCStatus.pending;
      }
      
      return User(
        id: parts[0],
        email: parts[1],
        firstName: parts[2],
        lastName: parts[3],
        phone: parts[4],
        userType: userType,
        kycStatus: kycStatus,
        isVerified: isVerified,
        riderProfileId: riderProfileId?.isNotEmpty == true ? riderProfileId : null,
        riderProfileStatus: riderProfileStatus?.isNotEmpty == true ? riderProfileStatus : null,
        createdAt: DateTime.now(),
        updatedAt: DateTime.now(),
      );
    } catch (e) {
      return null;
    }
  }

  bool get isAuthenticated => getStoredToken() != null;
}

// String extension for capitalize
extension StringExtension on String {
  String capitalize() {
    if (isEmpty) return this;
    return this[0].toUpperCase() + substring(1).toLowerCase();
  }
}
