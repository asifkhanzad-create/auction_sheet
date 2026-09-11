import 'package:flutter/material.dart';
import '../theme/app_theme.dart';
import '../widgets/report_panel.dart';

/// Dedicated full-screen view for a request's deliverables (auction sheet
/// PDF + car photos) — no chat here, just the files. Opened from the
/// compact "Your documents" button on the request detail screen.
class DocumentsScreen extends StatelessWidget {
  final List<Map<String, dynamic>> deliverables;

  const DocumentsScreen({super.key, required this.deliverables});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: context.bg,
      appBar: AppBar(
        title: Text(
          'Your Documents',
          style: TextStyle(color: context.textPrimary, fontWeight: FontWeight.w600),
        ),
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(16),
          child: ReportPanel(deliverables: deliverables),
        ),
      ),
    );
  }
}