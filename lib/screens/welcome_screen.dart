import 'package:flutter/material.dart';
import '../services/app_auth_service.dart';
import '../theme/app_theme.dart';
import 'main_shell.dart';
import 'login_screen.dart';
import 'signup_screen.dart';
import '../widgets/google_logo.dart';

class WelcomeScreen extends StatefulWidget {
  const WelcomeScreen({super.key});

  @override
  State<WelcomeScreen> createState() => _WelcomeScreenState();
}

class _WelcomeScreenState extends State<WelcomeScreen> {
  bool _loading = false;
  String? _error;

  Future<void> _signInWithGoogle() async {
    setState(() {
      _loading = true;
      _error = null;
    });
    try {
      await AppAuthService.signInWithGoogle();
      _goHome();
    } on SignInCancelledException {
      // User closed the sheet — no error to show.
    } catch (e) {
      setState(() => _error = AppAuthService.friendlyError(e));
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  void _goHome() {
    if (!mounted) return;
    Navigator.of(context).pushReplacement(
      MaterialPageRoute(builder: (_) => const MainShell()),
    );
  }

  void _showGuestSheet() {
    final controller = TextEditingController();
    showModalBottomSheet(
      context: context,
      backgroundColor: context.card,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (sheetContext) {
        return Padding(
          padding: EdgeInsets.fromLTRB(
            24, 24, 24, MediaQuery.of(sheetContext).viewInsets.bottom + 24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Continue as Guest',
                style: TextStyle(
                    fontSize: 18, fontWeight: FontWeight.w500, color: context.textPrimary),
              ),
              const SizedBox(height: 6),
              Text(
                'Enter your name to continue without an account.',
                style: TextStyle(fontSize: 14, color: context.textSecondary),
              ),
              const SizedBox(height: 18),
              TextField(
                controller: controller,
                autofocus: true,
                style: TextStyle(color: context.textPrimary),
                decoration: InputDecoration(
                  hintText: 'Your full name',
                  hintStyle: TextStyle(color: context.textSecondary),
                  filled: true,
                  fillColor: context.fieldFill,
                  contentPadding: const EdgeInsets.symmetric(
                      vertical: 16, horizontal: 16),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(14),
                    borderSide: BorderSide.none,
                  ),
                ),
              ),
              const SizedBox(height: 16),
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: () async {
                    final name = controller.text.trim();
                    if (name.isEmpty) return;
                    Navigator.pop(sheetContext);
                    setState(() => _loading = true);
                    try {
                      await AppAuthService.signInAsGuest(name);
                      _goHome();
                    } catch (e) {
                      setState(
                          () => _error = AppAuthService.friendlyError(e));
                    } finally {
                      if (mounted) setState(() => _loading = false);
                    }
                  },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.purple,
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(vertical: 16),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(28),
                    ),
                    elevation: 0,
                  ),
                  child: const Text('Continue',
                      style: TextStyle(fontWeight: FontWeight.w600)),
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: context.bg,
      body: SafeArea(
        child: LayoutBuilder(
          builder: (context, constraints) {
            return SingleChildScrollView(
              physics: const ClampingScrollPhysics(),
              padding: const EdgeInsets.symmetric(horizontal: 28),
              child: ConstrainedBox(
                constraints: BoxConstraints(minHeight: constraints.maxHeight),
                child: IntrinsicHeight(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.start,
                    children: [
              const SizedBox(height: 50),
              // Illustration circle
              Container(
                width: 140,
                height: 140,
                decoration: BoxDecoration(
                  color: context.lilac,
                  shape: BoxShape.circle,
                ),
                child: Padding(
                  padding: const EdgeInsets.all(2),
                  child: Image.asset(
                    'assets/images/welcome_clipboard.png',
                    fit: BoxFit.contain,
                  ),
                ),
              ),
              const SizedBox(height: 20),
              Text(
                'Verified. Original. Yours.',
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontSize: 23,
                  fontWeight: FontWeight.w600,
                  color: context.textPrimary,
                ),
              ),
              const SizedBox(height: 8),
              Text(
                'Get a 100% original, verified auction \nsheet for any Japanese import vehicle.',
                textAlign: TextAlign.center,
                style: TextStyle(fontSize: 14, color: context.textSecondary, height: 1.35),
              ),
              const SizedBox(height: 22),

              if (_error != null) ...[
                Text(
                  _error!,
                  style: const TextStyle(color: Colors.red, fontSize: 14),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 10),
              ],

              // Get Started -> Create Account
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: _loading
                      ? null
                      : () => Navigator.push(
                            context,
                            MaterialPageRoute(
                                builder: (_) => const SignupScreen()),
                          ),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.purple,
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(vertical: 15),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(28),
                    ),
                    elevation: 0,
                  ),
                  child: const Text(
                    'Get Started',
                    style: TextStyle(fontSize: 15, fontWeight: FontWeight.w600),
                  ),
                ),
              ),
              const SizedBox(height: 18),

              Row(
                children: [
                  Expanded(child: Divider(color: context.border)),
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 12),
                    child: Text('Or', style: TextStyle(color: context.textSecondary)),
                  ),
                  Expanded(child: Divider(color: context.border)),
                ],
              ),
              const SizedBox(height: 18),

              _SocialButton(
  iconWidget: const GoogleLogo(size: 20),
  label: 'Continue with Google',
  onTap: _loading ? null : _signInWithGoogle,
),
              const SizedBox(height: 10),
              _SocialButton(
                iconWidget: const Icon(Icons.mail_outline_rounded, size: 20),
                iconColor: AppColors.purple,
                label: 'Continue with Email',
                onTap: _loading
                    ? null
                    : () => Navigator.push(
                          context,
                          MaterialPageRoute(builder: (_) => const LoginScreen()),
                        ),
              ),
              const SizedBox(height: 10),
              _SocialButton(
                icon: Icons.person_outline_rounded,
                iconColor: context.textPrimary,
                label: 'Continue as Guest',
                onTap: _loading ? null : _showGuestSheet,
              ),

              const Spacer(),
              Padding(
                padding: const EdgeInsets.only(bottom: 10),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Text("Already have an account? ",
                        style: TextStyle(color: context.textSecondary, fontSize: 14)),
                    GestureDetector(
                      onTap: () => Navigator.push(
                        context,
                        MaterialPageRoute(builder: (_) => const LoginScreen()),
                      ),
                      child: const Text(
                        'Sign In',
                        style: TextStyle(
                          color: AppColors.purple,
                          fontWeight: FontWeight.w600,
                          fontSize: 14,
                        ),
                      ),
                    ),
                  ],
                ),
              ),

              if (_loading) ...[
                const SizedBox(height: 4),
                const CircularProgressIndicator(strokeWidth: 2, color: AppColors.purple),
                const SizedBox(height: 8),
              ],
            ],
                  ),
                ),
              ),
            );
          },
        ),
      ),
    );
  }
}

class _SocialButton extends StatelessWidget {
  final IconData? icon;
  final Widget? iconWidget;
  final Color? iconColor;
  final double iconSize;
  final String label;
  final VoidCallback? onTap;

  const _SocialButton({
    this.icon,
    this.iconWidget,
    this.iconColor,
    required this.label,
    this.onTap,
  }) : iconSize = 22;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: double.infinity,
      child: OutlinedButton(
        onPressed: onTap,
        style: OutlinedButton.styleFrom(
          foregroundColor: context.textPrimary,
          padding: const EdgeInsets.symmetric(vertical: 15),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(28),
          ),
          side: BorderSide(color: context.border),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            iconWidget ??
                Icon(icon, size: iconSize, color: iconColor),
            const SizedBox(width: 10),
            Text(label,
                style: TextStyle(
                    fontSize: 14, fontWeight: FontWeight.w500, color: context.textPrimary)),
          ],
        ),
      ),
    );
  }
}