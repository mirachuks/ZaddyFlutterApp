import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../config/theme.dart';
import '../../widgets/index.dart';
import '../../providers/index.dart';

class CustomerHomeScreen extends ConsumerStatefulWidget {
  const CustomerHomeScreen({Key? key}) : super(key: key);

  @override
  ConsumerState<CustomerHomeScreen> createState() => _CustomerHomeScreenState();
}

class _CustomerHomeScreenState extends ConsumerState<CustomerHomeScreen> {
  @override
  Widget build(BuildContext context) {
    final walletAsync = ref.watch(walletProvider);
    final jobsAsync = ref.watch(customerJobsProvider(1));

    return Scaffold(
      appBar: AppBar(
        title: const Text('ZaddyExpress'),
        centerTitle: false,
        elevation: 0,
        actions: [
          IconButton(
            icon: const Icon(Icons.notifications_outlined),
            onPressed: () => Navigator.of(context).pushNamed('/notifications'),
          ),
        ],
      ),
      body: SingleChildScrollView(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Wallet Balance Section
            walletAsync.when(
              data: (wallet) => _buildWalletCard(wallet?.balance ?? 0.0),
              loading: () => _buildWalletCardLoading(),
              error: (error, stack) => _buildWalletCard(0.0),
            ),

            const SizedBox(height: AppSpacing.lg),
            // Recent wallet activity section
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: AppSpacing.lg),
              child: Text('Wallet Activity', style: AppTextStyles.headingMedium),
            ),
            const SizedBox(height: AppSpacing.sm),
            Consumer(
              builder: (context, ref, child) {
                final transactionsAsync = ref.watch(transactionsProvider(1));

                return transactionsAsync.when(
                  data: (transactions) {
                    if (transactions.isEmpty) {
                      return Padding(
                        padding: const EdgeInsets.symmetric(horizontal: AppSpacing.lg),
                        child: Text(
                          'No wallet activity yet. Your top ups and withdrawals will appear here.',
                          style: AppTextStyles.bodySmall.copyWith(
                            color: AppColors.textSecondary,
                          ),
                        ),
                      );
                    }

                    final recentTransactions = transactions.take(3).toList();
                    return ListView.separated(
                      shrinkWrap: true,
                      physics: const NeverScrollableScrollPhysics(),
                      padding: const EdgeInsets.symmetric(horizontal: AppSpacing.lg),
                      itemCount: recentTransactions.length,
                      separatorBuilder: (_, __) => const SizedBox(height: AppSpacing.md),
                      itemBuilder: (context, index) {
                        final transaction = recentTransactions[index];
                        final isCredit = transaction.transactionType == 'credit';
                        final amountColor = isCredit ? AppColors.success : AppColors.error;
                        final label = transaction.purpose.isNotEmpty
                            ? transaction.purpose.replaceAll('_', ' ').toUpperCase()
                            : transaction.transactionType.toUpperCase();

                        return CustomCard(
                          padding: const EdgeInsets.all(AppSpacing.md),
                          child: Row(
                            children: [
                              Container(
                                width: 45,
                                height: 45,
                                decoration: BoxDecoration(
                                  color: amountColor.withOpacity(0.1),
                                  borderRadius: BorderRadius.circular(AppBorderRadius.md),
                                ),
                                child: Icon(
                                  isCredit ? Icons.arrow_upward : Icons.arrow_downward,
                                  color: amountColor,
                                ),
                              ),
                              const SizedBox(width: AppSpacing.md),
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(label, style: AppTextStyles.bodyLarge),
                                    const SizedBox(height: AppSpacing.xs),
                                    Text(
                                      transaction.comment ?? transaction.description ?? '',
                                      style: AppTextStyles.captionSmall,
                                      maxLines: 1,
                                      overflow: TextOverflow.ellipsis,
                                    ),
                                  ],
                                ),
                              ),
                              Text(
                                '${isCredit ? '+' : '-'}₦${transaction.amount.toStringAsFixed(0)}',
                                style: AppTextStyles.bodyLarge.copyWith(
                                  color: amountColor,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ],
                          ),
                        );
                      },
                    );
                  },
                  loading: () => const Padding(
                    padding: EdgeInsets.symmetric(horizontal: AppSpacing.lg),
                    child: Center(child: CircularProgressIndicator()),
                  ),
                  error: (error, stackTrace) => Padding(
                    padding: const EdgeInsets.symmetric(horizontal: AppSpacing.lg),
                    child: Text(
                      'Unable to load wallet activity.',
                      style: AppTextStyles.bodySmall.copyWith(
                        color: AppColors.error,
                      ),
                    ),
                  ),
                );
              },
            ),

