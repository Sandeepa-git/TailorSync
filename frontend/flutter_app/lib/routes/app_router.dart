import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../core/presentation/layout/main_layout.dart';
import '../features/splash/presentation/screens/splash_screen.dart';
import '../features/auth/presentation/screens/login_screen.dart';
import '../features/dashboard/presentation/screens/dashboard_screen.dart';
import '../features/customers/presentation/screens/customers_list_screen.dart';
import '../features/customers/presentation/screens/customer_form_screen.dart';
import '../features/orders/presentation/screens/orders_list_screen.dart';
import '../features/orders/presentation/screens/new_order_wizard.dart';
import '../features/orders/presentation/screens/order_details_screen.dart';
import '../features/orders/models/order.dart';
import '../features/tasks/presentation/screens/tasks_screen.dart';
import '../features/reports/presentation/screens/reports_screen.dart';
import '../features/ai_tools/presentation/screens/ai_tools_screen.dart';
import '../features/pattern_viewer/presentation/screens/pattern_viewer_screen.dart';
import '../features/profile/presentation/screens/profile_screen.dart';
import '../features/profile/presentation/screens/business_profile_screen.dart';
import '../features/profile/presentation/screens/staff_management_screen.dart';
import '../features/profile/presentation/screens/measurement_templates_screen.dart';
import '../features/customers/models/customer.dart';
import '../ui/components/transitions.dart';

final GlobalKey<NavigatorState> _rootNavigatorKey = GlobalKey<NavigatorState>(debugLabel: 'root');
final GlobalKey<NavigatorState> _shellNavigatorKey = GlobalKey<NavigatorState>(debugLabel: 'shell');

final GoRouter appRouter = GoRouter(
  navigatorKey: _rootNavigatorKey,
  initialLocation: '/splash',
  routes: <RouteBase>[
    // Splash & Auth (outside shell)
    GoRoute(
      path: '/splash',
      pageBuilder: (BuildContext context, GoRouterState state) => fadeScalePage(state, const SplashScreen()),
    ),
    GoRoute(
      path: '/login',
      pageBuilder: (BuildContext context, GoRouterState state) => fadeScalePage(state, const LoginScreen()),
    ),
    // New Order Wizard (full screen, outside shell)
    GoRoute(
      path: '/orders/new',
      parentNavigatorKey: _rootNavigatorKey,
      pageBuilder: (BuildContext context, GoRouterState state) => sharedAxisVerticalPage(state, const NewOrderWizard()),
    ),


    // Main app with bottom nav
    ShellRoute(
      navigatorKey: _shellNavigatorKey,
      builder: (BuildContext context, GoRouterState state, Widget child) {
        return MainLayout(child: child);
      },
      routes: <RouteBase>[
        GoRoute(
          path: '/home',
          pageBuilder: (BuildContext context, GoRouterState state) => fadeThroughPage(state, const DashboardScreen()),
        ),
        GoRoute(
          path: '/customers',
          pageBuilder: (BuildContext context, GoRouterState state) => fadeThroughPage(state, const CustomersListScreen()),
          routes: [
            GoRoute(
              path: 'new',
              builder: (BuildContext context, GoRouterState state) => const CustomerFormScreen(),
            ),
            GoRoute(
              path: 'edit',
              builder: (BuildContext context, GoRouterState state) => CustomerFormScreen(customer: state.extra as Customer),
            ),
          ],
        ),
        GoRoute(
          path: '/orders',
          pageBuilder: (BuildContext context, GoRouterState state) => fadeThroughPage(state, const OrdersListScreen()),
          routes: [
            GoRoute(
              path: 'details',
              builder: (BuildContext context, GoRouterState state) => OrderDetailsScreen(order: state.extra as Order),
            ),
          ],
        ),
        GoRoute(
          path: '/tasks',
          pageBuilder: (BuildContext context, GoRouterState state) => fadeThroughPage(state, const TasksScreen()),
        ),
        GoRoute(
          path: '/reports',
          pageBuilder: (BuildContext context, GoRouterState state) => fadeThroughPage(state, const ReportsScreen()),
        ),
        GoRoute(
          path: '/ai',
          pageBuilder: (BuildContext context, GoRouterState state) => fadeThroughPage(state, const AiToolsScreen()),
        ),
        GoRoute(
          path: '/pattern',
          pageBuilder: (BuildContext context, GoRouterState state) => fadeThroughPage(state, const PatternViewerScreen()),
        ),
        GoRoute(
          path: '/profile',
          pageBuilder: (BuildContext context, GoRouterState state) => fadeThroughPage(state, const ProfileScreen()),
          routes: [
            GoRoute(
              path: 'business',
              builder: (BuildContext context, GoRouterState state) => const BusinessProfileScreen(),
            ),
            GoRoute(
              path: 'staff',
              builder: (BuildContext context, GoRouterState state) => const StaffManagementScreen(),
            ),
            GoRoute(
              path: 'templates',
              builder: (BuildContext context, GoRouterState state) => const MeasurementTemplatesScreen(),
            ),
          ],
        ),
      ],
    ),
  ],
);
