import 'package:flutter/material.dart';
import 'package:flutter/cupertino.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:go_router/go_router.dart';
import '../../core/theme.dart';
import '../../widgets/app_button.dart';
import '../../widgets/animated_back_button.dart';

class CheckoutScreen extends StatefulWidget {
  final Map<String, dynamic> params;
  const CheckoutScreen({super.key, required this.params});

  @override
  State<CheckoutScreen> createState() => _CheckoutScreenState();
}

class _CheckoutScreenState extends State<CheckoutScreen> {
  String _selectedMethod = 'upi';
  bool _isProcessing = false;
  bool _isSuccess = false;

  int _userCoins = 0;
  bool _useCoins = false;

  @override
  void initState() {
    super.initState();
    _loadUserCoins();
  }

  Future<void> _loadUserCoins() async {
    final user = FirebaseAuth.instance.currentUser;
    if (user != null) {
      final doc = await FirebaseFirestore.instance.collection('users').doc(user.uid).get();
      if (doc.exists && mounted) {
        setState(() {
          _userCoins = doc.data()?['coins'] as int? ?? 0;
        });
      }
    }
  }

  final TextEditingController _couponController = TextEditingController();
  String? _appliedCoupon;
  double _discountAmount = 0.0;
  int _discountPercentage = 0;
  bool _isApplyingCoupon = false;
  String? _couponError;

  Future<void> _applyCoupon(double originalAmount) async {
    final code = _couponController.text.trim();
    if (code.isEmpty) return;

    setState(() {
      _isApplyingCoupon = true;
      _couponError = null;
    });

    try {
      final snap = await FirebaseFirestore.instance.collection('coupons').where('code', isEqualTo: code).get();
      if (snap.docs.isEmpty) {
        setState(() => _couponError = 'Invalid coupon code');
      } else {
        final data = snap.docs.first.data();
        final status = data['status'] as String? ?? 'Active';
        final limit = data['usageLimit'] as int? ?? 0;
        final used = data['usedCount'] as int? ?? 0;
        final discountPercent = data['discountPercentage'] as num? ?? 0;

        if (status != 'Active') {
          setState(() => _couponError = 'Coupon is no longer active');
        } else if (limit > 0 && used >= limit) {
          setState(() => _couponError = 'Coupon usage limit reached');
        } else {
          final amt = (originalAmount * discountPercent.toDouble() / 100);
          setState(() {
            _appliedCoupon = code;
            _discountPercentage = discountPercent.toInt();
            _discountAmount = amt;
          });
          _showCouponSuccessDialog(code, discountPercent.toInt(), amt);
        }
      }
    } catch (e) {
      setState(() => _couponError = 'Error applying coupon');
    } finally {
      setState(() {
        _isApplyingCoupon = false;
      });
    }
  }

