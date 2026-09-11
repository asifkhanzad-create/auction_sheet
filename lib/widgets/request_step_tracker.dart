import 'package:flutter/material.dart';
import '../theme/app_theme.dart';

/// Modern "hero card + vertical timeline" status view — replaces the old
/// horizontal 3-circle tracker. Same backend inputs (status, createdAt):
/// no new fields were added, so steps 2 & 3 intentionally show no
/// timestamp (we don't store when sourcing started / finished).
class RequestStepTracker extends StatefulWidget {
  final String status; // "pending" | "in_progress" | "completed"
  final DateTime? createdAt;

  const RequestStepTracker({
    super.key,
    required this.status,
    this.createdAt,
  });

  int get _activeIndex {
    switch (status) {
      case 'completed':
        return 2;
      case 'in_progress':
        return 1;
      default:
        return 0;
    }
  }

  @override
  State<RequestStepTracker> createState() => _RequestStepTrackerState();
}

class _RequestStepTrackerState extends State<RequestStepTracker>
    with SingleTickerProviderStateMixin {
  late final AnimationController _ringController;

  static const _titles = ['Request received', 'Sourcing sheet', 'Sheet ready'];
  static const _descriptions = [
    'Your request has been received',
    "We're locating your auction sheet",
    'Your auction sheet is ready',
  ];

  @override
  void initState() {
    super.initState();
    // Slow, gentle loop — signals "still working" without implying a
    // countdown/ETA, since we don't have real timing data to show.
    _ringController = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 3),
    )..repeat();
  }

  @override
  void dispose() {
    _ringController.dispose();
    super.dispose();
  }

  String _relativeTime(DateTime dt) {
    final diff = DateTime.now().difference(dt);
    if (diff.inMinutes < 1) return 'just now';
    if (diff.inMinutes < 60) return '${diff.inMinutes}m ago';
    if (diff.inHours < 24) return '${diff.inHours}h ago';
    return '${diff.inDays}d ago';
  }

  IconData get _heroIcon {
    switch (widget.status) {
      case 'completed':
        return Icons.check_rounded;
      case 'in_progress':
        return Icons.bolt_rounded;
      default:
        return Icons.hourglass_top_rounded;
    }
  }

  String get _heroSubtext {
    switch (widget.status) {
      case 'completed':
        return 'Your auction sheet is ready!';
      case 'in_progress':
        return "We're actively sourcing your auction sheet.";
      default:
        return 'Your request has been received.';
    }
  }

  @override
  Widget build(BuildContext context) {
    final active = widget._activeIndex;
    final isCompleted = widget.status == 'completed';

    return Column(
      children: [
        _buildHeroCard(active, isCompleted),
        const SizedBox(height: 16),
        _buildTimeline(active),
      ],
    );
  }

  Widget _buildHeroCard(int active, bool isCompleted) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.fromLTRB(20, 18, 20, 20),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [Color(0xFF6C63FF), Color(0xFF564FD8)],
        ),
        borderRadius: BorderRadius.circular(24),
        boxShadow: [
          BoxShadow(
            color: AppColors.purple.withValues(alpha: 0.30),
            blurRadius: 20,
            offset: const Offset(0, 10),
          ),
        ],
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                if (!isCompleted)
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                    decoration: BoxDecoration(
                      color: Colors.white.withValues(alpha: 0.18),
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Container(
                          width: 6,
                          height: 6,
                          decoration: const BoxDecoration(
                            color: Colors.white,
                            shape: BoxShape.circle,
                          ),
                        ),
                        const SizedBox(width: 6),
                        const Text(
                          'LIVE',
                          style: TextStyle(
                            color: Colors.white,
                            fontSize: 10,
                            fontWeight: FontWeight.w700,
                            letterSpacing: 0.5,
                          ),
                        ),
                      ],
                    ),
                  ),
                const SizedBox(height: 10),
                Text(
                  _titles[active],
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 22,
                    fontWeight: FontWeight.w700,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  _heroSubtext,
                  style: TextStyle(
                    color: Colors.white.withValues(alpha: 0.85),
                    fontSize: 12.5,
                    height: 1.3,
                  ),
                ),
                if (!isCompleted) ...[
                  const SizedBox(height: 2),
                  Text(
                    'This can take 10–30 minutes.',
                    style: TextStyle(
                      color: Colors.white.withValues(alpha: 0.6),
                      fontSize: 11,
                    ),
                  ),
                ],
              ],
            ),
          ),
          const SizedBox(width: 12),
          _buildRing(isCompleted),
        ],
      ),
    );
  }

  Widget _buildRing(bool isCompleted) {
    return SizedBox(
      width: 68,
      height: 68,
      child: Stack(
        alignment: Alignment.center,
        children: [
          if (!isCompleted)
            AnimatedBuilder(
              animation: _ringController,
              builder: (context, child) {
                return Transform.rotate(
                  angle: _ringController.value * 2 * 3.14159,
                  child: child,
                );
              },
              child: CustomPaint(
                size: const Size(68, 68),
                painter: _ArcPainter(),
              ),
            ),
          Container(
            width: 48,
            height: 48,
            decoration: const BoxDecoration(
              color: Colors.white,
              shape: BoxShape.circle,
            ),
            child: Icon(_heroIcon, color: AppColors.purple, size: 24),
          ),
        ],
      ),
    );
  }

  Widget _buildTimeline(int active) {
    final overallCompleted = widget.status == 'completed';
    return Column(
      children: List.generate(_titles.length, (i) {
        final isDone = overallCompleted ? true : i < active;
        final isActive = overallCompleted ? false : i == active;
        final isLast = i == _titles.length - 1;

        return IntrinsicHeight(
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Column(
                children: [
                  AnimatedContainer(
                    duration: const Duration(milliseconds: 300),
                    width: isActive ? 30 : 26,
                    height: isActive ? 30 : 26,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      color: isDone
                          ? AppColors.purple
                          : isActive
                              ? context.card
                              : context.lilac,
                      border: isActive
                          ? Border.all(color: AppColors.purple, width: 2.5)
                          : null,
                    ),
                    child: Center(
                      child: isDone
                          ? const Icon(Icons.check_rounded, color: Colors.white, size: 15)
                          : isActive
                              ? Container(
                                  width: 9,
                                  height: 9,
                                  decoration: const BoxDecoration(
                                    color: AppColors.purple,
                                    shape: BoxShape.circle,
                                  ),
                                )
                              : Text(
                                  '${i + 1}',
                                  style: const TextStyle(
                                    fontSize: 11,
                                    fontWeight: FontWeight.w600,
                                    color: Color(0xFFA9A4E0),
                                  ),
                                ),
                    ),
                  ),
                  if (!isLast)
                    Expanded(
                      child: Container(
                        width: 2,
                        margin: const EdgeInsets.symmetric(vertical: 2),
                        color: isDone ? AppColors.purple : context.border,
                      ),
                    ),
                ],
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Padding(
                  padding: EdgeInsets.only(bottom: isLast ? 0 : 22),
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              _titles[i],
                              style: TextStyle(
                                fontSize: 14.5,
                                fontWeight: isActive ? FontWeight.w700 : FontWeight.w600,
                                color: isDone || isActive
                                    ? context.textPrimary
                                    : context.textSecondary,
                              ),
                            ),
                            const SizedBox(height: 2),
                            Text(
                              _descriptions[i],
                              style: TextStyle(
                                fontSize: 12,
                                color: context.textSecondary,
                              ),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(width: 8),
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.end,
                        children: [
                          if (isDone || isActive)
                            Container(
                              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                              decoration: BoxDecoration(
                                color: isDone
                                    ? Colors.green.withValues(alpha: 0.15)
                                    : context.lilac,
                                borderRadius: BorderRadius.circular(20),
                              ),
                              child: Text(
                                isDone ? 'Done' : 'Now',
                                style: TextStyle(
                                  fontSize: 10,
                                  fontWeight: FontWeight.w700,
                                  color: isDone ? Colors.green.shade700 : AppColors.purple,
                                ),
                              ),
                            ),
                          // Only step 1 has a real timestamp (createdAt) —
                          // steps 2/3 aren't stamped in the backend.
                          if (i == 0 && widget.createdAt != null) ...[
                            const SizedBox(height: 4),
                            Text(
                              _relativeTime(widget.createdAt!),
                              style: TextStyle(fontSize: 10.5, color: context.textSecondary),
                            ),
                          ],
                        ],
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
        );
      }),
    );
  }
}

class _ArcPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = Colors.white.withValues(alpha: 0.85)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 2.5
      ..strokeCap = StrokeCap.round;

    final rect = Rect.fromLTWH(1.5, 1.5, size.width - 3, size.height - 3);
    // ~270 degrees of arc, leaving a visible gap — reads as "loading",
    // not a filled progress bar (since we have no real progress %).
    canvas.drawArc(rect, -1.57, 4.2, false, paint);
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}