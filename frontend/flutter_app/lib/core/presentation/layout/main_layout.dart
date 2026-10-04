import 'dart:ui';

import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../network/providers/user_provider.dart';
import '../../../ui/theme/app_theme.dart';
import '../../../ui/theme/motion.dart';
import '../../../ui/theme/responsive.dart';
import '../../../ui/theme/tokens.dart';

class MainLayout extends ConsumerStatefulWidget {
  final StatefulNavigationShell navigationShell;

  const MainLayout({super.key, required this.navigationShell});

  @override
  ConsumerState<MainLayout> createState() => _MainLayoutState();
}

class _MainLayoutState extends ConsumerState<MainLayout> {
  // UI-only: whether the floating nav is visible (hides on scroll down).
  bool _navVisible = true;

  bool _onScroll(UserScrollNotification n) {
    if (n.metrics.axis != Axis.vertical) return false;
    if (n.direction == ScrollDirection.reverse && _navVisible && n.metrics.pixels > 24) {
      setState(() => _navVisible = false);
    } else if (n.direction == ScrollDirection.forward && !_navVisible) {
      setState(() => _navVisible = true);
    }
    return false;
  }

  @override
  Widget build(BuildContext context) {
    final userAsync = ref.watch(userProvider);
    final isActive = userAsync.valueOrNull?['is_active'] ?? true;
    final isStaff = userAsync.valueOrNull?['role'] == 'staff' || userAsync.valueOrNull?['role'] == 'STAFF';

    // The order of branches in app_router.dart:
    // 0: /home, 1: /orders, 2: /customers, 3: /tasks, 4: /reports, 5: /profile, 6: /ai, 7: /pattern
    
    // We map the bottom nav index to the StatefulShellBranch index
    int getBranchIndex(int navIndex) {
      if (isStaff) {
        if (navIndex == 0) return 3; // tasks
        if (navIndex == 1) return 1; // orders
        if (navIndex == 2) return 5; // profile
      } else {
        if (navIndex == 0) return 0; // home
        if (navIndex == 1) return 1; // orders
        if (navIndex == 2) return 2; // customers
        if (navIndex == 3) return 3; // tasks
        if (navIndex == 4) return 4; // reports
      }
      return 0;
    }

    // Determine current nav index based on the active branch
    int currentIndex = 0;
    final int activeBranch = widget.navigationShell.currentIndex;
    if (isStaff) {
      if (activeBranch == 3) currentIndex = 0;
      else if (activeBranch == 1) currentIndex = 1;
      else if (activeBranch == 5) currentIndex = 2;
    } else {
      if (activeBranch == 0) currentIndex = 0;
      else if (activeBranch == 1) currentIndex = 1;
      else if (activeBranch == 2) currentIndex = 2;
      else if (activeBranch == 3) currentIndex = 3;
      else if (activeBranch == 4) currentIndex = 4;
    }

    void onSelectDestination(int navIndex) {
      final targetBranch = getBranchIndex(navIndex);
      widget.navigationShell.goBranch(
        targetBranch,
        initialLocation: targetBranch == widget.navigationShell.currentIndex,
      );
    }

    final destinations = isStaff
        ? const [
            _NavItem(Icons.assignment_outlined, Icons.assignment_rounded, 'Tasks'),
            _NavItem(Icons.shopping_bag_outlined, Icons.shopping_bag_rounded, 'Orders'),
            _NavItem(Icons.person_outline_rounded, Icons.person_rounded, 'Profile'),
          ]
        : const [
            _NavItem(Icons.home_outlined, Icons.home_rounded, 'Home'),
            _NavItem(Icons.shopping_bag_outlined, Icons.shopping_bag_rounded, 'Orders'),
            _NavItem(Icons.people_outline_rounded, Icons.people_rounded, 'Customers'),
            _NavItem(Icons.assignment_outlined, Icons.assignment_rounded, 'Tasks'),
            _NavItem(Icons.bar_chart_outlined, Icons.bar_chart_rounded, 'Reports'),
          ];

    final cs = context.colors;

    return Scaffold(
      extendBody: true,
      backgroundColor: cs.surface,
      body: Column(
        children: [
          AnimatedSize(
            duration: Motion.of(context, Motion.medium),
            curve: Motion.emphasized,
            child: !isActive ? const _InactiveBanner() : const SizedBox(width: double.infinity),
          ),
          Expanded(
            child: MediaQuery.removePadding(
              context: context,
              removeTop: !isActive,
              child: NotificationListener<UserScrollNotification>(
                onNotification: _onScroll,
                child: widget.navigationShell,
              ),
            ),
          ),
        ],
      ),
      bottomNavigationBar: AnimatedSlide(
        offset: _navVisible ? Offset.zero : const Offset(0, 1.4),
        duration: Motion.of(context, Motion.medium),
        curve: Motion.emphasized,
        child: _FloatingNavBar(
          items: destinations,
          currentIndex: currentIndex,
          onSelected: (index) {
            HapticFeedback.selectionClick();
            if (!_navVisible) setState(() => _navVisible = true);
            onSelectDestination(index);
          },
        ),
      ),
    );
  }
}

class _InactiveBanner extends StatelessWidget {
  const _InactiveBanner();

