import 'dart:async';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../../widgets/app_button.dart';
import '../../widgets/latex_text.dart';
import '../../core/theme.dart';

class TestActiveScreen extends StatefulWidget {
  final Map<String, dynamic> params;
  const TestActiveScreen({super.key, this.params = const {}});

  @override
  State<TestActiveScreen> createState() => _TestActiveScreenState();
}

class _TestActiveScreenState extends State<TestActiveScreen> {
  final PageController _pageController = PageController();
  final ScrollController _scrollController = ScrollController();
  int _currentIndex = 0;
  bool _isGridVisible = false;

  // State for options and review
  final Map<int, dynamic> _selectedOptions = {};
  final Map<int, bool> _markedForReview = {};
  final Set<int> _visitedQuestions = {0};
  
  late Future<List<Map<String, dynamic>>> _questionsFuture;
  List<Map<String, dynamic>> _questions = [];
  
  Timer? _timer;
  int _timeSpentSeconds = 0;
  late int _totalTimeSeconds;

  @override
  void initState() {
    super.initState();
    _totalTimeSeconds = widget.params['totalTimeSeconds'] ?? widget.params['totalTime'] ?? (180 * 60);
    _timeSpentSeconds = widget.params['timeSpentSeconds'] ?? 0;
    
    if (widget.params['selectedOptions'] != null) {
      final savedOptions = widget.params['selectedOptions'] as Map;
      savedOptions.forEach((key, value) {
        _selectedOptions[int.parse(key.toString())] = value;
      });
    }

    _questionsFuture = _fetchQuestions();
    _startTimer();
  }

  void _startTimer() {
    _timer = Timer.periodic(const Duration(seconds: 1), (timer) {
      if (mounted) {
        setState(() {
          _timeSpentSeconds++;
        });
      }
    });
  }

  @override
  void dispose() {
    _timer?.cancel();
    _pageController.dispose();
    _scrollController.dispose();
    super.dispose();
  }

  String _formatTime(int seconds) {
    int remaining = _totalTimeSeconds - seconds;
    if (remaining < 0) remaining = 0;
    int rh = remaining ~/ 3600;
    int rm = (remaining % 3600) ~/ 60;
    int rs = remaining % 60;
    return '${rh.toString().padLeft(2, '0')}:${rm.toString().padLeft(2, '0')}:${rs.toString().padLeft(2, '0')}';
  }

  Future<List<Map<String, dynamic>>> _fetchQuestions() async {
    String type = widget.params['type'] ?? 'pyq';
    String examId = widget.params['examId'] ?? '';
    bool isCustom = widget.params['isCustom'] == true;

    if (type == 'test_series') {
      final test = widget.params['test'];
      if (test != null && test['questions'] != null) {
        final List<dynamic> questionIds = test['questions'] as List<dynamic>;
        if (questionIds.isNotEmpty) {
          final List<Map<String, dynamic>> fetchedQuestions = [];
          for (var i = 0; i < questionIds.length; i += 30) {
            final chunk = questionIds.sublist(i, i + 30 > questionIds.length ? questionIds.length : i + 30);
            final qSnapshot = await FirebaseFirestore.instance.collection('questions')
                .where(FieldPath.documentId, whereIn: chunk)
                .get();
            fetchedQuestions.addAll(qSnapshot.docs.map((e) => {'id': e.id, ...e.data()}).toList());
          }
          fetchedQuestions.sort((a, b) => questionIds.indexOf(a['id']).compareTo(questionIds.indexOf(b['id'])));
          return fetchedQuestions;
        }
      }
      return [];
    }
    
    if (examId.isEmpty) {
      final snapshot = await FirebaseFirestore.instance.collection('questions').where('type', isEqualTo: type).get();
      return snapshot.docs.map((e) => {'id': e.id, ...e.data()}).toList();
    }

    // For Custom Tests, it requests type 'pyq', but we want to filter by selected subjects/chapters instead of year/date/shift.
    Query query = FirebaseFirestore.instance.collection('questions')
        .where('type', isEqualTo: type)
        .where('examId', isEqualTo: examId);

    if (type == 'pyq' && !isCustom) {
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
    } else {
      // Extra questions (type = 'extra') or Custom test (type = 'pyq', isCustom = true)
      String subject = widget.params['subject'] ?? '';
      String chapter = widget.params['chapter'] ?? '';
      if (subject.isNotEmpty) {
        query = query.where('subject', isEqualTo: subject);
      }
      if (chapter.isNotEmpty) {
        query = query.where('chapter', isEqualTo: chapter);
      }
      
      // If Custom Test, maybe we have a list of chapters instead of a single one?
      // Since firestore doesn't support whereIn for large arrays well, 
      // we'll filter on client side if there are multiple subjects/chapters.
    }

    final snapshot = await query.get();
    var docs = snapshot.docs.map((e) => {'id': e.id, ...e.data() as Map<String, dynamic>}).toList();
    
    if (isCustom || type == 'extra') {
      final selectedSubjects = widget.params['subjects'] as List<dynamic>?;
      final selectedChapters = widget.params['chapters'] as List<dynamic>?;
      
      if (selectedSubjects != null && selectedSubjects.isNotEmpty) {
        docs = docs.where((doc) => selectedSubjects.contains(doc['subject'])).toList();
      }
      if (selectedChapters != null && selectedChapters.isNotEmpty) {
        docs = docs.where((doc) => selectedChapters.contains(doc['chapter'])).toList();
      }
      
      docs.shuffle();
      // If there's a limit like maxQuestions, we should limit it. The user said "exactly equal to the set time", 
      // but if Custom Test specifies questions length, limit it:
      int limit = widget.params['questionCount'] ?? 90;
      if (docs.length > limit) {
        docs = docs.sublist(0, limit);
      }
    }
    
    return docs;
  }

