import 'package:flutter/material.dart';
import '../../config/theme.dart';
import '../../widgets/index.dart';

class CustomerPolicyScreen extends StatelessWidget {
  const CustomerPolicyScreen({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: const CustomAppBar(
        title: 'Privacy Policy',
        showBackButton: true,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(AppSpacing.lg),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'ZaddyExpress Privacy Policy – Customers (Users)',
              style: AppTextStyles.headingMedium,
            ),
            const SizedBox(height: AppSpacing.lg),
            _buildSection(
              'Information We Collect',
              'We collect personal information including your name, phone number, email, delivery addresses, payment information, and delivery preferences to provide and improve our services.',
            ),
            _buildSection(
              'How We Use Your Information',
              'Your information is used to process your delivery requests, facilitate payments, communicate with riders, improve our services, prevent fraud, and provide customer support.',
            ),
            _buildSection(
              'Location Information',
              'We collect and process your pickup and delivery location data to match you with available riders and facilitate delivery tracking. This data is used for service improvement and dispute resolution.',
            ),
            _buildSection(
              'Payment Information',
              'We securely process your payment information through encrypted payment gateways. We do not store your complete credit card or bank details. Payment information is handled in compliance with payment industry standards.',
            ),
            _buildSection(
              'Data Security',
              'We implement industry-standard security measures to protect your personal and payment information. However, no method of transmission over the internet is completely secure.',
            ),
            _buildSection(
              'Sharing Your Information',
              'We share essential delivery information with assigned riders to facilitate your delivery. We may also share information with payment processors, regulatory authorities when required, and third-party service providers.',
            ),
            _buildSection(
              'Data Retention',
              'We retain your personal information for as long as necessary to provide services and comply with legal obligations. Account information may be retained for dispute resolution and legal purposes.',
            ),
            _buildSection(
              'Your Rights',
              'You have the right to access, correct, and request deletion of your personal information. You may also control your communication preferences and opt-out of marketing communications.',
            ),
            _buildSection(
              'Cookies',
              'Our platform may use cookies and similar technologies to improve your user experience. You can control cookie settings through your browser preferences.',
            ),
            _buildSection(
              'Third-Party Links',
              'Our platform may contain links to third-party websites and payment gateways. We are not responsible for the privacy practices of these external sites.',
            ),
            _buildSection(
              'Policy Changes',
              'We may update this Privacy Policy at any time. We will notify you of significant changes. Continued use of the platform constitutes acceptance of changes.',
            ),
            _buildSection(
              'Contact Us',
              'For privacy inquiries or concerns, please contact our support team through the app or email our customer service department.',
            ),
            const SizedBox(height: AppSpacing.xl),
          ],
        ),
      ),
    );
  }

  Widget _buildSection(String title, String content) {
    return Padding(
      padding: const EdgeInsets.only(bottom: AppSpacing.lg),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            title,
            style: AppTextStyles.labelLarge,
          ),
          const SizedBox(height: AppSpacing.sm),
          Text(
            content,
            style: AppTextStyles.bodyMedium,
          ),
        ],
      ),
    );
  }
}
