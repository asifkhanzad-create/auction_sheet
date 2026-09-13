import 'package:flutter/material.dart';
import '../services/app_auth_service.dart';
import '../services/discord_service.dart';
import '../services/firestore_service.dart';
import '../theme/app_theme.dart';
import 'request_detail_screen.dart';

/// Base sizing spec for the bento grid, interpolated by viewport height.
/// The final on-screen sizes also get multiplied by _fitScale (see
/// _NewRequestScreenState), which auto-corrects for whatever this
/// device actually needs to avoid scrolling.
typedef _BentoSpec = ({
  double heroHeight,
  double gap,
  double gapInner,
  double verticalGap,
  double tilePadding,
  double titleSize,
  double titleSpacing,
  double bodySize,
  double trustIconSize,
  double trustVerticalPadding,
  double fieldVerticalPadding,
  double ctaHeight,
});

/// New-request screen arranged as a Bento Box Grid (UI/UX Pro Max style):
/// modular tiles with varied spans, 24px radii, 16px gaps and soft
/// shadows — colored exclusively with the project's AppColors tokens.
class NewRequestScreen extends StatefulWidget {
  const NewRequestScreen({super.key});

  @override
  State<NewRequestScreen> createState() => _NewRequestScreenState();
}

class _NewRequestScreenState extends State<NewRequestScreen> {
  final _chassisController = TextEditingController();
  final _scrollController = ScrollController();
  final _contentKey = GlobalKey();
  bool _submitting = false;

  // Auto-fit scaling: after each layout, measures the content's actual
  // rendered height (via _contentKey) against the available viewport
  // height, and adjusts _fitScale up or down until the two converge —
  // so the bento grid fits without scrolling on whatever device it's
  // running on, without needing per-device tuning.
  double _fitScale = 1.0;
  static const double _minFitScale = 0.8;
  static const double _overflowTolerance = 1.0;

  bool _needsScroll = true;

  void _updateScrollLock() {
    if (!_scrollController.hasClients) return;
    final renderBox =
        _contentKey.currentContext?.findRenderObject() as RenderBox?;
    if (renderBox == null || !renderBox.hasSize) return;

    final available = _scrollController.position.viewportDimension;
    final contentHeight = renderBox.size.height;
    if (available <= 0 || contentHeight <= 0) return;

    final diff = contentHeight - available;
    if (diff.abs() > _overflowTolerance) {
      final ratio = available / contentHeight;
      final newScale = (_fitScale * ratio).clamp(_minFitScale, 1.0);
      // Only rebuild on a meaningful change — avoids a micro-adjustment
      // loop from floating-point noise.
      if ((newScale - _fitScale).abs() > 0.005) {
        setState(() {
          _fitScale = newScale;
          _needsScroll = true; // re-verify once the new scale lays out
        });
        return;
      }
    }

    final needsScroll = contentHeight > available + _overflowTolerance;
    if (needsScroll != _needsScroll) {
      setState(() => _needsScroll = needsScroll);
    }
  }

  // Bento Box Grid tokens.
  static const double _tileRadius = 24;

  // Anchor heights the base spec interpolates between before _fitScale
  // is applied — a starting point for the auto-fit correction above,
  // not the final on-screen size.
  static const double _minH = 640;
  static const double _maxH = 900;

  /// Linear interpolation between the small- and large-screen value for
  /// a given viewport height, clamped to [0, 1] so it never overshoots
  /// on screens shorter than _minH or taller than _maxH.
  static double _scale(double viewportHeight, double small, double large) {
    final t = ((viewportHeight - _minH) / (_maxH - _minH)).clamp(0.0, 1.0);
    return small + (large - small) * t;
  }

