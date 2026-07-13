import 'dart:math';
import 'package:flutter/material.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/services.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../../core/theme.dart';
import '../../widgets/animated_back_button.dart';

class ReferralScreen extends StatefulWidget {
  const ReferralScreen({super.key});

  @override
  State<ReferralScreen> createState() => _ReferralScreenState();
}

class _ReferralScreenState extends State<ReferralScreen> {
  final TextEditingController _codeController = TextEditingController();
  bool _isLoading = true;
  String? _myReferralCode;
  int _myCoins = 0;
  bool _hasRedeemed = false;
  bool _isRedeeming = false;

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  Future<void> _loadData() async {
    try {
      final user = FirebaseAuth.instance.currentUser;
      if (user != null) {
        final doc = await FirebaseFirestore.instance.collection('users').doc(user.uid).get();
        if (doc.exists) {
          final data = doc.data()!;
          _myCoins = data['coins'] as int? ?? 0;
          _hasRedeemed = data['hasRedeemedReferral'] as bool? ?? false;
          _myReferralCode = data['referralCode'] as String?;

          if (_myReferralCode == null || _myReferralCode!.isEmpty) {
            _myReferralCode = _generateReferralCode(user.email ?? user.uid);
            await FirebaseFirestore.instance.collection('users').doc(user.uid).update({
              'referralCode': _myReferralCode,
            });
          }
        }
      }
    } catch (e) {
      debugPrint("Error loading referral data: $e");
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  String _generateReferralCode(String baseStr) {
    String clean = baseStr.replaceAll(RegExp(r'[^a-zA-Z0-9]'), '').toUpperCase();
    if (clean.length > 5) clean = clean.substring(0, 5);
    String randomDigits = (Random().nextInt(900) + 100).toString(); // 100-999
    return '$clean$randomDigits';
  }

  Future<void> _redeemCode() async {
    final code = _codeController.text.trim().toUpperCase();
    if (code.isEmpty) return;
    
    if (code == _myReferralCode) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text("You cannot use your own referral code!")));
      return;
    }

    setState(() => _isRedeeming = true);

