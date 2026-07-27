import 'dart:io';

import 'dart:typed_data';

import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:image_picker/image_picker.dart';
import '../../config/theme.dart';
import '../../widgets/index.dart';
import '../../providers/api_provider.dart';
import '../../providers/auth_provider.dart';
import '../../providers/index.dart';

import 'package:flutter/services.dart';

class PaymentScreen extends ConsumerStatefulWidget {
  final double amount;
  final String description;
  final String? jobId;

  const PaymentScreen({
    Key? key,
    required this.amount,
    required this.description,
    this.jobId,
  }) : super(key: key);

  @override
  ConsumerState<PaymentScreen> createState() => _PaymentScreenState();
}

class _PaymentScreenState extends ConsumerState<PaymentScreen> {
  String _selectedPaymentMethod = 'card';
  bool _isProcessing = false;
  final ImagePicker _imagePicker = ImagePicker();
  XFile? _paymentProof;
  Uint8List? _paymentProofBytes;

  Future<void> _processPayment() async {
    setState(() => _isProcessing = true);

    // Simulate payment processing
    await Future.delayed(const Duration(seconds: 2));

    if (!mounted) return;

    setState(() => _isProcessing = false);

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(AppBorderRadius.lg),
        ),
        title: const Icon(
          Icons.check_circle,
          color: AppColors.success,
          size: 64,
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const SizedBox(height: AppSpacing.lg),
            Text(
              'Payment Successful',
              style: AppTextStyles.headingMedium,
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: AppSpacing.md),
            Text(
              '₦${widget.amount.toStringAsFixed(2)}',
              style: AppTextStyles.displayMedium,
              textAlign: TextAlign.center,
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () {
              Navigator.pop(context);
              Navigator.pop(context);
            },
            child: Text(
              'Done',
              style: AppTextStyles.labelLarge
                  .copyWith(color: AppColors.primary),
            ),
          ),
        ],
      ),
    );
  }

  Future<void> _pickPaymentProof() async {
    final picked = await _imagePicker.pickImage(source: ImageSource.gallery, imageQuality: 85);
    if (!mounted || picked == null) return;
    final bytes = await picked.readAsBytes();
    setState(() {
      _paymentProof = picked;
      _paymentProofBytes = bytes;
    });
  }

  Future<void> _notifyManualPayment() async {
    final result = await showDialog<bool>(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: const Text('Upload payment proof'),
          content: SizedBox(
            width: 420,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Text(
                  'Upload a screenshot or photo of your bank transfer proof so the admin can verify it quickly.',
                  style: TextStyle(fontSize: 13),
                ),
                const SizedBox(height: 12),
                OutlinedButton.icon(
                  onPressed: _pickPaymentProof,
                  icon: const Icon(Icons.upload_file),
                  label: const Text('Upload proof'),
                ),
                if (_paymentProof != null && _paymentProofBytes != null) ...[
                  const SizedBox(height: 12),
                  Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      border: Border.all(color: Colors.grey.shade300),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Row(
                      children: [
                        SizedBox(
                          width: 56,
                          height: 56,
                          child: ClipRRect(
                            borderRadius: BorderRadius.circular(8),
                            child: Image.memory(_paymentProofBytes!, fit: BoxFit.cover),
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                _paymentProof!.name,
                                maxLines: 2,
                                overflow: TextOverflow.ellipsis,
                              ),
                              const SizedBox(height: 4),
                              const Text(
                                'Proof ready to send',
                                style: TextStyle(color: AppColors.success, fontSize: 12),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ],
            ),
          ),
          actions: [
            TextButton(onPressed: () => Navigator.pop(context, false), child: const Text('Cancel')),
            ElevatedButton(
              onPressed: () {
                if (_paymentProof == null) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text('Please upload payment proof before notifying admin.')),
                  );
                  return;
                }
                Navigator.pop(context, true);
              },
              child: const Text('Notify Admin'),
            ),
          ],
        );
      },
    );

    if (result != true) return;

    try {
      setState(() => _isProcessing = true);
      final apiClient = await ref.read(apiClientProvider.future);

      final payload = {
        'amount': widget.amount,
        'description': widget.description,
        if (widget.jobId != null && widget.jobId!.isNotEmpty) 'job_id': widget.jobId,
      };

      final formData = FormData();
      payload.forEach((key, value) {
        if (value != null && value.toString().isNotEmpty) {
          formData.fields.add(MapEntry(key, value.toString()));
        }
      });

        if (_paymentProof != null) {
        final proofBytes = await _paymentProof!.readAsBytes();
        formData.files.add(MapEntry(
          'payment_proof',
          MultipartFile.fromBytes(proofBytes, filename: _paymentProof!.name),
        ));
      }

      print('📤 Sending manual payment notification with proof');

      final response = await apiClient.post('/payments/manual/notify', data: formData);

      print('✅ Response status: ${response.statusCode}');
      print('✅ Response data: ${response.data}');

      if (!mounted) return;

      final responseData = response.data;
      final isSuccess = responseData is Map<String, dynamic> && 
          (responseData['success'] == true || responseData['success'] == 'true');
      final message = responseData is Map<String, dynamic> 
          ? (responseData['message']?.toString() ?? 'Admin notified.')
          : 'Admin notified.';

      if (isSuccess) {
        // Update job status to in_progress after manual payment notification
        if (widget.jobId != null && widget.jobId!.isNotEmpty) {
          try {
            final jobService = ref.read(jobServiceProvider);
            await jobService.updateJobStatus(widget.jobId!, 'in_progress');
            print('✅ Job status updated to in_progress');
          } catch (e) {
            print('⚠️ Failed to update job status: $e');
          }
        }

        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(message),
            backgroundColor: AppColors.success,
            duration: const Duration(seconds: 3),
          ),
        );
        Future.delayed(const Duration(milliseconds: 500), () {
          if (mounted) Navigator.pop(context);
        });
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(message),
            backgroundColor: AppColors.error,
            duration: const Duration(seconds: 3),
          ),
        );
      }
    } catch (e, stackTrace) {
      print('❌ Error notifying admin: $e');
      print('❌ Stack trace: $stackTrace');
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Error: ${e.toString()}'),
          backgroundColor: AppColors.error,
          duration: const Duration(seconds: 3),
        ),
      );
    } finally {
      if (mounted) setState(() => _isProcessing = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    Widget detailRow(String label, String value) {
      return Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Expanded(
            flex: 3,
            child: Text(
              label,
              style: AppTextStyles.bodySmall.copyWith(color: AppColors.textSecondary),
            ),
          ),
          const SizedBox(width: AppSpacing.sm),
          Expanded(
            flex: 5,
            child: Text(
              value,
              style: AppTextStyles.bodyMedium.copyWith(color: AppColors.textPrimary, fontWeight: FontWeight.w600),
            ),
          ),
        ],
      );
    }

    return Scaffold(
      appBar: const CustomAppBar(
        title: 'Payment',
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(AppSpacing.lg),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            CustomCard(
              backgroundColor: AppColors.grey50,
              padding: const EdgeInsets.all(AppSpacing.lg),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('Transfer Amount', style: AppTextStyles.bodySmall.copyWith(color: AppColors.textSecondary)),
                  const SizedBox(height: AppSpacing.sm),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text('Total due', style: AppTextStyles.bodySmall.copyWith(color: AppColors.textSecondary)),
                          const SizedBox(height: AppSpacing.xs),
                          Text(
                            '₦${widget.amount.toStringAsFixed(2)}',
                            style: AppTextStyles.displayMedium.copyWith(color: AppColors.accent),
                          ),
                        ],
                      ),
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: AppSpacing.sm,
                          vertical: AppSpacing.xs,
                        ),
                        decoration: BoxDecoration(
                          color: AppColors.accent.withOpacity(0.12),
                          borderRadius: BorderRadius.circular(AppBorderRadius.full),
                        ),
                        child: Text(
                          'Manual Transfer',
                          style: AppTextStyles.labelLarge.copyWith(color: AppColors.accentDark),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: AppSpacing.md),
                  Text(widget.description, style: AppTextStyles.bodyMedium.copyWith(color: AppColors.textSecondary)),
                ],
              ),
            ),

            const SizedBox(height: AppSpacing.lg),

            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(AppSpacing.md),
              decoration: BoxDecoration(
                color: AppColors.accent.withOpacity(0.08),
                borderRadius: BorderRadius.circular(AppBorderRadius.md),
                border: Border.all(color: AppColors.accent.withOpacity(0.2)),
              ),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Container(
                    width: 36,
                    height: 36,
                    decoration: BoxDecoration(
                      color: AppColors.accent.withOpacity(0.16),
                      shape: BoxShape.circle,
                    ),
                    child: const Icon(Icons.info_outline, color: AppColors.accent, size: 20),
                  ),
                  const SizedBox(width: AppSpacing.md),
                  Expanded(
                    child: Text(
                      'Transfer the exact amount to the account below, then notify admin to confirm your payment.',
                      style: AppTextStyles.bodySmall.copyWith(color: AppColors.textPrimary),
                    ),
                  ),
                ],
              ),
            ),

            const SizedBox(height: AppSpacing.xl),

            CustomCard(
              padding: const EdgeInsets.all(AppSpacing.lg),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Container(
                    height: 4,
                    width: 80,
                    decoration: BoxDecoration(
                      color: AppColors.accent,
                      borderRadius: BorderRadius.circular(AppBorderRadius.xs),
                    ),
                  ),
                  const SizedBox(height: AppSpacing.lg),
                  Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Container(
                        width: 48,
                        height: 48,
                        decoration: BoxDecoration(
                          color: AppColors.accent.withOpacity(0.12),
                          borderRadius: BorderRadius.circular(AppBorderRadius.md),
                        ),
                        child: const Icon(Icons.account_balance, color: AppColors.accent, size: 28),
                      ),
                      const SizedBox(width: AppSpacing.md),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text('Bank Transfer Details', style: AppTextStyles.headingSmall),
                            const SizedBox(height: AppSpacing.xs),
                            Text('Use the company account below to complete your payment.', style: AppTextStyles.bodySmall.copyWith(color: AppColors.textSecondary)),
                          ],
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: AppSpacing.lg),
                  detailRow('Account name', 'ZADDY EXPRESS'),
                  const SizedBox(height: AppSpacing.sm),
                  detailRow('Account number', '1017799231'),
                  const SizedBox(height: AppSpacing.sm),
                  detailRow('Bank', 'ZENITH BANK PLC'),
                  const SizedBox(height: AppSpacing.lg),
                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.all(AppSpacing.md),
                    decoration: BoxDecoration(
                      color: AppColors.accent.withOpacity(0.08),
                      borderRadius: BorderRadius.circular(AppBorderRadius.md),
                    ),
                    child: Text(
                      'After the transfer, tap “I have made payment” to notify admin for approval.',
                      style: AppTextStyles.bodySmall.copyWith(color: AppColors.textSecondary),
                    ),
                  ),
                ],
              ),
            ),

            const SizedBox(height: AppSpacing.xxxl),

            PrimaryButton(
              label: 'I have made payment',
              isLoading: _isProcessing,
              onPressed: _isProcessing ? null : _notifyManualPayment,
            ),
          ],
        ),
      ),
    );
  }
}

