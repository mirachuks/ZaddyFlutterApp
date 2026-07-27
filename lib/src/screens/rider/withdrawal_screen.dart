import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../config/theme.dart';
import '../../models/index.dart';
import '../../widgets/index.dart';
import '../../providers/index.dart';

class RiderWithdrawalScreen extends ConsumerStatefulWidget {
  const RiderWithdrawalScreen({Key? key}) : super(key: key);

  @override
  ConsumerState<RiderWithdrawalScreen> createState() => _RiderWithdrawalScreenState();
}

class _RiderWithdrawalScreenState extends ConsumerState<RiderWithdrawalScreen> {
  final TextEditingController _amountController = TextEditingController();
  String _selectedPaymentMethod = 'bank_transfer';
  bool _isProcessing = false;
  double _minWithdrawal = 1000.0;
  double _withdrawalFee = 50.0; // ₦50 flat fee

  @override
  void dispose() {
    _amountController.dispose();
    super.dispose();
  }

  double _calculateTotal() {
    final amount = double.tryParse(_amountController.text) ?? 0;
    return amount > 0 ? amount + _withdrawalFee : 0;
  }

  void _submitWithdrawal() {
    final amount = double.tryParse(_amountController.text) ?? 0;
    final walletAsync = ref.read(walletProvider);
    final riderProfileAsync = ref.read(riderProfileProvider);
    final profile = riderProfileAsync.maybeWhen(
      data: (profile) => profile,
      orElse: () => null,
    );
    final hasBankDetails = profile?.hasBankDetails ?? false;

    if (!hasBankDetails) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: const Text('Please add your bank details before requesting a withdrawal.'),
          backgroundColor: AppColors.error,
        ),
      );
      return;
    }

    if (amount < _minWithdrawal) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Minimum withdrawal is ₦${_minWithdrawal.toStringAsFixed(0)}'),
          backgroundColor: AppColors.error,
        ),
      );
      return;
    }

    final walletBalance = walletAsync.maybeWhen(
      data: (wallet) => wallet.balance,
      orElse: () => 0.0,
    );

    final total = amount + _withdrawalFee;
    if (total > walletBalance) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: const Text('Insufficient balance to cover amount and fee'),
          backgroundColor: AppColors.error,
        ),
      );
      return;
    }

    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: const Text('Confirm Withdrawal'),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Amount: ₦${amount.toStringAsFixed(0)}',
                style: AppTextStyles.bodyMedium,
              ),
              const SizedBox(height: AppSpacing.sm),
              Text(
                'Fee: ₦${_withdrawalFee.toStringAsFixed(0)}',
                style: AppTextStyles.bodySmall,
              ),
              const SizedBox(height: AppSpacing.sm),
              Text(
                'Total: ₦${_calculateTotal().toStringAsFixed(0)}',
                style: AppTextStyles.labelMedium.copyWith(
                  color: AppColors.accent,
                ),
              ),
              const SizedBox(height: AppSpacing.md),
              Text(
                'Method: ${_getPaymentMethodName(profile)}',
                style: AppTextStyles.bodySmall,
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(),
              child: const Text('Cancel'),
            ),
            ElevatedButton(
              onPressed: () {
                Navigator.of(context).pop();
                _processWithdrawal(amount);
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.primary,
              ),
              child: const Text(
                'Confirm',
                style: TextStyle(color: Colors.white),
              ),
            ),
          ],
        );
      },
    );
  }

  Future<void> _processWithdrawal(double amount) async {
    setState(() => _isProcessing = true);

    try {
      final walletService = await ref.watch(walletServiceProvider.future);
      final riderProfileAsync = ref.read(riderProfileProvider);
      final profile = riderProfileAsync.maybeWhen(
        data: (profile) => profile,
        orElse: () => null,
      );

      final bankDetails = <String, String>{};
      if (_selectedPaymentMethod == 'bank_transfer') {
        if (profile == null) {
          throw Exception('Your bank details are not loaded yet.');
        }
        final accountName = [profile.firstName?.trim(), profile.lastName?.trim()]
            .where((value) => value != null && value.isNotEmpty)
            .join(' ')
            .trim();
        bankDetails['bank_name'] = profile.bankName ?? '';
        bankDetails['account_number'] = profile.bankAccountNumber ?? '';
        bankDetails['account_name'] = accountName.isNotEmpty ? accountName : (profile.bankAccountName ?? '');
      } else if (_selectedPaymentMethod == 'mobile_money') {
        bankDetails['bank_name'] = 'Mobile Money';
        bankDetails['account_number'] = '08031234567';
        final accountName = [profile?.firstName?.trim(), profile?.lastName?.trim()]
            .where((value) => value != null && value.isNotEmpty)
            .join(' ')
            .trim();
        bankDetails['account_name'] = accountName.isNotEmpty ? accountName : (profile?.bankAccountName ?? 'Zaddy Rider');
      } else {
        bankDetails['bank_name'] = 'Wallet Transfer';
        bankDetails['account_number'] = 'wallet';
        final accountName = [profile?.firstName?.trim(), profile?.lastName?.trim()]
            .where((value) => value != null && value.isNotEmpty)
            .join(' ')
            .trim();
        bankDetails['account_name'] = accountName.isNotEmpty ? accountName : (profile?.bankAccountName ?? 'Zaddy Rider');
      }

      final withdrawal = await walletService.withdraw(
        amount,
        bankDetails,
      );

      ref.invalidate(walletProvider);
      ref.invalidate(transactionsProvider(1));
      ref.invalidate(notificationsProvider(1));
      ref.invalidate(riderProfileProvider);

      if (!mounted) return;

      showDialog(
        context: context,
        builder: (BuildContext context) {
          return AlertDialog(
            icon: Icon(
              Icons.check_circle,
              color: AppColors.success,
              size: 64,
            ),
            title: const Text('Withdrawal Requested'),
            content: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                const SizedBox(height: AppSpacing.md),
                Text(
                  '₦${amount.toStringAsFixed(0)}',
                  style: AppTextStyles.headingSmall.copyWith(
                    color: AppColors.success,
                  ),
                ),
                const SizedBox(height: AppSpacing.md),
                Text(
                  withdrawal.id.isNotEmpty
                      ? 'Your withdrawal request has been submitted successfully.'
                      : 'Your withdrawal request has been submitted. It will be processed shortly.',
                  textAlign: TextAlign.center,
                  style: AppTextStyles.bodySmall,
                ),
                const SizedBox(height: AppSpacing.md),
                Text(
                  'Amount will be sent to your ${_getPaymentMethodName(profile)} account within 24hrs.',
                  textAlign: TextAlign.center,
                  style: AppTextStyles.captionSmall.copyWith(
                    color: AppColors.textSecondary,
                  ),
                ),
              ],
            ),
            actions: [
              ElevatedButton(
                onPressed: () {
                  Navigator.of(context).pop();
                  Navigator.of(context).pop();
                  _amountController.clear();
                },
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.primary,
                ),
                child: const Text(
                  'Done',
                  style: TextStyle(color: Colors.white),
                ),
              ),
            ],
          );
        },
      );
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Withdrawal failed: ${e.toString()}'),
            backgroundColor: AppColors.error,
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() => _isProcessing = false);
      }
    }
  }

  String _getPaymentMethodName(RiderProfile? profile) {
    if (_selectedPaymentMethod == 'bank_transfer') {
      final bank = profile?.bankName ?? 'Bank Transfer';
      final accountNumber = profile?.bankAccountNumber ?? 'XXXXXXXXXX';
      return '$bank - $accountNumber';
    }
    if (_selectedPaymentMethod == 'mobile_money') {
      return 'Mobile Money';
    }
    if (_selectedPaymentMethod == 'wallet') {
      return 'Wallet Transfer';
    }
    return 'Unknown';
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: const CustomAppBar(
        title: 'Withdraw Funds',
        showBackButton: true,
      ),
      body: Consumer(
        builder: (context, ref, child) {
          final walletAsync = ref.watch(walletProvider);
          
          final riderProfileAsync = ref.watch(riderProfileProvider);

          // Prepare a subtitle for the bank transfer option using the latest profile
          final bankTransferSubtitle = riderProfileAsync.maybeWhen(
            data: (p) => '${p.bankName ?? 'Bank Transfer'} - ${p.bankAccountNumber ?? 'XXXXXXXXXX'}',
            orElse: () => 'Bank Transfer - XXXXXXXXXX',
          );

          return SingleChildScrollView(
            padding: const EdgeInsets.all(AppSpacing.lg),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Current Balance
                CustomCard(
                  padding: const EdgeInsets.all(AppSpacing.lg),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Available Balance',
                        style: AppTextStyles.bodySmall.copyWith(
                          color: AppColors.textSecondary,
                        ),
                      ),
                      const SizedBox(height: AppSpacing.sm),
                      walletAsync.when(
                        data: (wallet) => Text(
                          '₦${wallet.balance.toStringAsFixed(0)}',
                          style: AppTextStyles.displaySmall.copyWith(
                            color: AppColors.accent,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        loading: () => const Text(
                          '₦0',
                          style: AppTextStyles.displaySmall,
                        ),
                        error: (_, __) => const Text(
                          '₦0',
                          style: AppTextStyles.displaySmall,
                        ),
                      ),
                      const SizedBox(height: AppSpacing.md),
                      Container(
                        padding: const EdgeInsets.all(AppSpacing.md),
                        decoration: BoxDecoration(
                          color: AppColors.info.withValues(alpha: 0.1),
                          borderRadius: BorderRadius.circular(AppBorderRadius.md),
                        ),
                        child: Row(
                          children: [
                            Icon(
                              Icons.info_outline,
                              color: AppColors.info,
                              size: 20,
                            ),
                            const SizedBox(width: AppSpacing.md),
                            Expanded(
                              child: Text(
                                'Minimum withdrawal: ₦${_minWithdrawal.toStringAsFixed(0)} | Fee: ₦${_withdrawalFee.toStringAsFixed(0)}',
                                style: AppTextStyles.bodySmall.copyWith(
                                  color: AppColors.info,
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: AppSpacing.xl),

                // Amount Input
                Text('Withdrawal Amount', style: AppTextStyles.labelLarge),
                const SizedBox(height: AppSpacing.md),
                CustomTextField(
                  controller: _amountController,
                  label: 'Amount (₦)',
                  hint: 'Enter amount to withdraw',
                  keyboardType: TextInputType.number,
                  onChanged: (value) => setState(() {}),
                ),
                const SizedBox(height: AppSpacing.md),
                Container(
                  padding: const EdgeInsets.all(AppSpacing.md),
                  decoration: BoxDecoration(
                    color: AppColors.grey50,
                    borderRadius: BorderRadius.circular(AppBorderRadius.md),
                  ),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Total Amount',
                            style: AppTextStyles.bodySmall.copyWith(
                              color: AppColors.textSecondary,
                            ),
                          ),
                          const SizedBox(height: AppSpacing.xs),
                          Text(
                            '₦${_calculateTotal().toStringAsFixed(0)}',
                            style: AppTextStyles.bodyLarge.copyWith(
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ],
                      ),
                      Icon(
                        Icons.arrow_forward,
                        color: AppColors.primary,
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: AppSpacing.xl),

                // Payment Method Selection
                Text('Withdrawal Method', style: AppTextStyles.labelLarge),
                const SizedBox(height: AppSpacing.md),
                _buildPaymentMethodOption(
                  value: 'bank_transfer',
                  title: 'To Account',
                  subtitle: bankTransferSubtitle,
                  icon: Icons.account_balance,
                ),
                
                const SizedBox(height: AppSpacing.xl),

                // Terms
                Container(
                  padding: const EdgeInsets.all(AppSpacing.md),
                  decoration: BoxDecoration(
                    color: AppColors.warning.withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(AppBorderRadius.md),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Important Information',
                        style: AppTextStyles.labelSmall.copyWith(
                          color: AppColors.warning,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                  const SizedBox(height: AppSpacing.sm),
                  Text(
                    '• Withdrawals are processed within 24hrs\n• A ₦50 flat fee applies to all withdrawals\n• Ensure your bank details are correct\n• Contact support if withdrawal is delayed',
                    style: AppTextStyles.bodySmall.copyWith(
                      color: AppColors.warning,
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: AppSpacing.xl),

            // Submit Button
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: _isProcessing ||
                        _amountController.text.isEmpty ||
                        (double.tryParse(_amountController.text) ?? 0) <= 0
                    ? null
                    : _submitWithdrawal,
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.primary,
                  disabledBackgroundColor: AppColors.textTertiary,
                  padding: const EdgeInsets.symmetric(vertical: 16),
                ),
                child: _isProcessing
                    ? const SizedBox(
                        height: 20,
                        width: 20,
                        child: CircularProgressIndicator(
                          strokeWidth: 2,
                          valueColor: AlwaysStoppedAnimation<Color>(
                            Colors.white,
                          ),
                        ),
                      )
                    : Text(
                        'Submit Withdrawal',
                        style: AppTextStyles.labelLarge.copyWith(
                          color: Colors.white,
                        ),
                      ),
              ),
            ),
              ],
            ),
          );
        },
      ),
    );
  }

  Widget _buildPaymentMethodOption({
    required String value,
    required String title,
    required String subtitle,
    required IconData icon,
  }) {
    final isSelected = _selectedPaymentMethod == value;

    return GestureDetector(
      onTap: () => setState(() => _selectedPaymentMethod = value),
      child: Container(
        padding: const EdgeInsets.all(AppSpacing.md),
        decoration: BoxDecoration(
          border: Border.all(
            color: isSelected ? AppColors.primary : AppColors.border,
            width: isSelected ? 2 : 1,
          ),
          borderRadius: BorderRadius.circular(AppBorderRadius.md),
          color: isSelected
              ? AppColors.primary.withValues(alpha: 0.05)
              : Colors.transparent,
        ),
        child: Row(
          children: [
            Container(
              width: 44,
              height: 44,
              decoration: BoxDecoration(
                color: isSelected
                    ? AppColors.primary.withValues(alpha: 0.1)
                    : AppColors.grey50,
                borderRadius: BorderRadius.circular(AppBorderRadius.md),
              ),
              child: Center(
                child: Icon(
                  icon,
                  color: isSelected ? AppColors.primary : AppColors.textTertiary,
                  size: 22,
                ),
              ),
            ),
            const SizedBox(width: AppSpacing.md),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: AppTextStyles.bodyMedium.copyWith(
                      fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
                    ),
                  ),
                  const SizedBox(height: AppSpacing.xs),
                  Text(
                    subtitle,
                    style: AppTextStyles.bodySmall.copyWith(
                      color: AppColors.textSecondary,
                    ),
                  ),
                ],
              ),
            ),
            if (isSelected)
              Icon(
                Icons.check_circle,
                color: AppColors.primary,
                size: 24,
              ),
          ],
        ),
      ),
    );
  }
}