            const SizedBox(height: AppSpacing.lg),
            // Quick Stats Section
            Container(
              padding: const EdgeInsets.all(AppSpacing.lg),
              margin: const EdgeInsets.all(AppSpacing.lg),
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: [AppColors.primary, AppColors.primaryDark],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
                borderRadius: BorderRadius.circular(AppBorderRadius.lg),
              ),
              child: jobsAsync.when(
                data: (jobs) {
                  final allJobs = jobs.toList();
                  final totalOrders = allJobs.length;
                  final activeOrders = allJobs.where((j) => !['delivered','completed','cancelled'].contains(j.status)).length;
                  final deliveredOrders = allJobs.where((j) => j.status == 'delivered').length;
                  final completedOrders = allJobs.where((j) => j.status == 'completed').length;
                   

                  return Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Quick Stats',
                        style: AppTextStyles.bodyMedium.copyWith(
                          color: AppColors.textInverse.withOpacity(0.8),
                        ),
                      ),
                      const SizedBox(height: AppSpacing.md),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          _StatCard(label: 'Total Orders', value: totalOrders.toString()),
                          _StatCard(label: 'Active', value: activeOrders.toString()),
                          _StatCard(label: 'Delivered', value: deliveredOrders.toString()),
                          _StatCard(label: 'Completed', value: completedOrders.toString()),
                        ],
                      ),
                    ],
                  );
                },
                loading: () => _buildStatsLoading(),
                error: (error, stack) => Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Quick Stats',
                      style: AppTextStyles.bodyMedium.copyWith(
                        color: AppColors.textInverse.withOpacity(0.8),
                      ),
                    ),
                    const SizedBox(height: AppSpacing.md),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        _StatCard(label: 'Total Orders', value: '0'),
                        _StatCard(label: 'Active', value: '0'),
                        _StatCard(label: 'Completed', value: '0'),
                      ],
                    ),
                  ],
                ),
              ),
            ),

            // Post Delivery Button
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: AppSpacing.lg),
              child: PrimaryButton(
                label: 'Post a Delivery',
                onPressed: () =>
                    Navigator.of(context).pushNamed('/post-delivery'),
              ),
            ),

            const SizedBox(height: AppSpacing.xl),

            // Recent Orders Section
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: AppSpacing.lg),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    'Recent Orders',
                    style: AppTextStyles.headingMedium,
                  ),
                  GestureDetector(
                    onTap: () =>
                        Navigator.of(context).pushNamed('/customer-orders'),
                    child: Text(
                      'View All',
                      style: AppTextStyles.labelMedium.copyWith(
                        color: AppColors.primary,
                      ),
                    ),
                  ),
                ],
              ),
            ),

            const SizedBox(height: AppSpacing.md),

            // Orders List
            jobsAsync.when(
              data: (jobs) {
                if (jobs.isEmpty) {
                  return Padding(
                    padding: const EdgeInsets.symmetric(horizontal: AppSpacing.lg),
                    child: Container(
                      width: double.infinity,
                      padding: const EdgeInsets.all(AppSpacing.lg),
                      decoration: BoxDecoration(
                        border: Border.all(
                          color: AppColors.textSecondary.withValues(alpha: 0.2),
                          width: 1,
                        ),
                        borderRadius: BorderRadius.circular(AppBorderRadius.md),
                      ),
                      child: Center(
                        child: Text(
                          'No order history yet',
                          style: AppTextStyles.bodyMedium.copyWith(
                            color: AppColors.textSecondary,
                          ),
                        ),
                      ),
                    ),
                  );
                }

                // Show only last 3 orders
                final recentJobs = jobs.take(3).toList();

                return ListView.builder(
                  shrinkWrap: true,
                  physics: const NeverScrollableScrollPhysics(),
                  padding: const EdgeInsets.symmetric(horizontal: AppSpacing.lg),
                  itemCount: recentJobs.length,
                  itemBuilder: (context, index) {
                    final job = recentJobs[index];
                    final statusColor = _getStatusColor(job.status);

                    return GestureDetector(
                      onTap: () {
                        Navigator.of(context).pushNamed(
                          '/order-details',
                          arguments: job.id,
                        );
                      },
                      child: _OrderCard(
                        title: 'Order #${job.id}',
                        location: '${job.pickupLocation.address} → ${job.dropoffLocation.address}',
                        status: _formatStatus(job.status),
                        statusColor: statusColor,
                      ),
                    );
                  },
                );
              },
              loading: () => Padding(
                padding: const EdgeInsets.symmetric(horizontal: AppSpacing.lg),
                child: ListView.builder(
                  shrinkWrap: true,
                  physics: const NeverScrollableScrollPhysics(),
                  itemCount: 2,
                  itemBuilder: (context, index) => Container(
                    margin: const EdgeInsets.only(bottom: AppSpacing.md),
                    padding: const EdgeInsets.all(AppSpacing.md),
                    decoration: BoxDecoration(
                      color: AppColors.textSecondary.withValues(alpha: 0.1),
                      borderRadius: BorderRadius.circular(AppBorderRadius.md),
                    ),
                    height: 80,
                    child: const Center(
                      child: CircularProgressIndicator(),
                    ),
                  ),
                ),
              ),
              error: (error, stack) => Padding(
                padding: const EdgeInsets.symmetric(horizontal: AppSpacing.lg),
                child: Container(
                  width: double.infinity,
                  padding: const EdgeInsets.all(AppSpacing.lg),
                  decoration: BoxDecoration(
                    border: Border.all(
                      color: AppColors.error.withValues(alpha: 0.3),
                      width: 1,
                    ),
                    borderRadius: BorderRadius.circular(AppBorderRadius.md),
                  ),
                  child: Center(
                    child: Text(
                      'Unable to load orders',
                      style: AppTextStyles.bodyMedium.copyWith(
                        color: AppColors.error,
                      ),
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

  Widget _buildWalletCard(double balance) {
    final formattedBalance = balance.toStringAsFixed(2);
    return Container(
      padding: const EdgeInsets.all(AppSpacing.lg),
      margin: const EdgeInsets.all(AppSpacing.lg),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [AppColors.success, AppColors.success.withOpacity(0.7)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(AppBorderRadius.lg),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Wallet Balance',
                style: AppTextStyles.labelMedium.copyWith(
                  color: AppColors.textInverse.withOpacity(0.9),
                ),
              ),
              const SizedBox(height: AppSpacing.sm),
              Text(
                '₦$formattedBalance',
                style: AppTextStyles.displaySmall.copyWith(
                  color: AppColors.textInverse,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ],
          ),
          ElevatedButton(
            onPressed: () {
              Navigator.of(context).pushNamed('/topup');
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.textInverse.withOpacity(0.9),
              padding: const EdgeInsets.symmetric(
                horizontal: AppSpacing.lg,
                vertical: AppSpacing.md,
              ),
            ),
            child: Text(
              'Top Up',
              style: AppTextStyles.labelMedium.copyWith(
                color: AppColors.success,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildWalletCardLoading() {
    return Container(
      padding: const EdgeInsets.all(AppSpacing.lg),
      margin: const EdgeInsets.all(AppSpacing.lg),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [AppColors.success, AppColors.success.withOpacity(0.7)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(AppBorderRadius.lg),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Wallet Balance',
                style: AppTextStyles.labelMedium.copyWith(
                  color: AppColors.textInverse.withOpacity(0.9),
                ),
              ),
              const SizedBox(height: AppSpacing.sm),
              SizedBox(
                width: 120,
                height: 28,
                child: Container(
                  decoration: BoxDecoration(
                    color: AppColors.textInverse.withValues(alpha: 0.2),
                    borderRadius: BorderRadius.circular(AppBorderRadius.sm),
                  ),
                ),
              ),
            ],
          ),
          const CircularProgressIndicator(
            valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
          ),
        ],
      ),
    );
  }

  Widget _buildStatsLoading() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Quick Stats',
          style: AppTextStyles.bodyMedium.copyWith(
            color: AppColors.textInverse.withOpacity(0.8),
          ),
        ),
        const SizedBox(height: AppSpacing.md),
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Expanded(
              child: Container(
                height: 60,
                decoration: BoxDecoration(
                  color: AppColors.textInverse.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(AppBorderRadius.md),
                ),
              ),
            ),
            const SizedBox(width: AppSpacing.md),
            Expanded(
              child: Container(
                height: 60,
                decoration: BoxDecoration(
                  color: AppColors.textInverse.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(AppBorderRadius.md),
                ),
              ),
            ),
            const SizedBox(width: AppSpacing.md),
            Expanded(
              child: Container(
                height: 60,
                decoration: BoxDecoration(
                  color: AppColors.textInverse.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(AppBorderRadius.md),
                ),
              ),
            ),
          ],
        ),
      ],
    );
  }

  Color _getStatusColor(String status) {
    switch (status.toLowerCase()) {
      case 'posted':
        return AppColors.info;
      case 'accepted':
        return AppColors.info;
      case 'picked_up':
        return AppColors.warning;
      case 'in_progress':
        return AppColors.warning;
      case 'delivered':
        return AppColors.primary;
      case 'completed':
        return AppColors.success;
      case 'cancelled':
        return AppColors.error;
      default:
        return AppColors.textSecondary;
    }
  }

  String _formatStatus(String status) {
    switch (status.toLowerCase()) {
      case 'posted':
        return 'Posted';
      case 'accepted':
        return 'Accepted';
      case 'picked_up':
        return 'In Transit';
      case 'delivered':
        return 'Delivered';
      case 'completed':
        return 'Completed';
      case 'cancelled':
        return 'Cancelled';
      default:
        return status;
    }
  }
}

