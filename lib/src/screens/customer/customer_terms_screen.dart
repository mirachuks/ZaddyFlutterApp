import 'package:flutter/material.dart';
import '../../config/theme.dart';
import '../../widgets/index.dart';

class CustomerTermsScreen extends StatelessWidget {
  const CustomerTermsScreen({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: const CustomAppBar(
        title: 'Terms & Conditions',
        showBackButton: true,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(AppSpacing.lg),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'ZaddyExpress Terms & Conditions – Customers (Users)',
              style: AppTextStyles.headingMedium,
            ),
            const SizedBox(height: AppSpacing.lg),
            _buildSection('1. Acceptance of Terms',
                'By using the ZaddyExpress platform, you agree to these Terms and Conditions and all applicable policies.'),
            _buildSection('2. Platform Role',
                'ZaddyExpress is a technology platform that connects customers with independent delivery riders. ZaddyExpress is not the seller, manufacturer, or owner of goods being transported unless expressly stated otherwise.'),
            _buildSection('3. User Responsibilities',
                'Users shall provide accurate pickup and delivery information, valid contact details, and clear delivery instructions.'),
            _buildSection('4. Prohibited Items',
                'Users shall not request the transportation of illegal, dangerous, hazardous, counterfeit, stolen, prohibited, or restricted items. ZaddyExpress reserves the right to refuse or cancel such requests.'),
            _buildSection('5. Package Verification',
                'Users are solely responsible for the contents, legality, packaging, and labeling of all items submitted for delivery.'),
            _buildSection('6. Delivery Time Estimates',
                'Delivery times displayed on the platform are estimates only and are not guaranteed due to traffic, weather, security conditions, rider availability, or other unforeseen circumstances.'),
            _buildSection('7. Failed Deliveries',
                'Additional charges may apply where deliveries fail due to incorrect addresses, recipient unavailability, refusal to accept delivery, or inability to contact the sender or recipient.'),
            _buildSection('8. Limitation of Liability',
                'ZaddyExpress shall not be liable for indirect, incidental, consequential, special, or punitive damages arising from the use of the platform.'),
            _buildSection('9. Compensation Limits',
                'Where liability is established, compensation for lost or damaged items shall not exceed the declared item value or the maximum compensation limit determined by ZaddyExpress policy.'),
            _buildSection('10. Inspection Rights',
                'ZaddyExpress reserves the right to inspect, reject, or report any package suspected to contain prohibited items or items posing safety risks.'),
            _buildSection('11. Payments',
                'Users agree to pay all applicable delivery fees, service charges, penalties, and other charges displayed on the platform.'),
            _buildSection('12. Account Suspension',
                'ZaddyExpress may suspend or terminate any user account involved in fraud, abuse, unlawful activity, chargeback abuse, or violation of these Terms.'),
            _buildSection('13. Privacy',
                'Users consent to the collection and processing of personal information necessary to provide delivery services and improve platform operations.'),
            _buildSection('14. Amendments',
                'ZaddyExpress reserves the right to modify these Terms at any time. Continued use of the platform constitutes acceptance of the revised Terms.'),
            const SizedBox(height: AppSpacing.lg),
            Text(
              'Dispute Resolution',
              style: AppTextStyles.labelLarge,
            ),
            const SizedBox(height: AppSpacing.sm),
            Text(
              'Any dispute arising from the use of the ZaddyExpress platform shall first be resolved through negotiation with ZaddyExpress. Where resolution is not achieved, disputes shall be subject to the laws of the Federal Republic of Nigeria and the courts of competent jurisdiction in Nigeria.',
              style: AppTextStyles.bodyMedium,
            ),
            const SizedBox(height: AppSpacing.lg),
            Text(
              'Force Majeure',
              style: AppTextStyles.labelLarge,
            ),
            const SizedBox(height: AppSpacing.sm),
            Text(
              'ZaddyExpress shall not be liable for delays, interruptions, or service failures caused by events beyond its reasonable control, including accidents, weather conditions, government actions, strikes, civil unrest, internet outages, or natural disasters.',
              style: AppTextStyles.bodyMedium,
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
