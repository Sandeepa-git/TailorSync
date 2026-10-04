import 'package:animations/animations.dart';
import 'package:flutter/cupertino.dart' show CupertinoPageTransitionsBuilder;
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_fonts/google_fonts.dart';

import 'tokens.dart';

/// TailorSync design system – Material 3, seeded from the logo indigo.
abstract final class TsTheme {
  static ThemeData light() => _build(Brightness.light);
  static ThemeData dark() => _build(Brightness.dark);

  static ColorScheme _scheme(Brightness b) {
    final base = ColorScheme.fromSeed(
      seedColor: kBrandSeed,
      brightness: b,
      dynamicSchemeVariant: DynamicSchemeVariant.fidelity,
    );
    if (b == Brightness.light) {
      // Keep the exact logo indigo as the primary brand colour.
      return base.copyWith(
        primary: kBrandSeed,
        onPrimary: Colors.white,
        surface: const Color(0xFFFBFBFF),
        surfaceContainerLowest: Colors.white,
        surfaceContainerLow: const Color(0xFFF6F7FC),
        surfaceContainer: const Color(0xFFF0F1F8),
        surfaceContainerHigh: const Color(0xFFEAECF5),
        surfaceContainerHighest: const Color(0xFFE3E5F0),
      );
    }
    return base.copyWith(
      surface: const Color(0xFF0F1120),
      surfaceContainerLowest: const Color(0xFF0A0C18),
      surfaceContainerLow: const Color(0xFF161929),
      surfaceContainer: const Color(0xFF1B1E30),
      surfaceContainerHigh: const Color(0xFF232739),
      surfaceContainerHighest: const Color(0xFF2C3044),
    );
  }

  static TextTheme _text(ColorScheme cs) {
    final base = GoogleFonts.plusJakartaSansTextTheme(
      cs.brightness == Brightness.light ? ThemeData.light().textTheme : ThemeData.dark().textTheme,
    );
    TextStyle? t(TextStyle? s, {FontWeight? w, double? ls, double? h}) =>
        s?.copyWith(fontWeight: w, letterSpacing: ls, height: h, color: cs.onSurface);
    return base.copyWith(
      displayLarge: t(base.displayLarge, w: FontWeight.w800, ls: -1.2),
      displayMedium: t(base.displayMedium, w: FontWeight.w800, ls: -1.0),
      displaySmall: t(base.displaySmall, w: FontWeight.w700, ls: -0.8),
      headlineLarge: t(base.headlineLarge, w: FontWeight.w700, ls: -0.6),
      headlineMedium: t(base.headlineMedium, w: FontWeight.w700, ls: -0.5),
      headlineSmall: t(base.headlineSmall, w: FontWeight.w700, ls: -0.3),
      titleLarge: t(base.titleLarge, w: FontWeight.w700, ls: -0.2),
      titleMedium: t(base.titleMedium, w: FontWeight.w600),
      titleSmall: t(base.titleSmall, w: FontWeight.w600),
      bodyLarge: t(base.bodyLarge, h: 1.5),
      bodyMedium: t(base.bodyMedium, h: 1.45)?.copyWith(color: cs.onSurfaceVariant),
      bodySmall: t(base.bodySmall, h: 1.4)?.copyWith(color: cs.onSurfaceVariant),
      labelLarge: t(base.labelLarge, w: FontWeight.w700, ls: 0.1),
      labelMedium: t(base.labelMedium, w: FontWeight.w600),
      labelSmall: t(base.labelSmall, w: FontWeight.w600, ls: 0.3),
    );
  }

