import 'package:angle_mvp/core/theme/app_theme.dart';
import 'package:angle_mvp/features/dashboard/providers/checkin_provider.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

class ManualCheckinButton extends ConsumerStatefulWidget {
  const ManualCheckinButton({super.key});

  @override
  ConsumerState<ManualCheckinButton> createState() => _ManualCheckinButtonState();
}

class _ManualCheckinButtonState extends ConsumerState<ManualCheckinButton> {
  bool _isLoading = false;

  Future<void> _handleCheckin() async {
    setState(() => _isLoading = true);
    
    try {
      await ref.read(checkinManagerProvider).sendManualCheckin();
      
      if (mounted) {
        setState(() => _isLoading = false);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: const Row(
              children: [
                Icon(Icons.check_circle_outline, color: Colors.white),
                SizedBox(width: 12),
                Text('Signal Transmitted. You are marked Safe.', style: TextStyle(fontWeight: FontWeight.bold)),
              ],
            ),
            backgroundColor: Colors.green.shade600,
            behavior: SnackBarBehavior.floating,
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        setState(() => _isLoading = false);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Failed to transmit signal: $e'),
            backgroundColor: Colors.redAccent,
          ),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [AppColors.accent.withValues(alpha: 0.8), AppColors.accent],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(24),
        boxShadow: [
          BoxShadow(
            color: AppColors.accent.withValues(alpha: 0.3),
            blurRadius: 20,
            offset: const Offset(0, 10),
          )
        ],
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: _isLoading ? null : _handleCheckin,
          borderRadius: BorderRadius.circular(24),
          child: Padding(
            padding: const EdgeInsets.symmetric(vertical: 20),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                if (_isLoading)
                  const SizedBox(
                    width: 28,
                    height: 28,
                    child: CircularProgressIndicator(color: Colors.white, strokeWidth: 3),
                  )
                else
                  const Icon(Icons.shield_outlined, color: Colors.white, size: 28),
                const SizedBox(width: 12),
                const Text(
                  "I'm OK",
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 22,
                    fontWeight: FontWeight.bold,
                    letterSpacing: 1.2,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
