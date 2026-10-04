import 'package:flutter/material.dart';

/// Brand seed taken from the TailorSync logo (indigo scissors & needle).
const Color kBrandSeed = Color(0xFF1A237E);

/// Spacing scale (8pt grid with 4/12 half-steps).
abstract final class Space {
  static const double xxs = 4;
  static const double xs = 8;
  static const double sm = 12;
  static const double md = 16;
  static const double lg = 24;
  static const double xl = 32;
  static const double xxl = 48;
}

/// Corner radii.
abstract final class Radii {
  static const double xs = 8;
  static const double sm = 12;
  static const double md = 16;
  static const double lg = 20;
  static const double xl = 28;
  static const double pill = 999;

  static BorderRadius get brXs => BorderRadius.circular(xs);
  static BorderRadius get brSm => BorderRadius.circular(sm);
  static BorderRadius get brMd => BorderRadius.circular(md);
  static BorderRadius get brLg => BorderRadius.circular(lg);
  static BorderRadius get brXl => BorderRadius.circular(xl);
  static BorderRadius get brPill => BorderRadius.circular(pill);
}

/// Minimum interactive size (Material / WCAG).
const double kMinTouch = 48;

/// Content max widths used on wide screens (foldables / tablets).
abstract final class MaxWidth {
  static const double form = 600;
  static const double content = 720;
}

/// Semantic status colours that are not part of the M3 ColorScheme.
/// Each has a light and dark variant chosen for AA contrast on surfaces.
@immutable
class StatusColors extends ThemeExtension<StatusColors> {
  final Color success;
  final Color onSuccessContainer;
  final Color successContainer;
  final Color warning;
  final Color warningContainer;
  final Color onWarningContainer;
  final Color info;
  final Color infoContainer;
  final Color onInfoContainer;
  final Color danger;
  final Color dangerContainer;
  final Color onDangerContainer;

  const StatusColors({
    required this.success,
    required this.successContainer,
    required this.onSuccessContainer,
    required this.warning,
    required this.warningContainer,
    required this.onWarningContainer,
    required this.info,
    required this.infoContainer,
    required this.onInfoContainer,
    required this.danger,
    required this.dangerContainer,
    required this.onDangerContainer,
  });

  static const light = StatusColors(
    success: Color(0xFF1B7F4B),
    successContainer: Color(0xFFD5F5E3),
    onSuccessContainer: Color(0xFF0B3D23),
    warning: Color(0xFFB45309),
    warningContainer: Color(0xFFFFEDD5),
    onWarningContainer: Color(0xFF5A2A04),
    info: Color(0xFF1D5FBF),
    infoContainer: Color(0xFFDCE8FF),
    onInfoContainer: Color(0xFF0B2A5C),
    danger: Color(0xFFBA1A1A),
    dangerContainer: Color(0xFFFFDAD6),
    onDangerContainer: Color(0xFF410002),
  );

  static const dark = StatusColors(
    success: Color(0xFF6FDDA0),
    successContainer: Color(0xFF0F4D2E),
    onSuccessContainer: Color(0xFFC6F5DA),
    warning: Color(0xFFFFB870),
    warningContainer: Color(0xFF5C3307),
    onWarningContainer: Color(0xFFFFE0C2),
    info: Color(0xFF9EC2FF),
    infoContainer: Color(0xFF15386E),
    onInfoContainer: Color(0xFFD8E5FF),
    danger: Color(0xFFFFB4AB),
    dangerContainer: Color(0xFF93000A),
    onDangerContainer: Color(0xFFFFDAD6),
  );

  @override
  StatusColors copyWith() => this;

  @override
  StatusColors lerp(ThemeExtension<StatusColors>? other, double t) {
    if (other is! StatusColors) return this;
    Color l(Color a, Color b) => Color.lerp(a, b, t)!;
    return StatusColors(
      success: l(success, other.success),
      successContainer: l(successContainer, other.successContainer),
      onSuccessContainer: l(onSuccessContainer, other.onSuccessContainer),
      warning: l(warning, other.warning),
      warningContainer: l(warningContainer, other.warningContainer),
      onWarningContainer: l(onWarningContainer, other.onWarningContainer),
      info: l(info, other.info),
      infoContainer: l(infoContainer, other.infoContainer),
      onInfoContainer: l(onInfoContainer, other.onInfoContainer),
      danger: l(danger, other.danger),
      dangerContainer: l(dangerContainer, other.dangerContainer),
      onDangerContainer: l(onDangerContainer, other.onDangerContainer),
    );
  }
}

/// Soft layered shadows, tinted by the scheme's shadow colour.
abstract final class Shadows {
  static List<BoxShadow> soft(ColorScheme cs) => [
        BoxShadow(
          color: cs.shadow.withValues(alpha: cs.brightness == Brightness.dark ? 0.30 : 0.06),
          blurRadius: 18,
          offset: const Offset(0, 6),
        ),
        BoxShadow(
          color: cs.shadow.withValues(alpha: cs.brightness == Brightness.dark ? 0.20 : 0.04),
          blurRadius: 4,
          offset: const Offset(0, 1),
        ),
      ];

  static List<BoxShadow> raised(ColorScheme cs) => [
        BoxShadow(
          color: cs.primary.withValues(alpha: cs.brightness == Brightness.dark ? 0.25 : 0.18),
          blurRadius: 28,
          offset: const Offset(0, 12),
        ),
        BoxShadow(
          color: cs.shadow.withValues(alpha: 0.06),
          blurRadius: 6,
          offset: const Offset(0, 2),
        ),
      ];
}

/// Brand gradients.
abstract final class Gradients {
  static LinearGradient hero(ColorScheme cs) => LinearGradient(
        begin: Alignment.topLeft,
        end: Alignment.bottomRight,
        colors: cs.brightness == Brightness.dark
            ? const [Color(0xFF2A3290), Color(0xFF151A55)]
            : const [Color(0xFF283593), Color(0xFF1A237E)],
      );

  static LinearGradient accent(ColorScheme cs) => LinearGradient(
        begin: Alignment.topLeft,
        end: Alignment.bottomRight,
        colors: [cs.primary, Color.lerp(cs.primary, cs.tertiary, 0.55)!],
      );
}
