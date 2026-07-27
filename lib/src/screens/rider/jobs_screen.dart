import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../../config/theme.dart';
import '../../widgets/index.dart';
import '../../widgets/rider_bottom_nav.dart';
import '../../providers/index.dart';
import '../../models/index.dart';

class RiderJobsScreen extends ConsumerStatefulWidget {
  const RiderJobsScreen({Key? key}) : super(key: key);

  @override
  ConsumerState<RiderJobsScreen> createState() => _RiderJobsScreenState();
}

class _RiderJobsScreenState extends ConsumerState<RiderJobsScreen> {
  int? _activeJobAcceptedTime;
  bool _hasLoadedAcceptedTimestamp = false;
  final List<int> _pricesSuggestionTimestamps = [];
  bool _riderIsAvailable = true;
  bool _redirectScheduled = false;
  late Future<void> _initializationFuture;
  Timer? _countdownTimer;

  @override
  void initState() {
    super.initState();
    _initializationFuture = _loadRiderAvailabilityStatus()
        .then((_) => _loadPersistedAcceptedTimestamp());
    _countdownTimer = Timer.periodic(const Duration(seconds: 1), (_) {
      if (!mounted) return;
      if (_activeJobAcceptedTime != null) {
        setState(() {});
      }
    });
  }

  Future<void> _loadRiderAvailabilityStatus() async {
    final prefs = await SharedPreferences.getInstance();
    setState(() {
      _riderIsAvailable = prefs.getBool('rider_available') ?? true;
    });
  }

  Future<void> _loadPersistedAcceptedTimestamp() async {
    final acceptedTimestamp =
        ref.read(activeRiderJobProvider.notifier).acceptedAtMs;
    setState(() {
      _activeJobAcceptedTime = acceptedTimestamp;
      _hasLoadedAcceptedTimestamp = true;
    });
  }

  @override
  Widget build(BuildContext context) {
    final authState = ref.watch(authStateProvider);
    if (!authState.isAuthenticated || authState.currentRole != UserType.rider) {
      _redirectToLogin();
      return Scaffold(
        appBar: const CustomAppBar(
          title: 'Available Jobs',
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
                  'Please login as a rider to view available jobs.',
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

    // Prevent unverified or inactive rider profiles from viewing available jobs
    final currentUser = ref.watch(currentUserProvider);
    final riderStatus = currentUser?.riderProfileStatus?.toLowerCase();
    final isVerified = currentUser?.isVerified ?? false;

    if (riderStatus != 'active') {
      return Scaffold(
        appBar: const CustomAppBar(
          title: 'Available Jobs',
          showBackButton: false,
        ),
        body: Center(
          child: Padding(
            padding: const EdgeInsets.all(AppSpacing.lg),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(Icons.info_outline, size: 64, color: AppColors.textTertiary),
                const SizedBox(height: AppSpacing.lg),
                Text(
                  riderStatus == 'awaiting_verification'
                      ? 'Your rider profile is under review. You cannot view available jobs until verification completes.'
                      : 'Your rider profile must be active before viewing available jobs.',
                  textAlign: TextAlign.center,
                  style: AppTextStyles.bodyLarge,
                ),
                const SizedBox(height: AppSpacing.xl),
                ElevatedButton(
                  onPressed: () => Navigator.of(context).pushNamed('/rider-profile'),
                  style: ElevatedButton.styleFrom(backgroundColor: AppColors.primary),
                  child: Text('Go to Profile', style: AppTextStyles.labelMedium.copyWith(color: Colors.white)),
                ),
              ],
            ),
          ),
        ),
      );
    }

    if (!isVerified) {
      return Scaffold(
        appBar: const CustomAppBar(
          title: 'Available Jobs',
          showBackButton: false,
        ),
        body: Center(
          child: Padding(
            padding: const EdgeInsets.all(AppSpacing.lg),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(Icons.hourglass_top_outlined, size: 64, color: AppColors.textTertiary),
                const SizedBox(height: AppSpacing.lg),
                const Text(
                  'Your account is awaiting verification. You can view available jobs after approval.',
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: AppSpacing.xl),
                ElevatedButton(
                  onPressed: () => Navigator.of(context).pushNamed('/rider-profile'),
                  style: ElevatedButton.styleFrom(backgroundColor: AppColors.primary),
                  child: Text('Go to Profile', style: AppTextStyles.labelMedium.copyWith(color: Colors.white)),
                ),
              ],
            ),
          ),
        ),
      );
    }

