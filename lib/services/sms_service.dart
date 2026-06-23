import 'dart:io';
import 'package:flutter/services.dart';
import 'package:permission_handler/permission_handler.dart';

/// Sends SMS silently via Android's native SmsManager (no user interaction).
/// On non-Android platforms this throws [UnsupportedError].
class SmsService {
  static const _channel = MethodChannel('com.angel.sms/send');

  /// Requests the SEND_SMS permission and fires the message.
  /// Throws a descriptive [Exception] on failure.
  static Future<void> sendSms(String phoneNumber, String message) async {
    if (!Platform.isAndroid) {
      throw UnsupportedError('Silent SMS is only supported on Android.');
    }

    // Ensure the SEND_SMS runtime permission is granted
    final status = await Permission.sms.request();
    if (!status.isGranted) {
      if (status.isPermanentlyDenied) {
        throw Exception(
          'SMS permission permanently denied. '
          'Please enable it in your device Settings → App Permissions.',
        );
      }
      throw Exception('SMS permission denied by user.');
    }

    try {
      await _channel.invokeMethod<String>('sendSms', {
        'phone': phoneNumber.replaceAll(' ', ''),
        'message': message,
      });
      // result is "SMS sent successfully to <phone>"
      return;
    } on PlatformException catch (e) {
      throw Exception('Failed to send SMS: ${e.message}');
    }
  }
}
