import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:dio/dio.dart';
import '../../../../core/network/providers/user_provider.dart';
import '../../../../core/network/providers/api_provider.dart';
import '../../../../core/network/server_warmup.dart';
import '../../../../ui/ui.dart';

class SplashScreen extends ConsumerStatefulWidget {
  const SplashScreen({super.key});

  @override
  ConsumerState<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends ConsumerState<SplashScreen>
    with SingleTickerProviderStateMixin {
  // ── Entrance animation ──────────────────────────────────────────
  late final AnimationController _animationController;
  late final Animation<double> _fadeAnimation;
  late final Animation<double> _scaleAnimation;
  
  bool _navigating = false;
  Future<void> _checkAuthAndNavigate() async {
    // Removed artificial delay to speed up cold start
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
              ref.invalidate(userProvider);
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
            // The server is confirmed awake (see _bootstrap), so a 401 here
            // means the saved session is no longer valid. Ask the user to
            // sign in again instead of opening an empty, failing dashboard.
            // (The stored token is not deleted; a new login overwrites it.)
            destination = '/login';
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

    // Fade out and navigate
    await _animationController.reverse();
    if (mounted) context.go(destination);
  }
  @override
  void dispose() {
    _animationController.dispose();
    super.dispose();
  }

  // ── Connection bootstrap (UI + server wake-up) ──────────────────
  _BootPhase _phase = _BootPhase.connecting;
  Duration _elapsed = Duration.zero;
  Timer? _tick;

  @override
  void initState() {
    super.initState();

    _animationController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 800),
    );
    