class _PaymentMethodOption extends StatelessWidget {
  final String title;
  final String subtitle;
  final IconData icon;
  final bool isSelected;
  final VoidCallback onTap;

  const _PaymentMethodOption({
    required this.title,
    required this.subtitle,
    required this.icon,
    required this.isSelected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: CustomCard(
        padding: const EdgeInsets.all(AppSpacing.md),
        child: Row(
          children: [
            Container(
              width: 50,
              height: 50,
              decoration: BoxDecoration(
                color: isSelected
                    ? AppColors.primary.withOpacity(0.1)
                    : AppColors.surfaceVariant,
                borderRadius: BorderRadius.circular(AppBorderRadius.md),
              ),
              child: Center(
                child: Icon(
                  icon,
                  color: isSelected ? AppColors.primary : AppColors.textTertiary,
                  size: 24,
                ),
              ),
            ),
            const SizedBox(width: AppSpacing.md),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(title, style: AppTextStyles.bodyLarge),
                  const SizedBox(height: AppSpacing.xs),
                  Text(subtitle, style: AppTextStyles.bodySmall),
                ],
              ),
            ),
            Radio<String>(
              value: title.toLowerCase(),
              groupValue: null,
              onChanged: (_) => onTap(),
              activeColor: AppColors.primary,
            ),
          ],
        ),
      ),
    );
  }
}
