import 'dart:ui';
import 'package:flutter/material.dart';
import '../theme/app_colors.dart';

class LandingScreen extends StatefulWidget {
  final VoidCallback onEnter;
  const LandingScreen({super.key, required this.onEnter});

  @override
  State<LandingScreen> createState() => _LandingScreenState();
}

class _LandingScreenState extends State<LandingScreen>
    with TickerProviderStateMixin {
  late final AnimationController _fadeCtrl;
  late final AnimationController _floatCtrl;
  late final Animation<double> _fadeAnim;
  late final Animation<double> _floatAnim;

  @override
  void initState() {
    super.initState();

    _fadeCtrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1200),
    )..forward();

    _floatCtrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 2800),
    )..repeat(reverse: true);

    _fadeAnim = CurvedAnimation(parent: _fadeCtrl, curve: Curves.easeOut);
    _floatAnim = Tween<double>(begin: -8, end: 8).animate(
      CurvedAnimation(parent: _floatCtrl, curve: Curves.easeInOut),
    );
  }

  @override
  void dispose() {
    _fadeCtrl.dispose();
    _floatCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final size = MediaQuery.of(context).size;

    return Scaffold(
      backgroundColor: AppColors.scaffold,
      body: Stack(
        children: [
          // ── Background glow orbs ──────────────────────────────────────────
          Positioned(
            top: -80,
            left: -60,
            child: _GlowOrb(size: 280, color: AppColors.primary.withValues(alpha: 0.18)),
          ),
          Positioned(
            bottom: 60,
            right: -80,
            child: _GlowOrb(size: 240, color: const Color(0xFFFFD1DC).withValues(alpha: 0.12)),
          ),
          Positioned(
            top: size.height * 0.4,
            left: size.width * 0.5,
            child: _GlowOrb(size: 160, color: AppColors.accent.withValues(alpha: 0.08)),
          ),

          // ── Main content ──────────────────────────────────────────────────
          SafeArea(
            child: FadeTransition(
              opacity: _fadeAnim,
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 28),
                child: Column(
                  children: [
                    const Spacer(flex: 2),

                    // Floating logo
                    AnimatedBuilder(
                      animation: _floatAnim,
                      builder: (_, child) => Transform.translate(
                        offset: Offset(0, _floatAnim.value),
                        child: child,
                      ),
                      child: _LogoBadge(),
                    ),

                    const SizedBox(height: 36),

                    // Title
                    ShaderMask(
                      shaderCallback: (bounds) =>
                          AppColors.primaryGradient.createShader(bounds),
                      child: const Text(
                        'AI Demo App',
                        style: TextStyle(
                          fontSize: 38,
                          fontWeight: FontWeight.w800,
                          color: Colors.white,
                          letterSpacing: 0.5,
                        ),
                      ),
                    ),

                    const SizedBox(height: 10),

                    Text(
                      'Vision · Image Gen · Social Bridge',
                      style: TextStyle(
                        fontSize: 14,
                        color: Colors.white.withValues(alpha: 0.45),
                        letterSpacing: 2,
                        fontWeight: FontWeight.w400,
                      ),
                    ),

                    const SizedBox(height: 48),

                    // Feature cards
                    const _FeatureRow(features: [
                      _Feature(
                        icon: Icons.filter_center_focus_rounded,
                        label: 'Vision',
                        desc: 'Analyze images\nfor accessibility',
                        color: AppColors.primary2,
                      ),
                      _Feature(
                        icon: Icons.auto_awesome_mosaic_rounded,
                        label: 'Image Gen',
                        desc: 'Generate images\nfrom text',
                        color: Color(0xFFE94560),
                      ),
                      _Feature(
                        icon: Icons.favorite_rounded,
                        label: 'Lounge',
                        desc: 'Inclusive AI\nsocial space',
                        color: Color(0xFFFFD1DC),
                      ),
                    ]),

                    const Spacer(flex: 3),

                    // CTA button
                    _EnterButton(onTap: widget.onEnter),

                    const SizedBox(height: 12),

                    Text(
                      'Powered by Groq · Llama · Pollinations',
                      style: TextStyle(
                        fontSize: 11,
                        color: Colors.white.withValues(alpha: 0.25),
                        letterSpacing: 0.5,
                      ),
                    ),

                    const SizedBox(height: 32),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

// ── Logo Badge ────────────────────────────────────────────────────────────────

class _LogoBadge extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Container(
      width: 110,
      height: 110,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        gradient: AppColors.primaryGradient,
        boxShadow: [
          BoxShadow(
            color: AppColors.primary.withValues(alpha: 0.5),
            blurRadius: 40,
            spreadRadius: 4,
          ),
        ],
      ),
      child: ClipOval(
        child: BackdropFilter(
          filter: ImageFilter.blur(sigmaX: 0, sigmaY: 0),
          child: const Icon(
            Icons.auto_awesome_rounded,
            size: 52,
            color: Colors.white,
          ),
        ),
      ),
    );
  }
}

// ── Feature Card ──────────────────────────────────────────────────────────────

class _Feature {
  final IconData icon;
  final String label;
  final String desc;
  final Color color;
  const _Feature({
    required this.icon,
    required this.label,
    required this.desc,
    required this.color,
  });
}

class _FeatureRow extends StatelessWidget {
  final List<_Feature> features;
  const _FeatureRow({required this.features});

  @override
  Widget build(BuildContext context) {
    return Row(
      children: features
          .map((f) => Expanded(child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 5),
                child: _FeatureCard(feature: f),
              )))
          .toList(),
    );
  }
}

class _FeatureCard extends StatelessWidget {
  final _Feature feature;
  const _FeatureCard({required this.feature});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 18, horizontal: 10),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: feature.color.withValues(alpha: 0.2)),
        boxShadow: [
          BoxShadow(
            color: feature.color.withValues(alpha: 0.08),
            blurRadius: 16,
            spreadRadius: 1,
          ),
        ],
      ),
      child: Column(
        children: [
          Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: feature.color.withValues(alpha: 0.12),
            ),
            child: Icon(feature.icon, color: feature.color, size: 22),
          ),
          const SizedBox(height: 10),
          Text(
            feature.label,
            style: const TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.w700,
              color: Colors.white,
              letterSpacing: 0.5,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            feature.desc,
            textAlign: TextAlign.center,
            style: TextStyle(
              fontSize: 10,
              color: Colors.white.withValues(alpha: 0.4),
              height: 1.5,
              letterSpacing: 0.3,
            ),
          ),
        ],
      ),
    );
  }
}

