import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';

class MainLayout extends ConsumerWidget {
  final Widget child;

  const MainLayout({super.key, required this.child});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final String location = GoRouterState.of(context).location;

    int currentIndex = 0;
    if (location.startsWith('/orders')) {
      currentIndex = 1;
    } else if (location.startsWith('/customers')) {
      currentIndex = 2;
    } else if (location.startsWith('/tasks')) {
      currentIndex = 3;
    } else if (location.startsWith('/reports')) {
      currentIndex = 4;
    } else if (location.startsWith('/profile')) {
      currentIndex = 5;
    }

    void onSelectDestination(int index) {
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
        case 5:
          context.go('/profile');
          break;
      }
    }

    return Scaffold(
      backgroundColor: const Color(0xFFF8F9FA),
      body: child,
      bottomNavigationBar: SafeArea(
        child: Container(
          decoration: const BoxDecoration(
            color: Colors.white,
            border: Border(top: BorderSide(color: Color(0xFFE8EAF6), width: 1.5)),
            boxShadow: [
              BoxShadow(
                color: Color(0x0F1A237E),
                blurRadius: 10,
                offset: Offset(0, -2),
              ),
            ],
          ),
          child: NavigationBarTheme(
            data: NavigationBarThemeData(
              indicatorColor: const Color(0xFF1A237E).withValues(alpha: 0.12),
              labelTextStyle: WidgetStateProperty.resolveWith((states) {
                if (states.contains(WidgetState.selected)) {
                  return GoogleFonts.inter(fontSize: 11, fontWeight: FontWeight.bold, color: const Color(0xFF1A237E));
                }
                return GoogleFonts.inter(fontSize: 11, color: const Color(0xFF5C6BC0));
              }),
              iconTheme: WidgetStateProperty.resolveWith((states) {
                if (states.contains(WidgetState.selected)) {
                  return const IconThemeData(color: Color(0xFF1A237E));
                }
                return const IconThemeData(color: Color(0xFF5C6BC0));
              }),
            ),
            child: NavigationBar(
              selectedIndex: currentIndex,
              backgroundColor: Colors.white,
              elevation: 0,
              height: 64,
              onDestinationSelected: (index) {
                HapticFeedback.selectionClick();
                onSelectDestination(index);
              },
              destinations: const [
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
                NavigationDestination(
                  icon: Icon(Icons.person_outline),
                  selectedIcon: Icon(Icons.person),
                  label: 'Profile',
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

