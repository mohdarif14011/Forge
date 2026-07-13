import 'dart:ui';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../core/theme.dart';
import '../../core/theme_provider.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  final int _currentIndex = 0;

  @override
  void initState() {
    super.initState();
  }

  @override
  Widget build(BuildContext context) {
    final bool isDark = Theme.of(context).brightness == Brightness.dark;

    return Scaffold(
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      appBar: AppBar(
        leading: Builder(
          builder: (context) => IconButton(
            icon: const Icon(CupertinoIcons.bars),
            onPressed: () {
              context
                  .findRootAncestorStateOfType<ScaffoldState>()
                  ?.openDrawer();
            },
          ),
        ),
        actions: [
          StreamBuilder<DocumentSnapshot>(
              stream: FirebaseFirestore.instance
                  .collection('users')
                  .doc(FirebaseAuth.instance.currentUser?.uid)
                  .snapshots(),
              builder: (context, snapshot) {
                final data =
                    snapshot.data?.data() as Map<String, dynamic>? ?? {};
                final hasAppSub = data['hasAppSubscription'] as bool? ?? false;

                return Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Consumer(
                      builder: (context, ref, child) {
                        final isDark =
                            ref.watch(themeProvider) == ThemeMode.dark;
                        return IconButton(
                          icon: AnimatedSwitcher(
                            duration: const Duration(milliseconds: 300),
                            transitionBuilder:
                                (Widget child, Animation<double> animation) {
                              return RotationTransition(
                                turns: child.key == const ValueKey('dark')
                                    ? Tween<double>(begin: 0.5, end: 1)
                                        .animate(animation)
                                    : Tween<double>(begin: 0.5, end: 1)
                                        .animate(animation),
                                child: FadeTransition(
                                    opacity: animation, child: child),
                              );
                            },
                            child: Icon(
                              isDark
                                  ? CupertinoIcons.moon_fill
                                  : CupertinoIcons.sun_max_fill,
                              key: ValueKey(isDark ? 'dark' : 'light'),
                              color: Theme.of(context).colorScheme.onSurface,
                              size: 20,
                            ),
                          ),
                          onPressed: () {
                            ref.read(themeProvider.notifier).toggleTheme();
                          },
                        );
                      },
                    ),
                    Container(
                      margin:
                          const EdgeInsets.only(top: 12, bottom: 12, right: 4),
                      padding: const EdgeInsets.symmetric(
                          horizontal: 10, vertical: 4),
                      alignment: Alignment.center,
                      decoration: BoxDecoration(
                          gradient: hasAppSub
                              ? const LinearGradient(
                                  colors: [Colors.amber, Colors.orange])
                              : const LinearGradient(
                                  colors: [Colors.grey, Colors.blueGrey]),
                          borderRadius: BorderRadius.circular(12),
                          boxShadow: [
                            BoxShadow(
                              color: (hasAppSub ? Colors.amber : Colors.grey)
                                  .withValues(alpha: 0.3),
                              blurRadius: 4,
                              offset: const Offset(0, 2),
                            )
                          ]),
                      child: Text(
                        hasAppSub ? 'GOLD' : 'FREE',
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 10,
                          fontWeight: FontWeight.bold,
                          letterSpacing: 0.5,
                        ),
                      ),
                    ),
                  ],
                );
              }),
          StreamBuilder<QuerySnapshot>(
            stream: FirebaseFirestore.instance
                .collection('notifications')
                .limit(1)
                .snapshots(),
            builder: (context, snapshot) {
              final hasNotifications =
                  snapshot.hasData && snapshot.data!.docs.isNotEmpty;
              return IconButton(
                icon: Stack(
                  children: [
                    const Icon(CupertinoIcons.bell),
                    if (hasNotifications)
                      Positioned(
                        right: 0,
                        top: 0,
                        child: Container(
                          width: 8,
                          height: 8,
                          decoration: const BoxDecoration(
                            color: Colors.red,
                            shape: BoxShape.circle,
                          ),
                        ),
                      ),
                  ],
                ),
                onPressed: () => context.push('/notifications'),
              );
            },
          ),
        ],
        elevation: 0,
        backgroundColor: Colors.transparent,
      ),
      extendBody: true, // For floating navbar
      extendBodyBehindAppBar: true,
      body: Stack(
        children: [
          // Background Gradient
          Positioned.fill(
            child: Container(
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                  colors: isDark
                      ? [
                          Theme.of(context).scaffoldBackgroundColor,
                          Theme.of(context)
                              .colorScheme
                              .surfaceContainerHighest
                              .withValues(alpha: 0.3)
                        ]
                      : [
                          Theme.of(context).scaffoldBackgroundColor,
                          Theme.of(context)
                              .colorScheme
                              .surfaceContainerHighest
                              .withValues(alpha: 0.3)
                        ],
                ),
              ),
            ),
          ),

          // Decorator Orbs
          Positioned(
            top: -50,
            right: -50,
            child: Container(
              width: 200,
              height: 200,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: Theme.of(context).primaryColor.withValues(alpha: 0.05),
              ),
            ),
          ),

          SafeArea(
            bottom: false,
            child: Padding(
              padding: const EdgeInsets.fromLTRB(
                  16.0, 0.0, 16.0, 100.0), // bottom padding for floating navbar
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  // Goal Setting Section
                  const GoalSettingSection(),
                  const SizedBox(height: 8),

                  Expanded(
                    child: StreamBuilder<QuerySnapshot>(
                      stream: FirebaseFirestore.instance
                          .collection('test_results')
                          .where('userId', isEqualTo: FirebaseAuth.instance.currentUser?.uid)
                          .snapshots(),
                      builder: (context, testResultsSnapshot) {
                        final resultsDocs = testResultsSnapshot.data?.docs ?? [];
                        
                        final mockTestsSolved = resultsDocs.where((doc) {
                          final data = doc.data() as Map<String, dynamic>;
                          final type = data['type'] ?? '';
                          final isCustom = data['isCustom'] == true;
                          return type == 'pyq' && !isCustom;
                        }).length;

                        final testSeriesAppeared = resultsDocs.where((doc) {
                          final data = doc.data() as Map<String, dynamic>;
                          final type = data['type'] ?? '';
                          return type == 'test_series';
                        }).length;

                        return Column(
                          crossAxisAlignment: CrossAxisAlignment.stretch,
                          children: [
                            // Practice Card
                            Expanded(
                              flex: 12,
                              child: _buildPremiumCard(
                                context: context,
                                topText: 'Extensive Problem Sets • $mockTestsSolved Solved',
                                title: 'PYQ Mock Test',
                                bottomTitle: 'Start Mock Test',
                                buttonText1: 'Start',
                                icon: CupertinoIcons.book_solid,
                                bgColor: AppTheme.primaryBlue,
                                onTap1: () => context.push('/pyq/exams'),
                              ),
                            ),
                            const SizedBox(height: 16),

                            // Custom Test Card
                            Expanded(
                              flex: 11,
                              child: StreamBuilder<DocumentSnapshot>(
                                  stream: FirebaseFirestore.instance
                                      .collection('user_stats')
                                      .doc(FirebaseAuth.instance.currentUser?.uid)
                                      .snapshots(),
                                  builder: (context, snapshot) {
                                    final data =
                                        snapshot.data?.data() as Map<String, dynamic>? ??
                                            {};
                                    final solvedCount = data['total_solved'] as int? ?? 0;
                                    return _buildPremiumCard(
                                      context: context,
                                      topText:
                                          'Subjectwise & Chapterwise • $solvedCount Qs Solved',
                                      title: 'Practice by creating test',
                                      bottomTitle: 'Create Test',
                                      buttonText1: 'PYQ',
                                      buttonText2: 'Extra Qs',
                                      icon: CupertinoIcons.layers_fill,
                                      bgColor: const Color(
                                          0xFF00C853), // Green for custom tests
                                      onTap1: () => context
                                          .push('/ct/exams', extra: {'type': 'pyq'}),
                                      onTap2: () => context
                                          .push('/ct/exams', extra: {'type': 'extra'}),
                                    );
                                  }),
                            ),
                            const SizedBox(height: 16),

                            // Test Series Card
                            Expanded(
                              flex: 11,
                              child: _buildPremiumCard(
                                context: context,
                                topText: 'All India Mock Tests • $testSeriesAppeared Attempted',
                                title: 'Test Series',
                                bottomTitle: 'Mock Tests',
                                buttonText1: 'View',
                                icon: CupertinoIcons.star_circle_fill,
                                bgColor:
                                    const Color(0xFF6200EA), // Deep purple for mock tests
                                onTap1: () => context.push('/test_series/exams'),
                              ),
                            ),
                          ],
                        );
                      }
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildPremiumCard({
    required BuildContext context,
    required String topText,
    required String title,
    required String bottomTitle,
    required String buttonText1,
    String? buttonText2,
    required IconData icon,
    required Color bgColor,
    required VoidCallback onTap1,
    VoidCallback? onTap2,
  }) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final cardColor = isDark
        ? Theme.of(context)
            .colorScheme
            .surfaceContainerHighest
            .withValues(alpha: 0.3)
        : Theme.of(context).colorScheme.surface;
    final borderColor = isDark
        ? Colors.white.withValues(alpha: 0.05)
        : Theme.of(context).dividerTheme.color ?? const Color(0xFFE5E7EB);

    return Container(
      decoration: BoxDecoration(
        color: cardColor,
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: borderColor, width: 1.5),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: isDark ? 0.2 : 0.05),
            blurRadius: 24,
            spreadRadius: 0,
            offset: const Offset(0, 12),
          )
        ],
      ),
      child: Stack(
        children: [
          Positioned(
            right: -20,
            top: -20,
            child: Container(
              width: 120,
              height: 140,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                gradient: LinearGradient(
                  colors: [
                    bgColor.withValues(alpha: 0.2),
                    bgColor.withValues(alpha: 0.0)
                  ],
                  begin: Alignment.topRight,
                  end: Alignment.bottomLeft,
                ),
              ),
            ),
          ),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(
                child: Padding(
                  padding: const EdgeInsets.symmetric(
                      horizontal: 24.0, vertical: 20.0),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 12, vertical: 6),
                        decoration: BoxDecoration(
                          color: bgColor.withValues(alpha: 0.1),
                          borderRadius: BorderRadius.circular(12),
                          border:
                              Border.all(color: bgColor.withValues(alpha: 0.3)),
                        ),
                        child: Text(
                          topText.toUpperCase(),
                          style: TextStyle(
                              fontWeight: FontWeight.bold,
                              fontSize: 10,
                              color: bgColor,
                              letterSpacing: 1.0),
                        ),
                      ),
                      const SizedBox(height: 8),
                      Text(
                        title,
                        style: TextStyle(
                          fontSize: 22,
                          fontWeight: FontWeight.w900,
                          height: 1.1,
                          letterSpacing: -0.5,
                          color: Theme.of(context).colorScheme.onSurface,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              ClipRRect(
                borderRadius: const BorderRadius.only(
                  bottomLeft: Radius.circular(24),
                  bottomRight: Radius.circular(24),
                ),
                child: BackdropFilter(
                  filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),
                  child: Container(
                    decoration: BoxDecoration(
                      color: Theme.of(context)
                          .colorScheme
                          .surface
                          .withValues(alpha: isDark ? 0.3 : 0.8),
                      border: Border(
                          top: BorderSide(color: borderColor, width: 0.5)),
                    ),
                    padding: const EdgeInsets.symmetric(
                        horizontal: 20, vertical: 16),
                    child: Row(
                      children: [
                        GestureDetector(
                          onTap: onTap1,
                          child: Container(
                            height: 40,
                            width: 40,
                            decoration: BoxDecoration(
                                gradient: LinearGradient(
                                  colors: [
                                    bgColor,
                                    bgColor.withValues(alpha: 0.8)
                                  ],
                                  begin: Alignment.topLeft,
                                  end: Alignment.bottomRight,
                                ),
                                shape: BoxShape.circle,
                                boxShadow: [
                                  BoxShadow(
                                      color: bgColor.withValues(alpha: 0.2),
                                      blurRadius: 6,
                                      offset: const Offset(0, 2))
                                ]),
                            child: const Icon(CupertinoIcons.arrow_right,
                                size: 20, color: Colors.white),
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Text(
                            bottomTitle,
                            style: TextStyle(
                                fontWeight: FontWeight.w700,
                                fontSize: 15,
                                color: Theme.of(context).colorScheme.onSurface),
                          ),
                        ),
                        _buildProButton(
                            context, buttonText1, onTap1, isDark, bgColor),
                        if (buttonText2 != null && onTap2 != null) ...[
                          const SizedBox(width: 8),
                          _buildProButton(
                              context, buttonText2, onTap2, isDark, bgColor),
                        ],
                      ],
                    ),
                  ),
                ),
              )
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildProButton(BuildContext context, String text, VoidCallback onTap,
      bool isDark, Color accentColor) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(16),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
        decoration: BoxDecoration(
          gradient: LinearGradient(
            colors: [accentColor, accentColor.withValues(alpha: 0.8)],
            begin: Alignment.centerLeft,
            end: Alignment.centerRight,
          ),
          borderRadius: BorderRadius.circular(16),
          boxShadow: [
            BoxShadow(
              color: accentColor.withValues(alpha: 0.2),
              blurRadius: 6,
              offset: const Offset(0, 2),
            )
          ],
        ),
        child: Text(
          text,
          style: const TextStyle(
            color: Colors.white,
            fontSize: 13,
            fontWeight: FontWeight.bold,
            letterSpacing: 0.3,
          ),
        ),
      ),
    );
  }
}