    try {
      final user = FirebaseAuth.instance.currentUser;
      if (user == null) return;

      final snapshot = await FirebaseFirestore.instance.collection('users').where('referralCode', isEqualTo: code).get();
      if (snapshot.docs.isEmpty) {
        if (mounted) ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text("Invalid referral code.")));
        setState(() => _isRedeeming = false);
        return;
      }

      final referrerDoc = snapshot.docs.first;
      
      // Batch write to update both users
      final batch = FirebaseFirestore.instance.batch();
      
      // Update referrer
      batch.update(referrerDoc.reference, {
        'coins': FieldValue.increment(100),
      });

      // Update current user
      final myRef = FirebaseFirestore.instance.collection('users').doc(user.uid);
      batch.update(myRef, {
        'coins': FieldValue.increment(100),
        'hasRedeemedReferral': true,
      });

      await batch.commit();

      if (mounted) {
        setState(() {
          _myCoins += 100;
          _hasRedeemed = true;
          _isRedeeming = false;
        });
        showDialog(
          context: context,
          builder: (context) => AlertDialog(
            title: const Text('Success! 🎉'),
            content: const Text('You and your friend both received 100 coins!'),
            actions: [
              TextButton(onPressed: () => Navigator.pop(context), child: const Text('Awesome'))
            ],
          )
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text("Error redeeming code: $e")));
        setState(() => _isRedeeming = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Scaffold(
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      body: SafeArea(
        child: _isLoading 
            ? const Center(child: CircularProgressIndicator())
            : Column(
                children: [
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 12.0),
                    child: Row(
                      children: [
                        const AnimatedBackButton(),
                        Expanded(
                          child: Center(
                            child: Text(
                              'Refer & Earn',
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
                      padding: const EdgeInsets.all(24.0),
                      children: [
                        // Coins Display
                        Container(
                          padding: const EdgeInsets.all(20),
                          decoration: BoxDecoration(
                            gradient: const LinearGradient(colors: [Colors.amber, Colors.orange]),
                            borderRadius: BorderRadius.circular(20),
                            boxShadow: [BoxShadow(color: Colors.amber.withValues(alpha: 0.3), blurRadius: 10, offset: const Offset(0, 4))],
                          ),
                          child: Row(
                            children: [
                              Container(
                                padding: const EdgeInsets.all(12),
                                decoration: BoxDecoration(
                                  color: Colors.white.withValues(alpha: 0.2),
                                  shape: BoxShape.circle,
                                ),
                                child: const Icon(CupertinoIcons.star_circle_fill, color: Colors.white, size: 32),
                              ),
                              const SizedBox(width: 16),
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    const Text('Your Coin Balance', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
                                    const SizedBox(height: 4),
                                    Text('$_myCoins Coins', style: const TextStyle(color: Colors.white, fontSize: 28, fontWeight: FontWeight.w900)),
                                    Text('Worth ₹${(_myCoins * 0.25).toStringAsFixed(2)}', style: TextStyle(color: Colors.white.withValues(alpha: 0.9), fontSize: 12)),
                                  ],
                                ),
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(height: 32),
                        
                        // Invite Banner
                        Center(
                          child: Container(
                            width: 100,
                            height: 100,
                            decoration: BoxDecoration(
                              color: AppTheme.primaryBlue.withValues(alpha: 0.1),
                              shape: BoxShape.circle,
                            ),
                            child: const Icon(CupertinoIcons.gift_fill, color: AppTheme.primaryBlue, size: 48),
                          ),
                        ),
                        const SizedBox(height: 16),
                        Text(
                          'Invite Friends & Earn',
                          textAlign: TextAlign.center,
                          style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold, color: Theme.of(context).colorScheme.onSurface),
                        ),
                        const SizedBox(height: 8),
                        const Text(
                          'Share your code with friends. When they sign up and redeem it, you BOTH get 100 coins (₹25 value)!',
                          textAlign: TextAlign.center,
                          style: TextStyle(color: Colors.grey, height: 1.4),
                        ),
                        
                        const SizedBox(height: 32),
                        
                        // Your Code
                        Container(
                          padding: const EdgeInsets.all(20),
                          decoration: BoxDecoration(
                            color: Theme.of(context).colorScheme.surface,
                            borderRadius: BorderRadius.circular(16),
                            border: Border.all(color: Theme.of(context).dividerTheme.color ?? const Color(0xFFE5E7EB)),
                          ),
                          child: Column(
                            children: [
                              const Text('YOUR REFERRAL CODE', style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: Colors.grey, letterSpacing: 1)),
                              const SizedBox(height: 12),
                              Row(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  Text(
                                    _myReferralCode ?? '------',
                                    style: TextStyle(fontSize: 32, fontWeight: FontWeight.w900, color: Theme.of(context).colorScheme.onSurface, letterSpacing: 2),
                                  ),
                                  const SizedBox(width: 16),
                                  IconButton(
                                    icon: const Icon(Icons.copy, color: AppTheme.primaryBlue),
                                    onPressed: () {
                                      if (_myReferralCode != null) {
                                        Clipboard.setData(ClipboardData(text: _myReferralCode!));
                                        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Code copied to clipboard!')));
                                      }
                                    },
                                  ),
                                ],
                              ),
                            ],
                          ),
                        ),

                        const SizedBox(height: 32),
                        const Divider(),
                        const SizedBox(height: 24),
                        
                        // Redeem Code
                        Text(
                          'Redeem a Code',
                          style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Theme.of(context).colorScheme.onSurface),
                        ),
                        const SizedBox(height: 16),
                        if (_hasRedeemed)
                          Container(
                            padding: const EdgeInsets.all(16),
                            decoration: BoxDecoration(
                              color: Colors.green.withValues(alpha: 0.1),
                              borderRadius: BorderRadius.circular(12),
                            ),
                            child: const Row(
                              children: [
                                Icon(Icons.check_circle, color: Colors.green),
                                SizedBox(width: 12),
                                Expanded(child: Text('You have already redeemed a referral code.', style: TextStyle(color: Colors.green, fontWeight: FontWeight.bold))),
                              ],
                            ),
                          )
                        else
                          Row(
                            children: [
                              Expanded(
                                child: TextField(
                                  controller: _codeController,
                                  textCapitalization: TextCapitalization.characters,
                                  style: TextStyle(color: Theme.of(context).colorScheme.onSurface),
                                  decoration: InputDecoration(
                                    hintText: 'Enter Friend\'s Code',
                                    hintStyle: const TextStyle(color: Colors.grey),
                                    filled: true,
                                    fillColor: Theme.of(context).colorScheme.surfaceContainerHighest,
                                    border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide.none),
                                  ),
                                ),
                              ),
                              const SizedBox(width: 12),
                              ElevatedButton(
                                onPressed: _isRedeeming ? null : _redeemCode,
                                style: ElevatedButton.styleFrom(
                                  backgroundColor: AppTheme.primaryBlue,
                                  foregroundColor: Colors.white,
                                  padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
                                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                                ),
                                child: _isRedeeming
                                    ? const SizedBox(width: 20, height: 20, child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2))
                                    : const Text('Redeem', style: TextStyle(fontWeight: FontWeight.bold)),
                              ),
                            ],
                          ),
                      ],
                    ),
                  ),
                ],
              ),
      ),
    );
  }
}