    _fadeAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(parent: _animationController, curve: Curves.easeOut),
    );
    
    _scaleAnimation = Tween<double>(begin: 0.95, end: 1.0).animate(
      CurvedAnimation(parent: _animationController, curve: Curves.easeOutQuart),
    );

    _animationController.forward();
    _bootstrap();
  }

  /// Wake the cloud backend first (it cold-starts in ~2 min after idling),
  /// then run the original auth check unchanged.
  Future<void> _bootstrap() async {
    if (mounted) {
      setState(() {
        _phase = _BootPhase.connecting;
        _elapsed = Duration.zero;
      });
    }
    final watch = Stopwatch()..start();
    _tick?.cancel();
    _tick = Timer.periodic(const Duration(seconds: 1), (timer) {
      if (!mounted) {
        timer.cancel();
        return;
      }
      setState(() {
        _elapsed = watch.elapsed;
        if (_phase == _BootPhase.connecting && watch.elapsed > const Duration(seconds: 6)) {
          _phase = _BootPhase.waking;
        }
      });
    });
    final ready = await ServerWarmup.waitUntilReady();
    _tick?.cancel();
    if (!mounted) return;
    if (!ready) {
      setState(() => _phase = _BootPhase.offline);
      return;
    }
    setState(() => _phase = _BootPhase.ready);
    await _checkAuthAndNavigate();
  }

  void _continueAnyway() {
    setState(() => _phase = _BootPhase.ready);
    _checkAuthAndNavigate();
  }

  @override
  Widget build(BuildContext context) {
    final logoSize = (context.screenSize.shortestSide * 0.30).clamp(96.0, 148.0);
    return AnnotatedRegion<SystemUiOverlayStyle>(
      // Light status-bar icons over the dark brand splash.
      value: TsTheme.overlayStyle(Brightness.dark),
      child: Scaffold(
      backgroundColor: _SplashPalette.bgEdge,
      body: _SplashBackground(
        child: Semantics(
          label: 'Loading TailorSync',
          liveRegion: true,
          child: AnimatedBuilder(
            animation: _animationController,
            builder: (context, child) {
              return Opacity(
                opacity: _fadeAnimation.value,
                child: Transform.scale(scale: _scaleAnimation.value, child: child),
              );
            },
            child: SafeArea(
              child: Center(
                child: SingleChildScrollView(
                  padding: EdgeInsets.symmetric(horizontal: context.pagePadding),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      _LogoReveal(size: logoSize),
                      SizedBox(height: context.isShort ? Space.lg : Space.xl),
                      EntranceFade(
                        delay: const Duration(milliseconds: 350),
                        child: Text(
                          'TailorSync',
                          textAlign: TextAlign.center,
                          style: context.text.displaySmall?.copyWith(
                            color: Colors.white,
                            fontWeight: FontWeight.w600,
                            letterSpacing: -0.5,
                          ),
                        ),
                      ),
                      const SizedBox(height: Space.sm),
                      EntranceFade(
                        delay: const Duration(milliseconds: 420),
                        child: Container(
                          width: 36,
                          height: 2,
                          decoration: BoxDecoration(
                            borderRadius: Radii.brPill,
                            gradient: const LinearGradient(colors: [
                              _SplashPalette.goldSoft,
                              _SplashPalette.gold,
                            ]),
                          ),
                        ),
                      ),
                      const SizedBox(height: Space.sm),
                      EntranceFade(
                        delay: const Duration(milliseconds: 480),
                        child: Text(
                          'PROFESSIONAL TAILORING MANAGEMENT',
                          textAlign: TextAlign.center,
                          style: context.text.labelMedium?.copyWith(
                            color: Colors.white.withValues(alpha: 0.62),
                            letterSpacing: 2.2,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                      ),
                      SizedBox(height: context.isShort ? Space.xl : Space.xxl),
                      EntranceFade(
                        delay: const Duration(milliseconds: 650),
                        child: _BootStatus(
                          phase: _phase,
                          elapsed: _elapsed,
                          onRetry: _bootstrap,
                          onContinue: _continueAnyway,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
        ),
      ),
    ),
    );
  }
}

/// The existing logo, unchanged, revealed with fade + scale (0.8 → 1.0),
/// a soft pulsing glow and a single light sweep across it.
class _LogoReveal extends StatefulWidget {
  final double size;
  const _LogoReveal({required this.size});

  @override
  State<_LogoReveal> createState() => _LogoRevealState();
}

class _LogoRevealState extends State<_LogoReveal> with SingleTickerProviderStateMixin {
  late final AnimationController _c = AnimationController(vsync: this, duration: const Duration(milliseconds: 1600));

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (Motion.reduced(context)) {
      _c.value = 1;
    } else if (_c.value == 0) {
      _c.forward();
    }
  }

  @override
  void dispose() {
    _c.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final s = widget.size;
    final radius = BorderRadius.circular(s * 0.24);
    return RepaintBoundary(
      child: AnimatedBuilder(
        animation: _c,
        builder: (context, _) {
          final t = _c.value;
          final appear = Motion.emphasizedDecelerate.transform((t / 0.5).clamp(0.0, 1.0));
          final sweep = ((t - 0.45) / 0.5).clamp(0.0, 1.0);
          return Opacity(
            opacity: appear,
            child: Transform.scale(
              scale: 0.8 + 0.2 * appear,
              child: Container(
                width: s,
                height: s,
                decoration: BoxDecoration(
                  borderRadius: radius,
                  boxShadow: [
                    BoxShadow(
                      color: _SplashPalette.glow.withValues(alpha: 0.55 * appear),
                      blurRadius: 56 * appear,
                      spreadRadius: 4 * appear,
                    ),
                    BoxShadow(
                      color: Colors.black.withValues(alpha: 0.25 * appear),
                      blurRadius: 24,
                      offset: const Offset(0, 12),
                    ),
                  ],
                ),
                child: ClipRRect(
                  borderRadius: radius,
                  child: Stack(
                    fit: StackFit.expand,
                    children: [
                      Hero(
                        tag: 'app-logo',
                        child: Image.asset('assets/icon.png', fit: BoxFit.cover, semanticLabel: 'TailorSync logo'),
                      ),
                      if (sweep > 0 && sweep < 1)
                        IgnorePointer(
                          child: DecoratedBox(
                            decoration: BoxDecoration(
                              gradient: LinearGradient(
                                begin: Alignment(-1.5 + 3 * sweep, -1),
                                end: Alignment(-0.9 + 3 * sweep, 1),
                                colors: [
                                  Colors.white.withValues(alpha: 0),
                                  Colors.white.withValues(alpha: 0.55),
                                  Colors.white.withValues(alpha: 0),
                                ],
                              ),
                            ),
                          ),
                        ),
                    ],
                  ),
                ),
              ),
            ),
          );
        },
      ),
    );
  }
}

enum _BootPhase { connecting, waking, ready, offline }

/// Professional pre-loader: stitch loader + cross-fading status copy +
/// a calm explanation when the cloud server is waking up.
class _BootStatus extends StatelessWidget {
  final _BootPhase phase;
  final Duration elapsed;
  final VoidCallback onRetry;
  final VoidCallback onContinue;

  const _BootStatus({
    required this.phase,
    required this.elapsed,
    required this.onRetry,
    required this.onContinue,
  });

  @override
  Widget build(BuildContext context) {
    const white = Colors.white;
    final dim = Colors.white.withValues(alpha: 0.75);
    final offline = phase == _BootPhase.offline;

    final (String title, String? detail) = switch (phase) {
      _BootPhase.connecting => ('Connecting securely…', null),
      _BootPhase.waking => (
          'Waking up the TailorSync cloud…',
          'The server sleeps when idle. First launch can take up to 2 minutes '
              '(${elapsed.inSeconds}s).'
        ),
      _BootPhase.ready => ('Signing you in…', null),
      _BootPhase.offline => (
          'Can\'t reach the server',
          'Check your internet connection and try again.'
        ),
    };

    return ConstrainedBox(
      constraints: const BoxConstraints(maxWidth: 360),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          AnimatedSwitcher(
            duration: Motion.of(context, Motion.medium),
            transitionBuilder: (c, a) => FadeTransition(opacity: a, child: ScaleTransition(scale: a, child: c)),
            child: offline
                ? Container(
                    key: const ValueKey('off'),
                    width: 52,
                    height: 52,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      color: Colors.white.withValues(alpha: 0.08),
                      border: Border.all(color: Colors.white.withValues(alpha: 0.14)),
                    ),
                    child: const Icon(Icons.wifi_off_rounded, color: _SplashPalette.gold, size: 24),
                  )
                : const ScissorLoader(
                    key: ValueKey('load'),
                    size: 132,
                    color: _SplashPalette.goldSoft,
                  ),
          ),
          const SizedBox(height: Space.md),
          AnimatedSwitcher(
            duration: Motion.of(context, Motion.medium),
            transitionBuilder: (c, a) => FadeTransition(
              opacity: a,
              child: SlideTransition(
                position: Tween(begin: const Offset(0, 0.3), end: Offset.zero).animate(a),
                child: c,
              ),
            ),
            child: Text(
              title,
              key: ValueKey(title),
              textAlign: TextAlign.center,
              style: context.text.titleSmall?.copyWith(color: white.withValues(alpha: 0.92), letterSpacing: 0.2),
            ),
          ),
          AnimatedSize(
            duration: Motion.of(context, Motion.medium),
            curve: Motion.emphasized,
            child: detail == null
                ? const SizedBox(width: double.infinity)
                : Padding(
                    padding: const EdgeInsets.only(top: Space.xs),
                    child: Text(
                      detail,
                      textAlign: TextAlign.center,
                      style: context.text.bodySmall?.copyWith(color: dim),
                    ),
                  ),
          ),
          if (phase == _BootPhase.waking) ...[
            const SizedBox(height: Space.md),
            _GoldProgressBar(
              // Approximate progress against a ~2 min cold start.
              value: (elapsed.inMilliseconds / 140000).clamp(0.05, 0.95),
            ),
          ],
          if (offline) ...[
            const SizedBox(height: Space.lg),
            Wrap(
              alignment: WrapAlignment.center,
              spacing: Space.sm,
              runSpacing: Space.xs,
              children: [
                FilledButton.icon(
                  style: FilledButton.styleFrom(backgroundColor: _SplashPalette.gold, foregroundColor: _SplashPalette.bgCenter),
                  onPressed: onRetry,
                  icon: const Icon(Icons.refresh_rounded),
                  label: const Text('Try again'),
                ),
                TextButton(
                  style: TextButton.styleFrom(foregroundColor: white),
                  onPressed: onContinue,
                  child: const Text('Continue anyway'),
                ),
              ],
            ),
          ],
        ],
      ),
    );
  }
}

// ── Splash visual system ──────────────────────────────────────────

/// Midnight navy + champagne gold: calm, premium, and on-brand with the
/// indigo logo (which reads crisply on the dark field).
abstract final class _SplashPalette {
  static const bgCenter = Color(0xFF16205A); // spotlight behind logo
  static const bgMid = Color(0xFF0C1338);
  static const bgEdge = Color(0xFF050817); // matches native launch colour
  static const glow = Color(0xFF4C5FD5);
  static const gold = Color(0xFFE2C27D);
  static const goldSoft = Color(0xFFF6E7C1);
}

/// Deep radial spotlight with a slow, barely-there "breathing" glow and a
/// faint diagonal fabric weave. Replaces the busy colour blobs.
class _SplashBackground extends StatefulWidget {
  final Widget child;
  const _SplashBackground({required this.child});

  @override
  State<_SplashBackground> createState() => _SplashBackgroundState();
}

class _SplashBackgroundState extends State<_SplashBackground> with SingleTickerProviderStateMixin {
  late final AnimationController _c = AnimationController(vsync: this, duration: const Duration(seconds: 6));

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (Motion.reduced(context)) {
      _c.value = 0.5;
      _c.stop();
    } else if (!_c.isAnimating) {
      _c.repeat(reverse: true);
    }
  }

  @override
  void dispose() {
    _c.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Stack(
      fit: StackFit.expand,
      children: [
        const DecoratedBox(
          decoration: BoxDecoration(
            gradient: RadialGradient(
              center: Alignment(0, -0.25),
              radius: 1.15,
              colors: [_SplashPalette.bgCenter, _SplashPalette.bgMid, _SplashPalette.bgEdge],
              stops: [0.0, 0.45, 1.0],
            ),
          ),
        ),
        RepaintBoundary(
          child: CustomPaint(painter: _WeaveAndGlowPainter(_c)),
        ),
        widget.child,
      ],
    );
  }
}

class _WeaveAndGlowPainter extends CustomPainter {
  final Animation<double> anim;
  _WeaveAndGlowPainter(this.anim) : super(repaint: anim);

  @override
  void paint(Canvas canvas, Size size) {
    final t = Curves.easeInOut.transform(anim.value);

    // Soft breathing halo behind the logo.
    final center = Offset(size.width / 2, size.height * 0.36);
    final r = size.shortestSide * (0.55 + 0.05 * t);
    canvas.drawCircle(
      center,
      r,
      Paint()
        ..shader = RadialGradient(colors: [
          _SplashPalette.glow.withValues(alpha: 0.20 + 0.08 * t),
          _SplashPalette.glow.withValues(alpha: 0),
        ]).createShader(Rect.fromCircle(center: center, radius: r)),
    );

    // Very faint diagonal weave (tailoring texture), fades towards edges.
    final weave = Paint()
      ..color = Colors.white.withValues(alpha: 0.025)
      ..strokeWidth = 1;
    const step = 22.0;
    for (double x = -size.height; x < size.width; x += step) {
      canvas.drawLine(Offset(x, 0), Offset(x + size.height, size.height), weave);
    }

    // Vignette to keep focus in the centre.
    final rect = Offset.zero & size;
    canvas.drawRect(
      rect,
      Paint()
        ..shader = RadialGradient(
          radius: 0.95,
          colors: [Colors.transparent, Colors.black.withValues(alpha: 0.35)],
          stops: const [0.6, 1.0],
        ).createShader(rect),
    );
  }

  @override
  bool shouldRepaint(covariant _WeaveAndGlowPainter old) => false;
}

/// Slim gold progress bar with a travelling sheen, used while the cloud
/// server is waking up.
class _GoldProgressBar extends StatefulWidget {
  final double value;
  const _GoldProgressBar({required this.value});

  @override
  State<_GoldProgressBar> createState() => _GoldProgressBarState();
}

class _GoldProgressBarState extends State<_GoldProgressBar> with SingleTickerProviderStateMixin {
  late final AnimationController _sheen = AnimationController(vsync: this, duration: const Duration(milliseconds: 1600));

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (Motion.reduced(context)) {
      _sheen.stop();
    } else if (!_sheen.isAnimating) {
      _sheen.repeat();
    }
  }

  @override
  void dispose() {
    _sheen.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    const width = 200.0;
    return Semantics(
      value: '${(widget.value * 100).round()}%',
      child: ClipRRect(
        borderRadius: Radii.brPill,
        child: Container(
          width: width,
          height: 4,
          color: Colors.white.withValues(alpha: 0.10),
          alignment: Alignment.centerLeft,
          child: TweenAnimationBuilder<double>(
            tween: Tween(end: widget.value),
            duration: const Duration(milliseconds: 900),
            curve: Curves.easeOutCubic,
            builder: (context, v, _) => SizedBox(
              width: width * v,
              height: 4,
              child: AnimatedBuilder(
                animation: _sheen,
                builder: (context, _) {
                  final x = -1.0 + 3.0 * _sheen.value;
                  return DecoratedBox(
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        begin: Alignment(x - 1, 0),
                        end: Alignment(x + 1, 0),
                        colors: const [
                          _SplashPalette.gold,
                          _SplashPalette.goldSoft,
                          _SplashPalette.gold,
                        ],
                      ),
                    ),
                  );
                },
              ),
            ),
          ),
        ),
      ),
    );
  }
}
