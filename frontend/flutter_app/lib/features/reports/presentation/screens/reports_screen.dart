import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import '../../../../core/network/providers/api_provider.dart';
import '../../../../core/widgets/skeleton_loading.dart';
import '../../../../ui/ui.dart';

class ReportsScreen extends ConsumerStatefulWidget {
  const ReportsScreen({super.key});

  @override
  ConsumerState<ReportsScreen> createState() => _ReportsScreenState();
}

class _ReportsScreenState extends ConsumerState<ReportsScreen> {
  String _selectedPeriod = 'All Time';
  bool _loading = true;
  
  Map<String, dynamic>? _dashboardData;
  List<dynamic> _staffPerformance = [];
  List<dynamic> _allOrders = []; // To preserve existing status breakdown

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  String _getFromDate() {
    final now = DateTime.now();
    if (_selectedPeriod == 'Today') {
      return DateFormat('yyyy-MM-dd').format(now);
    } else if (_selectedPeriod == 'This Week') {
      return DateFormat('yyyy-MM-dd').format(now.subtract(const Duration(days: 7)));
    } else if (_selectedPeriod == 'This Month') {
      return DateFormat('yyyy-MM-dd').format(DateTime(now.year, now.month, 1));
    }
    return 'all'; // All Time
  }

  String? _getToDate() {
    if (_selectedPeriod == 'All Time') return null;
    return DateFormat('yyyy-MM-dd').format(DateTime.now());
  }

