import 'package:flutter/material.dart';
import '../../config/theme.dart';
import '../../widgets/index.dart';

class RiderPolicyScreen extends StatelessWidget {
  const RiderPolicyScreen({Key? key}) : super(key: key);

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
              'ZaddyExpress Privacy Policy – Riders',
              style: AppTextStyles.headingMedium,
            ),
            const SizedBox(height: AppSpacing.lg),
            _buildSection(
              'Information We Collect',
              'We collect personal information including your name, phone number, email, identification documents, bank details, vehicle information, location data, and delivery history to provide and improve our services.',
            ),
            _buildSection(
              'How We Use Your Information',
              'Your information is used to verify your identity, process payments, monitor service quality, ensure safety, prevent fraud, and improve our platform. We may also use it for marketing and customer support purposes.',
            ),
            _buildSection(
              'Location Tracking',
              'With your consent, we collect and monitor your location data in real-time to track deliveries, ensure rider safety, and optimize route efficiency. This data is retained for dispute resolution purposes.',
            ),
            _buildSection(
              'Data Security',
              'We implement industry-standard security measures to protect your personal information. However, no method of transmission over the internet is completely secure, and we cannot guarantee absolute security.',
            ),
            _buildSection(
              'Sharing Your Information',
              'We may share your information with customers for delivery purposes, payment processors for transaction processing, regulatory authorities when required by law, and third-party service providers who assist us in operations.',
            ),
            _buildSection(
              'Data Retention',
              'We retain your personal information for as long as necessary to provide services and comply with legal obligations. You may request deletion of your data, subject to our legal retention requirements.',
            ),
            _buildSection(
              'Your Rights',
              'You have the right to access, correct, and request deletion of your personal information. You may also withdraw consent for location tracking, though this may limit your ability to use the platform.',
            ),
            _buildSection(
              'Third-Party Links',
              'Our platform may contain links to third-party websites. We are not responsible for the privacy practices of these external sites.',
            ),
            _buildSection(
              'Policy Changes',
              'We may update this Privacy Policy at any time. Continued use of the platform constitutes acceptance of any changes.',
            ),
            _buildSection(
              'Contact Us',
              'For privacy inquiries, please contact our support team through the app or email our privacy team directly.',
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
