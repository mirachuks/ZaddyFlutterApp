import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../../config/theme.dart';
import '../../widgets/index.dart';
import '../../widgets/rider_bottom_nav.dart';
import '../../providers/index.dart';

class RiderProfileScreen extends ConsumerStatefulWidget {
  const RiderProfileScreen({Key? key}) : super(key: key);

  @override
  ConsumerState<RiderProfileScreen> createState() => _RiderProfileScreenState();
}

class _RiderProfileScreenState extends ConsumerState<RiderProfileScreen> {
  bool _isAvailable = false;

  @override
  void initState() {
    super.initState();
    _loadAvailabilityStatus();
  }

  Future<void> _loadAvailabilityStatus() async {
    final prefs = await SharedPreferences.getInstance();
    setState(() {
      _isAvailable = prefs.getBool('rider_available') ?? false;
    });
  }

  Future<void> _saveAvailabilityStatus(bool value) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool('rider_available', value);
  }

  @override
  Widget build(BuildContext context) {
    final currentUser = ref.watch(currentUserProvider);

    return Scaffold(
      appBar: const CustomAppBar(
        title: 'Profile',
        showBackButton: false,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(AppSpacing.lg),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Profile Header
            CustomCard(
              padding: const EdgeInsets.all(AppSpacing.lg),
              child: Column(
                children: [
                  Container(
                    width: 80,
                    height: 80,
                    decoration: BoxDecoration(
                      color: AppColors.primary.withValues(alpha: 0.1),
                      shape: BoxShape.circle,
                    ),
                    child: const Center(
                      child: Icon(
                        Icons.person_outline,
                        color: AppColors.primary,
                        size: 40,
                      ),
                    ),
                  ),
                  const SizedBox(height: AppSpacing.md),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Expanded(
                        child: Column(
                          children: [
                            Text(
                              currentUser?.firstName ?? 'First',
                              style: AppTextStyles.bodyMedium.copyWith(
                                color: AppColors.textSecondary,
                              ),
                              textAlign: TextAlign.center,
                            ),
                            const SizedBox(height: AppSpacing.xs),
                            Text(
                              currentUser?.lastName ?? 'Last',
                              style: AppTextStyles.headingMedium,
                              textAlign: TextAlign.center,
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: AppSpacing.md),
                  Text(
                    currentUser?.email ?? 'email@example.com',
                    style: AppTextStyles.bodySmall,
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: AppSpacing.xs),
                  Text(
                    currentUser?.phone ?? '+234 0000 0000',
                    style: AppTextStyles.bodySmall,
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: AppSpacing.md),
                  // Availability Toggle
                  Container(
                    padding: const EdgeInsets.all(AppSpacing.md),
                    decoration: BoxDecoration(
                      color: _isAvailable
                          ? AppColors.success.withValues(alpha: 0.1)
                          : AppColors.error.withValues(alpha: 0.1),
                      borderRadius: BorderRadius.circular(AppBorderRadius.md),
                    ),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Row(
                          children: [
                            Icon(
                              _isAvailable
                                  ? Icons.check_circle
                                  : Icons.remove_circle,
                              color: _isAvailable
                                  ? AppColors.success
                                  : AppColors.error,
                              size: 24,
                            ),
                            const SizedBox(width: AppSpacing.md),
                            Text(
                              _isAvailable ? 'Available' : 'Not Available',
                              style: AppTextStyles.labelMedium.copyWith(
                                color: _isAvailable
                                    ? AppColors.success
                                    : AppColors.error,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ],
                        ),
                        Switch(
                          value: _isAvailable,
                          activeColor: AppColors.success,
                          inactiveThumbColor: AppColors.error,
                          onChanged: (value) async {
                            final riderStatus = currentUser?.riderProfileStatus?.toLowerCase();
                            final canGoOnline = riderStatus == 'active' && (currentUser?.isVerified ?? false);

                            if (value && !canGoOnline) {
                              if (!mounted) return;
                              ScaffoldMessenger.of(context).showSnackBar(
                                SnackBar(
                                  content: Text(
                                    riderStatus == 'awaiting_verification'
                                        ? 'Your rider profile is under review. You cannot go online yet.'
                                        : 'Your account must be verified and active before going online.',
                                  ),
                                  backgroundColor: Colors.orange,
                                ),
                              );
                              return;
                            }

                            setState(() => _isAvailable = value);
                            await _saveAvailabilityStatus(value);
                            if (!mounted) return;
                            ScaffoldMessenger.of(context).showSnackBar(
                              SnackBar(
                                content: Text(
                                  value
                                      ? 'You are now available for orders'
                                      : 'You are now unavailable',
                                ),
                                backgroundColor: value
                                    ? AppColors.success
                                    : AppColors.error,
                              ),
                            );
                          },
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: AppSpacing.md),
                  // Edit Profile Button
                  SizedBox(
                    width: double.infinity,
                    child: ElevatedButton.icon(
                      onPressed: () =>
                          Navigator.of(context).pushNamed('/rider-edit-profile'),
                      icon: const Icon(Icons.edit),
                      label: const Text('Edit Profile'),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppColors.accent,
                      ),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: AppSpacing.xl),

            // Bank Details
            Text('Bank Details', style: AppTextStyles.headingSmall),
            const SizedBox(height: AppSpacing.md),
            Consumer(
              builder: (context, ref, child) {
                final riderProfileAsync = ref.watch(riderProfileProvider);
                return riderProfileAsync.when(
                  data: (profile) {
                    final hasBank = profile.hasBankDetails;
                    return CustomCard(
                      padding: const EdgeInsets.all(AppSpacing.lg),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Container(
                            padding: const EdgeInsets.all(AppSpacing.md),
                            decoration: BoxDecoration(
                              border: Border.all(
                                color: AppColors.textSecondary.withValues(alpha: 0.2),
                                width: 1,
                              ),
                              borderRadius: BorderRadius.circular(AppBorderRadius.md),
                            ),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Row(
                                  children: [
                                    Icon(Icons.account_balance,
                                        color: AppColors.primary, size: 24),
                                    const SizedBox(width: AppSpacing.md),
                                    Expanded(
                                      child: Column(
                                        crossAxisAlignment: CrossAxisAlignment.start,
                                        children: [
                                          Text('Bank Account',
                                            style: AppTextStyles.bodySmall.copyWith(
                                              color: AppColors.textSecondary,
                                            ),
                                          ),
                                          const SizedBox(height: AppSpacing.xs),
                                          if (hasBank) ...[
                                            Text(
                                              profile.bankName ?? 'Unknown bank',
                                              style: AppTextStyles.bodyMedium,
                                            ),
                                            const SizedBox(height: AppSpacing.xs),
                                            Text(
                                              profile.bankAccountNumber ?? '',
                                              style: AppTextStyles.bodyMedium,
                                            ),
                                            const SizedBox(height: AppSpacing.xs),
                                            Text(
                                              profile.bankAccountName ?? '',
                                              style: AppTextStyles.bodyMedium,
                                            ),
                                          ] else ...[
                                            Text('No bank details added yet',
                                              style: AppTextStyles.bodyMedium,
                                            ),
                                          ],
                                        ],
                                      ),
                                    ),
                                  ],
                                ),
                              ],
                            ),
                          ),
                          const SizedBox(height: AppSpacing.md),
                          SizedBox(
                            width: double.infinity,
                            child: ElevatedButton.icon(
                              onPressed: () =>
                                  Navigator.of(context).pushNamed('/rider-update-bank-details'),
                              icon: const Icon(Icons.edit),
                              label: Text(hasBank ? 'Update Bank Details' : 'Add Bank Details'),
                              style: ElevatedButton.styleFrom(
                                backgroundColor: AppColors.accent,
                              ),
                            ),
                          ),
                        ],
                      ),
                    );
                  },
                  loading: () => const CustomCard(
                    padding: EdgeInsets.all(AppSpacing.lg),
                    child: Center(child: CircularProgressIndicator()),
                  ),
                  error: (error, stack) => CustomCard(
                    padding: const EdgeInsets.all(AppSpacing.lg),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text('Unable to load bank details.',
                          style: AppTextStyles.bodyMedium),
                        const SizedBox(height: AppSpacing.sm),
                        Text(error.toString(), style: AppTextStyles.bodySmall),
                        const SizedBox(height: AppSpacing.md),
                        SizedBox(
                          width: double.infinity,
                          child: ElevatedButton.icon(
                            onPressed: () =>
                                Navigator.of(context).pushNamed('/rider-update-bank-details'),
                            icon: const Icon(Icons.edit),
                            label: const Text('Update Bank Details'),
                            style: ElevatedButton.styleFrom(
                              backgroundColor: AppColors.accent,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                );
              },
            ),
            const SizedBox(height: AppSpacing.xl),


            // Stats
            Text('Stats', style: AppTextStyles.headingSmall),
            const SizedBox(height: AppSpacing.md),
            Consumer(
              builder: (context, ref, child) {
                final riderApplicationsAsync = ref.watch(riderApplicationsProvider);
                final walletAsync = ref.watch(walletProvider);
                
                return Row(
                  children: [
                    Expanded(
                      child: riderApplicationsAsync.when(
                        data: (applications) => CustomCard(
                          padding: const EdgeInsets.all(AppSpacing.md),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text('Total Deliveries',
                                  style: AppTextStyles.bodySmall),
                              const SizedBox(height: AppSpacing.sm),
                              Text('${applications.length}', 
                                style: AppTextStyles.headingSmall),
                            ],
                          ),
                        ),
                        loading: () => const CustomCard(
                          padding: EdgeInsets.all(AppSpacing.md),
                          child: Center(child: CircularProgressIndicator()),
                        ),
                        error: (_, __) => CustomCard(
                          padding: const EdgeInsets.all(AppSpacing.md),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text('Total Deliveries',
                                  style: AppTextStyles.bodySmall),
                              const SizedBox(height: AppSpacing.sm),
                              Text('0', style: AppTextStyles.headingSmall),
                            ],
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(width: AppSpacing.md),
                    Expanded(
                      child: Consumer(
                        builder: (context, ref, child) {
                          final transactionsAsync = ref.watch(transactionsProvider(1));
                          
                          return transactionsAsync.when(
                            data: (transactions) {
                              // Calculate this month's earnings
                              final now = DateTime.now();
                              final thisMonthStart = DateTime(now.year, now.month, 1);
                              final thisMonthEnd = DateTime(now.year, now.month + 1, 0, 23, 59, 59);
                              
                              final monthlyEarnings = transactions
                                  .where((t) => 
                                    t.transactionType == 'credit' &&
                                    (t.purpose == 'Job Earnings' || t.purpose == 'delivery' || t.purpose.isEmpty) &&
                                    t.createdAt.isAfter(thisMonthStart) &&
                                    t.createdAt.isBefore(thisMonthEnd)
                                  )
                                  .fold<double>(0.0, (sum, t) => sum + t.amount);
                              
                              return CustomCard(
                                padding: const EdgeInsets.all(AppSpacing.md),
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text('This Month Earnings',
                                        style: AppTextStyles.bodySmall),
                                    const SizedBox(height: AppSpacing.sm),
                                    Text('₦${monthlyEarnings.toStringAsFixed(0)}', 
                                      style: AppTextStyles.headingSmall),
                                  ],
                                ),
                              );
                            },
                            loading: () => const CustomCard(
                              padding: EdgeInsets.all(AppSpacing.md),
                              child: Center(child: CircularProgressIndicator()),
                            ),
                            error: (_, __) => CustomCard(
                              padding: const EdgeInsets.all(AppSpacing.md),
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text('This Month Earnings',
                                      style: AppTextStyles.bodySmall),
                                  const SizedBox(height: AppSpacing.sm),
                                  Text('₦0', style: AppTextStyles.headingSmall),
                                ],
                              ),
                            ),
                          );
                        },
                      ),
                    ),
                  ],
                );
              },
            ),
            const SizedBox(height: AppSpacing.xl),

            // Policy
            Text('Policy & Support', style: AppTextStyles.headingSmall),
            const SizedBox(height: AppSpacing.md),
            CustomCard(
              padding: const EdgeInsets.all(AppSpacing.md),
              onTap: () => Navigator.of(context).pushNamed('/rider-policy'),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Row(
                    children: [
                      Icon(Icons.description_outlined, 
                        color: AppColors.primary, size: 24),
                      const SizedBox(width: AppSpacing.md),
                      Text('Privacy Policy', 
                        style: AppTextStyles.bodyMedium),
                    ],
                  ),
                  Icon(Icons.arrow_forward_ios,
                    size: 16, color: AppColors.textTertiary),
                ],
              ),
            ),
            const SizedBox(height: AppSpacing.xl),

            // Logout
            CustomCard(
              padding: const EdgeInsets.all(AppSpacing.md),
              onTap: () {
                showDialog(
                  context: context,
                  builder: (context) => AlertDialog(
                    title: const Text('Log Out'),
                    content: const Text('Are you sure you want to log out?'),
                    actions: [
                      TextButton(
                        onPressed: () => Navigator.pop(context),
                        child: const Text('Cancel'),
                      ),
                      TextButton(
                        onPressed: () async {
                          Navigator.pop(context);
                          await ref.read(authStateProvider.notifier).logout();
                          if (!mounted) return;
                          Navigator.of(context).pushReplacementNamed('/login');
                        },
                        child: const Text('Log Out', 
                          style: TextStyle(color: AppColors.error)),
                      ),
                    ],
                  ),
                );
              },
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Row(
                    children: [
                      const Icon(Icons.logout_outlined, 
                        color: AppColors.error, size: 24),
                      const SizedBox(width: AppSpacing.md),
                      Text('Log Out', 
                        style: AppTextStyles.bodyMedium.copyWith(
                          color: AppColors.error,
                        )),
                    ],
                  ),
                  Icon(Icons.arrow_forward_ios,
                    size: 16, color: AppColors.textTertiary),
                ],
              ),
            ),
            const SizedBox(height: AppSpacing.xxxl),
          ],
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
                  break;
              }
            },
          );
        },
      ),
    );
  }
}