class GoalSettingSection extends StatefulWidget {
  const GoalSettingSection({super.key});

  @override
  State<GoalSettingSection> createState() => _GoalSettingSectionState();
}

class _GoalSettingSectionState extends State<GoalSettingSection> {
  final Map<String, List<Map<String, dynamic>>> _weeklyGoals = {
    'Mon': [],
    'Tue': [],
    'Wed': [],
    'Thu': [],
    'Fri': [],
    'Sat': [],
    'Sun': [],
  };

  String _selectedDay = 'Mon';
  final TextEditingController _taskController = TextEditingController();

  double _calculateTotalProgress() {
    int total = 0;
    int completed = 0;
    for (var list in _weeklyGoals.values) {
      total += list.length;
      completed += list.where((item) => item['isDone'] == true).length;
    }
    return total == 0 ? 0.0 : completed / total;
  }

  @override
  void dispose() {
    _taskController.dispose();
    super.dispose();
  }

  void _showWeeklyGoalDialog(BuildContext context) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      useRootNavigator: true,
      builder: (context) {
        return StatefulBuilder(
          builder: (context, setModalState) {
            return Container(
              height: MediaQuery.of(context).size.height * 0.75,
              padding: EdgeInsets.fromLTRB(
                  20, 20, 20, MediaQuery.of(context).viewInsets.bottom + 20),
              decoration: BoxDecoration(
                color: Theme.of(context).colorScheme.surface,
                borderRadius:
                    const BorderRadius.vertical(top: Radius.circular(24)),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Header
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        'Weekly Goals',
                        style: TextStyle(
                            fontSize: 20,
                            fontWeight: FontWeight.bold,
                            color: Theme.of(context).colorScheme.onSurface),
                      ),
                      IconButton(
                        icon: const Icon(CupertinoIcons.clear),
                        onPressed: () => Navigator.pop(context),
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),
                  // Horizontal Days
                  SingleChildScrollView(
                    scrollDirection: Axis.horizontal,
                    child: Row(
                      children: [
                        'Mon',
                        'Tue',
                        'Wed',
                        'Thu',
                        'Fri',
                        'Sat',
                        'Sun'
                      ].asMap().entries.map((entry) {
                        int idx = entry.key;
                        String dayName = entry.value;
                        String dateStr =
                            (idx + 6).toString(); // mock dates 6-12
                        bool isSel = _selectedDay == dayName;
                        return Padding(
                          padding: const EdgeInsets.only(right: 8.0),
                          child: _buildDayItem(dayName, dateStr, isSel, () {
                            setModalState(() {
                              _selectedDay = dayName;
                            });
                          }),
                        );
                      }).toList(),
                    ),
                  ),
                  const SizedBox(height: 20),
                  // Task List for Selected Day
                  Expanded(
                    child: _weeklyGoals[_selectedDay]!.isEmpty
                        ? const Center(
                            child: Text(
                              'No goals set for this day.',
                              style: TextStyle(color: Colors.grey),
                            ),
                          )
                        : ListView.builder(
                            itemCount: _weeklyGoals[_selectedDay]!.length,
                            itemBuilder: (context, idx) {
                              final goal = _weeklyGoals[_selectedDay]![idx];
                              return ListTile(
                                contentPadding: EdgeInsets.zero,
                                leading: Checkbox(
                                  value: goal['isDone'],
                                  activeColor: AppTheme.primaryBlue,
                                  onChanged: (val) {
                                    setState(() {
                                      _weeklyGoals[_selectedDay]![idx]
                                          ['isDone'] = val;
                                    });
                                    setModalState(() {});
                                  },
                                ),
                                title: Text(
                                  goal['title'],
                                  style: TextStyle(
                                    decoration: goal['isDone']
                                        ? TextDecoration.lineThrough
                                        : null,
                                    color: goal['isDone']
                                        ? Colors.grey
                                        : Theme.of(context)
                                            .colorScheme
                                            .onSurface,
                                  ),
                                ),
                                trailing: IconButton(
                                  icon: const Icon(CupertinoIcons.trash,
                                      size: 20, color: Colors.redAccent),
                                  onPressed: () {
                                    setState(() {
                                      _weeklyGoals[_selectedDay]!.removeAt(idx);
                                    });
                                    setModalState(() {});
                                  },
                                ),
                              );
                            },
                          ),
                  ),
                  const Divider(),
                  // Add Task Form
                  Row(
                    children: [
                      Expanded(
                        child: TextField(
                          controller: _taskController,
                          style: TextStyle(
                              color: Theme.of(context).colorScheme.onSurface),
                          decoration: InputDecoration(
                            hintText: 'Add goal for $_selectedDay...',
                            hintStyle: const TextStyle(color: Colors.grey),
                            border: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(12),
                              borderSide: BorderSide(
                                  color: Theme.of(context).dividerTheme.color ??
                                      const Color(0xFFE5E7EB),
                                  width: 0.5),
                            ),
                            enabledBorder: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(12),
                              borderSide: BorderSide(
                                  color: Theme.of(context).dividerTheme.color ??
                                      const Color(0xFFE5E7EB),
                                  width: 0.5),
                            ),
                            contentPadding:
                                const EdgeInsets.symmetric(horizontal: 16),
                          ),
                        ),
                      ),
                      const SizedBox(width: 12),
                      ElevatedButton(
                        onPressed: () {
                          if (_taskController.text.trim().isNotEmpty) {
                            setState(() {
                              _weeklyGoals[_selectedDay]!.add({
                                'title': _taskController.text.trim(),
                                'isDone': false,
                              });
                            });
                            setModalState(() {
                              _taskController.clear();
                            });
                          }
                        },
                        style: ElevatedButton.styleFrom(
                          backgroundColor: AppTheme.primaryBlue,
                          foregroundColor: Colors.white,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                          padding: const EdgeInsets.symmetric(
                              horizontal: 16, vertical: 14),
                        ),
                        child: const Text('Add'),
                      ),
                    ],
                  ),
                ],
              ),
            );
          },
        );
      },
    );
  }

  Widget _buildDayItem(
      String day, String date, bool isSelected, VoidCallback onTap) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
        decoration: BoxDecoration(
          color: isSelected ? AppTheme.primaryBlue : Colors.transparent,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: isSelected
                ? AppTheme.primaryBlue
                : (Theme.of(context).dividerTheme.color ??
                    const Color(0xFFE5E7EB)),
            width: 0.5,
          ),
        ),
        child: Column(
          children: [
            Text(
              day,
              style: TextStyle(
                fontSize: 12,
                color: isSelected ? Colors.white : Colors.grey,
                fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
              ),
            ),
            const SizedBox(height: 4),
            Text(
              date,
              style: TextStyle(
                fontSize: 14,
                color: isSelected
                    ? Colors.white
                    : Theme.of(context).colorScheme.onSurface,
                fontWeight: FontWeight.bold,
              ),
            ),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    double progress = _calculateTotalProgress();
    final bool isDark = Theme.of(context).brightness == Brightness.dark;

    return Container(
      height: 72, // Matches floating navbar height
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.surface,
        borderRadius: BorderRadius.circular(24),
        border: Border.all(
            color:
                Theme.of(context).dividerTheme.color ?? const Color(0xFFE5E7EB),
            width: 0.5),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.04),
            blurRadius: 10,
            offset: const Offset(0, 4),
          )
        ],
      ),
      child: Row(
        children: [
          // Circular progress bar
          SizedBox(
            width: 44,
            height: 44,
            child: Stack(
              alignment: Alignment.center,
              children: [
                CircularProgressIndicator(
                  value: progress,
                  strokeWidth: 4,
                  backgroundColor: Theme.of(context).scaffoldBackgroundColor,
                  valueColor:
                      const AlwaysStoppedAnimation<Color>(AppTheme.primaryBlue),
                ),
                Text(
                  '${(progress * 100).toInt()}%',
                  style: TextStyle(
                      fontSize: 10,
                      fontWeight: FontWeight.bold,
                      color: Theme.of(context).colorScheme.onSurface),
                ),
              ],
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Text(
                  'Weekly Progress',
                  style: TextStyle(
                      fontWeight: FontWeight.bold,
                      fontSize: 14,
                      color: Theme.of(context).colorScheme.onSurface),
                ),
                const Text(
                  'Set and track your study goals',
                  style: TextStyle(fontSize: 11, color: Colors.grey),
                ),
              ],
            ),
          ),
          OutlinedButton(
            onPressed: () => _showWeeklyGoalDialog(context),
            style: OutlinedButton.styleFrom(
              foregroundColor: isDark ? Colors.white : const Color(0xFF1A1A1A),
              side: BorderSide(
                  color: isDark ? Colors.white : const Color(0xFF1A1A1A),
                  width: 1.2),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(16),
              ),
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            ),
            child: const Text('Manage Goals',
                style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold)),
          ),
        ],
      ),
    );
  }
}
