import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../../widgets/animated_back_button.dart';
import '../../widgets/app_button.dart';
import '../../widgets/section_title.dart';
import '../../core/theme.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

class TestResultScreen extends StatelessWidget {
  final Map<String, dynamic> params;
  const TestResultScreen({super.key, this.params = const {}});

  String _formatTime(int seconds) {
    if (seconds == 0) return '0s';
    int h = seconds ~/ 3600;
    int m = (seconds % 3600) ~/ 60;
    int s = seconds % 60;
    if (h > 0) return '${h}h ${m}m';
    if (m > 0) return '${m}m ${s}s';
    return '${s}s';
  }

  @override
  Widget build(BuildContext context) {
    final questions = (params['questions'] as List<dynamic>?)?.cast<Map<String, dynamic>>() ?? [];
    final selectedOptions = (params['selectedOptions'] as Map<int, dynamic>?)?.map((key, value) => MapEntry(key, value)) ?? {};
    
    int totalQuestions = questions.length;
    int correct = 0;
    int incorrect = 0;
    int skipped = 0;
    int score = 0;
    int maxScore = 0;

    int timeSpent = (params['timeSpent'] as num?)?.toInt() ?? 0;
    int totalTime = (params['totalTime'] as num?)?.toInt() ?? 180 * 60;
    int avgTime = totalQuestions > 0 ? timeSpent ~/ totalQuestions : 0;

    Map<String, Map<String, int>> chapterStats = {};

    for (int i = 0; i < totalQuestions; i++) {
      final q = questions[i];
      final marks = (q['marks'] as num?)?.toInt() ?? 4;
      final negMarks = (q['negativeMarks'] as num?)?.toInt() ?? -1;
      
      maxScore += marks;
      
      final selected = selectedOptions[i];
      String chapter = q['chapter'] ?? 'Unknown Chapter';
      if (!chapterStats.containsKey(chapter)) {
        chapterStats[chapter] = {'total': 0, 'correct': 0, 'incorrect': 0, 'skipped': 0};
      }
      
      chapterStats[chapter]!['total'] = chapterStats[chapter]!['total']! + 1;

      if (selected == null) {
        skipped++;
        chapterStats[chapter]!['skipped'] = chapterStats[chapter]!['skipped']! + 1;
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
          chapterStats[chapter]!['correct'] = chapterStats[chapter]!['correct']! + 1;
        } else {
          incorrect++;
          score += negMarks;
          chapterStats[chapter]!['incorrect'] = chapterStats[chapter]!['incorrect']! + 1;
        }
      }
    }
    
    // For Appeared Test fetching fallback (if directly loaded from DB)
    if (params.containsKey('score') && questions.isEmpty) {
      score = (params['score'] as num?)?.toInt() ?? 0;
      maxScore = (params['maxScore'] as num?)?.toInt() ?? 0;
      correct = (params['correct'] as num?)?.toInt() ?? 0;
      incorrect = (params['incorrect'] as num?)?.toInt() ?? 0;
      skipped = (params['skipped'] as num?)?.toInt() ?? 0;
      totalQuestions = correct + incorrect + skipped;
      timeSpent = (params['timeSpent'] as num?)?.toInt() ?? 0;
      totalTime = (params['totalTime'] as num?)?.toInt() ?? 180 * 60;
      avgTime = totalQuestions > 0 ? timeSpent ~/ totalQuestions : 0;
    }

    double accuracy = (correct + incorrect) > 0 ? (correct / (correct + incorrect)) * 100 : 0.0;

