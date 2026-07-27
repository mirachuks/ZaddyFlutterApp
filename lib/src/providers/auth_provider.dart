import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../models/index.dart';
import '../services/index.dart';
import 'api_provider.dart';

// Lazy-load Auth Service (depends on ApiClient which is lazy-loaded)
final authServiceProvider = FutureProvider<AuthService>((ref) async {
  final apiClient = await ref.watch(apiClientProvider.future);
  final prefs = await ref.watch(sharedPreferencesProvider.future);
  return AuthService(apiClient: apiClient, preferences: prefs);
});

final authStateProvider = StateNotifierProvider<AuthNotifier, AuthState>(
  (ref) => AuthNotifier(ref),
);

final isAuthenticatedProvider = Provider<bool>((ref) {
  return ref.watch(authStateProvider).isAuthenticated;
});

final currentUserProvider = Provider<User?>((ref) {
  return ref.watch(authStateProvider).user;
});

final currentRoleProvider = Provider<UserType?>((ref) {
  return ref.watch(authStateProvider).currentRole;
});

// Auth State and Notifier
class AuthState {
  final User? user;
  final String? token;
  final UserType? currentRole;
  final bool isLoading;
  final bool isInitialized;
  final String? error;
  final String kycStatus;

  AuthState({
    this.user,
    this.token,
    this.currentRole,
    this.isLoading = false,
    this.isInitialized = false,
    this.error,
    this.kycStatus = 'pending',
  });

  bool get isAuthenticated => user != null && token != null;

  AuthState copyWith({
    User? user,
    String? token,
    UserType? currentRole,
    bool? isLoading,
    bool? isInitialized,
    String? error,
    String? kycStatus,
  }) {
    return AuthState(
      user: user ?? this.user,
      token: token ?? this.token,
      currentRole: currentRole ?? this.currentRole,
      isLoading: isLoading ?? this.isLoading,
      isInitialized: isInitialized ?? this.isInitialized,
      error: error ?? this.error,
      kycStatus: kycStatus ?? this.kycStatus,
    );
  }
}

class AuthNotifier extends StateNotifier<AuthState> {
  final Ref ref;
  AuthService? _authService;
  bool _initialized = false;

  AuthNotifier(this.ref) : super(AuthState()) {
    // Start initialization in background without blocking
    Future.microtask(() => _initialize());
  }

  Future<void> _initialize() async {
    if (_initialized) return;
    _initialized = true;

    try {
      // Load services lazily in background
      _authService = await ref.read(authServiceProvider.future);
      
      await _authService!.initializeAuth();
      final token = _authService!.getStoredToken();
      final storedUser = _authService!.getStoredUser();

      if (token != null && storedUser != null) {
        // Restore user from localStorage
        state = state.copyWith(
          token: token,
          user: storedUser,
          currentRole: storedUser.userType,
          kycStatus: storedUser.kycStatus?.toString().split('.').last ?? 'pending',
          isInitialized: true,
        );
      } else {
        // No stored auth data
        state = state.copyWith(isInitialized: true);
      }
    } catch (e, _) {
      // Handle initialization errors gracefully without printing to console
      state = state.copyWith(
        isInitialized: true,
        error: e.toString(),
      );
    }
  }

  Future<void> login(String email, String password) async {
    // Ensure service is initialized
    _authService ??= await ref.read(authServiceProvider.future);
    
    state = state.copyWith(isLoading: true, error: null);
    try {
      final authResponse = await _authService!.login(email, password);
      state = state.copyWith(
        user: authResponse.user,
        token: authResponse.token,
        currentRole: authResponse.user.userType,
        kycStatus: authResponse.user.kycStatus?.toString().split('.').last ?? 'pending',
        isLoading: false,
      );
    } catch (e) {
      state = state.copyWith(
        isLoading: false,
        error: e.toString(),
      );
      rethrow;
    }
  }

  Future<void> register(Map<String, dynamic> data) async {
    _authService ??= await ref.read(authServiceProvider.future);
    
    state = state.copyWith(isLoading: true, error: null);
    try {
      final authResponse = await _authService!.register(data);
      state = state.copyWith(
        user: authResponse.user,
        token: authResponse.token,
        currentRole: authResponse.user.userType,
        kycStatus: authResponse.user.kycStatus?.toString().split('.').last ?? 'pending',
        isLoading: false,
      );
    } catch (e) {
      state = state.copyWith(
        isLoading: false,
        error: e.toString(),
      );
      rethrow;
    }
  }

  Future<void> setRole(UserType role) async {
    _authService ??= await ref.read(authServiceProvider.future);
    
    if (role == UserType.rider) {
      if (state.currentRole == UserType.customer) {
        throw Exception(
          'You are currently set up as a customer. '
          'Complete rider registration to switch roles.'
        );
      }
    }
    
    await _authService!.setUserRole(role == UserType.customer ? 'customer' : 'rider');
    state = state.copyWith(currentRole: role);
  }

  Future<void> completeRiderRegistration() async {
    _authService ??= await ref.read(authServiceProvider.future);
    await _authService!.markRiderRegistrationComplete();
    state = state.copyWith(currentRole: UserType.rider);
  }

  Future<void> logout() async {
    _authService ??= await ref.read(authServiceProvider.future);
    
    state = state.copyWith(isLoading: true);
    try {
      await _authService!.logout();
      state = AuthState();
    } catch (e) {
      state = state.copyWith(isLoading: false, error: e.toString());
      rethrow;
    }
  }
}
