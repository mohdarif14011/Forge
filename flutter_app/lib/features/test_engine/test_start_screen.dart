import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../../widgets/animated_back_button.dart';
import '../../widgets/app_button.dart';
import '../../core/theme.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class TestStartScreen extends StatefulWidget {
  final Map<String, dynamic> params;
  const TestStartScreen({super.key, this.params = const {}});

  @override
  State<TestStartScreen> createState() => _TestStartScreenState();
}

class _TestStartScreenState extends State<TestStartScreen> with SingleTickerProviderStateMixin {
  late TabController _tabController;
  Map<String, dynamic>? _exam;
  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
    if (widget.params['type'] == 'test_series') {
      final test = widget.params['test'];
      if (test != null) {
        _exam = {
          'id': test['examId'],
          'name': test['name'] ?? 'Mock Test',
          'subjects': [
            {
              'name': test['subject'] ?? 'Mixed',
              'chapters': List<String>.from(test['chapters'] ?? []),
            }
          ]
        };
      }
    } else if (widget.params['type'] == 'pyq') {
      _fetchData();
    } else if (widget.params['exam'] != null) {
      _exam = widget.params['exam'];
    } else if (widget.params['examId'] != null) {
      _fetchData();
    }
  }

  Future<void> _fetchData() async {
    setState(() => _isLoading = true);
    try {
      final examId = widget.params['examId'];
      final type = widget.params['type'] ?? 'pyq';
      if (examId != null) {
        if (type == 'pyq') {
          Query query = FirebaseFirestore.instance.collection('questions')
            .where('type', isEqualTo: 'pyq')
            .where('examId', isEqualTo: examId);
            
          if (widget.params['year'] != null) {
            query = query.where('year', isEqualTo: widget.params['year'].toString());
          }
          if (widget.params['date'] != null) {
            query = query.where('date', isEqualTo: widget.params['date']);
          }
          if (widget.params['shift'] != null) {
            String s = widget.params['shift'];
            if (s == 'Morning Shift') {
              query = query.where('shift', whereIn: ['1', 'Shift 1', 'Morning Shift', 'Morning', 'morning']);
            } else if (s == 'Evening Shift') {
              query = query.where('shift', whereIn: ['2', 'Shift 2', 'Evening Shift', 'Evening', 'evening']);
            } else {
              query = query.where('shift', isEqualTo: s);
            }
          }
          
          final qSnapshot = await query.get();
          final List<Map<String, dynamic>> questions = qSnapshot.docs.map((d) => d.data() as Map<String, dynamic>).toList();
          
          Map<String, Set<String>> subChapMap = {};
          for (var q in questions) {
            final subject = q['subject']?.toString() ?? 'Unknown';
            final chapter = q['chapter']?.toString() ?? 'Unknown';
            if (subject.isNotEmpty && chapter.isNotEmpty) {
              subChapMap.putIfAbsent(subject, () => {}).add(chapter);
            }
          }
          
          List<Map<String, dynamic>> subjectsList = [];
          for (var entry in subChapMap.entries) {
            subjectsList.add({
              'name': entry.key,
              'chapters': entry.value.toList(),
            });
          }
          
          setState(() {
            _exam = {'id': examId, 'name': widget.params['examName'] ?? 'PYQ Test', 'subjects': subjectsList};
          });
        } else {
          final snapshot = await FirebaseFirestore.instance.collection('exams').doc(examId).get();
          if (snapshot.exists) {
            setState(() => _exam = {'id': snapshot.id, ...?snapshot.data()});
          }
        }
      }
    } catch (e) {
      debugPrint('Error fetching data: $e');
    }
    if (mounted) setState(() => _isLoading = false);
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
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
                  AnimatedBackButton(onPressed: () => context.pop()),
                  Expanded(
                    child: Center(
                      child: Text(
                        'Test Start',
                        style: TextStyle(fontSize: 18, fontWeight: FontWeight.w600, color: Theme.of(context).colorScheme.onSurface),
                      ),
                    ),
                  ),
                  const SizedBox(width: 40),
                ],
              ),
            ),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16.0),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Icon(Icons.timer_outlined, size: 16, color: Colors.grey),
                  const SizedBox(width: 4),
                  const Text('180 Mins', style: TextStyle(color: Colors.grey)),
                  const SizedBox(width: 16),
                  const Icon(Icons.list_alt, size: 16, color: Colors.grey),
                  const SizedBox(width: 4),
                  Text(
                    '${widget.params['test']?['questions']?.length ?? widget.params['questions']?.length ?? 90} Questions', 
                    style: const TextStyle(color: Colors.grey)
                  ),
                ],
              ),
            ),
            const SizedBox(height: 16),
            TabBar(
              controller: _tabController,
              indicatorColor: AppTheme.primaryBlue,
              labelColor: AppTheme.primaryBlue,
              unselectedLabelColor: Colors.grey,
              tabs: const [
                Tab(text: 'Syllabus'),
                Tab(text: 'Instructions'),
              ],
            ),
            Expanded(
              child: TabBarView(
                controller: _tabController,
                children: [
                  // Syllabus View
                  _isLoading 
                    ? const Center(child: CircularProgressIndicator())
                    : ListView(
                        padding: const EdgeInsets.all(16.0),
                        children: _buildDynamicSyllabus(),
                      ),
                  // Instructions View
                  ListView(
                    padding: const EdgeInsets.all(16.0),
                    children: [
                      Text('1. The test is of 3 hours duration.', style: TextStyle(height: 1.5, color: Theme.of(context).colorScheme.onSurface)),
                      Text('2. There are 90 questions in total.', style: TextStyle(height: 1.5, color: Theme.of(context).colorScheme.onSurface)),
                      Text('3. +4 marks for correct answer, -1 mark for incorrect answer.', style: TextStyle(height: 1.5, color: Theme.of(context).colorScheme.onSurface)),
                      Text('4. Do not refresh or close the app during the test.', style: TextStyle(height: 1.5, color: Theme.of(context).colorScheme.onSurface)),
                    ],
                  ),
                ],
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
                  text: 'Start Test',
                  onPressed: () {
                    final fullParams = {...widget.params};
                    if (_exam != null) {
                      fullParams['exam'] = _exam;
                    }
                    context.push('/test/active', extra: fullParams);
                  },
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  List<Widget> _buildDynamicSyllabus() {
    if (_exam == null || _exam!['subjects'] == null) {
      return const [Text('Syllabus data not available.', style: TextStyle(color: Colors.grey))];
    }
    
    final List<Widget> list = [];
    final selectedSubjects = widget.params['subjects'] as List<String>?;
    final selectedChapters = widget.params['chapters'] as List<String>?;
    
    for (var subject in _exam!['subjects']) {
      final subjectName = subject['name'] as String;
      
      // Filter if subjects were specifically selected
      if (selectedSubjects != null && !selectedSubjects.contains(subjectName)) {
        continue;
      }
      
      List<String> chapters = List<String>.from(subject['chapters'] ?? []);
      if (selectedChapters != null && selectedChapters.isNotEmpty) {
        chapters = chapters.where((c) => selectedChapters.contains(c)).toList();
      }
      
      if (chapters.isEmpty) continue;
      
      list.add(Text(subjectName, style: TextStyle(fontWeight: FontWeight.w600, color: Theme.of(context).colorScheme.onSurface)));
      final chapterText = chapters.map((c) => '• $c').join('\n');
      list.add(Text(chapterText, style: const TextStyle(color: Colors.grey, height: 1.5)));
      list.add(const SizedBox(height: 16));
    }
    
    if (list.isEmpty) {
      return const [Text('No syllabus selected.', style: TextStyle(color: Colors.grey))];
    }
    
    return list;
  }
}
