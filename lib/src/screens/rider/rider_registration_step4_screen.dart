import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:image_picker/image_picker.dart';
import 'dart:io' as io;

import '../../config/theme.dart';
import '../../models/index.dart';
import '../../providers/index.dart';
import '../../widgets/index.dart';

class RiderRegistrationStep4Screen extends ConsumerStatefulWidget {
  const RiderRegistrationStep4Screen({Key? key}) : super(key: key);

  @override
  ConsumerState<RiderRegistrationStep4Screen> createState() =>
      _RiderRegistrationStep4ScreenState();
}

class _RiderRegistrationStep4ScreenState
    extends ConsumerState<RiderRegistrationStep4Screen> {
  late TextEditingController _brandController;
  late TextEditingController _modelController;
  late TextEditingController _yearController;
  late TextEditingController _plateNumberController;
  late TextEditingController _engineNumberController;
  late TextEditingController _chassisNumberController;

  String _selectedColor = 'Red';
  dynamic _registrationCertImage;
  dynamic _bikeImage;
  final _formKey = GlobalKey<FormState>();

  final List<String> _bikeColors = [
    'Red',
    'Green',
    'Blue',
    'Black',
    'White',
    'Yellow',
    'Silver',
    'Orange',
  ];

  @override
  void initState() {
    super.initState();
    final riderState = ref.read(riderRegistrationProvider);
    _brandController =
        TextEditingController(text: riderState.bikeData?.brand ?? '');
    _modelController =
        TextEditingController(text: riderState.bikeData?.model ?? '');
    _yearController =
        TextEditingController(text: riderState.bikeData?.productionYear ?? '');
    _plateNumberController =
        TextEditingController(text: riderState.bikeData?.plateNumber ?? '');
    _engineNumberController =
        TextEditingController(text: riderState.bikeData?.engineNumber ?? '');
    _chassisNumberController =
        TextEditingController(text: riderState.bikeData?.chassisNumber ?? '');
    _selectedColor = riderState.bikeData?.color ?? 'Red';
    _registrationCertImage = null; // Files not supported on web
    _bikeImage = null;
  }

  @override
  void dispose() {
    _brandController.dispose();
    _modelController.dispose();
    _yearController.dispose();
    _plateNumberController.dispose();
    _engineNumberController.dispose();
    _chassisNumberController.dispose();
    super.dispose();
  }

  Future<void> _pickImage(bool isRegistration) async {
    try {
      final picker = ImagePicker();
      final pickedFile = await picker.pickImage(
        source: ImageSource.gallery,
        imageQuality: 85,
      );

      if (pickedFile != null) {
        setState(() {
          if (isRegistration) {
            _registrationCertImage = pickedFile;
          } else {
            _bikeImage = pickedFile;
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

  Future<void> _handleSubmit() async {
    if (!_formKey.currentState!.validate()) return;
    if (_registrationCertImage == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
            content: Text('Please upload bike registration certificate')),
      );
      return;
    }
    if (_bikeImage == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please upload bike photo')),
      );
      return;
    }

    // XFile works on both web and mobile
    final bikeData = RiderBikeData(
      brand: _brandController.text,
      model: _modelController.text,
      productionYear: _yearController.text,
      plateNumber: _plateNumberController.text,
      color: _selectedColor,
      registrationCertPath: _registrationCertImage!.path,
      registrationCertFile: _registrationCertImage,
      bikeImagePath: _bikeImage!.path,
      bikeImageFile: _bikeImage,
      engineNumber: _engineNumberController.text.isNotEmpty
          ? _engineNumberController.text
          : null,
      chassisNumber: _chassisNumberController.text.isNotEmpty
          ? _chassisNumberController.text
          : null,
    );

    ref.read(riderRegistrationProvider.notifier).setBikeData(bikeData);

    // Navigate to completion/review screen
    if (!mounted) return;
    Navigator.of(context).pushNamed('/rider-registration-review');
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
        title: 'Bike Certification',
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
                  currentStep: 4,
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
                      // Bike Brand
                      CustomTextField(
                        label: 'Brand of Bike',
                        controller: _brandController,
                        hint: 'e.g., Bajaj, TVS, Qlink',
                        validator: (value) {
                          if (value?.isEmpty ?? true) {
                            return 'Bike brand is required';
                          }
                          return null;
                        },
                      ),
                      const SizedBox(height: AppSpacing.lg),

                      // Bike Model
                      CustomTextField(
                        label: 'Model of Bike',
                        controller: _modelController,
                        hint: 'e.g., CG125',
                        validator: (value) {
                          if (value?.isEmpty ?? true) {
                            return 'Model is required';
                          }
                          return null;
                        },
                      ),
                      const SizedBox(height: AppSpacing.lg),

                      // Production Year
                      CustomTextField(
                        label: 'Production Year',
                        controller: _yearController,
                        keyboardType: TextInputType.number,
                        hint: 'YYYY',
                        validator: (value) {
                          if (value?.isEmpty ?? true) {
                            return 'Year is required';
                          }
                          return null;
                        },
                      ),
                      const SizedBox(height: AppSpacing.lg),

                      // Plate Number
                      CustomTextField(
                        label: 'Plate Number',
                        controller: _plateNumberController,
                        hint: 'e.g., KN-123-ABC',
                        validator: (value) {
                          if (value?.isEmpty ?? true) {
                            return 'Plate number is required';
                          }
                          return null;
                        },
                      ),
                      const SizedBox(height: AppSpacing.lg),

                      // Engine Number 
                      CustomTextField(
                        label: 'Engine Number',
                        controller: _engineNumberController,
                        hint: 'Engine serial number',
                        validator: (value) {
                          if (value?.isEmpty ?? true) {
                            return 'Engine serial number is required';
                          }
                          return null;
                        },
                      ),
                      const SizedBox(height: AppSpacing.lg),

                      // Chassis Number
                      CustomTextField(
                        label: 'Chassis Number',
                        controller: _chassisNumberController,
                        hint: 'Chassis serial number',
                        validator: (value) {
                          if (value?.isEmpty ?? true) {
                            return 'Chassis serial number is required';
                          }
                          return null;
                        },
                      ),
                      const SizedBox(height: AppSpacing.lg),

                      // Color Selection
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Select Color of Bike',
                            style: AppTextStyles.labelMedium,
                          ),
                          const SizedBox(height: AppSpacing.md),
                          Wrap(
                            spacing: AppSpacing.md,
                            runSpacing: AppSpacing.md,
                            children: _bikeColors.map((color) {
                              final colorMap = {
                                'Red': Colors.red,
                                'Green': Colors.green,
                                'Blue': Colors.blue,
                                'Black': Colors.black,
                                'White': Colors.white,
                                'Yellow': Colors.yellow,
                                'Silver': Colors.grey[400],
                                'Orange': Colors.orange,
                              };

                              return GestureDetector(
                                onTap: () {
                                  setState(() => _selectedColor = color);
                                },
                                child: Container(
                                  width: 56,
                                  height: 56,
                                  decoration: BoxDecoration(
                                    shape: BoxShape.circle,
                                    color: colorMap[color],
                                    border: Border.all(
                                      color: _selectedColor == color
                                          ? Colors.black
                                          : Colors.transparent,
                                      width: 3,
                                    ),
                                  ),
                                  child: _selectedColor == color
                                      ? const Center(
                                          child: Icon(
                                            Icons.check,
                                            color: Colors.white,
                                            size: 24,
                                          ),
                                        )
                                      : null,
                                ),
                              );
                            }).toList(),
                          ),
                        ],
                      ),
                      const SizedBox(height: AppSpacing.xl),

                      // Bike Registration Certificate
                      _imageUploadBox(
                        'Bike Registration Certificate Picture',
                        _registrationCertImage,
                        () => _pickImage(true),
                      ),
                      const SizedBox(height: AppSpacing.xl),

                      // Bike Photo
                      _imageUploadBox(
                        'Picture of Bike',
                        _bikeImage,
                        () => _pickImage(false),
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
                              onPressed: _handleSubmit,
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
                                'Submit',
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
