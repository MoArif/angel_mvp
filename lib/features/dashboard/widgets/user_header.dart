import 'package:angle_mvp/features/auth/providers/auth_provider.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

class UserHeader extends ConsumerWidget {
  final AsyncValue<String?> profile;

  const UserHeader({super.key, required this.profile});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final session = ref.watch(authSessionProvider).value;

    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Hello,', style: Theme.of(context).textTheme.bodyMedium),
            profile.when(
              data: (name) => Text(
                name ?? 'Hero',
                style: Theme.of(
                  context,
                ).textTheme.displayLarge?.copyWith(fontSize: 28),
              ),
              loading: () => const Text('...'),
              error: (_, _) => Text(
                session?.user.email?.split('@').first ?? 'User',
                style: Theme.of(
                  context,
                ).textTheme.displayLarge?.copyWith(fontSize: 28),
              ),
            ),
          ],
        ),
        Row(
          children: [
            IconButton(
              onPressed: () => context.push('/contacts'),
              icon: Container(
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  color: Colors.white.withValues(alpha: 0.1),
                  shape: BoxShape.circle,
                ),
                child: const Icon(
                  Icons.people_alt_rounded,
                  color: Colors.white,
                  size: 20,
                ),
              ),
            ),
            IconButton(
              onPressed: () =>
                  ref.read(authNotifierProvider.notifier).signOut(),
              icon: Container(
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  color: Colors.redAccent.withValues(alpha: 0.1),
                  shape: BoxShape.circle,
                ),
                child: const Icon(
                  Icons.logout_rounded,
                  color: Colors.redAccent,
                  size: 20,
                ),
              ),
            ),
          ],
        ),
      ],
    );
  }
}