  Future<void> _loadData() async {
    try {
      setState(() => _loading = true);
      final api = ref.read(apiClientProvider);
      
      final fromDate = _getFromDate();
      final toDate = _getToDate();

      final dashResp = await api.getDashboard(fromDate: fromDate, toDate: toDate);
      final staffResp = await api.getStaffPerformance(fromDate: fromDate, toDate: toDate);
      final ordersResp = await api.listOrders(); // Fallback for local order status calculations
      
      if (mounted) {
        setState(() {
          if (dashResp.data['items'] != null && dashResp.data['items'].isNotEmpty) {
            _dashboardData = dashResp.data['items'][0]['metrics'];
          }
          if (staffResp.data['items'] != null && staffResp.data['items'].isNotEmpty) {
            _staffPerformance = staffResp.data['items'][0]['metrics']['staff_performance'] ?? [];
          }
          _allOrders = ordersResp.data;
          _loading = false;
        });
      }
    } catch (e) {
      if (mounted) setState(() => _loading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_loading) {
      return TsScrollPage(
        title: 'Reports',
        automaticallyImplyLeading: false,
        padSlivers: false,
        slivers: const [SliverToBoxAdapter(child: DashboardSkeleton())],
      );
    }

    final cs = context.colors;
    final st = context.status;
    
    // Overall metrics from dashboard
    final overall = _dashboardData?['overall'] ?? {};
    final totalOrders = overall['total_orders'] ?? 0;
    final activeOrders = overall['active_orders'] ?? 0;
    final completedOrders = overall['orders_completed'] ?? 0;
    final ordersDelayed = overall['orders_delayed'] ?? 0;

    final kpis = [
      _Kpi(Icons.shopping_bag_rounded, 'Total Orders', totalOrders, cs.tertiary),
      _Kpi(Icons.pending_actions_rounded, 'Ongoing Orders', activeOrders, st.warning),
      _Kpi(Icons.check_circle_rounded, 'Completed', completedOrders, st.success),
      _Kpi(Icons.warning_rounded, 'Delayed Orders', ordersDelayed, cs.error),
    ];

    // Local order status calculations for 'Order Insights' based on the selected date range
    int sewingCount = 0;
    int cuttingCount = 0;
    int readyCount = 0;
    int otherCount = 0;
    
    final fromDateStr = _getFromDate();
    final fromDate = DateTime.tryParse(fromDateStr) ?? DateTime.now();

    for (var o in _allOrders) {
      if (o['created_at'] != null) {
        final createdAt = DateTime.tryParse(o['created_at'].toString());
        if (createdAt != null && createdAt.isBefore(fromDate)) {
          continue; // Filter orders by selected period
        }
      }
      final status = o['status'] ?? 'Other';
      if (status == 'Sewing') sewingCount++;
      else if (status == 'Cutting') cuttingCount++;
      else if (status == 'Ready') readyCount++;
      else otherCount++;
    }

    final totalForStatus = sewingCount + cuttingCount + readyCount + otherCount;
    final sewingPct = totalForStatus > 0 ? ((sewingCount / totalForStatus) * 100).round() : 0;
    final cuttingPct = totalForStatus > 0 ? ((cuttingCount / totalForStatus) * 100).round() : 0;
    final readyPct = totalForStatus > 0 ? ((readyCount / totalForStatus) * 100).round() : 0;
    final otherPct = totalForStatus > 0 ? ((otherCount / totalForStatus) * 100).round() : 0;

    final slices = [
      _Slice('Sewing', sewingCount, sewingPct, cs.primary),
      _Slice('Cutting', cuttingCount, cuttingPct, st.warning),
      _Slice('Other', otherCount, otherPct, cs.tertiary),
      _Slice('Ready', readyCount, readyPct, st.success),
    ];

    // Garments and Customers
    final garmentPerformance = (_dashboardData?['garment_performance'] as List?) ?? [];
    final customerAnalytics = (_dashboardData?['customer_analytics'] as List?) ?? [];

    return TsScrollPage(
      title: 'Reports & Analytics',
      automaticallyImplyLeading: false,
      onRefresh: _loadData,
      slivers: [
        SliverToBoxAdapter(
          child: Padding(
            padding: const EdgeInsets.only(bottom: Space.md),
            child: _PeriodTabs(
              options: const ['All Time', 'This Month', 'This Week', 'Today'],
              selected: _selectedPeriod,
              onSelected: (p) {
                HapticFeedback.selectionClick();
                setState(() {
                  _selectedPeriod = p;
                  _loadData();
                });
              },
            ),
          ),
        ),
        
        // 1. OVERVIEW
        const SliverToBoxAdapter(child: SectionHeader(title: 'Overview')),
        SliverGrid.builder(
          gridDelegate: adaptiveGrid(
            maxTileWidth: context.isWide ? 200 : 240,
            mainAxisExtent: context.isSmallPhone ? 104 : 112,
            spacing: context.gridGap,
          ),
          itemCount: kpis.length,
          itemBuilder: (context, i) => EntranceFade.indexed(i, child: _KpiCard(kpi: kpis[i])),
        ),

        // 2. ORDER PERFORMANCE
        const SliverToBoxAdapter(child: SizedBox(height: Space.md)),
        const SliverToBoxAdapter(child: SectionHeader(title: 'Order Performance')),
        SliverToBoxAdapter(
          child: EntranceFade(
            delay: Motion.stagger(4),
            child: TsCard(
              padding: EdgeInsets.all(context.isSmallPhone ? Space.md : Space.lg),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Text('Status breakdown', style: context.text.labelMedium?.copyWith(color: cs.onSurfaceVariant)),
                  const SizedBox(height: Space.md),
                  LayoutBuilder(
                    builder: (context, c) {
                      final donut = (c.maxWidth * 0.42).clamp(110.0, 170.0);
                      final legend = Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          for (final s in slices)
                            Padding(
                              padding: const EdgeInsets.symmetric(vertical: 4),
                              child: _LegendItem(color: s.color, label: '${s.label} (${s.pct}%)'),
                            ),
                        ],
                      );
                      final chart = SizedBox.square(
                        dimension: donut,
                        child: _Donut(
                          slices: slices,
                          total: totalForStatus,
                          center: Column(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              AnimatedCount(value: totalForStatus, style: context.text.headlineSmall),
                              Text('orders', style: context.text.labelSmall?.copyWith(color: cs.onSurfaceVariant)),
                            ],
                          ),
                        ),
                      );
                      if (c.maxWidth < 300) {
                        return Column(children: [chart, const SizedBox(height: Space.md), legend]);
                      }
                      return Row(
                        children: [
                          chart,
                          const SizedBox(width: Space.lg),
                          Expanded(child: legend),
                        ],
                      );
                    },
                  ),
                ],
              ),
            ),
          ),
        ),

        // 3. FABRIC USAGE
        const SliverToBoxAdapter(child: SizedBox(height: Space.md)),
        const SliverToBoxAdapter(child: SectionHeader(title: 'Fabric Usage')),
        SliverToBoxAdapter(
          child: EntranceFade(
            delay: Motion.stagger(5),
            child: TsCard(
              padding: EdgeInsets.all(context.isSmallPhone ? Space.md : Space.lg),
              child: (_dashboardData?['fabric_usage'] as List?)?.isEmpty ?? true
                  ? Padding(
                      padding: const EdgeInsets.symmetric(vertical: Space.md),
                      child: Column(
                        children: [
                          Icon(Icons.inventory_2_outlined, size: 36, color: cs.onSurfaceVariant),
                          const SizedBox(height: Space.xs),
                          Text('No fabric usage data available for this period', style: context.text.bodyMedium),
                        ],
                      ),
                    )
                  : Column(
                      children: ((_dashboardData?['fabric_usage'] as List?) ?? []).map((f) {
                        return _InsightRow(
                          label: f['fabric_name']?.toString() ?? 'Unknown',
                          value: (f['quantity'] as num).toInt(),
                          color: cs.secondary,
                        );
                      }).toList(),
                    ),
            ),
          ),
        ),

        // 4. GARMENT PERFORMANCE
        const SliverToBoxAdapter(child: SizedBox(height: Space.md)),
        const SliverToBoxAdapter(child: SectionHeader(title: 'Garment Performance')),
        SliverToBoxAdapter(
          child: EntranceFade(
            delay: Motion.stagger(6),
            child: TsCard(
              padding: EdgeInsets.all(context.isSmallPhone ? Space.md : Space.lg),
              child: garmentPerformance.isEmpty
                  ? Padding(
                      padding: const EdgeInsets.symmetric(vertical: Space.md),
                      child: Column(
                        children: [
                          Icon(Icons.checkroom_rounded, size: 36, color: cs.onSurfaceVariant),
                          const SizedBox(height: Space.xs),
                          Text('No garment data available', style: context.text.bodyMedium),
                        ],
                      ),
                    )
                  : Column(
                      children: garmentPerformance.map((g) {
                        return _InsightRow(
                          label: g['garment_type'] ?? 'Unknown',
                          value: g['count'] ?? 0,
                          color: cs.primary,
                        );
                      }).toList(),
                    ),
            ),
          ),
        ),

        // 5. STAFF PERFORMANCE
        const SliverToBoxAdapter(child: SizedBox(height: Space.md)),
        const SliverToBoxAdapter(child: SectionHeader(title: 'Staff Performance')),
        SliverToBoxAdapter(
          child: EntranceFade(
            delay: Motion.stagger(7),
            child: TsCard(
              padding: EdgeInsets.all(context.isSmallPhone ? Space.md : Space.lg),
              child: _staffPerformance.isEmpty
                  ? Padding(
                      padding: const EdgeInsets.symmetric(vertical: Space.md),
                      child: Column(
                        children: [
                          Icon(Icons.groups_rounded, size: 36, color: cs.onSurfaceVariant),
                          const SizedBox(height: Space.xs),
                          Text('No staff performance data (or unauthorized)', style: context.text.bodyMedium),
                        ],
                      ),
                    )
                  : Column(
                      children: [
                        ..._staffPerformance.map((s) {
                          final name = s['staff_name']?.toString() ?? 'Staff';
                          final completed = s['tasks_completed'] ?? 0;
                          final rate = s['on_time_completion_rate'] ?? 0.0;

                          return Padding(
                            padding: const EdgeInsets.symmetric(vertical: Space.xs),
                            child: _StaffPerformanceRow(
                              name: name,
                              completed: completed,
                              onTimeRate: (rate as num).toDouble(),
                            ),
                          );
                        }),
                      ],
                    ),
            ),
          ),
        ),

        // 6. CUSTOMER ANALYTICS
        const SliverToBoxAdapter(child: SizedBox(height: Space.md)),
        const SliverToBoxAdapter(child: SectionHeader(title: 'Customer Analytics (Top 5)')),
        SliverToBoxAdapter(
          child: EntranceFade(
            delay: Motion.stagger(8),
            child: TsCard(
              padding: EdgeInsets.all(context.isSmallPhone ? Space.md : Space.lg),
              child: customerAnalytics.isEmpty
                  ? Padding(
                      padding: const EdgeInsets.symmetric(vertical: Space.md),
                      child: Column(
                        children: [
                          Icon(Icons.person_outline_rounded, size: 36, color: cs.onSurfaceVariant),
                          const SizedBox(height: Space.xs),
                          Text('No customer data available', style: context.text.bodyMedium),
                        ],
                      ),
                    )
                  : Column(
                      children: customerAnalytics.map((c) {
                        return _InsightRow(
                          label: c['customer_name'] ?? 'Unknown',
                          value: c['count'] ?? 0,
                          color: cs.tertiary,
                        );
                      }).toList(),
                    ),
            ),
          ),
        ),
        
        const SliverToBoxAdapter(child: SizedBox(height: Space.xl)),
      ],
    );
  }
}

