class RiderProfile {
  final String id;
  final String userId;
  final String? firstName;
  final String? lastName;
  final String? bankAccountName;
  final String? bankAccountNumber;
  final String? bankName;
  final String? bankCode;
  final String? status;
  final DateTime? createdAt;
  final DateTime? updatedAt;

  RiderProfile({
    required this.id,
    required this.userId,
    this.firstName,
    this.lastName,
    this.bankAccountName,
    this.bankAccountNumber,
    this.bankName,
    this.bankCode,
    this.status,
    this.createdAt,
    this.updatedAt,
  });

  bool get hasBankDetails {
    return bankAccountNumber?.isNotEmpty == true && bankName?.isNotEmpty == true;
  }

  factory RiderProfile.fromJson(Map<String, dynamic> json) {
    final payload = json['data'] is Map<String, dynamic> ? json['data'] as Map<String, dynamic> : json;
    final userPayload = payload['user'] is Map<String, dynamic>
        ? payload['user'] as Map<String, dynamic>
        : (payload['user'] is Map ? Map<String, dynamic>.from(payload['user'] as Map) : null);

    final firstName = payload['first_name']?.toString() ?? userPayload?['first_name']?.toString();
    final lastName = payload['last_name']?.toString() ?? userPayload?['last_name']?.toString();

    return RiderProfile(
      id: payload['id']?.toString() ?? '',
      userId: payload['user_id']?.toString() ?? '',
      firstName: firstName,
      lastName: lastName,
      bankAccountName: payload['bank_account_name']?.toString(),
      bankAccountNumber: payload['bank_account_number']?.toString(),
      bankName: payload['bank_name']?.toString(),
      bankCode: payload['bank_code']?.toString(),
      status: payload['status']?.toString(),
      createdAt: DateTime.tryParse(payload['created_at']?.toString() ?? ''),
      updatedAt: DateTime.tryParse(payload['updated_at']?.toString() ?? ''),
    );
  }
}
