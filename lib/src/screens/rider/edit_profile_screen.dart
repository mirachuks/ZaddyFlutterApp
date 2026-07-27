import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../config/theme.dart';
import '../../widgets/index.dart';
import '../../providers/index.dart';

class RiderEditProfileScreen extends ConsumerStatefulWidget {
  const RiderEditProfileScreen({Key? key}) : super(key: key);

  @override
  ConsumerState<RiderEditProfileScreen> createState() =>
      _RiderEditProfileScreenState();
}

class _RiderEditProfileScreenState
    extends ConsumerState<RiderEditProfileScreen> {
  late TextEditingController _firstNameController;
  late TextEditingController _lastNameController;
  late TextEditingController _phoneController;
  late TextEditingController _emailController;

  bool _isSubmitting = false;
  bool _isInitialized = false;

  @override
  void initState() {
    super.initState();
    // Initialize empty controllers - will be updated in build() when data loads
    _firstNameController = TextEditingController();
    _lastNameController = TextEditingController();
    _phoneController = TextEditingController();
    _emailController = TextEditingController();
    
    // Schedule profile fetch after first frame if user data is not cached
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _initializeUserData();
    });
  }
  
  Future<void> _initializeUserData() async {
    if (_isInitialized) return;
    _isInitialized = true;
    
    try {
      final currentUser = ref.read(currentUserProvider);
      
      // If user is cached, use that data
      if (currentUser != null) {
        setState(() {
          _firstNameController.text = currentUser.firstName ?? '';
          _lastNameController.text = currentUser.lastName ?? '';
          _emailController.text = currentUser.email ?? '';
          _phoneController.text = currentUser.phone ?? '';
        });
      } else {
        // Otherwise, fetch from API
        final userService = await ref.read(userServiceProvider.future);
        final user = await userService.getUserProfile();
        
        if (mounted) {
          setState(() {
            _firstNameController.text = user.firstName ?? '';
            _lastNameController.text = user.lastName ?? '';
            _emailController.text = user.email ?? '';
            _phoneController.text = user.phone ?? '';
          });
        }
      }
    } catch (e) {
      print('Error fetching profile data: $e');
      // Continue with empty fields if fetch fails
    }
  }

  @override
  void dispose() {
    _firstNameController.dispose();
    _lastNameController.dispose();
    _phoneController.dispose();
    _emailController.dispose();
    super.dispose();
  }

  Future<void> _saveChanges() async {
    if (_firstNameController.text.trim().isEmpty ||
        _lastNameController.text.trim().isEmpty ||
        _phoneController.text.trim().isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please fill in all required fields')),
      );
      return;
    }

    setState(() => _isSubmitting = true);

    try {
      // Call the update profile provider which submits for admin review
      await ref.read(updateUserProfileProvider.notifier).updateProfile(
            firstName: _firstNameController.text.trim(),
            lastName: _lastNameController.text.trim(),
            phone: _phoneController.text.trim(),
          );

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Profile update submitted for admin review!'),
            backgroundColor: Color(0xFF10B981),
          ),
        );
        Navigator.pop(context);
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error submitting profile update: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() => _isSubmitting = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final currentUser = ref.watch(currentUserProvider);
    
    // Update controllers when user data loads
    if (currentUser != null) {
      if (_firstNameController.text != (currentUser.firstName ?? '')) {
        _firstNameController.text = currentUser.firstName ?? '';
      }
      if (_lastNameController.text != (currentUser.lastName ?? '')) {
        _lastNameController.text = currentUser.lastName ?? '';
      }
      if (_emailController.text != (currentUser.email ?? '')) {
        _emailController.text = currentUser.email ?? '';
      }
      if (_phoneController.text != (currentUser.phone ?? '')) {
        _phoneController.text = currentUser.phone ?? '';
      }
    }
    
    return Scaffold(
      appBar: AppBar(
        title: const Text('Edit Profile'),
        backgroundColor: AppColors.primary,
        foregroundColor: Colors.white,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () => Navigator.pop(context),
        ),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(AppSpacing.lg),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Profile Avatar Section
            Center(
              child: Container(
                width: 120,
                height: 120,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: AppColors.primary.withValues(alpha: 0.1),
                ),
                child: const Center(
                  child: Icon(
                    Icons.person_outline,
                    size: 60,
                    color: AppColors.primary,
                  ),
                ),
              ),
            ),
            const SizedBox(height: AppSpacing.xxxl),

            // First Name
            Text(
              'First Name *',
              style: AppTextStyles.labelMedium.copyWith(
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: AppSpacing.sm),
            TextField(
              controller: _firstNameController,
              style: AppTextStyles.bodyLarge,
              decoration: InputDecoration(
                hintText: 'Enter your first name',
                hintStyle: AppTextStyles.bodyLarge.copyWith(
                  color: AppColors.textSecondary,
                ),
                prefixIcon: const Icon(Icons.person_outline),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(AppBorderRadius.md),
                ),
              ),
            ),
            const SizedBox(height: AppSpacing.lg),

            // Last Name
            Text(
              'Last Name *',
              style: AppTextStyles.labelMedium.copyWith(
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: AppSpacing.sm),
            TextField(
              controller: _lastNameController,
              style: AppTextStyles.bodyLarge,
              decoration: InputDecoration(
                hintText: 'Enter your last name',
                hintStyle: AppTextStyles.bodyLarge.copyWith(
                  color: AppColors.textSecondary,
                ),
                prefixIcon: const Icon(Icons.person_outline),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(AppBorderRadius.md),
                ),
              ),
            ),
            const SizedBox(height: AppSpacing.lg),

            // Email (Read-only)
            Text(
              'Email Address',
              style: AppTextStyles.labelMedium.copyWith(
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: AppSpacing.sm),
            TextField(
              controller: _emailController,
              keyboardType: TextInputType.emailAddress,
              style: AppTextStyles.bodyLarge.copyWith(
                color: AppColors.textSecondary,
              ),
              enabled: false,
              readOnly: true,
              decoration: InputDecoration(
                hintText: 'Email cannot be changed',
                hintStyle: AppTextStyles.bodyLarge.copyWith(
                  color: AppColors.textSecondary,
                ),
                prefixIcon: const Icon(Icons.email_outlined),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(AppBorderRadius.md),
                  borderSide: const BorderSide(
                    color: AppColors.textSecondary,
                  ),
                ),
                enabledBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(AppBorderRadius.md),
                  borderSide: BorderSide(
                    color: AppColors.textSecondary.withValues(alpha: 0.3),
                  ),
                ),
                disabledBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(AppBorderRadius.md),
                  borderSide: BorderSide(
                    color: AppColors.textSecondary.withValues(alpha: 0.3),
                  ),
                ),
              ),
            ),
            const SizedBox(height: AppSpacing.lg),

            // Phone Number
            Text(
              'Phone Number *',
              style: AppTextStyles.labelMedium.copyWith(
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: AppSpacing.sm),
            TextField(
              controller: _phoneController,
              keyboardType: TextInputType.phone,
              style: AppTextStyles.bodyLarge,
              decoration: InputDecoration(
                hintText: 'Enter your phone number',
                hintStyle: AppTextStyles.bodyLarge.copyWith(
                  color: AppColors.textSecondary,
                ),
                prefixIcon: const Icon(Icons.phone_outlined),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(AppBorderRadius.md),
                ),
              ),
            ),
            const SizedBox(height: AppSpacing.xxxl),

            // Save Button
            SizedBox(
              width: double.infinity,
              height: 56,
              child: ElevatedButton(
                onPressed: _isSubmitting ? null : _saveChanges,
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.primary,
                ),
                child: _isSubmitting
                    ? const SizedBox(
                        height: 24,
                        width: 24,
                        child: CircularProgressIndicator(
                          valueColor:
                              AlwaysStoppedAnimation<Color>(Colors.white),
                          strokeWidth: 2,
                        ),
                      )
                    : Text(
                        'Save Changes',
                        style: AppTextStyles.labelMedium.copyWith(
                          color: Colors.white,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
              ),
            ),
            const SizedBox(height: AppSpacing.lg),
          ],
        ),
      ),
    );
  }
}
