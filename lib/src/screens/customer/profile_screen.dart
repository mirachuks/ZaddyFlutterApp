import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../../config/theme.dart';
import '../../widgets/index.dart';
import '../../providers/index.dart';

class CustomerProfileScreen extends ConsumerStatefulWidget {
  const CustomerProfileScreen({Key? key}) : super(key: key);

  @override
  ConsumerState<CustomerProfileScreen> createState() => _CustomerProfileScreenState();
}

class _CustomerProfileScreenState extends ConsumerState<CustomerProfileScreen> {
  bool _notificationsEnabled = true;

  @override
  void initState() {
    super.initState();
    _loadNotificationSetting();
  }

  Future<void> _loadNotificationSetting() async {
    final prefs = await SharedPreferences.getInstance();
    setState(() {
      _notificationsEnabled = prefs.getBool('notifications_enabled') ?? true;
    });
  }

  Future<void> _saveNotificationSetting(bool value) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool('notifications_enabled', value);
    setState(() => _notificationsEnabled = value);
  }

  @override
  Widget build(BuildContext context) {
    final currentUser = ref.watch(currentUserProvider);
    
    return Scaffold(
      body: SafeArea(
        child: SingleChildScrollView(
          child: Column(
            children: [
              // Header with Profile Title
              Padding(
                padding: const EdgeInsets.symmetric(
                  horizontal: AppSpacing.lg,
                  vertical: AppSpacing.lg,
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    IconButton(
                      icon: const Icon(Icons.arrow_back),
                      onPressed: () => Navigator.pop(context),
                    ),
                    Text(
                      'Profile',
                      style: AppTextStyles.displaySmall.copyWith(
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(width: 48), // Spacing for centering
                  ],
                ),
              ),

              const SizedBox(height: AppSpacing.xl),

              // Profile Avatar with Badge
              Stack(
                children: [
                  Container(
                    width: 140,
                    height: 140,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      color: AppColors.primary.withOpacity(0.1),
                    ),
                    child: const Center(
                      child: Icon(
                        Icons.person_outline,
                        size: 80,
                        color: AppColors.primary,
                      ),
                    ),
                  ),
                  // Green verified badge
                  Positioned(
                    bottom: 0,
                    right: 0,
                    child: Container(
                      width: 40,
                      height: 40,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        color: AppColors.success,
                        border: Border.all(
                          color: Colors.white,
                          width: 2,
                        ),
                      ),
                      child: const Center(
                        child: Icon(
                          Icons.check,
                          color: Colors.white,
                          size: 24,
                        ),
                      ),
                    ),
                  ),
                ],
              ),

              const SizedBox(height: AppSpacing.lg),

              // Edit Profile Button
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: AppSpacing.lg),
                child: SizedBox(
                  width: double.infinity,
                  child: ElevatedButton.icon(
                    onPressed: () => Navigator.of(context).pushNamed('/edit-profile'),
                    icon: const Icon(Icons.edit),
                    label: const Text('Edit Profile'),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppColors.primary,
                    ),
                  ),
                ),
              ),

              const SizedBox(height: AppSpacing.xxxl),

              // User Details Section
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: AppSpacing.lg),
                child: Column(
                  children: [
                    // First Name
                    _buildDetailItem(
                      label: 'First Name',
                      value: currentUser?.firstName ?? 'Not set',
                      icon: Icons.person_outline,
                    ),
                    const SizedBox(height: AppSpacing.lg),

                    // Last Name
                    _buildDetailItem(
                      label: 'Last Name',
                      value: currentUser?.lastName ?? 'Not set',
                      icon: Icons.person_outline,
                    ),
                    const SizedBox(height: AppSpacing.lg),

                    // Email
                    _buildDetailItem(
                      label: 'Email Address',
                      value: currentUser?.email ?? 'Not set',
                      icon: Icons.email_outlined,
                    ),
                    const SizedBox(height: AppSpacing.lg),

                    // Phone Number
                    GestureDetector(
                      onTap: () => Navigator.of(context).pushNamed('/edit-profile'),
                      child: _buildDetailItem(
                        label: 'Phone Number',
                        value: currentUser?.phone ?? 'Not set',
                        icon: Icons.phone_outlined,
                        isTappable: true,
                      ),
                    ),
                  ],
                ),
              ),

              const SizedBox(height: AppSpacing.xxxl),

              // Settings Options
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: AppSpacing.lg),
                child: Column(
                  children: [
                    // Push Notification
                    _buildSettingItem(
                      context,
                      icon: Icons.notifications_outlined,
                      label: 'Push notification',
                      subtitle: 'Receive notification on your device',
                      hasToggle: true,
                      notificationValue: _notificationsEnabled,
                      onNotificationChange: _saveNotificationSetting,
                    ),
                    const SizedBox(height: AppSpacing.xxl),

                    // Help & Support
                    _buildSettingItem(
                      context,
                      icon: Icons.info_outline,
                      label: 'Help & Support',
                      onTap: () => Navigator.of(context).pushNamed('/help-support'),
                    ),
                    const SizedBox(height: AppSpacing.xxl),

                    // Policy
                    _buildSettingItem(
                      context,
                      icon: Icons.description_outlined,
                      label: 'Policy',
                      onTap: () => Navigator.of(context).pushNamed('/customer-policy'),
                    ),
                    const SizedBox(height: AppSpacing.xxl),

                    // Log Out
                    _buildSettingItem(
                      context,
                      icon: Icons.logout_outlined,
                      label: 'Log Out',
                      isLogout: true,
                      onTap: () async {
                        // Show confirmation dialog
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
                                onPressed: () {
                                  Navigator.pop(context);
                                  // Clear auth and navigate to login
                                  Navigator.of(context).pushReplacementNamed('/login');
                                },
                                child: const Text('Log Out'),
                              ),
                            ],
                          ),
                        );
                      },
                    ),
                  ],
                ),
              ),

              const SizedBox(height: AppSpacing.xxxl),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildDetailItem({
    required String label,
    required String value,
    required IconData icon,
    bool isTappable = false,
  }) {
    return Container(
      padding: const EdgeInsets.all(AppSpacing.md),
      decoration: BoxDecoration(
        border: Border.all(
          color: AppColors.textSecondary.withValues(alpha: 0.2),
          width: 1,
        ),
        borderRadius: BorderRadius.circular(AppBorderRadius.md),
        color: isTappable ? AppColors.primary.withValues(alpha: 0.05) : null,
      ),
      child: Row(
        children: [
          Icon(icon, color: AppColors.primary, size: 24),
          const SizedBox(width: AppSpacing.md),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  label,
                  style: AppTextStyles.bodySmall.copyWith(
                    color: AppColors.textSecondary,
                  ),
                ),
                const SizedBox(height: AppSpacing.xs),
                Text(
                  value,
                  style: AppTextStyles.bodyMedium.copyWith(
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ],
            ),
          ),
          if (isTappable)
            Icon(
              Icons.edit_outlined,
              color: AppColors.primary,
              size: 20,
            ),
        ],
      ),
    );
  }

  Widget _buildSettingItem(
    BuildContext context, {
    required IconData icon,
    required String label,
    String? subtitle,
    bool hasToggle = false,
    bool isLogout = false,
    bool notificationValue = false,
    Function(bool)? onNotificationChange,
    VoidCallback? onTap,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Row(
            children: [
              Icon(
                icon,
                size: 24,
                color: isLogout ? AppColors.error : AppColors.textPrimary,
              ),
              const SizedBox(width: AppSpacing.lg),
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    label,
                    style: AppTextStyles.bodyLarge.copyWith(
                      color: isLogout ? AppColors.error : AppColors.textPrimary,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  if (subtitle != null) ...[
                    const SizedBox(height: AppSpacing.sm),
                    Text(
                      subtitle,
                      style: AppTextStyles.bodySmall.copyWith(
                        color: AppColors.textSecondary,
                      ),
                    ),
                  ],
                ],
              ),
            ],
          ),
          if (hasToggle)
            Switch(
              value: notificationValue,
              onChanged: onNotificationChange,
              activeColor: AppColors.primary,
            )
          else
            Icon(
              Icons.arrow_forward_ios,
              size: 16,
              color: AppColors.textSecondary,
            ),
        ],
      ),
    );
  }
}
