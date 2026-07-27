import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../config/theme.dart';
import '../../widgets/index.dart';
import '../../widgets/rider_bottom_nav.dart';
import '../../providers/index.dart';

class RiderEarningsScreen extends ConsumerStatefulWidget {
  const RiderEarningsScreen({Key? key}) : super(key: key);

  @override
  ConsumerState<RiderEarningsScreen> createState() => _RiderEarningsScreenState();
}

class _RiderEarningsScreenState extends ConsumerState<RiderEarningsScreen>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Earnings'),
        centerTitle: false,
      ),
      body: Column(
        children: [
          // Wallet Summary
          Consumer(
            builder: (context, ref, child) {
              final walletAsync = ref.watch(walletProvider);
              
              return walletAsync.when(
                data: (wallet) => Container(
                  padding: const EdgeInsets.all(AppSpacing.lg),
                  color: AppColors.background,
                  child: CustomCard(
                    padding: const EdgeInsets.all(AppSpacing.lg),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text('Wallet Balance', style: AppTextStyles.bodySmall),
                        const SizedBox(height: AppSpacing.sm),
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Text(
                              '₦${(wallet?.balance ?? 0).toStringAsFixed(0)}',
                              style: AppTextStyles.displayLarge,
                            ),
                            GestureDetector(
                              onTap: () =>
                                  Navigator.of(context).pushNamed('/withdraw'),
                              child: Container(
                                padding: const EdgeInsets.symmetric(
                                  horizontal: AppSpacing.md,
                                  vertical: AppSpacing.sm,
                                ),
                                decoration: BoxDecoration(
                                  color: AppColors.accent,
                                  borderRadius:
                                      BorderRadius.circular(AppBorderRadius.md),
                                ),
                                child: Text(
                                  'Withdraw',
                                  style: AppTextStyles.labelSmall.copyWith(
                                    color: AppColors.textInverse,
                                  ),
                                ),
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                ),
                loading: () => Container(
                  padding: const EdgeInsets.all(AppSpacing.lg),
                  color: AppColors.background,
                  child: const CustomCard(
                    padding: EdgeInsets.all(AppSpacing.lg),
                    child: Center(child: CircularProgressIndicator()),
                  ),
                ),
                error: (error, stackTrace) => Container(
                  padding: const EdgeInsets.all(AppSpacing.lg),
                  color: AppColors.background,
                  child: CustomCard(
                    padding: const EdgeInsets.all(AppSpacing.lg),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text('Wallet Balance', style: AppTextStyles.bodySmall),
                        const SizedBox(height: AppSpacing.sm),
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Text(
                              '₦0',
                              style: AppTextStyles.displayLarge,
                            ),
                            GestureDetector(
                              onTap: () =>
                                  Navigator.of(context).pushNamed('/withdraw'),
                              child: Container(
                                padding: const EdgeInsets.symmetric(
                                  horizontal: AppSpacing.md,
                                  vertical: AppSpacing.sm,
                                ),
                                decoration: BoxDecoration(
                                  color: AppColors.accent,
                                  borderRadius:
                                      BorderRadius.circular(AppBorderRadius.md),
                                ),
                                child: Text(
                                  'Withdraw',
                                  style: AppTextStyles.labelSmall.copyWith(
                                    color: AppColors.textInverse,
                                  ),
                                ),
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                ),
              );
            },
          ),

          // Stats
          // Consumer(
          //   builder: (context, ref, child) {
          //     final walletAsync = ref.watch(walletProvider);
          //     final riderApplicationsAsync = ref.watch(riderApplicationsProvider);
              
          //     return Container(
          //       padding: const EdgeInsets.all(AppSpacing.lg),
          //       color: AppColors.background,
          //       child: Row(
          //         children: [
          //           Expanded(
          //             child: walletAsync.when(
          //               data: (wallet) => CustomCard(
          //                 padding: const EdgeInsets.all(AppSpacing.md),
          //                 child: Column(
          //                   crossAxisAlignment: CrossAxisAlignment.start,
          //                   children: [
          //                     Icon(Icons.trending_up,
          //                         color: AppColors.success, size: 24),
          //                     const SizedBox(height: AppSpacing.sm),
          //                     Text('Total Earned', style: AppTextStyles.captionSmall),
          //                     const SizedBox(height: AppSpacing.xs),
          //                     Text('₦${(wallet?.totalEarnings ?? 0).toStringAsFixed(0)}', style: AppTextStyles.bodyLarge),
          //                   ],
          //                 ),
          //               ),
          //               loading: () => const CustomCard(
          //                 padding: EdgeInsets.all(AppSpacing.md),
          //                 child: Center(child: CircularProgressIndicator()),
          //               ),
          //               error: (_, __) => CustomCard(
          //                 padding: const EdgeInsets.all(AppSpacing.md),
          //                 child: Column(
          //                   crossAxisAlignment: CrossAxisAlignment.start,
          //                   children: [
          //                     Icon(Icons.trending_up,
          //                         color: AppColors.success, size: 24),
          //                     const SizedBox(height: AppSpacing.sm),
          //                     Text('Total Earned', style: AppTextStyles.captionSmall),
          //                     const SizedBox(height: AppSpacing.xs),
          //                     Text('₦0', style: AppTextStyles.bodyLarge),
          //                   ],
          //                 ),
          //               ),
          //             ),
          //           ),
          //           const SizedBox(width: AppSpacing.md),
          //           Expanded(
          //             child: riderApplicationsAsync.when(
          //               data: (applications) => CustomCard(
          //                 padding: const EdgeInsets.all(AppSpacing.md),
          //                 child: Column(
          //                   crossAxisAlignment: CrossAxisAlignment.start,
          //                   children: [
          //                     Icon(Icons.local_shipping_outlined,
          //                         color: AppColors.info, size: 24),
          //                     const SizedBox(height: AppSpacing.sm),
          //                     Text('Deliveries', style: AppTextStyles.captionSmall),
          //                     const SizedBox(height: AppSpacing.xs),
          //                     Text('${applications.where((app) => app.status == 'completed').length}', style: AppTextStyles.bodyLarge),
          //                   ],
          //                 ),
          //               ),
          //               loading: () => const CustomCard(
          //                 padding: EdgeInsets.all(AppSpacing.md),
          //                 child: Center(child: CircularProgressIndicator()),
          //               ),
          //               error: (_, __) => CustomCard(
          //                 padding: const EdgeInsets.all(AppSpacing.md),
          //                 child: Column(
          //                   crossAxisAlignment: CrossAxisAlignment.start,
          //                   children: [
          //                     Icon(Icons.local_shipping_outlined,
          //                         color: AppColors.info, size: 24),
          //                     const SizedBox(height: AppSpacing.sm),
          //                     Text('Deliveries', style: AppTextStyles.captionSmall),
          //                     const SizedBox(height: AppSpacing.xs),
          //                     Text('0', style: AppTextStyles.bodyLarge),
          //                   ],
          //                 ),
          //               ),
          //             ),
          //           ),
          //         ],
          //       ),
          //     );
          //   },
          // ),

          // Monthly earnings summary
          // Consumer(
          //   builder: (context, ref, child) {
          //     final transactionsAsync = ref.watch(transactionsProvider(1));

          //     return transactionsAsync.when(
          //       data: (transactions) {
          //         final now = DateTime.now();
          //         final monthStart = DateTime(now.year, now.month, 1);
          //         final monthEnd = DateTime(now.year, now.month + 1, 0, 23, 59, 59);

          //         final monthlyEarnings = transactions
          //             .where((t) =>
          //                 t.transactionType == 'credit' &&
          //                 (t.purpose == 'Job Earnings' || t.purpose == 'delivery' || t.purpose.isEmpty) &&
          //                 t.createdAt.isAfter(monthStart) &&
          //                 t.createdAt.isBefore(monthEnd))
          //             .fold<double>(0.0, (sum, t) => sum + t.amount);

          //         return Container(
          //           padding: const EdgeInsets.fromLTRB(AppSpacing.lg, 0, AppSpacing.lg, AppSpacing.lg),
          //           color: AppColors.background,
          //           child: CustomCard(
          //             padding: const EdgeInsets.all(AppSpacing.lg),
          //             child: Row(
          //               children: [
          //                 Icon(Icons.calendar_today, color: AppColors.primary, size: 24),
          //                 const SizedBox(width: AppSpacing.md),
          //                 Expanded(
          //                   child: Column(
          //                     crossAxisAlignment: CrossAxisAlignment.start,
          //                     children: [
          //                       Text('This Month', style: AppTextStyles.captionSmall),
          //                       const SizedBox(height: AppSpacing.xs),
          //                       Text('₦${monthlyEarnings.toStringAsFixed(0)}', style: AppTextStyles.bodyLarge.copyWith(fontWeight: FontWeight.bold)),
          //                     ],
          //                   ),
          //                 ),
          //               ],
          //             ),
          //           ),
          //         );
          //       },
          //       loading: () => Container(
          //         padding: const EdgeInsets.fromLTRB(AppSpacing.lg, 0, AppSpacing.lg, AppSpacing.lg),
          //         color: AppColors.background,
          //         child: const CustomCard(
          //           padding: EdgeInsets.all(AppSpacing.lg),
          //           child: Center(child: CircularProgressIndicator()),
          //         ),
          //       ),
          //       error: (_, __) => Container(
          //         padding: const EdgeInsets.fromLTRB(AppSpacing.lg, 0, AppSpacing.lg, AppSpacing.lg),
          //         color: AppColors.background,
          //         child: CustomCard(
          //           padding: const EdgeInsets.all(AppSpacing.lg),
          //           child: Row(
          //             children: [
          //               Icon(Icons.calendar_today, color: AppColors.primary, size: 24),
          //               const SizedBox(width: AppSpacing.md),
          //               Expanded(
          //                 child: Column(
          //                   crossAxisAlignment: CrossAxisAlignment.start,
          //                   children: [
          //                     Text('This Month', style: AppTextStyles.captionSmall),
          //                     const SizedBox(height: AppSpacing.xs),
          //                     Text('₦0', style: AppTextStyles.bodyLarge.copyWith(fontWeight: FontWeight.bold)),
          //                   ],
          //                 ),
          //               ),
          //             ],
          //           ),
          //         ),
          //       ),
          //     );
          //   },
          // ),

          // Tabs
          Container(
            color: AppColors.background,
            child: TabBar(
              controller: _tabController,
              indicatorColor: AppColors.primary,
              labelColor: AppColors.primary,
              unselectedLabelColor: AppColors.textSecondary,
              tabs: const [
                Tab(text: 'Transactions'),
                Tab(text: 'Withdrawals'),
              ],
            ),
          ),

          // Tab Content
          Expanded(
            child: TabBarView(
              controller: _tabController,
              children: [
                // Transactions Tab
                Consumer(
                  builder: (context, ref, child) {
                    final transactionsAsync = ref.watch(transactionsProvider(1));

                    return transactionsAsync.when(
                      data: (transactions) {
                        if (transactions.isEmpty) {
                          return const Center(
                            child: EmptyState(
                              icon: Icons.account_balance_wallet,
                              title: 'No wallet activity yet',
                              subtitle: 'Your recent transactions will appear here.',
                            ),
                          );
                        }

                        return ListView.builder(
                          padding: const EdgeInsets.all(AppSpacing.lg),
                          itemCount: transactions.length,
                          itemBuilder: (context, index) {
                            final transaction = transactions[index];
                            final isCredit = transaction.transactionType == 'credit';
                            final label = transaction.purpose.isNotEmpty
                                ? transaction.purpose.replaceAll('_', ' ').toUpperCase()
                                : transaction.transactionType.toUpperCase();
                            final amountPrefix = isCredit ? '+' : '-';
                            final amountColor = isCredit ? AppColors.success : AppColors.error;

                            return CustomCard(
                              padding: const EdgeInsets.all(AppSpacing.md),
                              margin: const EdgeInsets.only(bottom: AppSpacing.md),
                              child: Row(
                                children: [
                                  Container(
                                    width: 45,
                                    height: 45,
                                    decoration: BoxDecoration(
                                      color: isCredit
                                          ? AppColors.success.withOpacity(0.1)
                                          : AppColors.error.withOpacity(0.1),
                                      borderRadius:
                                          BorderRadius.circular(AppBorderRadius.md),
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
                                          style: AppTextStyles.bodySmall,
                                          maxLines: 2,
                                          overflow: TextOverflow.ellipsis,
                                        ),
                                      ],
                                    ),
                                  ),
                                  Text(
                                    '$amountPrefix₦${transaction.amount.toStringAsFixed(0)}',
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
                      loading: () => const Center(child: CircularProgressIndicator()),
                      error: (error, stackTrace) => Center(
                        child: Padding(
                          padding: const EdgeInsets.all(AppSpacing.lg),
                          child: Text(
                            'Unable to load wallet transactions.',
                            style: AppTextStyles.bodyMedium.copyWith(color: AppColors.error),
                            textAlign: TextAlign.center,
                          ),
                        ),
                      ),
                    );
                  },
                ),

                // Withdrawals Tab - show real withdrawal transactions in real time
                Consumer(
                  builder: (context, ref, child) {
                    final transactionsAsync = ref.watch(transactionsProvider(1));

                    return transactionsAsync.when(
                      data: (transactions) {
                        final withdrawals = transactions
                            .where((t) => (t.purpose ?? '').toLowerCase() == 'withdrawal' || t.type.toLowerCase() == 'withdrawal')
                            .toList();

                        if (withdrawals.isEmpty) {
                          return const Center(
                            child: EmptyState(
                              icon: Icons.account_balance,
                              title: 'No withdrawals yet',
                              subtitle: 'Your past withdrawal requests will appear here.',
                            ),
                          );
                        }

                        return ListView.builder(
                          padding: const EdgeInsets.all(AppSpacing.lg),
                          itemCount: withdrawals.length,
                          itemBuilder: (context, index) {
                            final tx = withdrawals[index];
                            final statusColor = tx.status == 'completed'
                                ? AppColors.success
                                : tx.status == 'pending'
                                    ? AppColors.info
                                    : AppColors.error;

                            return CustomCard(
                              padding: const EdgeInsets.all(AppSpacing.md),
                              margin: const EdgeInsets.only(bottom: AppSpacing.md),
                              child: Row(
                                children: [
                                  Container(
                                    width: 45,
                                    height: 45,
                                    decoration: BoxDecoration(
                                      color: statusColor.withOpacity(0.1),
                                      borderRadius: BorderRadius.circular(AppBorderRadius.md),
                                    ),
                                    child: Center(
                                      child: Icon(
                                        Icons.account_balance,
                                        color: statusColor,
                                      ),
                                    ),
                                  ),
                                  const SizedBox(width: AppSpacing.md),
                                  Expanded(
                                    child: Column(
                                      crossAxisAlignment: CrossAxisAlignment.start,
                                      children: [
                                        Text('Withdrawal #${tx.id}', style: AppTextStyles.bodyLarge),
                                        const SizedBox(height: AppSpacing.xs),
                                        Text(
                                          tx.status.isNotEmpty
                                              ? tx.status[0].toUpperCase() + tx.status.substring(1)
                                              : tx.status,
                                          style: AppTextStyles.bodySmall.copyWith(color: statusColor),
                                        ),
                                      ],
                                    ),
                                  ),
                                  Text('-₦${tx.amount.toStringAsFixed(0)}', style: AppTextStyles.bodyLarge.copyWith(fontWeight: FontWeight.bold)),
                                ],
                              ),
                            );
                          },
                        );
                      },
                      loading: () => const Center(child: CircularProgressIndicator()),
                      error: (error, stackTrace) => Center(
                        child: Padding(
                          padding: const EdgeInsets.all(AppSpacing.lg),
                          child: Text(
                            'Unable to load withdrawals.',
                            style: AppTextStyles.bodyMedium.copyWith(color: AppColors.error),
                            textAlign: TextAlign.center,
                          ),
                        ),
                      ),
                    );
                  },
                ),
              ],
            ),
          ),
        ],
      ),
      bottomNavigationBar: Builder(
        builder: (context) {
          final activeJob = ref.watch(activeRiderJobProvider);
          final jobsRoute = activeJob != null ? '/rider-active-jobs' : '/rider-jobs';
          return RiderBottomNavigationBar(
            currentIndex: 2,
            onTap: (index) {
              switch (index) {
                case 0:
                  Navigator.of(context).pushReplacementNamed('/rider-dashboard');
                  break;
                case 1:
                  Navigator.of(context).pushReplacementNamed(jobsRoute);
                  break;
                case 2:
                  break;
                case 3:
                  Navigator.of(context).pushNamed('/rider-profile');
                  break;
              }
            },
          );
        },
      ),
    );
  }
}
