import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../../../widgets/animated_back_button.dart';
import '../../../widgets/app_button.dart';
import '../../../widgets/section_title.dart';
import '../../../core/theme.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

class EqChaptersScreen extends StatefulWidget {
  final Map<String, dynamic> params;
  const EqChaptersScreen({super.key, required this.params});

  @override
  State<EqChaptersScreen> createState() => _EqChaptersScreenState();
}

class _EqChaptersScreenState extends State<EqChaptersScreen> {
  Map<String, List<String>> _chaptersBySubject = {};
  bool _isLoading = true;
  
  final Set<String> _selectedChapters = {};

  @override
  void initState() {
    super.initState();
    _loadChapters();
  }

  void _loadChapters() {
    final subjects = widget.params['subjects'] as List<String>? ?? [];
    final dynamicSubjects = widget.params['dynamicSubjects'] as List<dynamic>?;
    
    if (subjects.isEmpty || dynamicSubjects == null) {
      setState(() => _isLoading = false);
      return;
    }

    final Map<String, List<String>> map = {};
    for (var subMap in dynamicSubjects) {
      final subjectName = subMap['name'] as String;
      if (subjects.contains(subjectName)) {
        final chaps = List<String>.from(subMap['all_chapters'] ?? []);
        if (chaps.isNotEmpty) {
          map[subjectName] = chaps;
        }
      }
    }
    
    setState(() {
      _chaptersBySubject = map;
      _isLoading = false;
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
                      child: SectionTitle(title: 'Select Chapters'),
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
                  hintText: 'Search chapters...',
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
                : _chaptersBySubject.isEmpty
                  ? const Center(child: Text("No chapters found for selected subjects."))
                  : StreamBuilder<DocumentSnapshot>(
                      stream: FirebaseFirestore.instance.collection('user_stats').doc(FirebaseAuth.instance.currentUser?.uid).snapshots(),
                      builder: (context, snapshot) {
                        final userStats = snapshot.data?.data() as Map<String, dynamic>? ?? {};
                        
                        return ListView.builder(
                          padding: const EdgeInsets.all(16.0),
                          itemCount: _chaptersBySubject.keys.length,
                          itemBuilder: (context, index) {
                            final subject = _chaptersBySubject.keys.elementAt(index);
                            final chapters = _chaptersBySubject[subject]!;
                            
                            return Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Padding(
                                  padding: const EdgeInsets.symmetric(vertical: 8.0),
                                  child: Text(
                                    subject,
                                    style: TextStyle(fontWeight: FontWeight.w600, color: Theme.of(context).colorScheme.onSurface),
                                  ),
                                ),
                                ...chapters.map((chapter) {
                                  final isSelected = _selectedChapters.contains(chapter);
                                  final solvedCount = userStats['chapter_$chapter'] as int? ?? 0;
                                  
                                  return GestureDetector(
                                    onTap: () {
                                      setState(() {
                                        if (isSelected) {
                                          _selectedChapters.remove(chapter);
                                        } else {
                                          _selectedChapters.add(chapter);
                                        }
                                      });
                                    },
                                    child: Container(
                                      margin: const EdgeInsets.only(bottom: 8),
                                      padding: const EdgeInsets.all(12),
                                      decoration: BoxDecoration(
                                        color: isSelected ? AppTheme.primaryBlue.withValues(alpha: 0.05) : Theme.of(context).colorScheme.surface,
                                        borderRadius: BorderRadius.circular(8),
                                        border: Border.all(
                                          color: isSelected ? AppTheme.primaryBlue : Theme.of(context).dividerTheme.color ?? const Color(0xFFE5E7EB),
                                          width: 0.5,
                                        ),
                                      ),
                                      child: Column(
                                        children: [
                                          Row(
                                            children: [
                                              Icon(
                                                isSelected ? Icons.check_box : Icons.check_box_outline_blank,
                                                color: isSelected ? AppTheme.primaryBlue : Theme.of(context).dividerTheme.color ?? const Color(0xFFE5E7EB),
                                              ),
                                              const SizedBox(width: 12),
                                              Expanded(
                                                child: Text(
                                                  chapter,
                                                  style: TextStyle(
                                                    fontWeight: isSelected ? FontWeight.w500 : FontWeight.normal,
                                                    color: isSelected ? AppTheme.primaryBlue : Theme.of(context).colorScheme.onSurface,
                                                  ),
                                                ),
                                              ),
                                            ],
                                          ),
                                          const SizedBox(height: 8),
                                          Row(
                                            children: [
                                              const SizedBox(width: 36),
                                              Text('$solvedCount solved', style: const TextStyle(fontSize: 12, color: Colors.grey)),
                                            ],
                                          ),
                                        ],
                                      ),
                                    ),
                                  );
                                }),
                                const SizedBox(height: 16),
                              ],
                            );
                          },
                        );
                      }
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
                  type: _selectedChapters.isNotEmpty ? AppButtonType.solid : AppButtonType.unselected,
                  onPressed: () {
                    if (_selectedChapters.isNotEmpty) {
                      final type = widget.params['type'] ?? 'extra';
                      final path = type == 'pyq' ? '/ct/timer' : '/eq/timer';
                      
                      context.push(path, extra: {
                        ...widget.params,
                        'chapters': _selectedChapters.toList(),
                      });
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
