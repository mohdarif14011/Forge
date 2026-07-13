import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../../core/services/firebase_service.dart';
import '../../widgets/latex_text.dart';

class TestSolutionScreen extends StatefulWidget {
  final Map<String, dynamic> params;
  const TestSolutionScreen({super.key, this.params = const {}});

  @override
  State<TestSolutionScreen> createState() => _TestSolutionScreenState();
}

class _TestSolutionScreenState extends State<TestSolutionScreen> {
  final PageController _pageController = PageController();
  int _currentIndex = 0;
  bool _isGridVisible = false;

  final Map<int, dynamic> _userAnswers = {};
  
  late Future<List<Map<String, dynamic>>> _questionsFuture;
  List<Map<String, dynamic>> _questions = [];

  @override
  void initState() {
    super.initState();
    if (widget.params['selectedOptions'] != null) {
      final savedOptions = widget.params['selectedOptions'] as Map;
      savedOptions.forEach((key, value) {
        _userAnswers[int.parse(key.toString())] = value;
      });
    }
    _questionsFuture = _fetchQuestions();
  }

  Future<List<Map<String, dynamic>>> _fetchQuestions() async {
    if (widget.params['questions'] != null && (widget.params['questions'] as List).isNotEmpty) {
      return (widget.params['questions'] as List<dynamic>).cast<Map<String, dynamic>>();
    }
    
    String type = widget.params['type'] ?? 'pyq';
    String examId = widget.params['examId'] ?? '';
    String subject = widget.params['subject'] ?? '';
    String chapter = widget.params['chapter'] ?? '';
    
    if (examId.isEmpty) {
      final snapshot = await FirebaseFirestore.instance.collection('questions').where('type', isEqualTo: type).get();
      return snapshot.docs.map((e) => {'id': e.id, ...e.data()}).toList();
    } else {
      return await firebaseService.getQuestions(type, examId, subject, chapter);
    }
  }

  void _nextQuestion() {
    if (_currentIndex < _questions.length - 1) {
      _pageController.nextPage(duration: const Duration(milliseconds: 300), curve: Curves.easeInOut);
    }
  }

