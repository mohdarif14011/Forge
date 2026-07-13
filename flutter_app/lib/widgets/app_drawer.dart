import 'package:flutter/material.dart';
import 'package:flutter/cupertino.dart';
import 'package:go_router/go_router.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../core/theme.dart';
import '../core/theme_provider.dart';

class AppDrawer extends ConsumerWidget {
  const AppDrawer({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final user = FirebaseAuth.instance.currentUser;
    final isDark = ref.watch(themeProvider) == ThemeMode.dark;

    return Drawer(
      backgroundColor: Theme.of(context).colorScheme.surface,
      surfaceTintColor: Colors.transparent,
      elevation: 0,
      child: SafeArea(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const SizedBox(height: 16),
            // Profile Info (Below App Name)
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: InkWell(
                onTap: () {
                  context.pop();
                  Future.delayed(const Duration(milliseconds: 150), () {
                    if (context.mounted) context.push('/profile');
                  });
                },
                borderRadius: BorderRadius.circular(16),
                child: Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: Theme.of(context).colorScheme.surface,
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(color: Theme.of(context).dividerTheme.color ?? AppTheme.borderColor, width: 0.5),
                  ),
                  child: Row(
                    children: [
                      Container(
                        width: 48,
                        height: 48,
                        clipBehavior: Clip.hardEdge,
                        decoration: BoxDecoration(
                          color: Colors.grey[100],
                          shape: BoxShape.circle,
                        ),
                        child: user?.photoURL != null
                            ? Image.network(
                                user!.photoURL!,
                                fit: BoxFit.cover,
                              )
                            : const Icon(
                                CupertinoIcons.person,
                                color: Colors.grey,
                                size: 24,
                              ),
                      ),
                      const SizedBox(width: 16),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              user?.displayName ?? 'Student',
                              style: TextStyle(
                                fontSize: 16,
                                fontWeight: FontWeight.w600,
                                color: Theme.of(context).colorScheme.onSurface,
                              ),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                            const SizedBox(height: 2),
                            Container(
                              padding: const EdgeInsets.symmetric(
                                  horizontal: 8, vertical: 4),
                              decoration: BoxDecoration(
                                color:
                                    AppTheme.primaryBlue.withValues(alpha: 0.1),
                                borderRadius: BorderRadius.circular(12),
                              ),
                              child: const Text(
                                'View profile',
                                style: TextStyle(
                                  fontSize: 11,
                                  fontWeight: FontWeight.w500,
                                  color: AppTheme.primaryBlue,
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                      const Icon(CupertinoIcons.chevron_right,
                          size: 16, color: Colors.grey),
                    ],
                  ),
                ),
              ),
            ),

            const SizedBox(height: 24),

            // Thin light line
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 24),
              child: Divider(
                color: Theme.of(context).dividerTheme.color ?? AppTheme.borderColor,
                thickness: 0.5,
                height: 1,
              ),
            ),

            const SizedBox(height: 16),

            // Menu Items
            Expanded(
              child: ListView(
                padding: const EdgeInsets.symmetric(horizontal: 16),
                children: [
                  _buildSectionHeader('Overview'),
                  _buildMenuItem(
                    context: context,
                    icon: CupertinoIcons.home,
                    title: 'Home',
                    onTap: () {
                      context.pop();
                      context.go('/home');
                    },
                  ),
                  _buildMenuItem(
                    context: context,
                    icon: CupertinoIcons.doc_text,
                    title: 'Notes',
                    onTap: () {
                      context.pop();
                      Future.delayed(const Duration(milliseconds: 150), () {
                        if (context.mounted) context.push('/notes/exams');
                      });
                    },
                  ),
                  _buildMenuItem(
                    context: context,
                    icon: CupertinoIcons.sparkles,
                    title: 'Ask AI',
                    onTap: () {
                      context.pop();
                      Future.delayed(const Duration(milliseconds: 150), () {
                        if (context.mounted) context.push('/ask');
                      });
                    },
                  ),
                  const SizedBox(height: 16),
                  _buildSectionHeader('Resources'),
                  _buildMenuItem(
                    context: context,
                    icon: CupertinoIcons.book,
                    title: 'Books',
                    onTap: () {
                      context.pop();
                      Future.delayed(const Duration(milliseconds: 150), () {
                        if (context.mounted) context.push('/books');
                      });
                    },
                  ),
                  _buildMenuItem(
                    context: context,
                    icon: CupertinoIcons.creditcard,
                    title: 'Subscription',
                    onTap: () {
                      context.pop();
                      Future.delayed(const Duration(milliseconds: 150), () {
                        if (context.mounted) context.push('/subscribe');
                      });
                    },
                  ),
                  const SizedBox(height: 16),
                  _buildSectionHeader('Account'),
                  _buildMenuItem(
                    context: context,
                    icon: CupertinoIcons.cart,
                    title: 'My Purchases',
                    onTap: () {
                      context.pop();
                      Future.delayed(const Duration(milliseconds: 150), () {
                        if (context.mounted) context.push('/purchases');
                      });
                    },
                  ),
                  _buildMenuItem(
                    context: context,
                    icon: CupertinoIcons.question_circle,
                    title: 'Help & Support',
                    onTap: () {
                      context.pop();
                      Future.delayed(const Duration(milliseconds: 150), () {
                        if (context.mounted) context.push('/support');
                      });
                    },
                  ),
                  _buildMenuItem(
                    context: context,
                    icon: CupertinoIcons.gift,
                    title: 'Refer & Earn',
                    onTap: () {
                      context.pop();
                      Future.delayed(const Duration(milliseconds: 150), () {
                        if (context.mounted) context.push('/referral');
                      });
                    },
                  ),
                  const SizedBox(height: 16),
                  _buildSectionHeader('Legal & Policies'),
                  _buildMenuItem(
                    context: context,
                    icon: CupertinoIcons.doc_text,
                    title: 'Terms & Conditions',
                    onTap: () {
                      context.pop();
                      Future.delayed(const Duration(milliseconds: 150), () {
                        if (context.mounted) context.push('/legal/terms');
                      });
                    },
                  ),
                  _buildMenuItem(
                    context: context,
                    icon: CupertinoIcons.lock_shield,
                    title: 'Privacy Policy',
                    onTap: () {
                      context.pop();
                      Future.delayed(const Duration(milliseconds: 150), () {
                        if (context.mounted) context.push('/legal/privacy');
                      });
                    },
                  ),
                  _buildMenuItem(
                    context: context,
                    icon: CupertinoIcons.arrow_counterclockwise,
                    title: 'Refund Policy',
                    onTap: () {
                      context.pop();
                      Future.delayed(const Duration(milliseconds: 150), () {
                        if (context.mounted) context.push('/legal/refund');
                      });
                    },
                  ),
                ],
              ),
            ),

            // Dark Mode Toggle
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Row(
                    children: [
                      Icon(
                        isDark ? CupertinoIcons.moon_fill : CupertinoIcons.sun_max_fill,
                        size: 22,
                        color: Theme.of(context).colorScheme.onSurface,
                      ),
                      const SizedBox(width: 16),
                      Text(
                        'Dark Mode',
                        style: TextStyle(
                          fontSize: 15,
                          fontWeight: FontWeight.w500,
                          color: Theme.of(context).colorScheme.onSurface,
                        ),
                      ),
                    ],
                  ),
                  Switch(
                    value: isDark,
                    onChanged: (_) {
                      ref.read(themeProvider.notifier).toggleTheme();
                    },
                    activeThumbColor: AppTheme.primaryBlue,
                  ),
                ],
              ),
            ),
            const SizedBox(height: 8),

            // Logout
            Padding(
              padding: const EdgeInsets.all(16),
              child: _buildMenuItem(
                context: context,
                icon: CupertinoIcons.square_arrow_right,
                title: 'Log out',
                isDestructive: true,
                onTap: () {
                  context.go('/login');
                },
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSectionHeader(String title) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      child: Text(
        title,
        style: TextStyle(
          fontSize: 13,
          fontWeight: FontWeight.w600,
          color: Colors.grey[500],
        ),
      ),
    );
  }

  Widget _buildMenuItem({
    required BuildContext context,
    required IconData icon,
    required String title,
    required VoidCallback onTap,
    bool isDestructive = false,
  }) {
    final color = isDestructive ? Colors.red[600] : Theme.of(context).colorScheme.onSurface;

    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(12),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
        child: Row(
          children: [
            Icon(
              icon,
              size: 22,
              color: color,
            ),
            const SizedBox(width: 16),
            Text(
              title,
              style: TextStyle(
                fontSize: 15,
                fontWeight: FontWeight.w500,
                color: color,
              ),
            ),
            if (!isDestructive) ...[
              const Spacer(),
              Icon(
                CupertinoIcons.chevron_right,
                size: 16,
                color: Colors.grey[400],
              ),
            ],
          ],
        ),
      ),
    );
  }
}
