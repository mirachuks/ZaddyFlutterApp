import 'api_client.dart';
import '../models/index.dart';

class WalletService {
  final ApiClient apiClient;

  WalletService({required this.apiClient});

  Future<Wallet> getWallet() async {
    try {
      final data = (await apiClient.getWallet()).data;

      if (data == null || data is! Map<String, dynamic>) {
        throw Exception('Invalid wallet response from server');
      }

      return Wallet.fromJson(data);
    } catch (e) {
      rethrow;
    }
  }

  Future<List<Transaction>> getTransactions({int page = 1, int limit = 20}) async {
    try {
      final response = await apiClient.getTransactions(page: page, limit: limit);
      final responseData = response.data as Map<String, dynamic>?;
      final data = responseData?['data'];

      if (data is Map<String, dynamic> && data['data'] is List) {
        return (data['data'] as List)
            .whereType<Map<String, dynamic>>()
            .map(Transaction.fromJson)
            .toList();
      }

      if (data is List) {
        return data
            .whereType<Map<String, dynamic>>()
            .map(Transaction.fromJson)
            .toList();
      }

      return [];
    } catch (e) {
      rethrow;
    }
  }

  Future<List<AppNotification>> getNotifications({int page = 1, int limit = 20}) async {
    try {
      final response = await apiClient.getNotifications(page: page, limit: limit);
      final responseData = response.data as Map<String, dynamic>?;
      final data = responseData?['data'];

      if (data is Map<String, dynamic> && data['data'] is List) {
        return (data['data'] as List)
            .whereType<Map<String, dynamic>>()
            .map(AppNotification.fromJson)
            .toList();
      }

      if (data is List) {
        return data
            .whereType<Map<String, dynamic>>()
            .map(AppNotification.fromJson)
            .toList();
      }

      return [];
    } catch (e) {
      rethrow;
    }
  }

  Future<Withdrawal> withdraw(double amount, Map<String, String> bankDetails) async {
    final response = await apiClient.withdraw(amount, bankDetails);

    if (response.statusCode == null || response.statusCode! < 200 || response.statusCode! >= 300) {
      final message = response.data is Map<String, dynamic>
          ? response.data['message'] ?? 'Failed to request withdrawal'
          : 'Failed to request withdrawal';
      throw Exception(message);
    }

    final data = response.data is Map<String, dynamic>
        ? response.data['data'] as Map<String, dynamic>? ?? {}
        : <String, dynamic>{};

    return Withdrawal(
      id: data['id']?.toString() ?? '',
      walletId: data['wallet_id']?.toString() ?? '',
      amount: double.tryParse(data['amount']?.toString() ?? amount.toString()) ?? amount,
      bankName: bankDetails['bank_name'] ?? '',
      accountNumber: bankDetails['account_number'] ?? '',
      accountName: bankDetails['account_name'] ?? '',
      status: data['status']?.toString() ?? 'pending',
      createdAt: DateTime.tryParse(data['created_at']?.toString() ?? '') ?? DateTime.now(),
      updatedAt: DateTime.tryParse(data['updated_at']?.toString() ?? '') ?? DateTime.now(),
    );
  }

  Future<void> topUp(double amount) async {
    final response = await apiClient.topUp(amount);

    if (response.statusCode != 200 &&
        response.statusCode != 201 &&
        response.data?['status'] != 'success') {
      throw Exception(response.data?['message'] ?? 'Failed to top up wallet');
    }
  }

  Future<void> markNotificationRead(String id) async {
    try {
      await apiClient.markNotificationAsRead(id);
    } catch (e) {
      rethrow;
    }
  }

  Future<void> debit(double amount, {String purpose = 'job_payment', String? jobId}) async {
    final response = await apiClient.debitWallet(amount, purpose: purpose, jobId: jobId);

    if (response.statusCode != 200 && response.statusCode != 201) {
      final message = response.data is Map<String, dynamic>
          ? response.data['message'] ?? 'Failed to debit wallet'
          : 'Failed to debit wallet';
      throw Exception(message);
    }

    if (response.data is Map<String, dynamic> &&
        response.data['status'] == 'error') {
      throw Exception(response.data['message'] ?? 'Failed to debit wallet');
    }
  }

  Future<void> holdPayment(String jobId, double amount) async {
    try {
      await apiClient.holdPayment(jobId, amount);
    } catch (e) {
      rethrow;
    }
  }

  Future<void> releasePayment(String jobId) async {
    try {
      await apiClient.releasePayment(jobId);
    } catch (e) {
      rethrow;
    }
  }

  Future<void> refundPayment(String jobId, String reason) async {
    try {
      await apiClient.refundPayment(jobId, reason);
    } catch (e) {
      rethrow;
    }
  }
}
