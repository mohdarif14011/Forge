import 'package:flutter/material.dart';
import '../../widgets/animated_back_button.dart';
import '../../widgets/section_title.dart';

class PrivacyScreen extends StatelessWidget {
  const PrivacyScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      body: SafeArea(
        child: Column(
          children: [
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 12.0),
              child: Row(
                children: [
                  const AnimatedBackButton(),
                  const Expanded(
                    child: Center(
                      child: SectionTitle(title: 'Privacy Policy'),
                    ),
                  ),
                  const SizedBox(width: 40),
                ],
              ),
            ),
            Expanded(
              child: SingleChildScrollView(
                padding: const EdgeInsets.all(24.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('Last updated: July 2026', style: TextStyle(color: Colors.grey.shade600, fontSize: 13)),
                    const SizedBox(height: 24),
                    _buildSection(context, '1. Information We Collect', 'When you use our application, we may collect personal information such as your name, email address, profile picture, phone number, and academic details. We also automatically collect diagnostic, usage, and performance data when you access or use the app, such as device identifiers and IP addresses.'),
                    _buildSection(context, '2. How We Use Your Information', 'We use the collected information for various purposes:\n• To provide and maintain our Service.\n• To personalize your learning experience and track your mock test progress.\n• To notify you about changes to our Service.\n• To provide customer support.\n• To monitor the usage of our Service and detect, prevent, and address technical issues.'),
                    _buildSection(context, '3. Information Sharing and Disclosure', 'We do not sell, trade, or rent your personal identification information to others. We may share generic aggregated demographic information not linked to any personal identification information regarding visitors and users with our business partners, trusted affiliates, and advertisers. We may disclose your information if required to do so by law.'),
                    _buildSection(context, '4. Data Security', 'The security of your data is important to us. We adopt appropriate data collection, storage, and processing practices and security measures to protect against unauthorized access, alteration, disclosure, or destruction of your personal information, username, password, transaction information, and data stored on our app.'),
                    _buildSection(context, '5. Third-Party Services', 'Our app may contain links to third-party websites or services (e.g., payment gateways) that are not owned or controlled by us. We have no control over and assume no responsibility for the content, privacy policies, or practices of any third-party websites or services. We encourage you to read the privacy policies of any third-party service you visit.'),
                    _buildSection(context, '6. Children\'s Privacy', 'Our Service does not address anyone under the age of 13. We do not knowingly collect personally identifiable information from anyone under the age of 13. If you are a parent or guardian and you are aware that your child has provided us with Personal Data, please contact us so that we can take necessary actions.'),
                    _buildSection(context, '7. Changes to This Privacy Policy', 'We may update our Privacy Policy from time to time. We will notify you of any changes by posting the new Privacy Policy on this page and updating the "Last updated" date at the top. You are advised to review this Privacy Policy periodically for any changes.'),
                    _buildSection(context, '8. Contact Us', 'If you have any questions about this Privacy Policy, please contact our support team through the Help & Support section in the app or by emailing our official contact address.'),
                    const SizedBox(height: 40),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSection(BuildContext context, String title, String content) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 24.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            title,
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.bold,
              color: Theme.of(context).colorScheme.onSurface,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            content,
            style: TextStyle(
              fontSize: 14,
              color: Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.8),
              height: 1.6,
            ),
          ),
        ],
      ),
    );
  }
}
