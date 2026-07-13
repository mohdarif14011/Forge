import 'package:flutter/material.dart';
import 'package:flutter/cupertino.dart';
import 'package:go_router/go_router.dart';
import '../core/theme.dart';

class SharedBottomNavBar extends StatelessWidget {
  final int currentIndex;
  final ValueChanged<int>? onTap;

  const SharedBottomNavBar({super.key, required this.currentIndex, this.onTap});

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      child: Container(
        margin: const EdgeInsets.fromLTRB(16, 0, 16, 2),
        decoration: BoxDecoration(
          color: Theme.of(context).colorScheme.surface,
          borderRadius: BorderRadius.circular(24),
          border: Border.all(color: Theme.of(context).dividerTheme.color ?? const Color(0xFFE5E7EB), width: 0.5),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.05),
              blurRadius: 10,
              offset: const Offset(0, 4),
            )
          ],
        ),
        child: ClipRRect(
          borderRadius: BorderRadius.circular(24),
          child: BottomNavigationBar(
            currentIndex: currentIndex,
            onTap: (index) {
              if (index == currentIndex) return;
              if (onTap != null) {
                onTap!(index);
                return;
              }
              if (index == 0) {
                context.go('/home');
              } else if (index == 1) {
                context.go('/notes/exams');
              } else if (index == 2) {
                context.go('/ask');
              } else if (index == 3) {
                context.go('/books');
              } else if (index == 4) {
                context.go('/subscribe');
              }
            },
            type: BottomNavigationBarType.fixed,
            backgroundColor: Theme.of(context).colorScheme.surface,
            elevation: 0,
            selectedItemColor: AppTheme.primaryBlue,
            unselectedItemColor: Theme.of(context).brightness == Brightness.dark ? Colors.grey[600] : Colors.grey,
            showUnselectedLabels: true,
            selectedFontSize: 11,
            unselectedFontSize: 11,
            items: [
              const BottomNavigationBarItem(
                  icon: Icon(CupertinoIcons.home), label: 'Home'),
              const BottomNavigationBarItem(
                  icon: Icon(CupertinoIcons.doc_text), label: 'Notes'),
              BottomNavigationBarItem(
                icon: AiButtonIcon(
                  icon: CupertinoIcons.sparkles,
                ),
                label: 'Ask AI',
              ),
              const BottomNavigationBarItem(
                  icon: Icon(CupertinoIcons.book), label: 'Books'),
              const BottomNavigationBarItem(
                  icon: Icon(CupertinoIcons.creditcard), label: 'Subscribe'),
            ],
          ),
        ),
      ),
    );
  }
}

class AiButtonIcon extends StatelessWidget {
  final IconData icon;
  const AiButtonIcon({super.key, required this.icon});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 42,
      height: 42,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        gradient: const LinearGradient(
          colors: [Color(0xFF6C63FF), Color(0xFF3F3D56)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        boxShadow: [
          BoxShadow(
            color: const Color(0xFF6C63FF).withValues(alpha: 0.3),
            blurRadius: 8,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Center(
        child: Icon(
          icon,
          color: Colors.white,
          size: 20,
        ),
      ),
    );
  }
}
