import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

class MainLayout extends StatelessWidget {
  final Widget child;

  const MainLayout({super.key, required this.child});

  @override
  Widget build(BuildContext context) {
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
      // Profile isn't in bottom nav anymore, but keep the nav hidden or just leave selected as home.
      currentIndex = 0;
    }

    return Scaffold(
      backgroundColor: const Color(0xFFF8F9FA),
      body: child,
      bottomNavigationBar: NavigationBarTheme(
        data: NavigationBarThemeData(
          indicatorColor: const Color(0xFF9FA8DA), // Light blue pill
          labelTextStyle: MaterialStateProperty.resolveWith((states) {
            if (states.contains(MaterialState.selected)) {
              return const TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: Color(0xFF1A237E));
            }
            return const TextStyle(fontSize: 11, color: Color(0xFF5C6BC0));
          }),
          iconTheme: MaterialStateProperty.resolveWith((states) {
            if (states.contains(MaterialState.selected)) {
              return const IconThemeData(color: Color(0xFF1A237E));
            }
            return const IconThemeData(color: Color(0xFF5C6BC0));
          }),
        ),
        child: NavigationBar(
          selectedIndex: currentIndex,
          backgroundColor: Colors.white,
          elevation: 10,
          onDestinationSelected: (index) {
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
          },
          destinations: const [
            NavigationDestination(icon: Icon(Icons.grid_view), label: 'Home'),
            NavigationDestination(icon: Icon(Icons.shopping_bag_outlined), label: 'Orders'),
            NavigationDestination(icon: Icon(Icons.people_outline), label: 'Customers'),
            NavigationDestination(icon: Icon(Icons.assignment_outlined), label: 'Tasks'),
            NavigationDestination(icon: Icon(Icons.bar_chart), label: 'Reports'),
          ],
        ),
      ),
    );
  }
}
