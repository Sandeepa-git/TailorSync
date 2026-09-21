import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:dio/dio.dart';
import '../../../../core/network/providers/api_provider.dart';
import '../../../../core/theme/app_theme.dart';

class SplashScreen extends ConsumerStatefulWidget {
  const SplashScreen({super.key});

  @override
  ConsumerState<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends ConsumerState<SplashScreen>
    with TickerProviderStateMixin {
  // ── Logo entrance ──────────────────────────────────────────────
  late final AnimationController _logoController;
  late final Animation<double> _logoFade;
  late final Animation<double> _logoScale;

  // ── Needle-and-thread stitch ──────────────────────────────────
  late final AnimationController _stitchController;

  // ── Soft glow pulse behind logo ───────────────────────────────
  late final AnimationController _glowController;
  late final Animation<double> _glowOpacity;

  // ── Exit fade ─────────────────────────────────────────────────
  late final AnimationController _exitController;
  late final Animation<double> _exitFade;

  bool _navigating = false;

  @override
  void initState() {
    super.initState();

    // Logo entrance: 0→1 fade, 0.92→1.0 scale, 400ms, easeOut
    _logoController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 500),
    );
    _logoFade = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(parent: _logoController, curve: Curves.easeOut),
    );
    _logoScale = Tween<double>(begin: 0.92, end: 1.0).animate(
      CurvedAnimation(parent: _logoController, curve: Curves.easeOut),
    );

    // Needle-and-thread running-stitch loop: continuous 2s
    _stitchController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 2200),
    );

    // Soft glow pulse behind the logo icon
    _glowController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 2000),
    );
    _glowOpacity = Tween<double>(begin: 0.15, end: 0.35).animate(
      CurvedAnimation(parent: _glowController, curve: Curves.easeInOut),
    );

    // Exit fade-out
    _exitController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 240),
    );
    _exitFade = Tween<double>(begin: 1.0, end: 0.0).animate(
      CurvedAnimation(parent: _exitController, curve: Curves.easeIn),
    );

    // Sequence: logo entrance → stitch starts → glow pulses
    _logoController.forward().then((_) {
      if (mounted) {
        _stitchController.repeat();
        _glowController.repeat(reverse: true);
      }
    });

    // Original auth/nav logic — 100% untouched
    _checkAuthAndNavigate();
  }

  // ══════════════════════════════════════════════════════════════
  //  AUTH / NAVIGATION — ORIGINAL LOGIC, DO NOT MODIFY
  // ══════════════════════════════════════════════════════════════
  Future<void> _checkAuthAndNavigate() async {
    // Give splash animation time to play
    await Future.delayed(const Duration(seconds: 2));
    if (!mounted) return;

    final storage = ref.read(secureStorageProvider);
    final api = ref.read(apiClientProvider);

    String destination = '/login'; // default

    try {
      final token = await storage.read(key: 'auth_token');
      if (token != null && token.isNotEmpty) {
        // Set the token and verify it with the backend
        api.setToken(token);
        try {
          final response = await api.verifyToken();
          if (response.statusCode == 200 && response.data?['valid'] == true) {
            // Fetch user info to determine role and initial route
            try {
              final userResp = await api.getMe();
              final role = userResp.data?['role'];
              if (role == 'staff' || role == 'STAFF') {
                destination = '/tasks';
              } else {
                destination = '/home';
              }
            } catch (_) {
              destination = '/home';
            }
          }
        } on DioException catch (e) {
          debugPrint('Token verification error: $e');
          if (e.response?.statusCode == 401) {
            api.clearToken();
            await storage.delete(key: 'auth_token');
          } else {
            // Network glitch / timeout — assume token is present and proceed to home
            destination = '/home';
          }
        } catch (e) {
          debugPrint('Token verification failed: $e');
        }
      }
    } catch (e) {
      debugPrint('Auth check error: $e');
    }

    if (!mounted || _navigating) return;
    _navigating = true;

    // Fade out then navigate
    await _exitController.forward();
    if (mounted) context.go(destination);
  }

  @override
  void dispose() {
    _logoController.dispose();
    _stitchController.dispose();
    _glowController.dispose();
    _exitController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    // Check reduce-motion preference
    final reduceMotion = MediaQuery.of(context).disableAnimations;

    return Scaffold(
      backgroundColor: AppTheme.scaffoldBg,
      body: Semantics(
        label: 'Loading TailorSync',
        liveRegion: true,
        child: AnimatedBuilder(
          animation: _exitController,
          builder: (context, child) {
            return Opacity(
              opacity: _exitFade.value,
              child: child,
            );
          },
          child: Center(
            child: AnimatedBuilder(
              animation: _logoController,
              builder: (context, child) {
                // If reduce-motion: skip scale, only gentle fade
                final effectiveScale = reduceMotion ? 1.0 : _logoScale.value;
                return Opacity(
                  opacity: _logoFade.value,
                  child: Transform.scale(
                    scale: effectiveScale,
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        // ── Logo with glow ──
                        AnimatedBuilder(
                          animation: _glowController,
                          builder: (context, _) {
                            return Container(
                              width: 120,
                              height: 120,
                              decoration: BoxDecoration(
                                borderRadius: BorderRadius.circular(34),
                                boxShadow: reduceMotion
                                    ? []
                                    : [
                                        BoxShadow(
                                          color: AppTheme.primary
                                              .withValues(alpha: _glowOpacity.value),
                                          blurRadius: 44,
                                          spreadRadius: 6,
                                        ),
                                      ],
                              ),
                              child: Container(
                                decoration: BoxDecoration(
                                  gradient: const LinearGradient(
                                    colors: [
                                      Color(0xFF283593),
                                      Color(0xFF1A237E),
                                      Color(0xFF0D1042),
                                    ],
                                    begin: Alignment.topLeft,
                                    end: Alignment.bottomRight,
                                  ),
                                  borderRadius: BorderRadius.circular(34),
                                ),
                                child: const Center(
                                  child:
                                      Icon(Icons.content_cut, size: 52, color: Colors.white),
                                ),
                              ),
                            );
                          },
                        ),
                        const SizedBox(height: 28),

                        // ── Wordmark ──
                        Text(
                          'TailorSync',
                          style: GoogleFonts.outfit(
                            fontSize: 36,
                            fontWeight: FontWeight.bold,
                            color: AppTheme.primary,
                            letterSpacing: 0.5,
                          ),
                        ),
                        const SizedBox(height: 6),
                        Text(
                          'Smart Tailoring Management',
                          style: GoogleFonts.inter(
                            fontSize: 13,
                            color: AppTheme.textCaption,
                            letterSpacing: 2.0,
                            fontWeight: FontWeight.w400,
                          ),
                        ),
                        const SizedBox(height: 36),

                        // ── Needle-and-thread running stitch ──
                        SizedBox(
                          width: 160,
                          height: 24,
                          child: reduceMotion
                              ? _StaticStitchLine()
                              : AnimatedBuilder(
                                  animation: _stitchController,
                                  builder: (context, _) {
                                    return CustomPaint(
                                      painter: _NeedleStitchPainter(
                                        progress: _stitchController.value,
                                      ),
                                    );
                                  },
                                ),
                        ),
                      ],
                    ),
                  ),
                );
              },
            ),
          ),
        ),
      ),
    );
  }
}

