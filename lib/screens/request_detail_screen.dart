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
class RequestDetailScreen extends StatefulWidget {
  final String chassisNumber;

  const RequestDetailScreen({super.key, required this.chassisNumber});

  @override
  State<RequestDetailScreen> createState() => _RequestDetailScreenState();
}

class _RequestDetailScreenState extends State<RequestDetailScreen> {
  // Bumped to force the status StreamBuilder to re-subscribe on retry —
  // Firestore streams close permanently on error rather than re-emitting.
  int _retryKey = 0;

  @override
  Widget build(BuildContext context) {
    // Tied directly to whether the on-screen keyboard is actually visible —
    // this can never get "stuck" the way a focus-listener flag can.
    final keyboardVisible = MediaQuery.of(context).viewInsets.bottom > 0;

    return Scaffold(
      appBar: AppBar(
        title: Text(
          widget.chassisNumber,
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
                      key: ValueKey(_retryKey),
                      stream: FirestoreService.statusStream(widget.chassisNumber),
                      builder: (context, snapshot) {
                        if (snapshot.hasError) {
                          return Container(
                            width: double.infinity,
                            padding: const EdgeInsets.all(20),
                            color: context.card,
                            child: Column(
                              children: [
                                Text(
                                  'Couldn\'t load the status for this request.',
                                  textAlign: TextAlign.center,
                                  style: TextStyle(
                                      fontSize: 13, color: context.textSecondary),
                                ),
                                const SizedBox(height: 10),
                                OutlinedButton.icon(
                                  onPressed: () => setState(() => _retryKey++),
                                  icon: const Icon(Icons.refresh_rounded, size: 16),
                                  label: const Text('Retry'),
                                  style: OutlinedButton.styleFrom(
                                    foregroundColor: AppColors.purple,
                                    side: const BorderSide(color: AppColors.purple),
                                  ),
                                ),
                              ],
                            ),
                          );
                        }

                        final data = snapshot.data?.data();
                        final status = data?['status'] ?? 'pending';

                        final rawDeliverables =
                            data?['deliverables'] as List<dynamic>?;
                        final deliverables = rawDeliverables
                                ?.map((e) =>
                                    Map<String, dynamic>.from(e as Map))
                                .toList() ??
                            [];

                        final createdAtTs = data?['createdAt'] as Timestamp?;

                        return ConstrainedBox(
                          constraints: BoxConstraints(
                            maxHeight: MediaQuery.of(context).size.height * 0.55,
                          ),
                          child: SingleChildScrollView(
                            child: Column(
                              children: [
                                Container(
                                  width: double.infinity,
                                  padding: const EdgeInsets.fromLTRB(20, 16, 20, 20),
                                  decoration: BoxDecoration(
                                    color: context.card,
                                    border: Border(
                                      bottom: BorderSide(color: context.border, width: 1),
                                    ),
                                  ),
                                  child: RequestStepTracker(
                                    status: status,
                                    createdAt: createdAtTs?.toDate(),
                                  ),
                                ),
                                if (deliverables.isNotEmpty)
                                  ReportPanel(deliverables: deliverables),
                              ],
                            ),
                          ),
                        );
                      },
                    ),
            ),
            const Divider(height: 1),
            Expanded(
              child: ChatPanel(
                chassisNumber: widget.chassisNumber,
                userId: AppUser.uid ?? 'unknown',
              ),
            ),
          ],
        ),
      ),
    );
  }
}