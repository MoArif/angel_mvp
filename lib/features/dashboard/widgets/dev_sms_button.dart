import 'package:angle_mvp/features/contacts/providers/contacts_provider.dart';
import 'package:angle_mvp/services/sms_service.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

const _defaultMessage = '🚨 [DEV TEST] Test Test Testicles ';

class DevSmsButton extends ConsumerStatefulWidget {
  const DevSmsButton({super.key});

  @override
  ConsumerState<DevSmsButton> createState() => _DevSmsButtonState();
}

class _DevSmsButtonState extends ConsumerState<DevSmsButton> {
  bool _isSending = false;
  String? _lastStatus; // 'success' | 'error'

  void _showErrorDialog(String errorMessage, {String? phone, String? name}) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: Colors.grey.shade900,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: const Row(
          children: [
            Icon(Icons.warning_amber_rounded, color: Colors.orangeAccent),
            SizedBox(width: 8),
            Text(
              'SMS Failed',
              style: TextStyle(
                color: Colors.white,
                fontSize: 18,
                fontWeight: FontWeight.bold,
              ),
            ),
          ],
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              errorMessage,
              style: const TextStyle(color: Colors.white70, fontSize: 13),
            ),
            if (phone != null && name != null) ...[
              const SizedBox(height: 16),
              const Text(
                'You can copy the message below and send it manually:',
                style: TextStyle(color: Colors.white54, fontSize: 12),
              ),
              const SizedBox(height: 8),
              Container(
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  color: Colors.black26,
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Text(
                  _defaultMessage,
                  style: const TextStyle(color: Colors.white70, fontSize: 13),
                ),
              ),
            ],
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('Close', style: TextStyle(color: Colors.white54)),
          ),
          if (phone != null)
            ElevatedButton(
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.orangeAccent,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(8),
                ),
              ),
              onPressed: () {
                Clipboard.setData(ClipboardData(text: _defaultMessage));
                Navigator.of(context).pop();
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(
                    content: Text('Message copied to clipboard!'),
                    backgroundColor: Colors.green,
                  ),
                );
              },
              child: const Text(
                'Copy Message',
                style: TextStyle(
                  color: Colors.black,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
        ],
      ),
    );
  }

  Future<void> _sendTestSms(List<Map<String, dynamic>> contacts) async {
    // Find priority 1 contact, fallback to first contact
    final target = contacts.firstWhere(
      (c) => c['priority'] == 1,
      orElse: () => contacts.first,
    );

    final phone = (target['phone'] as String).replaceAll(' ', '');
    final name = target['name'] as String;

    setState(() {
      _isSending = true;
      _lastStatus = null;
    });

    try {
      await SmsService.sendSms(phone, _defaultMessage);

      if (mounted) {
        setState(() => _lastStatus = 'success');
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Row(
              children: [
                const Icon(Icons.check_circle_outline, color: Colors.white),
                const SizedBox(width: 12),
                Expanded(child: Text('✅ SMS sent silently to $name ($phone)')),
              ],
            ),
            backgroundColor: Colors.green.shade700,
            behavior: SnackBarBehavior.floating,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12),
            ),
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        setState(() => _lastStatus = 'error');
        _showErrorDialog(e.toString(), phone: phone, name: name);
      }
    } finally {
      if (mounted) setState(() => _isSending = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final contactsAsync = ref.watch(contactsProvider);

    return contactsAsync.when(
      data: (contacts) {
        if (contacts.isEmpty) {
          return _buildButton(
            label: '⚠ No contacts – Add one first',
            subtitle: 'DEV ONLY • Sends SMS silently',
            onTap: null,
          );
        }

        final priority1 = contacts.firstWhere(
          (c) => c['priority'] == 1,
          orElse: () => contacts.first,
        );
        final name = priority1['name'] as String;

        String label;
        if (_isSending) {
          label = 'Sending…';
        } else if (_lastStatus == 'success') {
          label = '✅ Sent! Tap to resend to $name';
        } else {
          label = '📡 DEV: Fire Silent SMS → $name';
        }

        return _buildButton(
          label: label,
          subtitle: 'DEV ONLY • No user interaction needed',
          onTap: _isSending ? null : () => _sendTestSms(contacts),
        );
      },
      loading: () => _buildButton(
        label: 'Loading contacts…',
        subtitle: 'DEV ONLY • Sends SMS silently',
        onTap: null,
      ),
      error: (e, _) => _buildButton(
        label: 'Error loading contacts',
        subtitle: 'DEV ONLY • Sends SMS silently',
        onTap: null,
      ),
    );
  }

  Widget _buildButton({
    required String label,
    required String subtitle,
    required VoidCallback? onTap,
  }) {
    final borderColor = _lastStatus == 'success'
        ? Colors.greenAccent.withValues(alpha: 0.6)
        : Colors.orangeAccent.withValues(alpha: 0.6);
    final bgColor = _lastStatus == 'success'
        ? Colors.green.withValues(alpha: 0.08)
        : Colors.orange.withValues(alpha: 0.08);
    final iconColor = _lastStatus == 'success'
        ? Colors.greenAccent
        : Colors.orangeAccent;

    return Container(
      width: double.infinity,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: borderColor, width: 1.5),
        color: bgColor,
      ),
      child: Material(
        color: Colors.transparent,
        borderRadius: BorderRadius.circular(16),
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(16),
          splashColor: Colors.orangeAccent.withValues(alpha: 0.2),
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
            child: Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: iconColor.withValues(alpha: 0.15),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: Icon(
                    _lastStatus == 'success'
                        ? Icons.check_circle_outline
                        : Icons.send_rounded,
                    color: iconColor,
                    size: 22,
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        label,
                        style: TextStyle(
                          color: iconColor,
                          fontWeight: FontWeight.bold,
                          fontSize: 14,
                        ),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        subtitle,
                        style: TextStyle(
                          color: Colors.orange.withValues(alpha: 0.7),
                          fontSize: 11,
                        ),
                      ),
                    ],
                  ),
                ),
                if (_isSending)
                  const SizedBox(
                    width: 18,
                    height: 18,
                    child: CircularProgressIndicator(
                      strokeWidth: 2,
                      color: Colors.orangeAccent,
                    ),
                  )
                else
                  Icon(Icons.chevron_right, color: iconColor),
              ],
            ),
          ),
        ),
      ),
    ).animate().fadeIn(delay: 500.ms).slideY(begin: 0.1);
  }
}
