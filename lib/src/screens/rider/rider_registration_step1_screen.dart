import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:image_picker/image_picker.dart';
import '../../utils/file_image_helper.dart';

import '../../config/theme.dart';
import '../../models/index.dart';
import '../../providers/index.dart';
import '../../widgets/index.dart';

class RiderRegistrationStep1Screen extends ConsumerStatefulWidget {
  const RiderRegistrationStep1Screen({Key? key}) : super(key: key);

  @override
  ConsumerState<RiderRegistrationStep1Screen> createState() =>
      _RiderRegistrationStep1ScreenState();
}

class _RiderRegistrationStep1ScreenState
    extends ConsumerState<RiderRegistrationStep1Screen> {
  late TextEditingController _firstNameController;
  late TextEditingController _lastNameController;
  late TextEditingController _emailController;
  late TextEditingController _phoneController;
  late TextEditingController _passwordController;
  late TextEditingController _confirmPasswordController;
  late TextEditingController _dateOfBirthController;

  dynamic _profileImage;
  final _formKey = GlobalKey<FormState>();
  bool _isPasswordVisible = false;
  bool _isConfirmPasswordVisible = false;
  bool _isSubmitting = false;

  @override
  void initState() {
    super.initState();
    final riderState = ref.read(riderRegistrationProvider);
    _firstNameController =
        TextEditingController(text: riderState.personalData?.firstName ?? '');
    _lastNameController =
        TextEditingController(text: riderState.personalData?.lastName ?? '');
    _emailController =
        TextEditingController(text: riderState.personalData?.email ?? '');
    _phoneController =
        TextEditingController(text: riderState.personalData?.phone ?? '');
    _passwordController =
        TextEditingController(text: riderState.personalData?.password ?? '');
    _confirmPasswordController = TextEditingController(
        text: riderState.personalData?.passwordConfirmation ?? '');
    _dateOfBirthController =
        TextEditingController(text: riderState.personalData?.dateOfBirth ?? '');
    _profileImage = null; // Files not available on web or during initial load
  }

  @override
  void dispose() {
    _firstNameController.dispose();
    _lastNameController.dispose();
    _emailController.dispose();
    _phoneController.dispose();
    _passwordController.dispose();
    _confirmPasswordController.dispose();
    _dateOfBirthController.dispose();
    super.dispose();
  }

  Future<void> _pickProfileImage() async {
    try {
      final picker = ImagePicker();
      final pickedFile = await picker.pickImage(
        source: ImageSource.gallery,
        imageQuality: 85,
      );

      if (pickedFile != null) {
        setState(() {
          _profileImage = pickedFile;
        });
        if (!mounted) return;
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Profile photo selected successfully')),
        );
      }
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error picking image: $e')),
      );
    }
  }

  Future<void> _selectDateOfBirth() async {
    final selectedDate = await showDatePicker(
      context: context,
      initialDate: DateTime(2000),
      firstDate: DateTime(1950),
      lastDate: DateTime.now().subtract(Duration(days: 365 * 18)),
    );

    if (selectedDate != null) {
      _dateOfBirthController.text =
          '${selectedDate.year}-${selectedDate.month.toString().padLeft(2, '0')}-${selectedDate.day.toString().padLeft(2, '0')}';
    }
  }

  Future<void> _handleContinue() async {
    if (!_formKey.currentState!.validate()) return;
    if (_profileImage == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please upload a profile picture')),
      );
      return;
    }

    final personalData = RiderPersonalData(
      firstName: _firstNameController.text,
      lastName: _lastNameController.text,
      email: _emailController.text,
      phone: _phoneController.text,
      password: _passwordController.text,
      passwordConfirmation: _confirmPasswordController.text,
      dateOfBirth: _dateOfBirthController.text,
      profileImagePath: _profileImage!.path,
      profileImageFile: _profileImage,
    );

    ref.read(riderRegistrationProvider.notifier).setPersonalData(personalData);

    setState(() {
      _isSubmitting = true;
    });

    try {
      final registrationData = personalData.toFormData();
      registrationData['user_type'] = 'rider';

      await ref.read(authStateProvider.notifier).register(registrationData);

      if (!mounted) return;
      Navigator.of(context).pushNamed('/rider-registration-step2');
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Registration failed: $e')),
      );
    } finally {
      if (mounted) {
        setState(() {
          _isSubmitting = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: const CustomAppBar(
        title: "Rider's Data",
        showBackButton: true,
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          child: Padding(
            padding: const EdgeInsets.all(AppSpacing.xl),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Step indicator
                StepProgressIndicator(
                  totalSteps: 4,
                  currentStep: 1,
                  stepLabels: const [
                    'Data',
                    'License',
                    'Guarantor',
                    'Bike',
                  ],
                ),
                const SizedBox(height: AppSpacing.xl),

                Form(
                  key: _formKey,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Profile Picture Upload
                      Center(
                        child: GestureDetector(
                          onTap: _pickProfileImage,
                          child: Container(
                            width: 120,
                            height: 120,
                            decoration: BoxDecoration(
                              shape: BoxShape.circle,
                              border: Border.all(
                                color: AppColors.grey300,
                                width: 2,
                              ),
                              color: AppColors.grey50,
                                  image: (_profileImage != null && fileImageProvider(_profileImage.path) != null)
                                    ? DecorationImage(image: fileImageProvider(_profileImage.path)!, fit: BoxFit.cover)
                                    : null,
                            ),
                            child: _profileImage == null
                                ? Center(
                                    child: Column(
                                      mainAxisAlignment:
                                          MainAxisAlignment.center,
                                      children: [
                                        Icon(
                                          Icons.camera_alt_outlined,
                                          color: AppColors.primary,
                                          size: 32,
                                        ),
                                        const SizedBox(height: 4),
                                        Text(
                                          'Upload Photo',
                                          style:
                                              AppTextStyles.labelSmall.copyWith(
                                            color: AppColors.primary,
                                          ),
                                        ),
                                      ],
                                    ),
                                  )
                                : _profileImage != null && kIsWeb
                                    ? Center(
                                        child: Column(
                                          mainAxisAlignment:
                                              MainAxisAlignment.center,
                                          children: [
                                            Icon(
                                              Icons.check_circle,
                                              color: AppColors.primary,
                                              size: 32,
                                            ),
                                            const SizedBox(height: 4),
                                            Text(
                                              'Photo selected',
                                              style: AppTextStyles.labelSmall
                                                  .copyWith(
                                                color: AppColors.primary,
                                              ),
                                            ),
                                          ],
                                        ),
                                      )
                                    : null,
                          ),
                        ),
                      ),
                      const SizedBox(height: AppSpacing.xl),

                      // First Name & Last Name
                      Row(
                        children: [
                          Expanded(
                            child: CustomTextField(
                              label: 'First Name',
                              controller: _firstNameController,
                              hint: 'e.g., John',
                              validator: (value) {
                                if (value?.isEmpty ?? true) {
                                  return 'First name is required';
                                }
                                return null;
                              },
                            ),
                          ),
                          const SizedBox(width: AppSpacing.md),
                          Expanded(
                            child: CustomTextField(
                              label: 'Last Name',
                              controller: _lastNameController,
                              hint: 'e.g., Doe',
                              validator: (value) {
                                if (value?.isEmpty ?? true) {
                                  return 'Last name is required';
                                }
                                return null;
                              },
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: AppSpacing.lg),

                      // Email
                      CustomTextField(
                        label: 'Email Address',
                        controller: _emailController,
                        keyboardType: TextInputType.emailAddress,
                        hint: 'your.email@example.com',
                        validator: (value) {
                          if (value?.isEmpty ?? true) {
                            return 'Email is required';
                          }
                          if (!RegExp(r'^[^@]+@[^@]+\.[^@]+')
                              .hasMatch(value!)) {
                            return 'Please enter a valid email';
                          }
                          return null;
                        },
                      ),
                      const SizedBox(height: AppSpacing.lg),

                      // Phone
                      CustomTextField(
                        label: 'Phone Number',
                        controller: _phoneController,
                        keyboardType: TextInputType.phone,
                        hint: '+234 (0) 900 0000 000',
                        validator: (value) {
                          if (value?.isEmpty ?? true) {
                            return 'Phone number is required';
                          }
                          return null;
                        },
                      ),
                      const SizedBox(height: AppSpacing.lg),

                      // Date of Birth
                      GestureDetector(
                        onTap: _selectDateOfBirth,
                        child: CustomTextField(
                          label: 'Date of Birth',
                          controller: _dateOfBirthController,
                          hint: 'YYYY-MM-DD',
                          enabled: false,
                          validator: (value) {
                            if (value?.isEmpty ?? true) {
                              return 'Date of birth is required';
                            }
                            return null;
                          },
                        ),
                      ),
                      const SizedBox(height: AppSpacing.lg),

                      // Password
                      CustomTextField(
                        label: 'Password',
                        controller: _passwordController,
                        hint: 'Min 8 characters',
                        obscureText: !_isPasswordVisible,
                        suffixIcon: _isPasswordVisible
                            ? Icons.visibility
                            : Icons.visibility_off,
                        onSuffixIconPressed: () {
                          setState(() {
                            _isPasswordVisible = !_isPasswordVisible;
                          });
                        },
                        validator: (value) {
                          if (value?.isEmpty ?? true) {
                            return 'Password is required';
                          }
                          if (value!.length < 8) {
                            return 'Password must be at least 8 characters';
                          }
                          return null;
                        },
                      ),
                      const SizedBox(height: AppSpacing.lg),

                      // Confirm Password
                      CustomTextField(
                        label: 'Confirm Password',
                        controller: _confirmPasswordController,
                        hint: 'Re-enter your password',
                        obscureText: !_isConfirmPasswordVisible,
                        suffixIcon: _isConfirmPasswordVisible
                            ? Icons.visibility
                            : Icons.visibility_off,
                        onSuffixIconPressed: () {
                          setState(() {
                            _isConfirmPasswordVisible =
                                !_isConfirmPasswordVisible;
                          });
                        },
                        validator: (value) {
                          if (value?.isEmpty ?? true) {
                            return 'Please confirm your password';
                          }
                          if (value != _passwordController.text) {
                            return 'Passwords do not match';
                          }
                          return null;
                        },
                      ),
                      const SizedBox(height: AppSpacing.xl),

                      
                      const SizedBox(height: AppSpacing.xl),

                      // Terms & Conditions
                      Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Container(
                            width: 24,
                            height: 24,
                            decoration: BoxDecoration(
                              color: AppColors.primary,
                              borderRadius:
                                  BorderRadius.circular(AppSpacing.sm),
                            ),
                            child: const Icon(
                              Icons.check,
                              color: Colors.white,
                              size: 16,
                            ),
                          ),
                          const SizedBox(width: AppSpacing.md),
                          Expanded(
                            child: Text.rich(
                              TextSpan(
                                text:
                                    'I agree to ZaddyExpress ',
                                style: AppTextStyles.bodySmall,
                                children: [
                                  WidgetSpan(
                                    child: GestureDetector(
                                      onTap: () => Navigator.of(context)
                                          .pushNamed('/rider-terms'),
                                      child: Text(
                                        'Terms & Conditions',
                                        style: AppTextStyles.bodySmall.copyWith(
                                          color: AppColors.secondary,
                                          decoration: TextDecoration.underline,
                                        ),
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: AppSpacing.xl),

                      // Continue Button
                      SizedBox(
                        width: double.infinity,
                        height: 56,
                        child: ElevatedButton(
                          onPressed: _isSubmitting ? null : _handleContinue,
                          style: ElevatedButton.styleFrom(
                            backgroundColor: AppColors.accent,
                            disabledBackgroundColor: AppColors.grey400,
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(12),
                            ),
                          ),
                          child: _isSubmitting
                              ? SizedBox(
                                  height: 24,
                                  width: 24,
                                  child: CircularProgressIndicator(
                                    valueColor: AlwaysStoppedAnimation<Color>(
                                      Colors.white.withOpacity(0.8),
                                    ),
                                    strokeWidth: 2,
                                  ),
                                )
                              : Text(
                                  'Continue',
                                  style: AppTextStyles.labelLarge.copyWith(
                                    color: Colors.white,
                                  ),
                                ),
                        ),
                      ),
                    ],
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
