import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../config/theme.dart';
import '../../models/index.dart';
import '../../widgets/index.dart';
import '../../providers/index.dart';

class RoleSelectorScreen extends ConsumerWidget {
  const RoleSelectorScreen({Key? key}) : super(key: key);

  void _selectRole(BuildContext context, WidgetRef ref, UserType role) async {
    try {
      await ref.read(authStateProvider.notifier).setRole(role);
      
      if (!context.mounted) return;
      
      if (role == UserType.customer) {
        Navigator.of(context).pushReplacementNamed('/customer-dashboard');
      } else {
        // Start comprehensive rider registration process
        Navigator.of(context).pushReplacementNamed('/rider-registration-step1');
      }
    } catch (e) {
      if (!context.mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error: $e')),
      );
    }
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final currentUser = ref.watch(currentUserProvider);

    return Scaffold(
      body: SafeArea(
        child: SingleChildScrollView(
          child: Padding(
            padding: const EdgeInsets.symmetric(
              horizontal: AppSpacing.xl,
              vertical: AppSpacing.xxl,
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Header
                Text(
                  'Welcome, ${currentUser?.firstName}!',
                  style: AppTextStyles.displayMedium,
                ),
                const SizedBox(height: AppSpacing.md),
                Text(
                  'What would you like to do?',
                  style: AppTextStyles.bodyMedium,
                ),
                const SizedBox(height: AppSpacing.xxxl),

                // Customer Card
                GestureDetector(
                  onTap: () =>
                      _selectRole(context, ref, UserType.customer),
                  child: CustomCard(
                    padding: const EdgeInsets.all(AppSpacing.xl),
                    backgroundColor: AppColors.primary.withOpacity(0.05),
                    borderRadius: AppBorderRadius.lg,
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Container(
                          width: 60,
                          height: 60,
                          decoration: BoxDecoration(
                            color: AppColors.primary,
                            borderRadius:
                                BorderRadius.circular(AppBorderRadius.md),
                          ),
                          child: const Center(
                            child: Icon(
                              Icons.shopping_bag_outlined,
                              color: AppColors.textInverse,
                              size: 32,
                            ),
                          ),
                        ),
                        const SizedBox(height: AppSpacing.lg),
                        Text(
                          'Send Deliveries',
                          style: AppTextStyles.headingMedium,
                        ),
                        const SizedBox(height: AppSpacing.sm),
                        Text(
                          'Post delivery jobs and track your shipments in real-time',
                          style: AppTextStyles.bodySmall,
                        ),
                        const SizedBox(height: AppSpacing.lg),
                        Row(
                          children: [
                            const Icon(
                              Icons.check_circle,
                              color: AppColors.success,
                              size: 20,
                            ),
                            const SizedBox(width: AppSpacing.sm),
                            Text(
                              'Real-time tracking',
                              style: AppTextStyles.labelSmall,
                            ),
                          ],
                        ),
                        const SizedBox(height: AppSpacing.sm),
                        Row(
                          children: [
                            const Icon(
                              Icons.check_circle,
                              color: AppColors.success,
                              size: 20,
                            ),
                            const SizedBox(width: AppSpacing.sm),
                            Text(
                              'Secure payments',
                              style: AppTextStyles.labelSmall,
                            ),
                          ],
                        ),
                        const SizedBox(height: AppSpacing.sm),
                        Row(
                          children: [
                            const Icon(
                              Icons.check_circle,
                              color: AppColors.success,
                              size: 20,
                            ),
                            const SizedBox(width: AppSpacing.sm),
                            Text(
                              'Rate your riders',
                              style: AppTextStyles.labelSmall,
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                ),

                const SizedBox(height: AppSpacing.xl),

                // Rider Card
                GestureDetector(
                  onTap: () => _selectRole(context, ref, UserType.rider),
                  child: CustomCard(
                    padding: const EdgeInsets.all(AppSpacing.xl),
                    backgroundColor: AppColors.accent.withOpacity(0.05),
                    borderRadius: AppBorderRadius.lg,
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Container(
                          width: 60,
                          height: 60,
                          decoration: BoxDecoration(
                            color: AppColors.accent,
                            borderRadius:
                                BorderRadius.circular(AppBorderRadius.md),
                          ),
                          child: const Center(
                            child: Icon(
                              Icons.two_wheeler,
                              color: AppColors.textInverse,
                              size: 32,
                            ),
                          ),
                        ),
                        const SizedBox(height: AppSpacing.lg),
                        Text(
                          'Earn Money',
                          style: AppTextStyles.headingMedium,
                        ),
                        const SizedBox(height: AppSpacing.sm),
                        Text(
                          'Browse delivery jobs and earn money on your own schedule',
                          style: AppTextStyles.bodySmall,
                        ),
                        const SizedBox(height: AppSpacing.lg),
                        Row(
                          children: [
                            const Icon(
                              Icons.check_circle,
                              color: AppColors.success,
                              size: 20,
                            ),
                            const SizedBox(width: AppSpacing.sm),
                            Text(
                              'Flexible hours',
                              style: AppTextStyles.labelSmall,
                            ),
                          ],
                        ),
                        const SizedBox(height: AppSpacing.sm),
                        Row(
                          children: [
                            const Icon(
                              Icons.check_circle,
                              color: AppColors.success,
                              size: 20,
                            ),
                            const SizedBox(width: AppSpacing.sm),
                            Text(
                              'Instant withdrawals',
                              style: AppTextStyles.labelSmall,
                            ),
                          ],
                        ),
                        const SizedBox(height: AppSpacing.sm),
                        Row(
                          children: [
                            const Icon(
                              Icons.check_circle,
                              color: AppColors.success,
                              size: 20,
                            ),
                            const SizedBox(width: AppSpacing.sm),
                            Text(
                              'Earn bonuses',
                              style: AppTextStyles.labelSmall,
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                ),

                const SizedBox(height: AppSpacing.xxxl),

                // Switch Later Info
                Container(
                  padding: const EdgeInsets.all(AppSpacing.lg),
                  decoration: BoxDecoration(
                    color: AppColors.info.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(AppBorderRadius.md),
                  ),
                  child: Row(
                    children: [
                      const Icon(
                        Icons.info_outline,
                        color: AppColors.info,
                        size: 20,
                      ),
                      const SizedBox(width: AppSpacing.md),
                      Expanded(
                        child: Text(
                          'You can switch between roles anytime from your profile',
                          style: AppTextStyles.bodySmall,
                        ),
                      ),
                    ],
                  ),
                ),

                const SizedBox(height: AppSpacing.xxl),

                // Logout Button
                SecondaryButton(
                  label: 'Logout',
                  onPressed: () async {
                    await ref.read(authStateProvider.notifier).logout();
                    if (!context.mounted) return;
                    Navigator.of(context).pushReplacementNamed('/splash');
                  },
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
