import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:pomniter_design_system/pomniter_design_system.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// First-launch full-screen privacy consent modal.
///
/// Shown exactly once — on first ever app launch. The user cannot proceed to
/// [HomeScreen] without tapping "I UNDERSTAND, LET'S GO".
///
/// Persisted via [SharedPreferences] key 'hasAcceptedPrivacy'.
class PrivacyConsentScreen extends StatefulWidget {
  const PrivacyConsentScreen({super.key});

  @override
  State<PrivacyConsentScreen> createState() => _PrivacyConsentScreenState();
}

class _PrivacyConsentScreenState extends State<PrivacyConsentScreen>
    with SingleTickerProviderStateMixin {
  late final AnimationController _ctrl;
  late final Animation<double> _fadeAnim;
  late final Animation<Offset> _slideAnim;

  bool _isAccepting = false;

  @override
  void initState() {
    super.initState();
    _ctrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 600),
    );
    _fadeAnim = CurvedAnimation(parent: _ctrl, curve: Curves.easeOut);
    _slideAnim = Tween<Offset>(
      begin: const Offset(0, 0.08),
      end: Offset.zero,
    ).animate(CurvedAnimation(parent: _ctrl, curve: Curves.easeOut));
    _ctrl.forward();
  }

  @override
  void dispose() {
    _ctrl.dispose();
    super.dispose();
  }

  Future<void> _accept() async {
    setState(() => _isAccepting = true);
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool('hasAcceptedPrivacy', true);
    if (mounted) {
      context.go('/home');
    }
  }

  @override
  Widget build(BuildContext context) {
    final neo = NeoTheme.of(context);

    return Scaffold(
      backgroundColor: neo.bgMain,
      body: SafeArea(
        child: FadeTransition(
          opacity: _fadeAnim,
          child: SlideTransition(
            position: _slideAnim,
            child: SingleChildScrollView(
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 24),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // ─── Branding row ─────────────────────────────────────
                  Row(
                    children: [
                      Container(
                        width: 44,
                        height: 44,
                        decoration: BoxDecoration(
                          color: NeoColors.yellow,
                          border: NeoBorders.standard(),
                          borderRadius: NeoBorders.radius,
                        ),
                        child: const Icon(Icons.memory, color: NeoColors.black, size: 22),
                      ),
                      const SizedBox(width: 12),
                      Text(
                        'POMNITER',
                        style: NeoTypography.headlineMedium.copyWith(
                          fontWeight: FontWeight.w900,
                          color: neo.textMain,
                        ),
                      ),
                      const Spacer(),
                      NeoBadge(
                        label: 'PRIVACY FIRST',
                        color: NeoColors.green,
                        textColor: NeoColors.black,
                      ),
                    ],
                  ),
                  const SizedBox(height: 28),

                  // ─── Headline ─────────────────────────────────────────
                  Text(
                    'Before we begin,\nhere\'s our promise.',
                    style: NeoTypography.displayMedium.copyWith(
                      color: neo.textMain,
                      fontWeight: FontWeight.w900,
                      height: 1.1,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'Pomniter is built for privacy. Read what we do — and don\'t — with your data.',
                    style: NeoTypography.bodyLarge.copyWith(
                      color: neo.textMuted,
                    ),
                  ),
                  const SizedBox(height: 28),

                  // ─── Privacy Promise Cards ─────────────────────────────
                  _PrivacyCard(
                    accentColor: NeoColors.green,
                    icon: Icons.phone_android_outlined,
                    title: 'Everything stays on your device',
                    description:
                        'Your screenshots, their extracted text, and all AI-generated vectors are stored exclusively in a local database on your phone. No cloud, no server, no third party.',
                    badge: 'ON-DEVICE',
                    badgeColor: NeoColors.green,
                  ),
                  const SizedBox(height: 14),
                  _PrivacyCard(
                    accentColor: NeoColors.cyan,
                    icon: Icons.visibility_off_outlined,
                    title: 'We never see your images',
                    description:
                        'OCR and embedding models run fully offline using ONNX Runtime. Your photos never leave your device for AI processing — not even to us.',
                    badge: 'OFFLINE AI',
                    badgeColor: NeoColors.cyan,
                  ),
                  const SizedBox(height: 14),
                  _PrivacyCard(
                    accentColor: NeoColors.yellow,
                    icon: Icons.cloud_upload_outlined,
                    title: 'Cloud backup is optional & encrypted',
                    description:
                        'If you enable cloud backup in Settings, only metadata (not images) is uploaded — encrypted end-to-end. You can disable and delete it at any time.',
                    badge: 'OPT-IN',
                    badgeColor: NeoColors.yellow,
                  ),
                  const SizedBox(height: 14),
                  _PrivacyCard(
                    accentColor: NeoColors.pink,
                    icon: Icons.analytics_outlined,
                    title: 'No tracking, no ads, ever',
                    description:
                        'Pomniter is open-source (Apache 2.0). There is no analytics SDK, no ad network, no user profiling. You can audit every line of code on GitHub.',
                    badge: 'OPEN SOURCE',
                    badgeColor: NeoColors.pink,
                  ),
                  const SizedBox(height: 32),

                  // ─── Permissions notice ───────────────────────────────
                  Container(
                    padding: const EdgeInsets.all(14),
                    decoration: BoxDecoration(
                      color: neo.bgCard,
                      border: NeoBorders.standard(),
                      borderRadius: NeoBorders.radius,
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            const Icon(Icons.info_outline, size: 16),
                            const SizedBox(width: 6),
                            Text(
                              'PERMISSIONS WE\'LL REQUEST',
                              style: NeoTypography.labelSmall.copyWith(
                                fontWeight: FontWeight.w900,
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 10),
                        _permissionRow(
                          Icons.photo_library_outlined,
                          'Media / Photos',
                          'To read screenshots from your gallery',
                        ),
                        const SizedBox(height: 6),
                        _permissionRow(
                          Icons.notifications_none_outlined,
                          'Notifications',
                          'To show indexing progress (no marketing)',
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 32),

                  // ─── CTA ─────────────────────────────────────────────
                  SizedBox(
                    width: double.infinity,
                    child: NeoButton(
                      label: _isAccepting ? 'STARTING…' : 'I UNDERSTAND, LET\'S GO →',
                      color: NeoColors.yellow,
                      onPressed: _isAccepting ? null : _accept,
                    ),
                  ),
                  const SizedBox(height: 16),

                  // ─── Footer links ─────────────────────────────────────
                  Center(
                    child: RichText(
                      textAlign: TextAlign.center,
                      text: TextSpan(
                        style: NeoTypography.bodySmall.copyWith(
                          color: neo.textMuted,
                        ),
                        children: [
                          const TextSpan(text: 'By continuing you agree to our '),
                          TextSpan(
                            text: 'Privacy Policy',
                            style: NeoTypography.bodySmall.copyWith(
                              decoration: TextDecoration.underline,
                              color: neo.textMain,
                              fontWeight: FontWeight.w700,
                            ),
                            recognizer: TapGestureRecognizer()..onTap = () {},
                          ),
                          const TextSpan(text: ' and '),
                          TextSpan(
                            text: 'Terms of Service',
                            style: NeoTypography.bodySmall.copyWith(
                              decoration: TextDecoration.underline,
                              color: neo.textMain,
                              fontWeight: FontWeight.w700,
                            ),
                            recognizer: TapGestureRecognizer()..onTap = () {},
                          ),
                          const TextSpan(text: '.'),
                        ],
                      ),
                    ),
                  ),
                  const SizedBox(height: 20),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _permissionRow(IconData icon, String title, String subtitle) {
    final neo = NeoTheme.of(context);
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Icon(icon, size: 18, color: neo.textMuted),
        const SizedBox(width: 10),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(title,
                  style: NeoTypography.bodySmall
                      .copyWith(fontWeight: FontWeight.w700)),
              Text(subtitle,
                  style: NeoTypography.bodySmall
                      .copyWith(color: neo.textMuted)),
            ],
          ),
        ),
      ],
    );
  }
}

// ─── Sub-widgets ──────────────────────────────────────────────────────────────

class _PrivacyCard extends StatelessWidget {
  final Color accentColor;
  final IconData icon;
  final String title;
  final String description;
  final String badge;
  final Color badgeColor;

  const _PrivacyCard({
    required this.accentColor,
    required this.icon,
    required this.title,
    required this.description,
    required this.badge,
    required this.badgeColor,
  });

  @override
  Widget build(BuildContext context) {
    final neo = NeoTheme.of(context);
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: neo.bgCard,
        border: NeoBorders.standard(),
        borderRadius: NeoBorders.radius,
        boxShadow: NeoShadows.md(color: neo.shadowColor),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 40,
            height: 40,
            decoration: BoxDecoration(
              color: accentColor,
              border: NeoBorders.standard(),
              borderRadius: NeoBorders.radius,
            ),
            child: Icon(icon, size: 20, color: NeoColors.black),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Expanded(
                      child: Text(
                        title,
                        style: NeoTypography.labelMedium.copyWith(
                          fontWeight: FontWeight.w800,
                          color: neo.textMain,
                        ),
                      ),
                    ),
                    NeoBadge(
                      label: badge,
                      color: badgeColor,
                      textColor: NeoColors.black,
                    ),
                  ],
                ),
                const SizedBox(height: 6),
                Text(
                  description,
                  style: NeoTypography.bodySmall.copyWith(
                    color: neo.textMuted,
                    height: 1.5,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
