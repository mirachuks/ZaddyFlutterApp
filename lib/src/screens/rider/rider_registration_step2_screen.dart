import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:image_picker/image_picker.dart';
import 'dart:io' as io;

import '../../config/theme.dart';
import '../../models/index.dart';
import '../../providers/index.dart';
import '../../widgets/index.dart';

class RiderRegistrationStep2Screen extends ConsumerStatefulWidget {
  const RiderRegistrationStep2Screen({Key? key}) : super(key: key);

  @override
  ConsumerState<RiderRegistrationStep2Screen> createState() =>
      _RiderRegistrationStep2ScreenState();
}

class _RiderRegistrationStep2ScreenState
    extends ConsumerState<RiderRegistrationStep2Screen> {
  late TextEditingController _licenseNumberController;
  late TextEditingController _licenseExpiryController;

  dynamic _licenseImage;
  dynamic _licenseBackImage;
  final _formKey = GlobalKey<FormState>();

  @override
  void initState() {
    super.initState();
    final riderState = ref.read(riderRegistrationProvider);
    _licenseNumberController = TextEditingController(
        text: riderState.licenseData?.licenseNumber ?? '');
    _licenseExpiryController = TextEditingController(
        text: riderState.licenseData?.licenseExpiryDate ?? '');
    _licenseImage = null; // Files not available on web or during initial load
    _licenseBackImage = null;
  }

  @override
  void dispose() {
    _licenseNumberController.dispose();
    _licenseExpiryController.dispose();
    super.dispose();
  }

  Future<void> _pickLicenseImage(bool isBack) async {
    try {
      final picker = ImagePicker();
      final pickedFile = await picker.pickImage(
        source: ImageSource.gallery,
        imageQuality: 85,
      );

      if (pickedFile != null) {
        setState(() {
          if (isBack) {
            _licenseBackImage = pickedFile;
          } else {
            _licenseImage = pickedFile;
          }
        });
        if (!mounted) return;
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Image selected successfully')),
        );
      }
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error picking image: $e')),
      );
    }
  }

  dynamic _createWebFileInput() {
    return null;
  }

  Future<void> _selectExpiryDate() async {
    final selectedDate = await showDatePicker(
      context: context,
      initialDate: DateTime.now().add(const Duration(days: 365)),
      firstDate: DateTime.now(),
      lastDate: DateTime.now().add(const Duration(days: 365 * 10)),
    );

    if (selectedDate != null) {
      _licenseExpiryController.text =
          '${selectedDate.year}-${selectedDate.month.toString().padLeft(2, '0')}-${selectedDate.day.toString().padLeft(2, '0')}';
    }
  }

  Future<void> _handleContinue() async {
    if (!_formKey.currentState!.validate()) return;
    if (_licenseImage == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please upload front of license')),
      );
      return;
    }
    if (_licenseBackImage == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please upload back of license')),
      );
      return;
    }

    // XFile works on both web and mobile
    final licenseData = RiderLicenseData(
      licenseNumber: _licenseNumberController.text,
      licenseExpiryDate: _licenseExpiryController.text,
      licenseImagePath: _licenseImage!.path,
      licenseBackImagePath: _licenseBackImage!.path,
      licenseImageFile: _licenseImage,
      licenseBackImageFile: _licenseBackImage,
    );

    ref.read(riderRegistrationProvider.notifier).setLicenseData(licenseData);

    if (!mounted) return;
    Navigator.of(context).pushNamed('/rider-registration-step3');
  }

  Widget _imageUploadBox(
    String label,
    dynamic image,
    VoidCallback onTap,
  ) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label, style: AppTextStyles.labelMedium),
        const SizedBox(height: AppSpacing.md),
        GestureDetector(
          onTap: onTap,
          child: Container(
            height: 180,
            width: double.infinity,
            decoration: BoxDecoration(
              border: Border.all(
                color: AppColors.primary,
                width: 2,
                style: BorderStyle.solid,
              ),
              borderRadius: BorderRadius.circular(12),
              color: AppColors.grey50,
              image: image != null && !kIsWeb && io.File(image.path).existsSync()
                  ? DecorationImage(
                      image: FileImage(io.File(image.path)),
                      fit: BoxFit.cover,
                    )
                  : null,
            ),
            child: image == null
                ? Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(
                          Icons.image_outlined,
                          color: AppColors.primary,
                          size: 48,
                        ),
                        const SizedBox(height: 12),
                        Text(
                          'Tap to upload image',
                          style: AppTextStyles.labelMedium.copyWith(
                            color: AppColors.primary,
                          ),
                        ),
                      ],
                    ),
                  )
                : !kIsWeb
                    ? null
                    : Center(
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(
                              Icons.check_circle,
                              color: AppColors.primary,
                              size: 48,
                            ),
                            const SizedBox(height: 12),
                            Text(
                              'Image selected',
                              textAlign: TextAlign.center,
                              style: AppTextStyles.labelSmall.copyWith(
                                color: AppColors.primary,
                              ),
                            ),
                          ],
                        ),
                      ),
          ),
        ),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: const CustomAppBar(
        title: "Rider's License",
        showBackButton: true,
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          child: Padding(
            padding: const EdgeInsets.all(AppSpacing.xl),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Step indicator
                StepProgressIndicator(
                  totalSteps: 4,
                  currentStep: 2,
                  stepLabels: const [
                    'Data',
                    'License',
                    'Guarantor',
                    'Bike',
                  ],
                ),
                const SizedBox(height: AppSpacing.xl),

                Form(
                  key: _formKey,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // License Number
                      CustomTextField(
                        label: "Driver's License Number",
                        controller: _licenseNumberController,
                        hint: 'e.g., 123456789',
                        validator: (value) {
                          if (value?.isEmpty ?? true) {
                            return 'License number is required';
                          }
                          return null;
                        },
                      ),
                      const SizedBox(height: AppSpacing.lg),

                      // Expiry Date
                      GestureDetector(
                        onTap: _selectExpiryDate,
                        child: CustomTextField(
                          label: 'License Expiry Date',
                          controller: _licenseExpiryController,
                          hint: 'YYYY-MM-DD',
                          enabled: false,
                          validator: (value) {
                            if (value?.isEmpty ?? true) {
                              return 'Expiry date is required';
                            }
                            return null;
                          },
                        ),
                      ),
                      const SizedBox(height: AppSpacing.xl),

                      // Front of License
                      _imageUploadBox(
                        "Picture of Driver's License (Front)",
                        _licenseImage,
                        () => _pickLicenseImage(false),
                      ),
                      const SizedBox(height: AppSpacing.xl),

                      // Back of License
                      _imageUploadBox(
                        "Picture of Driver's License (Back)",
                        _licenseBackImage,
                        () => _pickLicenseImage(true),
                      ),
                      const SizedBox(height: AppSpacing.xl),

                      // Terms & Conditions
                      Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Container(
                            width: 24,
                            height: 24,
                            decoration: BoxDecoration(
                              color: AppColors.primary,
                              borderRadius:
                                  BorderRadius.circular(AppSpacing.sm),
                            ),
                            child: const Icon(
                              Icons.check,
                              color: Colors.white,
                              size: 16,
                            ),
                          ),
                          const SizedBox(width: AppSpacing.md),
                          Expanded(
                            child: Text.rich(
                              TextSpan(
                                text:
                                    'By creating an account, you agree to our ',
                                style: AppTextStyles.bodySmall,
                                children: [
                                  TextSpan(
                                    text: 'Terms',
                                    style: AppTextStyles.bodySmall.copyWith(
                                      color: AppColors.secondary,
                                      decoration: TextDecoration.underline,
                                    ),
                                  ),
                                  TextSpan(text: ' and '),
                                  TextSpan(
                                    text: 'Conditions',
                                    style: AppTextStyles.bodySmall.copyWith(
                                      color: AppColors.secondary,
                                      decoration: TextDecoration.underline,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: AppSpacing.xl),

                      // Navigation Buttons
                      Row(
                        children: [
                          Expanded(
                            child: OutlinedButton(
                              onPressed: () => Navigator.of(context).pop(),
                              style: OutlinedButton.styleFrom(
                                side: const BorderSide(
                                  color: AppColors.primary,
                                  width: 2,
                                ),
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(12),
                                ),
                                padding: const EdgeInsets.symmetric(
                                  vertical: 16,
                                ),
                              ),
                              child: Text(
                                'Back',
                                style: AppTextStyles.labelLarge.copyWith(
                                  color: AppColors.primary,
                                ),
                              ),
                            ),
                          ),
                          const SizedBox(width: AppSpacing.md),
                          Expanded(
                            child: ElevatedButton(
                              onPressed: _handleContinue,
                              style: ElevatedButton.styleFrom(
                                backgroundColor: AppColors.accent,
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(12),
                                ),
                                padding: const EdgeInsets.symmetric(
                                  vertical: 16,
                                ),
                              ),
                              child: Text(
                                'Continue',
                                style: AppTextStyles.labelLarge.copyWith(
                                  color: Colors.white,
                                ),
                              ),
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
