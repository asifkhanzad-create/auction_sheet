import 'package:flutter/material.dart';
import '../theme/app_theme.dart';

/// Shown in place of a StreamBuilder's content when snapshot.hasError is
/// true — replaces what would otherwise be an infinite loading spinner
/// with a clear message and a way to retry.
///
/// Firestore stream errors (permission-denied, missing index, offline,
/// etc.) close the stream entirely rather than re-emitting — so "retry"
/// here means rebuilding the StreamBuilder itself via a key change,
/// which re-subscribes a fresh stream.
class StreamErrorView extends StatelessWidget {
  final VoidCallback onRetry;
  final String? message;

  const StreamErrorView({
    super.key,
    required this.onRetry,
    this.message,
  });

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.cloud_off_rounded, size: 40, color: context.textSecondary),
            const SizedBox(height: 12),
            Text(
              message ?? 'Something went wrong loading this.',
              textAlign: TextAlign.center,
              style: TextStyle(color: context.textSecondary, fontSize: 13),
            ),
            const SizedBox(height: 16),
            OutlinedButton.icon(
              onPressed: onRetry,
              icon: const Icon(Icons.refresh_rounded, size: 18),
              label: const Text('Retry'),
              style: OutlinedButton.styleFrom(
                foregroundColor: AppColors.purple,
                side: const BorderSide(color: AppColors.purple),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(14),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}