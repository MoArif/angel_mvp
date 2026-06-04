import 'package:angle_mvp/core/providers/supabase_provider.dart';
import 'package:angle_mvp/features/auth/providers/auth_provider.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_timezone/flutter_timezone.dart';

final schedulesProvider = StreamProvider<List<Map<String, dynamic>>>((ref) async* {
  final client = ref.watch(supabaseClientProvider);
  final session = ref.watch(authSessionProvider).value;

  if (session == null) {
    yield [];
    return;
  }

  yield* client
      .from('checkin_schedules')
      .stream(primaryKey: ['id'])
      .eq('user_id', session.user.id)
      .order('start_time', ascending: true);
});

final schedulesManagerProvider = Provider<SchedulesManager>((ref) {
  return SchedulesManager(ref);
});

class SchedulesManager {
  final Ref ref;

  SchedulesManager(this.ref);

  Future<void> addSchedule(TimeOfDay start, TimeOfDay end) async {
    final client = ref.read(supabaseClientProvider);
    final session = ref.read(authSessionProvider).value;
    
    if (session == null) throw Exception('No user found');

    final timezoneObj = await FlutterTimezone.getLocalTimezone();
    final String timezone = timezoneObj.toString();

    await client.from('checkin_schedules').insert({
      'user_id': session.user.id,
      'start_time': _formatTime(start),
      'end_time': _formatTime(end),
      'timezone': timezone,
      'enabled': true,
    });
    
    ref.invalidate(schedulesProvider);
  }

  Future<void> deleteSchedule(String id) async {
    final client = ref.read(supabaseClientProvider);
    await client.from('checkin_schedules').delete().eq('id', id);
    ref.invalidate(schedulesProvider);
  }

  Future<void> toggleEnabled(String id, bool enabled) async {
    final client = ref.read(supabaseClientProvider);
    await client.from('checkin_schedules').update({'enabled': enabled}).eq('id', id);
    ref.invalidate(schedulesProvider);
  }

  String _formatTime(TimeOfDay time) {
    final String hour = time.hour.toString().padLeft(2, '0');
    final String minute = time.minute.toString().padLeft(2, '0');
    return '$hour:$minute:00';
  }
}
