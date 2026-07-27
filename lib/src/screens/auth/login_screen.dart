import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../config/theme.dart';
import '../../widgets/index.dart';
import '../../providers/index.dart';
import '../../models/index.dart';

class LoginScreen extends ConsumerStatefulWidget {
  const LoginScreen({Key? key}) : super(key: key);

  @override
  ConsumerState<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends ConsumerState<LoginScreen> {
  final _formKey = GlobalKey<FormState>();
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();

  @override
  void dispose() {
    _emailController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  Future<void> _handleLogin() async {
    if (!_formKey.currentState!.validate()) return;

    try {
      await ref.read(authStateProvider.notifier).login(
            _emailController.text,
            _passwordController.text,
          );

      if (!mounted) return;
      
      // Get the current auth state after login
      final authState = ref.read(authStateProvider);
      
      // Route directly based on user type - no role selector screen
      if (authState.currentRole == UserType.rider) {
        //straight to rider dashboard
        Navigator.of(context).pushReplacementNamed('/rider-dashboard');

        // // Check if rider needs KYC verification
        // if (authState.kycStatus == 'pending') {
        //   Navigator.of(context).pushReplacementNamed('/kyc-pending');
        // } else {
        //   Navigator.of(context).pushReplacementNamed('/rider-dashboard');
        // }
      } else {
        // Customer user - go directly to customer dashboard
        Navigator.of(context).pushReplacementNamed('/customer-dashboard');
      }
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Login failed: $e')),
      );
    }
  }

  void _fillTestCredentials(String role) {
    if (role == 'customer') {
      _emailController.text = 'customer@test.com';
      _passwordController.text = 'password123';
    } else if (role == 'rider') {
      _emailController.text = 'rider@test.com';
      _passwordController.text = 'password123';
    }
  }

  @override
  Widget build(BuildContext context) {
    final authState = ref.watch(authStateProvider);

    return Scaffold(
      body: SafeArea(
        child: SingleChildScrollView(
          child: Padding(
            padding: const EdgeInsets.all(AppSpacing.xl),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const SizedBox(height: AppSpacing.xl),
                Text(
                  'Welcome Back',
                  style: AppTextStyles.displayMedium,
                ),
                const SizedBox(height: AppSpacing.sm),
                Text(
                  'Login to your account',
                  style: AppTextStyles.bodyMedium,
                ),
                
                const SizedBox(height: AppSpacing.xxxl),
                Form(
                  key: _formKey,
                  child: Column(
                    children: [
                      EmailField(
                        label: 'Email Address',
                        controller: _emailController,
                      ),
                      const SizedBox(height: AppSpacing.lg),
                      PasswordField(
                        label: 'Password',
                        hint: 'Enter your password',
                        controller: _passwordController,
                      ),
                      const SizedBox(height: AppSpacing.lg),
                      Align(
                        alignment: Alignment.centerRight,
                        child: GestureDetector(
                          onTap: () => Navigator.of(context).pushNamed('/forgot-password'),
                          child: Text(
                            'Forgot Password?',
                            style: AppTextStyles.labelMedium.copyWith(
                              color: AppColors.primary,
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: AppSpacing.xxxl),
                PrimaryButton(
                  label: 'Sign In',
                  isLoading: authState.isLoading,
                  onPressed: _handleLogin,
                ),
                const SizedBox(height: AppSpacing.xxxl),
                Text(
                  "Don't have an Account Yet?",
                  style: AppTextStyles.bodyMedium,
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: AppSpacing.md),
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton(
                    onPressed: () => Navigator.of(context).pushNamed('/user-registration'),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppColors.accent,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                    child: Text(
                      'Register as User',
                      style: AppTextStyles.labelLarge.copyWith(
                      color: Colors.white,
                      ),
                    ),
                  ),
                ),
                const SizedBox(height: AppSpacing.md),
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton(
                    onPressed: () => Navigator.of(context).pushNamed('/rider-registration-step1'),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppColors.primary,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                    child: Text(
                      'Register as Rider',
                      style: AppTextStyles.labelLarge.copyWith(
                        color: Colors.white,
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
