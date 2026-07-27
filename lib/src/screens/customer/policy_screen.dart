import 'package:flutter/material.dart';
import '../../config/theme.dart';
import '../../widgets/index.dart';

class PolicyScreen extends StatefulWidget {
  const PolicyScreen({Key? key}) : super(key: key);

  @override
  State<PolicyScreen> createState() => _PolicyScreenState();
}

class _PolicyScreenState extends State<PolicyScreen> with SingleTickerProviderStateMixin {
  late TabController _tabController;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 3, vsync: this);
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
        title: const Text('Policies & Terms'),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () => Navigator.pop(context),
        ),
        bottom: TabBar(
          controller: _tabController,
          tabs: const [
            Tab(text: 'Terms'),
            Tab(text: 'Privacy'),
            Tab(text: 'Conduct'),
          ],
        ),
      ),
      body: TabBarView(
        controller: _tabController,
        children: [
          _buildTermsTab(),
          _buildPrivacyTab(),
          _buildConductTab(),
        ],
      ),
    );
  }

  Widget _buildTermsTab() {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(AppSpacing.lg),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildSection(
            'Terms of Service',
            'These terms govern your use of ZaddyExpress. By using our platform, you agree to comply with all terms and conditions outlined herein.',
          ),
          _buildSection(
            'Use License',
            'Permission is granted to temporarily download one copy of the materials on ZaddyExpress for personal, non-commercial transitory viewing only.',
          ),
          _buildSection(
            'Disclaimer',
            'The materials on ZaddyExpress are provided on an "as is" basis. ZaddyExpress makes no warranties, expressed or implied, and hereby disclaims and negates all other warranties.',
          ),
          _buildSection(
            'Limitation of Liability',
            'In no event shall ZaddyExpress or its suppliers be liable for any damages arising out of or related to the use of this website.',
          ),
        ],
      ),
    );
  }

  Widget _buildPrivacyTab() {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(AppSpacing.lg),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildSection(
            'Data Collection',
            'We collect information you provide directly to us, such as when you create an account or place an order.',
          ),
          _buildSection(
            'Data Usage',
            'Your data is used to provide and improve our services, process transactions, and communicate with you about our services.',
          ),
          _buildSection(
            'Data Security',
            'We implement appropriate technical and organizational measures to protect your personal data against unauthorized access.',
          ),
          _buildSection(
            'Third-Party Sharing',
            'We do not sell, trade, or rent your personal information to third parties without your consent.',
          ),
          _buildSection(
            'Contact Us',
            'If you have privacy concerns, please contact us at privacy@zaddyexpress.com',
          ),
        ],
      ),
    );
  }

  Widget _buildConductTab() {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(AppSpacing.lg),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildSection(
            'User Responsibilities',
            'Users must comply with all applicable laws and regulations. You are responsible for all activities that occur under your account.',
          ),
          _buildSection(
            'Prohibited Conduct',
            'Users must not engage in harassment, discrimination, fraud, or any illegal activities on the platform.',
          ),
          _buildSection(
            'Package Integrity',
            'Users must accurately describe package contents. Prohibited items include weapons, drugs, and hazardous materials.',
          ),
          _buildSection(
            'Payment Obligations',
            'Users agree to pay all fees and charges associated with their use of the platform.',
          ),
          _buildSection(
            'Dispute Resolution',
            'Disputes shall be resolved through our support team. Users agree to mediation before pursuing legal action.',
          ),
        ],
      ),
    );
  }

  Widget _buildSection(String title, String content) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          title,
          style: AppTextStyles.labelMedium.copyWith(
            fontWeight: FontWeight.bold,
            color: AppColors.primary,
          ),
        ),
        const SizedBox(height: AppSpacing.sm),
        Text(
          content,
          style: AppTextStyles.bodyMedium.copyWith(
            color: AppColors.textSecondary,
            height: 1.5,
          ),
        ),
        const SizedBox(height: AppSpacing.lg),
      ],
    );
  }
}
