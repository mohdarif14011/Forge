import 'package:flutter/material.dart';
import 'package:flutter/cupertino.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:go_router/go_router.dart';
import '../../core/services/firebase_service.dart';
import '../../widgets/animated_back_button.dart';
import '../../widgets/section_title.dart';
import '../../widgets/app_button.dart';
import '../../core/theme.dart';

class ManageExamsScreen extends StatefulWidget {
  const ManageExamsScreen({super.key});

  @override
  State<ManageExamsScreen> createState() => _ManageExamsScreenState();
}

class _ManageExamsScreenState extends State<ManageExamsScreen> {
  final User? _currentUser = FirebaseAuth.instance.currentUser;
  
  List<Map<String, dynamic>> _allExams = [];
  Set<String> _selectedExamIds = {};
  bool _isLoading = true;
  String _searchQuery = '';

  @override
  void initState() {
    super.initState();
    _loadExamsAndSelection();
  }

  Future<void> _loadExamsAndSelection() async {
    final user = _currentUser;
    if (user == null) return;
    try {
      final exams = await firebaseService.getExams();
      final userDoc = await FirebaseFirestore.instance.collection('users').doc(user.uid).get();
      
      final userData = userDoc.data() ?? {};
      final List<dynamic> selected = userData['selectedExams'] as List<dynamic>? ?? [];
      
      setState(() {
        _allExams = exams;
        _selectedExamIds = selected.map((e) => e.toString()).toSet();
        _isLoading = false;
      });
    } catch (e) {
      debugPrint("Error loading exams: $e");
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  Future<void> _saveSelection() async {
    final user = _currentUser;
    if (user == null) return;
    if (_selectedExamIds.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('User should have to select at least one exam.'),
          backgroundColor: Colors.redAccent,
        ),
      );
      return;
    }

    setState(() => _isLoading = true);

    try {
      // Find the names of selected exams to update examNames text field in profile
      List<String> selectedNames = [];
      for (var exam in _allExams) {
        if (_selectedExamIds.contains(exam['id'])) {
          selectedNames.add(exam['name'] ?? '');
        }
      }
      String examNamesStr = selectedNames.join(', ');

      await FirebaseFirestore.instance.collection('users').doc(user.uid).set({
        'selectedExams': _selectedExamIds.toList(),
        'examNames': examNamesStr,
      }, SetOptions(merge: true));

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Exams saved successfully!'),
            backgroundColor: Colors.green,
          ),
        );
        context.pop();
      }
    } catch (e) {
      debugPrint("Error saving exams: $e");
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error saving: $e')),
        );
        setState(() => _isLoading = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final filteredExams = _allExams.where((exam) {
      final name = (exam['name'] ?? '').toString().toLowerCase();
      return name.contains(_searchQuery.toLowerCase());
    }).toList();

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
                      child: SectionTitle(title: 'Manage Exams'),
                    ),
                  ),
                  const SizedBox(width: 40),
                ],
              ),
            ),
            
            // Search field
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 8.0),
              child: TextField(
                decoration: InputDecoration(
                  hintText: 'Search exams...',
                  prefixIcon: const Icon(CupertinoIcons.search),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                  contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                ),
                onChanged: (val) {
                  setState(() {
                    _searchQuery = val;
                  });
                },
              ),
            ),

            Expanded(
              child: _isLoading
                  ? const Center(child: CircularProgressIndicator())
                  : filteredExams.isEmpty
                      ? const Center(child: Text("No exams found."))
                      : ListView.builder(
                          padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 8.0),
                          itemCount: filteredExams.length,
                          itemBuilder: (context, index) {
                            final exam = filteredExams[index];
                            final examId = exam['id'] as String;
                            final isSelected = _selectedExamIds.contains(examId);

                            return Card(
                              margin: const EdgeInsets.only(bottom: 12),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(12),
                              ),
                              child: CheckboxListTile(
                                activeColor: AppTheme.primaryBlue,
                                title: Text(
                                  exam['name'] ?? 'Unknown Exam',
                                  style: const TextStyle(fontWeight: FontWeight.bold),
                                ),
                                subtitle: exam['fullName'] != null ? Text(exam['fullName']) : null,
                                value: isSelected,
                                onChanged: (bool? val) {
                                  setState(() {
                                    if (val == true) {
                                      _selectedExamIds.add(examId);
                                    } else {
                                      _selectedExamIds.remove(examId);
                                    }
                                  });
                                },
                              ),
                            );
                          },
                        ),
            ),

            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                border: Border(top: BorderSide(color: Theme.of(context).dividerTheme.color ?? const Color(0xFFE5E7EB), width: 0.5)),
              ),
              child: AppButton(
                text: 'Save Selection',
                onPressed: () {
                  if (!_isLoading) {
                    _saveSelection();
                  }
                },
              ),
            ),
          ],
        ),
      ),
    );
  }
}
