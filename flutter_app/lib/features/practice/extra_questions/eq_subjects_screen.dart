import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../../../widgets/animated_back_button.dart';
import '../../../widgets/app_button.dart';
import '../../../widgets/section_title.dart';
import '../../../core/theme.dart';
import 'package:cloud_firestore/cloud_firestore.dart';


class EqSubjectsScreen extends StatefulWidget {
  final Map<String, dynamic> params;
  const EqSubjectsScreen({super.key, required this.params});

  @override
  State<EqSubjectsScreen> createState() => _EqSubjectsScreenState();
}

class _EqSubjectsScreenState extends State<EqSubjectsScreen> {
  List<Map<String, dynamic>> _subjects = [];
  bool _isLoading = true;
  
  final Set<String> _selectedSubjects = {};

  @override
  void initState() {
    super.initState();
    _loadSubjects();
  }

  Future<void> _loadSubjects() async {
    final exam = widget.params['exam'];
    if (exam == null) {
      setState(() {
        _isLoading = false;
      });
      return;
    }

    final type = widget.params['type'] ?? 'extra';
    final examId = exam['id'];

    try {
      final snapshot = await FirebaseFirestore.instance.collection('questions')
          .where('type', isEqualTo: type)
          .where('examId', isEqualTo: examId)
          .get();

      final questions = snapshot.docs.map((e) => e.data()).toList();
      
      Map<String, Set<String>> subjectChapters = {};
      Map<String, int> subjectQuestionCount = {};
      
      for (var q in questions) {
        final sub = q['subject']?.toString() ?? '';
        final chap = q['chapter']?.toString() ?? '';
        
        if (sub.isNotEmpty) {
          subjectChapters.putIfAbsent(sub, () => {});
          if (chap.isNotEmpty) subjectChapters[sub]!.add(chap);
          subjectQuestionCount[sub] = (subjectQuestionCount[sub] ?? 0) + 1;
        }
      }
      
      final List<Map<String, dynamic>> loadedSubjects = [];
      for (var sub in subjectChapters.keys) {
        loadedSubjects.add({
          'name': sub,
          'chapters': subjectChapters[sub]!.length,
          'questions': subjectQuestionCount[sub]!,
          'all_chapters': subjectChapters[sub]!.toList(),
        });
      }

      if (mounted) {
        setState(() {
          _subjects = loadedSubjects;
          _isLoading = false;
        });
        if (loadedSubjects.isEmpty) {
          ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Found 0 questions for type: $type, examId: $examId')));
        }
      }
    } catch (e) {
      debugPrint('Error loading dynamic subjects: $e');
      if (mounted) {
        setState(() => _isLoading = false);
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Error: $e')));
      }
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
                      child: SectionTitle(title: 'Select Subjects'),
                    ),
                  ),
                  const SizedBox(width: 40),
                ],
              ),
            ),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 8.0),
              child: TextField(
                decoration: InputDecoration(
                  hintText: 'Search subjects...',
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
                : _subjects.isEmpty
                  ? const Center(child: Text("No subjects available."))
                  : ListView.builder(
                      padding: const EdgeInsets.all(16.0),
                      itemCount: _subjects.length,
                      itemBuilder: (context, index) {
                        final subject = _subjects[index];
                        final isSelected = _selectedSubjects.contains(subject['name']);
                        
                        return GestureDetector(
                          onTap: () {
                            setState(() {
                              if (isSelected) {
                                _selectedSubjects.remove(subject['name']);
                              } else {
                                _selectedSubjects.add(subject['name']);
                              }
                            });
                          },
                          child: Container(
                            margin: const EdgeInsets.only(bottom: 12),
                            padding: const EdgeInsets.all(16),
                            decoration: BoxDecoration(
                              color: isSelected ? AppTheme.primaryBlue.withValues(alpha: 0.05) : Theme.of(context).colorScheme.surface,
                              borderRadius: BorderRadius.circular(8),
                              border: Border.all(
                                color: isSelected ? AppTheme.primaryBlue : Theme.of(context).dividerTheme.color ?? const Color(0xFFE5E7EB),
                                width: 0.5,
                              ),
                            ),
                            child: Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      subject['name'],
                                      style: TextStyle(
                                        fontSize: 16,
                                        fontWeight: isSelected ? FontWeight.w600 : FontWeight.w500,
                                        color: isSelected ? AppTheme.primaryBlue : Theme.of(context).colorScheme.onSurface,
                                      ),
                                    ),
                                    const SizedBox(height: 4),
                                    Text(
                                      '${subject['chapters']} Chapters | ${subject['questions']} Questions',
                                      style: const TextStyle(fontSize: 12, color: Colors.grey),
                                    ),
                                  ],
                                ),
                                Icon(
                                  isSelected ? Icons.check_circle : Icons.circle_outlined,
                                  color: isSelected ? Theme.of(context).primaryColor : Theme.of(context).dividerTheme.color ?? const Color(0xFFE5E7EB),
                                ),
                              ],
                            ),
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
              child: SizedBox(
                width: double.infinity,
                child: AppButton(
                  text: 'Continue',
                  type: _selectedSubjects.isNotEmpty ? AppButtonType.solid : AppButtonType.unselected,
                  onPressed: () {
                    if (_selectedSubjects.isEmpty) return;
                    
                    final type = widget.params['type'] ?? 'extra';
                    final path = type == 'pyq' ? '/ct/chapters' : '/eq/chapters';
                    
                      context.push(path, extra: {
                        ...widget.params,
                        'exam': widget.params['exam'],
                        'subjects': _selectedSubjects.toList(),
                        'type': type,
                        'dynamicSubjects': _subjects,
                      });
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
