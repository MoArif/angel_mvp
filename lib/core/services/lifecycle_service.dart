import 'package:angle_mvp/core/providers/supabase_provider.dart';
import 'package:angle_mvp/features/auth/providers/auth_provider.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

final lifecycleServiceProvider = Provider<LifecycleService>((ref) {
  return LifecycleService(ref);
});

class LifecycleService with WidgetsBindingObserver {
  final Ref ref;
  DateTime? _lastSignalTime;
  static const _cooldown = Duration(minutes: 5);

  LifecycleService(this.ref);

  void init() {
    WidgetsBinding.instance.addObserver(this);
    // Trigger an initial signal if the app starts directly in foreground
    _sendSignal();
  }

  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.resumed) {
      _sendSignal();
    }
  }

  Future<void> _sendSignal() async {
    final now = DateTime.now();
    if (_lastSignalTime != null && now.difference(_lastSignalTime!) < _cooldown) {
      return;
    }

    final session = ref.read(authSessionProvider).value;
    if (session == null) return;

    try {
      final client = ref.read(supabaseClientProvider);
      await client.from('activity_signals').insert({
        'user_id': session.user.id,
        'type': 'app_open',
      });
      _lastSignalTime = now;
      debugPrint('Silent check-in signal sent: app_open');
    } catch (e) {
      debugPrint('Error sending silent check-in: $e');
    }
  }
}
