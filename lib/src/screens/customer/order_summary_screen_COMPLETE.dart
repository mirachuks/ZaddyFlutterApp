import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:uuid/uuid.dart';
import '../../config/theme.dart';
import '../../widgets/index.dart';
import '../../models/parcel_model.dart';
import '../../models/job_model.dart';
import '../../providers/index.dart';

class OrderSummaryScreen extends ConsumerStatefulWidget {
  final List<Parcel> parcels;

  const OrderSummaryScreen({
    Key? key,
    required this.parcels,
  }) : super(key: key);

  @override
  ConsumerState<OrderSummaryScreen> createState() => _OrderSummaryScreenState();
}

class _OrderSummaryScreenState extends ConsumerState<OrderSummaryScreen> {
  late double _currentFare;
  bool _isSubmitting = false;

  // Calculate estimated fare based on number of parcels
  double _calculateBaseFare() {
    // Base fare: ₦1,000 per parcel
    return widget.parcels.length * 1000.0;
  }

  double _calculateInitialFare() {
    final baseFare = _calculateBaseFare();
    final platformCharge = 500.0; // Flat platform charge
    return baseFare + platformCharge;
  }

  @override
  void initState() {
    super.initState();
    _currentFare = _calculateInitialFare();
  }

  void _increaseFare() {
    setState(() {
      _currentFare += 100;
    });
  }

  void _decreaseFare() {
    final minFare = _calculateInitialFare();
    setState(() {
      if (_currentFare > minFare) {
        _currentFare -= 100;
      }
    });
  }

  /// =========================================================================
  /// FORMAT PARCEL DATA FOR API
  /// This sends ALL parcel details to Laravel
  /// Laravel will loop through and create individual jobs
  /// =========================================================================
  Map<String, dynamic> _createParcelRequestData() {
    // Get authenticated user ID (adjust based on your auth setup)
    final auth = ref.read(authProvider);
    final userId = auth.user?.id ?? '';

    if (userId.isEmpty) {
      throw Exception('User not authenticated');
    }

    // Convert each parcel to API format
    final parcelDataList = widget.parcels.map((parcel) {
      return {
        'parcel_number': parcel.parcelNumber,
        'title': parcel.packageDetails.itemName,
        'item_category': parcel.packageDetails.itemCategory,
        'item_description': parcel.packageDetails.itemDescription,
        'pickup_address': parcel.pickupAddress,
        'pickup_lat': parcel.pickupCoordinates.lat,
        'pickup_lng': parcel.pickupCoordinates.lng,
        'dropoff_address': parcel.dropoffAddress,
        'dropoff_lat': parcel.dropoffCoordinates.lat,
        'dropoff_lng': parcel.dropoffCoordinates.lng,
        'recipient_name': parcel.packageDetails.recipientName,
        'recipient_phone': parcel.packageDetails.recipientPhone,
      };
    }).toList();

    // Build complete request
    final requestData = {
      'user_id': userId,
      'price': _currentFare.toInt(),
      'price_type': 'fixed',
      'parcels': parcelDataList,
    };

    print('📋 Parcel Request Data:');
    print(jsonEncode(requestData));

    return requestData;
  }

