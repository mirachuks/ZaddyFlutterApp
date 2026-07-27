import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../config/theme.dart';
import '../../models/index.dart';
import '../../providers/index.dart';
import '../../widgets/index.dart';

class RiderRegistrationStep3Screen extends ConsumerStatefulWidget {
  const RiderRegistrationStep3Screen({Key? key}) : super(key: key);

  @override
  ConsumerState<RiderRegistrationStep3Screen> createState() =>
      _RiderRegistrationStep3ScreenState();
}

class _RiderRegistrationStep3ScreenState
    extends ConsumerState<RiderRegistrationStep3Screen> {
  late List<_GuarantorFormData> _guarantorForms;

  @override
  void initState() {
    super.initState();
    // Initialize with at least one empty guarantor form
    _guarantorForms = [_GuarantorFormData()];
  }

  Future<void> _pickImage(int guarantorIndex, bool isNinImage) async {
    try {
      final picker = ImagePicker();
      final pickedFile = await picker.pickImage(
        source: ImageSource.gallery,
        imageQuality: 85,
      );
      if (pickedFile != null && mounted) {
        setState(() {
          if (isNinImage) {
            _guarantorForms[guarantorIndex].ninImagePath = pickedFile.path;
            _guarantorForms[guarantorIndex].ninImageFile = pickedFile;
          } else {
            _guarantorForms[guarantorIndex].idImagePath = pickedFile.path;
            _guarantorForms[guarantorIndex].idImageFile = pickedFile;
          }
        });
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(
                isNinImage ? 'NIN document selected' : 'ID document selected',
              ),
              duration: const Duration(seconds: 2),
            ),
          );
        }
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Failed to pick image: $e')),
        );
      }
    }
  }

  void _addGuarantor() {
    setState(() {
      _guarantorForms.add(_GuarantorFormData());
    });
  }

  void _removeGuarantor(int index) {
    if (_guarantorForms.length > 1) {
      setState(() {
        _guarantorForms.removeAt(index);
      });
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Guarantor removed')),
      );
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('At least one guarantor is required')),
      );
    }
  }

  void _handleContinue() {
    // Validate all guarantors
    for (int i = 0; i < _guarantorForms.length; i++) {
      final form = _guarantorForms[i];
      if (form.nameController.text.trim().isEmpty) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Guarantor ${i + 1}: Please enter name')),
        );
        return;
      }
      if (form.phoneController.text.trim().isEmpty) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Guarantor ${i + 1}: Please enter phone')),
        );
        return;
      }
      final ninText = form.ninController.text.trim();
      final idTypeText = form.idTypeController.text.trim();
      final normalizedNin = idTypeText == 'NIN'
          ? ninText.replaceAll(RegExp(r'[^0-9]'), '')
          : ninText;

      if (normalizedNin.isEmpty) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Guarantor ${i + 1}: Please enter NIN or ID number')),
        );
        return;
      }
      if (idTypeText == 'NIN' && normalizedNin.length != 11) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Guarantor ${i + 1}: NIN must be 11 digits')),
        );
        return;
      }
      if (idTypeText.isEmpty) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Guarantor ${i + 1}: Please select ID type')),
        );
        return;
      }
    }

    // Create guarantor objects and save to provider
    final List<RiderGuarantor> guarantors = _guarantorForms.map((form) {
      final idType = form.idTypeController.text.trim();
      final rawNin = form.ninController.text.trim();
      final normalizedNin = idType == 'NIN'
          ? rawNin.replaceAll(RegExp(r'[^0-9]'), '')
          : rawNin;

      return RiderGuarantor(
        name: form.nameController.text.trim(),
        phone: form.phoneController.text.trim(),
        email: form.emailController.text.trim().isNotEmpty
            ? form.emailController.text.trim()
            : null,
        nin: normalizedNin,
        relationship: form.relationshipController.text.trim().isNotEmpty
            ? form.relationshipController.text.trim()
            : null,
        ninImagePath: form.ninImagePath,
        ninImageFile: form.ninImageFile,
        idType: idType,
        idImagePath: form.idImagePath,
        idImageFile: form.idImageFile,
      );
    }).toList();

    // Update the provider with guarantors
    ref.read(riderRegistrationProvider.notifier).updateGuarantors(guarantors);

    // Navigate to Step 4
    Navigator.of(context).pushNamed('/rider-registration-step4');
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: const CustomAppBar(
        title: "Guarantor (Required)",
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
                  currentStep: 3,
                  stepLabels: const [
                    'Data',
                    'License',
                    'Guarantor',
                    'Bike',
                  ],
                ),
                const SizedBox(height: AppSpacing.xl),

                // Title
                Text(
                  'Provide Guarantor Details',
                  style: AppTextStyles.headingLarge,
                ),
                const SizedBox(height: AppSpacing.sm),
                Text(
                  'At least one guarantor is required. You can add more if needed.',
                  style: AppTextStyles.bodyMedium.copyWith(
                    color: AppColors.textSecondary,
                  ),
                ),
                const SizedBox(height: AppSpacing.xl),

                // Guarantors List
                ..._guarantorForms.asMap().entries.map((entry) {
                  final index = entry.key;
                  final form = entry.value;
                  return _buildGuarantorForm(index, form);
                }),

                const SizedBox(height: AppSpacing.lg),

                // Add Guarantor Button
                SizedBox(
                  width: double.infinity,
                  child: OutlinedButton.icon(
                    onPressed: _addGuarantor,
                    icon: const Icon(Icons.add),
                    label: const Text('Add Another Guarantor'),
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
                  ),
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
        ),
      ),
    );
  }

  Widget _buildGuarantorForm(int index, _GuarantorFormData form) {
    return Container(
      margin: const EdgeInsets.only(bottom: AppSpacing.xl),
      padding: const EdgeInsets.all(AppSpacing.lg),
      decoration: BoxDecoration(
        color: AppColors.primary.withValues(alpha: 0.05),
        border: Border.all(color: AppColors.primary.withValues(alpha: 0.2)),
        borderRadius: BorderRadius.circular(AppBorderRadius.md),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header with remove button
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'Guarantor ${index + 1}',
                style: AppTextStyles.labelLarge.copyWith(
                  fontWeight: FontWeight.bold,
                  color: AppColors.primary,
                ),
              ),
              if (_guarantorForms.length > 1)
                IconButton(
                  onPressed: () => _removeGuarantor(index),
                  icon: const Icon(Icons.delete_outline),
                  color: Colors.red,
                  padding: EdgeInsets.zero,
                  constraints: const BoxConstraints(),
                ),
            ],
          ),
          const SizedBox(height: AppSpacing.lg),

          // Name Field
          CustomTextField(
            controller: form.nameController,
            label: 'Full Name',
            hint: 'Enter guarantor full name',
          ),
          const SizedBox(height: AppSpacing.lg),

          // Phone Field
          CustomTextField(
            controller: form.phoneController,
            label: 'Phone Number',
            hint: '+234 (0) 900 0000 000',
            keyboardType: TextInputType.phone,
          ),
          const SizedBox(height: AppSpacing.lg),

          // Email Field
          CustomTextField(
            controller: form.emailController,
            label: 'Email Address (Optional)',
            hint: 'guarantor@example.com',
            keyboardType: TextInputType.emailAddress,
          ),
          const SizedBox(height: AppSpacing.lg),

          // NIN Field
          CustomTextField(
            controller: form.ninController,
            label: 'National ID / NIN',
            hint: 'Enter NIN or ID number',
          ),
          const SizedBox(height: AppSpacing.lg),

          // ID Type Dropdown
          DropdownButtonFormField<String>(
            initialValue: form.idTypeController.text.isNotEmpty
                ? form.idTypeController.text
                : null,
            items: const [
              DropdownMenuItem(value: 'NIN', child: Text('NIN')),
              DropdownMenuItem(value: 'Passport', child: Text('Passport')),
              DropdownMenuItem(
                value: 'Drivers License',
                child: Text('Driver\'s License'),
              ),
              DropdownMenuItem(value: 'Voter Card', child: Text('Voter Card')),
            ],
            onChanged: (value) {
              if (value != null) {
                setState(() => form.idTypeController.text = value);
              }
            },
            decoration: InputDecoration(
              labelText: 'ID Type',
              hintText: 'Select ID type',
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(8),
              ),
              contentPadding: const EdgeInsets.symmetric(
                horizontal: 12,
                vertical: 12,
              ),
            ),
          ),
          const SizedBox(height: AppSpacing.lg),

          // Relationship Field
          CustomTextField(
            controller: form.relationshipController,
            label: 'Relationship (Optional)',
            hint: 'e.g., Friend, Family, Colleague',
          ),
          const SizedBox(height: AppSpacing.lg),

          // NIN Document Upload
          _buildImageUploadButton(
            index: index,
            label: 'NIN/ID Document',
            isNinImage: true,
            form: form,
          ),
          const SizedBox(height: AppSpacing.md),

          // ID Document Upload
          _buildImageUploadButton(
            index: index,
            label: 'Additional ID Document',
            isNinImage: false,
            form: form,
          ),
        ],
      ),
    );
  }

  Widget _buildImageUploadButton({
    required int index,
    required String label,
    required bool isNinImage,
    required _GuarantorFormData form,
  }) {
    final hasImage = isNinImage ? form.ninImagePath != null : form.idImagePath != null;

    return InkWell(
      onTap: () => _pickImage(index, isNinImage),
      child: Container(
        padding: const EdgeInsets.all(AppSpacing.md),
        decoration: BoxDecoration(
          border: Border.all(
            color: hasImage ? AppColors.primary : AppColors.border,
            width: 2,
          ),
          borderRadius: BorderRadius.circular(8),
          color: hasImage ? AppColors.primary.withValues(alpha: 0.05) : AppColors.grey50,
        ),
        child: Row(
          children: [
            if (hasImage)
              Container(
                padding: const EdgeInsets.all(4),
                decoration: BoxDecoration(
                  color: AppColors.primary,
                  shape: BoxShape.circle,
                ),
                child: const Icon(
                  Icons.check,
                  color: Colors.white,
                  size: 16,
                ),
              )
            else
              const Icon(Icons.cloud_upload_outlined),
            const SizedBox(width: AppSpacing.md),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    label,
                    style: AppTextStyles.labelMedium.copyWith(
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 2),
                  if (hasImage)
                    Text(
                      '✓ Document selected',
                      style: AppTextStyles.bodySmall.copyWith(
                        color: AppColors.primary,
                      ),
                    )
                  else
                    Text(
                      'Tap to upload',
                      style: AppTextStyles.bodySmall.copyWith(
                        color: AppColors.textTertiary,
                      ),
                    ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// Helper class to manage form data for each guarantor
class _GuarantorFormData {
  final TextEditingController nameController = TextEditingController();
  final TextEditingController phoneController = TextEditingController();
  final TextEditingController emailController = TextEditingController();
  final TextEditingController ninController = TextEditingController();
  final TextEditingController idTypeController = TextEditingController();
  final TextEditingController relationshipController = TextEditingController();
  String? ninImagePath;
  String? idImagePath;
  dynamic ninImageFile;
  dynamic idImageFile;

  void dispose() {
    nameController.dispose();
    phoneController.dispose();
    emailController.dispose();
    ninController.dispose();
    idTypeController.dispose();
    relationshipController.dispose();
  }
}
