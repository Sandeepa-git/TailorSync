import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:dio/dio.dart';
import '../../../../routes/app_router.dart';
import '../../../../core/network/providers/user_provider.dart';
import '../../../../core/network/providers/api_provider.dart';
import '../../../../core/theme/app_theme.dart';

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
    _checkAuthAndNavigate();
  }

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

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.scaffoldBg,
      body: Semantics(
        label: 'Loading TailorSync',
        liveRegion: true,
        child: AnimatedBuilder(
          animation: _animationController,
          builder: (context, child) {
            return Opacity(
              opacity: _fadeAnimation.value,
              child: Transform.scale(
                scale: _scaleAnimation.value,
                child: Center(
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      // ── Logo ──
                      Container(
                        width: 120,
                        height: 120,
                        decoration: BoxDecoration(
                          borderRadius: BorderRadius.circular(28),
                          boxShadow: [
                            BoxShadow(
                              color: AppTheme.primary.withValues(alpha: 0.1),
                              blurRadius: 30,
                              offset: const Offset(0, 10),
                            ),
                          ],
                        ),
                        clipBehavior: Clip.antiAlias,
                        child: Image.asset(
                          'assets/icon.png',
                          fit: BoxFit.cover,
                        ),
                      ),
                      const SizedBox(height: 32),

                      // ── Wordmark ──
                      Text(
                        'TailorSync',
                        textAlign: TextAlign.center,
                        style: GoogleFonts.outfit(
                          fontSize: 32,
                          fontWeight: FontWeight.w800,
                          color: AppTheme.primaryDark,
                          letterSpacing: -0.5,
                        ),
                      ),
                      const SizedBox(height: 8),
                      
                      Text(
                        'Professional Tailoring Management',
                        textAlign: TextAlign.center,
                        style: GoogleFonts.inter(
                          fontSize: 14,
                          color: AppTheme.textBody,
                          letterSpacing: 0.5,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                      
                      const SizedBox(height: 48),
                      
                      // ── Minimal Loader ──
                      SizedBox(
                        width: 24,
                        height: 24,
                        child: CircularProgressIndicator(
                          strokeWidth: 2.5,
                          valueColor: AlwaysStoppedAnimation<Color>(AppTheme.primary.withValues(alpha: 0.7)),
                        ),
                      ),
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
