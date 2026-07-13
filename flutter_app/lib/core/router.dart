import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../widgets/shared_bottom_navbar.dart';
import '../widgets/app_drawer.dart';

import '../features/onboarding/splash_screen.dart';
import '../features/onboarding/onboarding_screen.dart';
import '../features/onboarding/login_screen.dart';
import '../features/onboarding/exam_selection_screen.dart';
import '../features/home/home_screen.dart';
import '../features/profile/profile_screen.dart';
import '../features/profile/manage_exams_screen.dart';
import '../features/support/help_support_screen.dart';
import '../features/notifications/notifications_screen.dart';
import '../features/referral/referral_screen.dart';

import '../features/practice/pyq/pyq_exam_screen.dart';
import '../features/practice/pyq/pyq_year_screen.dart';
import '../features/practice/pyq/pyq_day_shift_screen.dart';

import '../features/practice/extra_questions/eq_exam_screen.dart';
import '../features/practice/extra_questions/eq_subjects_screen.dart';
import '../features/practice/extra_questions/eq_chapters_screen.dart';
import '../features/practice/extra_questions/eq_timer_screen.dart';

import '../features/practice/custom_test/ct_exam_screen.dart';

import '../features/practice/test_series/test_series_exam_screen.dart';
import '../features/practice/test_series/test_series_list_screen.dart';

import '../features/notes/notes_exam_screen.dart';
import '../features/notes/notes_subject_screen.dart';
import '../features/notes/notes_chapter_screen.dart';
import '../features/notes/notes_pdf_viewer.dart';

import '../features/common/coming_soon_screen.dart';
import '../features/ask/ask_screen.dart';
import '../features/subscribe/subscribe_screen.dart';
import '../features/subscribe/checkout_screen.dart';
import '../features/subscribe/purchases_screen.dart';

import '../features/test_engine/test_start_screen.dart';
import '../features/test_engine/test_active_screen.dart';
import '../features/test_engine/test_summary_screen.dart';
import '../features/test_engine/test_result_screen.dart';
import '../features/test_engine/test_solution_screen.dart';

import '../features/legal/terms_screen.dart';
import '../features/legal/privacy_screen.dart';
import '../features/legal/refund_screen.dart';

