import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../theme/app_theme.dart';
import '../../network/providers/user_provider.dart';

class MainLayout extends ConsumerWidget {
  final Widget child;

  const MainLayout({super.key, required this.child});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final String location = GoRouterState.of(context).location;

    final userAsync = ref.watch(userProvider);
    final isStaff = userAsync.valueOrNull?['role'] == 'staff' || userAsync.valueOrNull?['role'] == 'STAFF';

    int currentIndex = 0;
    if (isStaff) {
      if (location.startsWith('/tasks')) {
        currentIndex = 0;
      } else if (location.startsWith('/profile')) {
        currentIndex = 1;
      }
    } else {
      if (location.startsWith('/orders')) {
        currentIndex = 1;
      } else if (location.startsWith('/customers')) {
        currentIndex = 2;
      } else if (location.startsWith('/tasks')) {
        currentIndex = 3;
      } else if (location.startsWith('/reports')) {
        currentIndex = 4;
      }
    }

    void onSelectDestination(int index) {
      if (isStaff) {
        if (index == 0) {
          context.go('/tasks');
        } else if (index == 1) {
          context.go('/profile');
        }
      } else {
        switch (index) {
          case 0:
            context.go('/home');
            break;
          case 1:
            context.go('/orders');
            break;
          case 2:
            context.go('/customers');
            break;
          case 3:
            context.go('/tasks');
            break;
          case 4:
            context.go('/reports');
            break;
        }
      }
    }

    return Scaffold(
      backgroundColor: AppTheme.scaffoldBg,
      body: child,
      bottomNavigationBar: SafeArea(
        child: Container(
          margin: const EdgeInsets.fromLTRB(16, 0, 16, 12),
          decoration: BoxDecoration(
            color: Colors.white.withValues(alpha: 0.92),
            borderRadius: BorderRadius.circular(26),
            boxShadow: [
              BoxShadow(
                color: AppTheme.primary.withValues(alpha: 0.10),
                blurRadius: 24,
                offset: const Offset(0, 6),
              ),
              BoxShadow(
                color: AppTheme.primary.withValues(alpha: 0.04),
                blurRadius: 6,
                offset: const Offset(0, 1),
              ),
            ],
          ),
          child: ClipRRect(
            borderRadius: BorderRadius.circular(26),
            child: BackdropFilter(
              filter: ImageFilter.blur(sigmaX: 12, sigmaY: 12),
              child: NavigationBarTheme(
                data: NavigationBarThemeData(
                  indicatorColor: AppTheme.primary.withValues(alpha: 0.10),
                  indicatorShape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(14),
                  ),
                  labelTextStyle: WidgetStateProperty.resolveWith((states) {
                    if (states.contains(WidgetState.selected)) {
                      return GoogleFonts.inter(fontSize: 11, fontWeight: FontWeight.bold, color: AppTheme.primary);
                    }
                    return GoogleFonts.inter(fontSize: 11, color: const Color(0xFF9E9E9E));
                  }),
                  iconTheme: WidgetStateProperty.resolveWith((states) {
                    if (states.contains(WidgetState.selected)) {
                      return const IconThemeData(color: Color(0xFF1A237E), size: 22);
                    }
                    return const IconThemeData(color: Color(0xFF9E9E9E));
                  }),
                ),
                child: NavigationBar(
                  selectedIndex: currentIndex,
                  backgroundColor: Colors.transparent,
                  surfaceTintColor: Colors.transparent,
                  elevation: 0,
                  height: 68,
                  onDestinationSelected: (index) {
                    HapticFeedback.selectionClick();
                    onSelectDestination(index);
                  },
                  destinations: isStaff 
                    ? const [
                        NavigationDestination(
                          icon: Icon(Icons.assignment_outlined),
                          selectedIcon: Icon(Icons.assignment),
                          label: 'Tasks',
                        ),
                        NavigationDestination(
                          icon: Icon(Icons.person_outline),
                          selectedIcon: Icon(Icons.person),
                          label: 'Profile',
                        ),
                      ]
                    : const [
                        NavigationDestination(
                          icon: Icon(Icons.grid_view_outlined),
                          selectedIcon: Icon(Icons.grid_view_rounded),
                          label: 'Home',
                        ),
                        NavigationDestination(
                          icon: Icon(Icons.shopping_bag_outlined),
                          selectedIcon: Icon(Icons.shopping_bag),
                          label: 'Orders',
                        ),
                        NavigationDestination(
                          icon: Icon(Icons.people_outline),
                          selectedIcon: Icon(Icons.people),
                          label: 'Customers',
                        ),
                        NavigationDestination(
                          icon: Icon(Icons.assignment_outlined),
                          selectedIcon: Icon(Icons.assignment),
                          label: 'Tasks',
                        ),
                        NavigationDestination(
                          icon: Icon(Icons.bar_chart_outlined),
                          selectedIcon: Icon(Icons.bar_chart_rounded),
                          label: 'Reports',
                        ),
                      ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