// ── Enter Button ──────────────────────────────────────────────────────────────

class _EnterButton extends StatefulWidget {
  final VoidCallback onTap;
  const _EnterButton({required this.onTap});

  @override
  State<_EnterButton> createState() => _EnterButtonState();
}

class _EnterButtonState extends State<_EnterButton>
    with SingleTickerProviderStateMixin {
  late final AnimationController _shimmerCtrl;

  @override
  void initState() {
    super.initState();
    _shimmerCtrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1800),
    )..repeat();
  }

  @override
  void dispose() {
    _shimmerCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: widget.onTap,
      child: AnimatedBuilder(
        animation: _shimmerCtrl,
        builder: (_, child) {
          return Container(
            width: double.infinity,
            height: 58,
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(18),
              gradient: AppColors.buttonGradient,
              boxShadow: [
                BoxShadow(
                  color: AppColors.primary.withValues(alpha: 0.45),
                  blurRadius: 24,
                  spreadRadius: 1,
                ),
              ],
            ),
            child: Stack(
              children: [
                // Shimmer sweep
                Positioned.fill(
                  child: ClipRRect(
                    borderRadius: BorderRadius.circular(18),
                    child: FractionallySizedBox(
                      alignment: Alignment(
                        -1.5 + _shimmerCtrl.value * 3.5,
                        0,
                      ),
                      widthFactor: 0.35,
                      child: Container(
                        decoration: BoxDecoration(
                          gradient: LinearGradient(
                            colors: [
                              Colors.white.withValues(alpha: 0),
                              Colors.white.withValues(alpha: 0.12),
                              Colors.white.withValues(alpha: 0),
                            ],
                          ),
                        ),
                      ),
                    ),
                  ),
                ),
                // Label
                const Center(
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(
                        'Get Started',
                        style: TextStyle(
                          fontSize: 17,
                          fontWeight: FontWeight.w700,
                          color: Colors.white,
                          letterSpacing: 0.8,
                        ),
                      ),
                      SizedBox(width: 10),
                      Icon(Icons.arrow_forward_rounded,
                          color: Colors.white, size: 20),
                    ],
                  ),
                ),
              ],
            ),
          );
        },
      ),
    );
  }
}

// ── Glow Orb ──────────────────────────────────────────────────────────────────

class _GlowOrb extends StatelessWidget {
  final double size;
  final Color color;
  const _GlowOrb({required this.size, required this.color});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        color: color,
      ),
    );
  }
}
