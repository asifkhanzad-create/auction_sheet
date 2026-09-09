import 'package:flutter/material.dart';
import '../services/app_auth_service.dart';
import '../services/discord_service.dart';
import '../services/firestore_service.dart';
import '../theme/app_theme.dart';
import 'request_detail_screen.dart';

class NewRequestScreen extends StatefulWidget {
  const NewRequestScreen({super.key});

  @override
  State<NewRequestScreen> createState() => _NewRequestScreenState();
}

class _NewRequestScreenState extends State<NewRequestScreen> {
  final _chassisController = TextEditingController();
  bool _submitting = false;

  Future<void> _submit() async {
    final chassis = _chassisController.text.trim();
    if (chassis.isEmpty || _submitting) return;

    setState(() => _submitting = true);

    final userId = AppUser.uid ?? 'unknown';
    final userName = AppUser.name ?? 'Guest';

    try {
      await FirestoreService.createRequest(
        chassisNumber: chassis,
        userId: userId,
        userName: userName,
      );
      await DiscordService.sendNewRequestAlert(
        chassisNumber: chassis,
        userId: userId,
        userName: userName,
      );

      _chassisController.clear();

      if (mounted) {
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (_) => RequestDetailScreen(chassisNumber: chassis),
          ),
        );
      }
    } finally {
      if (mounted) setState(() => _submitting = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SafeArea(
        child: SingleChildScrollView(
          padding: EdgeInsets.only(
            left: 28,
            right: 28,
            top: 20,
            bottom: MediaQuery.of(context).viewInsets.bottom + 20,
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Image.asset(
                'assets/images/hero_car.png',
                height: 150,
                fit: BoxFit.contain,
              ),
              const SizedBox(height: 20),
              Text(
                'Get Your Authentic\nAuction Sheet Report',
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontSize: 24,
                  fontWeight: FontWeight.w700,
                  color: context.textPrimary,
                  height: 1.3,
                ),
              ),
              const SizedBox(height: 10),
              Text(
                'Enter your chassis number below and get a 100% original, verified auction sheet — straight from the source.',
                textAlign: TextAlign.center,
                style: TextStyle(color: context.textSecondary, fontSize: 14, height: 1.4),
              ),
              const SizedBox(height: 16),
              const Wrap(
                alignment: WrapAlignment.center,
                spacing: 8,
                runSpacing: 8,
                children: [
                  _TrustBadge(label: '100% Original'),
                  _TrustBadge(label: 'Verified Source'),
                  _TrustBadge(label: 'Fast Delivery'),
                ],
              ),
              const SizedBox(height: 32),
              TextField(
                controller: _chassisController,
                style: TextStyle(color: context.textPrimary),
                decoration: InputDecoration(
                  hintText: 'e.g. ZN6-501234',
                  hintStyle: TextStyle(color: context.textSecondary, fontSize: 14),
                  filled: true,
                  fillColor: context.card,
                  contentPadding:
                      const EdgeInsets.symmetric(vertical: 16, horizontal: 18),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(16),
                    borderSide: BorderSide(color: context.border),
                  ),
                  enabledBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(16),
                    borderSide: BorderSide(color: context.border),
                  ),
                  focusedBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(16),
                    borderSide: const BorderSide(color: AppColors.purple, width: 1.6),
                  ),
                ),
              ),
              const SizedBox(height: 14),
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: _submitting ? null : _submit,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.purple,
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(vertical: 18),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(999),
                    ),
                    elevation: 0,
                  ),
                  child: _submitting
                      ? const SizedBox(
                          width: 18,
                          height: 18,
                          child: CircularProgressIndicator(
                              strokeWidth: 2, color: Colors.white),
                        )
                      : const Text(
                          'Get Auction Sheet',
                          style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
                        ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _TrustBadge extends StatelessWidget {
  final String label;
  const _TrustBadge({required this.label});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      decoration: BoxDecoration(
        color: Colors.green.withValues(alpha: context.isDark ? 0.15 : 0.08),
        borderRadius: BorderRadius.circular(999),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(Icons.check_circle_rounded, size: 13, color: Colors.green.shade400),
          const SizedBox(width: 4),
          Text(
            label,
            style: TextStyle(
              fontSize: 11,
              fontWeight: FontWeight.w600,
              color: context.isDark ? Colors.green.shade300 : Colors.green.shade700,
            ),
          ),
        ],
      ),
    );
  }
}