  /// =========================================================================
  /// SUBMIT PARCELS TO API
  /// =========================================================================
  Future<void> _handleFindRiderPressed() async {
    if (_isSubmitting) return;

    setState(() {
      _isSubmitting = true;
    });

    try {
      // Get the parcel data
      final requestData = _createParcelRequestData();

      print('🚀 Submitting ${widget.parcels.length} parcel(s) to API...');

      // Get JobService from providers
      final jobService = ref.read(jobServiceProvider);

      // Submit to API - Laravel will handle looping and job creation
      final createdJobs = await jobService.createJobsFromParcels(requestData);

      print('✅ Successfully created ${createdJobs.length} job(s)!');

      if (mounted) {
        // Show success message
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('${createdJobs.length} job(s) created successfully! 🎉'),
            backgroundColor: Colors.green,
            duration: const Duration(seconds: 3),
          ),
        );

        // Navigate to jobs tracking screen
        await Future.delayed(const Duration(milliseconds: 500));

        if (mounted) {
          Navigator.of(context).pushReplacementNamed(
            '/jobs-tracking',
            arguments: {'jobs': createdJobs},
          );
        }
      }
    } catch (e) {
      print('❌ Error submitting parcels: $e');

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error: $e'),
            backgroundColor: Colors.red,
            duration: const Duration(seconds: 4),
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() {
          _isSubmitting = false;
        });
      }
    }
  }

  /// =========================================================================
  /// HELPER: Old method (kept for reference/backward compatibility)
  /// =========================================================================
  Job _createJobFromParcels() {
    final firstParcel = widget.parcels.first;
    final lastParcel = widget.parcels.last;

    final itemDescriptions = widget.parcels
        .map((p) => p.packageDetails.itemName)
        .join(', ');

    return Job(
      id: const Uuid().v4(),
      customerId: '',
      pickupLocation: Location(
        latitude: firstParcel.pickupCoordinates.lat,
        longitude: firstParcel.pickupCoordinates.lng,
        address: firstParcel.pickupAddress ?? 'Pickup Location',
      ),
      dropoffLocation: Location(
        latitude: lastParcel.dropoffCoordinates.lat,
        longitude: lastParcel.dropoffCoordinates.lng,
        address: lastParcel.dropoffAddress ?? 'Dropoff Location',
      ),
      itemDescription: itemDescriptions,
      urgency: 'normal',
      estimatedFare: _currentFare,
      status: 'posted',
      paymentStatus: 'pending',
      createdAt: DateTime.now(),
      updatedAt: DateTime.now(),
    );
  }

  @override
  Widget build(BuildContext context) {
    final baseFare = _calculateBaseFare();
    final platformCharge = 500.0;

    return Scaffold(
      appBar: CustomAppBar(
        title: 'Order Summary',
        showBackButton: true,
      ),
      body: SingleChildScrollView(
        child: Column(
          children: [
            // ===== DELIVERY DETAILS CARD =====
            Container(
              margin: const EdgeInsets.all(AppSpacing.lg),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(AppBorderRadius.lg),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.05),
                    blurRadius: 8,
                    offset: const Offset(0, 2),
                  ),
                ],
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Header with parcel count
                  Container(
                    padding: const EdgeInsets.all(AppSpacing.lg),
                    decoration: BoxDecoration(
                      color: AppColors.primary.withOpacity(0.05),
                      borderRadius: const BorderRadius.only(
                        topLeft: Radius.circular(AppBorderRadius.lg),
                        topRight: Radius.circular(AppBorderRadius.lg),
                      ),
                    ),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(
                          'Delivery Details',
                          style: AppTextStyles.headingSmall,
                        ),
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: AppSpacing.md,
                            vertical: AppSpacing.sm,
                          ),
                          decoration: BoxDecoration(
                            color: AppColors.primary,
                            borderRadius: BorderRadius.circular(AppBorderRadius.md),
                          ),
                          child: Text(
                            '${widget.parcels.length} Parcel${widget.parcels.length > 1 ? 's' : ''}',
                            style: AppTextStyles.labelSmall.copyWith(
                              color: Colors.white,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),

                  // Parcels List
                  Padding(
                    padding: const EdgeInsets.all(AppSpacing.lg),
                    child: Column(
                      children: List.generate(
                        widget.parcels.length,
                        (index) {
                          final parcel = widget.parcels[index];
                          return Column(
                            children: [
                              if (index > 0)
                                Divider(
                                  color: AppColors.border,
                                  height: AppSpacing.lg,
                                ),
                              _buildParcelItem(parcel, index),
                            ],
                          );
                        },
                      ),
                    ),
                  ),
                ],
              ),
            ),

            const SizedBox(height: AppSpacing.lg),

            // ===== PRICING CARD =====
            Container(
              margin: const EdgeInsets.symmetric(horizontal: AppSpacing.lg),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(AppBorderRadius.lg),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.05),
                    blurRadius: 8,
                    offset: const Offset(0, 2),
                  ),
                ],
              ),
              child: Column(
                children: [
                  Container(
                    padding: const EdgeInsets.all(AppSpacing.lg),
                    decoration: BoxDecoration(
                      color: AppColors.primary.withOpacity(0.05),
                      borderRadius: const BorderRadius.only(
                        topLeft: Radius.circular(AppBorderRadius.lg),
                        topRight: Radius.circular(AppBorderRadius.lg),
                      ),
                    ),
                    child: Text(
                      'Recommended Fare',
                      style: AppTextStyles.headingSmall,
                    ),
                  ),
                  Padding(
                    padding: const EdgeInsets.all(AppSpacing.lg),
                    child: Column(
                      children: [
                        _buildFareRow(
                          'Base Fare (₦1,000 × ${widget.parcels.length})',
                          '₦${baseFare.toStringAsFixed(0)}',
                          false,
                        ),
                        const SizedBox(height: AppSpacing.md),
                        _buildFareRow(
                          'Platform Charge',
                          '₦${platformCharge.toStringAsFixed(0)}',
                          false,
                        ),
                        const SizedBox(height: AppSpacing.lg),
                        Divider(color: AppColors.border),
                        const SizedBox(height: AppSpacing.lg),

                        // Adjustable Total Fare with +/- buttons
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  'Total Fare',
                                  style: AppTextStyles.bodySmall.copyWith(
                                    color: AppColors.textSecondary,
                                  ),
                                ),
                                const SizedBox(height: AppSpacing.sm),
                                Text(
                                  '₦${_currentFare.toStringAsFixed(0)}',
                                  style: AppTextStyles.displayLarge.copyWith(
                                    color: AppColors.success,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                              ],
                            ),
                            Row(
                              spacing: AppSpacing.md,
                              children: [
                                // Decrease button
                                GestureDetector(
                                  onTap: _decreaseFare,
                                  child: Container(
                                    width: 48,
                                    height: 48,
                                    decoration: BoxDecoration(
                                      color: AppColors.error.withOpacity(0.1),
                                      borderRadius:
                                          BorderRadius.circular(AppBorderRadius.md),
                                      border: Border.all(
                                        color: AppColors.error,
                                        width: 1.5,
                                      ),
                                    ),
                                    child: Icon(
                                      Icons.remove,
                                      color: AppColors.error,
                                      size: 24,
                                    ),
                                  ),
                                ),

                                // Increase button
                                GestureDetector(
                                  onTap: _increaseFare,
                                  child: Container(
                                    width: 48,
                                    height: 48,
                                    decoration: BoxDecoration(
                                      color: AppColors.success.withOpacity(0.1),
                                      borderRadius:
                                          BorderRadius.circular(AppBorderRadius.md),
                                      border: Border.all(
                                        color: AppColors.success,
                                        width: 1.5,
                                      ),
                                    ),
                                    child: Icon(
                                      Icons.add,
                                      color: AppColors.success,
                                      size: 24,
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),

            const SizedBox(height: AppSpacing.xxxl),

            // ===== FIND RIDER BUTTON =====
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: AppSpacing.lg),
              child: SizedBox(
                width: double.infinity,
                child: ElevatedButton.icon(
                  onPressed: _isSubmitting ? null : _handleFindRiderPressed,
                  icon: _isSubmitting
                      ? const SizedBox(
                          width: 20,
                          height: 20,
                          child: CircularProgressIndicator(
                            strokeWidth: 2,
                            valueColor:
                                AlwaysStoppedAnimation<Color>(Colors.white),
                          ),
                        )
                      : const Icon(Icons.two_wheeler),
                  label: Text(
                    _isSubmitting ? 'Submitting...' : 'Find Rider(s)',
                  ),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.success,
                    disabledBackgroundColor: AppColors.success.withOpacity(0.6),
                    padding: const EdgeInsets.symmetric(vertical: 14),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(AppBorderRadius.md),
                    ),
                  ),
                ),
              ),
            ),

            const SizedBox(height: AppSpacing.xxxl),
          ],
        ),
      ),
    );
  }

  /// =========================================================================
  /// PARCEL ITEM WIDGET
  /// =========================================================================
  Widget _buildParcelItem(Parcel parcel, int index) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Parcel ${parcel.parcelNumber}',
          style: AppTextStyles.labelMedium.copyWith(
            fontWeight: FontWeight.bold,
          ),
        ),
        const SizedBox(height: AppSpacing.sm),
        _buildLocationRow(
          'Pickup',
          parcel.pickupAddress,
          AppColors.success,
        ),
        const SizedBox(height: AppSpacing.sm),
        _buildLocationRow(
          'Dropoff',
          parcel.dropoffAddress,
          AppColors.error,
        ),
        const SizedBox(height: AppSpacing.sm),
        if (parcel.packageDetails.isFilled) ...[
          Container(
            padding: const EdgeInsets.all(AppSpacing.md),
            decoration: BoxDecoration(
              color: AppColors.primary.withOpacity(0.05),
              borderRadius: BorderRadius.circular(AppBorderRadius.sm),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Package Info',
                  style: AppTextStyles.labelSmall.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: AppSpacing.sm),
                _buildDetailRow('Item', parcel.packageDetails.itemName),
                _buildDetailRow('Category', parcel.packageDetails.itemCategory),
                _buildDetailRow('Recipient', parcel.packageDetails.recipientName),
                _buildDetailRow('Phone', parcel.packageDetails.recipientPhone),
              ],
            ),
          ),
        ],
      ],
    );
  }

  /// =========================================================================
  /// LOCATION ROW WIDGET
  /// =========================================================================
  Widget _buildLocationRow(String label, String address, Color color) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Container(
          padding: const EdgeInsets.all(AppSpacing.sm),
          decoration: BoxDecoration(
            color: color.withOpacity(0.1),
            borderRadius: BorderRadius.circular(AppBorderRadius.sm),
          ),
          child: Icon(
            label == 'Pickup' ? Icons.location_on : Icons.location_on_outlined,
            color: color,
            size: 18,
          ),
        ),
        const SizedBox(width: AppSpacing.md),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                label,
                style: AppTextStyles.labelSmall.copyWith(
                  color: AppColors.textSecondary,
                ),
              ),
              const SizedBox(height: 2),
              Text(
                address,
                style: AppTextStyles.bodySmall,
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
              ),
            ],
          ),
        ),
      ],
    );
  }

  /// =========================================================================
  /// FARE ROW WIDGET
  /// =========================================================================
  Widget _buildFareRow(String label, String amount, bool isTotal) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(
          label,
          style: isTotal
              ? AppTextStyles.labelMedium.copyWith(fontWeight: FontWeight.bold)
              : AppTextStyles.bodySmall,
        ),
        Text(
          amount,
          style: isTotal
              ? AppTextStyles.labelMedium.copyWith(fontWeight: FontWeight.bold)
              : AppTextStyles.bodySmall,
        ),
      ],
    );
  }

  /// =========================================================================
  /// DETAIL ROW WIDGET
  /// =========================================================================
  Widget _buildDetailRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.only(bottom: AppSpacing.sm),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            label,
            style: AppTextStyles.labelSmall.copyWith(
              color: AppColors.textSecondary,
            ),
          ),
          Text(
            value,
            style: AppTextStyles.bodySmall.copyWith(
              fontWeight: FontWeight.w500,
            ),
          ),
        ],
      ),
    );
  }
}
