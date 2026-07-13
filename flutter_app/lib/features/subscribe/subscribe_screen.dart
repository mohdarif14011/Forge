import 'package:flutter/material.dart';
import 'package:flutter/cupertino.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:go_router/go_router.dart';
import '../../core/theme.dart';
import '../../widgets/animated_back_button.dart';

class SubscribeScreen extends StatefulWidget {
  const SubscribeScreen({super.key});

  @override
  State<SubscribeScreen> createState() => _SubscribeScreenState();
}

class _SubscribeScreenState extends State<SubscribeScreen> {
  bool _isLoading = true;
  bool _hasAppSubscription = false;
  String? _appSubscriptionExpiry;
  String? _activePlanName;

  double _app6MonthsPrice = 80;
  double _app1YearPrice = 99;

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  Future<void> _loadData() async {
    await Future.wait([
      _loadUserSubscriptionData(),
      _loadPricingData(),
    ]);
    if (mounted) {
      setState(() => _isLoading = false);
    }
  }

  Future<void> _loadPricingData() async {
    try {
      final doc = await FirebaseFirestore.instance.collection('settings').doc('pricing').get();
      if (doc.exists) {
        final data = doc.data() ?? {};
        if (mounted) {
          setState(() {
            _app6MonthsPrice = (data['app_6_months'] ?? 80).toDouble();
            _app1YearPrice = (data['app_1_year'] ?? 99).toDouble();
          });
        }
      }
    } catch (e) {
      debugPrint("Error loading pricing data: $e");
    }
  }

  Future<void> _loadUserSubscriptionData() async {
    try {
      final user = FirebaseAuth.instance.currentUser;
      if (user != null) {
        final doc = await FirebaseFirestore.instance.collection('users').doc(user.uid).get();
        if (doc.exists) {
          final data = doc.data() ?? {};
          if (mounted) {
            setState(() {
              _hasAppSubscription = data['hasAppSubscription'] as bool? ?? false;
              _appSubscriptionExpiry = data['appSubscriptionExpiry'] as String?;
              _activePlanName = data['activePlanName'] as String?;
              
              if (_hasAppSubscription && _appSubscriptionExpiry != null) {
                final expiryDate = DateTime.tryParse(_appSubscriptionExpiry!);
                if (expiryDate != null && expiryDate.isBefore(DateTime.now())) {
                  _hasAppSubscription = false;
                }
              }
            });
          }
        }
      }
    } catch (e) {
      debugPrint("Error loading subscription data: $e");
    }
  }

  void _navigateToCheckout({
    required String planName,
    required double amount,
    required String description,
    required String type,
  }) {
    context.push('/checkout', extra: {
      'planName': planName,
      'amount': amount,
      'description': description,
      'type': type,
    });
  }

