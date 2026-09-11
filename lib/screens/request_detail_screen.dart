import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../services/app_auth_service.dart';
import '../services/firestore_service.dart';
import '../theme/app_theme.dart';
import 'chat_screen.dart';
import '../widgets/request_step_tracker.dart';
import 'documents_screen.dart';

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
    return Scaffold(
      backgroundColor: context.bg,
      appBar: AppBar(
        title: Text(
          widget.chassisNumber,
          style: TextStyle(color: context.textPrimary, fontWeight: FontWeight.w600),
        ),
      ),
      body: SafeArea(
        child: Column(
          children: [
            // Top area (tracker + optional documents button).
            StreamBuilder<DocumentSnapshot<Map<String, dynamic>>>(
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

                return Container(
                  color: context.bg,
                  padding: const EdgeInsets.fromLTRB(16, 16, 16, 4),
                  child: Column(
                    children: [
                      RequestStepTracker(
                        status: status,
                        createdAt: createdAtTs?.toDate(),
                      ),
                      if (deliverables.isNotEmpty) ...[
                        const SizedBox(height: 14),
                        _DocumentsButton(
                          count: deliverables.length,
                          onTap: () => Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (_) => DocumentsScreen(
                                  deliverables: deliverables),
                            ),
                          ),
                        ),
                      ],
                    ],
                  ),
                );
              },
            ),
            const Expanded(child: SizedBox.shrink()),
            _MessageBarPreview(
              onTap: () => Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (_) => ChatScreen(
                    chassisNumber: widget.chassisNumber,
                    userId: AppUser.uid ?? 'unknown',
                    autofocus: true,
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// Compact, non-scrolling preview of the message bar — tapping anywhere
/// on it opens the full ChatScreen instead of expanding a message thread
/// inline on this screen.
class _MessageBarPreview extends StatelessWidget {
  final VoidCallback onTap;

  const _MessageBarPreview({required this.onTap});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(12, 0, 12, 12),
      child: Material(
        color: context.card,
        borderRadius: BorderRadius.circular(28),
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(28),
          child: Container(
            padding: const EdgeInsets.fromLTRB(8, 8, 8, 8),
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(28),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withValues(alpha: context.isDark ? 0.25 : 0.06),
                  blurRadius: 14,
                  offset: const Offset(0, 4),
                ),
              ],
            ),
            child: Row(
              children: [
                IconButton(
                  icon: const Icon(Icons.attach_file_rounded, color: AppColors.purple),
                  onPressed: onTap,
                ),
                Expanded(
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                    decoration: BoxDecoration(
                      color: context.fieldFill,
                      borderRadius: BorderRadius.circular(24),
                      border: Border.all(color: context.border, width: 1),
                    ),
                    child: Text(
                      'Message...',
                      style: TextStyle(color: context.textSecondary, fontSize: 14.5),
                    ),
                  ),
                ),
                const SizedBox(width: 8),
                CircleAvatar(
                  backgroundColor: AppColors.purple,
                  child: IconButton(
                    icon: const Icon(Icons.arrow_upward_rounded,
                        color: Colors.white, size: 20),
                    onPressed: onTap,
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

/// Compact "Your documents" entry point — replaces the old inline PDF/image
/// preview panel (which took up a lot of vertical space on this screen).
/// Tapping it opens the dedicated DocumentsScreen instead.
class _DocumentsButton extends StatelessWidget {
  final int count;
  final VoidCallback onTap;

  const _DocumentsButton({required this.count, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return Material(
      color: context.card,
      borderRadius: BorderRadius.circular(18),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(18),
        child: Container(
          width: double.infinity,
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(18),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: context.isDark ? 0.25 : 0.05),
                blurRadius: 16,
                offset: const Offset(0, 6),
              ),
            ],
          ),
          child: Row(
            children: [
              Container(
                width: 38,
                height: 38,
                decoration: BoxDecoration(
                  color: context.lilac,
                  borderRadius: BorderRadius.circular(12),
                ),
                child: const Icon(Icons.folder_rounded, color: AppColors.purple, size: 20),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Your documents',
                      style: TextStyle(
                        fontSize: 14.5,
                        fontWeight: FontWeight.w700,
                        color: context.textPrimary,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      '$count file${count == 1 ? '' : 's'} ready to view',
                      style: TextStyle(fontSize: 12, color: context.textSecondary),
                    ),
                  ],
                ),
              ),
              Icon(Icons.chevron_right_rounded, color: context.textSecondary),
            ],
          ),
        ),
      ),
    );
  }
}