import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../../../widgets/animated_back_button.dart';
import '../../../widgets/section_title.dart';
import '../../../core/services/firebase_service.dart';

import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../../../widgets/app_button.dart';

class CtExamScreen extends StatefulWidget {
  final Map<String, dynamic> params;
  const CtExamScreen({super.key, required this.params});

  @override
  State<CtExamScreen> createState() => _CtExamScreenState();
}

class _CtExamScreenState extends State<CtExamScreen> {
  List<Map<String, dynamic>> _exams = [];
  List<Map<String, dynamic>> _filteredExams = [];
  bool _isLoading = true;
  bool _noExamsSelected = false;
  String _searchQuery = '';

  @override
  void initState() {
    super.initState();
    _loadExams();
  }

  Future<void> _loadExams() async {
    try {
      final user = FirebaseAuth.instance.currentUser;
      if (user == null) {
        setState(() => _isLoading = false);
        return;
      }

      final userDoc = await FirebaseFirestore.instance.collection('users').doc(user.uid).get();
      final userData = userDoc.data() ?? {};
      final List<dynamic> selectedExams = userData['selectedExams'] as List<dynamic>? ?? [];

      if (selectedExams.isEmpty) {
        setState(() {
          _exams = [];
          _filteredExams = [];
          _noExamsSelected = true;
          _isLoading = false;
        });
        return;
      }

      final exams = await firebaseService.getExams();
      final filtered = exams.where((exam) => selectedExams.contains(exam['id'])).toList();

      setState(() {
        _exams = filtered;
        _filteredExams = filtered;
        _noExamsSelected = false;
        _isLoading = false;
      });
    } catch (e) {
      setState(() {
        _isLoading = false;
      });
    }
  }

  void _filterSearch(String query) {
    setState(() {
      _searchQuery = query;
      _filteredExams = _exams
          .where((exam) => (exam['name'] ?? '')
              .toString()
              .toLowerCase()
              .contains(query.toLowerCase()))
          .toList();
    });
  }

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
                      child: SectionTitle(title: 'Custom Test'),
                    ),
                  ),
                  const SizedBox(width: 40),
                ],
              ),
            ),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 8.0),
              child: TextField(
                onChanged: _filterSearch,
                decoration: InputDecoration(
                  hintText: 'Search exams...',
                  prefixIcon: const Icon(Icons.search, color: Colors.grey),
                  filled: true,
                  fillColor: Theme.of(context).colorScheme.surfaceContainerHighest,
                  contentPadding: const EdgeInsets.all(12),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(8),
                    borderSide: BorderSide(color: Theme.of(context).dividerTheme.color ?? const Color(0xFFE5E7EB), width: 0.5),
                  ),
                  enabledBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(8),
                    borderSide: BorderSide(color: Theme.of(context).dividerTheme.color ?? const Color(0xFFE5E7EB), width: 0.5),
                  ),
                ),
              ),
            ),
            Expanded(
              child: _isLoading 
                ? const Center(child: CircularProgressIndicator())
                : _noExamsSelected
                  ? Padding(
                      padding: const EdgeInsets.all(24.0),
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(Icons.school_outlined, size: 64, color: Colors.grey[400]),
                          const SizedBox(height: 16),
                          const Text(
                            "No exams selected",
                            style: TextStyle(fontWeight: FontWeight.bold, fontSize: 18),
                          ),
                          const SizedBox(height: 8),
                          const Text(
                            "Please select at least one exam in your profile settings to configure tests.",
                            textAlign: TextAlign.center,
                            style: TextStyle(color: Colors.grey),
                          ),
                          const SizedBox(height: 24),
                          AppButton(
                            text: "Go to Profile",
                            onPressed: () async {
                              await context.push('/manage-exams');
                              setState(() => _isLoading = true);
                              _loadExams();
                            },
                          ),
                        ],
                      ),
                    )
                  : _filteredExams.isEmpty 
                    ? const Center(child: Text("No exams found."))
                    : ListView.builder(
                        padding: const EdgeInsets.all(16.0),
                        itemCount: _filteredExams.length,
                        itemBuilder: (context, index) {
                          final exam = _filteredExams[index];
                          return _buildExamCard(context, exam);
                        },
                      ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildExamCard(BuildContext context, Map<String, dynamic> exam) {
    return GestureDetector(
      onTap: () {
        final type = widget.params['type'] ?? 'pyq';
        context.push('/ct/subjects', extra: {'exam': exam, 'type': type, 'isCustom': true});
      },
      child: Container(
        margin: const EdgeInsets.only(bottom: 12),
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: Theme.of(context).colorScheme.surface,
          borderRadius: BorderRadius.circular(8),
          border: Border.all(color: Theme.of(context).dividerTheme.color ?? const Color(0xFFE5E7EB), width: 0.5),
        ),
        child: Row(
          children: [
            Container(
              height: 40,
              width: 40,
              decoration: BoxDecoration(
                color: Theme.of(context).scaffoldBackgroundColor,
                shape: BoxShape.circle,
                border: Border.all(color: Theme.of(context).dividerTheme.color ?? const Color(0xFFE5E7EB), width: 0.5),
              ),
              child: Icon(Icons.school_outlined, size: 20, color: Theme.of(context).colorScheme.onSurface),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(exam['name'] ?? 'Unknown Exam', style: TextStyle(fontWeight: FontWeight.w500, color: Theme.of(context).colorScheme.onSurface)),
                ],
              ),
            ),
            Icon(Icons.chevron_right, color: Theme.of(context).dividerTheme.color ?? const Color(0xFFE5E7EB)),
          ],
        ),
      ),
    );
  }
}
