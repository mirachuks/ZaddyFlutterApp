import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../config/theme.dart';
import '../../providers/index.dart';
import '../../widgets/index.dart';
import '../../models/index.dart';

class CustomerOrdersScreen extends ConsumerStatefulWidget {
  const CustomerOrdersScreen({Key? key}) : super(key: key);

  @override
  ConsumerState<CustomerOrdersScreen> createState() =>
      _CustomerOrdersScreenState();
}

class _CustomerOrdersScreenState extends ConsumerState<CustomerOrdersScreen> {
  String _selectedFilter = 'all';

  @override
  Widget build(BuildContext context) {
    final jobsAsync = ref.watch(customerJobsProvider(1));

    return Scaffold(
      appBar: const CustomAppBar(
        title: 'My Orders',
      ),
      body: Column(
        children: [
          // Filter Chips
          SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            padding: const EdgeInsets.all(AppSpacing.lg),
            child: Row(
              children: [
                _FilterChip(
                  label: 'All',
                  isSelected: _selectedFilter == 'all',
                  onTap: () => setState(() => _selectedFilter = 'all'),
                ),
                const SizedBox(width: AppSpacing.md),
                _FilterChip(
                  label: 'Posted',
                  isSelected: _selectedFilter == 'posted',
                  onTap: () => setState(() => _selectedFilter = 'posted'),
                ),
                const SizedBox(width: AppSpacing.md),
                _FilterChip(
                  label: 'Accepted',
                  isSelected: _selectedFilter == 'accepted',
                  onTap: () => setState(() => _selectedFilter = 'accepted'),
                ),
                const SizedBox(width: AppSpacing.md),
                _FilterChip(
                  label: 'Delivered',
                  isSelected: _selectedFilter == 'delivered',
                  onTap: () => setState(() => _selectedFilter = 'delivered'),
                ),
                const SizedBox(width: AppSpacing.md),
                _FilterChip(
                  label: 'Completed',
                  isSelected: _selectedFilter == 'completed',
                  onTap: () => setState(() => _selectedFilter = 'completed'),
                ),
                const SizedBox(width: AppSpacing.md),
                _FilterChip(
                  label: 'Cancelled',
                  isSelected: _selectedFilter == 'cancelled',
                  onTap: () => setState(() => _selectedFilter = 'cancelled'),
                ),
              ],
            ),
          ),

          // Orders List
          jobsAsync.when(
            loading: () => Expanded(
              child: Center(
                child: CircularProgressIndicator(color: AppColors.primary),
              ),
            ),
            error: (error, stack) => Expanded(
              child: Center(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(Icons.error_outline, size: 48, color: AppColors.error),
                    const SizedBox(height: AppSpacing.md),
                    Text('Error loading orders', style: AppTextStyles.bodyLarge),
                    const SizedBox(height: AppSpacing.sm),
                    Text(error.toString(), style: AppTextStyles.bodySmall, textAlign: TextAlign.center),
                  ],
                ),
              ),
            ),
            data: (jobs) {
              // Filter jobs based on selected status
              final filteredJobs = _selectedFilter == 'all'
                  ? jobs
                  : jobs.where((job) {
                      final status = job.status.toLowerCase();
                      switch (_selectedFilter) {
                        case 'posted':
                          return status == 'posted' || status == 'open';
                        case 'accepted':
                          return status == 'accepted' || status == 'matched';
                        case 'in_progress':
                          return status == 'picked_up' || status == 'in_progress';
                        case 'delivered':
                          return status == 'delivered';
                        case 'completed':
                          return status == 'completed';
                        case 'cancelled':
                          return status == 'cancelled';
                        default:
                          return true;
                      }
                    }).toList();

              if (filteredJobs.isEmpty) {
                return Expanded(
                  child: EmptyState(
                    icon: Icons.shopping_bag_outlined,
                    title: 'No Orders',
                    subtitle: 'You don\'t have any ${_selectedFilter == 'all' ? 'orders' : _selectedFilter} orders yet',
                  ),
                );
              }

              return Expanded(
                child: ListView.builder(
                  padding: const EdgeInsets.symmetric(horizontal: AppSpacing.lg),
                  itemCount: filteredJobs.length,
                  itemBuilder: (context, index) {
                    final job = filteredJobs[index];
                    final location = '${job.pickupLocation.address} → ${job.dropoffLocation.address}';

                    // Determine status color and label
                    Color statusColor;
                    IconData statusIcon;
                    String statusLabel;

                    switch (job.status) {
                      case 'posted':
                        statusColor = AppColors.warning;
                        statusIcon = Icons.schedule;
                        statusLabel = 'Posted';
                        break;
                      case 'accepted':
                        statusColor = AppColors.info;
                        statusIcon = Icons.directions_run;
                        statusLabel = 'Accepted';
                        break;
                      case 'picked_up':
                      case 'in_progress':
                        statusColor = AppColors.info;
                        statusIcon = Icons.local_shipping;
                        statusLabel = 'In Transit';
                        break;
                      case 'delivered':
                        statusColor = AppColors.success;
                        statusIcon = Icons.check_circle;
                        statusLabel = 'Delivered';
                        break;
                      case 'completed':
                        statusColor = AppColors.success;
                        statusIcon = Icons.done_all;
                        statusLabel = 'Completed';
                        break;
                      case 'cancelled':
                        statusColor = AppColors.error;
                        statusIcon = Icons.cancel;
                        statusLabel = 'Cancelled';
                        break;
                      default:
                        statusColor = AppColors.textSecondary;
                        statusIcon = Icons.info;
                        statusLabel = job.status.toUpperCase();
                    }

                    return GestureDetector(
                      onTap: () => Navigator.of(context)
                          .pushNamed('/order-details', arguments: job.id),
                      child: _OrderJobCard(
                        job: job,
                        onPaymentNeeded: (jobId) {
                          // Navigate to payment screen when rider accepts
                          Navigator.of(context).pushNamed('/payment', arguments: {'jobId': jobId, 'job': job});
                        },
                      ),
                    );
                  },
                ),
              );
            },
          ),
        ],
      ),
    );
  }
}

