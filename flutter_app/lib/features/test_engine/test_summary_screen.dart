import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../../widgets/app_button.dart';
import '../../widgets/section_title.dart';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

class TestSummaryScreen extends StatefulWidget {
  final Map<String, dynamic> params;
  const TestSummaryScreen({super.key, this.params = const {}});

  @override
  State<TestSummaryScreen> createState() => _TestSummaryScreenState();
}

class _TestSummaryScreenState extends State<TestSummaryScreen> {
  bool _isSubmitting = false;

  Future<void> _submitTest() async {
    setState(() => _isSubmitting = true);
    try {
      final user = FirebaseAuth.instance.currentUser;
      if (user != null) {
        // Calculate score logic to save
        final questions = (widget.params['questions'] as List<Map<String, dynamic>>?) ?? [];
        final selectedOptions = (widget.params['selectedOptions'] as Map<int, dynamic>?) ?? {};
        
        int totalQuestions = questions.length;
        int correct = 0;
        int incorrect = 0;
        int skipped = 0;
        int score = 0;
        int maxScore = 0;

        for (int i = 0; i < totalQuestions; i++) {
          final q = questions[i];
          final marks = (q['marks'] as num?)?.toInt() ?? 4;
          final negMarks = (q['negativeMarks'] as num?)?.toInt() ?? -1;
          maxScore += marks;
          final selected = selectedOptions[i];
          
          if (selected == null) {
            skipped++;
          } else {
            final options = (q['options'] as List<dynamic>?)?.cast<String>() ?? [];
            String selectedString = (selected is int && options.length > selected) ? options[selected] : '';
            bool isCorrect = false;
            
            if (q['isInteger'] == true || options.isEmpty) {
              if (q['correctAnswer'] != null && selected != null) {
                isCorrect = num.tryParse(selected.toString()) == num.tryParse(q['correctAnswer'].toString());
              }
            } else if (q['correctAnswer'] is num) {
              isCorrect = (q['correctAnswer'] as num).toInt() == selected;
            } else {
              isCorrect = q['correctAnswer'].toString().trim() == selectedString.trim();
            }

            if (isCorrect) {
              correct++;
              score += marks;
            } else {
              incorrect++;
              score += negMarks;
            }
          }
        }
        
        String userName = user.displayName ?? 'Student';
        try {
          final userDoc = await FirebaseFirestore.instance.collection('users').doc(user.uid).get();
          if (userDoc.exists) {
            userName = userDoc.data()?['name'] ?? userDoc.data()?['displayName'] ?? userName;
          }
        } catch (e) {
          debugPrint('Error fetching user name: $e');
        }

        await FirebaseFirestore.instance.collection('test_results').add({
          'userId': user.uid,
          'userName': userName,
          'examId': widget.params['examId'],
          'examName': widget.params['exam']?['name'] ?? widget.params['examName'] ?? 'Unknown Exam',
          'year': widget.params['year'] ?? 'Unknown Year',
          'date': widget.params['date'] ?? 'Unknown Date',
          'shift': widget.params['shift'] ?? 'Unknown Shift',
          'type': widget.params['type'] ?? 'pyq',
          'score': score,
          'maxScore': maxScore,
          'correct': correct,
          'incorrect': incorrect,
          'skipped': skipped,
          'timeSpent': widget.params['timeSpent'] ?? 0,
          'totalTime': widget.params['totalTime'] ?? 180 * 60,
          'testSeriesId': widget.params['test']?['id'] ?? widget.params['testSeriesId'],
          'testName': widget.params['test']?['name'] ?? widget.params['testName'],
          'isCustom': widget.params['isCustom'] ?? false,
          'timestamp': FieldValue.serverTimestamp(),
        });
      }
    } catch (e) {
      debugPrint('Error saving test result: $e');
    }
    
    if (mounted) {
      setState(() => _isSubmitting = false);
      context.push('/test/result', extra: widget.params);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SafeArea(
        child: Column(
          children: [
            const Padding(
              padding: EdgeInsets.all(16.0),
              child: SectionTitle(title: 'Test Summary'),
            ),
            Expanded(
              child: Builder(builder: (context) {
                final questions = (widget.params['questions'] as List<Map<String, dynamic>>?) ?? [];
                final selectedOptions = (widget.params['selectedOptions'] as Map<int, dynamic>?) ?? {};
                
                int total = questions.length;
                int answered = selectedOptions.values.where((v) => v != null).length;
                int notAnswered = total - answered;

                return ListView(
                  padding: const EdgeInsets.all(16.0),
                  children: [
                    _buildSummaryRow(context, 'Total Questions', total.toString(), Colors.grey),
                    _buildSummaryRow(context, 'Answered', answered.toString(), Colors.green),
                    _buildSummaryRow(context, 'Not Answered', notAnswered.toString(), Colors.red),
                  ],
                );
              }),
            ),
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                border: Border(top: BorderSide(color: Theme.of(context).dividerTheme.color ?? const Color(0xFFE5E7EB), width: 0.5)),
              ),
              child: Row(
                children: [
                  Expanded(
                    child: AppButton(
                      text: 'Resume',
                      type: AppButtonType.outlined,
                      onPressed: () => context.pop(),
                    ),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: _isSubmitting 
                      ? const Center(child: CircularProgressIndicator())
                      : AppButton(
                          text: 'Submit Test',
                          onPressed: _submitTest,
                        ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSummaryRow(BuildContext context, String title, String count, Color color) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.surface,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: Theme.of(context).dividerTheme.color ?? const Color(0xFFE5E7EB), width: 0.5),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Row(
            children: [
              Container(
                width: 16,
                height: 16,
                decoration: BoxDecoration(
                  color: color.withValues(alpha: 0.2),
                  border: Border.all(color: color, width: 1),
                  borderRadius: BorderRadius.circular(4),
                ),
              ),
              const SizedBox(width: 12),
              Text(title, style: TextStyle(fontWeight: FontWeight.w500, color: Theme.of(context).colorScheme.onSurface)),
            ],
          ),
          Text(count, style: TextStyle(fontWeight: FontWeight.w600, color: Theme.of(context).colorScheme.onSurface)),
        ],
      ),
    );
  }
}
