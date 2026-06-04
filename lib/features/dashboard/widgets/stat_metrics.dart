import 'package:angle_mvp/core/theme/app_theme.dart';
import 'package:angle_mvp/core/widgets/glass_card.dart';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

class StatMetrics extends StatelessWidget {
  const StatMetrics({super.key});

  @override
  Widget build(BuildContext context) {
    return GlassCard(
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
                child: const Icon(
                  Icons.verified_user_rounded,
                  color: Colors.greenAccent,
                ),
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
              _buildStat(context, 'Check-ins', '0/3', onTap: () => context.push('/schedules')),
              _buildStat(context, 'Contacts', '5', onTap: () => context.push('/contacts')),
              _buildStat(context, 'Incidents', '0'),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildStat(BuildContext context, String label, String value, {VoidCallback? onTap}) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(8),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
        child: Column(
          children: [
            Text(
              value,
              style: const TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
                color: Colors.white,
              ),
            ),
            const SizedBox(height: 4),
            Text(
              label,
              style: const TextStyle(fontSize: 11, color: AppColors.textSecondary),
            ),
          ],
        ),
      ),
    );
  }
}

