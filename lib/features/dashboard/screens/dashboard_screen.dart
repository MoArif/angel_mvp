import 'package:angle_mvp/core/theme/app_theme.dart';
import 'package:angle_mvp/core/constants/build_env.dart';
import 'package:angle_mvp/features/dashboard/widgets/user_header.dart';
import 'package:angle_mvp/features/dashboard/widgets/stat_metrics.dart';
import 'package:angle_mvp/features/dashboard/widgets/recent_activity_list.dart';
import 'package:angle_mvp/features/dashboard/widgets/manual_checkin_button.dart';
import 'package:angle_mvp/features/dashboard/widgets/dev_sms_button.dart';
import 'package:angle_mvp/features/dashboard/widgets/dev_escalation_toggle.dart';
import 'package:flutter/foundation.dart';
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

                  // Standard Manual Check-in Button
                  const ManualCheckinButton().animate().fadeIn(delay: 300.ms).scale(),

                  const SizedBox(height: 32),

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

                  // DEV: SMS Test Button (debug builds only)
                  if (kDebugMode) ...
                  [
                    Text(
                      'Developer Tools',
                      style: Theme.of(context).textTheme.bodySmall?.copyWith(
                        color: Colors.orange.withValues(alpha: 0.7),
                        fontWeight: FontWeight.bold,
                        letterSpacing: 1.2,
                      ),
                    ),
                    const SizedBox(height: 8),
                    const DevEscalationToggle(),
                    const SizedBox(height: 12),
                    const DevSmsButton(),
                    const SizedBox(height: 24),
                  ],

                  // Branch Tracker Widget
                  Center(
                    child: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                      decoration: BoxDecoration(
                        color: Colors.white.withValues(alpha: 0.05),
                        borderRadius: BorderRadius.circular(20),
                        border: Border.all(color: Colors.white.withValues(alpha: 0.1)),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          const Icon(Icons.commit_outlined, color: Colors.white54, size: 16),
                          const SizedBox(width: 8),
                          Text(
                            BuildEnv.currentBranch,
                            style: const TextStyle(color: Colors.white54, fontSize: 12, fontFamily: 'monospace'),
                          ),
                        ],
                      ),
                    ),
                  ),
                  const SizedBox(height: 24),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
