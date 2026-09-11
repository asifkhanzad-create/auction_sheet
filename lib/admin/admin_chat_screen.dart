import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:file_picker/file_picker.dart';
import 'package:url_launcher/url_launcher.dart';
import '../services/firestore_service.dart';
import '../services/cloudinary_service.dart';
import 'admin_theme.dart';
import '../widgets/chat_panel.dart';

// Admin messages use this fixed senderId so they render distinctly
// from the customer (whose senderId is their own userId, e.g. "user_9921").
const String kAdminSenderId = 'admin';

class AdminChatScreen extends StatefulWidget {
  final String chassisNumber;
  final String userId;
  final String userName;
  final String initialStatus;

  const AdminChatScreen({
    super.key,
    required this.chassisNumber,
    required this.userId,
    required this.userName,
    required this.initialStatus,
  });

  @override
  State<AdminChatScreen> createState() => _AdminChatScreenState();
}

class _AdminChatScreenState extends State<AdminChatScreen> {
  bool _uploadingReport = false;
  bool _historyExpanded = false;

  @override
  void initState() {
    super.initState();
    // Clears this request's unread indicator on the dashboard as soon as
    // the admin opens the chat.
    FirestoreService.markReadByAdmin(widget.chassisNumber);
  }

  Future<void> _markInProgress(BuildContext context) async {
    await FirestoreService.markInProgress(widget.chassisNumber);
    if (context.mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Marked as sourcing in progress')),
      );
    }
  }

  Future<void> _markCompleted(BuildContext context) async {
    await FirestoreService.markCompleted(widget.chassisNumber);
    if (context.mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Marked as completed')),
      );
    }
  }

  String _relativeTime(DateTime dt) {
    final diff = DateTime.now().difference(dt);
    if (diff.inMinutes < 1) return 'just now';
    if (diff.inMinutes < 60) return '${diff.inMinutes}m ago';
    if (diff.inHours < 24) return '${diff.inHours}h ago';
    return '${diff.inDays}d ago';
  }

  Future<void> _openFile(String url) async {
    final uri = Uri.parse(url);
    if (!await launchUrl(uri, mode: LaunchMode.externalApplication)) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Could not open file.')),
        );
      }
    }
  }

  Future<void> _uploadReportFiles() async {
    final result = await FilePicker.platform.pickFiles(
      type: FileType.custom,
      allowedExtensions: ['pdf', 'png', 'jpg', 'jpeg', 'webp'],
      withData: true,
      allowMultiple: true,
    );

    if (result == null || result.files.isEmpty) return;

    setState(() => _uploadingReport = true);

    try {
      for (final picked in result.files) {
        if (picked.bytes == null) continue;

        final uploadResult = await CloudinaryService.uploadBytes(
          bytes: picked.bytes!,
          fileName: picked.name,
        );

        final isPdf = (uploadResult.format ?? '').toLowerCase() == 'pdf' ||
            picked.name.toLowerCase().endsWith('.pdf');

        await FirestoreService.addDeliverable(
          chassisNumber: widget.chassisNumber,
          fileUrl: uploadResult.url,
          fileName: uploadResult.originalFileName,
          fileType: isPdf ? 'pdf' : 'image',
        );
      }

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Report added to customer\'s screen')),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Upload failed: $e')),
        );
      }
    } finally {
      if (mounted) setState(() => _uploadingReport = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: context.bg,
      appBar: AppBar(
        backgroundColor: context.card,
        elevation: 0,
        titleSpacing: 0,
        title: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              widget.chassisNumber,
              style: TextStyle(
                color: context.textPrimary,
                fontWeight: FontWeight.w600,
                fontSize: 16,
              ),
            ),
            Text(
              widget.userName,
              style: TextStyle(color: context.textSecondary, fontSize: 12),
            ),
          ],
        ),
      ),
      body: Column(
        children: [
          StreamBuilder<DocumentSnapshot<Map<String, dynamic>>>(
            stream: FirestoreService.statusStream(widget.chassisNumber),
            builder: (context, snapshot) {
              final data = snapshot.data?.data();
              final status = data?['status'] ?? widget.initialStatus;
              final isPending = status == 'pending';
              final isInProgress = status == 'in_progress';
              final isCompleted = status == 'completed';

              final rawDeliverables = data?['deliverables'] as List<dynamic>?;
              final deliverables = rawDeliverables
                      ?.map((e) => Map<String, dynamic>.from(e as Map))
                      .toList() ??
                  [];

              return Container(
                width: double.infinity,
                padding: const EdgeInsets.fromLTRB(16, 10, 16, 12),
                decoration: BoxDecoration(
                  color: context.card,
                  border: Border(
                    bottom: BorderSide(color: context.border, width: 1),
                  ),
                ),
                child: Column(
                  children: [
                    Row(
                      children: [
                        Expanded(
                          child: OutlinedButton.icon(
                            onPressed:
                                isPending ? () => _markInProgress(context) : null,
                            icon: Icon(
                              isInProgress || isCompleted
                                  ? Icons.bolt_rounded
                                  : Icons.bolt_outlined,
                              size: 17,
                            ),
                            label: Text(
                              isInProgress
                                  ? 'Sourcing'
                                  : isCompleted
                                      ? 'Sourcing'
                                      : 'Start Sourcing',
                              style: const TextStyle(
                                  fontSize: 13, fontWeight: FontWeight.w600),
                            ),
                            style: OutlinedButton.styleFrom(
                              foregroundColor: (isInProgress || isCompleted)
                                  ? Colors.orange.shade300
                                  : AdminTheme.purple,
                              side: BorderSide(
                                color: (isInProgress || isCompleted)
                                    ? Colors.orange.withValues(alpha: 0.4)
                                    : AdminTheme.purple.withValues(alpha: 0.4),
                              ),
                              backgroundColor: (isInProgress || isCompleted)
                                  ? Colors.orange.withValues(alpha: 0.15)
                                  : Colors.transparent,
                              padding: const EdgeInsets.symmetric(vertical: 10),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(12),
                              ),
                            ),
                          ),
                        ),
                        const SizedBox(width: 10),
                        Expanded(
                          child: ElevatedButton.icon(
                            onPressed: isCompleted
                                ? null
                                : () => _markCompleted(context),
                            icon: Icon(
                              isCompleted
                                  ? Icons.check_circle_rounded
                                  : Icons.check_circle_outline_rounded,
                              size: 17,
                            ),
                            label: Text(
                              isCompleted ? 'Completed' : 'Mark Completed',
                              style: const TextStyle(
                                  fontSize: 13, fontWeight: FontWeight.w600),
                            ),
                            style: ElevatedButton.styleFrom(
                              backgroundColor: isCompleted
                                  ? Colors.green.withValues(alpha: 0.15)
                                  : AdminTheme.purple,
                              foregroundColor: isCompleted
                                  ? Colors.green.shade300
                                  : Colors.white,
                              elevation: 0,
                              padding: const EdgeInsets.symmetric(vertical: 10),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(12),
                              ),
                            ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 10),
                    SizedBox(
                      width: double.infinity,
                      child: OutlinedButton.icon(
                        onPressed: _uploadingReport ? null : _uploadReportFiles,
                        icon: _uploadingReport
                            ? const SizedBox(
                                width: 15,
                                height: 15,
                                child: CircularProgressIndicator(strokeWidth: 2),
                              )
                            : const Icon(Icons.upload_file_rounded, size: 17),
                        label: Text(
                          _uploadingReport
                              ? 'Uploading...'
                              : 'Upload Report / Photos',
                          style: const TextStyle(
                              fontSize: 13, fontWeight: FontWeight.w600),
                        ),
                        style: OutlinedButton.styleFrom(
                          foregroundColor: context.textPrimary,
                          side: BorderSide(color: context.border),
                          padding: const EdgeInsets.symmetric(vertical: 10),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                        ),
                      ),
                    ),
                    if (deliverables.isNotEmpty) ...[
                      const SizedBox(height: 10),
                      InkWell(
                        onTap: () => setState(
                            () => _historyExpanded = !_historyExpanded),
                        borderRadius: BorderRadius.circular(10),
                        child: Padding(
                          padding: const EdgeInsets.symmetric(vertical: 4),
                          child: Row(
                            children: [
                              Icon(
                                Icons.folder_outlined,
                                size: 16,
                                color: context.textSecondary,
                              ),
                              const SizedBox(width: 6),
                              Text(
                                'Documents sent (${deliverables.length})',
                                style: TextStyle(
                                  fontSize: 12,
                                  fontWeight: FontWeight.w600,
                                  color: context.textSecondary,
                                ),
                              ),
                              const Spacer(),
                              Icon(
                                _historyExpanded
                                    ? Icons.keyboard_arrow_up_rounded
                                    : Icons.keyboard_arrow_down_rounded,
                                size: 18,
                                color: context.textSecondary,
                              ),
                            ],
                          ),
                        ),
                      ),
                      if (_historyExpanded) ...[
                        const SizedBox(height: 6),
                        ...deliverables.reversed.map((d) {
                          final fileName =
                              (d['fileName'] ?? 'file').toString();
                          final fileType =
                              (d['fileType'] ?? 'file').toString();
                          final fileUrl = (d['fileUrl'] ?? '').toString();
                          final sentAtTs = d['sentAt'] as Timestamp?;
                          return InkWell(
                            onTap: fileUrl.isEmpty
                                ? null
                                : () => _openFile(fileUrl),
                            borderRadius: BorderRadius.circular(8),
                            child: Padding(
                              padding:
                                  const EdgeInsets.symmetric(vertical: 4),
                              child: Row(
                                children: [
                                  Icon(
                                    fileType == 'pdf'
                                        ? Icons.picture_as_pdf_rounded
                                        : Icons.image_rounded,
                                    size: 15,
                                    color: AdminTheme.purple,
                                  ),
                                  const SizedBox(width: 8),
                                  Expanded(
                                    child: Text(
                                      fileName,
                                      overflow: TextOverflow.ellipsis,
                                      style: TextStyle(
                                        fontSize: 12,
                                        color: context.textPrimary,
                                        decoration:
                                            TextDecoration.underline,
                                        decorationColor:
                                            context.textSecondary,
                                      ),
                                    ),
                                  ),
                                  const SizedBox(width: 6),
                                  if (sentAtTs != null)
                                    Text(
                                      _relativeTime(sentAtTs.toDate()),
                                      style: TextStyle(
                                        fontSize: 11,
                                        color: context.textSecondary,
                                      ),
                                    ),
                                  const SizedBox(width: 4),
                                  Icon(
                                    Icons.open_in_new_rounded,
                                    size: 13,
                                    color: context.textSecondary,
                                  ),
                                ],
                              ),
                            ),
                          );
                        }),
                      ],
                    ],
                  ],
                ),
              );
            },
          ),
          Expanded(
            child: ChatPanel(
              chassisNumber: widget.chassisNumber,
              userId: kAdminSenderId,
            ),
          ),
        ],
      ),
    );
  }
}