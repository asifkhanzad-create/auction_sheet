import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';
import '../services/app_auth_service.dart';
import '../services/theme_controller.dart';
import '../theme/app_theme.dart';
import 'welcome_screen.dart';

/// Profile screen — Bento Box Grid design (ui-ux-pro-max style).
///
/// Layout:
///   Tile 1  : Hero gradient — avatar, name, account badge.
///   Tile 2  : Single horizontal appearance card with 3 theme options inside.
///   Tile 3  : Sign-out action — full-width bento CTA.
///
/// Uses the same _bentoTile surface, viewport scaling interpolation, and
/// auto-fit scroll lock pattern as new_request_screen.dart. Full-screen
/// page bounds (minH 640 → maxH 900), capped text scaling, and bottom
/// clearance for the floating nav bar in MainShell.
class ProfileScreen extends StatefulWidget {
  const ProfileScreen({super.key});

  @override
  State<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends State<ProfileScreen> {
  static const String _heroSvg = '''<svg width="607" height="753" viewBox="0 0 607 753" fill="none" xmlns="http://www.w3.org/2000/svg">
<g opacity="0.5">
<path d="M245.467 433.462V434.665C245.136 460.098 223.751 479.223 181.311 492.04C232.449 529.231 283.59 558.985 334.728 558.985C385.866 558.985 437.007 529.231 488.145 492.04C445.994 479.209 424.608 460.055 423.989 434.578C423.989 430.037 424.022 423.588 424.053 411.479C424.053 409.556 424.058 407.587 424.067 405.571C427.116 406.001 426.857 405.727 424.067 404.952C424.151 373.1 424.287 330.268 424.477 286.74C464.455 234.921 449.769 174.171 437.241 175.685C421.886 177.557 288.823 51.2864 263.3 44.8122C237.777 38.338 172.943 59.2389 161.785 117.468C150.628 175.696 145.964 322.469 188.285 381.066C200.327 397.741 219.295 404.264 245.188 400.634C245.225 412.821 245.297 419.66 245.467 433.462Z" fill="url(#paint0_linear_4_1276)"/>
<path d="M245.468 400.592C306.834 393.619 345.886 367.119 345.886 367.119C345.886 367.119 303.654 423.234 245.468 434.065V400.592Z" fill="#FFBE94"/>
<path d="M444.91 287.621C464.129 241.401 541.144 147.267 474.756 88.6894C452.441 -20.0973 329.15 -8.05541 246.862 17.0492C191.557 33.9223 149.791 67.2584 140.865 42.1538C85.0769 88.6894 113.016 134.204 149.791 147.267C183.169 159.122 239.61 170.977 335.582 159.819C352.726 157.825 349.136 210.33 358.296 216.006C372.04 224.522 382.706 170.977 420.385 187.055C458.065 203.133 435.705 277.683 395.259 277.683C381.312 277.683 374.338 316.028 411.995 334.16C439.331 347.593 432.422 317.655 444.91 287.621Z" fill="url(#paint1_linear_4_1276)"/>
<path d="M627.615 577.184C654.171 631.178 669.456 755.705 669.456 755.705H0C0 755.705 15.2915 631.164 41.841 577.184C68.3906 523.203 223.431 473.136 223.431 473.136C253.314 534.483 417.317 534.483 445.944 473.117C445.944 473.117 601.06 523.189 627.615 577.184Z" fill="white"/>
</g>
<defs>
<linearGradient id="paint0_linear_4_1276" x1="321.12" y1="43.6797" x2="321.12" y2="558.985" gradientUnits="userSpaceOnUse">
<stop stop-color="#FFD4B3"/>
<stop offset="1" stop-color="#FFDCC2"/>
</linearGradient>
<linearGradient id="paint1_linear_4_1276" x1="305.273" y1="337.463" x2="305.273" y2="0" gradientUnits="userSpaceOnUse">
<stop stop-color="#E6864E"/>
<stop offset="1" stop-color="#E67240"/>
</linearGradient>
</defs>
</svg>''';

  // -------- Auto-fit scaling (pattern from new_request_screen.dart) ----
  final _contentKey = GlobalKey();
  final _scrollController = ScrollController();
  double _fitScale = 1.0;
  static const double _minFitScale = 0.82;
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
      if ((newScale - _fitScale).abs() > 0.005) {
        setState(() {
          _fitScale = newScale;
          _needsScroll = true;
        });
        return;
      }
    }