// ══════════════════════════════════════════════════════════════════
//  CUSTOM PAINTER — running-stitch with needle dot
// ══════════════════════════════════════════════════════════════════
class _NeedleStitchPainter extends CustomPainter {
  final double progress; // 0.0 → 1.0 (looping)

  _NeedleStitchPainter({required this.progress});

  @override
  void paint(Canvas canvas, Size size) {
    final double midY = size.height / 2;
    const double stitchLength = 10.0;
    const double gapLength = 6.0;
    const double amplitude = 3.0; // subtle wave
    final double totalWidth = size.width;

    // Thread line (drawn stitches)
    final threadPaint = Paint()
      ..color = AppTheme.primary.withValues(alpha: 0.35)
      ..strokeWidth = 1.8
      ..strokeCap = StrokeCap.round
      ..style = PaintingStyle.stroke;

    // Active/leading section of thread
    final activePaint = Paint()
      ..color = AppTheme.primary.withValues(alpha: 0.7)
      ..strokeWidth = 2.0
      ..strokeCap = StrokeCap.round
      ..style = PaintingStyle.stroke;

    // Needle dot
    final needlePaint = Paint()
      ..color = AppTheme.primary
      ..style = PaintingStyle.fill;

    // The "needle" position travels across the width
    final double needleX = progress * (totalWidth + 40) - 20;

    // Draw the dashed stitch line with a subtle sine wave
    double x = 0;
    while (x < totalWidth) {
      final double endX = (x + stitchLength).clamp(0.0, totalWidth);
      final double y1 = midY + math.sin((x / totalWidth) * math.pi * 4) * amplitude;
      final double y2 = midY + math.sin((endX / totalWidth) * math.pi * 4) * amplitude;

      // Determine if this stitch segment is behind the needle (already sewn)
      final bool isSewn = endX < needleX;
      final bool isActive = (endX - needleX).abs() < 25;

      final paint = isActive ? activePaint : (isSewn ? threadPaint : threadPaint);

      // Fade unstitched segments
      if (!isSewn && !isActive) {
        paint.color = AppTheme.primary.withValues(alpha: 0.12);
      } else if (isSewn && !isActive) {
        paint.color = AppTheme.primary.withValues(alpha: 0.35);
      }

      canvas.drawLine(Offset(x, y1), Offset(endX, y2), paint);
      x += stitchLength + gapLength;
    }

    // Draw the needle tip (small filled circle)
    if (needleX >= -4 && needleX <= totalWidth + 4) {
      final double needleY =
          midY + math.sin((needleX.clamp(0, totalWidth) / totalWidth) * math.pi * 4) * amplitude;
      canvas.drawCircle(Offset(needleX, needleY), 3.2, needlePaint);

      // Tiny trailing thread from needle
      final trailPaint = Paint()
        ..color = AppTheme.primary.withValues(alpha: 0.5)
        ..strokeWidth = 1.5
        ..strokeCap = StrokeCap.round;
      final double trailStartX = (needleX - 8).clamp(0.0, totalWidth);
      final double trailY =
          midY + math.sin((trailStartX / totalWidth) * math.pi * 4) * amplitude;
      canvas.drawLine(Offset(trailStartX, trailY), Offset(needleX, needleY), trailPaint);
    }
  }

  @override
  bool shouldRepaint(covariant _NeedleStitchPainter oldDelegate) =>
      oldDelegate.progress != progress;
}

// ── Static stitch for reduce-motion ─────────────────────────────
class _StaticStitchLine extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return CustomPaint(
      painter: _StaticStitchPainter(),
    );
  }
}

class _StaticStitchPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final double midY = size.height / 2;
    const double stitchLength = 10.0;
    const double gapLength = 6.0;
    final double totalWidth = size.width;

    final paint = Paint()
      ..color = AppTheme.primary.withValues(alpha: 0.25)
      ..strokeWidth = 1.8
      ..strokeCap = StrokeCap.round
      ..style = PaintingStyle.stroke;

    double x = 0;
    while (x < totalWidth) {
      final double endX = (x + stitchLength).clamp(0.0, totalWidth);
      canvas.drawLine(Offset(x, midY), Offset(endX, midY), paint);
      x += stitchLength + gapLength;
    }
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}