  void _purchaseAppSubscription(String durationName, double amount) {
    _navigateToCheckout(
      planName: 'Whole App Gold Access ($durationName)',
      amount: amount,
      description: 'Unlock mock tests, reports, study notes, and explanations.',
      type: 'app',
    );
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Scaffold(
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : Stack(
              children: [
                // Background Gradient
                Positioned.fill(
                  child: Container(
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                        colors: isDark 
                            ? [const Color(0xFF1F1A0F), const Color(0xFF121212)]
                            : [const Color(0xFFFFF9E5), const Color(0xFFFDF7F0)],
                      ),
                    ),
                  ),
                ),
                
                // Decorator Orbs
                Positioned(
                  top: -50,
                  right: -50,
                  child: Container(
                    width: 200,
                    height: 200,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      color: Colors.amber.withValues(alpha: isDark ? 0.05 : 0.2),
                    ),
                  ),
                ),

                SafeArea(
                  child: Column(
                    children: [
                      Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 12.0),
                        child: Row(
                          children: [
                            const AnimatedBackButton(),
                            Expanded(
                              child: Center(
                                child: Text(
                                  'Upgrade',
                                  style: TextStyle(
                                    fontSize: 18,
                                    fontWeight: FontWeight.bold,
                                    color: Theme.of(context).colorScheme.onSurface,
                                  ),
                                ),
                              ),
                            ),
                            const SizedBox(width: 40),
                          ],
                        ),
                      ),
                      
                      Expanded(
                        child: ListView(
                          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
                          children: [
                            // Hero Section
                            Center(
                              child: Container(
                                padding: const EdgeInsets.all(16),
                                decoration: BoxDecoration(
                                  shape: BoxShape.circle,
                                  color: Colors.amber.withValues(alpha: 0.15),
                                ),
                                child: const Icon(CupertinoIcons.rosette, size: 48, color: Colors.amber),
                              ),
                            ),
                            const SizedBox(height: 16),
                            Text(
                              'Forge Gold Access',
                              textAlign: TextAlign.center,
                              style: TextStyle(
                                fontSize: 32,
                                fontWeight: FontWeight.w900,
                                color: Theme.of(context).colorScheme.onSurface,
                                letterSpacing: -0.5,
                              ),
                            ),
                            const SizedBox(height: 8),
                            const Text(
                              'Unlock your true potential with unlimited access to premium features.',
                              textAlign: TextAlign.center,
                              style: TextStyle(fontSize: 15, color: Colors.grey, height: 1.4),
                            ),
                            
                            const SizedBox(height: 24),
                            
                            // Features List
                            Text(
                              'EVERYTHING YOU NEED TO SUCCEED:',
                              style: TextStyle(
                                fontSize: 11,
                                fontWeight: FontWeight.bold,
                                color: AppTheme.primaryBlue.withValues(alpha: 0.8),
                                letterSpacing: 1.2,
                              ),
                            ),
                            const SizedBox(height: 16),
                            _buildFeatureRow(Icons.menu_book_rounded, 'Comprehensive Study Notes', 'Topic-wise detailed materials'),
                            _buildFeatureRow(Icons.history_edu, 'Previous Year Questions (PYQs)', 'Real exam practice with solutions'),
                            _buildFeatureRow(Icons.library_books, 'Unlimited Practice Questions', 'Extensive question banks'),
                            _buildFeatureRow(Icons.timer, 'All India Mock Tests', 'Simulated exam environment'),
                            _buildFeatureRow(Icons.analytics, 'Smart Performance Analysis', 'Track weak areas and improve'),
                            _buildFeatureRow(Icons.psychology, 'AI Doubt Solver', 'Now included completely free!'),

                            const SizedBox(height: 24),

                            // Pricing Cards
                            if (_hasAppSubscription)
                              Container(
                                padding: const EdgeInsets.all(20),
                                decoration: BoxDecoration(
                                  gradient: const LinearGradient(colors: [Colors.amber, Colors.orange]),
                                  borderRadius: BorderRadius.circular(16),
                                ),
                                child: Column(
                                  children: [
                                    const Icon(CupertinoIcons.check_mark_circled_solid, color: Colors.white, size: 32),
                                    const SizedBox(height: 12),
                                    const Text('You are a Gold Member!', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 18)),
                                    const SizedBox(height: 4),
                                    Text('Your active plan: $_activePlanName', style: const TextStyle(color: Colors.white, fontSize: 13)),
                                  ],
                                ),
                              )
                            else ...[
                              _buildPricingCard(
                                title: '6 Months Access',
                                price: _app6MonthsPrice.toInt(),
                                originalPrice: (_app6MonthsPrice * 1.5).toInt(),
                                tag: 'GREAT FOR MIDTERMS',
                                isPopular: false,
                                onTap: () => _purchaseAppSubscription('6 Months', _app6MonthsPrice),
                              ),
                              const SizedBox(height: 16),
                              _buildPricingCard(
                                title: '1 Year Access',
                                price: _app1YearPrice.toInt(),
                                originalPrice: (_app1YearPrice * 2).toInt(),
                                tag: 'MOST POPULAR',
                                isPopular: true,
                                onTap: () => _purchaseAppSubscription('1 Year', _app1YearPrice),
                              ),
                            ],
                            const SizedBox(height: 24),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
    );
  }

  Widget _buildFeatureRow(IconData icon, String title, String subtitle) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              color: Theme.of(context).colorScheme.surface,
              shape: BoxShape.circle,
              border: Border.all(color: Theme.of(context).dividerTheme.color ?? const Color(0xFFE5E7EB), width: 0.5),
              boxShadow: [
                BoxShadow(color: Colors.black.withValues(alpha: 0.05), blurRadius: 4, offset: const Offset(0, 2))
              ]
            ),
            child: Icon(icon, color: AppTheme.primaryBlue, size: 18),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: TextStyle(fontWeight: FontWeight.w700, fontSize: 15, color: Theme.of(context).colorScheme.onSurface),
                ),
                const SizedBox(height: 2),
                Text(
                  subtitle,
                  style: const TextStyle(fontSize: 13, color: Colors.grey),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildPricingCard({
    required String title,
    required int price,
    required int originalPrice,
    required String tag,
    required bool isPopular,
    required VoidCallback onTap,
  }) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return GestureDetector(
      onTap: onTap,
      child: Container(
        decoration: BoxDecoration(
          color: Theme.of(context).colorScheme.surface,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(
            color: isPopular ? AppTheme.primaryBlue : (Theme.of(context).dividerTheme.color ?? const Color(0xFFE5E7EB)),
            width: isPopular ? 2 : 1,
          ),
          boxShadow: isPopular 
            ? [BoxShadow(color: AppTheme.primaryBlue.withValues(alpha: 0.2), blurRadius: 16, offset: const Offset(0, 4))] 
            : [BoxShadow(color: Colors.black.withValues(alpha: 0.05), blurRadius: 8, offset: const Offset(0, 2))],
        ),
        child: ClipRRect(
          borderRadius: BorderRadius.circular(18),
          child: Stack(
            children: [
              if (isPopular)
                Positioned(
                  top: 0,
                  right: 0,
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
                    decoration: const BoxDecoration(
                      color: AppTheme.primaryBlue,
                      borderRadius: BorderRadius.only(bottomLeft: Radius.circular(16)),
                    ),
                    child: Text(
                      tag,
                      style: const TextStyle(color: Colors.white, fontSize: 10, fontWeight: FontWeight.bold, letterSpacing: 0.5),
                    ),
                  ),
                ),
              Padding(
                padding: const EdgeInsets.all(16),
                child: Row(
                  children: [
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          if (!isPopular)
                            Padding(
                              padding: const EdgeInsets.only(bottom: 8.0),
                              child: Text(
                                tag,
                                style: TextStyle(color: Colors.grey[600], fontSize: 10, fontWeight: FontWeight.bold, letterSpacing: 0.5),
                              ),
                            ),
                          Text(
                            title,
                            style: TextStyle(
                              fontSize: 18,
                              fontWeight: FontWeight.bold,
                              color: Theme.of(context).colorScheme.onSurface,
                            ),
                          ),
                          const SizedBox(height: 8),
                          Row(
                            children: [
                              Text(
                                '₹$originalPrice',
                                style: const TextStyle(
                                  fontSize: 14,
                                  color: Colors.grey,
                                  decoration: TextDecoration.lineThrough,
                                ),
                              ),
                              const SizedBox(width: 8),
                              Container(
                                padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                                decoration: BoxDecoration(
                                  color: Colors.green.withValues(alpha: 0.1),
                                  borderRadius: BorderRadius.circular(4),
                                ),
                                child: const Text(
                                  'SAVE',
                                  style: TextStyle(color: Colors.green, fontSize: 9, fontWeight: FontWeight.bold),
                                ),
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.end,
                      children: [
                        Text(
                          '₹$price',
                          style: TextStyle(
                            fontSize: 32,
                            fontWeight: FontWeight.w900,
                            color: Theme.of(context).colorScheme.onSurface,
                            letterSpacing: -1,
                          ),
                        ),
                        const SizedBox(height: 8),
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                          decoration: BoxDecoration(
                            color: isPopular ? AppTheme.primaryBlue : (isDark ? const Color(0xFF2C2C2C) : const Color(0xFFF1F1F1)),
                            borderRadius: BorderRadius.circular(20),
                          ),
                          child: Text(
                            'Select',
                            style: TextStyle(
                              fontSize: 13,
                              fontWeight: FontWeight.bold,
                              color: isPopular ? Colors.white : Theme.of(context).colorScheme.onSurface,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
