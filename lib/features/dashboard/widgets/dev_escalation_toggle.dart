import 'package:angle_mvp/core/providers/supabase_provider.dart';
import 'package:angle_mvp/features/auth/providers/auth_provider.dart';
import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

class DevEscalationToggle extends ConsumerStatefulWidget {
  const DevEscalationToggle({super.key});

  @override
  ConsumerState<DevEscalationToggle> createState() => _DevEscalationToggleState();
}

class _DevEscalationToggleState extends ConsumerState<DevEscalationToggle> {
  bool _isUpdating = false;

  Future<void> _toggleEscalation(bool value, String userId) async {
    setState(() => _isUpdating = true);
    try {
      final client = ref.read(supabaseClientProvider);
      await client.from('profiles').update({
        'short_escalation': value,
      }).eq('id', userId);

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(value
                ? '⚡ 2-min escalation enabled for testing!'
                : '🛡 30-min default escalation restored.'),
            backgroundColor: value ? Colors.orangeAccent.shade700 : Colors.green.shade700,
            behavior: SnackBarBehavior.floating,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12),
            ),
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Failed to update escalation timeframe: $e'),
            backgroundColor: Colors.red.shade700,
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() => _isUpdating = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final profileAsync = ref.watch(profileProvider);

    return profileAsync.when(
      data: (profile) {
        if (profile == null) {
          return _buildToggle(
            label: 'No profile found',
            value: false,
            onChanged: null,
          );
        }

        final isShort = profile['short_escalation'] as bool? ?? false;
        final userId = profile['id'] as String;

        return _buildToggle(
          label: 'Shorten Escalation (2 mins)',
          subtitle: 'Shortens inactivity check to 2 mins for testing',
          value: isShort,
          onChanged: _isUpdating ? null : (val) => _toggleEscalation(val, userId),
        );
      },
      loading: () => _buildToggle(
        label: 'Loading settings…',
        value: false,
        onChanged: null,
      ),
      error: (e, _) => _buildToggle(
        label: 'Error loading settings',
        value: false,
        onChanged: null,
      ),
    );
  }

  Widget _buildToggle({
    required String label,
    String? subtitle,
    required bool value,
    required ValueChanged<bool>? onChanged,
  }) {
    final borderColor = value
        ? Colors.orangeAccent.withValues(alpha: 0.6)
        : Colors.orangeAccent.withValues(alpha: 0.3);
    final bgColor = value
        ? Colors.orange.withValues(alpha: 0.08)
        : Colors.orange.withValues(alpha: 0.02);
    final iconColor = value ? Colors.orangeAccent : Colors.white60;

    return Container(
      width: double.infinity,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: borderColor, width: 1.5),
        color: bgColor,
      ),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: iconColor.withValues(alpha: 0.15),
                borderRadius: BorderRadius.circular(10),
              ),
              child: Icon(
                value ? Icons.timer_outlined : Icons.timer_off_outlined,
                color: iconColor,
                size: 22,
              ),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    label,
                    style: TextStyle(
                      color: value ? Colors.orangeAccent : Colors.white,
                      fontWeight: FontWeight.bold,
                      fontSize: 14,
                    ),
                  ),
                  if (subtitle != null) ...[
                    const SizedBox(height: 2),
                    Text(
                      subtitle,
                      style: TextStyle(
                        color: Colors.white54,
                        fontSize: 11,
                      ),
                    ),
                  ],
                ],
              ),
            ),
            if (_isUpdating)
              const SizedBox(
                width: 18,
                height: 18,
                child: CircularProgressIndicator(
                  strokeWidth: 2,
                  color: Colors.orangeAccent,
                ),
              )
            else
              Switch.adaptive(
                value: value,
                onChanged: onChanged,
                activeThumbColor: Colors.orangeAccent,
                activeTrackColor: Colors.orangeAccent.withValues(alpha: 0.3),
                inactiveThumbColor: Colors.grey,
                inactiveTrackColor: Colors.grey.withValues(alpha: 0.2),
              ),
          ],
        ),
      ),
    ).animate().fadeIn(delay: 400.ms).slideY(begin: 0.1);
  }
}
