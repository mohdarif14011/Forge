import 'package:flutter/material.dart';
import '../../widgets/animated_back_button.dart';
import '../../widgets/section_title.dart';

class TermsScreen extends StatelessWidget {
  const TermsScreen({super.key});

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
                      child: SectionTitle(title: 'Terms and Conditions'),
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
                    _buildSection(context, '1. Acceptance of Terms', 'By accessing and using this application, you accept and agree to be bound by the terms and provision of this agreement. In addition, when using these particular services, you shall be subject to any posted guidelines or rules applicable to such services.'),
                    _buildSection(context, '2. User Accounts', 'To access most features of the platform, you must register for an account. You agree to provide accurate, current, and complete information during the registration process and to update such information to keep it accurate, current, and complete. You are responsible for safeguarding your password and for all activities that occur under your account.'),
                    _buildSection(context, '3. Subscription and Billing', 'Certain features of our service are billed on a subscription basis. You will be billed in advance on a recurring and periodic basis. If your auto-renewal fails, your premium access will be suspended until payment is received.'),
                    _buildSection(context, '4. Educational Content and Accuracy', 'The educational material provided in this app is for general informational purposes. While we strive to provide high-quality and accurate study materials, we make no guarantees regarding the completeness, reliability, or accuracy of the mock tests, PYQs, and notes.'),
                    _buildSection(context, '5. User Conduct', 'You agree not to use the service to:\n• Upload, post, or transmit any content that is unlawful, harmful, or abusive.\n• Impersonate any person or entity.\n• Attempt to bypass or break any security mechanism of the application.\n• Share your premium account credentials with unauthorized users.'),
                    _buildSection(context, '6. Intellectual Property Rights', 'All content, features, and functionality (including but not limited to all information, software, text, displays, images, video, and audio) are owned by the platform and are protected by international copyright, trademark, patent, trade secret, and other intellectual property laws. You may not reproduce, distribute, or create derivative works from any part of the app.'),
                    _buildSection(context, '7. Limitation of Liability', 'In no event shall the platform, nor its directors, employees, partners, agents, suppliers, or affiliates, be liable for any indirect, incidental, special, consequential or punitive damages, including without limitation, loss of profits, data, use, goodwill, or other intangible losses, resulting from your access to or use of or inability to access or use the Service.'),
                    _buildSection(context, '8. Modifications to Terms', 'We reserve the right, at our sole discretion, to modify or replace these Terms at any time. If a revision is material we will try to provide at least 30 days notice prior to any new terms taking effect. What constitutes a material change will be determined at our sole discretion.'),
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