class _Slice {
  final String label;
  final int count;
  final int pct;
  final Color color;
  _Slice(this.label, this.count, this.pct, this.color);
}

class _Kpi {
  final IconData icon;
  final String title;
  final num value;
  final Color color;
  _Kpi(this.icon, this.title, this.value, this.color);
}

class _PeriodTabs extends StatelessWidget {
  final List<String> options;
  final String selected;
  final ValueChanged<String> onSelected;
  const _PeriodTabs({required this.options, required this.selected, required this.onSelected});

  @override
  Widget build(BuildContext context) {
    final cs = context.colors;
    final idx = options.indexOf(selected).clamp(0, options.length - 1);
    return Container(
      height: 48,
      padding: const EdgeInsets.all(4),
      decoration: BoxDecoration(color: cs.surfaceContainerHigh, borderRadius: Radii.brPill),
      child: LayoutBuilder(
        builder: (context, c) {
          final w = c.maxWidth / options.length;
          return Stack(
            children: [
              AnimatedPositioned(
                duration: Motion.of(context, Motion.medium),
                curve: Motion.emphasized,
                left: w * idx,
                top: 0,
                bottom: 0,
                width: w,
                child: DecoratedBox(
                  decoration: BoxDecoration(color: cs.primary, borderRadius: Radii.brPill, boxShadow: Shadows.raised(cs)),
                ),
              ),
              Row(
                children: [
                  for (final p in options)
                    Expanded(
                      child: Semantics(
                        button: true,
                        selected: p == selected,
                        child: InkWell(
                          borderRadius: Radii.brPill,
                          onTap: () => onSelected(p),
                          child: Center(
                            child: AnimatedDefaultTextStyle(
                              duration: Motion.of(context, Motion.short),
                              style: (context.text.labelLarge ?? const TextStyle()).copyWith(
                                color: p == selected ? cs.onPrimary : cs.onSurfaceVariant,
                              ),
                              child: Text(p, maxLines: 1, overflow: TextOverflow.ellipsis),
                            ),
                          ),
                        ),
                      ),
                    ),
                ],
              ),
            ],
          );
        },
      ),
    );
  }
}