class _StatCard extends StatelessWidget {
  final String label;
  final String value;

  const _StatCard({
    required this.label,
    required this.value,
  });

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            value,
            style: AppTextStyles.headingLarge.copyWith(
              color: AppColors.textInverse,
            ),
          ),
          const SizedBox(height: AppSpacing.xs),
          Text(
            label,
            style: AppTextStyles.captionSmall.copyWith(
              color: AppColors.textInverse.withOpacity(0.8),
            ),
          ),
        ],
      ),
    );
  }
}

class _OrderCard extends StatelessWidget {
  final String title;
  final String location;
  final String status;
  final Color statusColor;

  const _OrderCard({
    required this.title,
    required this.location,
    required this.status,
    required this.statusColor,
  });

  @override
  Widget build(BuildContext context) {
    return CustomCard(
      margin: const EdgeInsets.only(bottom: AppSpacing.md),
      padding: const EdgeInsets.all(AppSpacing.md),
      child: Row(
        children: [
          Container(
            width: 50,
            height: 50,
            decoration: BoxDecoration(
              color: statusColor.withOpacity(0.1),
              borderRadius: BorderRadius.circular(AppBorderRadius.md),
            ),
            child: Center(
              child: Icon(
                Icons.local_shipping_outlined,
                color: statusColor,
                size: 24,
              ),
            ),
          ),
          const SizedBox(width: AppSpacing.md),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: AppTextStyles.bodyLarge,
                ),
                const SizedBox(height: AppSpacing.xs),
                Text(
                  location,
                  style: AppTextStyles.bodySmall,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ],
            ),
          ),
          Container(
            padding: const EdgeInsets.symmetric(
              horizontal: AppSpacing.md,
              vertical: AppSpacing.xs,
            ),
            decoration: BoxDecoration(
              color: statusColor.withOpacity(0.1),
              borderRadius: BorderRadius.circular(AppBorderRadius.sm),
            ),
            child: Text(
              status,
              style: AppTextStyles.labelSmall.copyWith(color: statusColor),
            ),
          ),
        ],
      ),
    );
  }
}
