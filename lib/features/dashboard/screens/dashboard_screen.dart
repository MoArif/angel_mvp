import 'package:angle_mvp/core/theme/app_theme.dart';
import 'package:angle_mvp/core/widgets/glass_card.dart';
import 'package:angle_mvp/features/auth/providers/auth_provider.dart';
import 'package:angle_mvp/core/providers/supabase_provider.dart';
import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

// Provider to fetch user profile name from the profiles table
final profileProvider = FutureProvider<String?>((ref) async {
  final supabase = ref.watch(supabaseClientProvider);
  final user = supabase.auth.currentUser;
  if (user == null) return null;

  final response = await supabase
      .from('profiles')
      .select('name')
      .eq('id', user.id)
      .single();
  
  return response['name'] as String?;
});

class DashboardScreen extends ConsumerWidget {
  const DashboardScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final session = ref.watch(authSessionProvider).value;
    final profile = ref.watch(profileProvider);

    return Scaffold(
      body: Container(
        decoration: const BoxDecoration(
          gradient: AppColors.backgroundGradient,
        ),
        child: SafeArea(
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 24),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const SizedBox(height: 32),
                
                // Header with Sign Out
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Hello,',
                          style: Theme.of(context).textTheme.bodyMedium,
                        ),
                        profile.when(
                          data: (name) => Text(
                            name ?? 'Hero',
                            style: Theme.of(context).textTheme.displayLarge?.copyWith(fontSize: 28),
                          ),
                          loading: () => const Text('...'),
                          error: (_, __) => Text(
                            session?.user.email?.split('@').first ?? 'User',
                            style: Theme.of(context).textTheme.displayLarge?.copyWith(fontSize: 28),
                          ),
                        ),
                      ],
                    ),
                    IconButton(
                      onPressed: () => ref.read(authNotifierProvider.notifier).signOut(),
                      icon: Container(
                        padding: const EdgeInsets.all(10),
                        decoration: BoxDecoration(
                          color: Colors.white.withValues(alpha: 0.1),
                          shape: BoxShape.circle,
                        ),
                        child: const Icon(Icons.logout_rounded, color: Colors.white, size: 20),
                      ),
                    ),
                  ],
                ).animate().fadeIn().slideY(begin: -0.2),

                const SizedBox(height: 48),

                // Main Status Card
                GlassCard(
                  child: Column(
                    children: [
                      Row(
                        children: [
                          Container(
                            padding: const EdgeInsets.all(12),
                            decoration: BoxDecoration(
                              color: Colors.green.withValues(alpha: 0.2),
                              borderRadius: BorderRadius.circular(12),
                            ),
                            child: const Icon(Icons.verified_user_rounded, color: Colors.greenAccent),
                          ),
                          const SizedBox(width: 16),
                          const Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                'Safety Status',
                                style: TextStyle(fontWeight: FontWeight.bold),
                              ),
                              Text(
                                'You are protected',
                                style: TextStyle(color: Colors.greenAccent, fontSize: 12),
                              ),
                            ],
                          ),
                        ],
                      ),
                      const SizedBox(height: 24),
                      const Divider(color: Colors.white10),
                      const SizedBox(height: 24),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          _buildStat('Check-ins', '0/3'),
                          _buildStat('Contacts', '5'),
                          _buildStat('Incidents', '0'),
                        ],
                      ),
                    ],
                  ),
                ).animate().fadeIn(delay: 200.ms).scale(),

                const SizedBox(height: 32),

                Text(
                  'Recent Activity',
                  style: Theme.of(context).textTheme.bodyLarge?.copyWith(fontWeight: FontWeight.bold),
                ).animate().fadeIn(delay: 400.ms),

                const SizedBox(height: 16),

                Expanded(
                  child: ListView.separated(
                    itemCount: 2,
                    separatorBuilder: (context, index) => const SizedBox(height: 12),
                    itemBuilder: (context, index) => GlassCard(
                      opacity: 0.03,
                      borderRadius: 16,
                      child: Row(
                        children: [
                          Icon(
                            index == 0 ? Icons.login_rounded : Icons.person_add_rounded,
                            color: AppColors.textSecondary,
                            size: 16,
                          ),
                          const SizedBox(width: 12),
                          Text(
                            index == 0 ? 'Successful Login' : 'Account Created',
                            style: const TextStyle(fontSize: 13),
                          ),
                          const Spacer(),
                          const Text(
                            'Just now',
                            style: TextStyle(color: Colors.white24, fontSize: 11),
                          ),
                        ],
                      ),
                    ),
                  ).animate().fadeIn(delay: 600.ms).slideY(begin: 0.1),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildStat(String label, String value) {
    return Column(
      children: [
        Text(
          value,
          style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Colors.white),
        ),
        const SizedBox(height: 4),
        Text(
          label,
          style: const TextStyle(fontSize: 11, color: AppColors.textSecondary),
        ),
      ],
    );
  }
}
