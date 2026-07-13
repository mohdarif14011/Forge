import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../../../widgets/animated_back_button.dart';
import '../../../widgets/section_title.dart';
import '../../../core/theme.dart';
import 'package:firebase_auth/firebase_auth.dart';

class PyqYearScreen extends StatefulWidget {
  final Map<String, dynamic> params;
  const PyqYearScreen({super.key, this.params = const {}});

  @override
  State<PyqYearScreen> createState() => _PyqYearScreenState();
}

class _PyqYearScreenState extends State<PyqYearScreen> {
  List<String> _years = [];
  bool _isLoading = true;
  List<Map<String, dynamic>> _appearedTests = [];
  bool _isLoadingTests = true;

  @override
  void initState() {
    super.initState();
    _fetchYears();
    _loadAppearedTests();
  }

  Future<void> _loadAppearedTests() async {
    try {
      final user = FirebaseAuth.instance.currentUser;
      final examId = widget.params['examId'];
      
      if (user != null && examId != null) {
        final snapshot = await FirebaseFirestore.instance
            .collection('test_results')
            .where('userId', isEqualTo: user.uid)
            .where('examId', isEqualTo: examId)
            .where('type', isEqualTo: 'pyq')
            .get();
            
        if (mounted) {
          final tests = snapshot.docs.map((e) => {'id': e.id, ...e.data()}).toList();
          tests.sort((a, b) {
            final tA = a['timestamp'] as Timestamp?;
            final tB = b['timestamp'] as Timestamp?;
            if (tA == null && tB == null) return 0;
            if (tA == null) return 1;
            if (tB == null) return -1;
            return tB.compareTo(tA);
          });
          
          setState(() {
            _appearedTests = tests;
            _isLoadingTests = false;
          });
        }
      } else {
        if (mounted) setState(() => _isLoadingTests = false);
      }
    } catch (e) {
      debugPrint('Error loading tests: $e');
      if (mounted) setState(() => _isLoadingTests = false);
    }
  }

  Future<void> _fetchYears() async {
    final examId = widget.params['examId'];
    if (examId == null) {
      setState(() => _isLoading = false);
      return;
    }
    
    try {
      final snapshot = await FirebaseFirestore.instance
          .collection('questions')
          .where('type', isEqualTo: 'pyq')
          .where('examId', isEqualTo: examId)
          .get();
          
      final Set<String> uniqueYears = {};
      for (var doc in snapshot.docs) {
        final data = doc.data();
        if (data['year'] != null && data['year'].toString().isNotEmpty) {
          uniqueYears.add(data['year'].toString());
        }
      }
      
      final sortedYears = uniqueYears.toList()..sort((a, b) => b.compareTo(a));
      
      setState(() {
        _years = sortedYears;
        _isLoading = false;
      });
    } catch (e) {
      setState(() => _isLoading = false);
    }
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
                      child: SectionTitle(title: 'Select Year'),
                    ),
                  ),
                  const SizedBox(width: 40),
                ],
              ),
            ),
            Expanded(
              child: _isLoading 
                ? const Center(child: CircularProgressIndicator())
                : _years.isEmpty
                  ? const Center(child: Text("No PYQs found for this exam."))
                  : ListView.builder(
                      padding: const EdgeInsets.all(16.0),
                      itemCount: _years.length,
                      itemBuilder: (context, index) {
                        return GestureDetector(
                          onTap: () => context.push('/pyq/shifts', extra: {
                            ...widget.params,
                            'year': _years[index],
                          }),
                          child: Container(
                            margin: const EdgeInsets.only(bottom: 12),
                            padding: const EdgeInsets.all(16),
                            decoration: BoxDecoration(
                              color: Theme.of(context).colorScheme.surface,
                              borderRadius: BorderRadius.circular(8),
                              border: Border.all(color: Theme.of(context).dividerTheme.color ?? const Color(0xFFE5E7EB), width: 0.5),
                            ),
                            child: Center(
                              child: Text(
                                _years[index],
                                style: TextStyle(
                                  fontSize: 16,
                                  fontWeight: FontWeight.w500,
                                  color: Theme.of(context).colorScheme.onSurface,
                                ),
                              ),
                            ),
                          ),
                        );
                      },
                    ),
            ),
            
            // Appeared Tests Fixed Bottom Section
            if (_appearedTests.isNotEmpty || _isLoadingTests)
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: Theme.of(context).colorScheme.surface,
                  border: Border(top: BorderSide(color: Theme.of(context).dividerTheme.color ?? const Color(0xFFE5E7EB), width: 0.5)),
                  boxShadow: [
                    BoxShadow(color: Colors.black.withValues(alpha: 0.05), blurRadius: 10, offset: const Offset(0, -5))
                  ],
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const SectionTitle(title: 'Appeared Tests (This Exam)'),
                    const SizedBox(height: 12),
                    _isLoadingTests
                      ? const Center(child: CircularProgressIndicator())
                      : SingleChildScrollView(
                          scrollDirection: Axis.horizontal,
                          child: Row(
                            children: _appearedTests.map((test) => _buildAppearedTestCard(context, test)).toList(),
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

  Widget _buildAppearedTestCard(BuildContext context, Map<String, dynamic> test) {
    return GestureDetector(
      onTap: () {
        context.push('/test/result', extra: test);
      },
      child: Container(
        width: 280,
        margin: const EdgeInsets.only(right: 12),
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: Theme.of(context).colorScheme.surface,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: Theme.of(context).dividerTheme.color ?? const Color(0xFFE5E7EB), width: 0.5),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.02),
              blurRadius: 4,
              offset: const Offset(0, 2),
            )
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  test['examName'] ?? 'Unknown Exam',
                  style: TextStyle(fontWeight: FontWeight.w600, fontSize: 16, color: Theme.of(context).colorScheme.onSurface),
                ),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                  decoration: BoxDecoration(
                    color: AppTheme.primaryBlue.withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(4),
                  ),
                  child: Text(
                    'Score: ${test['score']}/${test['maxScore']}',
                    style: const TextStyle(color: AppTheme.primaryBlue, fontWeight: FontWeight.bold, fontSize: 12),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 8),
            Row(
              children: [
                const Icon(Icons.calendar_today, size: 14, color: Colors.grey),
                const SizedBox(width: 4),
                Text('${test['year']} • ${test['date']}', style: const TextStyle(color: Colors.grey, fontSize: 13)),
                const SizedBox(width: 16),
                const Icon(Icons.access_time, size: 14, color: Colors.grey),
                const SizedBox(width: 4),
                Text('${test['shift']}', style: const TextStyle(color: Colors.grey, fontSize: 13)),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
