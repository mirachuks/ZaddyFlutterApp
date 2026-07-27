import 'api_client.dart';
import '../models/index.dart';
import '../utils/form_data_utils.dart';

class RiderService {
  final ApiClient apiClient;

  RiderService({required this.apiClient});

  Future<User> getRiderProfile(String riderId) async {
    try {
      final response = await apiClient.getRiderProfile(riderId);
      return User(
        id: riderId,
        email: response.data['data']['email'] ?? '',
        firstName: response.data['data']['first_name'] ?? '',
        lastName: response.data['data']['last_name'] ?? '',
        phone: response.data['data']['phone'] ?? '',
        userType: UserType.rider,
        kycStatus: response.data['data']['kyc_status'] ?? 'pending',
        createdAt: DateTime.now(),
        updatedAt: DateTime.now(),
      );
    } catch (e) {
      rethrow;
    }
  }

  Future<RiderProfile> getMyRiderProfile() async {
    try {
      final response = await apiClient.getMyRiderProfile();
      if (response.statusCode != 200) {
        throw Exception('Failed to fetch rider profile: ${response.statusCode}');
      }
      final data = response.data['data'] ?? response.data;
      if (data == null || data is! Map<String, dynamic>) {
        throw Exception('Invalid rider profile response');
      }
      return RiderProfile.fromJson(data);
    } catch (e) {
      rethrow;
    }
  }

  Future<void> updateRiderProfile(String riderProfileId, Map<String, dynamic> data) async {
    try {
      await apiClient.updateRiderProfile(riderProfileId, data);
    } catch (e) {
      rethrow;
    }
  }

  Future<RiderProfile> updateRiderBankDetails(String riderProfileId, Map<String, dynamic> data) async {
    try {
      final response = await apiClient.updateRiderBankDetails(riderProfileId, data);
      if (response.statusCode != 200) {
        throw Exception('Failed to update bank details: ${response.statusCode}');
      }
      final dataJson = response.data['data'] ?? response.data;
      if (dataJson == null || dataJson is! Map<String, dynamic>) {
        throw Exception('Invalid bank details response');
      }
      return RiderProfile.fromJson(dataJson);
    } catch (e) {
      rethrow;
    }
  }

  Future<void> completeRegistration(Map<String, dynamic> data) async {
    try {
      final requestData = await FormDataUtils.prepareFormData(data);
      final response = await apiClient.completeRiderRegistration(requestData);

      if (response.statusCode != null && response.statusCode! >= 400) {
        final rawData = response.data;
        final message = rawData is Map
            ? (rawData['message'] ?? 'Registration failed')
            : 'Registration failed';

        if (rawData is Map && rawData['errors'] != null) {
          final errors = rawData['errors'];
          throw Exception('$message: ${errors.toString()}');
        }

        throw Exception(message);
      }
    } catch (e) {
      rethrow;
    }
  }

  Future<void> submitKYC(Map<String, dynamic> kycData) async {
    try {
      await apiClient.submitKYC(kycData);
    } catch (e) {
      rethrow;
    }
  }

  Future<String> getKYCStatus() async {
    try {
      final response = await apiClient.getKYCStatus();
      return response.data['status'];
    } catch (e) {
      rethrow;
    }
  }

  Future<List<dynamic>> getRiderRatings(String riderId) async {
    try {
      final response = await apiClient.getRiderRatings(riderId);
      return response.data['data'] ?? [];
    } catch (e) {
      rethrow;
    }
  }
}
