/// API Environment Configuration
/// This file manages API URLs for different environments

import 'package:flutter/foundation.dart';

enum ApiEnvironment {
  production,
  development,
  local,
}

class ApiConfig {
  static ApiEnvironment _environment = ApiEnvironment.production;

  /// Get the current API environment
  static ApiEnvironment get environment => _environment;

  /// Set the API environment
  static void setEnvironment(ApiEnvironment env) {
    _environment = env;
  }

  /// Get the base URL for the current environment
  static String get baseUrl {
    // Force the app to use the live API for now.
    return 'https://ugoconsult82.com/api';
  }

  /// Get a descriptive name for the environment
  static String get environmentName {
    switch (_environment) {
      case ApiEnvironment.production:
        return 'Production (Hosted)';
      case ApiEnvironment.development:
        return 'Development';
      case ApiEnvironment.local:
        return 'Local';
    }
  }

  /// Check if running in production
  static bool get isProduction => _environment == ApiEnvironment.production;

  /// Check if running in development
  static bool get isDevelopment => _environment == ApiEnvironment.development;

  /// Check if running in local mode
  static bool get isLocal => _environment == ApiEnvironment.local;

  /// Get timeout duration (shorter for local, longer for hosted due to latency)
  static Duration get timeout {
    return const Duration(seconds: 300);
  }
}