    return PopScope(
      canPop: false,
      onPopInvokedWithResult: (didPop, result) {
        if (didPop) return;
        context.go('/home');
      },
      child: Scaffold(
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      body: SafeArea(
        child: Column(
          children: [
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 12.0),
              child: Row(
                children: [
                  AnimatedBackButton(onPressed: () => context.go('/home')),
                  const Expanded(
                    child: Center(
                      child: SectionTitle(title: 'Result Summary'),
                    ),
                  ),
                  const SizedBox(width: 40),
                ],
              ),
            ),
            Expanded(
              child: SingleChildScrollView(
                padding: const EdgeInsets.all(16.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    // Main Score Card
                    Container(
                      padding: const EdgeInsets.all(20),
                      decoration: BoxDecoration(
                        color: Theme.of(context).colorScheme.surface,
                        borderRadius: BorderRadius.circular(16),
                        border: Border.all(color: Theme.of(context).dividerTheme.color ?? const Color(0xFFE5E7EB), width: 0.5),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withValues(alpha: 0.03),
                            blurRadius: 10,
                            offset: const Offset(0, 4),
                          )
                        ],
                      ),
                      child: Column(
                        children: [
                           Text(
                            params['testName'] ?? params['test']?['name'] ?? params['examName'] ?? params['exam']?['name'] ?? 'Mock Test',
                            style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Theme.of(context).colorScheme.onSurface),
                            textAlign: TextAlign.center,
                          ),
                          const SizedBox(height: 8),
                          if (params['type'] == 'test_series') ...[
                            Container(
                              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                              decoration: BoxDecoration(
                                color: AppTheme.primaryBlue.withValues(alpha: 0.1),
                                borderRadius: BorderRadius.circular(4),
                              ),
                              child: Text(
                                'Exam: ${params['examName'] ?? params['exam']?['name'] ?? 'EdTech Exam'}',
                                style: const TextStyle(color: AppTheme.primaryBlue, fontWeight: FontWeight.bold, fontSize: 12),
                              ),
                            ),
                            const SizedBox(height: 8),
                          ] else ...[
                            Text(
                              '${params['year'] ?? ''} ${params['date'] ?? ''} ${params['shift'] ?? ''}',
                              style: const TextStyle(color: Colors.grey, fontSize: 13),
                            ),
                            const SizedBox(height: 8),
                          ],
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                            children: [
                              Column(
                                children: [
                                  const Text('Score', style: TextStyle(color: Colors.grey, fontSize: 14)),
                                  const SizedBox(height: 4),
                                  Text('$score', style: const TextStyle(fontSize: 28, fontWeight: FontWeight.bold, color: AppTheme.primaryBlue)),
                                  Text('/ $maxScore', style: const TextStyle(color: Colors.grey, fontSize: 12)),
                                ],
                              ),
                              Container(width: 1, height: 50, color: Theme.of(context).dividerTheme.color ?? const Color(0xFFE5E7EB)),
                              Column(
                                children: [
                                  const Text('Accuracy', style: TextStyle(color: Colors.grey, fontSize: 14)),
                                  const SizedBox(height: 4),
                                  Text('${accuracy.toStringAsFixed(1)}%', style: const TextStyle(fontSize: 24, fontWeight: FontWeight.bold, color: Colors.green)),
                                ],
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 16),
                    
                    // Action Buttons
                    Row(
                      children: [
                        Expanded(
                          child: AppButton(
                            text: 'Reattempt',
                            type: AppButtonType.outlined,
                            onPressed: () => context.push('/test/start', extra: params),
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: AppButton(
                            text: 'View Solution',
                            onPressed: () => context.push('/test/solution', extra: params),
                          ),
                        ),
                      ],
                    ),
                    
                    const SizedBox(height: 24),
                    Text('Time Analytics', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: Theme.of(context).colorScheme.onSurface)),
                    const SizedBox(height: 12),
                    
                    // Time Stats
                    Row(
                      children: [
                        _buildStatBox('Allotted Time', _formatTime(totalTime), Icons.timer_outlined, Colors.purple, context),
                        const SizedBox(width: 12),
                        _buildStatBox('Time Used', _formatTime(timeSpent), Icons.timelapse, Colors.orange, context),
                        const SizedBox(width: 12),
                        _buildStatBox('Avg. Time/Q', _formatTime(avgTime), Icons.speed, Colors.blue, context),
                      ],
                    ),

                    const SizedBox(height: 24),
                    Text('Question Stats', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: Theme.of(context).colorScheme.onSurface)),
                    const SizedBox(height: 12),
                    
                    Row(
                      children: [
                        _buildStatBox('Correct', '$correct', Icons.check_circle_outline, Colors.green, context),
                        const SizedBox(width: 12),
                        _buildStatBox('Incorrect', '$incorrect', Icons.cancel_outlined, Colors.red, context),
                        const SizedBox(width: 12),
                        _buildStatBox('Skipped', '$skipped', Icons.remove_circle_outline, Colors.grey, context),
                      ],
                    ),

                    if (chapterStats.isNotEmpty) ...[
                      const SizedBox(height: 24),
                      Text('Chapter-wise Performance', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: Theme.of(context).colorScheme.onSurface)),
                      const SizedBox(height: 12),
                      ...chapterStats.entries.map((e) {
                        final chap = e.key;
                        final stats = e.value;
                        final c = stats['correct']!;
                        final i = stats['incorrect']!;
                        final s = stats['skipped']!;
                        final t = stats['total']!;
                        final acc = (c + i) > 0 ? (c / (c + i)) * 100 : 0.0;
                        
                        return Container(
                          margin: const EdgeInsets.only(bottom: 12),
                          padding: const EdgeInsets.all(16),
                          decoration: BoxDecoration(
                            color: Theme.of(context).colorScheme.surface,
                            borderRadius: BorderRadius.circular(12),
                            border: Border.all(color: Theme.of(context).dividerTheme.color ?? const Color(0xFFE5E7EB), width: 0.5),
                          ),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(chap, style: TextStyle(fontWeight: FontWeight.w600, fontSize: 14, color: Theme.of(context).colorScheme.onSurface)),
                              const SizedBox(height: 12),
                              Row(
                                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                children: [
                                  _buildMiniStat('Correct', '$c', Colors.green),
                                  _buildMiniStat('Incorrect', '$i', Colors.red),
                                  _buildMiniStat('Skipped', '$s', Colors.grey),
                                  _buildMiniStat('Acc.', '${acc.toStringAsFixed(0)}%', AppTheme.primaryBlue),
                                ],
                              ),
                            ],
                          ),
                        );
                      }),
                    ],
                    if (params['type'] == 'test_series') ...[
                      const SizedBox(height: 24),
                      Text('Leaderboard & Rankings', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: Theme.of(context).colorScheme.onSurface)),
                      const SizedBox(height: 12),
                      _buildLeaderboardSection(context),
                    ]
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    ));
  }

  Widget _buildLeaderboardSection(BuildContext context) {
    final testSeriesId = params['test']?['id'] ?? params['testSeriesId'];
    if (testSeriesId == null) {
      return const Center(
        child: Padding(
          padding: EdgeInsets.all(16.0),
          child: Text('No ranking data available.'),
        ),
      );
    }
    
    final currentUser = FirebaseAuth.instance.currentUser;
    
    return StreamBuilder<QuerySnapshot>(
      stream: FirebaseFirestore.instance.collection('test_results')
          .where('testSeriesId', isEqualTo: testSeriesId)
          .snapshots(),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(child: CircularProgressIndicator());
        }
        
        if (snapshot.hasError) {
          return Center(
            child: Padding(
              padding: const EdgeInsets.all(16.0),
              child: Text('Error loading leaderboard: ${snapshot.error}'),
            ),
          );
        }
        
        final List<QueryDocumentSnapshot> docs = List.from(snapshot.data?.docs ?? []);
        docs.sort((a, b) => (b['score'] as num? ?? 0).compareTo(a['score'] as num? ?? 0));
        
        if (docs.isEmpty) {
          return const Center(
            child: Padding(
              padding: EdgeInsets.all(16.0),
              child: Text('No rankings available yet. Be the first!'),
            ),
          );
        }
        
        int userRank = -1;
        for (int i = 0; i < docs.length; i++) {
          if (docs[i]['userId'] == currentUser?.uid) {
            userRank = i + 1;
            break;
          }
        }
        
        return Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: Theme.of(context).colorScheme.surface,
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: Theme.of(context).dividerTheme.color ?? const Color(0xFFE5E7EB), width: 0.5),
          ),
          child: Column(
            children: [
              if (userRank != -1) ...[
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: AppTheme.primaryBlue.withValues(alpha: 0.05),
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(color: AppTheme.primaryBlue.withValues(alpha: 0.2), width: 0.5),
                  ),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      const Row(
                        children: [
                          Icon(Icons.emoji_events, color: Colors.orange, size: 20),
                          SizedBox(width: 8),
                          Text('Your Rank:', style: TextStyle(fontWeight: FontWeight.w600)),
                        ],
                      ),
                      Text('#$userRank / ${docs.length}', style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 18, color: AppTheme.primaryBlue)),
                    ],
                  ),
                ),
                const SizedBox(height: 16),
              ],
              
              ElevatedButton.icon(
                onPressed: () => _showRankSheet(context, docs, currentUser?.uid),
                icon: const Icon(Icons.leaderboard, size: 18),
                label: const Text('View Full Ranking List'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppTheme.primaryBlue,
                  foregroundColor: Colors.white,
                  minimumSize: const Size(double.infinity, 44),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                  elevation: 0,
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  void _showRankSheet(BuildContext context, List<QueryDocumentSnapshot> docs, String? currentUserId) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) {
        return DraggableScrollableSheet(
          initialChildSize: 0.75,
          maxChildSize: 0.95,
          minChildSize: 0.5,
          expand: false,
          builder: (context, scrollController) {
            return Column(
              children: [
                const SizedBox(height: 12),
                Container(
                  width: 40,
                  height: 4,
                  decoration: BoxDecoration(color: Colors.grey[300], borderRadius: BorderRadius.circular(2)),
                ),
                const SizedBox(height: 16),
                Text('Leaderboard', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Theme.of(context).colorScheme.onSurface)),
                const SizedBox(height: 8),
                Text(
                  '${docs.length} submissions',
                  style: const TextStyle(color: Colors.grey, fontSize: 13),
                ),
                const SizedBox(height: 16),
                Expanded(
                  child: ListView.builder(
                    controller: scrollController,
                    itemCount: docs.length,
                    itemBuilder: (context, index) {
                      final doc = docs[index];
                      final isCurrentUser = doc['userId'] == currentUserId;
                      final rank = index + 1;
                      final score = doc['score'] ?? 0;
                      
                      final String userName = doc['userName'] ?? 'Student';
                      
                      return Container(
                        margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
                        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                        decoration: BoxDecoration(
                          color: isCurrentUser ? AppTheme.primaryBlue.withValues(alpha: 0.05) : Colors.transparent,
                          borderRadius: BorderRadius.circular(12),
                          border: isCurrentUser ? Border.all(color: AppTheme.primaryBlue.withValues(alpha: 0.2)) : null,
                        ),
                        child: Row(
                           children: [
                             // Rank badge
                             Container(
                               width: 32,
                               height: 32,
                               decoration: BoxDecoration(
                                 color: rank == 1 ? Colors.amber[100] : rank == 2 ? Colors.grey[200] : rank == 3 ? Colors.brown[100] : Colors.transparent,
                                 shape: BoxShape.circle,
                               ),
                               alignment: Alignment.center,
                               child: Text(
                                 '$rank',
                                 style: TextStyle(
                                   fontWeight: FontWeight.bold,
                                   color: rank == 1 ? Colors.orange : rank == 2 ? Colors.grey[700] : rank == 3 ? Colors.brown : Colors.grey,
                                 ),
                               ),
                             ),
                             const SizedBox(width: 16),
                             Expanded(
                               child: Column(
                                 crossAxisAlignment: CrossAxisAlignment.start,
                                 children: [
                                   Text(
                                     isCurrentUser ? 'You ($userName)' : userName,
                                     style: TextStyle(
                                       fontWeight: isCurrentUser ? FontWeight.bold : FontWeight.w500,
                                       color: isCurrentUser ? AppTheme.primaryBlue : Theme.of(context).colorScheme.onSurface,
                                     ),
                                   ),
                                   Text(
                                     'Accuracy: ${(doc['correct'] ?? 0) + (doc['incorrect'] ?? 0) > 0 ? (((doc['correct'] ?? 0) / ((doc['correct'] ?? 0) + (doc['incorrect'] ?? 0))) * 100).toStringAsFixed(0) : '0'}%',
                                     style: const TextStyle(fontSize: 12, color: Colors.grey),
                                   )
                                 ],
                               ),
                             ),
                             Text(
                               '$score Pts',
                               style: TextStyle(fontWeight: FontWeight.bold, color: Theme.of(context).colorScheme.onSurface),
                             ),
                           ],
                         ),
                      );
                    },
                  ),
                ),
              ],
            );
          },
        );
      },
    );
  }

  Widget _buildStatBox(String title, String value, IconData icon, Color color, BuildContext context) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 8),
        decoration: BoxDecoration(
          color: Theme.of(context).colorScheme.surface,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: Theme.of(context).dividerTheme.color ?? const Color(0xFFE5E7EB), width: 0.5),
        ),
        child: Column(
          children: [
            Icon(icon, color: color, size: 24),
            const SizedBox(height: 8),
            Text(value, style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Theme.of(context).colorScheme.onSurface)),
            const SizedBox(height: 4),
            Text(title, style: const TextStyle(color: Colors.grey, fontSize: 11), textAlign: TextAlign.center),
          ],
        ),
      ),
    );
  }
  
  Widget _buildMiniStat(String label, String val, Color color) {
    return Column(
      children: [
        Text(val, style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16, color: color)),
        const SizedBox(height: 2),
        Text(label, style: const TextStyle(fontSize: 10, color: Colors.grey)),
      ],
    );
  }
}