  /// Builds the base (unscaled) spec, then applies the measured
  /// _fitScale correction on top. Only size-y fields are scaled — text
  /// stays legible down to _minFitScale (0.8x of an already-compact
  /// 18px title = ~14.4px floor).
  _BentoSpec _specFor(double viewportHeight) {
    final s = _fitScale;
    return (
      heroHeight: _scale(viewportHeight, 100, 180) * s,
      gap: _scale(viewportHeight, 10, 16) * s,
      gapInner: _scale(viewportHeight, 6, 12) * s,
      verticalGap: 18 * s,
      tilePadding: _scale(viewportHeight, 12, 20) * s,
      titleSize: _scale(viewportHeight, 18, 24) * s,
      titleSpacing: _scale(viewportHeight, 5, 10) * s,
      bodySize: _scale(viewportHeight, 12, 14) * s,
      trustIconSize: _scale(viewportHeight, 16, 20) * s,
      trustVerticalPadding: _scale(viewportHeight, 8, 14) * s,
      fieldVerticalPadding: _scale(viewportHeight, 10, 16) * s,
      ctaHeight: _scale(viewportHeight, 46, 56) * s,
    );
  }

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
  void dispose() {
    _chassisController.dispose();
    _scrollController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final mq = MediaQuery.of(context);
    final wide = mq.size.width >= 600;
    final spec = _specFor(mq.size.height);

    // The floating nav bar itself is ~82px tall with ~16px of breathing
    // room around it (see MainShell). System bottom inset (gesture bar /
    // 3-button nav) varies per device, so add mq.viewPadding.bottom
    // instead of baking a single guessed constant in.
    const navBarHeight = 82.0;
    const navBarMargin = 16.0;
    final bottomClearance =
        mq.viewInsets.bottom + mq.viewPadding.bottom + navBarHeight + navBarMargin;

    // Cap text scaling for this screen only. Large accessibility font
    // sizes are still respected (nobody gets shrunk below default), but
    // capped enough that the tile budget doesn't blow out and force
    // scrolling anyway.
    final cappedTextScaler = mq.textScaler.clamp(maxScaleFactor: 1.15);

    // Re-check after every layout pass (orientation change, text scale
    // change, hot reload, etc.) — cheap, and only triggers a rebuild when
    // the fits/doesn't-fit verdict actually flips.
    WidgetsBinding.instance.addPostFrameCallback((_) => _updateScrollLock());

    return MediaQuery(
      data: mq.copyWith(textScaler: cappedTextScaler),
      child: Scaffold(
        body: SafeArea(
          child: SingleChildScrollView(
            controller: _scrollController,
            physics: _needsScroll
                ? const ClampingScrollPhysics()
                : const NeverScrollableScrollPhysics(),
            padding: EdgeInsets.only(
              left: 28,
              right: 28,
              top: 20,
              bottom: bottomClearance,
            ),
            child: Center(
              child: ConstrainedBox(
                constraints: const BoxConstraints(maxWidth: 560),
                child: Column(
                  key: _contentKey,
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    _heroTile(spec),
                    SizedBox(height: spec.verticalGap),
                    if (wide)
                      Row(
                        crossAxisAlignment: CrossAxisAlignment.center,
                        children: [
                          Expanded(flex: 3, child: _titleTile(spec)),
                          SizedBox(width: spec.gap),
                          Expanded(
                            flex: 2,
                            child: Column(
                              children: [
                                _trustTile('100% Original', spec),
                                SizedBox(height: spec.verticalGap),
                                _trustTile('Verified Source', spec),
                                SizedBox(height: spec.verticalGap),
                                _trustTile('Fast Delivery', spec),
                              ],
                            ),
                          ),
                        ],
                      )
                    else ...[
                      _titleTile(spec),
                      SizedBox(height: spec.verticalGap),
                      Row(
                        children: [
                          Expanded(child: _trustTile('100% Original', spec)),
                          SizedBox(width: spec.gapInner),
                          Expanded(child: _trustTile('Verified Source', spec)),
                          SizedBox(width: spec.gapInner),
                          Expanded(child: _trustTile('Fast Delivery', spec)),
                        ],
                      ),
                    ],
                    SizedBox(height: spec.verticalGap),
                    _inputAndCtaTile(spec),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }

  /// Shared bento tile surface: 24px radius, soft shadow in light mode,
  /// subtle hairline border in dark mode (shadows are invisible on dark
  /// surfaces, so the border keeps tiles separated).
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

  /// Full-span hero tile — same card surface as the other tiles so the
  /// grid reads as one cohesive set in both light and dark themes.
  Widget _heroTile(_BentoSpec spec) {
    return _bentoTile(
      height: spec.heroHeight,
      alignment: Alignment.center,
      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
      child: Image.asset(
        'assets/images/hero_car.png',
        fit: BoxFit.contain,
        // Decorative illustration — the headline carries the meaning.
        excludeFromSemantics: true,
      ),
    );
  }

  Widget _titleTile(_BentoSpec spec) {
    return _bentoTile(
      padding: EdgeInsets.all(spec.tilePadding),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(
            'Get Your Authentic Auction Sheet Report',
            style: TextStyle(
              fontSize: spec.titleSize,
              fontWeight: FontWeight.w700,
              color: context.textPrimary,
              height: 1.3,
            ),
          ),
          SizedBox(height: spec.titleSpacing),
          Text(
            'Enter your chassis number below and get a 100% original, '
            'verified auction sheet — straight from the source.',
            style: TextStyle(
              color: context.textSecondary,
              fontSize: spec.bodySize,
              height: 1.4,
            ),
          ),
        ],
      ),
    );
  }

  /// Trust badges promoted from pills to 1x1 bento mini-cards.
  Widget _trustTile(String label, _BentoSpec spec) {
    return _bentoTile(
      padding: EdgeInsets.symmetric(
          horizontal: 8, vertical: spec.trustVerticalPadding),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            Icons.check_circle_rounded,
            size: spec.trustIconSize,
            color:
                context.isDark ? Colors.green.shade400 : Colors.green.shade600,
          ),
          const SizedBox(height: 6),
          FittedBox(
            fit: BoxFit.scaleDown,
            child: Text(
              label,
              maxLines: 1,
              style: TextStyle(
                fontSize: 11.5,
                fontWeight: FontWeight.w600,
                color: context.isDark
                    ? Colors.green.shade300
                    : Colors.green.shade700,
              ),
            ),
          ),
        ],
      ),
    );
  }

  /// Input + CTA combined tile — single bento card with label, field, and button.
  Widget _inputAndCtaTile(_BentoSpec spec) {
    return _bentoTile(
      padding: EdgeInsets.all(spec.tilePadding),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(
            'Chassis Number',
            style: TextStyle(
              fontSize: 13,
              fontWeight: FontWeight.w600,
              letterSpacing: 0.2,
              color: context.textPrimary,
            ),
          ),
          const SizedBox(height: 8),
          TextField(
            controller: _chassisController,
            textInputAction: TextInputAction.done,
            onSubmitted: (_) => _submit(),
            style: TextStyle(color: context.textPrimary),
            decoration: InputDecoration(
              hintText: 'e.g. ZN6-501234',
              hintStyle: TextStyle(color: context.textSecondary, fontSize: 14),
              filled: true,
              fillColor: context.fieldFill,
              contentPadding: EdgeInsets.symmetric(
                  vertical: spec.fieldVerticalPadding, horizontal: 18),
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
                borderSide:
                    const BorderSide(color: AppColors.purple, width: 1.6),
              ),
            ),
          ),
          const SizedBox(height: 16),
          SizedBox(
            width: double.infinity,
            height: spec.ctaHeight,
            child: ElevatedButton(
              onPressed: _submitting ? null : _submit,
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.purple,
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(horizontal: 24),
                shape:
                    RoundedRectangleBorder(borderRadius: BorderRadius.circular(999)),
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
    );
  }
}