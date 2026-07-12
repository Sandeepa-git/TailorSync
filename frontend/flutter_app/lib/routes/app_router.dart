import 'package:flutter/widgets.dart';
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

final GlobalKey<NavigatorState> _rootNavigatorKey = GlobalKey<NavigatorState>(debugLabel: 'root');
final GlobalKey<NavigatorState> _shellNavigatorKey = GlobalKey<NavigatorState>(debugLabel: 'shell');

final GoRouter appRouter = GoRouter(
  navigatorKey: _rootNavigatorKey,
  initialLocation: '/splash',
  routes: <RouteBase>[
    // Splash & Auth (outside shell)
    GoRoute(
      path: '/splash',
      builder: (BuildContext context, GoRouterState state) => const SplashScreen(),
    ),
    GoRoute(
      path: '/login',
      builder: (BuildContext context, GoRouterState state) => const LoginScreen(),
    ),
    // New Order Wizard (full screen, outside shell)
    GoRoute(
      path: '/orders/new',
      parentNavigatorKey: _rootNavigatorKey,
      builder: (BuildContext context, GoRouterState state) => const NewOrderWizard(),
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
          builder: (BuildContext context, GoRouterState state) => const DashboardScreen(),
        ),
        GoRoute(
          path: '/customers',
          builder: (BuildContext context, GoRouterState state) => const CustomersListScreen(),
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
          builder: (BuildContext context, GoRouterState state) => const OrdersListScreen(),
          routes: [
            GoRoute(
              path: 'details',
              builder: (BuildContext context, GoRouterState state) => OrderDetailsScreen(order: state.extra as Order),
            ),
          ],
        ),
        GoRoute(
          path: '/tasks',
          builder: (BuildContext context, GoRouterState state) => const TasksScreen(),
        ),
        GoRoute(
          path: '/reports',
          builder: (BuildContext context, GoRouterState state) => const ReportsScreen(),
        ),
        GoRoute(
          path: '/ai',
          builder: (BuildContext context, GoRouterState state) => const AiToolsScreen(),
        ),
        GoRoute(
          path: '/pattern',
          builder: (BuildContext context, GoRouterState state) => const PatternViewerScreen(),
        ),
        GoRoute(
          path: '/profile',
          builder: (BuildContext context, GoRouterState state) => const ProfileScreen(),
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
