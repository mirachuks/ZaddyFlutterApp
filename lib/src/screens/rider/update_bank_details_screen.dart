import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../config/theme.dart';
import '../../providers/index.dart';
import '../../widgets/index.dart';

class UpdateBankDetailsScreen extends ConsumerStatefulWidget {
  const UpdateBankDetailsScreen({Key? key}) : super(key: key);

  @override
  ConsumerState<UpdateBankDetailsScreen> createState() =>
      _UpdateBankDetailsScreenState();
}

class _UpdateBankDetailsScreenState
    extends ConsumerState<UpdateBankDetailsScreen> {
  final TextEditingController _accountNameController =
      TextEditingController(text: '');
  final TextEditingController _accountNumberController =
      TextEditingController(text: '');
  final TextEditingController _bankNameController =
      TextEditingController(text: 'GTBank');
  String _selectedBank = 'GTBank';
  bool _isSubmitting = false;
  bool _isInitialized = false;

  final List<String> _banks = [
    'GTBank',
    'Access Bank',
    'First Bank',
    'Zenith Bank',
    'Opay',
    'PalmPay',
    'Union Bank',
    'Sterling Bank',
    'Keystone Bank',
    'UBA',
    'Fidelity Bank',
  ];

  void _submitChanges() {
    if (_bankNameController.text.isEmpty ||
        _accountNumberController.text.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please fill all required fields.')),
      );
      return;
    }

    // Show confirmation dialog
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Save Bank Details'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Account Name: ${_accountNameController.text}'),
            const SizedBox(height: AppSpacing.md),
            Text('Bank: ${_bankNameController.text}'),
            const SizedBox(height: AppSpacing.md),
            Text('Account Number: ${_accountNumberController.text}'),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () {
              Navigator.pop(context);
              _processSubmission();
            },
            child: const Text('Save'),
          ),
        ],
      ),
    );
  }

  Future<void> _processSubmission() async {
    setState(() => _isSubmitting = true);

    try {
      final riderService = await ref.watch(riderServiceProvider.future);
      final profileValue = ref.read(riderProfileProvider);
      final profile = profileValue.maybeWhen(
        data: (profile) => profile,
        orElse: () => null,
      );

      if (profile == null) {
        throw Exception('Unable to load your rider profile.');
      }

      final bankAccountName = [profile.firstName?.trim(), profile.lastName?.trim()]
          .where((s) => s != null && s.isNotEmpty)
          .join(' ')
          .trim();
      final bankAccountNumber = _accountNumberController.text.trim();
      final bankName = _bankNameController.text.trim();

      if (bankAccountName.isEmpty) {
        throw Exception('Account name is required from profile.');
      }

      await riderService.updateRiderBankDetails(profile.id, {
        'bank_account_name': bankAccountName,
        'bank_name': bankName,
        'bank_account_number': bankAccountNumber,
      });

      ref.invalidate(riderProfileProvider);

      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Bank details saved successfully.'),
          backgroundColor: AppColors.success,
        ),
      );

      Navigator.of(context).pop();
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Failed to save bank details: ${e.toString()}'),
            backgroundColor: AppColors.error,
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() => _isSubmitting = false);
      }
    }
  }

  @override
  void dispose() {
    _accountNameController.dispose();
    _accountNumberController.dispose();
    _bankNameController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final riderProfileAsync = ref.watch(riderProfileProvider);

    riderProfileAsync.whenData((profile) {
      if (!_isInitialized) {
        // IMPORTANT: Account name must be 'FirstName LastName' order
        // to match backend validation in RiderProfileController
        final accountName = [
          profile.firstName?.trim(),
          profile.lastName?.trim(),
        ].where((element) => element != null && element.isNotEmpty).join(' ');
        _accountNameController.text = accountName.isNotEmpty
            ? accountName
            : _accountNameController.text;
        _selectedBank = profile.bankName?.isNotEmpty == true
            ? profile.bankName!
            : _selectedBank;
        _bankNameController.text = profile.bankName ?? _selectedBank;
        _accountNumberController.text = profile.bankAccountNumber ?? '';
        _isInitialized = true;
      }
    });

    return Scaffold(
      appBar: const CustomAppBar(title: 'Update Bank Details'),
      body: riderProfileAsync.when(
        data: (profile) {
            // IMPORTANT: Account name must be 'FirstName LastName' order
            // to match backend validation in RiderProfileController
            final accountName = [
              profile.firstName?.trim(),
              profile.lastName?.trim(),
            ].where((element) => element != null && element.isNotEmpty).join(' ');

          if (!_isInitialized) {
            _accountNameController.text =
                accountName.isNotEmpty ? accountName : _accountNameController.text;
            _selectedBank = profile.bankName?.isNotEmpty == true
                ? profile.bankName!
                : _selectedBank;
            _bankNameController.text = profile.bankName ?? _selectedBank;
            _accountNumberController.text = profile.bankAccountNumber ?? '';
            _isInitialized = true;
          }

          return SingleChildScrollView(
            padding: const EdgeInsets.all(AppSpacing.lg),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Container(
                  padding: const EdgeInsets.all(AppSpacing.md),
                  decoration: BoxDecoration(
                    color: AppColors.primary.withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(AppBorderRadius.md),
                  ),
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Icon(
                        Icons.info_outline,
                        color: AppColors.primary,
                      ),
                      const SizedBox(width: AppSpacing.md),
                      Expanded(
                        child: Text(
                          'Your bank details are used for payouts. Account name is read-only and must match your profile.',
                          style: AppTextStyles.bodySmall.copyWith(
                            color: AppColors.primary,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: AppSpacing.xl),
                Text('Bank Details', style: AppTextStyles.headingSmall),
                const SizedBox(height: AppSpacing.md),
                CustomTextField(
                  label: 'Account Name',
                  controller: _accountNameController,
                  prefixIcon: Icons.person,
                  enabled: false,
                ),
                const SizedBox(height: AppSpacing.md),
                Container(
                  padding: const EdgeInsets.all(AppSpacing.md),
                  decoration: BoxDecoration(
                    border: Border.all(color: AppColors.border),
                    borderRadius: BorderRadius.circular(AppBorderRadius.md),
                  ),
                  child: DropdownButton<String>(
                    isExpanded: true,
                    value: _selectedBank,
                    underline: const SizedBox.shrink(),
                    items: _banks.map((bank) {
                      return DropdownMenuItem(
                        value: bank,
                        child: Text(bank),
                      );
                    }).toList(),
                    onChanged: (value) {
                      if (value != null) {
                        setState(() {
                          _selectedBank = value;
                          _bankNameController.text = value;
                        });
                      }
                    },
                  ),
                ),
                const SizedBox(height: AppSpacing.md),
                CustomTextField(
                  label: 'Account Number',
                  controller: _accountNumberController,
                  keyboardType: TextInputType.number,
                  prefixIcon: Icons.credit_card,
                ),
                const SizedBox(height: AppSpacing.xl),
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton(
                    onPressed: _isSubmitting ? null : _submitChanges,
                    child: _isSubmitting
                        ? const SizedBox(
                            height: 20,
                            width: 20,
                            child: CircularProgressIndicator(
                              strokeWidth: 2,
                              valueColor:
                                  AlwaysStoppedAnimation<Color>(Colors.white),
                            ),
                          )
                        : const Text('Save Bank Details'),
                  ),
                ),
                const SizedBox(height: AppSpacing.lg),
                if (!profile.hasBankDetails)
                  Text(
                    'Your bank details are not set yet. Please provide bank name and account number to enable withdrawals.',
                    style: AppTextStyles.bodySmall.copyWith(
                      color: AppColors.error,
                    ),
                  ),
              ],
            ),
          );
        },
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (error, stack) => Padding(
          padding: const EdgeInsets.all(AppSpacing.lg),
          child: Column(
            children: [
              Text('Failed to load your profile. Please try again.'),
              const SizedBox(height: AppSpacing.md),
              Text(error.toString()),
            ],
          ),
        ),
      ),
    );
  }
}