  Future<void> _updateQuestionStats(String chapterName, bool isCorrect) async {
    try {
      final user = FirebaseAuth.instance.currentUser;
      if (user != null) {
        final ref = FirebaseFirestore.instance.collection('user_stats').doc(user.uid);
        await ref.set({
          'total_solved': FieldValue.increment(1),
          'chapter_$chapterName': FieldValue.increment(1),
          if (isCorrect) 'chapter_${chapterName}_correct': FieldValue.increment(1),
        }, SetOptions(merge: true));
      }
    } catch (e) {
      debugPrint("Stat error: $e");
    }
  }

  void _nextQuestion() {
    if (_currentIndex < _questions.length - 1) {
      _pageController.nextPage(duration: const Duration(milliseconds: 300), curve: Curves.easeInOut);
    }
  }

  bool _isOptionCorrect(Map<String, dynamic> question, dynamic selectedOpt, List<String> options) {
    if (question['isInteger'] == true || options.isEmpty) {
      if (selectedOpt == null || question['correctAnswer'] == null) return false;
      return num.tryParse(selectedOpt.toString()) == num.tryParse(question['correctAnswer'].toString());
    }

    if (question['correctAnswer'] is num) {
      return (question['correctAnswer'] as num).toInt() == selectedOpt;
    } else if (question['correctAnswer'] != null) {
      String selectedString = (selectedOpt is int && options.length > selectedOpt) ? options[selectedOpt] : '';
      return question['correctAnswer'].toString().trim() == selectedString.trim();
    } else if (question['correctOptionIndex'] != null) {
      return question['correctOptionIndex'] == selectedOpt;
    }
    return false;
  }

  bool _isCorrect(Map<String, dynamic> question, dynamic selectedOpt) {
    final options = (question['options'] as List? ?? []).cast<String>();
    return _isOptionCorrect(question, selectedOpt, options);
  }

  Color _getQuestionColor(int index) {
    final bool isPracticeMode = widget.params['isCustom'] == true;
    final dynamic selectedOpt = _selectedOptions[index];
    final bool isMarked = _markedForReview[index] == true;

    if (selectedOpt != null) {
      if (isPracticeMode) {
        if (_questions.isNotEmpty && index < _questions.length) {
          final q = _questions[index];
          final correct = _isCorrect(q, selectedOpt);
          return correct ? Colors.green : Colors.red;
        }
      }
      // Non-practice mode
      if (isMarked) {
        return Colors.purple; // Answered & Marked
      }
      return Colors.green; // Answered
    }

    if (isMarked) {
      return Colors.orange; // Marked for review
    }

    // Skipped: visited, not answered, and not currently active
    if (_visitedQuestions.contains(index) && index != _currentIndex) {
      return Colors.grey; // Skipped
    }

    return Theme.of(context).dividerTheme.color ?? const Color(0xFFE5E7EB); // Not visited
  }