  static ThemeData _build(Brightness b) {
    final cs = _scheme(b);
    final text = _text(cs);
    final isDark = b == Brightness.dark;
    final status = isDark ? StatusColors.dark : StatusColors.light;

    final inputBorder = OutlineInputBorder(
      borderRadius: Radii.brMd,
      borderSide: BorderSide(color: cs.outlineVariant),
    );

    return ThemeData(
      useMaterial3: true,
      brightness: b,
      colorScheme: cs,
      textTheme: text,
      scaffoldBackgroundColor: cs.surface,
      canvasColor: cs.surface,
      splashFactory: InkSparkle.splashFactory,
      visualDensity: VisualDensity.standard,
      materialTapTargetSize: MaterialTapTargetSize.padded,
      extensions: [status],
      pageTransitionsTheme: const PageTransitionsTheme(
        builders: {
          TargetPlatform.android: SharedAxisPageTransitionsBuilder(
            transitionType: SharedAxisTransitionType.horizontal,
          ),
          TargetPlatform.iOS: CupertinoPageTransitionsBuilder(),
          TargetPlatform.windows: SharedAxisPageTransitionsBuilder(
            transitionType: SharedAxisTransitionType.horizontal,
          ),
          TargetPlatform.linux: SharedAxisPageTransitionsBuilder(
            transitionType: SharedAxisTransitionType.horizontal,
          ),
          TargetPlatform.macOS: CupertinoPageTransitionsBuilder(),
        },
      ),
      appBarTheme: AppBarTheme(
        backgroundColor: Colors.transparent,
        surfaceTintColor: Colors.transparent,
        foregroundColor: cs.onSurface,
        elevation: 0,
        scrolledUnderElevation: 0,
        centerTitle: false,
        titleTextStyle: text.titleLarge,
        systemOverlayStyle: overlayStyle(b),
      ),
      cardTheme: CardThemeData(
        color: cs.surfaceContainerLowest,
        surfaceTintColor: Colors.transparent,
        elevation: 0,
        margin: EdgeInsets.zero,
        shape: RoundedRectangleBorder(
          borderRadius: Radii.brLg,
          side: BorderSide(color: cs.outlineVariant.withValues(alpha: isDark ? 0.35 : 0.5)),
        ),
      ),
      dividerTheme: DividerThemeData(color: cs.outlineVariant.withValues(alpha: 0.6), thickness: 1, space: 1),
      iconTheme: IconThemeData(color: cs.onSurfaceVariant, size: 22),
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: isDark ? cs.surfaceContainerHigh : cs.surfaceContainerLow,
        contentPadding: const EdgeInsets.symmetric(horizontal: Space.md, vertical: 14),
        labelStyle: text.bodyMedium,
        floatingLabelStyle: text.labelLarge?.copyWith(color: cs.primary),
        hintStyle: text.bodyMedium?.copyWith(color: cs.onSurfaceVariant.withValues(alpha: 0.7)),
        prefixIconColor: WidgetStateColor.resolveWith(
          (s) => s.contains(WidgetState.focused) ? cs.primary : cs.onSurfaceVariant,
        ),
        suffixIconColor: cs.onSurfaceVariant,
        errorStyle: text.bodySmall?.copyWith(color: cs.error),
        errorMaxLines: 3,
        border: inputBorder,
        enabledBorder: inputBorder,
        focusedBorder: inputBorder.copyWith(borderSide: BorderSide(color: cs.primary, width: 2)),
        errorBorder: inputBorder.copyWith(borderSide: BorderSide(color: cs.error)),
        focusedErrorBorder: inputBorder.copyWith(borderSide: BorderSide(color: cs.error, width: 2)),
        disabledBorder: inputBorder.copyWith(
          borderSide: BorderSide(color: cs.outlineVariant.withValues(alpha: 0.4)),
        ),
      ),
      filledButtonTheme: FilledButtonThemeData(
        style: FilledButton.styleFrom(
          minimumSize: const Size(kMinTouch, 52),
          padding: const EdgeInsets.symmetric(horizontal: Space.lg, vertical: 14),
          shape: RoundedRectangleBorder(borderRadius: Radii.brMd),
          textStyle: text.labelLarge,
        ),
      ),
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          backgroundColor: cs.primary,
          foregroundColor: cs.onPrimary,
          elevation: 0,
          minimumSize: const Size(kMinTouch, 52),
          padding: const EdgeInsets.symmetric(horizontal: Space.lg, vertical: 14),
          shape: RoundedRectangleBorder(borderRadius: Radii.brMd),
          textStyle: text.labelLarge,
        ),
      ),
      outlinedButtonTheme: OutlinedButtonThemeData(
        style: OutlinedButton.styleFrom(
          foregroundColor: cs.primary,
          minimumSize: const Size(kMinTouch, 52),
          padding: const EdgeInsets.symmetric(horizontal: Space.lg, vertical: 14),
          side: BorderSide(color: cs.outlineVariant),
          shape: RoundedRectangleBorder(borderRadius: Radii.brMd),
          textStyle: text.labelLarge,
        ),
      ),
      textButtonTheme: TextButtonThemeData(
        style: TextButton.styleFrom(
          foregroundColor: cs.primary,
          minimumSize: const Size(kMinTouch, kMinTouch),
          shape: RoundedRectangleBorder(borderRadius: Radii.brSm),
          textStyle: text.labelLarge,
        ),
      ),
      iconButtonTheme: IconButtonThemeData(
        style: IconButton.styleFrom(minimumSize: const Size(kMinTouch, kMinTouch)),
      ),
      floatingActionButtonTheme: FloatingActionButtonThemeData(
        backgroundColor: cs.primary,
        foregroundColor: cs.onPrimary,
        elevation: 2,
        highlightElevation: 4,
        shape: RoundedRectangleBorder(borderRadius: Radii.brLg),
        extendedTextStyle: text.labelLarge,
      ),
      chipTheme: ChipThemeData(
        shape: RoundedRectangleBorder(borderRadius: Radii.brPill),
        side: BorderSide(color: cs.outlineVariant),
        backgroundColor: cs.surfaceContainerLowest,
        selectedColor: cs.primary,
        // Selected chips are dark blue, so their text turns white.
        labelStyle: text.labelMedium?.copyWith(
          color: WidgetStateColor.resolveWith(
            (s) => s.contains(WidgetState.selected) ? cs.onPrimary : cs.onSurface,
          ),
        ),
        secondaryLabelStyle: text.labelMedium?.copyWith(color: cs.onPrimary),
        secondarySelectedColor: cs.primary,
        padding: const EdgeInsets.symmetric(horizontal: Space.xs, vertical: Space.xxs),
        showCheckmark: false,
      ),
      listTileTheme: ListTileThemeData(
        contentPadding: const EdgeInsets.symmetric(horizontal: Space.md),
        minVerticalPadding: Space.sm,
        shape: RoundedRectangleBorder(borderRadius: Radii.brMd),
        iconColor: cs.onSurfaceVariant,
        titleTextStyle: text.titleMedium,
        subtitleTextStyle: text.bodySmall,
      ),
      dialogTheme: DialogThemeData(
        backgroundColor: cs.surfaceContainerLow,
        surfaceTintColor: Colors.transparent,
        shape: RoundedRectangleBorder(borderRadius: Radii.brXl),
        titleTextStyle: text.titleLarge,
        contentTextStyle: text.bodyMedium,
        insetPadding: const EdgeInsets.symmetric(horizontal: Space.md, vertical: Space.lg),
      ),
      bottomSheetTheme: BottomSheetThemeData(
        backgroundColor: cs.surfaceContainerLow,
        surfaceTintColor: Colors.transparent,
        modalBarrierColor: Colors.black.withValues(alpha: 0.45),
        showDragHandle: true,
        dragHandleColor: cs.outlineVariant,
        shape: const RoundedRectangleBorder(
          borderRadius: BorderRadius.vertical(top: Radius.circular(Radii.xl)),
        ),
        constraints: const BoxConstraints(maxWidth: MaxWidth.content),
      ),
      snackBarTheme: SnackBarThemeData(
        behavior: SnackBarBehavior.floating,
        backgroundColor: isDark ? cs.surfaceContainerHighest : const Color(0xFF1B1E30),
        contentTextStyle: text.bodyMedium?.copyWith(color: isDark ? cs.onSurface : Colors.white),
        actionTextColor: isDark ? cs.primary : const Color(0xFFBAC3FF),
        shape: RoundedRectangleBorder(borderRadius: Radii.brMd),
        elevation: 4,
        insetPadding: const EdgeInsets.fromLTRB(Space.md, 0, Space.md, Space.md),
      ),
      progressIndicatorTheme: ProgressIndicatorThemeData(
        color: cs.primary,
        linearTrackColor: cs.primaryContainer,
        circularTrackColor: Colors.transparent,
      ),
      switchTheme: SwitchThemeData(
        thumbIcon: WidgetStateProperty.resolveWith(
          (s) => s.contains(WidgetState.selected) ? const Icon(Icons.check_rounded, size: 14) : null,
        ),
      ),
      tabBarTheme: TabBarThemeData(
        labelColor: cs.onPrimary,
        unselectedLabelColor: cs.onSurfaceVariant,
        labelStyle: text.labelLarge,
        unselectedLabelStyle: text.labelLarge,
        indicatorSize: TabBarIndicatorSize.tab,
        dividerColor: Colors.transparent,
        indicator: BoxDecoration(color: cs.primary, borderRadius: Radii.brPill),
        splashBorderRadius: Radii.brPill,
      ),
      tooltipTheme: TooltipThemeData(
        decoration: BoxDecoration(color: cs.inverseSurface, borderRadius: Radii.brXs),
        textStyle: text.labelMedium?.copyWith(color: cs.onInverseSurface),
      ),
      datePickerTheme: DatePickerThemeData(
        backgroundColor: cs.surfaceContainerLow,
        surfaceTintColor: Colors.transparent,
        shape: RoundedRectangleBorder(borderRadius: Radii.brXl),
      ),
    );
  }

  /// Transparent, edge-to-edge system bars with the right icon brightness.
  static SystemUiOverlayStyle overlayStyle(Brightness b) {
    final dark = b == Brightness.dark;
    return SystemUiOverlayStyle(
      statusBarColor: Colors.transparent,
      statusBarIconBrightness: dark ? Brightness.light : Brightness.dark,
      statusBarBrightness: dark ? Brightness.dark : Brightness.light,
      systemNavigationBarColor: Colors.transparent,
      systemNavigationBarDividerColor: Colors.transparent,
      systemNavigationBarIconBrightness: dark ? Brightness.light : Brightness.dark,
      systemNavigationBarContrastEnforced: false,
    );
  }
}

/// Convenience accessors.
extension ThemeX on BuildContext {
  ThemeData get theme => Theme.of(this);
  ColorScheme get colors => Theme.of(this).colorScheme;
  TextTheme get text => Theme.of(this).textTheme;
  StatusColors get status => Theme.of(this).extension<StatusColors>() ?? StatusColors.light;
  bool get isDark => Theme.of(this).brightness == Brightness.dark;
}
