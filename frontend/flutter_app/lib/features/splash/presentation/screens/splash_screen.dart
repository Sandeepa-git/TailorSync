import 'dart:async';

import 'package:flutter/material.dart';
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
    // Ensure the splash screen is visible for at least 2 seconds
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
            // Proceed anyway as per the requirement not to force logout
            destination = '/home'; 
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
    return Scaffold(
      body: AmbientBackground(
        vivid: true,
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
                          style: context.text.displaySmall?.copyWith(color: Colors.white),
                        ),
                      ),
                      const SizedBox(height: Space.xs),
                      EntranceFade(
                        delay: const Duration(milliseconds: 480),
                        child: Text(
                          'Professional Tailoring Management',
                          textAlign: TextAlign.center,
                          style: context.text.bodyLarge?.copyWith(
                            color: Colors.white.withValues(alpha: 0.78),
                            letterSpacing: 0.4,
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
                      color: const Color(0xFF8C9EFF).withValues(alpha: 0.45 * appear),
                      blurRadius: 48 * appear,
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
                    width: 64,
                    height: 64,
                    decoration: BoxDecoration(shape: BoxShape.circle, color: Colors.white.withValues(alpha: 0.12)),
                    child: const Icon(Icons.wifi_off_rounded, color: white, size: 30),
                  )
                : const StitchLoader(key: ValueKey('load'), size: 64, color: white),
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
              style: context.text.titleSmall?.copyWith(color: white),
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
            ClipRRect(
              borderRadius: Radii.brPill,
              child: SizedBox(
                width: 180,
                child: LinearProgressIndicator(
                  // Approximate progress against a ~2 min cold start.
                  value: (elapsed.inMilliseconds / 140000).clamp(0.05, 0.95),
                  minHeight: 4,
                  color: white,
                  backgroundColor: Colors.white.withValues(alpha: 0.18),
                ),
              ),
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
                  style: FilledButton.styleFrom(backgroundColor: white, foregroundColor: const Color(0xFF1A237E)),
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
