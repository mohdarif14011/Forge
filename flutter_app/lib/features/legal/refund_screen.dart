import 'package:flutter/material.dart';
import '../../widgets/animated_back_button.dart';
import '../../widgets/section_title.dart';

class RefundScreen extends StatelessWidget {
  const RefundScreen({super.key});

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
                      child: SectionTitle(title: 'Refund Policy'),
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
                    _buildSection(context, '1. General Refund Policy', 'We want to ensure you are 100% happy with your purchase. However, due to the digital nature of our educational products and subscriptions, we generally do not offer refunds once the subscription has been activated or the digital goods have been accessed, except as outlined in this policy.'),
                    _buildSection(context, '2. Eligibility for Refunds', 'You may be eligible for a refund if:\n• You were charged multiple times for the same transaction due to a technical error.\n• The content you purchased is completely inaccessible or heavily flawed, and our support team cannot resolve the issue within 7 business days.\n• You request a cancellation and refund within 24 hours of your initial purchase, provided you have not completed any mock tests or downloaded any study materials.'),
                    _buildSection(context, '3. Non-Refundable Scenarios', 'Refunds will NOT be granted under the following circumstances:\n• You changed your mind after purchasing.\n• You forgot to cancel an auto-renewing subscription before the renewal date.\n• You have actively used the premium features, taken multiple mock tests, or downloaded substantial notes.\n• Your account was suspended or terminated due to a violation of our Terms and Conditions.'),
                    _buildSection(context, '4. Subscription Cancellations', 'You can cancel your subscription at any time to prevent future billing. Cancellation will take effect at the end of the current billing cycle. You will continue to have access to your premium features until the end of your billing cycle. We do not provide prorated refunds for mid-cycle cancellations.'),
                    _buildSection(context, '5. How to Request a Refund', 'To request a refund, please contact our support team through the Help & Support section or by emailing us directly. You must include your account email, proof of purchase, and a detailed explanation of why you are requesting a refund. Our team will review your request and respond within 3-5 business days.'),
                    _buildSection(context, '6. Processing Refunds', 'If your refund request is approved, the refund will be processed, and a credit will automatically be applied to your credit card or original method of payment within 7-10 business days, depending on your bank or payment provider.'),
                    _buildSection(context, '7. Abuse of the Refund Policy', 'We reserve the right, at our sole discretion, to limit or deny refund requests in cases where we believe there is refund abuse, including but not limited to purchasing and requesting refunds for multiple subscriptions or a history of refund requests.'),
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
