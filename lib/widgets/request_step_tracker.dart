import 'package:flutter/material.dart';
import '../theme/app_theme.dart';

/// Compact 2-tile bento step tracker (ui-ux-pro-max style).
///
///   Tile 1  : Hero gradient — full width.
///   Tile 2  : Single horizontal bento card containing all 3 steps
///             stacked vertically inside (timeline-style with check marks).
///
/// No green, no asymmetric flex step tiles — all step accent coloring uses
/// the app's purple + lilac tokens only. Device viewport sizing follows
/// the same interpolation pattern as new_request_screen.dart.
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
  static const _stepIcons = [
    Icons.inbox_rounded,
    Icons.search_rounded,
    Icons.description_rounded,
  ];

  // -------- Compact device scaling (pattern from new_request_screen) ----
  // Tighter base bounds (520 → 800 dp) + smaller small/large endpoints
  // so the 2-tile layout stays well clear of the chat-message preview
  // bar at the bottom of RequestDetailScreen (avoids the 6–7 px overflow
  // that used to occur on small portrait phones).
  static const double _tileRadius = 24;
  static const double _minH = 520;
  static const double _maxH = 800;

  static double _scale(double viewportHeight, double small, double large) {
    final t = ((viewportHeight - _minH) / (_maxH - _minH)).clamp(0.0, 1.0);
    return small + (large - small) * t;
  }

  ({
    double heroHeight,
    double gap,
    double tilePadding,
    double titleSize,
    double stepTitleSize,
    double bodySize,
    double iconSize,
    double stepIconSize,
    double chipHeight,
    double stepItemHeight,
  }) _specFor(double viewportHeight) {
    return (
      heroHeight: _scale(viewportHeight, 86, 140),
      gap: _scale(viewportHeight, 10, 14),
      tilePadding: _scale(viewportHeight, 12, 16),
      titleSize: _scale(viewportHeight, 15, 19),
      stepTitleSize: _scale(viewportHeight, 13, 14.5),
      bodySize: _scale(viewportHeight, 11, 12.5),
      iconSize: _scale(viewportHeight, 20, 26),
      stepIconSize: _scale(viewportHeight, 18, 22),
      chipHeight: _scale(viewportHeight, 20, 26),
      stepItemHeight: _scale(viewportHeight, 52, 64),
    );
  }
  // ---------------------------------------------------------------------

  @override
  void initState() {
    super.initState();
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
    final mq = MediaQuery.of(context);
    final spec = _specFor(mq.size.height);
    final active = widget._activeIndex;
    final isCompleted = widget.status == 'completed';

    final cappedTextScaler = mq.textScaler.clamp(maxScaleFactor: 1.12);

    return MediaQuery(
      data: mq.copyWith(textScaler: cappedTextScaler),
      child: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 560),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              _heroTile(spec, active, isCompleted),
              SizedBox(height: spec.gap),
              _stepsTile(spec, active, isCompleted),
            ],
          ),
        ),
      ),
    );
  }

  // -------- Shared bento surface (matches new_request_screen) ----------
  Widget _bentoTile({
    required Widget child,
    Color? color,
    double? height,
    AlignmentGeometry? alignment,
    EdgeInsetsGeometry? padding,
  }) {
    padding ??= const EdgeInsets.all(20);
    final dark = context.isDark;
    return Container(
      height: height,
      alignment: alignment,
      padding: padding,
      decoration: BoxDecoration(
        color: color ?? context.card,
        borderRadius: BorderRadius.circular(_tileRadius),
        border: dark ? Border.all(color: context.border) : null,
        boxShadow: dark
            ? null
            : [
                BoxShadow(
                  color: Colors.black.withValues(alpha: 0.05),
                  blurRadius: 6,
                  offset: const Offset(0, 4),
                ),
              ],
      ),
      child: child,
    );
  }

  // -------- Tile 1: Hero gradient --------------------------------------
  Widget _heroTile(spec, int active, bool isCompleted) {
    return Container(
      height: spec.heroHeight,
      padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 14),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [Color(0xFF6C63FF), Color(0xFF564FD8)],
        ),
        borderRadius: BorderRadius.circular(_tileRadius),
        boxShadow: [
          BoxShadow(
            color: AppColors.purple.withValues(alpha: 0.28),
            blurRadius: 18,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                if (!isCompleted)
                  Container(
                    height: spec.chipHeight,
                    padding: const EdgeInsets.symmetric(horizontal: 10),
                    decoration: BoxDecoration(
                      color: Colors.white.withValues(alpha: 0.18),
                      borderRadius: BorderRadius.circular(999),
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
                SizedBox(height: 6),
                Text(
                  _titles[active],
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: spec.titleSize,
                    fontWeight: FontWeight.w700,
                    height: 1.2,
                  ),
                ),
                SizedBox(height: 3),
                Text(
                  _heroSubtext,
                  style: TextStyle(
                    color: Colors.white.withValues(alpha: 0.88),
                    fontSize: spec.bodySize,
                    height: 1.3,
                  ),
                ),
                if (!isCompleted) ...[
                  SizedBox(height: 2),
                  Text(
                    '10–30 minutes',
                    style: TextStyle(
                      color: Colors.white.withValues(alpha: 0.62),
                      fontSize: spec.bodySize - 1,
                    ),
                  ),
                ],
              ],
            ),
          ),
          const SizedBox(width: 8),
          _heroRing(isCompleted, spec.iconSize),
        ],
      ),
    );
  }

  Widget _heroRing(bool isCompleted, double iconSize) {
    const box = 60.0;
    return SizedBox(
      width: box,
      height: box,
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
                size: const Size(box, box),
                painter: _ArcPainter(),
              ),
            ),
          Container(
            width: box * 0.72,
            height: box * 0.72,
            decoration: const BoxDecoration(
              color: Colors.white,
              shape: BoxShape.circle,
            ),
            child: Icon(_heroIcon, color: AppColors.purple, size: iconSize),
          ),
        ],
      ),
    );
  }

  // -------- Tile 2: Single horizontal card — 3 steps stacked vertically
  Widget _stepsTile(spec, int active, bool overallCompleted) {
    return _bentoTile(
      padding: EdgeInsets.all(spec.tilePadding),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [
          Padding(
            padding: EdgeInsets.only(left: 2, bottom: spec.tilePadding * 0.6),
            child: Text(
              'Progress',
              style: TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.w700,
                color: context.textSecondary,
                letterSpacing: 0.2,
              ),
            ),
          ),
          Column(
            children: List.generate(_titles.length, (i) {
              final isDone = overallCompleted ? true : i < active;
              final isActive = overallCompleted ? false : i == active;
              final isLast = i == _titles.length - 1;

              return SizedBox(
                height: spec.stepItemHeight,
                child: _StepRow(
                  index: i,
                  isDone: isDone,
                  isActive: isActive,
                  isLast: isLast,
                  iconSize: spec.stepIconSize,
                  titleSize: spec.stepTitleSize,
                  bodySize: spec.bodySize,
                  createdAt: i == 0 ? widget.createdAt : null,
                  relativeTime: i == 0 && widget.createdAt != null
                      ? _relativeTime(widget.createdAt!)
                      : null,
                ),
              );
            }),
          ),
        ],
      ),
    );
  }
}