    final needsScroll = contentHeight > available + _overflowTolerance;
    if (needsScroll != _needsScroll) {
      setState(() => _needsScroll = needsScroll);
    }
  }

  static const double _tileRadius = 24;
  static const double _minH = 640;
  static const double _maxH = 900;

  static double _scale(double viewportHeight, double small, double large) {
    final t = ((viewportHeight - _minH) / (_maxH - _minH)).clamp(0.0, 1.0);
    return small + (large - small) * t;
  }

  ({
    double avatarRadius,
    double gap,
    double tilePadding,
    double nameSize,
    double subtitleSize,
    double sectionTitleSize,
    double bodySize,
    double themeIconSize,
    double themeLabelSize,
    double ctaHeight,
    double heroHeight,
  }) _specFor(double viewportHeight) {
    final s = _fitScale;
    return (
      avatarRadius: _scale(viewportHeight, 26, 36) * s,
      gap: _scale(viewportHeight, 12, 18) * s,
      tilePadding: _scale(viewportHeight, 14, 20) * s,
      nameSize: _scale(viewportHeight, 17, 22) * s,
      subtitleSize: _scale(viewportHeight, 12, 13.5) * s,
      sectionTitleSize: _scale(viewportHeight, 14, 16) * s,
      bodySize: _scale(viewportHeight, 12, 13.5) * s,
      themeIconSize: _scale(viewportHeight, 18, 22) * s,
      themeLabelSize: _scale(viewportHeight, 11, 12.5) * s,
      ctaHeight: _scale(viewportHeight, 48, 56) * s,
      heroHeight: _scale(viewportHeight, 110, 160) * s,
    );
  }
  // ---------------------------------------------------------------------

  Future<void> _signOut() async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Sign out?'),
        content: const Text(
          'You\'ll need to sign in again to submit or track requests.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: Text(
              'Cancel',
              style: TextStyle(color: context.textSecondary),
            ),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            style: TextButton.styleFrom(foregroundColor: AppColors.purple),
            child: const Text('Sign out'),
          ),
        ],
      ),
    );

    if (confirmed != true) return;
    await AppAuthService.signOut();
    if (!mounted) return;
    Navigator.of(context).pushAndRemoveUntil(
      MaterialPageRoute(builder: (_) => const WelcomeScreen()),
      (route) => false,
    );
  }

  @override
  void dispose() {
    _scrollController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final mq = MediaQuery.of(context);
    final wide = mq.size.width >= 600;
    final spec = _specFor(mq.size.height);

    // Matches new_request_screen clearance for the floating nav bar in
    // MainShell (~82px bar + 16px margin + system gesture bar).
    const navBarHeight = 82.0;
    const navBarMargin = 16.0;
    final bottomClearance =
        mq.viewInsets.bottom + mq.viewPadding.bottom + navBarHeight + navBarMargin;

    final cappedTextScaler = mq.textScaler.clamp(maxScaleFactor: 1.15);

    WidgetsBinding.instance
        .addPostFrameCallback((_) => _updateScrollLock());

    return MediaQuery(
      data: mq.copyWith(textScaler: cappedTextScaler),
      child: Scaffold(
        backgroundColor: context.bg,
        appBar: AppBar(
          title: Text(
            'Account',
            style: TextStyle(
              color: context.textPrimary,
              fontWeight: FontWeight.w600,
            ),
          ),
          backgroundColor: context.card,
          foregroundColor: context.textPrimary,
          elevation: 0,
        ),
        body: SafeArea(
          top: false,
          child: SingleChildScrollView(
            controller: _scrollController,
            physics: _needsScroll
                ? const ClampingScrollPhysics()
                : const NeverScrollableScrollPhysics(),
            padding: EdgeInsets.fromLTRB(20, 16, 20, bottomClearance),
            child: Center(
              child: ConstrainedBox(
                constraints: const BoxConstraints(maxWidth: 560),
                child: Column(
                  key: _contentKey,
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: wide
                      ? _buildWideLayout(spec)
                      : _buildNarrowLayout(spec),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }

  // -------- Narrow layout (mobile portrait) ----------------------------
  List<Widget> _buildNarrowLayout(spec) {
    return [
      _heroTile(spec),
      SizedBox(height: spec.gap),
      _appearanceTile(spec),
      SizedBox(height: spec.gap),
      _signOutTile(spec),
    ];
  }

  // -------- Wide layout (tablet / landscape) ---------------------------
  List<Widget> _buildWideLayout(spec) {
    return [
      Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Expanded(flex: 3, child: _heroTile(spec)),
          SizedBox(width: spec.gap),
          Expanded(flex: 2, child: _signOutTile(spec)),
        ],
      ),
      SizedBox(height: spec.gap),
      _appearanceTile(spec),
    ];
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
  Widget _heroTile(spec) {
    final initial =
        (AppUser.name ?? 'G').substring(0, 1).toUpperCase();
    final accountLabel =
        AppUser.isGuest ? 'Guest account' : 'Signed in with Google';
    final accountIcon = AppUser.isGuest
        ? Icons.person_outline_rounded
        : Icons.verified_rounded;

    return Container(
      height: spec.heroHeight,
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
      child: ClipRRect(
        borderRadius: BorderRadius.circular(_tileRadius),
        child: Stack(
          children: [
            Positioned(
              right: -spec.tilePadding * 0.55,
              top: spec.tilePadding * 0.2,
              bottom: spec.tilePadding * 0.2,
              child: Transform.translate(
                offset: const Offset(0, 16),
                child: SvgPicture.string(
                  _heroSvg,
                  fit: BoxFit.contain,
                ),
              ),
            ),
            Padding(
              padding: EdgeInsets.symmetric(
                  horizontal: spec.tilePadding,
                  vertical: spec.tilePadding * 0.85),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.center,
                children: [
                  Container(
                    width: spec.avatarRadius * 2,
                    height: spec.avatarRadius * 2,
                    decoration: BoxDecoration(
                      color: Colors.white,
                      shape: BoxShape.circle,
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withValues(alpha: 0.10),
                          blurRadius: 8,
                          offset: const Offset(0, 2),
                        ),
                      ],
                    ),
                    child: Center(
                      child: Text(
                        initial,
                        style: TextStyle(
                          color: AppColors.purple,
                          fontWeight: FontWeight.w700,
                          fontSize: spec.avatarRadius * 0.78,
                        ),
                      ),
                    ),
                  ),
                  SizedBox(width: spec.tilePadding * 0.7),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Text(
                          AppUser.name ?? 'Guest',
                          style: TextStyle(
                            color: Colors.white,
                            fontSize: spec.nameSize,
                            fontWeight: FontWeight.w700,
                            height: 1.2,
                          ),
                        ),
                        SizedBox(height: spec.tilePadding * 0.2),
                        Container(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 10, vertical: 4),
                          decoration: BoxDecoration(
                            color: Colors.white.withValues(alpha: 0.18),
                            borderRadius: BorderRadius.circular(999),
                          ),
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Icon(accountIcon,
                                  color: Colors.white, size: 12),
                              const SizedBox(width: 5),
                              Text(
                                accountLabel,
                                style: TextStyle(
                                  color: Colors.white.withValues(alpha: 0.92),
                                  fontSize: spec.subtitleSize,
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  // -------- Tile 2: Appearance — single horizontal bento card ----------
  Widget _appearanceTile(spec) {
    return _bentoTile(
      padding: EdgeInsets.all(spec.tilePadding),
      child: ValueListenableBuilder<ThemeMode>(
        valueListenable: ThemeController.mode,
        builder: (context, mode, _) {
          return Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              Row(
                children: [
                  Container(
                    width: spec.heroHeight * 0.32,
                    height: spec.heroHeight * 0.32,
                    decoration: BoxDecoration(
                      color: context.lilac,
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Icon(
                      Icons.dark_mode_rounded,
                      color: AppColors.purple,
                      size: spec.themeIconSize + 2,
                    ),
                  ),
                  SizedBox(width: spec.tilePadding * 0.55),
                  Text(
                    'Appearance',
                    style: TextStyle(
                      fontWeight: FontWeight.w700,
                      fontSize: spec.sectionTitleSize,
                      color: context.textPrimary,
                      height: 1.2,
                    ),
                  ),
                ],
              ),
              SizedBox(height: spec.tilePadding * 0.75),
              Row(
                children: [
                  Expanded(
                    child: _ThemeOption(
                      label: 'System',
                      icon: Icons.brightness_auto_rounded,
                      selected: mode == ThemeMode.system,
                      iconSize: spec.themeIconSize,
                      labelSize: spec.themeLabelSize,
                      onTap: () => ThemeController.setMode(ThemeMode.system),
                    ),
                  ),
                  SizedBox(width: spec.tilePadding * 0.5),
                  Expanded(
                    child: _ThemeOption(
                      label: 'Light',
                      icon: Icons.light_mode_rounded,
                      selected: mode == ThemeMode.light,
                      iconSize: spec.themeIconSize,
                      labelSize: spec.themeLabelSize,
                      onTap: () => ThemeController.setMode(ThemeMode.light),
                    ),
                  ),
                  SizedBox(width: spec.tilePadding * 0.5),
                  Expanded(
                    child: _ThemeOption(
                      label: 'Dark',
                      icon: Icons.dark_mode_rounded,
                      selected: mode == ThemeMode.dark,
                      iconSize: spec.themeIconSize,
                      labelSize: spec.themeLabelSize,
                      onTap: () => ThemeController.setMode(ThemeMode.dark),
                    ),
                  ),
                ],
              ),
            ],
          );
        },
      ),
    );
  }

  // -------- Tile 3: Sign out CTA ---------------------------------------
  Widget _signOutTile(spec) {
    return _bentoTile(
      padding: EdgeInsets.all(spec.tilePadding * 0.8),
      child: SizedBox(
        width: double.infinity,
        height: spec.ctaHeight,
        child: OutlinedButton.icon(
          onPressed: _signOut,
          icon: const Icon(Icons.logout_rounded, size: 18),
          label: Text(
            'Sign out',
            style: TextStyle(
              fontWeight: FontWeight.w700,
              fontSize: spec.bodySize + 0.5,
            ),
          ),
          style: OutlinedButton.styleFrom(
            foregroundColor: AppColors.purple,
            side: const BorderSide(color: AppColors.purple, width: 1.4),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(16),
            ),
            backgroundColor: context.lilac.withValues(alpha: 0.5),
          ),
        ),
      ),
    );
  }
}

class _ThemeOption extends StatelessWidget {
  final String label;
  final IconData icon;
  final bool selected;
  final double iconSize;
  final double labelSize;
  final VoidCallback onTap;

  const _ThemeOption({
    required this.label,
    required this.icon,
    required this.selected,
    required this.iconSize,
    required this.labelSize,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(14),
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 220),
          curve: Curves.easeOut,
          padding: const EdgeInsets.symmetric(vertical: 12),
          decoration: BoxDecoration(
            color: selected ? context.lilac : context.fieldFill,
            borderRadius: BorderRadius.circular(14),
            border: Border.all(
              color: selected ? AppColors.purple : context.border,
              width: selected ? 1.6 : 1,
            ),
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(
                icon,
                size: iconSize,
                color: selected ? AppColors.purple : context.textSecondary,
              ),
              const SizedBox(height: 4),
              Text(
                label,
                style: TextStyle(
                  fontSize: labelSize,
                  fontWeight: selected ? FontWeight.w700 : FontWeight.w500,
                  color: selected ? AppColors.purple : context.textSecondary,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
