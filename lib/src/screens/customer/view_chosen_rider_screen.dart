import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../config/theme.dart';
import '../../widgets/index.dart';
import '../../models/parcel_model.dart';
import '../../models/job_model.dart';
import '../../providers/index.dart';
import 'choose_rider_screen.dart';

class ViewChosenRiderScreen extends ConsumerStatefulWidget {
  final List<Parcel> parcels;
  final RiderOffer rider;
  final List<Job>? jobs;

  const ViewChosenRiderScreen({
    Key? key,
    required this.parcels,
    required this.rider,
    this.jobs,
  }) : super(key: key);

  @override
  ConsumerState<ViewChosenRiderScreen> createState() => _ViewChosenRiderScreenState();
}

class _ViewChosenRiderScreenState extends ConsumerState<ViewChosenRiderScreen> {
  final TextEditingController _notesController = TextEditingController();
  Timer? _refreshTimer;
  bool _isRefreshing = false;

  @override
  void initState() {
    super.initState();
    _startRealtimeRefresh();
  }

  void _startRealtimeRefresh() {
    _refreshTimer?.cancel();
    _refreshTimer = Timer.periodic(const Duration(seconds: 5), (_) async {
      if (mounted && widget.jobs != null && widget.jobs!.isNotEmpty) {
        await _refreshRiderData();
      }
    });
  }

  Future<void> _refreshRiderData() async {
    if (_isRefreshing) return;
    setState(() => _isRefreshing = true);
    try {
      final jobService = ref.read(jobServiceProvider);
      for (final job in widget.jobs ?? []) {
        await jobService.getJobDetails(job.id);
      }
      ref.refresh(jobServiceProvider);
    } catch (e) {
      print('❌ Error refreshing rider data: $e');
    } finally {
      if (mounted) setState(() => _isRefreshing = false);
    }
  }

