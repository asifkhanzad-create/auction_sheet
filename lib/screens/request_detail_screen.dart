import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../services/app_auth_service.dart';
import '../services/firestore_service.dart';
import '../theme/app_theme.dart';
import '../widgets/chat_panel.dart';
import '../widgets/request_step_tracker.dart';
import '../widgets/report_panel.dart';

/// The waiting/status + chat view for a single request.
/// Opened right after submitting a new request, or from "My Requests" history.
class RequestDetailScreen extends StatelessWidget {
  final String chassisNumber;

  const RequestDetailScreen({super.key, required this.chassisNumber});

  @override
  Widget build(BuildContext context) {
    // Tied directly to whether the on-screen keyboard is actually visible —
    // this can never get "stuck" the way a focus-listener flag can.
    final keyboardVisible = MediaQuery.of(context).viewInsets.bottom > 0;

    return Scaffold(
      appBar: AppBar(
        title: Text(
          chassisNumber,
          style: TextStyle(color: context.textPrimary, fontWeight: FontWeight.w600),
        ),
      ),
      body: SafeArea(
        child: Column(
          children: [
            // Top area (tracker + optional report panel) — collapses smoothly
            // out of view whenever the keyboard is on screen, so it never has
            // to fight the keyboard for space. Reappears once the keyboard closes.
            AnimatedSize(
              duration: const Duration(milliseconds: 220),
              curve: Curves.easeInOut,
              child: keyboardVisible
                  ? const SizedBox(width: double.infinity, height: 0)
                  : StreamBuilder<DocumentSnapshot<Map<String, dynamic>>>(
                      stream: FirestoreService.statusStream(chassisNumber),
                      builder: (context, snapshot) {
                        final data = snapshot.data?.data();
                        final status = data?['status'] ?? 'pending';
                        final isCompleted = status == 'completed';

                        final rawDeliverables =
                            data?['deliverables'] as List<dynamic>?;
                        final deliverables = rawDeliverables
                                ?.map((e) =>
                                    Map<String, dynamic>.from(e as Map))
                                .toList() ??
                            [];

                        return Column(
                          children: [
                            Container(
                              width: double.infinity,
                              padding: const EdgeInsets.fromLTRB(24, 16, 24, 16),
                              decoration: BoxDecoration(
                                color: context.card,
                                border: Border(
                                  bottom: BorderSide(color: context.border, width: 1),
                                ),
                              ),
                              child: Column(
                                children: [
                                  RequestStepTracker(status: status),
                                  const SizedBox(height: 14),
                                  Text(
                                    isCompleted
                                        ? 'Your auction sheet is ready!'
                                        : status == 'in_progress'
                                            ? 'We\'re actively sourcing your auction sheet.'
                                            : 'Your request has been received.',
                                    textAlign: TextAlign.center,
                                    style: TextStyle(
                                      fontSize: 15,
                                      fontWeight: FontWeight.w600,
                                      color: context.textPrimary,
                                    ),
                                  ),
                                  if (!isCompleted) ...[
                                    const SizedBox(height: 4),
                                    Text(
                                      'This can take 10–30 minutes. Track it live below.',
                                      textAlign: TextAlign.center,
                                      style: TextStyle(
                                          fontSize: 12, color: context.textSecondary),
                                    ),
                                  ],
                                ],
                              ),
                            ),
                            if (deliverables.isNotEmpty)
                              ReportPanel(deliverables: deliverables),
                          ],
                        );
                      },
                    ),
            ),
            const Divider(height: 1),
            Expanded(
              child: ChatPanel(
                chassisNumber: chassisNumber,
                userId: AppUser.uid ?? 'unknown',
              ),
            ),
          ],
        ),
      ),
    );
  }
}