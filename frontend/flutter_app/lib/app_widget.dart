import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'routes/app_router.dart';
import 'core/theme/app_theme.dart';

class AppWidget extends StatelessWidget {
  const AppWidget({super.key});

  @override
  Widget build(BuildContext context) {
    return ProviderScope(
      child: MaterialApp.router(
        title: 'TailorSync',
        theme: AppTheme.lightTheme,
        routerConfig: appRouter,
        debugShowCheckedModeBanner: false,
        builder: (context, child) {
          return Container(
            color: const Color(0xFFE0E0E0), // Light neutral background on empty desktop sides
            child: Center(
              child: LayoutBuilder(
                builder: (context, constraints) {
                  final double effectiveWidth = constraints.maxWidth > 430 ? 430 : constraints.maxWidth;
                  final double effectiveHeight = constraints.maxHeight;
                  final currentMediaQuery = MediaQuery.of(context);

                  return MediaQuery(
                    data: currentMediaQuery.copyWith(
                      size: Size(effectiveWidth, effectiveHeight),
                    ),
                    child: ConstrainedBox(
                      constraints: const BoxConstraints(maxWidth: 430),
                      child: ClipRect(
                        child: child ?? const SizedBox.shrink(),
                      ),
                    ),
                  );
                },
              ),
            ),
          );
        },
      ),
    );
  }
}