  void _showCouponSuccessDialog(String code, int percent, double amount) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: const Column(
          children: [
            Icon(CupertinoIcons.checkmark_seal_fill, color: Colors.green, size: 48),
            SizedBox(height: 12),
            Text('Coupon Applied!', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 20)),
          ],
        ),
        content: Text(
          'Congratulations! You just saved ₹${amount.toStringAsFixed(0)} ($percent%) on your purchase using code $code.',
          textAlign: TextAlign.center,
          style: const TextStyle(fontSize: 14),
        ),
        actionsAlignment: MainAxisAlignment.center,
        actions: [
          ElevatedButton(
            onPressed: () => Navigator.pop(context),
            style: ElevatedButton.styleFrom(
              backgroundColor: AppTheme.primaryBlue,
              foregroundColor: Colors.white,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
              padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
            ),
            child: const Text('Awesome!', style: TextStyle(fontWeight: FontWeight.bold)),
          )
        ],
      ),
    );
  }

  Future<void> _handlePayment() async {
    setState(() {
      _isProcessing = true;
    });

    // Simulate secure bank transaction delay
    await Future.delayed(const Duration(milliseconds: 1800));

    try {
      final user = FirebaseAuth.instance.currentUser;
      if (user != null) {
        final type = widget.params['type'] as String;
        final originalAmount = widget.params['amount'] as double;
        
        double amountAfterCoupon = (originalAmount - _discountAmount).clamp(0.0, double.infinity);
        double maxCoinsValue = _userCoins * 0.25;
        double coinDiscount = 0.0;
        int coinsToDeduct = 0;
        
        if (_useCoins) {
           coinDiscount = amountAfterCoupon < maxCoinsValue ? amountAfterCoupon : maxCoinsValue;
           coinsToDeduct = (coinDiscount / 0.25).ceil();
        }
        
        final amountPaid = (amountAfterCoupon - coinDiscount).clamp(0.0, double.infinity);
        final planName = widget.params['planName'] as String;

        // Save transaction
        final txnRef = FirebaseFirestore.instance.collection('transactions').doc();
        await txnRef.set({
          'userId': user.uid,
          'item': planName,
          'amount': amountPaid,
          'date': DateTime.now().toIso8601String(),
          'status': 'Completed',
          if (_appliedCoupon != null) 'coupon': _appliedCoupon,
          if (coinsToDeduct > 0) 'coinsUsed': coinsToDeduct,
        });

        if (coinsToDeduct > 0) {
           await FirebaseFirestore.instance.collection('users').doc(user.uid).update({
             'coins': FieldValue.increment(-coinsToDeduct),
           });
        }

        if (type == 'app') {
          final is6Months = planName.contains('6 Months');
          final duration = is6Months ? const Duration(days: 180) : const Duration(days: 365);
          
          await FirebaseFirestore.instance.collection('users').doc(user.uid).update({
            'hasAppSubscription': true,
            'activePlanName': planName,
            'appSubscriptionExpiry': DateTime.now().add(duration).toIso8601String(),
          });
        } else if (type == 'ai') {
          final qsToAdd = widget.params['qsToAdd'] as int;
          final userRef = FirebaseFirestore.instance.collection('users').doc(user.uid);
          
          await FirebaseFirestore.instance.runTransaction((transaction) async {
            final snapshot = await transaction.get(userRef);
            int currentLimit = 10;
            if (snapshot.exists) {
              currentLimit = snapshot.data()?['aiQuestionsLimit'] as int? ?? 10;
            }
            transaction.update(userRef, {
              'aiQuestionsLimit': currentLimit + qsToAdd,
            });
          });
        }

        if (_appliedCoupon != null) {
           final snap = await FirebaseFirestore.instance.collection('coupons').where('code', isEqualTo: _appliedCoupon).get();
           if (snap.docs.isNotEmpty) {
              final doc = snap.docs.first;
              await FirebaseFirestore.instance.collection('coupons').doc(doc.id).update({
                'usedCount': FieldValue.increment(1),
              });
           }
        }
      }

      setState(() {
        _isProcessing = false;
        _isSuccess = true;
      });

      // Show success checkmark for 1.2s before going back
      await Future.delayed(const Duration(milliseconds: 1200));
      if (mounted) {
        context.go('/home');
      }
    } catch (e) {
      setState(() {
        _isProcessing = false;
      });
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Payment failed: $e')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final planName = widget.params['planName'] ?? 'Premium Upgrade';
    final originalAmount = widget.params['amount'] ?? 0.0;
    
    double amountAfterCoupon = (originalAmount - _discountAmount).clamp(0.0, double.infinity);
    double maxCoinsValue = _userCoins * 0.25;
    double coinDiscount = 0.0;
    if (_useCoins) {
       coinDiscount = amountAfterCoupon < maxCoinsValue ? amountAfterCoupon : maxCoinsValue;
    }
    
    final amount = (amountAfterCoupon - coinDiscount).clamp(0.0, double.infinity);
    final description = widget.params['description'] ?? 'Unlimited app resources';

    if (_isProcessing) {
      return Scaffold(
        body: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const CircularProgressIndicator(strokeWidth: 3, color: AppTheme.primaryBlue),
              const SizedBox(height: 24),
              Text(
                'Processing Secured Transaction...',
                style: TextStyle(fontWeight: FontWeight.bold, fontSize: 18, color: Theme.of(context).colorScheme.onSurface),
              ),
              const SizedBox(height: 8),
              const Text(
                'Please do not refresh, go back or close the app.',
                style: TextStyle(color: Colors.grey, fontSize: 13),
              ),
            ],
          ),
        ),
      );
    }

    if (_isSuccess) {
      return Scaffold(
        body: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Icon(CupertinoIcons.check_mark_circled_solid, color: Colors.green, size: 72),
              const SizedBox(height: 24),
              Text(
                'Payment Successful!',
                style: TextStyle(fontWeight: FontWeight.bold, fontSize: 22, color: Theme.of(context).colorScheme.onSurface),
              ),
              const SizedBox(height: 8),
              const Text(
                'Your subscription has been updated.',
                style: TextStyle(color: Colors.grey, fontSize: 14),
              ),
            ],
          ),
        ),
      );
    }

    return Scaffold(
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      body: SafeArea(
        child: Column(
          children: [
            // Custom Header
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 12.0),
              child: Row(
                children: [
                  const AnimatedBackButton(),
                  Expanded(
                    child: Center(
                      child: Text(
                        'Secure Checkout',
                        style: TextStyle(
                          fontSize: 20,
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
                padding: const EdgeInsets.all(16.0),
                children: [
                  // Order Summary Card
                  Container(
                    padding: const EdgeInsets.all(20),
                    decoration: BoxDecoration(
                      color: Theme.of(context).colorScheme.surface,
                      borderRadius: BorderRadius.circular(20),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withValues(alpha: 0.04),
                          blurRadius: 10,
                          offset: const Offset(0, 4),
                        )
                      ],
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text(
                          'PLAN PURCHASED',
                          style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: AppTheme.primaryBlue, letterSpacing: 0.5),
                        ),
                        const SizedBox(height: 8),
                        Text(
                          planName,
                          style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: Theme.of(context).colorScheme.onSurface),
                        ),
                        const SizedBox(height: 6),
                        Text(
                          description,
                          style: const TextStyle(fontSize: 13, color: Colors.grey),
                        ),
                        const Divider(height: 24),
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            const Text('Subtotal', style: TextStyle(color: Colors.grey)),
                            Text('₹$originalAmount', style: TextStyle(fontWeight: FontWeight.w600, color: Theme.of(context).colorScheme.onSurface)),
                          ],
                        ),
                        if (_discountAmount > 0) ...[
                          const SizedBox(height: 8),
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Text('Discount ($_appliedCoupon)', style: const TextStyle(color: Colors.green)),
                              Text('-₹${_discountAmount.toStringAsFixed(2)}', style: const TextStyle(fontWeight: FontWeight.w600, color: Colors.green)),
                            ],
                          ),
                        ],
                        if (_useCoins && coinDiscount > 0) ...[
                          const SizedBox(height: 8),
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              const Text('Coins Applied', style: TextStyle(color: Colors.amber)),
                              Text('-₹${coinDiscount.toStringAsFixed(2)}', style: const TextStyle(fontWeight: FontWeight.w600, color: Colors.amber)),
                            ],
                          ),
                        ],
                        const SizedBox(height: 8),
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            const Text('Taxes & Fees', style: TextStyle(color: Colors.grey)),
                            Text('₹0.00', style: TextStyle(fontWeight: FontWeight.w600, color: Theme.of(context).colorScheme.onSurface)),
                          ],
                        ),
                        const Divider(height: 24),
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Text('Total Amount', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16, color: Theme.of(context).colorScheme.onSurface)),
                            Text('₹$amount', style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 20, color: AppTheme.primaryBlue)),
                          ],
                        ),
                      ],
                    ),
                  ),

                  // Coupon Section
                  Container(
                    margin: const EdgeInsets.only(top: 16),
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: Theme.of(context).colorScheme.surface,
                      borderRadius: BorderRadius.circular(16),
                      border: Border.all(color: _appliedCoupon != null ? Colors.green : (Theme.of(context).dividerTheme.color ?? const Color(0xFFE5E7EB))),
                      boxShadow: _appliedCoupon != null ? [BoxShadow(color: Colors.green.withValues(alpha: 0.1), blurRadius: 8, spreadRadius: 1)] : [],
                    ),
                    child: _appliedCoupon != null 
                        ? Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Row(
                                children: [
                                  const Icon(CupertinoIcons.checkmark_seal_fill, color: Colors.green, size: 20),
                                  const SizedBox(width: 8),
                                  const Text('Coupon Applied', style: TextStyle(fontWeight: FontWeight.bold, color: Colors.green)),
                                  const Spacer(),
                                  InkWell(
                                    onTap: () {
                                      setState(() {
                                        _appliedCoupon = null;
                                        _discountAmount = 0.0;
                                        _discountPercentage = 0;
                                        _couponController.clear();
                                      });
                                    },
                                    child: const Text('Remove', style: TextStyle(color: Colors.red, fontSize: 12, fontWeight: FontWeight.bold)),
                                  ),
                                ],
                              ),
                              const SizedBox(height: 12),
                              Container(
                                padding: const EdgeInsets.all(12),
                                decoration: BoxDecoration(
                                  color: Colors.green.withValues(alpha: 0.05),
                                  borderRadius: BorderRadius.circular(12),
                                  border: Border.all(color: Colors.green.withValues(alpha: 0.2)),
                                ),
                                child: Row(
                                  children: [
                                    Expanded(
                                      child: Column(
                                        crossAxisAlignment: CrossAxisAlignment.start,
                                        children: [
                                          Text('Code: $_appliedCoupon', style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14, color: Colors.green)),
                                          const SizedBox(height: 4),
                                          Text('You saved ₹${_discountAmount.toStringAsFixed(0)} ($_discountPercentage% Off!)', style: const TextStyle(fontSize: 12, color: Colors.green)),
                                        ],
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ],
                          )
                        : Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              const Text('Apply Coupon Code', style: TextStyle(fontWeight: FontWeight.bold)),
                              const SizedBox(height: 8),
                              Row(
                                children: [
                                  Expanded(
                                    child: TextField(
                                      controller: _couponController,
                                      style: TextStyle(color: Theme.of(context).colorScheme.onSurface),
                                      decoration: InputDecoration(
                                        hintText: 'Enter code',
                                        hintStyle: const TextStyle(color: Colors.grey),
                                        errorText: _couponError,
                                        isDense: true,
                                        border: OutlineInputBorder(
                                          borderRadius: BorderRadius.circular(8),
                                        ),
                                        filled: true,
                                        fillColor: Theme.of(context).brightness == Brightness.dark ? const Color(0xFF2C2C2C) : const Color(0xFFF8F9FA),
                                      ),
                                    ),
                                  ),
                                  const SizedBox(width: 12),
                                  ElevatedButton(
                                    onPressed: _isApplyingCoupon ? null : () => _applyCoupon(originalAmount),
                                    style: ElevatedButton.styleFrom(
                                      backgroundColor: AppTheme.primaryBlue,
                                      foregroundColor: Colors.white,
                                      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 14),
                                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                                    ),
                                    child: _isApplyingCoupon 
                                        ? const SizedBox(width: 20, height: 20, child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2)) 
                                        : const Text('Apply', style: TextStyle(fontWeight: FontWeight.bold)),
                                  ),
                                ],
                              ),
                            ],
                          ),
                  ),

                  // Coins Section
                  if (_userCoins > 0)
                    Container(
                      margin: const EdgeInsets.only(top: 16),
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        color: Theme.of(context).colorScheme.surface,
                        borderRadius: BorderRadius.circular(16),
                        border: Border.all(color: _useCoins ? Colors.amber : (Theme.of(context).dividerTheme.color ?? const Color(0xFFE5E7EB))),
                        boxShadow: _useCoins ? [BoxShadow(color: Colors.amber.withValues(alpha: 0.1), blurRadius: 8, spreadRadius: 1)] : [],
                      ),
                      child: Row(
                        children: [
                          Container(
                            padding: const EdgeInsets.all(8),
                            decoration: BoxDecoration(
                              color: Colors.amber.withValues(alpha: 0.1),
                              shape: BoxShape.circle,
                            ),
                            child: const Icon(CupertinoIcons.star_fill, color: Colors.amber, size: 20),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text('Use Coins Balance', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14, color: Theme.of(context).colorScheme.onSurface)),
                                const SizedBox(height: 4),
                                Text('$_userCoins coins available (Worth ₹${(_userCoins * 0.25).toStringAsFixed(2)})', style: const TextStyle(fontSize: 12, color: Colors.grey)),
                              ],
                            ),
                          ),
                          Switch(
                            value: _useCoins,
                            onChanged: (val) {
                              setState(() {
                                _useCoins = val;
                              });
                            },
                            activeThumbColor: Colors.amber,
                          ),
                        ],
                      ),
                    ),

                  const SizedBox(height: 28),

                  // Payment Options Title
                  Text(
                    'Select Payment Method',
                    style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16, color: Theme.of(context).colorScheme.onSurface),
                  ),
                  const SizedBox(height: 12),

                  // UPI Card
                  _buildPaymentMethodOption(
                    id: 'upi',
                    title: 'UPI (GPay / PhonePe / Paytm)',
                    subtitle: 'Pay instantly using secure virtual address',
                    icon: CupertinoIcons.phone_fill,
                    iconColor: Colors.green,
                  ),

                  const SizedBox(height: 12),

                  // Cards Option
                  _buildPaymentMethodOption(
                    id: 'card',
                    title: 'Credit / Debit Card',
                    subtitle: 'Visa, MasterCard, RuPay, Maestro',
                    icon: CupertinoIcons.creditcard_fill,
                    iconColor: Colors.blue,
                  ),

                  const SizedBox(height: 12),

                  // Net Banking Option
                  _buildPaymentMethodOption(
                    id: 'netbanking',
                    title: 'Net Banking',
                    subtitle: 'Secure direct portal connection to all major banks',
                    icon: CupertinoIcons.shield_fill,
                    iconColor: Colors.orange,
                  ),
                ],
              ),
            ),

            // Pay Button
            Padding(
              padding: const EdgeInsets.all(16.0),
              child: SizedBox(
                width: double.infinity,
                child: AppButton(
                  text: 'Complete Payment • ₹$amount',
                  onPressed: _handlePayment,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildPaymentMethodOption({
    required String id,
    required String title,
    required String subtitle,
    required IconData icon,
    required Color iconColor,
  }) {
    final isSelected = _selectedMethod == id;

    return GestureDetector(
      onTap: () {
        setState(() {
          _selectedMethod = id;
        });
      },
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: Theme.of(context).colorScheme.surface,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: isSelected ? AppTheme.primaryBlue : (Theme.of(context).dividerTheme.color ?? const Color(0xFFE5E7EB)), width: isSelected ? 1.5 : 0.5),
        ),
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(
                color: iconColor.withValues(alpha: 0.1),
                shape: BoxShape.circle,
              ),
              child: Icon(icon, color: iconColor, size: 20),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(title, style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14, color: Theme.of(context).colorScheme.onSurface)),
                  const SizedBox(height: 4),
                  Text(subtitle, style: const TextStyle(fontSize: 11, color: Colors.grey)),
                ],
              ),
            ),
            Radio<String>(
              value: id,
              groupValue: _selectedMethod,
              activeColor: AppTheme.primaryBlue,
              onChanged: (val) {
                setState(() {
                  _selectedMethod = val!;
                });
              },
            ),
          ],
        ),
      ),
    );
  }
}