  @override
  Widget build(BuildContext context) {
    final s = context.status;
    return Container(
      width: double.infinity,
      color: s.dangerContainer,
      padding: EdgeInsets.fromLTRB(Space.md, MediaQuery.paddingOf(context).top + Space.xs, Space.md, Space.sm),
      child: Row(
        children: [
          Icon(Icons.lock_clock_rounded, size: 18, color: s.onDangerContainer),
          const SizedBox(width: Space.xs),
          Expanded(
            child: Text(
              'Your account is currently inactive. You can still look around in read-only mode.',
              style: context.text.labelMedium?.copyWith(color: s.onDangerContainer),
            ),
          ),
        ],
      ),
    );
  }
}

class _NavItem {
  final IconData icon;
  final IconData selectedIcon;
  final String label;
  const _NavItem(this.icon, this.selectedIcon, this.label);
}

/// Frosted floating pill nav with a sliding indicator, bouncing selected
/// icon and animated label colour.
class _FloatingNavBar extends StatelessWidget {
  final List<_NavItem> items;
  final int currentIndex;
  final ValueChanged<int> onSelected;

  const _FloatingNavBar({required this.items, required this.currentIndex, required this.onSelected});

  @override
  Widget build(BuildContext context) {
    final cs = context.colors;
    final side = context.responsive<double>(xs: Space.sm, md: Space.md, xl: Space.lg);
    final bottom = MediaQuery.paddingOf(context).bottom;
    const barHeight = 68.0;
    const pillW = 56.0;
    const pillH = 32.0;

    return Padding(
      padding: EdgeInsets.fromLTRB(side, 0, side, (bottom > 0 ? bottom : Space.sm) + Space.xxs),
      // heightFactor: 1 keeps the bar only as tall as itself (otherwise Align
      // fills the whole screen height and pushes SnackBars off screen).
      child: MaxWidthBox(
        maxWidth: 520,
        alignment: Alignment.bottomCenter,
        heightFactor: 1,
        child: DecoratedBox(
          decoration: BoxDecoration(
            borderRadius: Radii.brXl,
            boxShadow: Shadows.raised(cs),
          ),
          child: ClipRRect(
            borderRadius: Radii.brXl,
            child: BackdropFilter(
              filter: ImageFilter.blur(sigmaX: 18, sigmaY: 18),
              child: Container(
                height: barHeight,
                decoration: BoxDecoration(
                  color: (context.isDark ? cs.surfaceContainerHigh : cs.surfaceContainerLowest).withValues(alpha: 0.88),
                  borderRadius: Radii.brXl,
                  border: Border.all(color: cs.outlineVariant.withValues(alpha: 0.35)),
                ),
                child: ClampedTextScale(
                  max: 1.15,
                  child: LayoutBuilder(
                    builder: (context, c) {
                      final itemW = c.maxWidth / items.length;
                      return Stack(
                        children: [
                          AnimatedPositioned(
                            duration: Motion.of(context, Motion.medium),
                            curve: Motion.emphasized,
                            left: itemW * currentIndex + (itemW - pillW) / 2,
                            top: 9,
                            width: pillW,
                            height: pillH,
                            child: DecoratedBox(
                              decoration: BoxDecoration(color: cs.primaryContainer, borderRadius: Radii.brPill),
                            ),
                          ),
                          Row(
                            children: [
                              for (var i = 0; i < items.length; i++)
                                Expanded(
                                  child: _NavButton(
                                    item: items[i],
                                    selected: i == currentIndex,
                                    onTap: () => onSelected(i),
                                  ),
                                ),
                            ],
                          ),
                        ],
                      );
                    },
                  ),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _NavButton extends StatelessWidget {
  final _NavItem item;
  final bool selected;
  final VoidCallback onTap;

  const _NavButton({required this.item, required this.selected, required this.onTap});

  @override
  Widget build(BuildContext context) {
    final cs = context.colors;
    final fg = selected ? cs.onPrimaryContainer : cs.onSurfaceVariant;
    final dur = Motion.of(context, Motion.medium);
    return Semantics(
      selected: selected,
      button: true,
      label: item.label,
      excludeSemantics: true,
      child: InkWell(
        onTap: onTap,
        customBorder: const StadiumBorder(),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            SizedBox(
              height: 32,
              child: AnimatedScale(
                scale: selected ? 1.12 : 1.0,
                duration: dur,
                curve: Motion.spring,
                child: AnimatedSwitcher(
                  duration: Motion.of(context, Motion.short),
                  child: Icon(
                    selected ? item.selectedIcon : item.icon,
                    key: ValueKey(selected),
                    size: 22,
                    color: fg,
                  ),
                ),
              ),
            ),
            const SizedBox(height: 2),
            AnimatedDefaultTextStyle(
              duration: dur,
              style: (context.text.labelSmall ?? const TextStyle()).copyWith(
                color: selected ? cs.primary : cs.onSurfaceVariant,
                fontWeight: selected ? FontWeight.w800 : FontWeight.w500,
                fontSize: 11,
              ),
              child: Text(item.label, maxLines: 1, overflow: TextOverflow.fade, softWrap: false),
            ),
          ],
        ),
      ),
    );
  }
}
