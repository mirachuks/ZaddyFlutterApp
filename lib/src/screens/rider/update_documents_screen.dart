import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart';
import '../../config/theme.dart';
import '../../widgets/index.dart';

class UpdateDocumentsScreen extends StatefulWidget {
  const UpdateDocumentsScreen({Key? key}) : super(key: key);

  @override
  State<UpdateDocumentsScreen> createState() => _UpdateDocumentsScreenState();
}

class _UpdateDocumentsScreenState extends State<UpdateDocumentsScreen> {
  dynamic _drivingLicenseImage;
  dynamic _insuranceImage;
  dynamic _vehicleRegistrationImage;
  bool _isSubmitting = false;

  Future<void> _pickImage(Function(dynamic) onImagePicked) async {
    try {
      if (kIsWeb) {
        if (!mounted) return;
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('File upload available on web')),
        );
        return;
      }
      // Native platform - image picker functionality
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error picking image: $e')),
      );
    }
  }

  void _submitDocuments() {
    if (_drivingLicenseImage == null ||
        _insuranceImage == null ||
        _vehicleRegistrationImage == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please upload all required documents')),
      );
      return;
    }

    // Show confirmation dialog
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Submit Documents'),
        content: const Text(
            'Are you sure you want to submit these documents for verification?'),
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
            child: const Text('Submit'),
          ),
        ],
      ),
    );
  }

  Future<void> _processSubmission() async {
    setState(() => _isSubmitting = true);

    // Simulate API call
    await Future.delayed(const Duration(seconds: 2));

    setState(() => _isSubmitting = false);

    if (mounted) {
      showDialog(
        context: context,
        builder: (context) => AlertDialog(
          title: const Text('Success'),
          content: const Text(
              'Your documents have been submitted successfully. Our team will review them within 24-48 hours.'),
          actions: [
            ElevatedButton(
              onPressed: () {
                Navigator.pop(context);
                Navigator.pop(context);
              },
              child: const Text('OK'),
            ),
          ],
        ),
      );
    }
  }

  Widget _buildDocumentUploadCard(
    String title,
    String subtitle,
    dynamic file,
    VoidCallback onTap,
  ) {
    return CustomCard(
      padding: const EdgeInsets.all(AppSpacing.md),
      child: GestureDetector(
        onTap: onTap,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(title, style: AppTextStyles.bodyMedium),
                    const SizedBox(height: AppSpacing.xs),
                    Text(subtitle,
                        style: AppTextStyles.bodySmall.copyWith(
                          color: AppColors.textSecondary,
                        )),
                  ],
                ),
                Icon(
                  file != null ? Icons.check_circle : Icons.upload_file,
                  color: file != null ? AppColors.success : AppColors.primary,
                  size: 24,
                ),
              ],
            ),
            if (file != null) ...[
              const SizedBox(height: AppSpacing.md),
              Container(
                padding: const EdgeInsets.all(AppSpacing.sm),
                decoration: BoxDecoration(
                  color: AppColors.success.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(AppBorderRadius.md),
                ),
                child: Row(
                  children: [
                    Icon(
                      Icons.image,
                      color: AppColors.success,
                      size: 16,
                    ),
                    const SizedBox(width: AppSpacing.sm),
                    Expanded(
                      child: Text(
                        'File selected',
                        style: AppTextStyles.bodySmall.copyWith(
                          color: AppColors.success,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: const CustomAppBar(title: 'Update Documents'),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(AppSpacing.lg),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Info Box
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
                      'Upload clear, legible photos of all required documents. They will be verified by our admin team.',
                      style: AppTextStyles.bodySmall.copyWith(
                        color: AppColors.primary,
                      ),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: AppSpacing.xl),

            // Document Upload Cards
            Text('Required Documents', style: AppTextStyles.headingSmall),
            const SizedBox(height: AppSpacing.md),
            _buildDocumentUploadCard(
              'Driving License',
              'Upload a clear photo of your driving license',
              _drivingLicenseImage,
              () => _pickImage((file) => _drivingLicenseImage = file),
            ),
            const SizedBox(height: AppSpacing.md),
            _buildDocumentUploadCard(
              'Insurance Certificate',
              'Upload proof of vehicle insurance',
              _insuranceImage,
              () => _pickImage((file) => _insuranceImage = file),
            ),
            const SizedBox(height: AppSpacing.md),
            _buildDocumentUploadCard(
              'Vehicle Registration',
              'Upload vehicle registration document',
              _vehicleRegistrationImage,
              () => _pickImage((file) => _vehicleRegistrationImage = file),
            ),
            const SizedBox(height: AppSpacing.xl),

            // Submit Button
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: _isSubmitting ? null : _submitDocuments,
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
                    : const Text('Submit Documents'),
              ),
            ),
            const SizedBox(height: AppSpacing.lg),
          ],
        ),
      ),
    );
  }
}
