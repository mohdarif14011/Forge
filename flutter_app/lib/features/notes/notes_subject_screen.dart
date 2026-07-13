import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../../widgets/animated_back_button.dart';
import '../../widgets/section_title.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class NotesSubjectScreen extends StatefulWidget {
  final Map<String, dynamic> params;
  const NotesSubjectScreen({super.key, required this.params});

  @override
  State<NotesSubjectScreen> createState() => _NotesSubjectScreenState();
}

class _NotesSubjectScreenState extends State<NotesSubjectScreen> {
  List<Map<String, dynamic>> _subjects = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadSubjects();
  }

  Future<void> _loadSubjects() async {
    final exam = widget.params['exam'];
    if (exam == null) {
      setState(() => _isLoading = false);
      return;
    }

    try {
      final examId = exam['id'];
      final snapshot = await FirebaseFirestore.instance.collection('notes')
          .where('examId', isEqualTo: examId)
          .get();

      final notes = snapshot.docs.map((e) => e.data()).toList();
      
      Map<String, Set<String>> subjectChapters = {};
      Map<String, int> subjectPagesCount = {}; // Assuming each note has a 'pages' field or similar
      
      for (var n in notes) {
        final sub = n['subject']?.toString() ?? '';
        final chap = n['chapter']?.toString() ?? '';
        final pages = n['pages'] as int? ?? 1; // if you have a pages field
        
        if (sub.isNotEmpty) {
          subjectChapters.putIfAbsent(sub, () => {});
          if (chap.isNotEmpty) subjectChapters[sub]!.add(chap);
          subjectPagesCount[sub] = (subjectPagesCount[sub] ?? 0) + pages;
        }
      }
      
      final List<Map<String, dynamic>> loadedSubjects = [];
      for (var sub in subjectChapters.keys) {
        loadedSubjects.add({
          'name': sub,
          'chapters': subjectChapters[sub]!.length,
          'all_chapters': subjectChapters[sub]!.toList(),
        });
      }

      if (mounted) {
        setState(() {
          _subjects = loadedSubjects;
          _isLoading = false;
        });
      }
    } catch (e) {
      debugPrint('Error loading notes subjects: $e');
      if (mounted) setState(() => _isLoading = false);
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
                      child: SectionTitle(title: 'Select Subject'),
                    ),
                  ),
                  const SizedBox(width: 40),
                ],
              ),
            ),
            Expanded(
              child: _isLoading 
                ? const Center(child: CircularProgressIndicator())
                : _subjects.isEmpty
                  ? const Center(child: Text("No notes available for this exam."))
                  : ListView.builder(
                      padding: const EdgeInsets.all(16.0),
                      itemCount: _subjects.length,
                      itemBuilder: (context, index) {
                        final subject = _subjects[index];
                        return GestureDetector(
                          onTap: () => context.push('/notes/chapters', extra: {
                            'exam': widget.params['exam'],
                            'subject': subject['name'],
                            'chapters': subject['all_chapters'],
                          }),
                          child: Container(
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
                                Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      subject['name'],
                                      style: TextStyle(
                                        fontSize: 16,
                                        fontWeight: FontWeight.w500,
                                        color: Theme.of(context).colorScheme.onSurface,
                                      ),
                                    ),
                                    const SizedBox(height: 4),
                                    Text(
                                      '${subject['chapters']} Chapters',
                                      style: const TextStyle(fontSize: 12, color: Colors.grey),
                                    ),
                                  ],
                                ),
                                Icon(Icons.chevron_right, color: Theme.of(context).dividerTheme.color ?? const Color(0xFFE5E7EB)),
                              ],
                            ),
                          ),
                        );
                      },
                    ),
            ),
          ],
        ),
      ),
    );
  }
}
