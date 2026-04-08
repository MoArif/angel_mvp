import 'package:angle_mvp/core/providers/supabase_provider.dart';
import 'package:angle_mvp/features/auth/providers/auth_provider.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

final checkinManagerProvider = Provider<CheckinManager>((ref) {
  return CheckinManager(ref);
});

class CheckinManager {
  final Ref ref;

  CheckinManager(this.ref);

  Future<void> sendManualCheckin() async {
    final client = ref.read(supabaseClientProvider);
    final session = ref.read(authSessionProvider).value;
    
    if (session == null) {
      throw Exception('No user found');
    }

    await client.from('activity_signals').insert({
      'user_id': session.user.id,
      'type': 'manual_checkin',
    });
  }
}
