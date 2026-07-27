/// API Initialization and Setup
/// This file provides setup functions for initializing the API client and services

import 'package:shared_preferences/shared_preferences.dart';
import 'api_client.dart';
import 'api_service.dart';
import '../config/api_config.dart';

/// Initialize API client with proper configuration
Future<ApiClient> initializeApiClient() async {
  final apiClient = ApiClient();
  
  // Try to load stored auth token
  final prefs = await SharedPreferences.getInstance();
  final token = prefs.getString('auth_token');
  
  if (token != null && token.isNotEmpty) {
    apiClient.setAuthToken(token);
  }
  
  return apiClient;
}

/// Initialize high-level API service
Future<ApiService> initializeApiService() async {
  final apiClient = await initializeApiClient();
  return ApiService(apiClient: apiClient);
}

/// Get current API environment info
String getApiEnvironmentInfo() {
  return '''
API Configuration:
Environment: ${ApiConfig.environmentName}
Base URL: ${ApiConfig.baseUrl}
Timeout: ${ApiConfig.timeout.inSeconds}s
  ''';
}

/// Switch API environment (for testing purposes)
void switchApiEnvironment(ApiEnvironment environment) {
  ApiConfig.setEnvironment(environment);
  print('API Environment switched to: ${ApiConfig.environmentName}');
  print('New Base URL: ${ApiConfig.baseUrl}');
}
