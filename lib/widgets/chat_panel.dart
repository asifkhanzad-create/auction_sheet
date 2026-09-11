import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:file_picker/file_picker.dart';
import 'package:url_launcher/url_launcher.dart';
import '../services/firestore_service.dart';
import '../services/cloudinary_service.dart';
import '../theme/app_theme.dart';
import 'stream_error_view.dart';

class ChatPanel extends StatefulWidget {
  final String chassisNumber;
  final String userId;
  final ValueChanged<bool>? onFocusChange;

  const ChatPanel({
    super.key,
    required this.chassisNumber,
    required this.userId,
    this.onFocusChange,
  });

  @override
  State<ChatPanel> createState() => _ChatPanelState();
}

class _ChatPanelState extends State<ChatPanel> {
  final _controller = TextEditingController();
  final _focusNode = FocusNode();
  bool _uploading = false;
  // Bumped to force the chat StreamBuilder to re-subscribe on retry —
  // Firestore streams close permanently on error rather than re-emitting.
  int _retryKey = 0;

  @override
  void initState() {
    super.initState();
    _focusNode.addListener(() {
      widget.onFocusChange?.call(_focusNode.hasFocus);
    });
  }

  @override
  void dispose() {
    _focusNode.dispose();
    _controller.dispose();
    super.dispose();
  }

  Future<void> _send() async {
    final text = _controller.text.trim();
    if (text.isEmpty) return;
    _controller.clear();
    try {
      await FirestoreService.sendMessage(
        chassisNumber: widget.chassisNumber,
        senderId: widget.userId,
        text: text,
      );
    } catch (e) {
      _showError('Message failed to send: $e');
    }
  }

  Future<void> _pickAndUploadFile() async {
    final result = await FilePicker.platform.pickFiles(
      type: FileType.custom,
      allowedExtensions: ['pdf', 'png', 'jpg', 'jpeg', 'webp'],
      withData: true, // ensures bytes are available on all platforms
    );

    if (result == null || result.files.isEmpty) return;
    final picked = result.files.first;

    if (picked.bytes == null) {
      _showError('Could not read file data.');
      return;
    }

    setState(() => _uploading = true);

    try {
      final uploadResult = await CloudinaryService.uploadBytes(
        bytes: picked.bytes!,
        fileName: picked.name,
      );

      await FirestoreService.sendFileMessage(
        chassisNumber: widget.chassisNumber,
        senderId: widget.userId,
        fileUrl: uploadResult.url,
        fileName: uploadResult.originalFileName,
        fileType: uploadResult.displayType, // "image" | "file"
      );
    } catch (e) {
      _showError('Upload failed: $e');
    } finally {
      if (mounted) setState(() => _uploading = false);
    }
  }

