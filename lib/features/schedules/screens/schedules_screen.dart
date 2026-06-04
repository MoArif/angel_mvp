import 'package:angle_mvp/core/theme/app_theme.dart';
import 'package:angle_mvp/core/widgets/glass_card.dart';
import 'package:angle_mvp/features/schedules/providers/schedules_provider.dart';
import 'package:angle_mvp/features/schedules/widgets/add_schedule_dialog.dart';
import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

class SchedulesScreen extends ConsumerWidget {
  const SchedulesScreen({super.key});

  void _showAddSchedule(BuildContext context) {
    showDialog(
      context: context,
      builder: (context) => const AddScheduleDialog(),
    );
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final schedulesAsync = ref.watch(schedulesProvider);

    return Scaffold(
      extendBodyBehindAppBar: true,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(
            Icons.arrow_back_ios_new_rounded,
            color: Colors.white,
          ),
          onPressed: () => context.pop(),
        ),
        title: const Text(
          'Safety Schedules',
          style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
        ),
      ),
      body: Container(
        decoration: const BoxDecoration(gradient: AppColors.backgroundGradient),
        child: SafeArea(
          child: schedulesAsync.when(
            data: (schedules) {
              if (schedules.isEmpty) {
                return Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      const Icon(
                        Icons.schedule_rounded,
                        size: 64,
                        color: Colors.white54,
                      ),
                      const SizedBox(height: 16),
                      const Text(
                        'No schedules set.',
                        style: TextStyle(color: Colors.white70, fontSize: 18),
                      ),
                      const SizedBox(height: 24),
                      ElevatedButton.icon(
                        onPressed: () => _showAddSchedule(context),
                        icon: const Icon(Icons.add, color: Colors.white),
                        label: const Text(
                          'New Safety Window',
                          style: TextStyle(
                            color: Colors.white,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: AppColors.primary,
                          padding: const EdgeInsets.symmetric(
                            horizontal: 24,
                            vertical: 12,
                          ),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(20),
                          ),
                        ),
                      ).animate().scale(delay: 200.ms),
                    ],
                  ),
                );
              }

              return ListView.builder(
                padding: const EdgeInsets.symmetric(
                  horizontal: 24,
                  vertical: 16,
                ),
                itemCount: schedules.length,
                itemBuilder: (context, index) {
                  final schedule = schedules[index];
                  final startTime = schedule['start_time'].toString().substring(
                    0,
                    5,
                  );
                  final endTime = schedule['end_time'].toString().substring(
                    0,
                    5,
                  );

                  return Padding(
                    padding: const EdgeInsets.only(bottom: 16),
                    child:
                        GlassCard(
                              child: ListTile(
                                contentPadding: const EdgeInsets.symmetric(
                                  horizontal: 16,
                                  vertical: 8,
                                ),
                                leading: CircleAvatar(
                                  backgroundColor: schedule['enabled']
                                      ? AppColors.accent.withValues(alpha: 0.2)
                                      : Colors.white10,
                                  child: Icon(
                                    Icons.timer_outlined,
                                    color: schedule['enabled']
                                        ? AppColors.accent
                                        : Colors.white38,
                                  ),
                                ),
                                title: Text(
                                  '$startTime — $endTime',
                                  style: const TextStyle(
                                    color: Colors.white,
                                    fontWeight: FontWeight.bold,
                                    fontSize: 18,
                                  ),
                                ),
                                subtitle: Text(
                                  schema_timezone_label(schedule['timezone']),
                                  style: const TextStyle(
                                    color: Colors.white54,
                                    fontSize: 12,
                                  ),
                                ),
                                trailing: Row(
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    Switch(
                                      value: schedule['enabled'],
                                      activeThumbColor: AppColors.accent,
                                      onChanged: (val) {
                                        ref
                                            .read(schedulesManagerProvider)
                                            .toggleEnabled(schedule['id'], val);
                                      },
                                    ),
                                    IconButton(
                                      icon: const Icon(
                                        Icons.delete_outline,
                                        color: Colors.white30,
                                      ),
                                      onPressed: () {
                                        ref
                                            .read(schedulesManagerProvider)
                                            .deleteSchedule(schedule['id']);
                                      },
                                    ),
                                  ],
                                ),
                              ),
                            )
                            .animate()
                            .fadeIn(delay: Duration(milliseconds: index * 100))
                            .slideX(begin: 0.1),
                  );
                },
              );
            },
            loading: () => const Center(
              child: CircularProgressIndicator(color: AppColors.primary),
            ),
            error: (err, stack) => Center(
              child: Text(
                'Error: $err',
                style: const TextStyle(color: Colors.redAccent),
              ),
            ),
          ),
        ),
      ),
      floatingActionButton: schedulesAsync.maybeWhen(
        data: (s) => s.isNotEmpty
            ? FloatingActionButton(
                onPressed: () => _showAddSchedule(context),
                backgroundColor: AppColors.primary,
                child: const Icon(Icons.add, color: Colors.white),
              )
            : null,
        orElse: () => null,
      ),
    );
  }

  String schema_timezone_label(String tz) {
    if (tz.contains('/')) return tz.split('/').last.replaceAll('_', ' ');
    return tz;
  }
}
