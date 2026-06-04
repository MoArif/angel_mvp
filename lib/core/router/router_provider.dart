import 'package:angle_mvp/features/auth/providers/auth_provider.dart';
import 'package:angle_mvp/features/auth/screens/login_screen.dart';
import 'package:angle_mvp/features/auth/screens/signup_screen.dart';
import 'package:angle_mvp/features/dashboard/screens/dashboard_screen.dart';
import 'package:angle_mvp/features/onboarding/screens/onboarding_screen.dart';
import 'package:angle_mvp/features/contacts/screens/contacts_screen.dart';
import 'package:angle_mvp/features/schedules/screens/schedules_screen.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

final routerProvider = Provider<GoRouter>((ref) {
  final authState = ref.watch(authSessionProvider);
  final profileState = ref.watch(profileProvider);

  return GoRouter(
    initialLocation: '/',
    redirect: (context, state) {
      final session = authState.value;
      final profile = profileState.value;

      final isLoggingIn =
          state.matchedLocation == '/login' ||
          state.matchedLocation == '/signup';

      final isOnboarding = state.matchedLocation == '/onboarding';

      if (session == null) {
        return isLoggingIn ? null : '/login';
      }

      // If logged in but profile is still loading, stay on the loading page (or let it hit dashboard briefly)
      if (profileState.isLoading) {
        return null;
      }

      // If user profile exists, check if timezone is null
      final needsOnboarding = profile == null || profile['timezone'] == null;

      if (needsOnboarding) {
        return isOnboarding ? null : '/onboarding';
      }

      // If we are logged in, don't need onboarding, but are on auth pages or root or onboarding, go to dashboard
      if (isLoggingIn || state.matchedLocation == '/' || isOnboarding) {
        return '/dashboard';
      }

      return null;
    },
    routes: [
      GoRoute(
        path: '/',
        builder: (context, state) =>
            const Scaffold(body: Center(child: CircularProgressIndicator())),
      ),
      GoRoute(path: '/login', builder: (context, state) => const LoginScreen()),
      GoRoute(
        path: '/signup',
        builder: (context, state) => const SignupScreen(),
      ),
      GoRoute(
        path: '/onboarding',
        builder: (context, state) => const OnboardingScreen(),
      ),
      GoRoute(
        path: '/dashboard',
        builder: (context, state) => const DashboardScreen(),
      ),
      GoRoute(
        path: '/contacts',
        builder: (context, state) => const ContactsScreen(),
      ),
      GoRoute(
        path: '/schedules',
        builder: (context, state) => const SchedulesScreen(),
      ),
    ],
  );
});
