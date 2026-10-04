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
import '../features/virtual_tryon/presentation/screens/virtual_tryon_screen.dart';
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


    // Virtual Try-On (full screen, outside shell)
    GoRoute(
      path: '/tryon',
      parentNavigatorKey: _rootNavigatorKey,
      pageBuilder: (BuildContext context, GoRouterState state) => sharedAxisVerticalPage(state, const VirtualTryOnScreen()),
    ),

    // Main app with bottom nav
    StatefulShellRoute.indexedStack(
      builder: (BuildContext context, GoRouterState state, StatefulNavigationShell navigationShell) {
        return MainLayout(navigationShell: navigationShell);
      },
      branches: <StatefulShellBranch>[
        StatefulShellBranch(
          routes: [
            GoRoute(
              path: '/home',
              pageBuilder: (BuildContext context, GoRouterState state) => fadeThroughPage(state, const DashboardScreen()),
            ),
          ],
        ),
        StatefulShellBranch(
          routes: [
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
          ],
        ),
        StatefulShellBranch(
          routes: [
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
          ],
        ),
        StatefulShellBranch(
          routes: [
            GoRoute(
              path: '/tasks',
              pageBuilder: (BuildContext context, GoRouterState state) => fadeThroughPage(state, const TasksScreen()),
            ),
          ],
        ),
        StatefulShellBranch(
          routes: [
            GoRoute(
              path: '/reports',
              pageBuilder: (BuildContext context, GoRouterState state) => fadeThroughPage(state, const ReportsScreen()),
            ),
          ],
        ),
        StatefulShellBranch(
          routes: [
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
        // Hidden branches for tools
        StatefulShellBranch(
          routes: [
            GoRoute(
              path: '/ai',
              pageBuilder: (BuildContext context, GoRouterState state) => fadeThroughPage(state, const AiToolsScreen()),
            ),
          ],
        ),
        StatefulShellBranch(
          routes: [
            GoRoute(
              path: '/pattern',
              pageBuilder: (BuildContext context, GoRouterState state) => fadeThroughPage(state, const PatternViewerScreen()),
            ),
          ],
        ),
      ],
    ),
  ],
);
