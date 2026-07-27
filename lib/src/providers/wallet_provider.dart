import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../models/index.dart';
import '../services/index.dart';
import 'api_provider.dart';
import 'auth_provider.dart';

/// Provide a ready-to-use `WalletService` by resolving the underlying `ApiClient`.
final walletServiceProvider = FutureProvider<WalletService>((ref) async {
  final apiClient = await ref.watch(apiClientProvider.future);
  return WalletService(apiClient: apiClient);
});

final walletProvider = FutureProvider<Wallet>((ref) async {
  final authState = ref.watch(authStateProvider);

  if (!authState.isAuthenticated) {
    throw Exception('User is not authenticated');
  }

  final walletService = await ref.watch(walletServiceProvider.future);
  return walletService.getWallet();
});

final transactionsProvider = FutureProvider.family<List<Transaction>, int>((ref, page) async {
  final walletService = await ref.watch(walletServiceProvider.future);
  return walletService.getTransactions(page: page);
});

final notificationsProvider = FutureProvider.family<List<AppNotification>, int>((ref, page) async {
  final walletService = await ref.watch(walletServiceProvider.future);
  return walletService.getNotifications(page: page);
});

final withdrawalProvider = StateNotifierProvider<WithdrawalNotifier, WithdrawalState>(
  (ref) => WithdrawalNotifier(ref),
);

class WithdrawalState {
  final bool isLoading;
  final String? error;
  final Withdrawal? withdrawal;

  WithdrawalState({
    this.isLoading = false,
    this.error,
    this.withdrawal,
  });

  WithdrawalState copyWith({
    bool? isLoading,
    String? error,
    Withdrawal? withdrawal,
  }) {
    return WithdrawalState(
      isLoading: isLoading ?? this.isLoading,
      error: error ?? this.error,
      withdrawal: withdrawal ?? this.withdrawal,
    );
  }
}

class WithdrawalNotifier extends StateNotifier<WithdrawalState> {
  final Ref ref;

  WithdrawalNotifier(this.ref) : super(WithdrawalState());

  Future<void> withdraw(double amount, Map<String, String> bankDetails) async {
    state = state.copyWith(isLoading: true, error: null);
    try {
      final walletService = await ref.watch(walletServiceProvider.future);
      final withdrawal = await walletService.withdraw(amount, bankDetails);
      state = state.copyWith(
        isLoading: false,
        withdrawal: withdrawal,
      );
    } catch (e) {
      state = state.copyWith(
        isLoading: false,
        error: e.toString(),
      );
      rethrow;
    }
  }

  void reset() {
    state = WithdrawalState();
  }
}
