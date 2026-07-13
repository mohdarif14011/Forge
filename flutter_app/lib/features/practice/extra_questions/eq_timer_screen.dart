import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../../../widgets/animated_back_button.dart';
import '../../../widgets/app_button.dart';
import '../../../widgets/section_title.dart';
import '../../../core/theme.dart';

class EqTimerScreen extends StatefulWidget {
  final Map<String, dynamic> params;
  const EqTimerScreen({super.key, this.params = const {}});

  @override
  State<EqTimerScreen> createState() => _EqTimerScreenState();
}

class _EqTimerScreenState extends State<EqTimerScreen> {
  int _selectedMinutes = 60;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
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
                      child: SectionTitle(title: 'Set Timer'),
                    ),
                  ),
                  const SizedBox(width: 40),
                ],
              ),
            ),
            Expanded(
              child: Padding(
                padding: const EdgeInsets.all(24.0),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    const Text(
                      'Recommended Time: 60 mins',
                      style: TextStyle(color: Colors.grey, fontWeight: FontWeight.w500),
                    ),
                    const SizedBox(height: 32),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        IconButton(
                          onPressed: () {
                            if (_selectedMinutes > 15) {
                              setState(() {
                                _selectedMinutes -= 15;
                              });
                            }
                          },
                          icon: const Icon(Icons.remove_circle_outline, color: AppTheme.primaryBlue, size: 32),
                        ),
                        const SizedBox(width: 24),
                        Text(
                          '$_selectedMinutes',
                          style: TextStyle(fontSize: 48, fontWeight: FontWeight.bold, color: Theme.of(context).colorScheme.onSurface),
                        ),
                        const SizedBox(width: 8),
                        const Text('mins', style: TextStyle(color: Colors.grey)),
                        const SizedBox(width: 16),
                        IconButton(
                          onPressed: () {
                            setState(() {
                              _selectedMinutes += 15;
                            });
                          },
                          icon: const Icon(Icons.add_circle_outline, color: AppTheme.primaryBlue, size: 32),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ),
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                border: Border(top: BorderSide(color: Theme.of(context).dividerTheme.color ?? const Color(0xFFE5E7EB), width: 0.5)),
              ),
              child: SizedBox(
                width: double.infinity,
                child: AppButton(
                  text: 'Start Practice',
                  onPressed: () async {
                    final type = widget.params['type'] ?? 'extra';
                    final isCustom = widget.params['isCustom'] == true;
                    
                    final user = FirebaseAuth.instance.currentUser;
                    if (user != null) {
                      String docId = '${user.uid}_$type';
                      if (isCustom) docId = '${user.uid}_custom';
                      
                      final snapshot = await FirebaseFirestore.instance.collection('in_progress_tests').doc(docId).get();
                      
                      if (snapshot.exists) {
                        // Ask user if they want to resume
                        if (!mounted) return;
                        final bool? resume = await showDialog<bool>(
                          context: context,
                          builder: (context) => AlertDialog(
                            backgroundColor: Theme.of(context).scaffoldBackgroundColor,
                            title: Text('Resume Practice?', style: TextStyle(color: Theme.of(context).colorScheme.onSurface)),
                            content: Text('You have an incomplete test. Do you want to resume it or start a new one?', style: TextStyle(color: Theme.of(context).colorScheme.onSurface)),
                            actions: [
                              TextButton(
                                onPressed: () => Navigator.pop(context, false), // Start new
                                child: const Text('Start New', style: TextStyle(color: Colors.red)),
                              ),
                              TextButton(
                                onPressed: () => Navigator.pop(context, true), // Resume
                                child: const Text('Resume', style: TextStyle(color: Colors.blue)),
                              ),
                            ],
                          ),
                        );
                        
                        if (resume == true) {
                          final data = snapshot.data()!;
                          final extra = {
                            ...(data['params'] as Map? ?? {}).cast<String, dynamic>(),
                            'selectedOptions': data['selectedOptions'],
                            'timeSpentSeconds': data['timeSpentSeconds'],
                            'totalTimeSeconds': data['totalTimeSeconds'],
                          };
                          
                          // delete it so it's not repeatedly resumed
                          await FirebaseFirestore.instance.collection('in_progress_tests').doc(docId).delete();
                          
                          if (mounted) context.push('/test/active', extra: extra);
                          return;
                        } else if (resume == false) {
                          // Start new, delete the old one
                          await FirebaseFirestore.instance.collection('in_progress_tests').doc(docId).delete();
                        } else {
                          // Cancelled
                          return;
                        }
                      }
                    }
                    
                    if (mounted) {
                      final extra = {...widget.params, 'totalTime': _selectedMinutes * 60, 'type': type};
                      context.push('/test/active', extra: extra);
                    }
                  },
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
