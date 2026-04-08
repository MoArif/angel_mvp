import 'package:angle_mvp/core/theme/app_theme.dart';
import 'package:angle_mvp/features/dashboard/widgets/user_header.dart';
import 'package:angle_mvp/features/dashboard/widgets/stat_metrics.dart';
import 'package:angle_mvp/features/dashboard/widgets/recent_activity_list.dart';
import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:angle_mvp/features/auth/providers/auth_provider.dart';

// Provider to fetch user profile name from the global profile provider
final userNameProvider = Provider<AsyncValue<String?>>((ref) {
  final profileStream = ref.watch(profileProvider);
  return profileStream.whenData((profile) => profile?['name'] as String?);
});

class DashboardScreen extends ConsumerWidget {
  const DashboardScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final profile = ref.watch(userNameProvider);

    return Scaffold(
      body: Container(
        decoration: const BoxDecoration(gradient: AppColors.backgroundGradient),
        child: SafeArea(
          child: RefreshIndicator(
            onRefresh: () async {
              // Dummy refresh action until backend is connected
              await Future.delayed(const Duration(seconds: 1));
            },
            child: SingleChildScrollView(
              physics: const AlwaysScrollableScrollPhysics(),
              padding: const EdgeInsets.symmetric(horizontal: 24),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const SizedBox(height: 32),

                  // Componentized User Header
                  UserHeader(
                    profile: profile,
                  ).animate().fadeIn().slideY(begin: -0.2),

                  const SizedBox(height: 48),

                  // Componentized Stats
                  const StatMetrics().animate().fadeIn(delay: 200.ms).scale(),

                  const SizedBox(height: 32),

                  Text(
                    'Recent Activity',
                    style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                      fontWeight: FontWeight.bold,
                    ),
                  ).animate().fadeIn(delay: 400.ms),

                  const SizedBox(height: 16),

                  // Componentized Activity List
                  const RecentActivityList()
                      .animate()
                      .fadeIn(delay: 600.ms)
                      .slideY(begin: 0.1),

                  const SizedBox(height: 32),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