class _KpiCard extends StatelessWidget {
  final _Kpi kpi;
  const _KpiCard({required this.kpi});

  @override
  Widget build(BuildContext context) {
    return Semantics(
      label: '${kpi.title}: ${kpi.value}',
      excludeSemantics: true,
      child: TsCard(
        padding: const EdgeInsets.all(Space.md - 2),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            IconBadge(icon: kpi.icon, color: kpi.color, size: 34),
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                FittedBox(
                  fit: BoxFit.scaleDown,
                  alignment: Alignment.centerLeft,
                  child: AnimatedCount(value: kpi.value, style: context.text.headlineSmall),
                ),
                Text(kpi.title, style: context.text.bodySmall, maxLines: 1, overflow: TextOverflow.ellipsis),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

class _Donut extends StatelessWidget {
  final List<_Slice> slices;
  final int total;
  final Widget center;
  const _Donut({required this.slices, required this.total, required this.center});

  @override
  Widget build(BuildContext context) {
    final track = context.colors.surfaceContainerHighest;
    return Semantics(
      label: slices.map((s) => '${s.label} ${s.pct} percent').join(', '),
      excludeSemantics: true,
      child: TweenAnimationBuilder<double>(
        tween: Tween(begin: 0, end: 1),
        duration: Motion.of(context, const Duration(milliseconds: 900)),
        curve: Motion.emphasizedDecelerate,
        builder: (context, t, child) => CustomPaint(
          painter: _DonutPainter(slices: slices, total: total, t: t, track: track),
          child: Center(child: child),
        ),
        child: center,
      ),
    );
  }
}

class _DonutPainter extends CustomPainter {
  final List<_Slice> slices;
  final int total;
  final double t;
  final Color track;
  _DonutPainter({required this.slices, required this.total, required this.t, required this.track});

  @override
  void paint(Canvas canvas, Size size) {
    final stroke = size.width * 0.13;
    final rect = Rect.fromLTWH(stroke / 2, stroke / 2, size.width - stroke, size.height - stroke);
    final p = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = stroke
      ..strokeCap = StrokeCap.butt;
    canvas.drawArc(rect, 0, math.pi * 2, false, p..color = track);
    if (total == 0) return;
    var start = -math.pi / 2;
    const gap = 0.04;
    final visible = slices.where((s) => s.count > 0).length;
    for (final s in slices) {
      if (s.count == 0) continue;
      final sweep = (s.count / total) * math.pi * 2 * t;
      final g = visible > 1 ? gap : 0.0;
      if (sweep > g) {
        canvas.drawArc(rect, start + g / 2, sweep - g, false, p..color = s.color);
      }
      start += sweep;
    }
  }

  @override
  bool shouldRepaint(covariant _DonutPainter old) => old.t != t || old.total != total || old.track != track;
}

class _LegendItem extends StatelessWidget {
  final Color color;
  final String label;
  const _LegendItem({required this.color, required this.label});

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(width: 10, height: 10, decoration: BoxDecoration(color: color, borderRadius: BorderRadius.circular(3))),
        const SizedBox(width: Space.xs),
        Flexible(child: Text(label, style: context.text.bodySmall?.copyWith(color: context.colors.onSurface))),
      ],
    );
  }
}

class _InsightRow extends StatelessWidget {
  final String label;
  final int value;
  final Color color;
  const _InsightRow({required this.label, required this.value, required this.color});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: Space.sm),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: Space.md, vertical: Space.sm),
        decoration: BoxDecoration(
          color: color.withValues(alpha: context.isDark ? 0.16 : 0.08),
          borderRadius: Radii.brMd,
        ),
        child: Row(
          children: [
            Expanded(child: Text(label, style: context.text.bodyMedium?.copyWith(color: context.colors.onSurface))),
            AnimatedCount(value: value, style: context.text.titleMedium?.copyWith(color: color)),
          ],
        ),
      ),
    );
  }
}

class _StaffPerformanceRow extends StatelessWidget {
  final String name;
  final int completed;
  final double onTimeRate;

  const _StaffPerformanceRow({required this.name, required this.completed, required this.onTimeRate});

  @override
  Widget build(BuildContext context) {
    final cs = context.colors;
    return Row(
      children: [
        InitialsAvatar(name: name, size: 42),
        const SizedBox(width: Space.sm),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(name, style: context.text.titleSmall, maxLines: 1, overflow: TextOverflow.ellipsis),
              const SizedBox(height: 6),
              Row(
                children: [
                  Icon(Icons.timer_outlined, size: 12, color: cs.onSurfaceVariant),
                  const SizedBox(width: 4),
                  Text('${onTimeRate.toStringAsFixed(0)}% On-Time', style: context.text.labelSmall?.copyWith(color: cs.onSurfaceVariant)),
                ],
              ),
            ],
          ),
        ),
        const SizedBox(width: Space.md),
        Column(
          crossAxisAlignment: CrossAxisAlignment.end,
          children: [
            AnimatedCount(value: completed, style: context.text.titleMedium),
            Text('completed', style: context.text.labelSmall?.copyWith(color: cs.onSurfaceVariant)),
          ],
        ),
      ],
    );
  }
}