class _FilterChip extends StatelessWidget {
  final String label;
  final bool isSelected;
  final VoidCallback onTap;

  const _FilterChip({
    required this.label,
    required this.isSelected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(
          horizontal: AppSpacing.md,
          vertical: AppSpacing.sm,
        ),
        decoration: BoxDecoration(
          color: isSelected ? AppColors.primary : AppColors.surface,
          border: Border.all(
            color: isSelected ? AppColors.primary : AppColors.border,
          ),
          borderRadius: BorderRadius.circular(AppBorderRadius.full),
        ),
        child: Text(
          label,
          style: AppTextStyles.labelSmall.copyWith(
            color: isSelected ? AppColors.textInverse : AppColors.textPrimary,
          ),
        ),
      ),
    );
  }
}

extension on CustomCard {
  CustomCard copyWith({EdgeInsets? margin}) {
    return CustomCard(
      padding: padding,
      onTap: onTap,
      backgroundColor: backgroundColor,
      borderRadius: borderRadius,
      child: child,
    );
  }
}

// Widget to display order card with real-time status monitoring
class _OrderJobCard extends ConsumerStatefulWidget {
  final Job job;
  final Function(String) onPaymentNeeded;

  const _OrderJobCard({
    required this.job,
    required this.onPaymentNeeded,
  });

  @override
  ConsumerState<_OrderJobCard> createState() => _OrderJobCardState();
}

class _OrderJobCardState extends ConsumerState<_OrderJobCard> {
  bool _showPaymentPrompt = false;
  bool _autoConfirmed = false;
  Timer? _autoConfirmTimer;

