import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../config/theme.dart';
import '../../widgets/index.dart';
import '../../models/parcel_model.dart';
import '../../models/job_model.dart';
import '../../models/job_application_model.dart';
import '../../providers/index.dart';
import '../shared/payment_screen.dart' as shared;
import 'choose_rider_screen.dart';

class PaymentScreen extends ConsumerStatefulWidget {
  final List<Parcel>? parcels;
  final List<Job>? jobs;
  final double estimatedFare;
  final double? platformCharge;
  final JobApplication? acceptedApplication;

  const PaymentScreen({
    Key? key,
    this.parcels,
    this.jobs,
    required this.estimatedFare,
    this.platformCharge,
    this.acceptedApplication,
  }) : super(key: key);

  @override
  ConsumerState<PaymentScreen> createState() => _PaymentScreenState();
}

class _PaymentScreenState extends ConsumerState<PaymentScreen> {
  String _selectedPaymentMethod = 'wallet'; // wallet or bank
  bool _isProcessing = false;

  double get _baseFareAmount {
    final acceptedPrice = widget.acceptedApplication?.offeredPrice;
    if (acceptedPrice != null && acceptedPrice > 0) {
      return acceptedPrice;
    }

    if (widget.jobs != null && widget.jobs!.isNotEmpty) {
      return widget.jobs!.first.estimatedFare;
    }

    return widget.estimatedFare;
  }

  double get _totalAmount {
    if (widget.jobs != null && widget.jobs!.isNotEmpty) {
      final job = widget.jobs!.first;
      if (job.totalPrice != null && job.totalPrice! > 0) {
        return job.totalPrice!;
      }
    }
    return _baseFareAmount + (widget.platformCharge ?? 0.0);
  }

  String get _fareLabel {
    return widget.acceptedApplication != null ? 'Agreed Fare:' : 'Estimated Fare:';
  }

