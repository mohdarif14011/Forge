import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../../../widgets/animated_back_button.dart';
import '../../../widgets/section_title.dart';
import '../../../core/theme.dart';
import '../../../core/services/firebase_service.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class TestSeriesListScreen extends StatefulWidget {
  final Map<String, dynamic> params;
  const TestSeriesListScreen({super.key, required this.params});

  @override
  State<TestSeriesListScreen> createState() => _TestSeriesListScreenState();
}

class _TestSeriesListScreenState extends State<TestSeriesListScreen> {
  List<Map<String, dynamic>> _testSeries = [];
  Map<String, Map<String, dynamic>> _userAttempts = {};
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadTestSeries();
  }

  Future<void> _loadTestSeries() async {
    final exam = widget.params['exam'];
    if (exam == null) {
      setState(() => _isLoading = false);
      return;
    }
    
    try {
      final tests = await firebaseService.getTestSeries(exam['id']);
      if (mounted) {
        setState(() {
          _testSeries = tests;
          // Don't turn off loading yet, try fetching attempts
        });
      }
      
      final user = FirebaseAuth.instance.currentUser;
      final Map<String, Map<String, dynamic>> attempts = {};
      
      if (user != null) {
        final attemptsSnapshot = await FirebaseFirestore.instance.collection('test_results')
            .where('userId', isEqualTo: user.uid)
            .where('examId', isEqualTo: exam['id'])
            .where('type', isEqualTo: 'test_series')
            .get();
            
        for (var doc in attemptsSnapshot.docs) {
          final data = doc.data();
          final testSeriesId = data['testSeriesId'] as String?;
          if (testSeriesId != null) {
            attempts[testSeriesId] = {
              'id': doc.id,
              ...data,
            };
          }
        }
      }
      
      // Calculate ranking client-side for appeared tests
      if (attempts.isNotEmpty) {
        for (var testSeriesId in attempts.keys) {
          final allResultsSnapshot = await FirebaseFirestore.instance.collection('test_results')
              .where('testSeriesId', isEqualTo: testSeriesId)
              .get();
          final docs = allResultsSnapshot.docs;
          docs.sort((a, b) => (b['score'] as num? ?? 0).compareTo(a['score'] as num? ?? 0));
          int rank = -1;
          for (int i = 0; i < docs.length; i++) {
            if (docs[i]['userId'] == user?.uid) {
              rank = i + 1;
              break;
            }
          }
          if (rank != -1) {
            attempts[testSeriesId]!['rank'] = rank;
            attempts[testSeriesId]!['totalSubmissions'] = docs.length;
          }
        }
      }

      if (mounted) {
        setState(() {
          _userAttempts = attempts;
          _isLoading = false;
        });
      }
    } catch (e) {
      debugPrint('Error loading test series: $e');
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final exam = widget.params['exam'] ?? {};
    return Scaffold(
      body: SafeArea(
        child: DefaultTabController(
          length: 2,
          child: Column(
            children: [
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 12.0),
              child: Row(
                children: [
                  const AnimatedBackButton(),
                  const Expanded(
                    child: Center(
                      child: SectionTitle(title: 'Test Series'),
                    ),
                  ),
                  const SizedBox(width: 40),
                ],
              ),
            ),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 8.0),
              child: Container(
                height: 48,
                padding: const EdgeInsets.all(4),
                decoration: BoxDecoration(
                  color: Theme.of(context).colorScheme.surfaceContainerHighest,
                  borderRadius: BorderRadius.circular(24.0),
                ),
                child: TabBar(
                  indicatorSize: TabBarIndicatorSize.tab,
                  dividerColor: Colors.transparent,
                  indicator: BoxDecoration(
                    borderRadius: BorderRadius.circular(20.0),
                    color: AppTheme.primaryBlue,
                    boxShadow: [
                      BoxShadow(
                        color: AppTheme.primaryBlue.withValues(alpha: 0.2),
                        blurRadius: 8,
                        offset: const Offset(0, 2),
                      )
                    ]
                  ),
                  labelColor: Colors.white,
                  unselectedLabelColor: Colors.grey.shade600,
                  labelStyle: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14),
                  unselectedLabelStyle: const TextStyle(fontWeight: FontWeight.w600, fontSize: 14),
                  tabs: const [
                    Tab(text: 'Available'),
                    Tab(text: 'Appeared'),
                  ],
                ),
              ),
            ),
            Expanded(
              child: _isLoading
                ? const Center(child: CircularProgressIndicator())
                : TabBarView(
                    children: [
                      _buildTestList(exam, _testSeries.where((t) => _userAttempts[t['id']] == null).toList()),
                      _buildTestList(exam, _testSeries.where((t) => _userAttempts[t['id']] != null).toList()),
                    ],
                  ),
            ),
          ],
        ),
      ),
    ));
  }

  Widget _buildTestList(Map<String, dynamic> exam, List<Map<String, dynamic>> testsToDisplay) {
    if (testsToDisplay.isEmpty) {
      return const Center(child: Text("No tests found in this category."));
    }
    return ListView.builder(
      padding: const EdgeInsets.all(16.0),
      itemCount: testsToDisplay.length,
      itemBuilder: (context, index) {
        final test = testsToDisplay[index];
        final attempt = _userAttempts[test['id']];
        final appeared = attempt != null;

        return GestureDetector(
          onTap: () {
            if (appeared) {
              context.push('/test/result', extra: {
                ...attempt,
                'type': 'test_series',
                'questions': [],
              });
            } else {
              context.push('/test/start', extra: {
                'test': test,
                'type': 'test_series',
                'examId': test['examId'],
                'examName': test['examName'] ?? exam['name'],
                'totalTime': (test['time'] as num?)?.toInt() != null ? (test['time'] as num).toInt() * 60 : 180 * 60,
              });
            }
          },
          child: Container(
            margin: const EdgeInsets.only(bottom: 16),
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: Theme.of(context).colorScheme.surface,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(
                color: appeared ? Colors.green.withValues(alpha: 0.3) : Theme.of(context).dividerTheme.color ?? const Color(0xFFE5E7EB), 
                width: appeared ? 1.0 : 0.5
              ),
              boxShadow: appeared ? [
                BoxShadow(
                  color: Colors.green.withValues(alpha: 0.03),
                  blurRadius: 8,
                  offset: const Offset(0, 2),
                )
              ] : null,
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Row(
                      children: [
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                          decoration: BoxDecoration(
                            color: appeared 
                                ? Colors.green.withValues(alpha: 0.1) 
                                : AppTheme.primaryBlue.withValues(alpha: 0.1),
                            borderRadius: BorderRadius.circular(4),
                          ),
                          child: Text(
                            appeared ? 'APPEARED' : 'MOCK TEST',
                            style: TextStyle(
                              fontSize: 10,
                              fontWeight: FontWeight.bold,
                              color: appeared ? Colors.green : AppTheme.primaryBlue,
                            ),
                          ),
                        ),
                        if (appeared && attempt['score'] != null) ...[
                          const SizedBox(width: 8),
                          Text(
                            'Score: ${attempt['score']}/${attempt['maxScore'] ?? 300}',
                            style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: Theme.of(context).colorScheme.onSurface),
                          ),
                        ],
                        if (appeared && attempt['rank'] != null) ...[
                          const SizedBox(width: 12),
                          const Icon(Icons.emoji_events, size: 14, color: Colors.orange),
                          const SizedBox(width: 2),
                          Text(
                            'Rank: #${attempt['rank']}/${attempt['totalSubmissions']}',
                            style: const TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: Colors.orange),
                          ),
                        ],
                      ],
                    ),
                    const Icon(Icons.bookmark_border, size: 20, color: Colors.grey),
                  ],
                ),
                const SizedBox(height: 12),
                Text(
                  test['name'],
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.w600,
                    color: Theme.of(context).colorScheme.onSurface,
                  ),
                ),
                const SizedBox(height: 16),
                Row(
                  children: [
                    const Icon(Icons.help_outline, size: 16, color: Colors.grey),
                    const SizedBox(width: 4),
                    Text(
                      '${test['questions'] is List ? (test['questions'] as List).length : 0} Qs', 
                      style: const TextStyle(color: Colors.grey, fontSize: 13)
                    ),
                    const SizedBox(width: 16),
                    const Icon(Icons.access_time, size: 16, color: Colors.grey),
                    const SizedBox(width: 4),
                    Text('${test['time'] ?? 180} mins', style: const TextStyle(color: Colors.grey, fontSize: 13)),
                    const Spacer(),
                    Icon(
                      Icons.chevron_right, 
                      color: appeared ? Colors.green : Theme.of(context).primaryColor
                    ),
                  ],
                ),
              ],
            ),
          ),
        );
      },
    );
  }
}
