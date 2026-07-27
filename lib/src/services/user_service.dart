import 'package:shared_preferences/shared_preferences.dart';
import 'api_client.dart';
import '../models/index.dart';

class UserService {
  final ApiClient apiClient;
  final SharedPreferences preferences;

  UserService({required this.apiClient, required this.preferences});

  /// Get current user profile from API
  Future<User> getUserProfile() async {
    try {
      final response = await apiClient.getUserProfile();

      if (response.statusCode != 200) {
        throw Exception('Failed to fetch user profile: ${response.statusCode}');
      }

      final userData = response.data['user'] ?? response.data['data'];

      if (userData == null) {
        throw Exception('Invalid response format from server');
      }

      // Handle phone field - API may use 'phone', 'mobile_number', or 'mobile'
      String phoneValue = userData['phone'] ?? userData['mobile_number'] ?? userData['mobile'] ?? '';

      final user = User(
        id: userData['id']?.toString() ?? '',
        email: userData['email'] ?? '',
        firstName: userData['first_name'] ?? '',
        lastName: userData['last_name'] ?? '',
        phone: phoneValue,
        avatar: userData['avatar'],
        userType: (userData['user_type'] ?? 'customer').toLowerCase() == 'rider'
            ? UserType.rider
            : UserType.customer,
        kycStatus: userData['kyc_status'] != null
            ? (userData['kyc_status'].toString().toLowerCase() == 'approved'
                ? KYCStatus.approved
                : userData['kyc_status'].toString().toLowerCase() == 'rejected'
                    ? KYCStatus.rejected
                    : KYCStatus.pending)
            : KYCStatus.pending,
        isVerified: userData['is_verified'] == 1 || userData['is_verified'] == true || userData['is_verified'].toString().toLowerCase() == 'yes',
        createdAt: DateTime.tryParse(userData['created_at'] ?? '') ?? DateTime.now(),
        updatedAt: DateTime.tryParse(userData['updated_at'] ?? '') ?? DateTime.now(),
      );

      return user;
    } catch (e) {
      print('GET USER PROFILE ERROR: $e');
      rethrow;
    }
  }

  /// Update user profile
  Future<User> updateUserProfile({
    required String firstName,
    required String lastName,
    required String phone,
    String? email,
  }) async {
    try {
      final updateData = {
        'first_name': firstName,
        'last_name': lastName,
        'phone': phone,
        if (email != null && email.isNotEmpty) 'email': email,
      };

      final response = await apiClient.updateUserProfile(updateData);

      if (response.statusCode != 200) {
        throw Exception('Failed to update profile: ${response.statusCode}');
      }

      final userData = response.data['user'] ?? response.data['data'];

      if (userData == null) {
        throw Exception('Invalid response format from server');
      }

      // Handle phone field - API may use 'phone', 'mobile_number', or 'mobile'
      String phoneValue = userData['phone'] ?? userData['mobile_number'] ?? userData['mobile'] ?? phone;

      final user = User(
        id: userData['id']?.toString() ?? '',
        email: userData['email'] ?? email ?? '',
        firstName: userData['first_name'] ?? firstName,
        lastName: userData['last_name'] ?? lastName,
        phone: phoneValue,
        avatar: userData['avatar'],
        userType: (userData['user_type'] ?? 'customer').toLowerCase() == 'rider'
            ? UserType.rider
            : UserType.customer,
        kycStatus: userData['kyc_status'] != null
            ? (userData['kyc_status'].toString().toLowerCase() == 'approved'
                ? KYCStatus.approved
                : userData['kyc_status'].toString().toLowerCase() == 'rejected'
                    ? KYCStatus.rejected
                    : KYCStatus.pending)
            : KYCStatus.pending,
        isVerified: userData['is_verified'] == 1 || userData['is_verified'] == true || userData['is_verified'].toString().toLowerCase() == 'yes',
        createdAt: DateTime.tryParse(userData['created_at'] ?? '') ?? DateTime.now(),
        updatedAt: DateTime.tryParse(userData['updated_at'] ?? '') ?? DateTime.now(),
      );

      return user;
    } catch (e) {
      print('UPDATE USER PROFILE ERROR: $e');
      rethrow;
    }
  }

  /// Submit a profile update request for admin review
  Future<Map<String, dynamic>> submitProfileUpdateRequest({
    required String firstName,
    required String lastName,
    required String phone,
  }) async {
    try {
      final updateData = {
        'first_name': firstName,
        'last_name': lastName,
        'phone': phone,
      };

      final response = await apiClient.post(
        '/profile/update-request',
        data: updateData,
      );

      if (response.statusCode != 201 && response.statusCode != 200) {
        throw Exception('Failed to submit profile update request: ${response.statusCode}');
      }

      final result = response.data;

      if (result == null) {
        throw Exception('Invalid response format from server');
      }

      return result;
    } catch (e) {
      print('SUBMIT PROFILE UPDATE REQUEST ERROR: $e');
      rethrow;
    }
  }
}
