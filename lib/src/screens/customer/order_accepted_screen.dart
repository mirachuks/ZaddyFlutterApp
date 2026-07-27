import 'package:flutter/material.dart';
import '../../config/theme.dart';
import '../../widgets/index.dart';
import '../../models/parcel_model.dart';
import '../../models/job_model.dart';

class OrderAcceptedScreen extends StatefulWidget {
  final List<Parcel> parcels;
  final double estimatedFare;
  final List<Job>? jobs;
  final double? platformCharge;

  const OrderAcceptedScreen({
    Key? key,
    required this.parcels,
    required this.estimatedFare,
    this.jobs,
    this.platformCharge,
  }) : super(key: key);

  @override
  State<OrderAcceptedScreen> createState() => _OrderAcceptedScreenState();
}

class _OrderAcceptedScreenState extends State<OrderAcceptedScreen>
    with TickerProviderStateMixin {
  late AnimationController _animationController;

  @override
  void initState() {
    super.initState();
    _animationController = AnimationController(
      duration: const Duration(milliseconds: 800),
      vsync: this,
    )..forward();
  }

  @override
  void dispose() {
    _animationController.dispose();
    super.dispose();
  }

  double get _displayTotalAmount {
    if (widget.jobs != null && widget.jobs!.isNotEmpty) {
      final job = widget.jobs!.first;
      return (job.totalPrice ?? job.estimatedFare) + (widget.platformCharge ?? 0.0);
    }
    return widget.estimatedFare + (widget.platformCharge ?? 0.0);
  }

  @override
  Widget build(BuildContext context) {
    return WillPopScope(
      onWillPop: () async => false, // Prevent back button
      child: Scaffold(
        body: Center(
          child: SingleChildScrollView(
            child: Padding(
              padding: const EdgeInsets.all(AppSpacing.lg),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  // Animated checkmark
                  ScaleTransition(
                    scale: Tween<double>(begin: 0, end: 1).animate(
                      CurvedAnimation(parent: _animationController, curve: Curves.elasticOut),
                    ),
                    child: Container(
                      width: 120,
                      height: 120,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        color: AppColors.success.withOpacity(0.1),
                      ),
                      child: Center(
                        child: Icon(
                          Icons.check_circle,
                          size: 100,
                          color: AppColors.success,
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(height: AppSpacing.xxxl),

                  // Success message
                  Text(
                    'Order Accepted!',
                    style: AppTextStyles.displaySmall.copyWith(
                      color: AppColors.success,
                      fontWeight: FontWeight.bold,
                    ),
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: AppSpacing.md),

                  // Description
                  Text(
                    'Payment confirmed. A rider has been assigned to your order.',
                    style: AppTextStyles.bodyMedium.copyWith(
                      color: AppColors.textSecondary,
                    ),
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: AppSpacing.xxxl),

                  // Order details card
                  Container(
                    padding: const EdgeInsets.all(AppSpacing.lg),
                    decoration: BoxDecoration(
                      color: AppColors.primary.withOpacity(0.05),
                      borderRadius: BorderRadius.circular(AppBorderRadius.md),
                      border: Border.all(color: AppColors.primary),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Text(
                              'Order Details',
                              style: AppTextStyles.headingSmall,
                            ),
                            Container(
                              padding: const EdgeInsets.symmetric(
                                horizontal: AppSpacing.md,
                                vertical: AppSpacing.sm,
                              ),
                              decoration: BoxDecoration(
                                color: AppColors.primary,
                                borderRadius:
                                    BorderRadius.circular(AppBorderRadius.sm),
                              ),
                              child: Text(
                                'ID: ${DateTime.now().millisecondsSinceEpoch.toString().substring(0, 8)}',
                                style: AppTextStyles.labelSmall.copyWith(
                                  color: Colors.white,
                                  fontFamily: 'monospace',
                                ),
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: AppSpacing.md),
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Text(
                              'Total Fare:',
                              style: AppTextStyles.bodyMedium,
                            ),
                            Text(
                              '₦${_displayTotalAmount.toStringAsFixed(0)}',
                              style: AppTextStyles.bodyMedium.copyWith(
                                fontWeight: FontWeight.bold,
                                color: AppColors.success,
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: AppSpacing.md),
                        Divider(color: AppColors.border),
                        const SizedBox(height: AppSpacing.md),
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Text(
                              'Status:',
                              style: AppTextStyles.bodyMedium,
                            ),
                            Container(
                              padding: const EdgeInsets.symmetric(
                                horizontal: AppSpacing.md,
                                vertical: AppSpacing.sm,
                              ),
                              decoration: BoxDecoration(
                                color: AppColors.success.withOpacity(0.1),
                                border: Border.all(color: AppColors.success),
                                borderRadius:
                                    BorderRadius.circular(AppBorderRadius.sm),
                              ),
                              child: Text(
                                'Confirmed',
                                style: AppTextStyles.labelSmall.copyWith(
                                  color: AppColors.success,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: AppSpacing.xxxl),

                  // Action buttons
                  SizedBox(
                    width: double.infinity,
                    child: ElevatedButton.icon(
                      onPressed: () {
                        final jobId = (widget.jobs != null && widget.jobs!.isNotEmpty)
                            ? widget.jobs!.first.id
                            : null;
                        Navigator.pushReplacementNamed(
                          context,
                          '/track-delivery',
                          arguments: {
                            'parcels': widget.parcels,
                            if (jobId != null) 'jobId': jobId,
                          },
                        );
                      },
                      icon: const Icon(Icons.location_on),
                      label: const Text('Track Delivery'),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppColors.primary,
                        padding: const EdgeInsets.symmetric(vertical: 14),
                      ),
                    ),
                  ),
                  const SizedBox(height: AppSpacing.md),

                  SizedBox(
                    width: double.infinity,
                    child: OutlinedButton.icon(
                      onPressed: () {
                        Navigator.pushReplacementNamed(
                          context,
                          '/customer-dashboard',
                        );
                      },
                      icon: const Icon(Icons.home),
                      label: const Text('Back to Home'),
                      style: OutlinedButton.styleFrom(
                        side: BorderSide(color: AppColors.primary),
                        padding: const EdgeInsets.symmetric(vertical: 14),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
