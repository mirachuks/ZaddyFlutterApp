import 'package:flutter/material.dart';
import '../../config/theme.dart';
import '../../widgets/index.dart';

class RiderTermsScreen extends StatelessWidget {
  const RiderTermsScreen({Key? key}) : super(key: key);

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
              'ZaddyExpress Terms & Conditions – Riders',
              style: AppTextStyles.headingMedium,
            ),
            const SizedBox(height: AppSpacing.lg),
            _buildSection('1. Independent Contractor Relationship',
                'Riders operate as independent contractors and not as employees, agents, partners, or representatives of ZaddyExpress.'),
            _buildSection('2. Rider Eligibility',
                'Riders must maintain valid identification, licenses, permits, and other documents required by law and by ZaddyExpress.'),
            _buildSection('3. Compliance with Laws',
                'Riders shall comply with all traffic laws, road safety regulations, and government requirements at all times.'),
            _buildSection('4. Account Responsibility',
                'Riders are responsible for maintaining the confidentiality and security of their accounts and login credentials.'),
            _buildSection('5. Delivery Standards',
                'Riders shall handle all deliveries professionally, safely, and with reasonable care.'),
            _buildSection('6. Prohibited Conduct',
                'Riders shall not engage in theft, fraud, harassment, misconduct, discrimination, violence, substance abuse while on duty, or any unlawful activity.'),
            _buildSection('7. Cash Handling',
                'Riders collecting cash on behalf of ZaddyExpress must accurately account for and remit all funds received. Any shortage may result in deductions, suspension, or legal action.'),
            _buildSection('8. Equipment and Vehicle Responsibility',
                'Riders are solely responsible for maintaining their motorcycles, bicycles, vehicles, phones, fuel, insurance, permits, and operating expenses.'),
            _buildSection('9. Liability for Losses',
                'Riders may be held responsible for losses resulting from negligence, misconduct, theft, fraud, unauthorized delivery completion, or intentional damage.'),
            _buildSection('10. No Guaranteed Earnings',
                'ZaddyExpress does not guarantee any minimum number of delivery requests or minimum earnings.'),
            _buildSection('11. Suspension and Termination',
                'ZaddyExpress may suspend or permanently deactivate a rider account for safety violations, poor performance, customer complaints, fraud, misconduct, document expiration, or breach of these Terms.'),
            _buildSection('12. GPS and Activity Monitoring',
                'Riders consent to location tracking and operational monitoring while using the platform for service quality, safety, and dispute resolution purposes.'),
            _buildSection('13. Indemnity',
                'Riders agree to indemnify and hold harmless ZaddyExpress from claims, damages, penalties, or losses arising from the rider\'s negligence, misconduct, or violation of applicable laws.'),
            _buildSection('14. Amendments',
                'ZaddyExpress reserves the right to amend these Terms at any time. Continued use of the platform constitutes acceptance of such amendments.'),
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
