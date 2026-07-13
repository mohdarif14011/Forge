import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:go_router/go_router.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:google_sign_in/google_sign_in.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../../core/theme.dart';
import '../../core/services/notification_service.dart';

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  bool _isLoading = false;

  Future<void> _signInWithGoogle() async {
    bool? accepted = await _showTermsAndConditions();
    if (accepted != true) return;

    setState(() {
      _isLoading = true;
    });
    try {
      UserCredential? userCredential;
      if (kIsWeb) {
        GoogleAuthProvider googleProvider = GoogleAuthProvider();
        userCredential = await FirebaseAuth.instance.signInWithPopup(googleProvider);
      } else {
        final GoogleSignInAccount? googleUser = await GoogleSignIn().signIn();
        if (googleUser == null) {
          setState(() {
            _isLoading = false;
          });
          return; // User canceled
        }
        final GoogleSignInAuthentication googleAuth = await googleUser.authentication;
        final AuthCredential credential = GoogleAuthProvider.credential(
          accessToken: googleAuth.accessToken,
          idToken: googleAuth.idToken,
        );
        userCredential = await FirebaseAuth.instance.signInWithCredential(credential);
      }
      
      await _checkAndSetupUser(userCredential.user);

    } catch (e) {
      setState(() {
        _isLoading = false;
      });
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Failed to sign in with Google: $e')),
        );
      }
    }
  }

  Future<bool?> _showTermsAndConditions() {
    return showDialog<bool>(
      context: context,
      builder: (context) {
        return AlertDialog(
          backgroundColor: Theme.of(context).colorScheme.surface,
          title: Text('Terms & Conditions', style: TextStyle(fontWeight: FontWeight.bold, color: Theme.of(context).colorScheme.onSurface)),
          content: SingleChildScrollView(
            child: Text(
              'By proceeding, you agree to our Terms and Conditions and Privacy Policy. Please use the app responsibly and maintain community guidelines.',
              style: TextStyle(color: Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.87)),
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context, false),
              child: const Text('Decline', style: TextStyle(color: Colors.grey)),
            ),
            ElevatedButton(
              onPressed: () => Navigator.pop(context, true),
              style: ElevatedButton.styleFrom(
                backgroundColor: AppTheme.primaryBlue,
                foregroundColor: Colors.white,
              ),
              child: const Text('Accept'),
            ),
          ],
        );
      },
    );
  }

  Future<void> _checkAndSetupUser(User? user) async {
    if (user == null) {
       setState(() { _isLoading = false; });
       return;
    }
    
    try {
      final userRef = FirebaseFirestore.instance.collection('users').doc(user.uid);
      final doc = await userRef.get();
      
      if (!doc.exists || (doc.data()?['exam'] == 'N/A') || (doc.data()?['exam'] == null)) {
        setState(() { _isLoading = false; });
        final result = await _showOnboardingBottomSheet();
        if (result == null) {
          await FirebaseAuth.instance.signOut();
          return;
        }
        
        setState(() { _isLoading = true; });
        await _saveUserToFirestore(user, exam: result['exam'], year: result['year']);
        notificationService.showWelcomeNotification(userName: user.displayName ?? 'Learner');
        if (mounted) context.go('/home');
      } else {
        await _saveUserToFirestore(user);
        notificationService.showWelcomeNotification(userName: user.displayName ?? 'Learner');
        if (mounted) context.go('/home');
      }
    } catch (e) {
      debugPrint('Error: $e');
      setState(() { _isLoading = false; });
    }
  }

  Future<Map<String, String>?> _showOnboardingBottomSheet() {
    return showModalBottomSheet<Map<String, String>>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      useRootNavigator: true,
      isDismissible: false,
      enableDrag: false,
      builder: (context) {
        return const OnboardingBottomSheet();
      },
    );
  }

  Future<void> _saveUserToFirestore(User? user, {String? exam, String? year}) async {
    if (user == null) return;
    try {
      final userRef = FirebaseFirestore.instance.collection('users').doc(user.uid);
      final doc = await userRef.get();
      if (!doc.exists) {
        await userRef.set({
          'name': user.displayName,
          'email': user.email,
          'status': 'Active',
          'exam': exam ?? 'N/A',
          'year': year ?? 'N/A',
          'createdAt': FieldValue.serverTimestamp(),
          'lastLogin': FieldValue.serverTimestamp(),
        });
      } else {
        final updates = <String, dynamic>{
          'lastLogin': FieldValue.serverTimestamp(),
          'status': 'Active',
        };
        if (exam != null) updates['exam'] = exam;
        if (year != null) updates['year'] = year;
        await userRef.update(updates);
      }
    } catch (e) {
      debugPrint('Error saving user to Firestore: $e');
    }
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    
    return AnnotatedRegion<SystemUiOverlayStyle>(
      value: isDark ? SystemUiOverlayStyle.light : SystemUiOverlayStyle.dark,
      child: Scaffold(
        backgroundColor: Theme.of(context).scaffoldBackgroundColor,
        body: SafeArea(
        bottom: false,
        child: Column(
          children: [
            // Top Section (Logo/Illustration Placeholder)
            Expanded(
              flex: 5,
              child: Center(
                child: Padding(
                  padding: const EdgeInsets.all(40.0),
                  child: ClipOval(
                    child: Image.network(
                      'https://res.cloudinary.com/dsnatrse2/image/upload/v1783518589/Logo_zmghow.png',
                      height: 180,
                      width: 180,
                      fit: BoxFit.cover,
                    ),
                  ),
                ),
              ),
            ),
            
            // Bottom Section (Content)
            Expanded(
              flex: 4,
              child: Container(
                width: double.infinity,
                decoration: BoxDecoration(
                  color: Theme.of(context).colorScheme.surface,
                  borderRadius: const BorderRadius.only(
                    topLeft: Radius.circular(32),
                    topRight: Radius.circular(32),
                  ),
                ),
                padding: const EdgeInsets.fromLTRB(28, 40, 28, 32),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    RichText(
                      text: TextSpan(
                        style: TextStyle(
                          fontSize: 26,
                          fontWeight: FontWeight.w800,
                          color: Theme.of(context).colorScheme.onSurface,
                          height: 1.25,
                        ),
                        children: const [
                          TextSpan(text: 'Master Concepts, Practice.\nPrepare For '),
                          TextSpan(
                            text: 'Ultimate Success!',
                            style: TextStyle(color: Color(0xFFFF5722)),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 16),
                    Text(
                      'Get comprehensive notes, detailed PYQs, and mock tests.\nJoin now to boost your preparation!',
                      style: TextStyle(
                        fontSize: 14,
                        color: Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.7),
                        height: 1.5,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                    const Spacer(),
                    Row(
                      children: [
                        Expanded(
                          child: GestureDetector(
                            onTap: _isLoading ? null : _signInWithGoogle,
                            child: Container(
                              height: 60,
                              decoration: BoxDecoration(
                                color: Theme.of(context).colorScheme.surface,
                                borderRadius: BorderRadius.circular(30),
                                border: Border.all(color: Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.12), width: 1.5),
                              ),
                              child: _isLoading 
                                ? Center(child: CircularProgressIndicator(color: Theme.of(context).colorScheme.onSurface, strokeWidth: 2))
                                : Row(
                                    mainAxisAlignment: MainAxisAlignment.center,
                                    children: [
                                      Text('G', style: TextStyle(fontSize: 24, fontWeight: FontWeight.w900, color: Theme.of(context).colorScheme.onSurface)),
                                      const SizedBox(width: 12),
                                      Text(
                                        'Continue With Google',
                                        style: TextStyle(
                                          fontSize: 16,
                                          fontWeight: FontWeight.w700,
                                          color: Theme.of(context).colorScheme.onSurface,
                                        ),
                                      ),
                                    ],
                                  ),
                            ),
                          ),
                        ),
                        const SizedBox(width: 16),
                        GestureDetector(
                          onTap: _isLoading ? null : _signInWithGoogle,
                          child: Container(
                            height: 60,
                            width: 60,
                            decoration: BoxDecoration(
                              color: Theme.of(context).colorScheme.onSurface,
                              shape: BoxShape.circle,
                            ),
                            child: Icon(Icons.chevron_right, color: Theme.of(context).colorScheme.surface, size: 32),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 16),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    ),
    );
  }
}

class OnboardingBottomSheet extends StatefulWidget {
  const OnboardingBottomSheet({super.key});

  @override
  State<OnboardingBottomSheet> createState() => _OnboardingBottomSheetState();
}

class _OnboardingBottomSheetState extends State<OnboardingBottomSheet> {
  String? _selectedExam;
  String? _selectedYear;
  bool _isLoading = true;
  List<String> _exams = [];
  final List<String> _years = ['2024', '2025', '2026', '2027'];

  @override
  void initState() {
    super.initState();
    _fetchExams();
  }

  Future<void> _fetchExams() async {
    try {
      final snap = await FirebaseFirestore.instance.collection('exams').get();
      if (mounted) {
        setState(() {
          _exams = snap.docs.map((doc) {
            final data = doc.data();
            return (data['name']?.toString() ?? doc.id);
          }).toList();
          _isLoading = false;
        });
      }
    } catch (e) {
      debugPrint("Error fetching exams: $e");
      if (mounted) {
        setState(() {
          _exams = ['JEE', 'NEET', 'UPSC']; // fallback
          _isLoading = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      height: MediaQuery.of(context).size.height * 0.7,
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.surface,
        borderRadius: const BorderRadius.vertical(top: Radius.circular(32)),
      ),
      padding: const EdgeInsets.all(24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('Complete Profile', style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold, color: Theme.of(context).colorScheme.onSurface)),
          const SizedBox(height: 8),
          Text('Select your target exam and year.', style: TextStyle(color: Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.6))),
          const SizedBox(height: 24),
          Text('Target Exam', style: TextStyle(fontWeight: FontWeight.w600, color: Theme.of(context).colorScheme.onSurface)),
          const SizedBox(height: 12),
          _isLoading 
            ? const Center(child: CircularProgressIndicator())
            : Wrap(
                spacing: 8,
                runSpacing: 8,
                children: _exams.map((exam) {
                  final isSelected = _selectedExam == exam;
                  return GestureDetector(
                    onTap: () => setState(() => _selectedExam = exam),
                    child: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                      decoration: BoxDecoration(
                        color: isSelected ? AppTheme.primaryBlue : Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.05),
                        borderRadius: BorderRadius.circular(20),
                        border: Border.all(color: isSelected ? AppTheme.primaryBlue : Colors.transparent),
                      ),
                      child: Text(
                        exam, 
                        style: TextStyle(
                          color: isSelected ? Colors.white : Theme.of(context).colorScheme.onSurface,
                          fontWeight: isSelected ? FontWeight.bold : FontWeight.normal
                        )
                      ),
                    ),
                  );
                }).toList(),
              ),
          const SizedBox(height: 24),
          Text('Target Year', style: TextStyle(fontWeight: FontWeight.w600, color: Theme.of(context).colorScheme.onSurface)),
          const SizedBox(height: 12),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: _years.map((year) {
              final isSelected = _selectedYear == year;
              return GestureDetector(
                onTap: () => setState(() => _selectedYear = year),
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                  decoration: BoxDecoration(
                    color: isSelected ? AppTheme.primaryBlue : Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.05),
                    borderRadius: BorderRadius.circular(20),
                    border: Border.all(color: isSelected ? AppTheme.primaryBlue : Colors.transparent),
                  ),
                  child: Text(
                    year, 
                    style: TextStyle(
                      color: isSelected ? Colors.white : Theme.of(context).colorScheme.onSurface,
                      fontWeight: isSelected ? FontWeight.bold : FontWeight.normal
                    )
                  ),
                ),
              );
            }).toList(),
          ),
          const Spacer(),
          SizedBox(
            width: double.infinity,
            height: 56,
            child: ElevatedButton(
              onPressed: (_selectedExam != null && _selectedYear != null) ? () {
                Navigator.pop(context, {'exam': _selectedExam!, 'year': _selectedYear!});
              } : null,
              style: ElevatedButton.styleFrom(
                backgroundColor: AppTheme.primaryBlue,
                foregroundColor: Colors.white,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(28)),
              ),
              child: const Text('Continue', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
            ),
          ),
          const SizedBox(height: 16),
        ],
      ),
    );
  }
}
