import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:file_picker/file_picker.dart';
import '../services/firestore_service.dart';
import '../services/cloudinary_service.dart';
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
      backgroundColor: const Color(0xFFFAFAFC),
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        titleSpacing: 0,
        title: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              widget.chassisNumber,
              style: const TextStyle(
                color: Color(0xFF1A1A2E),
                fontWeight: FontWeight.w600,
                fontSize: 16,
              ),
            ),
            Text(
              widget.userName,
              style: const TextStyle(color: Colors.black45, fontSize: 12),
            ),
          ],
        ),
      ),
      body: Column(
        children: [
          StreamBuilder<DocumentSnapshot<Map<String, dynamic>>>(
            stream: FirestoreService.statusStream(widget.chassisNumber),
            builder: (context, snapshot) {
              final status =
                  snapshot.data?.data()?['status'] ?? widget.initialStatus;
              final isPending = status == 'pending';
              final isInProgress = status == 'in_progress';
              final isCompleted = status == 'completed';

              return Container(
                width: double.infinity,
                padding: const EdgeInsets.fromLTRB(16, 10, 16, 12),
                decoration: const BoxDecoration(
                  color: Colors.white,
                  border: Border(
                    bottom: BorderSide(color: Color(0xFFF0F0F5), width: 1),
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
                                  ? Colors.orange.shade700
                                  : const Color(0xFF6C63FF),
                              side: BorderSide(
                                color: (isInProgress || isCompleted)
                                    ? Colors.orange.shade200
                                    : const Color(0xFF6C63FF).withValues(alpha: 0.4),
                              ),
                              backgroundColor: (isInProgress || isCompleted)
                                  ? Colors.orange.shade50
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
                                  ? Colors.green.shade50
                                  : const Color(0xFF6C63FF),
                              foregroundColor: isCompleted
                                  ? Colors.green.shade700
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
                          foregroundColor: const Color(0xFF1A1A2E),
                          side: const BorderSide(color: Color(0xFFDADADF)),
                          padding: const EdgeInsets.symmetric(vertical: 10),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                        ),
                      ),
                    ),
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