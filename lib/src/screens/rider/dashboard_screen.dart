import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../../config/theme.dart';
import '../../models/index.dart';
import '../../widgets/index.dart';
import '../../widgets/rider_bottom_nav.dart';
import '../../providers/index.dart';

class RiderDashboardScreen extends ConsumerStatefulWidget {
  const RiderDashboardScreen({Key? key}) : super(key: key);

  @override
  ConsumerState<RiderDashboardScreen> createState() =>
      _RiderDashboardScreenState();
}

class _RiderDashboardScreenState extends ConsumerState<RiderDashboardScreen> {
  bool _riderIsAvailable = false;
  bool _redirectScheduled = false;

  @override
  void initState() {
    super.initState();
    _loadRiderAvailabilityStatus();

    // Ensure the active job is recovered from server-side job_applications
    // once after the first frame (covers login and cold start).
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      try {
        // trigger provider to recover authoritative active job
        // ignore: unused_result
        ref.read(activeRiderJobProvider.notifier).recoverActiveJobFromApplications();
      } catch (_) {}
    });
  }

  void _redirectToLogin() {
    if (_redirectScheduled) return;
    _redirectScheduled = true;
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      Navigator.of(context).pushReplacementNamed('/login');
    });
  }

  Future<void> _loadRiderAvailabilityStatus() async {
    final prefs = await SharedPreferences.getInstance();
    setState(() {
      _riderIsAvailable = prefs.getBool('rider_available') ?? false;
    });
  }

  Future<void> _toggleAvailability() async {
    final auth = ref.read(authStateProvider);
    final currentUser = auth.user;

    final riderStatus = currentUser?.riderProfileStatus?.toLowerCase();
    final isVerified = currentUser?.isVerified ?? false;
    final isProfileActive = riderStatus == 'active';

    if (!isProfileActive) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            riderStatus == 'awaiting_verification'
                ? 'Your rider profile is still under review. You cannot go online until verification is complete.'
                : 'Your rider profile must be active before you can go online.',
          ),
          backgroundColor: Colors.orange,
        ),
      );
      return;
    }

    if (!isVerified) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text(
            'Your account is awaiting verification confirmation. You can go online after approval.',
          ),
          backgroundColor: Colors.orange,
        ),
      );
      return;
    }

    final prefs = await SharedPreferences.getInstance();
    setState(() {
      _riderIsAvailable = !_riderIsAvailable;
    });
    await prefs.setBool('rider_available', _riderIsAvailable);
  }

  @override
  Widget build(BuildContext context) {
    final authState = ref.watch(authStateProvider);
    if (!authState.isAuthenticated || authState.currentRole != UserType.rider) {
      _redirectToLogin();
      return Scaffold(
        appBar: AppBar(
          backgroundColor: AppColors.primary,
          elevation: 0,
          title: const Text(
            'Dashboard',
            style: TextStyle(color: Colors.white),
          ),
          centerTitle: false,
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
                  'Please login as a rider to access your dashboard.',
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

    final walletAsync = ref.watch(walletProvider);
    final activeJob = ref.watch(activeRiderJobProvider);
    final recentActivitiesAsync = ref.watch(riderRecentActivitiesProvider(10));
    final availableJobsAsync = _riderIsAvailable
        ? ref.watch(availableJobsStreamProvider(const {
            'lat': 6.5244, // Lagos coordinates
            'lng': 3.3792,
          }))
        : const AsyncValue.data([]);

    return Scaffold(
      appBar: AppBar(
        backgroundColor: AppColors.primary,
        elevation: 0,
        title: const Text(
          'Dashboard',
          style: TextStyle(color: Colors.white),
        ),
        centerTitle: false,
        actions: [
          IconButton(
            icon: const Icon(Icons.message_outlined),
            color: Colors.white,
            tooltip: 'Messages',
            onPressed: () {
              Navigator.of(context).pushNamed('/chat');
            },
          ),
          Padding(
            padding: const EdgeInsets.all(AppSpacing.md),
            child: GestureDetector(
              onTap: _toggleAvailability,
              child: Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: AppSpacing.md,
                  vertical: AppSpacing.xs,
                ),
                decoration: BoxDecoration(
                  color:
                      _riderIsAvailable ? AppColors.success : AppColors.error,
                  borderRadius: BorderRadius.circular(AppBorderRadius.full),
                  border: Border.all(
                    color: Colors.white,
                    width: 2,
                  ),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(
                      _riderIsAvailable ? Icons.check_circle : Icons.cancel,
                      color: Colors.white,
                      size: 16,
                    ),
                    const SizedBox(width: AppSpacing.xs),
                    Text(
                      _riderIsAvailable ? 'Online' : 'Offline',
                      style: AppTextStyles.labelSmall.copyWith(
                        color: Colors.white,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
      body: SingleChildScrollView(
        child: Column(
          children: [
            // Top Header - Welcome Section with Real Name
            Container(
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                  colors: [
                    const Color(0xFFF57C00),
                    const Color(0xFFF57C00).withValues(alpha: 0.7),
                  ],
                ),
              ),
              padding: const EdgeInsets.all(AppSpacing.lg),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'Welcome Back',
                              style: AppTextStyles.bodyLarge.copyWith(
                                color: Colors.white.withValues(alpha: 0.9),
                              ),
                            ),
                            const SizedBox(height: AppSpacing.md),
                            Consumer(
                              builder: (context, ref, child) {
                                final currentUser =
                                    ref.watch(currentUserProvider);
                                return Text(
                                  currentUser?.fullName ?? 'Rider',
                                  style: AppTextStyles.displaySmall.copyWith(
                                    color: Colors.white,
                                    fontWeight: FontWeight.bold,
                                  ),
                                );
                              },
                            ),
                            const SizedBox(height: AppSpacing.sm),
                            Text(
                              'Ready to earn today?',
                              style: AppTextStyles.bodySmall.copyWith(
                                color: Colors.white.withValues(alpha: 0.8),
                              ),
                            ),
                          ],
                        ),
                      ),
                      Container(
                        width: 80,
                        height: 80,
                        decoration: BoxDecoration(
                          color: Colors.white.withValues(alpha: 0.2),
                          shape: BoxShape.circle,
                          border: Border.all(
                            color: Colors.white.withValues(alpha: 0.3),
                            width: 2,
                          ),
                        ),
                        child: Center(
                          child: Icon(
                            Icons.directions_bike,
                            color: Colors.white,
                            size: 40,
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: AppSpacing.lg),
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: AppSpacing.md,
                      vertical: AppSpacing.sm,
                    ),
                    decoration: BoxDecoration(
                      color: Colors.white.withValues(alpha: 0.15),
                      borderRadius: BorderRadius.circular(AppBorderRadius.full),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(
                          Icons.info_outline,
                          color: Colors.white,
                          size: 16,
                        ),
                        const SizedBox(width: AppSpacing.xs),
                        Text(
                          'Tap your status to go online',
                          style: AppTextStyles.bodySmall.copyWith(
                            color: Colors.white.withValues(alpha: 0.9),
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),

            // Main Content
            Padding(
              padding: const EdgeInsets.all(AppSpacing.lg),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Quick Stats
                  Row(
                    children: [
                      Expanded(
                        child: walletAsync.when(
                          data: (wallet) => _buildStatCard(
                            icon: Icons.wallet_giftcard,
                            label: 'Balance',
                            value:
                                '₦${(wallet?.balance ?? 0).toStringAsFixed(0)}',
                            color: AppColors.accent,
                          ),
                          loading: () => _buildStatCard(
                            icon: Icons.wallet_giftcard,
                            label: 'Balance',
                            value: '₦0',
                            color: AppColors.accent,
                          ),
                          error: (_, __) => _buildStatCard(
                            icon: Icons.wallet_giftcard,
                            label: 'Balance',
                            value: '₦0',
                            color: AppColors.accent,
                          ),
                        ),
                      ),
                      const SizedBox(width: AppSpacing.md),
                      Expanded(
                        child: availableJobsAsync.when(
                          data: (jobs) => _buildStatCard(
                            icon: Icons.shopping_bag,
                            label: 'Available',
                            value: '${jobs.length}',
                            color: AppColors.success,
                          ),
                          loading: () => _buildStatCard(
                            icon: Icons.shopping_bag,
                            label: 'Available',
                            value: '0',
                            color: AppColors.success,
                          ),
                          error: (_, __) => _buildStatCard(
                            icon: Icons.shopping_bag,
                            label: 'Available',
                            value: '0',
                            color: AppColors.success,
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: AppSpacing.md),
                  Row(
                    children: [
                      Expanded(
                        child: _buildStatCard(
                          icon: Icons.assignment_turned_in,
                          label: 'Active Orders',
                          value: activeJob != null ? '1' : '0',
                          color: AppColors.warning,
                        ),
                      ),
                      const SizedBox(width: AppSpacing.md),
                      Expanded(
                        child: _buildStatCard(
                          icon: Icons.star_rate,
                          label: 'Rating',
                          value: '4.8', // TODO: Get from rider profile
                          color: AppColors.primary,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: AppSpacing.xl),

                  // Live Orders
                  Text('Live Orders', style: AppTextStyles.headingSmall),
                  const SizedBox(height: AppSpacing.md),
                  if (!_riderIsAvailable)
                    CustomCard(
                      padding: const EdgeInsets.all(AppSpacing.lg),
                      child: Text(
                        'You are offline. Go online to receive live orders and job updates.',
                        style: AppTextStyles.bodySmall,
                      ),
                    )
                  else
                    availableJobsAsync.when(
                      data: (jobs) {
                        if (jobs.isEmpty) {
                          return CustomCard(
                            padding: const EdgeInsets.all(AppSpacing.lg),
                            child: Text(
                              'No new jobs available right now. Stay online to receive new orders.',
                              style: AppTextStyles.bodySmall,
                            ),
                          );
                        }

                        return Column(
                        children: jobs.take(3).map((job) {
                          return Padding(
                            padding:
                                const EdgeInsets.only(bottom: AppSpacing.sm),
                            child: _buildLiveOrderPreview(job),
                          );
                        }).toList(),
                      );
                    },
                    loading: () =>
                        const Center(child: CircularProgressIndicator()),
                    error: (_, __) => CustomCard(
                      padding: const EdgeInsets.all(AppSpacing.lg),
                      child: Text(
                        'Unable to load live orders.\nPlease check your connection.',
                        style: AppTextStyles.bodySmall,
                      ),
                    ),
                  ),
                  const SizedBox(height: AppSpacing.xl),

                  // Quick Actions
                  Text('Quick Actions', style: AppTextStyles.headingSmall),
                  const SizedBox(height: AppSpacing.md),
                  Row(
                    children: [
                      Expanded(
                        child: _buildActionButton(
                          icon: Icons.assignment_outlined,
                          label: 'Available\nOrder',
                          onTap: () async {
                            await _onAvailableOrderTapped(activeJob);
                          },
                        ),
                      ),
                      const SizedBox(width: AppSpacing.md),
                      Expanded(
                        child: _buildActionButton(
                          icon: Icons.local_shipping_outlined,
                          label: 'Active\nOrder',
                          onTap: () {
                            Navigator.of(context)
                                .pushNamed('/rider-active-jobs');
                          },
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: AppSpacing.md),
                  Row(
                    children: [
                      Expanded(
                        child: _buildActionButton(
                          icon: Icons.history,
                          label: 'Order\nHistory',
                          onTap: () {
                            Navigator.of(context)
                                .pushNamed('/rider-order-history');
                          },
                        ),
                      ),
                      const SizedBox(width: AppSpacing.md),
                      Expanded(
                        child: _buildActionButton(
                          icon: Icons.account_balance_wallet,
                          label: 'Withdraw\nFunds',
                          onTap: () {
                            Navigator.of(context)
                                .pushNamed('/rider-withdrawal');
                          },
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: AppSpacing.xl),

                  // Recent Activity
                  Text('Recent Activity', style: AppTextStyles.headingSmall),
                  const SizedBox(height: AppSpacing.md),
                  recentActivitiesAsync.when(
                    data: (applications) {
                      if (applications.isEmpty) {
                        return CustomCard(
                          padding: const EdgeInsets.all(AppSpacing.lg),
                          child: Text(
                            'No recent rider activity yet. Stay online to receive live order updates.',
                            style: AppTextStyles.bodySmall,
                          ),
                        );
                      }

                      final displayCount = applications.length > 4
                          ? 4
                          : applications.length;

                      return CustomCard(
                        padding: const EdgeInsets.all(AppSpacing.lg),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: List<Widget>.generate(
                            displayCount,
                            (index) {
                              final app = applications[index];
                              return Column(
                                children: [
                                  GestureDetector(
                                    onTap: () {
                                      Navigator.of(context)
                                          .pushNamed('/rider-order-history');
                                    },
                                    child: _buildActivityItem(
                                      icon: _activityIcon(app),
                                      title: _activityTitle(app),
                                      subtitle: _activitySubtitle(app),
                                      time: _activityTimeAgo(app.createdAt),
                                      color: _activityColor(app),
                                    ),
                                  ),
                                  if (index < applications.length.clamp(0, 4) - 1) ...[
                                    const SizedBox(height: AppSpacing.lg),
                                    Divider(color: AppColors.border),
                                    const SizedBox(height: AppSpacing.lg),
                                  ],
                                ],
                              );
                            },
                          ),
                        ),
                      );
                    },
                    loading: () => CustomCard(
                      padding: const EdgeInsets.all(AppSpacing.lg),
                      child: Row(
                        children: [
                          const CircularProgressIndicator(),
                          const SizedBox(width: AppSpacing.md),
                          Text('Loading recent activity...',
                              style: AppTextStyles.bodySmall),
                        ],
                      ),
                    ),
                    error: (_, __) => CustomCard(
                      padding: const EdgeInsets.all(AppSpacing.lg),
                      child: Text(
                        'Unable to load recent activity. Pull down or reopen the dashboard to refresh.',
                        style: AppTextStyles.bodySmall,
                      ),
                    ),
                  ),
                  const SizedBox(height: AppSpacing.xl),

                  // Profile Quick Access
                  GestureDetector(
                    onTap: () {
                      Navigator.of(context).pushNamed('/rider-profile');
                    },
                    child: CustomCard(
                      padding: const EdgeInsets.all(AppSpacing.lg),
                      child: Row(
                        children: [
                          Container(
                            width: 50,
                            height: 50,
                            decoration: BoxDecoration(
                              color: AppColors.primary.withValues(alpha: 0.1),
                              shape: BoxShape.circle,
                            ),
                            child: const Center(
                              child: Icon(
                                Icons.person_outline,
                                color: AppColors.primary,
                                size: 28,
                              ),
                            ),
                          ),
                          const SizedBox(width: AppSpacing.md),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  'View Full Profile',
                                  style: AppTextStyles.bodyMedium
                                      .copyWith(fontWeight: FontWeight.bold),
                                ),
                                const SizedBox(height: AppSpacing.xs),
                                Text(
                                  'Manage settings and documents',
                                  style: AppTextStyles.bodySmall.copyWith(
                                    color: AppColors.textSecondary,
                                  ),
                                ),
                              ],
                            ),
                          ),
                          Icon(
                            Icons.arrow_forward_ios,
                            size: 16,
                            color: AppColors.textTertiary,
                          ),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
      bottomNavigationBar: RiderBottomNavigationBar(
        currentIndex: 0,
        onTap: (index) {
          final targetJobsRoute = activeJob != null ? '/rider-active-jobs' : '/rider-jobs';
          switch (index) {
            case 0:
              break;
            case 1:
              Navigator.of(context).pushReplacementNamed(targetJobsRoute);
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

  Future<void> _onAvailableOrderTapped(Job? activeJob) async {
    final authState = ref.read(authStateProvider);
    final currentUser = authState.user;

    final riderStatus = currentUser?.riderProfileStatus?.toLowerCase();
    final isVerified = currentUser?.isVerified ?? false;

    if (riderStatus != 'active') {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            riderStatus == 'awaiting_verification'
                ? 'Your rider profile is under review. You cannot view available jobs until verification completes.'
                : 'Your rider profile must be active before viewing available jobs.',
          ),
          backgroundColor: Colors.orange,
        ),
      );
      return;
    }

    if (!isVerified) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Your account is awaiting verification. You can view available jobs after approval.'),
          backgroundColor: Colors.orange,
        ),
      );
      return;
    }

    if (!_riderIsAvailable) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Go online to receive available jobs.'),
          backgroundColor: Colors.orange,
        ),
      );
      return;
    }

    final targetJobsRoute = activeJob != null ? '/rider-active-jobs' : '/rider-jobs';
    Navigator.of(context).pushNamed(targetJobsRoute);
  }

  Widget _buildStatCard({
    required IconData icon,
    required String label,
    required String value,
    required Color color,
  }) {
    return CustomCard(
      padding: const EdgeInsets.all(AppSpacing.md),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, color: color, size: 24),
          const SizedBox(height: AppSpacing.sm),
          Text(label,
              style: AppTextStyles.captionSmall.copyWith(
                color: AppColors.textSecondary,
              )),
          const SizedBox(height: AppSpacing.xs),
          Text(value,
              style: AppTextStyles.bodyLarge.copyWith(
                color: color,
                fontWeight: FontWeight.bold,
              )),
        ],
      ),
    );
  }

  Widget _buildLiveOrderPreview(Job job) {
    return GestureDetector(
      onTap: () => Navigator.of(context).pushNamed('/rider-jobs'),
      child: CustomCard(
        padding: const EdgeInsets.all(AppSpacing.lg),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
                Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Expanded(
                  child: Text(
                    job.customer?.fullName ?? 'Customer',
                    style: AppTextStyles.labelLarge,
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
                Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    // Show chat icon while job is active/delivering (until completed)
                    if (['in_progress', 'picked_up', 'delivered']
                        .contains(job.status)) ...[
                      IconButton(
                        icon: const Icon(Icons.message_outlined),
                        color: AppColors.primary,
                        onPressed: () {
                          final customerId = job.customerId ?? job.customer?.id ?? '';
                          Navigator.of(context).pushNamed(
                            '/chat-detail',
                            arguments: {
                              'userId': customerId,
                              'userName': job.customer?.fullName ?? 'Customer',
                              'riderRole': 'Customer',
                              'riderPhoneNumber': job.customer?.phone ?? '',
                            },
                          );
                        },
                      ),
                      const SizedBox(width: AppSpacing.xs),
                    ],
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: AppSpacing.sm,
                        vertical: AppSpacing.xs,
                      ),
                      decoration: BoxDecoration(
                        color: AppColors.info.withValues(alpha: 0.1),
                        borderRadius: BorderRadius.circular(AppBorderRadius.full),
                      ),
                      child: Text(
                        job.status.toUpperCase(),
                        style: AppTextStyles.captionSmall.copyWith(
                          color: AppColors.info,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                  ],
                ),
              ],
            ),
            const SizedBox(height: AppSpacing.sm),
            Text(
              job.customer?.phone ?? '',
              style: AppTextStyles.bodySmall.copyWith(
                color: AppColors.textSecondary,
              ),
            ),
            const SizedBox(height: AppSpacing.md),
            _buildRouteLabel(
                'Pickup', job.pickupLocation.address, AppColors.primary),
            const SizedBox(height: AppSpacing.sm),
            _buildRouteLabel(
                'Dropoff', job.dropoffLocation.address, AppColors.accent),
            const SizedBox(height: AppSpacing.md),
            if (job.items != null && job.items!.isNotEmpty) ...[
              Text(
                'Package details',
                style: AppTextStyles.labelSmall,
              ),
              const SizedBox(height: AppSpacing.xs),
              ...job.items!.take(2).map((item) {
                final label = item.title.isNotEmpty ? item.title : 'Package';
                final receiver = item.receiverName?.isNotEmpty == true
                    ? item.receiverName!
                    : 'Receiver';
                return Padding(
                  padding: const EdgeInsets.only(bottom: AppSpacing.xs),
                  child: Text(
                    '• $label — $receiver',
                    style: AppTextStyles.bodySmall
                        .copyWith(color: AppColors.textSecondary),
                  ),
                );
              }),
              if (job.items!.length > 2) ...[
                const SizedBox(height: AppSpacing.xs),
                Text(
                  '+${job.items!.length - 2} more packages',
                  style: AppTextStyles.captionSmall
                      .copyWith(color: AppColors.primary),
                ),
              ],
              const SizedBox(height: AppSpacing.md),
            ] else if (job.itemDescription.isNotEmpty) ...[
              Text(
                'Package details',
                style: AppTextStyles.labelSmall,
              ),
              const SizedBox(height: AppSpacing.xs),
              Text(
                job.itemDescription,
                style: AppTextStyles.bodySmall
                    .copyWith(color: AppColors.textSecondary),
              ),
              const SizedBox(height: AppSpacing.md),
            ],
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                _buildDetailItem(
                  icon: Icons.shopping_bag_outlined,
                  label: 'Item',
                  value: job.itemDescription.isNotEmpty
                      ? job.itemDescription
                      : 'Parcel',
                ),
                _buildDetailItem(
                  icon: Icons.straighten_outlined,
                  label: 'Fare',
                  value: '₦${job.estimatedFare.toStringAsFixed(0)}',
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildRouteLabel(String label, String location, Color color) {
    return Row(
      children: [
        Icon(
          label.toLowerCase() == 'pickup' ? Icons.location_on : Icons.flag,
          color: color,
          size: 18,
        ),
        const SizedBox(width: AppSpacing.xs),
        Expanded(
          child: Text(
            '$label: $location',
            style: AppTextStyles.bodySmall,
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
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Icon(icon, color: AppColors.primary, size: 18),
        const SizedBox(height: AppSpacing.xs),
        Text(label, style: AppTextStyles.captionSmall),
        const SizedBox(height: AppSpacing.xs),
        Text(value, style: AppTextStyles.bodySmall),
      ],
    );
  }

  IconData _activityIcon(JobApplication application) {
    final status = application.status?.toLowerCase() ??
        application.job?.status?.toLowerCase() ??
        'pending';

    if (status.contains('delivered') || status.contains('completed')) {
      return Icons.check_circle_outline;
    }
    if (status.contains('in_progress')) {
      return Icons.directions_bike;
    }
    if (status.contains('accepted') || status.contains('matched')) {
      return Icons.thumb_up_off_alt;
    }
    if (status.contains('cancelled') || status.contains('rejected') ||
        status.contains('withdrawn')) {
      return Icons.cancel_outlined;
    }
    return Icons.history;
  }

  String _activityTitle(JobApplication application) {
    final status = application.status?.toLowerCase() ??
        application.job?.status?.toLowerCase() ??
        'pending';

    if (status.contains('delivered') || status.contains('completed')) {
      return 'Order Completed';
    }
    if (status.contains('in_progress')) {
      return 'Order In Progress';
    }
    if (status.contains('accepted') || status.contains('matched')) {
      return 'Order Accepted';
    }
    if (status.contains('cancelled') || status.contains('rejected') ||
        status.contains('withdrawn')) {
      return 'Order Cancelled';
    }
    return 'New Order Activity';
  }

  String _activitySubtitle(JobApplication application) {
    final job = application.job;
    if (job != null) {
      final pickup = job.pickupLocation.address;
      final dropoff = job.dropoffLocation.address;
      return '${job.itemDescription.isNotEmpty ? job.itemDescription : 'Package'} • $pickup → $dropoff';
    }

    return application.riderMessage?.isNotEmpty == true
        ? application.riderMessage!
        : 'Tap to view order details';
  }

  Color _activityColor(JobApplication application) {
    final status = application.status?.toLowerCase() ??
        application.job?.status?.toLowerCase() ??
        'pending';
    if (status.contains('delivered') || status.contains('completed')) {
      return AppColors.success;
    }
    if (status.contains('in_progress')) {
      return AppColors.warning;
    }
    if (status.contains('accepted') || status.contains('matched')) {
      return AppColors.info;
    }
    if (status.contains('cancelled') || status.contains('rejected') ||
        status.contains('withdrawn')) {
      return AppColors.error;
    }
    return AppColors.primary;
  }

  String _activityTimeAgo(DateTime dateTime) {
    final difference = DateTime.now().difference(dateTime);
    if (difference.inSeconds < 60) {
      return 'Just now';
    }
    if (difference.inMinutes < 60) {
      return '${difference.inMinutes}m ago';
    }
    if (difference.inHours < 24) {
      return '${difference.inHours}h ago';
    }
    return '${difference.inDays}d ago';
  }

  Widget _buildActionButton({
    required IconData icon,
    required String label,
    required VoidCallback onTap,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: CustomCard(
        padding: const EdgeInsets.all(AppSpacing.md),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              width: 50,
              height: 50,
              decoration: BoxDecoration(
                color: AppColors.primary.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(AppBorderRadius.md),
              ),
              child: Center(
                child: Icon(
                  icon,
                  color: AppColors.primary,
                  size: 24,
                ),
              ),
            ),
            const SizedBox(height: AppSpacing.sm),
            Text(
              label,
              textAlign: TextAlign.center,
              style: AppTextStyles.bodySmall.copyWith(
                fontWeight: FontWeight.bold,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildActivityItem({
    required IconData icon,
    required String title,
    required String subtitle,
    required String time,
    required Color color,
  }) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Container(
          width: 40,
          height: 40,
          decoration: BoxDecoration(
            color: color.withValues(alpha: 0.1),
            borderRadius: BorderRadius.circular(AppBorderRadius.md),
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
              Text(title, style: AppTextStyles.bodyMedium),
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
        Text(
          time,
          style: AppTextStyles.captionSmall.copyWith(
            color: AppColors.textTertiary,
          ),
        ),
      ],
    );
  }
}