  Future<void> _launchPhone(String phone) async {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('📞 Call rider: $phone'),
        duration: const Duration(seconds: 3),
      ),
    );
  }

  Future<void> _launchEmail(String email) async {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('📧 Email: $email'),
        duration: const Duration(seconds: 3),
      ),
    );
  }

  String _getDisplayPhone() {
    if (widget.rider.phone != null && widget.rider.phone!.isNotEmpty) {
      return widget.rider.phone!;
    }
    if (widget.jobs != null && widget.jobs!.isNotEmpty) {
      final riderPhone = widget.jobs!.first.rider?.phone;
      if (riderPhone != null && riderPhone.isNotEmpty) {
        return riderPhone;
      }
    }
    return 'Not available';
  }

  String _getDisplayEmail() {
    if (widget.rider.email != null && widget.rider.email!.isNotEmpty) {
      return widget.rider.email!;
    }
    if (widget.jobs != null && widget.jobs!.isNotEmpty) {
      final riderEmail = widget.jobs!.first.rider?.email;
      if (riderEmail != null && riderEmail.isNotEmpty) {
        return riderEmail;
      }
    }
    return 'Not available';
  }

  void _cancelDelivery() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Cancel Delivery'),
        content: const Text('Are you sure you want to cancel this delivery?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Keep Delivery'),
          ),
          TextButton(
            onPressed: () {
              Navigator.pop(context);
              Navigator.pushNamedAndRemoveUntil(
                context,
                '/customer-dashboard',
                (route) => false,
              );
            },
            child: const Text(
              'Cancel',
              style: TextStyle(color: Colors.red),
            ),
          ),
        ],
      ),
    );
  }

  @override
  void dispose() {
    _notesController.dispose();
    _refreshTimer?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Stack(
        children: [
          // Map background (placeholder)
          Container(
            color: AppColors.border.withOpacity(0.5),
            child: Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(
                    Icons.map,
                    size: 64,
                    color: AppColors.textSecondary,
                  ),
                  const SizedBox(height: AppSpacing.lg),
                  Text(
                    'Live Tracking Map',
                    style: AppTextStyles.headingSmall.copyWith(
                      color: AppColors.textSecondary,
                    ),
                  ),
                ],
              ),
            ),
          ),

          // Content overlay
          Column(
            children: [
              // Top app bar with back button
              SafeArea(
                child: Padding(
                  padding: const EdgeInsets.all(AppSpacing.lg),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      IconButton(
                        onPressed: () => Navigator.pop(context),
                        icon: const Icon(Icons.arrow_back),
                        style: IconButton.styleFrom(
                          backgroundColor: Colors.white,
                          side: BorderSide(color: AppColors.border),
                        ),
                      ),
                      Text(
                        'Your Rider',
                        style: AppTextStyles.headingSmall,
                      ),
                      SizedBox(width: 48), // Placeholder for symmetry
                    ],
                  ),
                ),
              ),

              // Spacer to push rider card to bottom
              Expanded(
                child: SizedBox.expand(),
              ),

              // Rider details card at bottom
              Container(
                margin: const EdgeInsets.all(AppSpacing.lg),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(AppBorderRadius.lg),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withOpacity(0.1),
                      blurRadius: 12,
                      offset: const Offset(0, -2),
                    ),
                  ],
                ),
                child: SingleChildScrollView(
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      // Rider header
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
                          crossAxisAlignment: CrossAxisAlignment.center,
                          children: [
                            // Avatar
                            Container(
                              width: 56,
                              height: 56,
                              decoration: BoxDecoration(
                                shape: BoxShape.circle,
                                color: AppColors.primary.withOpacity(0.2),
                              ),
                              child: Center(
                                child: Text(
                                  widget.rider.riderName.substring(0, 1).toUpperCase(),
                                  style: AppTextStyles.displaySmall.copyWith(
                                    color: AppColors.primary,
                                  ),
                                ),
                              ),
                            ),

                            const SizedBox(width: AppSpacing.lg),

                            // Rider details
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    widget.rider.riderName,
                                    style: AppTextStyles.headingSmall,
                                  ),
                                  const SizedBox(height: AppSpacing.xs),
                                  Row(
                                    children: [
                                      Icon(
                                        Icons.star,
                                        size: 16,
                                        color: Colors.amber,
                                      ),
                                      const SizedBox(width: AppSpacing.xs),
                                      Text(
                                        '${widget.rider.rating} • ${widget.rider.vehicleType}',
                                        style: AppTextStyles.bodySmall,
                                      ),
                                    ],
                                  ),
                                ],
                              ),
                            ),

                            // ETA badge
                            Container(
                              padding: const EdgeInsets.symmetric(
                                horizontal: AppSpacing.md,
                                vertical: AppSpacing.sm,
                              ),
                              decoration: BoxDecoration(
                                color: AppColors.success.withOpacity(0.1),
                                borderRadius: BorderRadius.circular(AppBorderRadius.sm),
                              ),
                              child: Text(
                                widget.rider.eta,
                                style: AppTextStyles.labelSmall.copyWith(
                                  color: AppColors.success,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),

                      // Body content
                      Padding(
                        padding: const EdgeInsets.all(AppSpacing.lg),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            // Vehicle info
                            Container(
                              padding: const EdgeInsets.all(AppSpacing.lg),
                              decoration: BoxDecoration(
                                color: AppColors.info.withOpacity(0.05),
                                borderRadius: BorderRadius.circular(AppBorderRadius.md),
                              ),
                              child: Row(
                                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                children: [
                                  Column(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      Text(
                                        'Vehicle',
                                        style: AppTextStyles.labelSmall.copyWith(
                                          color: AppColors.textSecondary,
                                        ),
                                      ),
                                      const SizedBox(height: AppSpacing.xs),
                                      Text(
                                        widget.rider.vehicleType,
                                        style: AppTextStyles.bodySmall,
                                      ),
                                    ],
                                  ),
                                  Column(
                                    crossAxisAlignment: CrossAxisAlignment.end,
                                    children: [
                                      Text(
                                        'Plate Number',
                                        style: AppTextStyles.labelSmall.copyWith(
                                          color: AppColors.textSecondary,
                                        ),
                                      ),
                                      const SizedBox(height: AppSpacing.xs),
                                      Text(
                                        widget.rider.vehiclePlate,
                                        style: AppTextStyles.bodySmall.copyWith(
                                          fontWeight: FontWeight.bold,
                                        ),
                                      ),
                                    ],
                                  ),
                                ],
                              ),
                            ),

                            const SizedBox(height: AppSpacing.lg),

                            // Contact options
                            Row(
                              spacing: AppSpacing.md,
                              children: [
                                // Call button
                                Expanded(
                                  child: OutlinedButton.icon(
                                    onPressed: () {
                                      ScaffoldMessenger.of(context).showSnackBar(
                                        const SnackBar(
                                          content: Text('Calling rider...'),
                                        ),
                                      );
                                    },
                                    icon: const Icon(Icons.phone),
                                    label: const Text('Call'),
                                    style: OutlinedButton.styleFrom(
                                      foregroundColor: AppColors.primary,
                                      side: BorderSide(color: AppColors.primary),
                                      padding: const EdgeInsets.symmetric(vertical: 12),
                                    ),
                                  ),
                                ),

                                // Chat button
                                Expanded(
                                  child: OutlinedButton.icon(
                                    onPressed: () {
                                      Navigator.of(context).pushNamed(
                                        '/chat-detail',
                                        arguments: {
                                          'userId': widget.rider.riderId,
                                          'userName': widget.rider.riderName,
                                          'riderRole': 'Rider',
                                          'riderPhoneNumber': _getDisplayPhone(),
                                        },
                                      );
                                    },
                                    icon: const Icon(Icons.chat),
                                    label: const Text('Chat'),
                                    style: OutlinedButton.styleFrom(
                                      foregroundColor: AppColors.primary,
                                      side: BorderSide(color: AppColors.primary),
                                      padding: const EdgeInsets.symmetric(vertical: 12),
                                    ),
                                  ),
                                ),

                                // Safety button
                                Expanded(
                                  child: OutlinedButton.icon(
                                    onPressed: () {
                                      ScaffoldMessenger.of(context).showSnackBar(
                                        const SnackBar(
                                          content: Text('Safety features available'),
                                        ),
                                      );
                                    },
                                    icon: const Icon(Icons.security),
                                    label: const Text('Safety'),
                                    style: OutlinedButton.styleFrom(
                                      foregroundColor: AppColors.primary,
                                      side: BorderSide(color: AppColors.primary),
                                      padding: const EdgeInsets.symmetric(vertical: 12),
                                    ),
                                  ),
                                ),
                              ],
                            ),

                            const SizedBox(height: AppSpacing.lg),

                            // Rider contact details
                            Container(
                              padding: const EdgeInsets.all(AppSpacing.lg),
                              decoration: BoxDecoration(
                                color: AppColors.success.withOpacity(0.05),
                                borderRadius: BorderRadius.circular(AppBorderRadius.md),
                                border: Border.all(
                                  color: AppColors.success.withOpacity(0.3),
                                ),
                              ),
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    'Contact Information',
                                    style: AppTextStyles.labelMedium.copyWith(
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                                  const SizedBox(height: AppSpacing.md),
                                  // Phone
                                  Row(
                                    children: [
                                      Icon(
                                        Icons.phone,
                                        size: 20,
                                        color: AppColors.primary,
                                      ),
                                      const SizedBox(width: AppSpacing.md),
                                      Expanded(
                                        child: Column(
                                          crossAxisAlignment: CrossAxisAlignment.start,
                                          children: [
                                            Text(
                                              'Phone',
                                              style: AppTextStyles.labelSmall.copyWith(
                                                color: AppColors.textSecondary,
                                              ),
                                            ),
                                            const SizedBox(height: AppSpacing.xs),
                                            GestureDetector(
                                              onTap: () => _launchPhone(_getDisplayPhone()),
                                              child: Text(
                                                _getDisplayPhone(),
                                                style: AppTextStyles.bodySmall.copyWith(
                                                  color: AppColors.primary,
                                                  fontWeight: FontWeight.w600,
                                                ),
                                              ),
                                            ),
                                          ],
                                        ),
                                      ),
                                    ],
                                  ),
                                  const SizedBox(height: AppSpacing.md),
                                  // Email
                                  Row(
                                    children: [
                                      Icon(
                                        Icons.email,
                                        size: 20,
                                        color: AppColors.primary,
                                      ),
                                      const SizedBox(width: AppSpacing.md),
                                      Expanded(
                                        child: Column(
                                          crossAxisAlignment: CrossAxisAlignment.start,
                                          children: [
                                            Text(
                                              'Email',
                                              style: AppTextStyles.labelSmall.copyWith(
                                                color: AppColors.textSecondary,
                                              ),
                                            ),
                                            const SizedBox(height: AppSpacing.xs),
                                            GestureDetector(
                                              onTap: () => _launchEmail(_getDisplayEmail()),
                                              child: Text(
                                                _getDisplayEmail(),
                                                style: AppTextStyles.bodySmall.copyWith(
                                                  color: AppColors.primary,
                                                  fontWeight: FontWeight.w600,
                                                ),
                                                maxLines: 1,
                                                overflow: TextOverflow.ellipsis,
                                              ),
                                            ),
                                          ],
                                        ),
                                      ),
                                    ],
                                  ),
                                  const SizedBox(height: AppSpacing.md),
                                  // Refresh status
                                  Center(
                                    child: InkWell(
                                      onTap: _isRefreshing ? null : _refreshRiderData,
                                      child: Padding(
                                        padding: const EdgeInsets.all(AppSpacing.sm),
                                        child: Row(
                                          mainAxisAlignment: MainAxisAlignment.center,
                                          children: [
                                            if (_isRefreshing)
                                              SizedBox(
                                                height: 16,
                                                width: 16,
                                                child: CircularProgressIndicator(
                                                  strokeWidth: 2,
                                                  valueColor: AlwaysStoppedAnimation(
                                                    AppColors.primary.withOpacity(0.6),
                                                  ),
                                                ),
                                              )
                                            else
                                              Icon(
                                                Icons.refresh,
                                                size: 16,
                                                color: AppColors.primary,
                                              ),
                                            const SizedBox(width: AppSpacing.sm),
                                            Text(
                                              'Refresh Details',
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
                              ),
                            ),

                            const SizedBox(height: AppSpacing.lg),

                            // Pickup notes
                            Text(
                              'Pickup Notes',
                              style: AppTextStyles.labelMedium.copyWith(
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                            const SizedBox(height: AppSpacing.sm),
                            TextField(
                              controller: _notesController,
                              maxLines: 3,
                              decoration: InputDecoration(
                                hintText: 'Add notes for the rider (optional)',
                                border: OutlineInputBorder(
                                  borderRadius: BorderRadius.circular(AppBorderRadius.md),
                                ),
                                contentPadding: const EdgeInsets.all(AppSpacing.md),
                              ),
                            ),

                            const SizedBox(height: AppSpacing.lg),

                            // Delivery locations
                            Text(
                              'Delivery Locations',
                              style: AppTextStyles.labelMedium.copyWith(
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                            const SizedBox(height: AppSpacing.md),
                            ...widget.parcels.asMap().entries.map((e) {
                              final index = e.key;
                              final parcel = e.value;
                              return Padding(
                                padding: EdgeInsets.only(
                                  bottom: index < widget.parcels.length - 1 ? AppSpacing.md : 0,
                                ),
                                child: Container(
                                  padding: const EdgeInsets.all(AppSpacing.md),
                                  decoration: BoxDecoration(
                                    border: Border.all(color: AppColors.border),
                                    borderRadius: BorderRadius.circular(AppBorderRadius.md),
                                  ),
                                  child: Column(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      Text(
                                        'Parcel ${parcel.parcelNumber}',
                                        style: AppTextStyles.labelSmall.copyWith(
                                          fontWeight: FontWeight.bold,
                                        ),
                                      ),
                                      const SizedBox(height: AppSpacing.sm),
                                      _buildLocationInfo(
                                        'Pickup',
                                        parcel.pickupAddress,
                                        AppColors.success,
                                      ),
                                      const SizedBox(height: AppSpacing.sm),
                                      _buildLocationInfo(
                                        'Dropoff',
                                        parcel.dropoffAddress,
                                        AppColors.error,
                                      ),
                                    ],
                                  ),
                                ),
                              );
                            }).toList(),

                            const SizedBox(height: AppSpacing.lg),

                            // Payment method
                            Text(
                              'Payment Method',
                              style: AppTextStyles.labelMedium.copyWith(
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                            const SizedBox(height: AppSpacing.md),
                            Container(
                              padding: const EdgeInsets.all(AppSpacing.md),
                              decoration: BoxDecoration(
                                color: AppColors.info.withOpacity(0.05),
                                borderRadius: BorderRadius.circular(AppBorderRadius.md),
                              ),
                              child: Row(
                                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                children: [
                                  Row(
                                    children: [
                                      Icon(
                                        Icons.payment,
                                        color: AppColors.info,
                                        size: 20,
                                      ),
                                      const SizedBox(width: AppSpacing.md),
                                      Text(
                                        'Cash on Delivery',
                                        style: AppTextStyles.bodySmall,
                                      ),
                                    ],
                                  ),
                                  Text(
                                    '₦${widget.rider.price.toStringAsFixed(0)}',
                                    style: AppTextStyles.labelMedium.copyWith(
                                      color: AppColors.success,
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                                ],
                              ),
                            ),

                            const SizedBox(height: AppSpacing.lg),

                            // Cancel button
                            SizedBox(
                              width: double.infinity,
                              child: OutlinedButton(
                                onPressed: _cancelDelivery,
                                style: OutlinedButton.styleFrom(
                                  foregroundColor: AppColors.error,
                                  side: BorderSide(color: AppColors.error),
                                  padding: const EdgeInsets.symmetric(vertical: 12),
                                  shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(AppBorderRadius.md),
                                  ),
                                ),
                                child: const Text('Cancel Delivery'),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildLocationInfo(String label, String address, Color color) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Icon(
          label == 'Pickup' ? Icons.location_on : Icons.flag,
          size: 16,
          color: color,
        ),
        const SizedBox(width: AppSpacing.sm),
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
}
