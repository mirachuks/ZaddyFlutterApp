import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../services/index.dart';

/// Provider for SharedPreferences (singleton)
final sharedPreferencesProvider = FutureProvider<SharedPreferences>((ref) async {
  return await SharedPreferences.getInstance();
});

/// Provider for ApiClient (singleton)
final apiClientProvider = FutureProvider<ApiClient>((ref) async {
  final apiClient = ApiClient();
  
  // Try to load stored auth token
  final prefs = await ref.watch(sharedPreferencesProvider.future);
  final token = prefs.getString('auth_token');
  
  if (token != null && token.isNotEmpty) {
    apiClient.setAuthToken(token);
  }
  
  return apiClient;
});

/// Provider for ApiService (singleton) - depends on ApiClient
final apiServiceProvider = FutureProvider<ApiService>((ref) async {
  final apiClient = await ref.watch(apiClientProvider.future);
  return ApiService(apiClient: apiClient);
});

/// Provider for RiderService (singleton) - depends on ApiClient
final riderServiceProvider = FutureProvider<RiderService>((ref) async {
  final apiClient = await ref.watch(apiClientProvider.future);
  return RiderService(apiClient: apiClient);
});

/// Provider for UserService (singleton) - depends on ApiClient and SharedPreferences
final userServiceProvider = FutureProvider<UserService>((ref) async {
  final apiClient = await ref.watch(apiClientProvider.future);
  final prefs = await ref.watch(sharedPreferencesProvider.future);
  return UserService(apiClient: apiClient, preferences: prefs);
});

/// Provider to manage auth token in SharedPreferences
final authTokenProvider = StateNotifierProvider<AuthTokenNotifier, String?>((ref) {
  return AuthTokenNotifier(ref);
});

class AuthTokenNotifier extends StateNotifier<String?> {
  final Ref ref;

  AuthTokenNotifier(this.ref) : super(null) {
    _loadToken();
  }

  Future<void> _loadToken() async {
    final prefs = await ref.read(sharedPreferencesProvider.future);
    state = prefs.getString('auth_token');
  }

  Future<void> setToken(String token) async {
    state = token;
    final prefs = await ref.read(sharedPreferencesProvider.future);
    await prefs.setString('auth_token', token);
    
    // Update API client with token
    final apiClient = await ref.read(apiClientProvider.future);
    apiClient.setAuthToken(token);
  }

  Future<void> clearToken() async {
    state = null;
    final prefs = await ref.read(sharedPreferencesProvider.future);
    await prefs.remove('auth_token');
    
    // Clear token from API client
    final apiClient = await ref.read(apiClientProvider.future);
    apiClient.clearAuthToken();
  }
}
