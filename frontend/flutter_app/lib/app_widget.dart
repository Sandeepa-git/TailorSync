import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'routes/app_router.dart';
import 'ui/theme/app_theme.dart';
import 'ui/theme/motion.dart';

class AppWidget extends StatefulWidget {
  const AppWidget({super.key});

  @override
  State<AppWidget> createState() => _AppWidgetState();
}

class _AppWidgetState extends State<AppWidget> {
  @override
  void initState() {
    super.initState();
    // Edge-to-edge: draw behind transparent status & navigation bars
    // (works with both gesture and 3-button navigation).
    SystemChrome.setEnabledSystemUIMode(SystemUiMode.edgeToEdge);
  }

  @override
  Widget build(BuildContext context) {
    return ProviderScope(
      child: MaterialApp.router(
        title: 'TailorSync',
        theme: TsTheme.light(),
        themeMode: ThemeMode.light, // App is designed to run in light mode
        themeAnimationDuration: Motion.long,
        themeAnimationCurve: Motion.standard,
        routerConfig: appRouter,
        debugShowCheckedModeBanner: false,
        builder: (context, child) {
          final brightness = Theme.of(context).brightness;
          return AnnotatedRegion<SystemUiOverlayStyle>(
            value: TsTheme.overlayStyle(brightness),
            child: ColoredBox(
              color: Theme.of(context).colorScheme.surface,
              child: child ?? const SizedBox.shrink(),
            ),
          );
        },
      ),
    );
  }
}