final routerProvider = Provider<GoRouter>((ref) {
  return GoRouter(
    initialLocation: '/',
    routes: [
      GoRoute(
        path: '/',
        builder: (context, state) => const SplashScreen(),
      ),
      GoRoute(
        path: '/onboarding',
        builder: (context, state) => const OnboardingScreen(),
      ),
      GoRoute(
        path: '/login',
        builder: (context, state) => const LoginScreen(),
      ),
      GoRoute(
        path: '/exam-selection',
        builder: (context, state) => const ExamSelectionScreen(),
      ),
      StatefulShellRoute.indexedStack(
        builder: (context, state, navigationShell) {
          return PopScope(
            canPop: navigationShell.currentIndex == 0,
            onPopInvokedWithResult: (didPop, result) {
              if (didPop) return;
              if (navigationShell.currentIndex != 0) {
                navigationShell.goBranch(0);
              }
            },
            child: Scaffold(
              drawer: const AppDrawer(),
              body: navigationShell,
              bottomNavigationBar: SharedBottomNavBar(
                currentIndex: navigationShell.currentIndex >= 2 ? navigationShell.currentIndex + 1 : navigationShell.currentIndex,
                onTap: (index) {
                  if (index == 2) {
                    context.push('/ask');
                  } else {
                    final branchIndex = index > 2 ? index - 1 : index;
                    navigationShell.goBranch(
                      branchIndex,
                      initialLocation: branchIndex == navigationShell.currentIndex,
                    );
                  }
                },
              ),
              extendBody: true,
            ),
          );
        },
        branches: [
          StatefulShellBranch(
            routes: [
              GoRoute(
                path: '/home',
                builder: (context, state) => const HomeScreen(),
              ),
            ],
          ),
          StatefulShellBranch(
            routes: [
              GoRoute(
                path: '/notes/exams',
                builder: (context, state) => const NotesExamScreen(),
              ),
            ],
          ),
          StatefulShellBranch(
            routes: [
              GoRoute(
                path: '/books',
                builder: (context, state) => const ComingSoonScreen(title: 'Books & Resources', currentIndex: 3),
              ),
            ],
          ),
          StatefulShellBranch(
            routes: [
              GoRoute(
                path: '/subscribe',
                builder: (context, state) => const SubscribeScreen(),
              ),
            ],
          ),
        ],
      ),
      GoRoute(
        path: '/ask',
        builder: (context, state) => const AskScreen(),
      ),
      GoRoute(
        path: '/profile',
        builder: (context, state) => const ProfileScreen(),
      ),
      GoRoute(
        path: '/manage-exams',
        builder: (context, state) => const ManageExamsScreen(),
      ),
      GoRoute(
        path: '/referral',
        builder: (context, state) => const ReferralScreen(),
      ),
      GoRoute(
        path: '/checkout',
        builder: (context, state) {
          final extra = state.extra as Map<String, dynamic>? ?? {};
          return CheckoutScreen(params: extra);
        },
      ),
      GoRoute(
        path: '/purchases',
        builder: (context, state) => const PurchasesScreen(),
      ),
      GoRoute(
        path: '/support',
        builder: (context, state) => const HelpSupportScreen(),
      ),
      GoRoute(
        path: '/notifications',
        builder: (context, state) => const NotificationsScreen(),
      ),
      
      // Legal Flow
      GoRoute(
        path: '/legal/terms',
        builder: (context, state) => const TermsScreen(),
      ),
      GoRoute(
        path: '/legal/privacy',
        builder: (context, state) => const PrivacyScreen(),
      ),
      GoRoute(
        path: '/legal/refund',
        builder: (context, state) => const RefundScreen(),
      ),
      
      // Notes Flow
      GoRoute(
        path: '/notes/subjects',
        builder: (context, state) {
          final extra = state.extra as Map<String, dynamic>? ?? {};
          return NotesSubjectScreen(params: extra);
        },
      ),
      GoRoute(
        path: '/notes/chapters',
        builder: (context, state) {
          final extra = state.extra as Map<String, dynamic>? ?? {};
          return NotesChapterScreen(params: extra);
        },
      ),
      GoRoute(
        path: '/notes/pdf',
        builder: (context, state) {
          final extra = state.extra as Map<String, dynamic>? ?? {};
          return NotesPdfViewerScreen(params: extra);
        },
      ),
      
      // PYQ Flow
      GoRoute(
        path: '/pyq/exams',
        builder: (context, state) => const PyqExamScreen(),
      ),
      GoRoute(
        path: '/pyq/years',
        builder: (context, state) {
          final extra = state.extra as Map<String, dynamic>? ?? {};
          return PyqYearScreen(params: extra);
        },
      ),
      GoRoute(
        path: '/pyq/shifts',
        builder: (context, state) {
          final extra = state.extra as Map<String, dynamic>? ?? {};
          return PyqDayShiftScreen(params: extra);
        },
      ),
      
      // Extra Questions Flow
      GoRoute(
        path: '/eq/exams',
        builder: (context, state) => const EqExamScreen(),
      ),
      GoRoute(
        path: '/eq/subjects',
        builder: (context, state) {
          final extra = state.extra as Map<String, dynamic>? ?? {};
          return EqSubjectsScreen(params: extra);
        },
      ),
      GoRoute(
        path: '/eq/chapters',
        builder: (context, state) {
          final extra = state.extra as Map<String, dynamic>? ?? {};
          return EqChaptersScreen(params: extra);
        },
      ),
      GoRoute(
        path: '/eq/timer',
        builder: (context, state) {
          final extra = state.extra as Map<String, dynamic>? ?? {};
          return EqTimerScreen(params: extra);
        },
      ),
      
      GoRoute(
        path: '/ct/exams',
        builder: (context, state) {
          final extra = state.extra as Map<String, dynamic>? ?? {};
          return CtExamScreen(params: extra);
        },
      ),
      GoRoute(
        path: '/ct/subjects',
        builder: (context, state) {
          final extra = state.extra as Map<String, dynamic>? ?? {};
          return EqSubjectsScreen(params: extra);
        },
      ),
      GoRoute(
        path: '/ct/chapters',
        builder: (context, state) {
          final extra = state.extra as Map<String, dynamic>? ?? {};
          return EqChaptersScreen(params: extra);
        },
      ),
      GoRoute(
        path: '/ct/timer',
        builder: (context, state) {
          final extra = state.extra as Map<String, dynamic>? ?? {};
          return EqTimerScreen(params: extra);
        },
      ),

      // Test Series Flow
      GoRoute(
        path: '/test_series/exams',
        builder: (context, state) => const TestSeriesExamScreen(),
      ),
      GoRoute(
        path: '/test_series/list',
        builder: (context, state) {
          final extra = state.extra as Map<String, dynamic>? ?? {};
          return TestSeriesListScreen(params: extra);
        },
      ),

      // Test Engine
      GoRoute(
        path: '/test/start',
        builder: (context, state) {
          final extra = state.extra as Map<String, dynamic>? ?? {};
          return TestStartScreen(params: extra);
        },
      ),
      GoRoute(
        path: '/test/active',
        builder: (context, state) {
          final extra = state.extra as Map<String, dynamic>? ?? {};
          return TestActiveScreen(params: extra);
        },
      ),
      GoRoute(
        path: '/test/summary',
        builder: (context, state) {
          final extra = state.extra as Map<String, dynamic>? ?? {};
          return TestSummaryScreen(params: extra);
        },
      ),
      GoRoute(
        path: '/test/result',
        builder: (context, state) {
          final extra = state.extra as Map<String, dynamic>? ?? {};
          return TestResultScreen(params: extra);
        },
      ),
      GoRoute(
        path: '/test/solution',
        builder: (context, state) {
          final extra = state.extra as Map<String, dynamic>? ?? {};
          return TestSolutionScreen(params: extra);
        },
      ),

    ],
  );
});