  void _prevQuestion() {
    if (_currentIndex > 0) {
      _pageController.previousPage(duration: const Duration(milliseconds: 300), curve: Curves.easeInOut);
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

  Color _getQuestionColor(int index) {
    if (_userAnswers[index] == null) {
      return Colors.grey; // Skipped
    }
    if (_questions.isEmpty) return Colors.grey;
    final question = _questions[index];
    final options = (question['options'] as List<dynamic>? ?? []).cast<String>();
    
    if (_isOptionCorrect(question, _userAnswers[index], options)) {
      return Colors.green; // Correct
    } else {
      return Colors.red; // Incorrect
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SafeArea(
        child: Column(
          children: [
            // Header
            Padding(
              padding: const EdgeInsets.all(16.0),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    'Solution',
                    style: TextStyle(fontSize: 18, fontWeight: FontWeight.w600, color: Theme.of(context).colorScheme.onSurface),
                  ),
                  IconButton(
                    icon: const Icon(Icons.close),
                    onPressed: () {
                      context.pop();
                    },
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
                          child: Builder(
                            builder: (context) {
                              final question = _questions.isNotEmpty && index < _questions.length ? _questions[index] : null;
                              final isInteger = question != null && (question['isInteger'] == true || (question['options'] as List? ?? []).isEmpty);
                              
                              String answerText = '${index + 1}';
                              if (_userAnswers[index] != null) {
                                if (isInteger) {
                                  answerText = '${index + 1} (${_userAnswers[index]})';
                                } else {
                                  int val = _userAnswers[index] is int ? _userAnswers[index] as int : 0;
                                  answerText = '${index + 1} ${String.fromCharCode(65 + val)}';
                                }
                              }

                              return Container(
                                width: 40,
                                margin: const EdgeInsets.symmetric(horizontal: 4, vertical: 8),
                                decoration: BoxDecoration(
                                  color: _getQuestionColor(index).withValues(alpha: 0.1),
                                  border: Border.all(color: _getQuestionColor(index), width: 1),
                                  borderRadius: BorderRadius.circular(4),
                                ),
                                alignment: Alignment.center,
                                child: Text(
                                  answerText,
                                  style: TextStyle(
                                    color: _getQuestionColor(index),
                                    fontWeight: FontWeight.w600,
                                  ),
                                ),
                              );
                            }
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
                          });
                        },
                        itemCount: _questions.length,
                        itemBuilder: (context, index) {
                          final question = _questions[index];
                          final options = (question['options'] as List<dynamic>? ?? []).cast<String>();
                          final correctAnswerIndex = options.indexOf(question['correctAnswer'] ?? '');
                          final userAnswer = _userAnswers[index];
                          
                          return SingleChildScrollView(
                        padding: const EdgeInsets.all(16.0),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                Text(
                                  'Question ${index + 1}',
                                  style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 16),
                                ),
                                Container(
                                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                                    decoration: BoxDecoration(
                                      color: Theme.of(context).colorScheme.surfaceContainerHighest,
                                      borderRadius: BorderRadius.circular(4),
                                      border: Border.all(color: Theme.of(context).dividerTheme.color ?? const Color(0xFFE5E7EB)),
                                    ),
                                  child: Text('Marks: ${question['marks'] ?? 4}', style: const TextStyle(fontSize: 12)),
                                ),
                              ],
                            ),
                            const SizedBox(height: 16),
                            Builder(
                              builder: (context) {
                                final isCorrectAnswer = _isOptionCorrect(question, _userAnswers[index], options);
                                final isSkipped = _userAnswers[index] == null;
                                final isInteger = question['isInteger'] == true || options.isEmpty;
                                
                                final statusStr = isSkipped ? 'Skipped' : (isCorrectAnswer ? 'Correct' : 'Incorrect');
                                final statusColor = isSkipped ? Colors.grey : (isCorrectAnswer ? Colors.green : Colors.red);
                                final statusIcon = isSkipped ? Icons.remove_circle_outline : (isCorrectAnswer ? Icons.check_circle : Icons.cancel);
                                
                                String yourAnsStr = 'None';
                                if (!isSkipped) {
                                  if (isInteger) {
                                    yourAnsStr = _userAnswers[index].toString();
                                  } else {
                                    int val = _userAnswers[index] is int ? _userAnswers[index] as int : 0;
                                    yourAnsStr = String.fromCharCode(65 + val);
                                  }
                                }

                                String correctAnsStr = '';
                                if (isInteger) {
                                  correctAnsStr = question['correctAnswer']?.toString() ?? 'N/A';
                                } else {
                                  correctAnsStr = String.fromCharCode(65 + correctAnswerIndex);
                                }

                                return Container(
                                  padding: const EdgeInsets.all(12),
                                  decoration: BoxDecoration(
                                    color: statusColor.withValues(alpha: 0.1),
                                    borderRadius: BorderRadius.circular(8),
                                    border: Border.all(color: statusColor.withValues(alpha: 0.5)),
                                  ),
                                  child: Row(
                                    children: [
                                      Icon(statusIcon, color: statusColor),
                                      const SizedBox(width: 8),
                                      Expanded(
                                        child: Text(
                                          'Your Answer: $yourAnsStr ($statusStr) | Correct: $correctAnsStr',
                                          style: TextStyle(fontWeight: FontWeight.bold, color: statusColor),
                                        ),
                                      ),
                                    ],
                                  ),
                                );
                              }
                            ),
                            const SizedBox(height: 24),
                            LatexText(
                              text: question['text'] ?? '',
                              style: TextStyle(fontSize: 16, color: Theme.of(context).colorScheme.onSurface),
                            ),
                            if (question['imageUrl'] != null && question['imageUrl'].toString().startsWith('http')) ...[
                              const SizedBox(height: 16),
                              Image.network(question['imageUrl']),
                            ],
                            const SizedBox(height: 32),
                            if (question['isInteger'] != true && options.isNotEmpty)
                              // Options
                              ...List.generate(options.length, (optIndex) {
                                final isCorrect = correctAnswerIndex == optIndex;
                                final isUserSelected = userAnswer == optIndex;
                                final optionImages = (question['optionImages'] as List<dynamic>? ?? []).cast<String>();
                                final optImageUrl = optionImages.length > optIndex ? optionImages[optIndex] : '';
                                
                                Color optColor = Theme.of(context).dividerTheme.color ?? const Color(0xFFE5E7EB);
                                Color bgColor = Theme.of(context).colorScheme.surface;
                                
                                if (isCorrect) {
                                  optColor = Colors.green;
                                  bgColor = Colors.green.withValues(alpha: 0.05);
                                } else if (isUserSelected && !isCorrect) {
                                  optColor = Colors.red;
                                  bgColor = Colors.red.withValues(alpha: 0.05);
                                }

                                return Container(
                                  width: double.infinity,
                                  margin: const EdgeInsets.only(bottom: 12),
                                  padding: const EdgeInsets.all(16),
                                  decoration: BoxDecoration(
                                    color: bgColor,
                                    border: Border.all(color: optColor, width: 1),
                                    borderRadius: BorderRadius.circular(8),
                                  ),
                                  child: Row(
                                    children: [
                                      Icon(
                                        isCorrect ? Icons.check_circle : (isUserSelected ? Icons.cancel : Icons.circle_outlined),
                                        color: optColor,
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
                                                  color: (isCorrect || isUserSelected) ? Theme.of(context).colorScheme.onSurface : Colors.grey,
                                                  fontWeight: (isCorrect || isUserSelected) ? FontWeight.w500 : FontWeight.normal,
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
                                );
                              }),
                            const SizedBox(height: 24),
                            const Text('Solution:', style: TextStyle(fontWeight: FontWeight.bold)),
                            const SizedBox(height: 8),
                            LatexText(
                              text: question['solution'] ?? question['explanation'] ?? 'No solution provided.',
                              style: TextStyle(
                                fontSize: 14,
                                color: Theme.of(context).colorScheme.onSurface,
                                height: 1.5,
                              ),
                            ),
                            if (question['solutionImageUrl'] != null && question['solutionImageUrl'].toString().startsWith('http'))
                               Padding(
                                 padding: const EdgeInsets.only(top: 8),
                                 child: Image.network(question['solutionImageUrl']),
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
                              child: Text('${index + 1}', style: TextStyle(color: _getQuestionColor(index), fontWeight: FontWeight.w600)),
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
      // Footer Navigation
      Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          border: Border(top: BorderSide(color: Theme.of(context).dividerTheme.color ?? const Color(0xFFE5E7EB), width: 0.5)),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            IconButton(
              icon: const Icon(Icons.chevron_left),
              onPressed: _currentIndex > 0 ? _prevQuestion : null,
            ),
            Text('${_questions.isNotEmpty ? _currentIndex + 1 : 0} / ${_questions.length}'),
            IconButton(
              icon: const Icon(Icons.chevron_right),
              onPressed: _questions.isNotEmpty && _currentIndex < _questions.length - 1 ? _nextQuestion : null,
            ),
          ],
        ),
      ),
          ],
        ),
      ),
    );
  }
}