  @override
  void initState() {
    super.initState();
    // Monitor job status changes
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (widget.job.status == 'accepted' && !_showPaymentPrompt) {
        setState(() {
          _showPaymentPrompt = true;
        });
        // Show notification
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: const Text('🎉 A rider accepted your order! Time to pay.'),
            backgroundColor: AppColors.success,
            duration: const Duration(minutes: 1),
            action: SnackBarAction(
              label: 'Close',
              textColor: Colors.white,
              onPressed: () {
                ScaffoldMessenger.of(context).hideCurrentSnackBar();
              },
            ),
          ),
        );
      }
    });
    // If job already delivered, schedule auto-confirm after 5 minutes
    if (widget.job.status == 'delivered') {
      _autoConfirmTimer = Timer(const Duration(minutes: 5), () async {
        if (!mounted) return;
        if (_autoConfirmed) return;
        try {
          final jobService = ref.read(jobServiceProvider);
          await jobService.autoConfirmJob(widget.job.id);
          setState(() {
            _autoConfirmed = true;
          });
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Order automatically confirmed (no response).'),
              backgroundColor: AppColors.success,
            ),
          );
        } catch (e) {
          // ignore
        }
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final location = '${widget.job.pickupLocation.address} → ${widget.job.dropoffLocation.address}';

    // Determine status color and label
    Color statusColor;
    IconData statusIcon;
    String statusLabel;

    switch (widget.job.status) {
      case 'posted':
        statusColor = AppColors.warning;
        statusIcon = Icons.schedule;
        statusLabel = 'Posted';
        break;
      case 'accepted':
        statusColor = AppColors.info;
        statusIcon = Icons.directions_run;
        statusLabel = 'Accepted';
        break;
      case 'picked_up':
        statusColor = AppColors.info;
        statusIcon = Icons.local_shipping;
        statusLabel = 'In Transit';
        break;
      case 'delivered':
        statusColor = AppColors.success;
        statusIcon = Icons.check_circle;
        statusLabel = 'Delivered';
        break;
      case 'cancelled':
        statusColor = AppColors.error;
        statusIcon = Icons.cancel;
        statusLabel = 'Cancelled';
        break;
      default:
        statusColor = AppColors.textSecondary;
        statusIcon = Icons.info;
        statusLabel = widget.job.status.toUpperCase();
    }

    return CustomCard(
      padding: const EdgeInsets.all(AppSpacing.lg),
      margin: const EdgeInsets.only(bottom: AppSpacing.md),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header with status badge
              Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'Order #${widget.job.id}',
                style: AppTextStyles.bodyLarge.copyWith(
                  fontWeight: FontWeight.bold,
                ),
              ),
              Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  // Chat icon visible while job is active/delivering (until completed)
                  if (['in_progress', 'picked_up', 'delivered']
                      .contains(widget.job.status)) ...[
                    IconButton(
                      icon: const Icon(Icons.message_outlined),
                      color: AppColors.primary,
                      onPressed: () {
                        final riderId = widget.job.riderId ?? widget.job.rider?.id ?? '';
                        Navigator.of(context).pushNamed('/chat-detail', arguments: {
                          'userId': riderId,
                          'userName': widget.job.rider?.fullName ?? 'Rider',
                          'riderRole': 'Rider',
                          'riderPhoneNumber': widget.job.rider?.phone ?? '',
                        });
                      },
                    ),
                    const SizedBox(width: AppSpacing.xs),
                  ],
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: AppSpacing.md,
                      vertical: AppSpacing.sm,
                    ),
                    decoration: BoxDecoration(
                      color: statusColor.withOpacity(0.1),
                      border: Border.all(color: statusColor),
                      borderRadius: BorderRadius.circular(AppBorderRadius.sm),
                    ),
                    child: Row(
                      children: [
                        Icon(
                          statusIcon,
                          size: 16,
                          color: statusColor,
                        ),
                        const SizedBox(width: AppSpacing.xs),
                        Text(
                          statusLabel,
                          style: AppTextStyles.labelSmall.copyWith(
                            color: statusColor,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ],
          ),
          const SizedBox(height: AppSpacing.md),

          // Location info
          Row(
            children: [
              Icon(
                Icons.location_on_outlined,
                size: 18,
                color: AppColors.textSecondary,
              ),
              const SizedBox(width: AppSpacing.sm),
              Expanded(
                child: Text(
                  location,
                  style: AppTextStyles.bodySmall.copyWith(
                    color: AppColors.textSecondary,
                  ),
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
            ],
          ),
          const SizedBox(height: AppSpacing.md),

          // Fare
          Text(
            '₦${(widget.job.totalPrice ?? widget.job.estimatedFare).toStringAsFixed(2)}',
            style: AppTextStyles.bodyLarge.copyWith(
              fontWeight: FontWeight.bold,
              color: AppColors.primary,
            ),
          ),

          // Payment button if job is accepted
          if (widget.job.status == 'accepted' && _showPaymentPrompt) ...[
            const SizedBox(height: AppSpacing.lg),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton.icon(
                onPressed: () => widget.onPaymentNeeded(widget.job.id),
                icon: const Icon(Icons.payment),
                label: const Text('Proceed to Payment'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.success,
                  padding: const EdgeInsets.symmetric(vertical: 12),
                ),
              ),
            ),
          ],
          // Confirm Received button when delivered
          if (widget.job.status == 'delivered') ...[
            const SizedBox(height: AppSpacing.lg),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton.icon(
                onPressed: () async {
                  try {
                    final jobService = ref.read(jobServiceProvider);
                    await jobService.updateJobStatus(widget.job.id, 'completed');
                    setState(() {});
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(
                        content: Text('Order marked as received. Thank you!'),
                        backgroundColor: AppColors.success,
                      ),
                    );
                  } catch (e) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(
                        content: Text('Failed to confirm receipt: $e'),
                        backgroundColor: AppColors.error,
                      ),
                    );
                  }
                },
                icon: const Icon(Icons.check_circle),
                label: const Text('Confirm Received'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.success,
                  padding: const EdgeInsets.symmetric(vertical: 12),
                ),
              ),
            ),
          ],
        ],
      ),
    );
  }
  @override
  void dispose() {
    _autoConfirmTimer?.cancel();
    super.dispose();
  }
}

