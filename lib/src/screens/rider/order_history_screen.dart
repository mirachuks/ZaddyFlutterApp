import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../config/theme.dart';
import '../../widgets/index.dart';
import '../../widgets/rider_bottom_nav.dart';
import '../../providers/index.dart';
import '../../models/index.dart';

class RiderOrderHistoryScreen extends ConsumerStatefulWidget {
  const RiderOrderHistoryScreen({Key? key}) : super(key: key);

  @override
  ConsumerState<RiderOrderHistoryScreen> createState() =>
      _RiderOrderHistoryScreenState();
}

class _RiderOrderHistoryScreenState
    extends ConsumerState<RiderOrderHistoryScreen> {
  bool _redirectScheduled = false;
  String _selectedFilter = 'all';

  String _effectiveStatus(JobApplication app) {
    final appStatus = app.status?.toLowerCase();
    if (appStatus != null && appStatus.isNotEmpty) {
      if (['cancelled', 'rejected', 'withdrawn'].contains(appStatus)) {
        return appStatus;
      }
    }

    final jobStatus = app.job?.status?.toLowerCase();
    if (jobStatus != null && jobStatus.isNotEmpty) {
      return jobStatus;
    }

    return appStatus ?? 'unknown';
  }

  String _statusLabel(String status) {
    switch (status) {
      case 'delivered':
      case 'completed':
        return 'Completed';
      case 'accepted':
      case 'matched':
        return 'Accepted';
      case 'in_progress':
        return 'In Progress';
      case 'cancelled':
      case 'rejected':
      case 'withdrawn':
        return 'Cancelled';
      case 'pending':
        return 'Suggested';
      default:
        return status.isNotEmpty
            ? status[0].toUpperCase() + status.substring(1)
            : 'Unknown';
    }
  }

  List<JobApplication> _filterApplications(
      List<JobApplication> applications,
      String filterKey,
  ) {
    if (filterKey == 'all') return applications;

    return applications.where((app) {
      final status = _effectiveStatus(app);
      if (filterKey == 'completed') {
        return status == 'delivered' || status == 'completed';
      }
      if (filterKey == 'cancelled') {
        return status == 'cancelled' ||
            status == 'rejected' ||
            status == 'withdrawn';
      }
      if (filterKey == 'active') {
        return status == 'accepted' ||
            status == 'matched' ||
            status == 'in_progress';
      }
      if (filterKey == 'suggested') {
        return status == 'pending';
      }
      return true;
    }).toList();
  }

  @override
  Widget build(BuildContext context) {
    final authState = ref.watch(authStateProvider);
    if (!authState.isAuthenticated || authState.currentRole != UserType.rider) {
      _redirectToLogin();
      return Scaffold(
        appBar: const CustomAppBar(
          title: 'Order History',
          showBackButton: true,
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
                  'Please login as a rider to view your order history.',
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

    final riderApplicationsAsync = ref.watch(riderApplicationsProvider);

    return Scaffold(
      appBar: const CustomAppBar(
        title: 'Order History',
        showBackButton: true,
      ),
      body: riderApplicationsAsync.when(
        data: (applications) {
          final allCount = applications.length;
          final completedCount = applications.where((app) {
            final status = _effectiveStatus(app);
            return status == 'delivered' || status == 'completed';
          }).length;
          final activeCount = applications.where((app) {
            final status = _effectiveStatus(app);
            return status == 'accepted' ||
                status == 'matched' ||
                status == 'in_progress';
          }).length;
          final cancelledCount = applications.where((app) {
            final status = _effectiveStatus(app);
            return status == 'cancelled' ||
                status == 'rejected' ||
                status == 'withdrawn';
          }).length;
          final suggestedCount = applications.where((app) {
            final status = _effectiveStatus(app);
            return status == 'pending';
          }).length;

          final filteredApplications =
              _filterApplications(applications, _selectedFilter);

          return Column(
            children: [
              Container(
                width: double.infinity,
                padding: const EdgeInsets.symmetric(
                  horizontal: AppSpacing.sm,
                  vertical: AppSpacing.xs,
                ),
                child: Wrap(
                  spacing: AppSpacing.xs,
                  runSpacing: AppSpacing.xs,
                  alignment: WrapAlignment.start,
                  children: [
                    _buildFilterChip('all', 'All', allCount),
                    _buildFilterChip('suggested', 'Suggested', suggestedCount),
                    _buildFilterChip('cancelled', 'Cancelled', cancelledCount),
                    _buildFilterChip('active', 'Active', activeCount),
                    _buildFilterChip('completed', 'Completed', completedCount),
                  ],
                ),
              ),
              Padding(
                padding: const EdgeInsets.symmetric(
                  horizontal: AppSpacing.lg,
                  vertical: AppSpacing.sm,
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      'Showing ${filteredApplications.length} of $allCount orders',
                      style: AppTextStyles.bodySmall,
                    ),
                    Text(
                      '${_selectedFilter[0].toUpperCase()}${_selectedFilter.substring(1)}',
                      style: AppTextStyles.labelSmall,
                    ),
                  ],
                ),
              ),
              Expanded(
                child: ListView.builder(
                  padding: const EdgeInsets.all(AppSpacing.lg),
                  itemCount: filteredApplications.length,
                  itemBuilder: (context, index) {
                    return _buildOrderCard(filteredApplications[index]);
                  },
                ),
              ),
            ],
          );
        },
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (_, __) => Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(
                Icons.error_outline,
                size: 64,
                color: AppColors.error,
              ),
              const SizedBox(height: AppSpacing.lg),
              Text('Unable to load order history',
                  style: AppTextStyles.headingSmall),
              const SizedBox(height: AppSpacing.sm),
              Text('Please try again later.', style: AppTextStyles.bodySmall),
            ],
          ),
        ),
      ),
      bottomNavigationBar: Builder(
        builder: (context) {
          final activeJob = ref.watch(activeRiderJobProvider);
          final jobsRoute = activeJob != null ? '/rider-active-jobs' : '/rider-jobs';
          return RiderBottomNavigationBar(
            currentIndex: 3,
            onTap: (index) {
              switch (index) {
                case 0:
                  Navigator.of(context).pushReplacementNamed('/rider-dashboard');
                  break;
                case 1:
                  Navigator.of(context).pushReplacementNamed(jobsRoute);
                  break;
                case 2:
                  Navigator.of(context).pushReplacementNamed('/rider-earnings');
                  break;
                case 3:
                  Navigator.of(context).pushReplacementNamed('/rider-profile');
                  break;
              }
            },
          );
        },
      ),
    );
  }

  Widget _buildFilterChip(String value, String label, int count) {
    final isSelected = _selectedFilter == value;

    return GestureDetector(
      onTap: () => setState(() => _selectedFilter = value),
      child: Container(
        padding: const EdgeInsets.symmetric(
          horizontal: 10,
          vertical: 6,
        ),
        decoration: BoxDecoration(
          color: isSelected ? AppColors.primary : AppColors.grey50,
          borderRadius: BorderRadius.circular(AppBorderRadius.full),
          border: Border.all(
            color: isSelected ? AppColors.primary : AppColors.border,
            width: isSelected ? 2 : 1,
          ),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              label,
              style: AppTextStyles.bodySmall.copyWith(
                fontSize: 11,
                color: isSelected ? Colors.white : AppColors.textSecondary,
                fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
              ),
            ),
            const SizedBox(width: 6),
            Container(
              padding: const EdgeInsets.symmetric(
                horizontal: 6,
                vertical: 2,
              ),
              decoration: BoxDecoration(
                color: isSelected ? Colors.white.withValues(alpha: 0.2) : AppColors.border,
                borderRadius: BorderRadius.circular(AppBorderRadius.full),
              ),
              child: Text(
                count.toString(),
                style: AppTextStyles.bodySmall.copyWith(
                  fontSize: 11,
                  color: isSelected ? Colors.white : AppColors.textSecondary,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _redirectToLogin() {
    if (_redirectScheduled) return;
    _redirectScheduled = true;
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      Navigator.of(context).pushReplacementNamed('/login');
    });
  }

  Widget _buildOrderCard(JobApplication application) {
    final job = application.job;
    final status = _effectiveStatus(application);
    final isCompleted = status == 'delivered' || status == 'completed';
    final orderId = job?.id ?? application.id;
    final locationFrom = job?.pickupLocation.address ?? 'Unknown pickup';
    final locationTo = job?.dropoffLocation.address ?? 'Unknown dropoff';
    final description = job != null && job.itemDescription.isNotEmpty
        ? job.itemDescription
        : 'Package details not available';
    final estimatedFare = job?.estimatedFare;
    final amount = job?.totalPrice != null
        ? '₦${job!.totalPrice!.toStringAsFixed(0)}'
        : '₦${estimatedFare != null ? estimatedFare.toStringAsFixed(0) : '0'}';
    final rating = job?.rating != null ? job!.rating!.toInt() : 0;
    final createdAt = application.createdAt.toLocal();
    final createdAtLabel = '${createdAt.day.toString().padLeft(2, '0')}/'
        '${createdAt.month.toString().padLeft(2, '0')}/'
        '${createdAt.year} ${createdAt.hour.toString().padLeft(2, '0')}:'
        '${createdAt.minute.toString().padLeft(2, '0')}';

    return CustomCard(
      margin: const EdgeInsets.only(bottom: AppSpacing.lg),
      padding: const EdgeInsets.all(AppSpacing.lg),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(orderId, style: AppTextStyles.labelLarge),
                  const SizedBox(height: AppSpacing.xs),
                  Text(createdAtLabel,
                      style: AppTextStyles.bodySmall
                          .copyWith(color: AppColors.textSecondary)),
                ],
              ),
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: AppSpacing.md,
                  vertical: AppSpacing.sm,
                ),
                decoration: BoxDecoration(
                  color: isCompleted
                      ? AppColors.success.withValues(alpha: 0.1)
                      : AppColors.error.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(AppBorderRadius.sm),
                ),
                child: Text(
                  _statusLabel(status),
                  style: AppTextStyles.bodySmall.copyWith(
                    color: isCompleted ? AppColors.success : AppColors.error,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: AppSpacing.lg),
          Text(description, style: AppTextStyles.bodyMedium),
          const SizedBox(height: AppSpacing.md),
          Row(
            children: [
              Icon(Icons.person_outline, size: 18, color: AppColors.primary),
              const SizedBox(width: AppSpacing.sm),
              Expanded(
                child: Text(
                  application.riderName ?? 'Rider details unavailable',
                  style: AppTextStyles.bodyMedium,
                ),
              ),
            ],
          ),
          const SizedBox(height: AppSpacing.md),
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                width: 28,
                height: 28,
                decoration: BoxDecoration(
                  color: AppColors.primary.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(AppBorderRadius.sm),
                ),
                child: const Center(
                  child: Icon(Icons.location_on,
                      size: 14, color: AppColors.primary),
                ),
              ),
              const SizedBox(width: AppSpacing.sm),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('From',
                        style: AppTextStyles.captionSmall
                            .copyWith(color: AppColors.textSecondary)),
                    Text(locationFrom,
                        style: AppTextStyles.bodySmall,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: AppSpacing.sm),
          Padding(
            padding: const EdgeInsets.only(left: 14),
            child: SizedBox(
              height: 20,
              child: VerticalDivider(color: AppColors.border, thickness: 1),
            ),
          ),
          const SizedBox(height: AppSpacing.sm),
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                width: 28,
                height: 28,
                decoration: BoxDecoration(
                  color: AppColors.accent.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(AppBorderRadius.sm),
                ),
                child: const Center(
                  child: Icon(Icons.location_on,
                      size: 14, color: AppColors.accent),
                ),
              ),
              const SizedBox(width: AppSpacing.sm),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('To',
                        style: AppTextStyles.captionSmall
                            .copyWith(color: AppColors.textSecondary)),
                    Text(locationTo,
                        style: AppTextStyles.bodySmall,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: AppSpacing.lg),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(amount,
                  style: AppTextStyles.labelLarge.copyWith(
                      color: AppColors.accent, fontWeight: FontWeight.bold)),
              if (isCompleted && rating > 0)
                Row(
                  children: [
                    Icon(Icons.star, size: 18, color: AppColors.accent),
                    const SizedBox(width: AppSpacing.xs),
                    Text('$rating/5', style: AppTextStyles.bodySmall),
                  ],
                ),
            ],
          ),
        ],
      ),
    );
  }
}
