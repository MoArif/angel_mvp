import 'package:angle_mvp/core/theme/app_theme.dart';
import 'package:angle_mvp/core/widgets/glass_card.dart';
import 'package:flutter/material.dart';

class RecentActivityList extends StatelessWidget {
  const RecentActivityList({super.key});

  @override
  Widget build(BuildContext context) {
    return ListView.separated(
      physics: const NeverScrollableScrollPhysics(),
      shrinkWrap: true,
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
    );
  }
}
