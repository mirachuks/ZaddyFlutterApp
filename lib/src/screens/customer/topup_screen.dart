import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../config/theme.dart';
import '../../widgets/index.dart';
import '../../providers/wallet_provider.dart';
import '../shared/payment_screen.dart' as shared;

class TopUpScreen extends ConsumerStatefulWidget {
  const TopUpScreen({Key? key}) : super(key: key);

  @override
  ConsumerState<TopUpScreen> createState() => _TopUpScreenState();
}

class _TopUpScreenState extends ConsumerState<TopUpScreen> {
  final _amountController = TextEditingController();
  String _selectedPaymentMethod = 'bank_transfer';
  bool _isProcessing = false;

  @override
  void dispose() {
    _amountController.dispose();
    super.dispose();
  }

  Future<void> _processTopUp() async {
    final rawAmount = _amountController.text.trim().replaceAll(',', '');
    final amount = double.tryParse(rawAmount);

    if (amount == null || amount <= 0) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please enter a valid amount')),
      );
      return;
    }

    // Instead of immediately topping up, navigate to the manual payment
    // confirmation screen where the user sees company account details and
    // can notify admin after completing a transfer.
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => shared.PaymentScreen(
          amount: amount,
          description: 'Top-up Wallet',
          jobId: null,
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Top Up Wallet'),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () => Navigator.pop(context),
        ),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(AppSpacing.lg),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Current Balance
            Container(
              padding: const EdgeInsets.all(AppSpacing.lg),
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: [AppColors.success, AppColors.success.withOpacity(0.7)],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
                borderRadius: BorderRadius.circular(AppBorderRadius.lg),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Current Balance',
                    style: AppTextStyles.labelMedium.copyWith(
                      color: AppColors.textInverse.withOpacity(0.9),
                    ),
                  ),
                  const SizedBox(height: AppSpacing.md),
                  ref.watch(walletProvider).when(
                        data: (wallet) => Text(
                          '₦${wallet.balance.toStringAsFixed(2)}',
                          style: AppTextStyles.displaySmall.copyWith(
                            color: AppColors.textInverse,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        loading: () => Text(
                          'Loading...',
                          style: AppTextStyles.displaySmall.copyWith(
                            color: AppColors.textInverse,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        error: (_, __) => Text(
                          'N/A',
                          style: AppTextStyles.displaySmall.copyWith(
                            color: AppColors.textInverse,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                ],
              ),
            ),
            const SizedBox(height: AppSpacing.xxxl),

            // Amount Input
            Text(
              'Enter Amount',
              style: AppTextStyles.labelMedium.copyWith(
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: AppSpacing.md),
            TextField(
              controller: _amountController,
              keyboardType: TextInputType.number,
              style: AppTextStyles.bodyLarge,
              decoration: InputDecoration(
                hintText: 'Enter amount to top up',
                hintStyle: AppTextStyles.bodyLarge.copyWith(
                  color: AppColors.textSecondary,
                ),
                prefixText: '₦ ',
                prefixStyle: AppTextStyles.bodyLarge.copyWith(
                  color: AppColors.textPrimary,
                  fontWeight: FontWeight.bold,
                ),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(AppBorderRadius.md),
                  borderSide: const BorderSide(
                    color: AppColors.border,
                  ),
                ),
                focusedBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(AppBorderRadius.md),
                  borderSide: const BorderSide(
                    color: AppColors.primary,
                    width: 2,
                  ),
                ),
              ),
            ),
            const SizedBox(height: AppSpacing.xxxl),

            // Payment Methods
            Text(
              'Payment Method',
              style: AppTextStyles.labelMedium.copyWith(
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: AppSpacing.md),
            _buildPaymentOption(
              'bank_transfer',
              Icons.account_balance,
              'Bank Transfer',
              'Direct transfer from your bank account',
            ),
            
            const SizedBox(height: AppSpacing.xxxl),

            // Quick Top Up Options
            Text(
              'Quick Top Up',
              style: AppTextStyles.labelMedium.copyWith(
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: AppSpacing.md),
            GridView.count(
              crossAxisCount: 3,
              mainAxisSpacing: AppSpacing.md,
              crossAxisSpacing: AppSpacing.md,
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              children: ['1,000', '2,000', '3,000', '5,000', '10,000', '20,000']
                  .map((amount) => _buildQuickAmount(amount))
                  .toList(),
            ),
            const SizedBox(height: AppSpacing.xxxl),

            // Top Up Button
            SizedBox(
              width: double.infinity,
              height: 56,
              child: ElevatedButton(
                onPressed: _isProcessing ? null : _processTopUp,
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.primary,
                  disabledBackgroundColor: AppColors.textSecondary,
                ),
                child: _isProcessing
                    ? const SizedBox(
                        height: 24,
                        width: 24,
                        child: CircularProgressIndicator(
                          valueColor:
                              AlwaysStoppedAnimation<Color>(Colors.white),
                          strokeWidth: 2,
                        ),
                      )
                    : Text(
                        'Proceed to Payment',
                        style: AppTextStyles.labelMedium.copyWith(
                          color: Colors.white,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildPaymentOption(
    String value,
    IconData icon,
    String title,
    String subtitle,
  ) {
    return InkWell(
      onTap: () {
        setState(() => _selectedPaymentMethod = value);
      },
      child: Container(
        padding: const EdgeInsets.all(AppSpacing.md),
        decoration: BoxDecoration(
          border: Border.all(
            color: _selectedPaymentMethod == value
                ? AppColors.primary
                : AppColors.border,
            width: _selectedPaymentMethod == value ? 2 : 1,
          ),
          borderRadius: BorderRadius.circular(AppBorderRadius.md),
        ),
        child: Row(
          children: [
            Container(
              width: 50,
              height: 50,
              decoration: BoxDecoration(
                color: AppColors.primary.withOpacity(0.1),
                borderRadius: BorderRadius.circular(AppBorderRadius.md),
              ),
              child: Center(
                child: Icon(icon, color: AppColors.primary),
              ),
            ),
            const SizedBox(width: AppSpacing.md),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: AppTextStyles.labelMedium.copyWith(
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  Text(
                    subtitle,
                    style: AppTextStyles.captionSmall.copyWith(
                      color: AppColors.textSecondary,
                    ),
                  ),
                ],
              ),
            ),
            if (_selectedPaymentMethod == value)
              Container(
                width: 24,
                height: 24,
                decoration: const BoxDecoration(
                  shape: BoxShape.circle,
                  color: AppColors.primary,
                ),
                child: const Center(
                  child: Icon(
                    Icons.check,
                    color: Colors.white,
                    size: 16,
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }

  Widget _buildQuickAmount(String amount) {
    return InkWell(
      onTap: () {
        _amountController.text = amount.replaceAll(',', '');
      },
      child: Container(
        decoration: BoxDecoration(
          border: Border.all(color: AppColors.border),
          borderRadius: BorderRadius.circular(AppBorderRadius.md),
        ),
        child: Center(
          child: Text(
            amount,
            style: AppTextStyles.labelMedium.copyWith(
              fontWeight: FontWeight.bold,
              color: AppColors.primary,
            ),
          ),
        ),
      ),
    );
  }
}