  void _showSubmitConfirmation() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: Theme.of(context).scaffoldBackgroundColor,
        title: Text('Submit Test', style: TextStyle(color: Theme.of(context).colorScheme.onSurface)),
        content: Text('Are you sure you want to submit the test? You cannot change your answers after submission.', style: TextStyle(color: Theme.of(context).colorScheme.onSurface)),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel', style: TextStyle(color: Colors.grey)),
          ),
          TextButton(
            onPressed: () {
              Navigator.pop(context);
              context.push('/test/summary', extra: {
                ...widget.params,
                'questions': _questions,
                'selectedOptions': _selectedOptions,
                'timeSpent': _timeSpentSeconds,
                'totalTime': _totalTimeSeconds,
              });
            },
            child: const Text('Submit', style: TextStyle(color: AppTheme.primaryBlue)),
          ),
        ],
      ),
    );
  }

  void _showReportDialog(String questionId) {
    final TextEditingController reportCtrl = TextEditingController();
    String selectedIssue = 'Wrong Answer';
    final issues = ['Wrong Answer', 'Bad Image', 'Formatting Error', 'Other'];

    showDialog(
      context: context,
      builder: (context) {
        return StatefulBuilder(
          builder: (context, setDialogState) {
            return AlertDialog(
              backgroundColor: Theme.of(context).scaffoldBackgroundColor,
              title: Text('Report Question', style: TextStyle(color: Theme.of(context).colorScheme.onSurface)),
              content: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  DropdownButtonFormField<String>(
                    initialValue: selectedIssue,
                    dropdownColor: Theme.of(context).scaffoldBackgroundColor,
                    style: TextStyle(color: Theme.of(context).colorScheme.onSurface),
                    decoration: const InputDecoration(border: OutlineInputBorder()),
                    items: issues.map((e) => DropdownMenuItem(value: e, child: Text(e))).toList(),
                    onChanged: (val) {
                      if (val != null) setDialogState(() => selectedIssue = val);
                    },
                  ),
                  const SizedBox(height: 16),
                  TextField(
                    controller: reportCtrl,
                    style: TextStyle(color: Theme.of(context).colorScheme.onSurface),
                    decoration: InputDecoration(
                      labelText: 'Additional Details (optional)',
                      labelStyle: TextStyle(color: Theme.of(context).colorScheme.onSurface),
                      border: const OutlineInputBorder(),
                    ),
                    maxLines: 2,
                  ),
                ],
              ),
              actions: [
                TextButton(
                  onPressed: () => Navigator.pop(context),
                  child: const Text('Cancel', style: TextStyle(color: Colors.grey)),
                ),
                TextButton(
                  onPressed: () async {
                    Navigator.pop(context);
                    try {
                      await FirebaseFirestore.instance.collection('reports').add({
                        'questionId': questionId,
                        'issue': selectedIssue,
                        'details': reportCtrl.text,
                        'timestamp': FieldValue.serverTimestamp(),
                      });
                      if (mounted) {
                        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Report submitted')));
                      }
                    } catch (e) {
                      debugPrint('Report error: $e');
                    }
                  },
                  child: const Text('Submit Report', style: TextStyle(color: AppTheme.primaryBlue)),
                ),
              ],
            );
          }
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final bool isPracticeMode = widget.params['isCustom'] == true;

    return PopScope(
      canPop: false,
      onPopInvokedWithResult: (didPop, result) async {
        if (didPop) return;

        final String? action = await showDialog<String>(
          context: context,
          builder: (context) => AlertDialog(
            backgroundColor: Theme.of(context).scaffoldBackgroundColor,
            title: Text('Leave Test?', style: TextStyle(color: Theme.of(context).colorScheme.onSurface)),
            content: Text(
              'Do you want to save your progress and leave, or submit the test?',
              style: TextStyle(color: Theme.of(context).colorScheme.onSurface)
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(context, 'resume'),
                child: const Text('Resume', style: TextStyle(color: Colors.grey)),
              ),
              TextButton(
                onPressed: () => Navigator.pop(context, 'submit'),
                child: const Text('Submit', style: TextStyle(color: Colors.orange)),
              ),
              TextButton(
                onPressed: () => Navigator.pop(context, 'save'),
                child: const Text('Save & Leave', style: TextStyle(color: AppTheme.primaryBlue)),
              ),
            ],
          ),
        );

        if (action == 'submit' && context.mounted) {
          context.pushReplacement('/test/summary', extra: {
            ...widget.params,
            'questions': _questions,
            'selectedOptions': _selectedOptions,
            'timeSpent': _timeSpentSeconds,
            'totalTime': _totalTimeSeconds,
          });
          return;
        }

        if (action == 'save' && context.mounted) {
          try {
            final user = FirebaseAuth.instance.currentUser;
            if (user != null) {
               final Map<String, dynamic> savedOptions = {};
               _selectedOptions.forEach((key, value) {
                 if (value != null) savedOptions[key.toString()] = value;
               });
               
               // Create a clean copy of params without complex objects if any
               final cleanParams = Map<String, dynamic>.from(widget.params);
               
               // Use a single document for 'extra' and a single one for 'custom' per user, overriding the previous saved test.
               String docId = '${user.uid}_${widget.params['type']}';
               if (widget.params['isCustom'] == true) docId = '${user.uid}_custom';
               
               await FirebaseFirestore.instance.collection('in_progress_tests').doc(docId).set({
                 'userId': user.uid,
                 'type': widget.params['type'],
                 'isCustom': widget.params['isCustom'] ?? false,
                 'params': cleanParams,
                 'selectedOptions': savedOptions,
                 'timeSpentSeconds': _timeSpentSeconds,
                 'totalTimeSeconds': _totalTimeSeconds,
                 'timestamp': FieldValue.serverTimestamp(),
               });
            }
          } catch(e) {
            debugPrint("Error saving progress: $e");
          }
          if (context.mounted) {
            context.go('/home');
          }
        }
      },
      child: Scaffold(
        body: SafeArea(
        child: Column(
          children: [
            // Header
            Padding(
              padding: const EdgeInsets.all(16.0),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Row(
                    children: [
                      Icon(Icons.timer_outlined, color: Theme.of(context).colorScheme.onSurface),
                      const SizedBox(width: 8),
                      Text(
                        _formatTime(_timeSpentSeconds),
                        style: TextStyle(fontSize: 18, fontWeight: FontWeight.w600, color: Theme.of(context).colorScheme.onSurface),
                      ),
                    ],
                  ),
                  AppButton(
                    text: 'Submit',
                    type: AppButtonType.outlined,
                    onPressed: _showSubmitConfirmation,
                  ),
                ],
              ),
            ),
            const Divider(),
              // Horizontal Question Numbers & Grid Toggle
              SizedBox(
                height: 50,
                child: Row(
                  children: [
                    Expanded(
                      child: ListView.builder(
                        scrollDirection: Axis.horizontal,
                        itemCount: _questions.length,
                        itemBuilder: (context, index) {
                        return GestureDetector(
                          onTap: () {
                            _pageController.jumpToPage(index);
                          },
                           child: Container(
                            width: 40,
                            margin: const EdgeInsets.symmetric(horizontal: 4, vertical: 8),
                            decoration: BoxDecoration(
                              color: _getQuestionColor(index).withValues(alpha: index == _currentIndex ? 0.25 : 0.1),
                              border: Border.all(
                                color: index == _currentIndex ? AppTheme.primaryBlue : _getQuestionColor(index),
                                width: index == _currentIndex ? 2.5 : 1.0,
                              ),
                              borderRadius: BorderRadius.circular(6),
                            ),
                            alignment: Alignment.center,
                            child: Text(
                              '${index + 1}',
                              style: TextStyle(
                                color: _getQuestionColor(index) == (Theme.of(context).dividerTheme.color ?? const Color(0xFFE5E7EB)) 
                                    ? Theme.of(context).colorScheme.onSurface 
                                    : _getQuestionColor(index),
                                fontWeight: FontWeight.w700,
                              ),
                            ),
                          ),
                        );
                      },
                    ),
                  ),
                  IconButton(
                    icon: Icon(_isGridVisible ? Icons.grid_off : Icons.grid_view),
                    onPressed: () {
                      setState(() {
                        _isGridVisible = !_isGridVisible;
                      });
                    },
                  ),
                ],
              ),
            ),
            const Divider(),
              // Question Area
              Expanded(
                child: FutureBuilder<List<Map<String, dynamic>>>(
                  future: _questionsFuture,
                  builder: (context, snapshot) {
                    if (snapshot.connectionState == ConnectionState.waiting) {
                      return const Center(child: CircularProgressIndicator());
                    }
                    if (snapshot.hasError) {
                      return Center(child: Text('Error: ${snapshot.error}'));
                    }
                    _questions = snapshot.data ?? [];
                    if (_questions.isEmpty) {
                      return const Center(child: Text('No questions found for this test.'));
                    }

                    return Stack(
                      children: [
                        PageView.builder(
                          controller: _pageController,
                          physics: const NeverScrollableScrollPhysics(),
                          onPageChanged: (index) {
                            setState(() {
                              _currentIndex = index;
                              _visitedQuestions.add(index);
                            });
                          },
                          itemCount: _questions.length,
                          itemBuilder: (context, index) {
                            final question = _questions[index];
                            final options = (question['options'] as List<dynamic>? ?? []).cast<String>();
                            return SingleChildScrollView(
                              controller: index == _currentIndex ? _scrollController : null,
                        padding: const EdgeInsets.all(16.0),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            // Question Meta
                            Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                Text(
                                  'Question ${index + 1}',
                                  style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 16),
                                ),
                                Row(
                                  children: [
                                    Container(
                                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                                      decoration: BoxDecoration(
                                        color: Colors.green.withValues(alpha: 0.1),
                                        borderRadius: BorderRadius.circular(4),
                                      ),
                                      child: Text('+${question['marks'] ?? 4}', style: const TextStyle(color: Colors.green, fontSize: 12)),
                                    ),
                                    const SizedBox(width: 8),
                                    Container(
                                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                                      decoration: BoxDecoration(
                                        color: Colors.red.withValues(alpha: 0.1),
                                        borderRadius: BorderRadius.circular(4),
                                      ),
                                      child: Text('${question['negativeMarks'] ?? -1}', style: const TextStyle(color: Colors.red, fontSize: 12)),
                                    ),
                                    const SizedBox(width: 16),
                                    GestureDetector(
                                      onTap: () => _showReportDialog(question['id'] ?? 'unknown'),
                                      child: const Icon(Icons.report_problem_outlined, color: Colors.grey, size: 20),
                                    ),
                                  ],
                                ),
                              ],
                            ),
                              const SizedBox(height: 24),
                              // Question Text
                              LatexText(
                                text: question['text'] ?? '',
                                style: TextStyle(fontSize: 16, color: Theme.of(context).colorScheme.onSurface),
                              ),
                              if (question['imageUrl'] != null && question['imageUrl'].toString().startsWith('http')) ...[
                                const SizedBox(height: 16),
                                Image.network(question['imageUrl']),
                              ],
                              const SizedBox(height: 32),
                              if (question['isInteger'] == true || options.isEmpty)
                                Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    TextFormField(
                                      initialValue: _selectedOptions[index]?.toString() ?? '',
                                      keyboardType: const TextInputType.numberWithOptions(signed: true, decimal: true),
                                      decoration: InputDecoration(
                                        labelText: 'Enter Integer Answer',
                                        border: const OutlineInputBorder(),
                                        filled: true,
                                        fillColor: Theme.of(context).colorScheme.surface,
                                      ),
                                      onChanged: (val) {
                                        _selectedOptions[index] = val;
                                      },
                                    ),
                                    if (isPracticeMode)
                                      Padding(
                                        padding: const EdgeInsets.only(top: 16),
                                        child: AppButton(
                                          text: 'Check Answer',
                                          onPressed: () {
                                            setState(() {});
                                            final bool isCorrect = _isOptionCorrect(question, _selectedOptions[index], options);
                                            _updateQuestionStats(question['chapter'] ?? 'unknown', isCorrect);
                                          },
                                        ),
                                      ),
                                  ],
                                )
                              else
                                ...List.generate(options.length, (optIndex) {
                                  final isSelected = _selectedOptions[index] == optIndex;
                                  final optionImages = (question['optionImages'] as List<dynamic>? ?? []).cast<String>();
                                  final optImageUrl = optionImages.length > optIndex ? optionImages[optIndex] : '';
                                  
                                  bool showCorrect = isPracticeMode && _selectedOptions[index] != null;
                                  bool isThisOptionCorrect = _isOptionCorrect(question, optIndex, options);
                                  Color optColor = Theme.of(context).colorScheme.surface;
                                  Color borderColor = Theme.of(context).dividerTheme.color ?? const Color(0xFFE5E7EB);
                                  
                                  if (showCorrect) {
                                    if (isThisOptionCorrect) {
                                       optColor = Colors.green.withValues(alpha: 0.1);
                                       borderColor = Colors.green;
                                    } else if (isSelected) {
                                       optColor = Colors.red.withValues(alpha: 0.1);
                                       borderColor = Colors.red;
                                    }
                                  } else if (isSelected) {
                                    optColor = AppTheme.primaryBlue.withValues(alpha: 0.05);
                                    borderColor = AppTheme.primaryBlue;
                                  }
                                  
                                  return GestureDetector(
                                    onTap: () {
                                      if (isPracticeMode) {
                                        if (_selectedOptions[index] == null) {
                                          setState(() {
                                            _selectedOptions[index] = optIndex;
                                          });
                                          final bool isCorrect = _isOptionCorrect(question, optIndex, options);
                                          _updateQuestionStats(question['chapter'] ?? 'unknown', isCorrect);

                                          Future.delayed(const Duration(milliseconds: 100), () {
                                            if (_scrollController.hasClients) {
                                              _scrollController.animateTo(
                                                _scrollController.position.maxScrollExtent,
                                                duration: const Duration(milliseconds: 300),
                                                curve: Curves.easeOut,
                                              );
                                            }
                                          });
                                        }
                                      } else {
                                        setState(() {
                                          _selectedOptions[index] = optIndex;
                                        });
                                      }
                                    },
                                    child: Container(
                                      width: double.infinity,
                                      margin: const EdgeInsets.only(bottom: 12),
                                      padding: const EdgeInsets.all(16),
                                      decoration: BoxDecoration(
                                        color: optColor,
                                        border: Border.all(
                                          color: borderColor,
                                          width: (isSelected || (showCorrect && isThisOptionCorrect)) ? 1.5 : 0.5,
                                        ),
                                        borderRadius: BorderRadius.circular(8),
                                      ),
                                      child: Row(
                                        children: [
                                          Container(
                                            height: 20,
                                            width: 20,
                                            decoration: BoxDecoration(
                                              shape: BoxShape.circle,
                                              border: Border.all(
                                                color: borderColor,
                                                width: (isSelected || (showCorrect && isThisOptionCorrect)) ? 6 : 1,
                                              ),
                                            ),
                                          ),
                                          const SizedBox(width: 16),
                                            Expanded(
                                              child: Column(
                                                crossAxisAlignment: CrossAxisAlignment.start,
                                                children: [
                                                  if (options[optIndex].isNotEmpty)
                                                    LatexText(
                                                      text: options[optIndex],
                                                      style: TextStyle(
                                                        color: (showCorrect && (isThisOptionCorrect || isSelected)) ? borderColor : (isSelected ? AppTheme.primaryBlue : Theme.of(context).colorScheme.onSurface),
                                                        fontWeight: (isSelected || (showCorrect && isThisOptionCorrect)) ? FontWeight.w500 : FontWeight.normal,
                                                      ),
                                                    ),
                                                  if (optImageUrl.startsWith('http'))
                                                    Padding(
                                                      padding: const EdgeInsets.only(top: 8.0),
                                                      child: Image.network(optImageUrl, height: 100),
                                                    ),
                                                ],
                                              ),
                                            ),
                                        ],
                                      ),
                                    ),
                                  );
                                }),
                            if (isPracticeMode && _selectedOptions[index] != null) ...[
                              const SizedBox(height: 24),
                              Container(
                                padding: const EdgeInsets.all(16),
                                decoration: BoxDecoration(
                                  color: Theme.of(context).colorScheme.surfaceContainerHighest,
                                  borderRadius: BorderRadius.circular(12),
                                ),
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                      Row(
                                        children: [
                                          Icon(
                                            _isOptionCorrect(question, _selectedOptions[index]!, options) ? Icons.check_circle : Icons.cancel,
                                            color: _isOptionCorrect(question, _selectedOptions[index]!, options) ? Colors.green : Colors.red,
                                          ),
                                          const SizedBox(width: 8),
                                          Text(
                                            _isOptionCorrect(question, _selectedOptions[index]!, options) ? 'Correct Answer!' : 'Incorrect Answer',
                                            style: TextStyle(
                                              fontWeight: FontWeight.bold,
                                              color: _isOptionCorrect(question, _selectedOptions[index]!, options) ? Colors.green : Colors.red,
                                            ),
                                          ),
                                        ],
                                      ),
                                    const SizedBox(height: 16),
                                    const Text('Solution:', style: TextStyle(fontWeight: FontWeight.bold)),
                                    const SizedBox(height: 8),
                                    if (question['solution'] != null && question['solution'].toString().isNotEmpty)
                                       LatexText(text: question['solution'], style: TextStyle(color: Theme.of(context).colorScheme.onSurface)),
                                    if (question['solutionImageUrl'] != null && question['solutionImageUrl'].toString().startsWith('http'))
                                       Padding(
                                         padding: const EdgeInsets.only(top: 8),
                                         child: Image.network(question['solutionImageUrl']),
                                       ),
                                  ],
                                ),
                              ),
                            ],
                            const SizedBox(height: 24),
                            // Mark for review toggle
                            Row(
                              children: [
                                Checkbox(
                                  value: _markedForReview[index] ?? false,
                                  onChanged: (val) {
                                    setState(() {
                                      _markedForReview[index] = val ?? false;
                                    });
                                  },
                                  activeColor: AppTheme.primaryBlue,
                                  side: BorderSide(color: Theme.of(context).dividerTheme.color ?? const Color(0xFFE5E7EB), width: 1),
                                ),
                                const Text('Mark for Review'),
                              ],
                            ),
                          ],
                        ),
                      );
                    },
                  ),
                      if (_isGridVisible)
                        Container(
                          color: Theme.of(context).scaffoldBackgroundColor,
                          child: GridView.builder(
                            padding: const EdgeInsets.all(16),
                            gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                              crossAxisCount: 5,
                              crossAxisSpacing: 8,
                              mainAxisSpacing: 8,
                            ),
                            itemCount: _questions.length,
                            itemBuilder: (context, index) {
                          return GestureDetector(
                            onTap: () {
                              _pageController.jumpToPage(index);
                              setState(() {
                                _isGridVisible = false;
                              });
                            },
                            child: Container(
                              decoration: BoxDecoration(
                                color: _getQuestionColor(index).withValues(alpha: 0.1),
                                border: Border.all(color: _getQuestionColor(index), width: 1),
                                borderRadius: BorderRadius.circular(4),
                              ),
                              alignment: Alignment.center,
                              child: Text('${index + 1}', style: TextStyle(color: _getQuestionColor(index) == (Theme.of(context).dividerTheme.color ?? const Color(0xFFE5E7EB)) ? Theme.of(context).colorScheme.onSurface : _getQuestionColor(index), fontWeight: FontWeight.w600)),
                            ),
                          );
                        },
                      ),
                    ),
                ],
              );
            },
          ),
        ),
        // Footer
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                border: Border(top: BorderSide(color: Theme.of(context).dividerTheme.color ?? const Color(0xFFE5E7EB), width: 0.5)),
              ),
              child: SizedBox(
                width: double.infinity,
                child: AppButton(
                  text: 'Save and Next',
                  onPressed: _nextQuestion,
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