    // Show active job even when offline; only hide available listings when not available
    if (!_riderIsAvailable && activeJob == null) {
      return Scaffold(
        appBar: const CustomAppBar(
          title: 'Available Jobs',
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
                'Toggle your availability to see available jobs',
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
    _syncActiveJobAcceptedTime(activeJob);

    // If rider has an active job, show only that job with countdown
    if (activeJob != null) {
      return WillPopScope(
        onWillPop: () async {
          if (!_canCancelJob()) {
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(
                content: Text(
                    'Please wait for the countdown to finish before leaving.'),
                backgroundColor: AppColors.warning,
                duration: Duration(seconds: 2),
              ),
            );
            return false;
          }
          return true;
        },
        child: Scaffold(
          appBar: const CustomAppBar(
            title: 'Active Job',
            showBackButton: false,
          ),
          body: SingleChildScrollView(
            padding: const EdgeInsets.all(AppSpacing.lg),
            child: Column(
              children: [
                _buildActiveJobCard(activeJob),
                const SizedBox(height: AppSpacing.xl),
                _buildCancellationSection(),
              ],
            ),
          ),
        ),
      );
    }

    final availableJobsAsync = ref.watch(availableJobsStreamProvider(const {
      'lat': 6.5244,
      'lng': 3.3792,
    }));

    // Show all available jobs
    return Scaffold(
      appBar: const CustomAppBar(
        title: 'Available Jobs',
        showBackButton: false,
      ),
      body: availableJobsAsync.when(
        data: (jobs) {
          if (jobs.isEmpty) {
            return _buildNoJobsScreen();
          }

          return ListView.builder(
            padding: const EdgeInsets.all(AppSpacing.lg),
            itemCount: jobs.length,
            itemBuilder: (context, index) {
              final job = jobs[index];
              return _buildJobCard(job);
            },
          );
        },
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (_, __) => _buildNoJobsScreen(),
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
              Navigator.of(context).pushNamed('/rider-profile');
              break;
          }
        },
      ),
    );
  }

  Widget _buildNoJobsScreen() {
    return Center(
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
            'No Available Jobs',
            style: AppTextStyles.headingSmall,
          ),
          const SizedBox(height: AppSpacing.sm),
          Text(
            'Check back later for new delivery opportunities',
            style: AppTextStyles.bodySmall,
          ),
        ],
      ),
    );
  }

  Widget _buildJobCard(Job job) {
    final priceLabel = '₦${job.estimatedFare.toStringAsFixed(0)}';
    final netPayLabel = job.platformCharge != null
        ? 'Net: ₦${(job.totalPrice != null ? job.totalPrice! - job.platformCharge! : job.estimatedFare).toStringAsFixed(0)}'
        : '';

    return CustomCard(
      margin: const EdgeInsets.only(bottom: AppSpacing.lg),
      padding: const EdgeInsets.all(AppSpacing.lg),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Price and Urgency
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    priceLabel,
                    style: AppTextStyles.headingSmall.copyWith(
                      color: AppColors.accent,
                    ),
                  ),
                  if (netPayLabel.isNotEmpty) ...[
                    const SizedBox(height: AppSpacing.xs),
                    Text(
                      netPayLabel,
                      style: AppTextStyles.captionSmall.copyWith(
                        color: AppColors.success,
                      ),
                    ),
                  ],
                ],
              ),
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: AppSpacing.md,
                  vertical: AppSpacing.sm,
                ),
                decoration: BoxDecoration(
                  color: job.urgency.toLowerCase() == 'urgent'
                      ? AppColors.error.withValues(alpha: 0.1)
                      : AppColors.info.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(AppBorderRadius.sm),
                ),
                child: Text(
                  job.urgency.toUpperCase(),
                  style: AppTextStyles.bodySmall.copyWith(
                    color: job.urgency.toLowerCase() == 'urgent'
                        ? AppColors.error
                        : AppColors.info,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: AppSpacing.lg),

          // Customer Info
          Text(
            job.customer?.fullName ?? 'Customer',
            style: AppTextStyles.labelLarge,
          ),
          const SizedBox(height: AppSpacing.xs),
          Text(
            job.customer?.phone ?? '',
            style: AppTextStyles.bodySmall.copyWith(
              color: AppColors.textSecondary,
            ),
          ),
          const SizedBox(height: AppSpacing.lg),

          // From and To
          _buildRouteSection(
            label: 'Pickup',
            location: job.pickupLocation.address,
            icon: Icons.location_on,
            color: AppColors.primary,
          ),
          const SizedBox(height: AppSpacing.lg),
          Padding(
            padding: const EdgeInsets.only(left: 20),
            child: SizedBox(
              height: 30,
              child: VerticalDivider(
                color: AppColors.border,
                thickness: 2,
              ),
            ),
          ),
          const SizedBox(height: AppSpacing.lg),
          _buildRouteSection(
            label: 'Delivery',
            location: job.dropoffLocation.address,
            icon: Icons.location_on,
            color: AppColors.accent,
          ),
          const SizedBox(height: AppSpacing.lg),
          _buildItemDetailsSection(job),
          const SizedBox(height: AppSpacing.lg),

          // Details Grid
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              _buildDetailItem(
                icon: Icons.straighten_outlined,
                label: 'Fare',
                value: priceLabel,
              ),
              _buildDetailItem(
                icon: Icons.timer_outlined,
                label: 'Status',
                value: job.status,
              ),
            ],
          ),
          const SizedBox(height: AppSpacing.xl),

          // Action Buttons
          Row(
            children: [
              Expanded(
                child: OutlinedButton(
                  onPressed: _canSuggestPrice()
                      ? () => _showPriceSuggestionDialog(job)
                      : null,
                  style: OutlinedButton.styleFrom(
                    side: const BorderSide(
                      color: AppColors.primary,
                      width: 2,
                    ),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(AppBorderRadius.md),
                    ),
                    padding: const EdgeInsets.symmetric(vertical: 12),
                  ),
                  child: Text(
                    'Suggest Price',
                    style: AppTextStyles.labelMedium.copyWith(
                      color: _canSuggestPrice()
                          ? AppColors.primary
                          : AppColors.textTertiary,
                    ),
                  ),
                ),
              ),
              const SizedBox(width: AppSpacing.md),
              Expanded(
                child: ElevatedButton(
                  onPressed: ref.read(activeRiderJobProvider) == null
                      ? () => _acceptJob(job)
                      : null,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.primary,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(AppBorderRadius.md),
                    ),
                    padding: const EdgeInsets.symmetric(vertical: 12),
                  ),
                  child: Text(
                    'Accept',
                    style: AppTextStyles.labelMedium.copyWith(
                      color: Colors.white,
                    ),
                  ),
                ),
              ),
            ],
          ),
        ],
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
          // Price and Status
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                priceLabel,
                style: AppTextStyles.headingSmall.copyWith(
                  color: AppColors.accent,
                ),
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
                  'Active',
                  style: AppTextStyles.bodySmall.copyWith(
                    color: AppColors.warning,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: AppSpacing.lg),

          // Customer
          Text(
            job.customer?.fullName ?? 'Customer',
            style: AppTextStyles.labelLarge,
          ),
          const SizedBox(height: AppSpacing.xs),
          Text(
            job.customer?.phone ?? '',
            style: AppTextStyles.bodySmall,
          ),
          const SizedBox(height: AppSpacing.lg),

          // From and To
          _buildRouteSection(
            label: 'Pickup',
            location: job.pickupLocation.address,
            icon: Icons.location_on,
            color: AppColors.primary,
          ),
          const SizedBox(height: AppSpacing.lg),
          Padding(
            padding: const EdgeInsets.only(left: 20),
            child: SizedBox(
              height: 30,
              child: VerticalDivider(
                color: AppColors.border,
                thickness: 2,
              ),
            ),
          ),
          const SizedBox(height: AppSpacing.lg),
          _buildRouteSection(
            label: 'Delivery',
            location: job.dropoffLocation.address,
            icon: Icons.location_on,
            color: AppColors.accent,
          ),
          const SizedBox(height: AppSpacing.lg),
          _buildItemDetailsSection(job),
          const SizedBox(height: AppSpacing.lg),

          // Details Grid
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              _buildDetailItem(
                icon: Icons.straighten_outlined,
                label: 'Fare',
                value: priceLabel,
              ),
              _buildDetailItem(
                icon: Icons.shopping_bag_outlined,
                label: 'Item',
                value: _jobDescription(job),
              ),
              _buildDetailItem(
                icon: Icons.timer_outlined,
                label: 'Status',
                value: job.status,
              ),
            ],
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

  Widget _buildRouteSection({
    required String label,
    required String location,
    required IconData icon,
    required Color color,
  }) {
    return Row(
      children: [
        Container(
          width: 40,
          height: 40,
          decoration: BoxDecoration(
            color: color.withValues(alpha: 0.1),
            borderRadius: BorderRadius.circular(AppBorderRadius.sm),
          ),
          child: Center(
            child: Icon(icon, color: color, size: 20),
          ),
        ),
        const SizedBox(width: AppSpacing.md),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(label, style: AppTextStyles.labelSmall),
              const SizedBox(height: AppSpacing.xs),
              Text(location, style: AppTextStyles.bodyMedium),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildDetailItem({
    required IconData icon,
    required String label,
    required String value,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.center,
      children: [
        Icon(icon, color: AppColors.primary, size: 20),
        const SizedBox(height: AppSpacing.xs),
        Text(label, style: AppTextStyles.captionSmall),
        const SizedBox(height: AppSpacing.xs),
        Text(value, style: AppTextStyles.bodySmall),
      ],
    );
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
                    'Job Locked',
                    style: AppTextStyles.labelMedium.copyWith(
                      color: AppColors.warning,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: AppSpacing.md),
              Text(
                'You can cancel this job in:',
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
        if (_canCancelJob())
          SizedBox(
            width: double.infinity,
            child: OutlinedButton(
              onPressed: _cancelActiveJob,
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
                'Cancel Job',
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
                  'Job locked. Cannot cancel yet.',
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

  String _jobDescription(Job job) {
    if (job.itemDescription.isNotEmpty) {
      return job.itemDescription;
    }

    if (job.items != null && job.items!.isNotEmpty) {
      return job.items!.map((item) => item.title).join(', ');
    }

    return 'Parcel';
  }

  // Helper Methods

  void _syncActiveJobAcceptedTime(Job? activeJob) {
    if (activeJob != null &&
        _activeJobAcceptedTime == null &&
        _hasLoadedAcceptedTimestamp) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (!mounted) return;
        setState(() {
          _activeJobAcceptedTime =
              ref.read(activeRiderJobProvider.notifier).acceptedAtMs ??
                  DateTime.now().millisecondsSinceEpoch;
        });
      });
      return;
    }

    if (activeJob == null && _activeJobAcceptedTime != null) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (!mounted) return;
        setState(() {
          _activeJobAcceptedTime = null;
        });
      });
    }
  }

  @override
  void dispose() {
    _countdownTimer?.cancel();
    super.dispose();
  }

  void _redirectToLogin() {
    if (_redirectScheduled) return;
    _redirectScheduled = true;
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      Navigator.of(context).pushReplacementNamed('/login');
    });
  }

  Future<void> _applyForJob(Job job) async {
    try {
      final jobService = ref.read(jobServiceProvider);
      await jobService.applyForJob(job.id,
          message: 'I would like to take this job');

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Application submitted successfully.'),
          backgroundColor: AppColors.success,
          duration: Duration(seconds: 3),
        ),
      );
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Failed to apply for job: $e'),
          backgroundColor: AppColors.error,
          duration: const Duration(seconds: 3),
        ),
      );
    }
  }

  Future<void> _cancelActiveJob() async {
    final job = ref.read(activeRiderJobProvider);
    if (job == null) return;

    try {
      await ref.read(jobServiceProvider).cancelJob(job.id);
      await ref.read(activeRiderJobProvider.notifier).clear();
      setState(() {
        _activeJobAcceptedTime = null;
        _pricesSuggestionTimestamps.clear();
      });

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Job cancelled successfully.'),
          backgroundColor: AppColors.error,
          duration: Duration(seconds: 2),
        ),
      );
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Failed to cancel job: $e'),
          backgroundColor: AppColors.error,
          duration: const Duration(seconds: 3),
        ),
      );
    }
  }

  Future<void> _acceptJob(Job job) async {
    try {
      // Prevent accepting if there is already an active job
      final currentActive = ref.read(activeRiderJobProvider);
      if (currentActive != null) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text(
                'You already have an active job. Complete or cancel it before accepting another.'),
            backgroundColor: AppColors.error,
          ),
        );
        return;
      }

      await ref.read(activeRiderJobProvider.notifier).acceptJob(job.id);

      setState(() {
        _activeJobAcceptedTime =
            ref.read(activeRiderJobProvider.notifier).acceptedAtMs ??
                DateTime.now().millisecondsSinceEpoch;
      });

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text(
              'Job accepted successfully. You can cancel within 2 minutes.'),
          backgroundColor: AppColors.success,
          duration: Duration(seconds: 3),
        ),
      );
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Failed to accept job: $e'),
          backgroundColor: AppColors.error,
          duration: const Duration(seconds: 3),
        ),
      );
    }
  }

  bool _canCancelJob() {
    if (_activeJobAcceptedTime == null) return false;

    final now = DateTime.now().millisecondsSinceEpoch;
    final elapsedMs = now - _activeJobAcceptedTime!;
    final threeMinutesMs = 3 * 60 * 1000;

    return elapsedMs >= threeMinutesMs;
  }

  String _calculateTimeRemaining() {
    if (_activeJobAcceptedTime == null) return '3:00';

    final now = DateTime.now().millisecondsSinceEpoch;
    final elapsedMs = now - _activeJobAcceptedTime!;
    final threeMinutesMs = 3 * 60 * 1000;
    final remainingMs = threeMinutesMs - elapsedMs;

    if (remainingMs <= 0) {
      return '0:00';
    }

    final minutes = (remainingMs ~/ 60000);
    final seconds = ((remainingMs % 60000) ~/ 1000);

    return '$minutes:${seconds.toString().padLeft(2, '0')}';
  }

  bool _canSuggestPrice() {
    final now = DateTime.now().millisecondsSinceEpoch;
    final threeMinutesAgo = now - (3 * 60 * 1000);

    _pricesSuggestionTimestamps
        .removeWhere((timestamp) => timestamp < threeMinutesAgo);

    return _pricesSuggestionTimestamps.length < 3;
  }

  void _showPriceSuggestionDialog(Job job) {
    final TextEditingController priceController = TextEditingController();

    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: const Text('Suggest Price'),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Current fare: ₦${job.estimatedFare.toStringAsFixed(0)}',
                style: AppTextStyles.bodySmall.copyWith(
                  color: AppColors.textSecondary,
                ),
              ),
              const SizedBox(height: AppSpacing.lg),
              TextField(
                controller: priceController,
                keyboardType: TextInputType.number,
                decoration: InputDecoration(
                  hintText: 'Enter your suggested price',
                  prefixText: '₦ ',
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(AppBorderRadius.md),
                  ),
                ),
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(),
              child: const Text('Cancel'),
            ),
            ElevatedButton(
              onPressed: () async {
                final priceText = priceController.text.trim();
                if (priceText.isEmpty) {
                  return;
                }

                _pricesSuggestionTimestamps
                    .add(DateTime.now().millisecondsSinceEpoch);
                Navigator.of(context).pop();

                try {
                  final jobService = ref.read(jobServiceProvider);
                  await jobService.applyForJob(
                    job.id,
                    bidPrice: priceText,
                    message: 'Counteroffer from rider',
                  );
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Text('Price suggestion of ₦$priceText sent!'),
                      backgroundColor: AppColors.success,
                      duration: const Duration(seconds: 2),
                    ),
                  );
                } catch (e) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Text('Failed to send price suggestion: $e'),
                      backgroundColor: AppColors.error,
                      duration: const Duration(seconds: 2),
                    ),
                  );
                }

                setState(() {});
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.accent,
              ),
              child: const Text(
                'Send',
                style: TextStyle(color: Colors.white),
              ),
            ),
          ],
        );
      },
    );
  }
}