// Single vertical step row inside the shared steps bento card.
// Purples only — no green anywhere.
class _StepRow extends StatelessWidget {
  final int index;
  final bool isDone;
  final bool isActive;
  final bool isLast;
  final double iconSize;
  final double titleSize;
  final double bodySize;
  final DateTime? createdAt;
  final String? relativeTime;

  const _StepRow({
    required this.index,
    required this.isDone,
    required this.isActive,
    required this.isLast,
    required this.iconSize,
    required this.titleSize,
    required this.bodySize,
    this.createdAt,
    this.relativeTime,
  });

  static const _titles = ['Request received', 'Sourcing sheet', 'Sheet ready'];
  static const _descriptions = [
    'Your request has been received',
    "We're locating your auction sheet",
    'Your auction sheet is ready',
  ];
  static const _stepIcons = [
    Icons.inbox_rounded,
    Icons.search_rounded,
    Icons.description_rounded,
  ];

  @override
  Widget build(BuildContext context) {
    final dotSize = isActive ? 28.0 : 24.0;

    final Color nodeBg;
    final Color nodeFg;
    final Color? nodeBorderColor;
    final double? nodeBorderWidth;
    if (isDone) {
      nodeBg = AppColors.purple;
      nodeFg = Colors.white;
      nodeBorderColor = null;
      nodeBorderWidth = null;
    } else if (isActive) {
      nodeBg = context.card;
      nodeFg = AppColors.purple;
      nodeBorderColor = AppColors.purple;
      nodeBorderWidth = 2.2;
    } else {
      nodeBg = context.lilac;
      nodeFg = AppColors.purple.withValues(alpha: 0.55);
      nodeBorderColor = null;
      nodeBorderWidth = null;
    }

    final Color connectorColor =
        isDone ? AppColors.purple : context.border;

    return IntrinsicHeight(
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Node + connector column
          SizedBox(
            width: 30,
            child: Column(
              children: [
                AnimatedContainer(
                  duration: const Duration(milliseconds: 300),
                  width: dotSize,
                  height: dotSize,
                  margin: EdgeInsets.only(top: isActive ? 0 : 2),
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: nodeBg,
                    border: nodeBorderColor != null
                        ? Border.all(color: nodeBorderColor, width: nodeBorderWidth!)
                        : null,
                  ),
                  child: Center(
                    child: isDone
                        ? Icon(Icons.check_rounded,
                            color: nodeFg, size: iconSize * 0.7)
                        : isActive
                            ? Container(
                                width: 8,
                                height: 8,
                                decoration: const BoxDecoration(
                                  color: AppColors.purple,
                                  shape: BoxShape.circle,
                                ),
                              )
                            : Icon(_stepIcons[index],
                                color: nodeFg, size: iconSize * 0.62),
                  ),
                ),
                if (!isLast)
                  Expanded(
                    child: Container(
                      width: 2,
                      margin: const EdgeInsets.symmetric(vertical: 3),
                      color: connectorColor,
                    ),
                  ),
              ],
            ),
          ),
          const SizedBox(width: 12),
          // Body + right-aligned meta
          Expanded(
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const SizedBox(height: 4),
                      Text(
                        _titles[index],
                        style: TextStyle(
                          fontSize: titleSize,
                          fontWeight:
                              isActive ? FontWeight.w700 : FontWeight.w600,
                          color: isDone || isActive
                              ? context.textPrimary
                              : context.textSecondary,
                          height: 1.2,
                        ),
                      ),
                      SizedBox(height: 2),
                      Text(
                        _descriptions[index],
                        style: TextStyle(
                          fontSize: bodySize,
                          color: context.textSecondary,
                          height: 1.3,
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(width: 8),
                Column(
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: [
                    const SizedBox(height: 2),
                    _StateChip(
                      isDone: isDone,
                      isActive: isActive,
                      index: index,
                    ),
                    if (relativeTime != null) ...[
                      SizedBox(height: 5),
                      Text(
                        relativeTime!,
                        style: TextStyle(
                          fontSize: bodySize - 0.5,
                          color: context.textSecondary,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ],
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

// Step status chip — purples only.
class _StateChip extends StatelessWidget {
  final bool isDone;
  final bool isActive;
  final int index;

  const _StateChip({
    required this.isDone,
    required this.isActive,
    required this.index,
  });

  @override
  Widget build(BuildContext context) {
    final Color bg;
    final Color fg;
    final String label;

    if (isDone) {
      bg = context.lilac;
      fg = AppColors.purple;
      label = 'Done';
    } else if (isActive) {
      bg = context.lilac;
      fg = AppColors.purple;
      label = 'Now';
    } else {
      bg = context.fieldFill;
      fg = context.textSecondary;
      label = 'Step ${index + 1}';
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
      decoration: BoxDecoration(
        color: bg,
        borderRadius: BorderRadius.circular(999),
      ),
      child: Text(
        label,
        style: TextStyle(
          fontSize: 10,
          fontWeight: FontWeight.w700,
          color: fg,
        ),
      ),
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
    canvas.drawArc(rect, -1.57, 4.2, false, paint);
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}
