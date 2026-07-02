import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'routes/app_router.dart';
import 'core/theme/app_theme.dart';

class AppWidget extends StatelessWidget {
  const AppWidget({super.key});

  @override
  Widget build(BuildContext context) {
    return ProviderScope(
      child: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 480),
          child: MaterialApp.router(
            title: 'TailorSync',
            theme: AppTheme.lightTheme,
            routerConfig: appRouter,
            debugShowCheckedModeBanner: false,
          ),
        ),
      ),
    );
  }
}

