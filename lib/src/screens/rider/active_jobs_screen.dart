import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../../config/theme.dart';
import '../../models/index.dart';
import '../../widgets/index.dart';
import '../../widgets/rider_bottom_nav.dart';
import '../../providers/index.dart';

class RiderActiveJobsScreen extends ConsumerStatefulWidget {
  const RiderActiveJobsScreen({Key? key}) : super(key: key);

  @override
  ConsumerState<RiderActiveJobsScreen> createState() =>
      _RiderActiveJobsScreenState();
}

class _RiderActiveJobsScreenState extends ConsumerState<RiderActiveJobsScreen> {
  int? _activeOrderAcceptedTime; // Timestamp when job was accepted
  bool _hasLoadedAcceptedTimestamp = false;
  bool _riderIsAvailable = true;
  bool _redirectScheduled = false;
  Timer? _countdownTimer;
  Timer? _refreshTimer;

  @override
  void initState() {
    super.initState();
    _loadRiderAvailabilityStatus()
        .then((_) => _loadPersistedAcceptedTimestamp());
    Future.microtask(() {
      final activeJob = ref.read(activeRiderJobProvider);
      if (activeJob != null) {
        ref.read(activeRiderJobProvider.notifier).refreshActiveJob();
      } else {
        ref
            .read(activeRiderJobProvider.notifier)
            .recoverActiveJobFromApplications();
      }
    });
    _countdownTimer = Timer.periodic(const Duration(seconds: 1), (_) {
      if (!mounted) return;
      if (_activeOrderAcceptedTime != null) {
        setState(() {});
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    ref.listen<int>(appPollerProvider, (previous, next) {
      if (!mounted) return;
      final activeJob = ref.read(activeRiderJobProvider);
      if (activeJob != null) {
        ref.read(activeRiderJobProvider.notifier)
            .refreshActiveJob()
            .catchError((_) {});
      }
    });

    final authState = ref.watch(authStateProvider);
    if (!authState.isAuthenticated || authState.currentRole != UserType.rider) {
      _redirectToLogin();
      return Scaffold(
        appBar: const CustomAppBar(
          title: 'Active Job',
          showBackButton: false,
        ),
        body: Center(
          child: Padding(
            padding: const EdgeInsets.all(AppSpacing.lg),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(
                  Icons.lock_outline,
                  size: 64,
                  color: AppColors.textTertiary,
                ),
                const SizedBox(height: AppSpacing.lg),
                Text(
                  'Please login as a rider to view this page.',
                  textAlign: TextAlign.center,
                  style: AppTextStyles.headingSmall,
                ),
                const SizedBox(height: AppSpacing.sm),
                Text(
                  'You will be redirected to login shortly.',
                  textAlign: TextAlign.center,
                  style: AppTextStyles.bodySmall,
                ),
              ],
            ),
          ),
        ),
      );
    }

    final activeJob = ref.watch(activeRiderJobProvider);
    _syncActiveJobAcceptedTime(activeJob);

    if (!_riderIsAvailable && activeJob == null) {
      return Scaffold(
        appBar: const CustomAppBar(
          title: 'Active Job',
          showBackButton: false,
        ),
        body: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(
                Icons.visibility_off_outlined,
                size: 64,
                color: AppColors.textTertiary,
              ),
              const SizedBox(height: AppSpacing.lg),
              Text(
                'You are Offline',
                style: AppTextStyles.headingSmall,
              ),
              const SizedBox(height: AppSpacing.sm),
              Text(
                'Toggle your availability to see active jobs',
                style: AppTextStyles.bodySmall,
              ),
              const SizedBox(height: AppSpacing.xl),
              ElevatedButton(
                onPressed: () {
                  Navigator.of(context).pushNamed('/rider-profile');
                },
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.primary,
                ),
                child: Text(
                  'Go to Profile',
                  style: AppTextStyles.labelMedium.copyWith(
                    color: Colors.white,
                  ),
                ),
              ),
            ],
          ),
        ),
      );
    }

    if (activeJob != null) {
      return Scaffold(
        appBar: const CustomAppBar(
          title: 'Active Job',
          showBackButton: false,
        ),
        body: SingleChildScrollView(
          padding: const EdgeInsets.all(AppSpacing.lg),
          child: Column(
            children: [
              _buildActiveJobCard(activeJob),
              if (activeJob.status == 'accepted') ...[
                const SizedBox(height: AppSpacing.xl),
                _buildCancellationSection(),
              ],
            ],
          ),
        ),
        bottomNavigationBar: RiderBottomNavigationBar(
          currentIndex: 1,
          onTap: (index) {
            switch (index) {
              case 0:
                Navigator.of(context).pushReplacementNamed('/rider-dashboard');
                break;
              case 1:
                break;
              case 2:
                Navigator.of(context).pushReplacementNamed('/rider-earnings');
                break;
              case 3:
                Navigator.of(context).pushReplacementNamed('/rider-profile');
                break;
            }
          },
        ),
      );
    }

    return Scaffold(
      appBar: const CustomAppBar(
        title: 'Active Job',
        showBackButton: false,
      ),
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.inbox_outlined,
              size: 64,
              color: AppColors.textTertiary,
            ),
            const SizedBox(height: AppSpacing.lg),
            Text(
              'No Active Jobs',
              style: AppTextStyles.headingSmall,
            ),
            const SizedBox(height: AppSpacing.sm),
            Text(
              'You currently have no active order. Accept a job from available jobs to see it here.',
              textAlign: TextAlign.center,
              style: AppTextStyles.bodySmall,
            ),
            const SizedBox(height: AppSpacing.xl),
            ElevatedButton(
              onPressed: () {
                Navigator.of(context).pushReplacementNamed('/rider-jobs');
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.primary,
              ),
              child: Text(
                'View Available Jobs',
                style: AppTextStyles.labelMedium.copyWith(
                  color: Colors.white,
                ),
              ),
            ),
          ],
        ),
      ),
      bottomNavigationBar: RiderBottomNavigationBar(
        currentIndex: 1,
        onTap: (index) {
          switch (index) {
            case 0:
              Navigator.of(context).pushReplacementNamed('/rider-dashboard');
              break;
            case 1:
              break;
            case 2:
              Navigator.of(context).pushReplacementNamed('/rider-earnings');
              break;
            case 3:
              Navigator.of(context).pushReplacementNamed('/rider-profile');
              break;
          }
        },
      ),
    );
  }

  Widget _buildActiveJobCard(Job job) {
    final priceLabel = '₦${job.estimatedFare.toStringAsFixed(0)}';

    return CustomCard(
      padding: const EdgeInsets.all(AppSpacing.lg),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Status badge
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    job.customer?.fullName ?? 'Customer',
                    style: AppTextStyles.headingSmall,
                  ),
                  const SizedBox(height: AppSpacing.xs),
                  Text(
                    job.customer?.phone ?? '',
                    style: AppTextStyles.bodySmall,
                  ),
                ],
              ),
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: AppSpacing.md,
                  vertical: AppSpacing.sm,
                ),
                decoration: BoxDecoration(
                  color: AppColors.warning.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(AppBorderRadius.sm),
                ),
                child: Text(
                  job.status.toUpperCase(),
                  style: AppTextStyles.bodySmall.copyWith(
                    color: AppColors.warning,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: AppSpacing.lg),

          // Order details
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    job.pickupLocation.address,
                    style: AppTextStyles.bodySmall.copyWith(
                      color: AppColors.textSecondary,
                    ),
                  ),
                  const SizedBox(height: AppSpacing.xs),
                  Text(
                    'Pickup location',
                    style: AppTextStyles.bodySmall,
                  ),
                ],
              ),
              Column(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  Text(
                    job.dropoffLocation.address,
                    style: AppTextStyles.bodySmall.copyWith(
                      color: AppColors.textSecondary,
                    ),
                  ),
                  const SizedBox(height: AppSpacing.xs),
                  Text(
                    'Dropoff location',
                    style: AppTextStyles.bodySmall,
                  ),
                ],
              ),
            ],
          ),
          const SizedBox(height: AppSpacing.lg),
          if (_packageSummary(job).isNotEmpty) ...[
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(AppSpacing.md),
              decoration: BoxDecoration(
                color: AppColors.primary.withValues(alpha: 0.06),
                borderRadius: BorderRadius.circular(AppBorderRadius.md),
              ),
              child: Row(
                children: [
                  Icon(Icons.inventory_2_outlined,
                      color: AppColors.primary, size: 18),
                  const SizedBox(width: AppSpacing.sm),
                  Expanded(
                    child: Text(
                      _packageSummary(job),
                      style: AppTextStyles.bodySmall
                          .copyWith(color: AppColors.textSecondary),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: AppSpacing.lg),
          ],
          const Divider(),
          const SizedBox(height: AppSpacing.lg),
          _buildItemDetailsSection(job),
          const SizedBox(height: AppSpacing.lg),

          // Fare and item
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    _jobDescription(job),
                    style: AppTextStyles.bodySmall,
                  ),
                  const SizedBox(height: AppSpacing.xs),
                  Text(
                    'Item',
                    style: AppTextStyles.bodySmall,
                  ),
                ],
              ),
              Column(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  Text(
                    priceLabel,
                    style: AppTextStyles.labelLarge.copyWith(
                      color: AppColors.accent,
                    ),
                  ),
                  const SizedBox(height: AppSpacing.xs),
                  Text(
                    'Fare',
                    style: AppTextStyles.bodySmall,
                  ),
                ],
              ),
            ],
          ),
          const SizedBox(height: AppSpacing.lg),
          if (job.status == 'in_progress' || job.status == 'picked_up')
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: () async {
                  try {
                    await ref
                        .read(activeRiderJobProvider.notifier)
                        .updateDeliveryState('delivered');
                    if (mounted) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(
                          content: Text(
                              'Marked as delivered. Waiting for customer confirmation.'),
                          backgroundColor: AppColors.success,
                        ),
                      );
                    }
                  } catch (e) {
                    if (mounted) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(
                          content: Text('Failed to mark delivered: $e'),
                          backgroundColor: AppColors.error,
                        ),
                      );
                    }
                  }
                },
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.accent,
                  padding: const EdgeInsets.symmetric(vertical: 16),
                ),
                child: Text(
                  'Mark Delivered',
                  style:
                      AppTextStyles.labelMedium.copyWith(color: Colors.white),
                ),
              ),
            ),
          const SizedBox(height: AppSpacing.md),
          // Show Start Delivery if job is accepted and not yet picked up
          if (job.status == 'accepted')
            SizedBox(
              width: double.infinity,
              child: OutlinedButton(
                onPressed: () async {
                  try {
                    await ref
                        .read(activeRiderJobProvider.notifier)
                        .updateDeliveryState('picked_up');
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(
                        content: Text('Delivery started.'),
                        backgroundColor: AppColors.info,
                      ),
                    );
                  } catch (e) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(
                        content: Text('Failed to start delivery: $e'),
                        backgroundColor: AppColors.error,
                      ),
                    );
                  }
                },
                style: OutlinedButton.styleFrom(
                  side: BorderSide(color: AppColors.primary),
                  padding: const EdgeInsets.symmetric(vertical: 16),
                ),
                child: Text('Start Delivery', style: AppTextStyles.labelMedium),
              ),
            ),
          const SizedBox(height: AppSpacing.md),
          // Dispute / Report option
          if (job.status == 'in_progress' || job.status == 'picked_up' || job.status == 'delivered')
            SizedBox(
              width: double.infinity,
              child: OutlinedButton(
                onPressed: () {
                  showDialog(
                    context: context,
                    builder: (context) {
                      final TextEditingController _reportController =
                          TextEditingController();
                    return AlertDialog(
                      title: const Text('Report / Dispute'),
                      content: TextField(
                        controller: _reportController,
                        maxLines: 4,
                        decoration: const InputDecoration(
                            hintText: 'Describe the issue'),
                      ),
                      actions: [
                        TextButton(
                            onPressed: () => Navigator.pop(context),
                            child: const Text('Cancel')),
                        ElevatedButton(
                          onPressed: () async {
                            final msg = _reportController.text.trim();
                            Navigator.pop(context);
                            if (msg.isEmpty) {
                              ScaffoldMessenger.of(context).showSnackBar(
                                const SnackBar(
                                    content:
                                        Text('Report message cannot be empty')),
                              );
                              return;
                            }
                            try {
                              final jobService = ref.read(jobServiceProvider);
                              await jobService.reportJob(job.id, msg);
                              ScaffoldMessenger.of(context).showSnackBar(
                                const SnackBar(
                                    content: Text('Report submitted'),
                                    backgroundColor: AppColors.success),
                              );
                            } catch (e) {
                              ScaffoldMessenger.of(context).showSnackBar(
                                SnackBar(
                                    content:
                                        Text('Failed to submit report: $e'),
                                    backgroundColor: AppColors.error),
                              );
                            }
                          },
                          child: const Text('Send'),
                        ),
                      ],
                    );
                  },
                );
              },
              child: Text('Report / Dispute',
                  style: AppTextStyles.bodyMedium
                      .copyWith(color: AppColors.primary)),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildItemDetailsSection(Job job) {
    if ((job.items == null || job.items!.isEmpty) &&
        job.itemDescription.isEmpty) {
      return const SizedBox.shrink();
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Package Details',
          style: AppTextStyles.labelLarge,
        ),
        const SizedBox(height: AppSpacing.sm),
        if (job.items != null && job.items!.isNotEmpty) ...[
          for (final item in job.items!) ...[
            _buildJobItemTile(item, job),
            const SizedBox(height: AppSpacing.sm),
          ],
        ] else ...[
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(AppSpacing.md),
            decoration: BoxDecoration(
              color: AppColors.surfaceVariant.withValues(alpha: 0.08),
              borderRadius: BorderRadius.circular(AppBorderRadius.md),
            ),
            child: Text(
              job.itemDescription,
              style: AppTextStyles.bodyMedium,
            ),
          ),
        ],
      ],
    );
  }

  Widget _buildJobItemTile(JobItem item, Job job) {
    final itemTitle = item.title.isNotEmpty ? item.title : 'Package';
    final receiver = item.receiverName ?? 'Receiver';
    final contact = item.receiverPhone ?? 'No phone provided';
    final receiverAddress = item.dropoffAddress?.isNotEmpty == true
        ? item.dropoffAddress!
        : job.dropoffLocation.address;
    final pickupAddress = item.pickupAddress?.isNotEmpty == true
        ? item.pickupAddress!
        : job.pickupLocation.address;

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(AppSpacing.md),
      decoration: BoxDecoration(
        color: AppColors.surfaceVariant.withValues(alpha: 0.08),
        borderRadius: BorderRadius.circular(AppBorderRadius.md),
        border: Border.all(color: AppColors.border, width: 1),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            itemTitle,
            style:
                AppTextStyles.bodyLarge.copyWith(fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: AppSpacing.xs),
          if (item.itemCategory != null && item.itemCategory!.isNotEmpty) ...[
            Text(
              'Category: ${item.itemCategory}',
              style: AppTextStyles.bodySmall
                  .copyWith(color: AppColors.textSecondary),
            ),
            const SizedBox(height: AppSpacing.xs),
          ],
          if (item.description != null && item.description!.isNotEmpty) ...[
            Text(
              item.description!,
              style: AppTextStyles.bodySmall,
            ),
            const SizedBox(height: AppSpacing.xs),
          ],
          Text(
            'Receiver: $receiver',
            style: AppTextStyles.bodySmall,
          ),
          const SizedBox(height: AppSpacing.xs),
          Text(
            'Phone: $contact',
            style: AppTextStyles.bodySmall,
          ),
          const SizedBox(height: AppSpacing.xs),
          Text(
            'Receiver address: $receiverAddress',
            style: AppTextStyles.bodySmall,
          ),
          const SizedBox(height: AppSpacing.xs),
          Text(
            'Pickup address: $pickupAddress',
            style: AppTextStyles.bodySmall,
          ),
        ],
      ),
    );
  }

  String _jobDescription(Job job) {
    if (job.itemDescription.isNotEmpty) {
      return job.itemDescription;
    }

    if (job.items != null && job.items!.isNotEmpty) {
      return job.items!.map((item) => item.title).join(', ');
    }

    return 'Parcel';
  }

  String _packageSummary(Job job) {
    if (job.items != null && job.items!.isNotEmpty) {
      final itemTitles = job.items!
          .map((item) => item.title.isNotEmpty ? item.title : 'Package')
          .toList();
      final countLabel = itemTitles.length == 1
          ? '1 package'
          : '${itemTitles.length} packages';
      return '$countLabel • ${itemTitles.join(', ')}';
    }

    if (job.itemDescription.isNotEmpty) {
      return job.itemDescription;
    }

    return '';
  }

  Widget _buildCancellationSection() {
    final timeRemaining = _calculateTimeRemaining();

    return Column(
      children: [
        Container(
          padding: const EdgeInsets.all(AppSpacing.lg),
          decoration: BoxDecoration(
            color: AppColors.warning.withValues(alpha: 0.1),
            borderRadius: BorderRadius.circular(AppBorderRadius.md),
            border: Border.all(color: AppColors.warning, width: 1),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Icon(
                    Icons.lock_clock,
                    color: AppColors.warning,
                    size: 20,
                  ),
                  const SizedBox(width: AppSpacing.md),
                  Text(
                    'Order Locked',
                    style: AppTextStyles.labelMedium.copyWith(
                      color: AppColors.warning,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: AppSpacing.md),
              Text(
                'You can cancel this order in:',
                style: AppTextStyles.bodySmall,
              ),
              const SizedBox(height: AppSpacing.sm),
              Text(
                timeRemaining,
                style: AppTextStyles.headingSmall.copyWith(
                  color: AppColors.warning,
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: AppSpacing.lg),
        if (_canCancelOrder())
          SizedBox(
            width: double.infinity,
            child: OutlinedButton(
              onPressed: _cancelActiveOrder,
              style: OutlinedButton.styleFrom(
                side: const BorderSide(
                  color: AppColors.error,
                  width: 2,
                ),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(AppBorderRadius.md),
                ),
                padding: const EdgeInsets.symmetric(vertical: 16),
              ),
              child: Text(
                'Cancel Order',
                style: AppTextStyles.labelMedium.copyWith(
                  color: AppColors.error,
                ),
              ),
            ),
          )
        else
          Container(
            padding: const EdgeInsets.symmetric(
              horizontal: AppSpacing.lg,
              vertical: AppSpacing.md,
            ),
            decoration: BoxDecoration(
              color: AppColors.textTertiary.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(AppBorderRadius.md),
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(
                  Icons.lock_outline,
                  color: AppColors.textTertiary,
                  size: 18,
                ),
                const SizedBox(width: AppSpacing.sm),
                Text(
                  'Order locked. Cannot cancel yet.',
                  style: AppTextStyles.bodySmall.copyWith(
                    color: AppColors.textTertiary,
                  ),
                ),
              ],
            ),
          ),
      ],
    );
  }

  // Helper Methods

  Future<void> _cancelActiveOrder() async {
    final job = ref.read(activeRiderJobProvider);
    if (job == null) return;

    try {
      await ref.read(jobServiceProvider).cancelJob(job.id);
      await ref.read(activeRiderJobProvider.notifier).clear();
      setState(() {
        _activeOrderAcceptedTime = null;
      });

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Order cancelled successfully.'),
          backgroundColor: AppColors.error,
          duration: Duration(seconds: 2),
        ),
      );
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Failed to cancel order: $e'),
          backgroundColor: AppColors.error,
          duration: const Duration(seconds: 3),
        ),
      );
    }
  }

  void _syncActiveJobAcceptedTime(Job? activeJob) {
    if (activeJob != null &&
        _activeOrderAcceptedTime == null &&
        _hasLoadedAcceptedTimestamp) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (!mounted) return;
        setState(() {
          _activeOrderAcceptedTime =
              ref.read(activeRiderJobProvider.notifier).acceptedAtMs ??
                  DateTime.now().millisecondsSinceEpoch;
        });
      });
      return;
    }

    if (activeJob == null && _activeOrderAcceptedTime != null) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (!mounted) return;
        setState(() {
          _activeOrderAcceptedTime = null;
        });
      });
    }
  }

  bool _canCancelOrder() {
    if (_activeOrderAcceptedTime == null) return false;

    final now = DateTime.now().millisecondsSinceEpoch;
    final elapsedMs = now - _activeOrderAcceptedTime!;
    final cancelWindowMs = 2 * 60 * 1000; // 2 minutes in milliseconds

    return elapsedMs >= cancelWindowMs;
  }

  String _calculateTimeRemaining() {
    if (_activeOrderAcceptedTime == null) return '2:00';

    final now = DateTime.now().millisecondsSinceEpoch;
    final elapsedMs = now - _activeOrderAcceptedTime!;
    final cancelWindowMs = 2 * 60 * 1000;
    final remainingMs = cancelWindowMs - elapsedMs;

    if (remainingMs <= 0) {
      return '0:00';
    }

    final minutes = (remainingMs ~/ 60000);
    final seconds = ((remainingMs % 60000) ~/ 1000);

    return '$minutes:${seconds.toString().padLeft(2, '0')}';
  }

  // Minimal implementations for missing helpers referenced in init/build
  Future<void> _loadRiderAvailabilityStatus() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      _riderIsAvailable = prefs.getBool('rider_available') ?? true;
      if (mounted) setState(() {});
    } catch (_) {
      _riderIsAvailable = true;
    }
  }

  Future<void> _loadPersistedAcceptedTimestamp() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final ts = prefs.getInt('accepted_timestamp');
      if (ts != null) {
        _hasLoadedAcceptedTimestamp = true;
        _activeOrderAcceptedTime = ts;
      }
    } catch (_) {
      _hasLoadedAcceptedTimestamp = false;
    }
  }

  void _redirectToLogin() {
    if (!mounted) return;
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      Navigator.pushReplacementNamed(context, '/login');
    });
  }
}
