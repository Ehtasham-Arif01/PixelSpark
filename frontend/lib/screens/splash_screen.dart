import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:provider/provider.dart';

import '../constants/app_constants.dart';
import '../providers/editor_provider.dart';
import '../theme/app_theme.dart';
import 'home_screen.dart';

class SplashScreen extends StatefulWidget {
  const SplashScreen({super.key});

  @override
  State<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen>
    with SingleTickerProviderStateMixin {
  late final AnimationController _progressCtrl;
  late final Animation<double>   _progressAnim;

  @override
  void initState() {
    super.initState();

    _progressCtrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 300),
    );
    _progressAnim = Tween<double>(begin: 0.0, end: 1.0)
        .animate(CurvedAnimation(parent: _progressCtrl, curve: Curves.easeOut));

    // Init ML model in background
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<EditorProvider>().init();
    });

    // Start progress fill at t=2500ms
    Future.delayed(const Duration(milliseconds: 2500), () {
      if (mounted) _progressCtrl.forward();
    });

    // Navigate after splash duration
    Future.delayed(AppConstants.splashDur, () {
      if (!mounted) return;
      Navigator.of(context).pushReplacement(
        PageRouteBuilder(
          pageBuilder: (_, __, ___) => const HomeScreen(),
          transitionsBuilder: (_, anim, __, child) =>
              FadeTransition(opacity: anim, child: child),
          transitionDuration: AppConstants.normalAnim,
        ),
      );
    });
  }

  @override
  void dispose() {
    _progressCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Container(
        decoration: const BoxDecoration(gradient: AppTheme.heroGradient),
        child: SafeArea(
          child: Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const Spacer(flex: 2),

                // ── App icon ──────────────────────────────────────────────
                Container(
                  width: 110,
                  height: 110,
                  decoration: BoxDecoration(
                    color: Colors.white,
                    shape: BoxShape.circle,
                    boxShadow: [
                      BoxShadow(
                        color: AppTheme.cyan.withOpacity(0.5),
                        blurRadius: 30,
                        spreadRadius: 5,
                      ),
                    ],
                  ),
                  child: const Icon(
                    Icons.auto_awesome,
                    color: AppTheme.cyan,
                    size: 56,
                  ),
                )
                    .animate()
                    .scale(
                      begin: const Offset(0.3, 0.3),
                      end: const Offset(1.0, 1.0),
                      duration: 600.ms,
                      curve: Curves.elasticOut,
                    )
                    .fadeIn(duration: 400.ms),

                const SizedBox(height: 28),

                // ── App name ──────────────────────────────────────────────
                Text(
                  AppConstants.appName,
                  style: const TextStyle(
                    fontSize: 38,
                    fontWeight: FontWeight.w800,
                    color: Colors.white,
                    letterSpacing: 1,
                  ),
                )
                    .animate(delay: 700.ms)
                    .slideY(begin: 0.3, end: 0, duration: 500.ms,
                        curve: Curves.easeOut)
                    .fadeIn(duration: 500.ms),

                const SizedBox(height: 8),

                // ── Tagline ───────────────────────────────────────────────
                Text(
                  AppConstants.appTagline.toUpperCase(),
                  style: const TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w400,
                    color: Colors.white60,
                    letterSpacing: 2.5,
                  ),
                )
                    .animate(delay: 1100.ms)
                    .fadeIn(duration: 400.ms),

                const Spacer(flex: 1),

                // ── Animated dots ─────────────────────────────────────────
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: List.generate(3, (i) {
                    return Container(
                      margin: const EdgeInsets.symmetric(horizontal: 4),
                      width: 8,
                      height: 8,
                      decoration: const BoxDecoration(
                        color: Colors.white30,
                        shape: BoxShape.circle,
                      ),
                    )
                        .animate(
                          onPlay: (c) => c.repeat(reverse: true),
                          delay: Duration(milliseconds: 1600 + i * 150),
                        )
                        .scaleXY(
                          begin: 0.6,
                          end: 1.0,
                          duration: 500.ms,
                          curve: Curves.easeInOut,
                        )
                        .fadeIn(duration: 300.ms);
                  }),
                ),

                const SizedBox(height: 12),

                // ── Loading caption ───────────────────────────────────────
                const Text(
                  'Loading AI model...',
                  style: TextStyle(
                    color: Colors.white38,
                    fontSize: 11,
                    letterSpacing: 0.5,
                  ),
                ).animate(delay: 2000.ms).fadeIn(duration: 400.ms),

                const SizedBox(height: 20),

                // ── Progress bar ──────────────────────────────────────────
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 60),
                  child: AnimatedBuilder(
                    animation: _progressAnim,
                    builder: (_, __) => ClipRRect(
                      borderRadius: BorderRadius.circular(4),
                      child: LinearProgressIndicator(
                        value: _progressAnim.value,
                        backgroundColor: Colors.white12,
                        valueColor: const AlwaysStoppedAnimation<Color>(
                            AppTheme.cyan),
                        minHeight: 3,
                      ),
                    ),
                  ),
                ).animate(delay: 2000.ms).fadeIn(duration: 300.ms),

                const Spacer(flex: 1),

                // ── Version ───────────────────────────────────────────────
                Padding(
                  padding: const EdgeInsets.only(bottom: 24),
                  child: Text(
                    'v${AppConstants.appVersion}',
                    style: const TextStyle(
                      color: Colors.white24,
                      fontSize: 11,
                    ),
                  ).animate(delay: 1400.ms).fadeIn(duration: 400.ms),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
