import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'api_provider.dart';

// Update user profile using an AsyncNotifier with UserService dependency
class UpdateProfileAsyncNotifier extends AsyncNotifier<Map<String, dynamic>?> {
  @override
  Future<Map<String, dynamic>?> build() async {
    return null;
  }

  Future<void> updateProfile({
    required String firstName,
    required String lastName,
    required String phone,
  }) async {
    state = const AsyncValue.loading();
    try {
      final userService = await ref.read(userServiceProvider.future);
      final result = await userService.submitProfileUpdateRequest(
        firstName: firstName,
        lastName: lastName,
        phone: phone,
      );
      state = AsyncValue.data(result);
    } catch (e, stackTrace) {
      state = AsyncValue.error(e, stackTrace);
      rethrow;
    }
  }
}

// Provider for updating user profile
final updateUserProfileProvider = AsyncNotifierProvider<UpdateProfileAsyncNotifier, Map<String, dynamic>?>(() {
  return UpdateProfileAsyncNotifier();
});