  Future<void> _processPayment({required bool useWallet}) async {
    setState(() {
      _isProcessing = true;
    });

    final navigator = Navigator.of(context);
    final String? jobId = widget.jobs?.isNotEmpty == true ? widget.jobs!.first.id : null;

    try {
      if (useWallet) {
        final walletService = await ref.read(walletServiceProvider.future);
        await walletService.debit(
          _totalAmount,
          purpose: 'job_payment',
          jobId: jobId,
        );
        ref.invalidate(walletProvider);
      }

      // Simulate payment processing
      await Future.delayed(const Duration(seconds: 1));

      if (!mounted) return;

      final jobService = ref.read(jobServiceProvider);

      if (widget.jobs != null && widget.jobs!.isNotEmpty) {
        final job = widget.jobs!.first;
        try {
          // Update job status to 'in_progress' after payment is confirmed
          try {
            await jobService.updateJobStatus(job.id, 'in_progress');
            print('✅ Job status updated to in_progress');
          } catch (e) {
            print('⚠️ Failed to update job status: $e');
          }

          final fresh = await jobService.getJobDetails(job.id);
          if (!mounted) return;

          JobApplication? acceptedApp = widget.acceptedApplication;

          try {
            final apps = await jobService.getJobApplicationsForJob(job.id);
            if (!mounted) return;

            acceptedApp ??= apps.firstWhere(
              (a) => (a.status ?? '').toLowerCase() == 'accepted',
              orElse: () => JobApplication(
                id: '',
                jobId: '',
                riderId: '',
                createdAt: DateTime.now(),
                updatedAt: DateTime.now(),
              ),
            );
            if (acceptedApp.id.isEmpty) {
              acceptedApp = null;
            }
          } catch (e) {
            print('⚠️ Failed to fetch applications: $e');
          }

          if (acceptedApp != null || fresh.status == 'accepted' || fresh.status == 'in_progress' || fresh.riderId != null || fresh.rider != null) {
            if (acceptedApp != null && acceptedApp.id.isNotEmpty) {
              try {
                await jobService.updateJobApplicationStatus(
                    acceptedApp.id, 'in_progress');
                print('✅ Application status updated to in_progress');
              } catch (e) {
                print('⚠️ Failed to update application status: $e');
              }
            }

            final riderOffer = RiderOffer(
              riderId: acceptedApp?.riderId ?? fresh.rider?.id ?? fresh.riderId ?? '',
              riderName: acceptedApp?.riderName ?? fresh.rider?.fullName ?? fresh.rider?.firstName ?? 'Rider',
              rating: fresh.rating ?? 4.5,
              vehicleType: 'Bike',
              vehiclePlate: '',
              price: acceptedApp?.offeredPrice ?? fresh.totalPrice ?? fresh.estimatedFare,
              eta: '5 mins',
              avatarUrl: acceptedApp?.riderAvatar ?? fresh.rider?.avatar ?? '',
              phone: fresh.rider?.phone.isNotEmpty == true ? fresh.rider!.phone : null,
              email: fresh.rider?.email.isNotEmpty == true ? fresh.rider!.email : null,
            );

            if (!mounted) return;
            navigator.pushReplacementNamed(
              '/view-chosen-rider',
              arguments: {
                'parcels': widget.parcels ?? [],
                'jobs': [fresh],
                'rider': riderOffer,
              },
            );
            return;
          }
        } catch (e) {
          print('❌ Error in payment processing: $e');
          // fall through to default flow
        }
      }

      if (!mounted) return;
      navigator.pushReplacementNamed(
        '/order-accepted',
        arguments: {
          'parcels': widget.parcels ?? [],
          'jobs': widget.jobs ?? [],
          'estimatedFare': widget.estimatedFare,
          'platform_charge': widget.platformCharge ?? 0.0,
        },
      );
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Payment error: ${e.toString()}'),
          backgroundColor: AppColors.error,
        ),
      );
    } finally {
      if (mounted) {
        setState(() {
          _isProcessing = false;
        });
      }
    }
  }

  Future<void> _handleAction(double walletBalance) async {
    if (_selectedPaymentMethod == 'wallet') {
      if (walletBalance >= _totalAmount) {
        await _processPayment(useWallet: true);
        return;
      }
      Navigator.pushNamed(context, '/topup');
      return;
    }

    // Bank transfer flow
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => shared.PaymentScreen(
          amount: _totalAmount,
          description: widget.jobs?.isNotEmpty == true
              ? widget.jobs!.first.itemDescription
              : 'Order payment',
          jobId: widget.jobs?.isNotEmpty == true
              ? widget.jobs!.first.id
              : null,
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final walletAsync = ref.watch(walletProvider);
    return Scaffold(
      appBar: CustomAppBar(
        title: 'Payment',
        showBackButton: true,
        onBackPressed: () {
          if (widget.jobs != null && widget.jobs!.isNotEmpty) {
            Navigator.pushReplacementNamed(
              context,
              '/find-rider',
              arguments: widget.jobs,
            );
          } else {
            Navigator.pop(context);
          }
        },
      ),
      body: SingleChildScrollView(
        child: Padding(
          padding: const EdgeInsets.all(AppSpacing.lg),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Order Summary
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
                    Text(
                      'Order Summary',
                      style: AppTextStyles.headingSmall,
                    ),
                    const SizedBox(height: AppSpacing.md),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(
                          _fareLabel,
                          style: AppTextStyles.bodyMedium,
                        ),
                        Text(
                          '₦${_baseFareAmount.toStringAsFixed(0)}',
                          style: AppTextStyles.bodyMedium.copyWith(
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: AppSpacing.md),
                    if ((widget.jobs == null || widget.jobs!.isEmpty || widget.jobs!.first.totalPrice == null) &&
                        (widget.platformCharge ?? 0.0) > 0) ...[
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text(
                            'Platform Charge:',
                            style: AppTextStyles.bodyMedium,
                          ),
                          Text(
                            '₦${widget.platformCharge!.toStringAsFixed(0)}',
                            style: AppTextStyles.bodyMedium.copyWith(
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: AppSpacing.md),
                    ],
                    Divider(
                      color: AppColors.border,
                      thickness: 1,
                    ),
                    const SizedBox(height: AppSpacing.md),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(
                          'Total Amount:',
                          style: AppTextStyles.headingSmall,
                        ),
                        Text(
                          '₦${_totalAmount.toStringAsFixed(0)}',
                          style: AppTextStyles.headingSmall.copyWith(
                            color: AppColors.success,
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
              const SizedBox(height: AppSpacing.xxxl),

              // Wallet Balance
              Container(
                padding: const EdgeInsets.all(AppSpacing.lg),
                decoration: BoxDecoration(
                  color: AppColors.success.withOpacity(0.05),
                  borderRadius: BorderRadius.circular(AppBorderRadius.md),
                ),
                child: walletAsync.when(
                  data: (wallet) {
                    final hasEnough = wallet.balance >= _totalAmount;
                    return Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Wallet Balance',
                          style: AppTextStyles.bodySmall.copyWith(
                            color: AppColors.textSecondary,
                          ),
                        ),
                        const SizedBox(height: AppSpacing.sm),
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Text(
                              '₦${wallet.balance.toStringAsFixed(0)}',
                              style: AppTextStyles.headingMedium.copyWith(
                                color: AppColors.success,
                              ),
                            ),
                            ElevatedButton(
                              onPressed: () {
                                Navigator.pushNamed(context, '/topup');
                              },
                              style: ElevatedButton.styleFrom(
                                backgroundColor: AppColors.success,
                              ),
                              child: const Text('Top Up'),
                            ),
                          ],
                        ),
                        const SizedBox(height: AppSpacing.sm),
                        Text(
                          hasEnough
                              ? 'You can pay from your wallet.'
                              : 'Insufficient wallet balance. Top up to use wallet.',
                          style: AppTextStyles.bodySmall.copyWith(
                            color: hasEnough ? AppColors.textSecondary : AppColors.error,
                          ),
                        ),
                      ],
                    );
                  },
                  loading: () => const Center(child: CircularProgressIndicator()),
                  error: (_, __) => Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Wallet Balance',
                        style: AppTextStyles.bodySmall.copyWith(
                          color: AppColors.textSecondary,
                        ),
                      ),
                      const SizedBox(height: AppSpacing.sm),
                      Text(
                        'Unable to load wallet balance',
                        style: AppTextStyles.bodyMedium.copyWith(
                          color: AppColors.error,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: AppSpacing.xxxl),

              // Payment Methods
              Text(
                'Payment Method',
                style: AppTextStyles.headingSmall,
              ),
              const SizedBox(height: AppSpacing.lg),

              // Bank Transfer Payment
              _buildPaymentOption(
                'bank',
                'Bank Transfer',
                Icons.account_balance,
                'Direct bank account transfer',
              ),
              const SizedBox(height: AppSpacing.md),

              // Wallet Payment
              _buildPaymentOption(
                'wallet',
                'Wallet Balance',
                Icons.wallet_travel,
                walletAsync.maybeWhen(
                  data: (wallet) => '₦${wallet.balance.toStringAsFixed(0)} available',
                  orElse: () => 'Loading balance...',
                ),
              ),
              const SizedBox(height: AppSpacing.xxxl),

              // Pay Button
              SizedBox(
                width: double.infinity,
                child: walletAsync.when(
                  data: (wallet) {
                    final hasEnough = wallet.balance >= _totalAmount;
                    final actionLabel = _selectedPaymentMethod == 'wallet'
                        ? hasEnough
                            ? 'Pay with Wallet'
                            : 'Top Up Wallet'
                        : 'Continue to Bank Transfer';

                    return ElevatedButton(
                      onPressed: _isProcessing ? null : () => _handleAction(wallet.balance),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppColors.success,
                        padding: const EdgeInsets.symmetric(vertical: 16),
                        disabledBackgroundColor: AppColors.textSecondary,
                      ),
                      child: _isProcessing
                          ? const SizedBox(
                              height: 20,
                              width: 20,
                              child: CircularProgressIndicator(
                                strokeWidth: 2,
                                valueColor: AlwaysStoppedAnimation(Colors.white),
                              ),
                            )
                          : Text(
                              actionLabel,
                              style: AppTextStyles.headingSmall.copyWith(
                                color: Colors.white,
                              ),
                            ),
                    );
                  },
                  loading: () {
                    final actionLabel = _selectedPaymentMethod == 'wallet'
                        ? 'Loading wallet...'
                        : 'Continue to Bank Transfer';
                    return ElevatedButton(
                      onPressed: _selectedPaymentMethod == 'bank' && !_isProcessing
                          ? () => _handleAction(0)
                          : null,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: _selectedPaymentMethod == 'bank'
                            ? AppColors.success
                            : AppColors.textSecondary,
                        padding: const EdgeInsets.symmetric(vertical: 16),
                      ),
                      child: _selectedPaymentMethod == 'bank'
                          ? Text(
                              actionLabel,
                              style: AppTextStyles.headingSmall.copyWith(
                                color: Colors.white,
                              ),
                            )
                          : const SizedBox(
                              height: 20,
                              width: 20,
                              child: CircularProgressIndicator(
                                strokeWidth: 2,
                                valueColor: AlwaysStoppedAnimation(Colors.white),
                              ),
                            ),
                    );
                  },
                  error: (_, __) {
                    final actionLabel = _selectedPaymentMethod == 'wallet'
                        ? 'Wallet unavailable'
                        : 'Continue to Bank Transfer';
                    return ElevatedButton(
                      onPressed: _selectedPaymentMethod == 'bank' && !_isProcessing
                          ? () => _handleAction(0)
                          : null,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: _selectedPaymentMethod == 'bank'
                            ? AppColors.success
                            : AppColors.textSecondary,
                        padding: const EdgeInsets.symmetric(vertical: 16),
                      ),
                      child: Text(
                        actionLabel,
                        style: AppTextStyles.headingSmall.copyWith(
                          color: Colors.white,
                        ),
                      ),
                    );
                  },
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildPaymentOption(
    String value,
    String title,
    IconData icon,
    String subtitle,
  ) {
    final isSelected = _selectedPaymentMethod == value;
    return GestureDetector(
      onTap: () {
        setState(() {
          _selectedPaymentMethod = value;
        });
      },
      child: Container(
        padding: const EdgeInsets.all(AppSpacing.lg),
        decoration: BoxDecoration(
          color: isSelected ? AppColors.primary.withOpacity(0.1) : Colors.white,
          border: Border.all(
            color: isSelected ? AppColors.primary : AppColors.border,
            width: isSelected ? 2 : 1,
          ),
          borderRadius: BorderRadius.circular(AppBorderRadius.md),
        ),
        child: Row(
          children: [
            Icon(
              icon,
              color: isSelected ? AppColors.primary : AppColors.textSecondary,
              size: 32,
            ),
            const SizedBox(width: AppSpacing.lg),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: AppTextStyles.labelMedium.copyWith(
                      color: isSelected
                          ? AppColors.primary
                          : AppColors.textPrimary,
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
            Container(
              width: 24,
              height: 24,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                border: Border.all(
                  color: isSelected ? AppColors.primary : AppColors.border,
                  width: 2,
                ),
              ),
              child: isSelected
                  ? Center(
                      child: Container(
                        width: 12,
                        height: 12,
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          color: AppColors.primary,
                        ),
                      ),
                    )
                  : null,
            ),
          ],
        ),
      ),
    );
  }
}