  void _showError(String message) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(message)),
    );
  }

  Future<void> _openFile(String url) async {
    final uri = Uri.parse(url);
    if (!await launchUrl(uri, mode: LaunchMode.externalApplication)) {
      _showError('Could not open file.');
    }
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Expanded(
          child: StreamBuilder<QuerySnapshot<Map<String, dynamic>>>(
            key: ValueKey(_retryKey),
            stream: FirestoreService.chatStream(widget.chassisNumber),
            builder: (context, snapshot) {
              if (snapshot.hasError) {
                return StreamErrorView(
                  message: 'Couldn\'t load this conversation.',
                  onRetry: () => setState(() => _retryKey++),
                );
              }
              if (!snapshot.hasData) {
                return const SizedBox();
              }
              final docs = snapshot.data!.docs;
              return ListView.builder(
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                itemCount: docs.length,
                itemBuilder: (context, index) {
                  final data = docs[index].data();
                  final isMe = data['senderId'] == widget.userId;
                  final type = data['type'] ?? 'text';
                  final isAdmin = data['senderId'] == 'admin';

                  return Align(
                    alignment:
                        isMe ? Alignment.centerRight : Alignment.centerLeft,
                    child: Container(
                      margin: const EdgeInsets.symmetric(vertical: 4),
                      constraints: BoxConstraints(
                        maxWidth: MediaQuery.of(context).size.width * 0.75,
                      ),
                      child: Column(
                        crossAxisAlignment: isMe
                            ? CrossAxisAlignment.end
                            : CrossAxisAlignment.start,
                        children: [
                          if (isAdmin)
                            Padding(
                              padding: const EdgeInsets.only(
                                  left: 4, right: 4, bottom: 2),
                              child: Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  Icon(Icons.verified_rounded,
                                      size: 12, color: Colors.green.shade600),
                                  const SizedBox(width: 3),
                                  Text(
                                    'Admin',
                                    style: TextStyle(
                                      fontSize: 11,
                                      fontWeight: FontWeight.w600,
                                      color: Colors.green.shade700,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          type == 'file'
                              ? _buildFileBubble(context, data, isMe)
                              : _buildTextBubble(context, data, isMe),
                        ],
                      ),
                    ),
                  );
                },
              );
            },
          ),
        ),
        if (_uploading)
          const Padding(
            padding: EdgeInsets.symmetric(vertical: 6),
            child: SizedBox(
              height: 18,
              width: 18,
              child: CircularProgressIndicator(strokeWidth: 2),
            ),
          ),
        SafeArea(
          top: false,
          child: Padding(
            padding: const EdgeInsets.fromLTRB(12, 6, 12, 12),
            child: Row(
              children: [
                IconButton(
                  icon: const Icon(Icons.attach_file_rounded, color: AppColors.purple),
                  onPressed: _uploading ? null : _pickAndUploadFile,
                ),
                Expanded(
                  child: TextField(
                    controller: _controller,
                    focusNode: _focusNode,
                    style: TextStyle(color: context.textPrimary),
                    decoration: InputDecoration(
                      hintText: 'Message...',
                      hintStyle: TextStyle(color: context.textSecondary),
                      filled: true,
                      fillColor: context.fieldFill,
                      contentPadding: const EdgeInsets.symmetric(
                          horizontal: 16, vertical: 12),
                      // Explicitly set border for every state — leaving
                      // enabledBorder/focusedBorder unset lets Material 3
                      // fall back to ColorScheme.outline (auto-generated
                      // from the purple seed color), which renders much
                      // darker than intended. Setting all three keeps the
                      // border consistently light grey in both themes.
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(24),
                        borderSide: BorderSide(color: context.border, width: 1),
                      ),
                      enabledBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(24),
                        borderSide: BorderSide(color: context.border, width: 1),
                      ),
                      focusedBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(24),
                        borderSide: BorderSide(color: AppColors.purple, width: 1.6),
                      ),
                    ),
                    onSubmitted: (_) => _send(),
                  ),
                ),
                const SizedBox(width: 8),
                CircleAvatar(
                  backgroundColor: AppColors.purple,
                  child: IconButton(
                    icon: const Icon(Icons.arrow_upward_rounded,
                        color: Colors.white, size: 20),
                    onPressed: _send,
                  ),
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildTextBubble(BuildContext context, Map<String, dynamic> data, bool isMe) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
      decoration: BoxDecoration(
        color: isMe ? AppColors.purple : context.fieldFill,
        borderRadius: BorderRadius.circular(16),
      ),
      child: Text(
        data['text'] ?? '',
        style: TextStyle(
          color: isMe ? Colors.white : context.textPrimary,
          fontSize: 14,
        ),
      ),
    );
  }

  Widget _buildFileBubble(BuildContext context, Map<String, dynamic> data, bool isMe) {
    final fileType = data['fileType'] ?? 'file';
    final fileUrl = data['fileUrl'] ?? '';
    final fileName = data['fileName'] ?? 'file';

    if (fileType == 'image') {
      return GestureDetector(
        onTap: () => _openFile(fileUrl),
        child: ClipRRect(
          borderRadius: BorderRadius.circular(14),
          child: Image.network(
            fileUrl,
            fit: BoxFit.cover,
            loadingBuilder: (context, child, progress) {
              if (progress == null) return child;
              return const SizedBox(
                height: 160,
                width: 160,
                child: Center(child: CircularProgressIndicator(strokeWidth: 2)),
              );
            },
            errorBuilder: (context, error, stack) => Container(
              height: 100,
              width: 160,
              color: context.fieldFill,
              child: const Icon(Icons.broken_image_outlined),
            ),
          ),
        ),
      );
    }

    // Non-image file (PDF etc.) — render as a tappable card
    return GestureDetector(
      onTap: () => _openFile(fileUrl),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
        decoration: BoxDecoration(
          color: isMe ? AppColors.purple : context.fieldFill,
          borderRadius: BorderRadius.circular(16),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              Icons.picture_as_pdf_rounded,
              color: isMe ? Colors.white : AppColors.purple,
              size: 22,
            ),
            const SizedBox(width: 8),
            Flexible(
              child: Text(
                fileName,
                overflow: TextOverflow.ellipsis,
                style: TextStyle(
                  color: isMe ? Colors.white : context.textPrimary,
                  fontSize: 13,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}