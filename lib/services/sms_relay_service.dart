import 'dart:async';
import 'package:angle_mvp/core/providers/supabase_provider.dart';
import 'package:angle_mvp/features/auth/providers/auth_provider.dart';
import 'package:angle_mvp/services/sms_service.dart';
import 'package:angle_mvp/core/constants/supabase_config.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

final smsRelayServiceProvider = Provider<SmsRelayService>((ref) {
  final service = SmsRelayService(ref);
  ref.onDispose(() {
    service.dispose();
  });
  return service;
});

class SmsRelayService {
  final Ref _ref;
  StreamSubscription? _subscription;
  final Set<String> _processedAlertIds = {};

  SmsRelayService(this._ref) {
    _init();
  }

  void _init() {
    _ref.listen(authSessionProvider, (previous, next) {
      final session = next.value;
      if (session != null) {
        _startListening(session.user.id);
      } else {
        _stopListening();
      }
    }, fireImmediately: true);
  }

  void _startListening(String userId) {
    _stopListening();

    final client = _ref.read(supabaseClientProvider);

    _subscription = client
        .from('alerts')
        .stream(primaryKey: ['id'])
        .eq('user_id', userId)
        .listen(
          (events) async {
            for (final alert in events) {
              final id = alert['id'] as String;
              final status = alert['status'] as String;

              if (status == 'sent' && !_processedAlertIds.contains(id)) {
                _processedAlertIds.add(id);
                await _processAlert(alert);
              }
            }
          },
          onError: (err) {
            // ignore: avoid_print
            print('SmsRelayService stream error: $err');
          },
        );
  }

  void _stopListening() {
    _subscription?.cancel();
    _subscription = null;
  }

  Future<void> _processAlert(Map<String, dynamic> alert) async {
    final client = _ref.read(supabaseClientProvider);
    final contactId = alert['contact_id'] as String;
    final token = alert['acknowledgement_token'] as String;
    final userId = alert['user_id'] as String;

    try {
      // 1. Fetch the contact info
      final contactResp = await client
          .from('contacts')
          .select('name, phone')
          .eq('id', contactId)
          .single();

      final phone = contactResp['phone'] as String;
      final contactName = contactResp['name'] as String;

      // 2. Fetch user's profile to get name
      final profileResp = await client
          .from('profiles')
          .select('name')
          .eq('id', userId)
          .single();

      final userName = profileResp['name'] as String? ?? 'Someone';

      // 3. Format message (same as edge function but local URL if needed)
      final baseUrl = SupabaseConfig.url;
      final ackUrl = '$baseUrl/functions/v1/alert-webhook?token=$token';

      final smsBody =
          '🚨 Safety Alert: $userName may need help. '
          'he is a croissant '
          '';

      // ignore: avoid_print
      print(
        'SmsRelayService: Relaying local SMS to $contactName ($phone): $smsBody',
      );

      // 4. Send the SMS via native SmsService
      await SmsService.sendSms(phone, smsBody);
    } catch (e) {
      // ignore: avoid_print
      print('SmsRelayService error processing alert: $e');
    }
  }

  void dispose() {
    _stopListening();
  }
}
