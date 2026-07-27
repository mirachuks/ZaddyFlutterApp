import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../config/theme.dart';
import '../../widgets/index.dart';

class KYCSubmissionScreen extends ConsumerStatefulWidget {
  const KYCSubmissionScreen({Key? key}) : super(key: key);

  @override
  ConsumerState<KYCSubmissionScreen> createState() =>
      _KYCSubmissionScreenState();
}

class _KYCSubmissionScreenState extends ConsumerState<KYCSubmissionScreen> {
  final _formKey = GlobalKey<FormState>();
  final _vehicleNumberController = TextEditingController();
  final _licenseNumberController = TextEditingController();
  final _bankNameController = TextEditingController();
  final _accountNumberController = TextEditingController();
  final _accountNameController = TextEditingController();

  bool _isLoading = false;

  @override
  void dispose() {
    _vehicleNumberController.dispose();
    _licenseNumberController.dispose();
    _bankNameController.dispose();
    _accountNumberController.dispose();
    _accountNameController.dispose();
    super.dispose();
  }

  Future<void> _submitKYC() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => _isLoading = true);
    try {
      // Submit KYC data
      // await ref.read(riderServiceProvider).submitKYC({...});

      if (!mounted) return;
      Navigator.of(context).pushReplacementNamed('/kyc-pending');
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error: $e')),
      );
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: const CustomAppBar(
        title: 'KYC Verification',
        showBackButton: false,
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          child: Padding(
            padding: const EdgeInsets.all(AppSpacing.xl),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Complete Your Profile',
                  style: AppTextStyles.headingLarge,
                ),
                const SizedBox(height: AppSpacing.md),
                Text(
                  'We need some information to verify your rider account',
                  style: AppTextStyles.bodyMedium,
                ),
                const SizedBox(height: AppSpacing.xl),
                Form(
                  key: _formKey,
                  child: Column(
                    children: [
                      CustomTextField(
                        label: 'Vehicle Number',
                        controller: _vehicleNumberController,
                        hint: 'e.g., ABC-123-XYZ',
                        validator: (value) {
                          if (value?.isEmpty ?? true) {
                            return 'Vehicle number is required';
                          }
                          return null;
                        },
                      ),
                      const SizedBox(height: AppSpacing.lg),
                      CustomTextField(
                        label: 'Driver\'s License Number',
                        controller: _licenseNumberController,
                        validator: (value) {
                          if (value?.isEmpty ?? true) {
                            return 'License number is required';
                          }
                          return null;
                        },
                      ),
                      const SizedBox(height: AppSpacing.lg),
                      CustomTextField(
                        label: 'Bank Name',
                        controller: _bankNameController,
                        validator: (value) {
                          if (value?.isEmpty ?? true) {
                            return 'Bank name is required';
                          }
                          return null;
                        },
                      ),
                      const SizedBox(height: AppSpacing.lg),
                      CustomTextField(
                        label: 'Account Number',
                        controller: _accountNumberController,
                        validator: (value) {
                          if (value?.isEmpty ?? true) {
                            return 'Account number is required';
                          }
                          return null;
                        },
                      ),
                      const SizedBox(height: AppSpacing.lg),
                      CustomTextField(
                        label: 'Account Name',
                        controller: _accountNameController,
                        validator: (value) {
                          if (value?.isEmpty ?? true) {
                            return 'Account name is required';
                          }
                          return null;
                        },
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: AppSpacing.xxxl),
                PrimaryButton(
                  label: 'Submit for Verification',
                  isLoading: _isLoading,
                  onPressed: _submitKYC,
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
