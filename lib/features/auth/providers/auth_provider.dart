import 'dart:async';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:angle_mvp/core/providers/supabase_provider.dart';

/// Provider for the Supabase Session.
final authSessionProvider = StreamProvider<Session?>((ref) async* {
  final client = ref.watch(supabaseClientProvider);
  
  // Emit the current session immediately if it exists
  yield client.auth.currentSession;
  
  // Then listen for changes
  yield* client.auth.onAuthStateChange.map((event) => event.session);
});

/// Notifier to handle authentication logic.
class AuthNotifier extends AsyncNotifier<String?> {
  @override
  FutureOr<String?> build() async {
    return null;
  }

  Future<bool> signIn({required String email, required String password}) async {
    state = const AsyncLoading();
    bool success = true;
    
    state = await AsyncValue.guard(() async {
      try {
        final client = ref.read(supabaseClientProvider);
        await client.auth.signInWithPassword(
          email: email,
          password: password,
        );
        return null;
      } catch (e) {
        success = false;
        rethrow;
      }
    });
    
    return success;
  }

  Future<bool> signUp({
    required String name,
    required String email,
    required String password,
  }) async {
    state = const AsyncLoading();
    bool success = true;

    state = await AsyncValue.guard(() async {
      try {
        final client = ref.read(supabaseClientProvider);
        await client.auth.signUp(
          email: email,
          password: password,
          data: {'name': name},
        );
        return null;
      } catch (e) {
        success = false;
        rethrow;
      }
    });
    
    return success;
  }

  // ... (signOut remains same, but returns !state.hasError)
  Future<bool> signOut() async {
    state = const AsyncLoading();
    state = await AsyncValue.guard(() async {
      await ref.read(supabaseClientProvider).auth.signOut();
      return null;
    });
    return !state.hasError;
  }
}

final authNotifierProvider =
    AsyncNotifierProvider<AuthNotifier, String?>(AuthNotifier.new);
