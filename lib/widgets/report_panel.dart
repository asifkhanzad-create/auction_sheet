import 'dart:typed_data';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:pdfx/pdfx.dart';
import 'package:url_launcher/url_launcher.dart';
import '../theme/app_theme.dart';

/// Displays the official deliverables (auction sheet PDF + car photos) for a
/// request — separate from the chat thread. Shown in the white space between
/// the step tracker and the chat panel on the customer's request screen.
class ReportPanel extends StatelessWidget {
  final List<Map<String, dynamic>> deliverables;

  const ReportPanel({super.key, required this.deliverables});

  Future<void> _openFile(BuildContext context, String url) async {
    final uri = Uri.parse(url);
    if (!await launchUrl(uri, mode: LaunchMode.externalApplication)) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Could not open file.')),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    if (deliverables.isEmpty) return const SizedBox.shrink();

    final pdfs = deliverables.where((d) => d['fileType'] == 'pdf').toList();
    final images = deliverables.where((d) => d['fileType'] == 'image').toList();

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.fromLTRB(18, 18, 18, 20),
      decoration: BoxDecoration(
        color: context.card,
        borderRadius: BorderRadius.circular(22),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: context.isDark ? 0.25 : 0.05),
            blurRadius: 16,
            offset: const Offset(0, 6),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Icon(Icons.verified_rounded, size: 16, color: AppColors.purple),
              const SizedBox(width: 6),
              Text(
                'Your documents',
                style: TextStyle(
                  fontSize: 13,
                  fontWeight: FontWeight.w700,
                  color: context.textSecondary,
                  letterSpacing: 0.2,
                ),
              ),
            ],
          ),
          const SizedBox(height: 4),
          Padding(
            padding: const EdgeInsets.only(left: 22),
            child: Text(
              'Tap a file to open it',
              style: TextStyle(
                fontSize: 11.5,
                color: context.textSecondary,
              ),
            ),
          ),
          const SizedBox(height: 12),
          for (final pdf in pdfs) ...[
            _PdfCard(
              fileUrl: pdf['fileUrl'] ?? '',
              fileName: pdf['fileName'] ?? 'Auction Sheet.pdf',
              onTap: () => _openFile(context, pdf['fileUrl'] ?? ''),
            ),
            const SizedBox(height: 14),
          ],
          if (images.isNotEmpty)
            SizedBox(
              height: 92,
              child: ListView.separated(
                scrollDirection: Axis.horizontal,
                itemCount: images.length,
                separatorBuilder: (_, __) => const SizedBox(width: 10),
                itemBuilder: (context, i) {
                  final img = images[i];
                  return GestureDetector(
                    onTap: () => _openFile(context, img['fileUrl'] ?? ''),
                    child: ClipRRect(
                      borderRadius: BorderRadius.circular(12),
                      child: Image.network(
                        img['fileUrl'] ?? '',
                        width: 92,
                        height: 92,
                        fit: BoxFit.cover,
                        loadingBuilder: (context, child, progress) {
                          if (progress == null) return child;
                          return Container(
                            width: 92,
                            height: 92,
                            color: context.fieldFill,
                            child: const Center(
                              child: SizedBox(
                                width: 18,
                                height: 18,
                                child: CircularProgressIndicator(strokeWidth: 2),
                              ),
                            ),
                          );
                        },
                        errorBuilder: (context, error, stack) => Container(
                          width: 92,
                          height: 92,
                          color: context.fieldFill,
                          child: const Icon(Icons.broken_image_outlined,
                              color: Colors.black26),
                        ),
                      ),
                    ),
                  );
                },
              ),
            ),
        ],
      ),
    );
  }
}

class _PdfCard extends StatefulWidget {
  final String fileUrl;
  final String fileName;
  final VoidCallback onTap;

  const _PdfCard({
    required this.fileUrl,
    required this.fileName,
    required this.onTap,
  });

  @override
  State<_PdfCard> createState() => _PdfCardState();
}

class _PdfCardState extends State<_PdfCard> {
  Uint8List? _thumbnailBytes;
  bool _loading = true;
  bool _failed = false;

  @override
  void initState() {
    super.initState();
    _renderThumbnail();
  }

  Future<void> _renderThumbnail() async {
    try {
      final response = await http.get(Uri.parse(widget.fileUrl));
      if (response.statusCode != 200) throw Exception('Download failed');

      final document = await PdfDocument.openData(response.bodyBytes);
      final page = await document.getPage(1);
      final pageImage = await page.render(
        width: page.width * 2,
        height: page.height * 2,
        format: PdfPageImageFormat.png,
      );
      await page.close();
      await document.close();

      if (mounted && pageImage != null) {
        setState(() {
          _thumbnailBytes = pageImage.bytes;
          _loading = false;
        });
      }
    } catch (_) {
      if (mounted) {
        setState(() {
          _failed = true;
          _loading = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: widget.onTap,
      child: Container(
        width: double.infinity,
        decoration: BoxDecoration(
          color: context.bg,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: context.lilac, width: 1.5),
        ),
        padding: const EdgeInsets.all(12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            ClipRRect(
              borderRadius: BorderRadius.circular(10),
              child: SizedBox(
                height: 200,
                width: double.infinity,
                child: _loading
                    ? Container(
                        color: context.fieldFill,
                        child: const Center(
                          child: SizedBox(
                            width: 22,
                            height: 22,
                            child: CircularProgressIndicator(
                                strokeWidth: 2, color: AppColors.purple),
                          ),
                        ),
                      )
                    : _failed || _thumbnailBytes == null
                        ? Container(
                            color: context.fieldFill,
                            child: const Center(
                              child: Icon(Icons.picture_as_pdf_rounded,
                                  size: 40, color: AppColors.purple),
                            ),
                          )
                        : Image.memory(_thumbnailBytes!, fit: BoxFit.cover, alignment: Alignment.topCenter),
              ),
            ),
            const SizedBox(height: 10),
            Row(
              children: [
                const Icon(Icons.picture_as_pdf_rounded,
                    size: 16, color: AppColors.purple),
                const SizedBox(width: 6),
                Expanded(
                  child: Text(
                    widget.fileName,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(
                      fontSize: 13,
                      fontWeight: FontWeight.w600,
                      color: context.textPrimary,
                    ),
                  ),
                ),
                const SizedBox(width: 6),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                  decoration: BoxDecoration(
                    color: context.lilac,
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: const Text(
                    'View',
                    style: TextStyle(
                      fontSize: 11,
                      fontWeight: FontWeight.w700,
                      color: AppColors.purple,
                    ),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}