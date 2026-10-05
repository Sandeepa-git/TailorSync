import 'dart:math' as math;

import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/network/providers/api_provider.dart';
import '../../../../core/widgets/skeleton_loading.dart';
import '../../../../ui/ui.dart';
import '../../../orders/presentation/providers/orders_provider.dart';
import '../widgets/trend_line_chart.dart';

/// Reports & Analytics: orders, delivery quality, fabric use,
/// inventory, staff and customers - all from /reports/overview.
class ReportsScreen extends ConsumerStatefulWidget {
  const ReportsScreen({super.key});

  @override
  ConsumerState<ReportsScreen> createState() => _ReportsScreenState();
}

class _ReportsScreenState extends ConsumerState<ReportsScreen> {
  static const _periods = {'7 Days': 7, '30 Days': 30, '90 Days': 90, 'All Time': 0};
  String _selectedPeriod = '90 Days';
  bool _loading = true;
  String? _error;
  Map<String, dynamic>? _data;


  @override
  void initState() {
    super.initState();
    _loadData();
  }

  Future<void> _loadData() async {
    setState(() {
      _loading = _data == null;
      _error = null;
    });
    try {
      final resp = await ref.read(apiClientProvider).getReportsOverview(_periods[_selectedPeriod]!);
      if (mounted) {
        setState(() {
          _data = Map<String, dynamic>.from(resp.data as Map);
          _loading = false;
        });
      }
    } catch (e) {
      var msg = 'Could not load reports. Pull down to try again.';
      if (e is DioException) {
        final code = e.response?.statusCode;
        final d = e.response?.data;
        if (code == 401 || code == 403) {
          msg = 'Your session has expired. Please sign in again.';
        } else if (d is Map && d['detail'] != null) {
          msg = '${d['detail']}';
        } else if (code != null) {
          msg = 'Server error ($code). Pull down to try again.';
        } else {
          msg = 'Can\'t reach the server. Check your connection.';
        }
      }
      if (mounted) {
        setState(() {
          _loading = false;
          _error = msg;
        });
      }
    }
  }

  // ---------------------------------------------------------------- helpers
  num _n(dynamic v) => (v as num?) ?? 0;
  List<Map<String, dynamic>> _list(String key) =>
      ((_data?[key] as List?) ?? const []).map((e) => Map<String, dynamic>.from(e as Map)).toList();
  String _m(num v) => '${v.toStringAsFixed(1).replaceFirst(RegExp(r'\.0$'), '')} m';

  /// "+12%" vs the previous period of the same length (null when no baseline).
  String? _delta(num now, num prev) {
    if (_selectedPeriod == 'All Time' || prev <= 0) return null;
    final pct = ((now - prev) / prev * 100).round();
    return '${pct >= 0 ? '▲' : '▼'} ${pct.abs()}% vs previous';
  }

  Widget _card(Widget child, {int stagger = 0}) => EntranceFade(
        delay: Motion.stagger(stagger),
        child: TsCard(padding: EdgeInsets.all(context.isSmallPhone ? Space.md : Space.lg), child: child),
      );

  Widget _caption(String t) => Padding(
        padding: const EdgeInsets.only(bottom: Space.sm),
        child: Text(t, style: context.text.labelMedium?.copyWith(color: context.colors.onSurfaceVariant)),
      );

  Widget _emptyNote(IconData icon, String text) => Padding(
        padding: const EdgeInsets.symmetric(vertical: Space.md),
        child: Column(children: [
          Icon(icon, size: 32, color: context.colors.onSurfaceVariant),
          const SizedBox(height: Space.xs),
          Text(text, style: context.text.bodyMedium, textAlign: TextAlign.center),
        ]),
      );

  SliverToBoxAdapter _section(String title) => SliverToBoxAdapter(
        child: Padding(padding: const EdgeInsets.only(top: Space.md), child: SectionHeader(title: title)),
      );

  @override
  Widget build(BuildContext context) {
    // refresh automatically when orders are created/updated anywhere in the app
    ref.listen(refreshTriggerProvider, (prev, next) {
      if (prev != next && mounted) _loadData();
    });

    if (_loading) {
      return TsScrollPage(
        watermark: TailorAccessory.button,
        title: 'Reports',
        automaticallyImplyLeading: false,
        padSlivers: false,
        slivers: const [SliverToBoxAdapter(child: DashboardSkeleton())],
      );
    }

    final cs = context.colors;
    final st = context.status;
    final k = Map<String, dynamic>.from((_data?['kpis'] as Map?) ?? {});
    final trend = _list('trend');
    final labels = trend.map((b) => b['label'].toString()).toList();
    final unit = (_data?['period']?['unit'] ?? 'week').toString();
    final inventory = _data?['inventory'] as Map?;

    // On-time performance: delivered-on-time / (delivered + still-open overdue).
    // The API's on_time_rate only looks at delivered orders, so it showed 100%
    // even while orders were overdue. Count late open orders as misses too.
    final deliveredCount = _n(k['completed']);
    final lateDelivered = _n(k['delayed']);
    final overdueCount = _n(k['overdue']);
    final onTimeBase = deliveredCount + overdueCount;
    final num? onTime = onTimeBase > 0 ? (deliveredCount - lateDelivered) / onTimeBase * 100 : null;
    final turnaround = k['avg_turnaround_days'] as num?;
    final tiles = <_StatTile>[
      _StatTile(Icons.shopping_bag_rounded, 'Orders', '${_n(k['total_orders'])}', cs.primary,
          sub: _delta(_n(k['total_orders']), _n(k['prev_total_orders']))),
      _StatTile(Icons.check_circle_rounded, 'Delivered', '${_n(k['completed'])}', st.success),
      _StatTile(Icons.pending_actions_rounded, 'In progress', '${_n(k['active'])}', st.info),
      _StatTile(Icons.warning_rounded, 'Overdue', '${_n(k['overdue'])}',
          _n(k['overdue']) > 0 ? st.danger : cs.onSurfaceVariant,
          sub: 'past due date, not delivered'),
      _StatTile(Icons.timer_rounded, 'On-time delivery', onTime == null ? '—' : '${onTime.round()}%',
          onTime == null ? cs.onSurfaceVariant : (onTime >= 80 ? st.success : st.warning),
          sub: '${lateDelivered.toInt()} delivered late · ${overdueCount.toInt()} overdue'),
      _StatTile(Icons.hourglass_bottom_rounded, 'Avg turnaround',
          turnaround == null ? '—' : '${turnaround.toStringAsFixed(1)} days', cs.tertiary,
          sub: 'order to delivery'),
      _StatTile(Icons.straighten_rounded, 'Fabric used', '${_n(k['fabric_used_m']).toStringAsFixed(1)} m', cs.secondary,
          sub: 'across orders this period'),
    ];

    final statuses = _list('status_breakdown');
    const statusColors = [kSeriesBlue, kSeriesOrange, kSeriesAqua, Color(0xFFEDA100), Color(0xFFE87BA4),
      Color(0xFF4A3AA7), Color(0xFF008300)];
    final statusTotal = statuses.fold<int>(0, (a, s) => a + _n(s['count']).toInt());
    final slices = [
      for (var i = 0; i < statuses.length; i++)
        _Slice(statuses[i]['status'], _n(statuses[i]['count']).toInt(),
            statusTotal == 0 ? 0 : (_n(statuses[i]['count']) / statusTotal * 100).round(), statusColors[i % 7]),
    ];

    final garments = _list('garments');
    final fabrics = _list('fabrics');
    final staff = _list('staff');
    final customers = _list('customers');
    final methods = Map<String, dynamic>.from((k['prediction_methods'] as Map?) ?? {});
    final methodsTotal = methods.values.fold<num>(0, (a, b) => a + (b as num));

    return TsScrollPage(
        watermark: TailorAccessory.button,
      title: 'Reports & Analytics',
      automaticallyImplyLeading: false,
      onRefresh: _loadData,
      slivers: [
        SliverToBoxAdapter(
          child: _PeriodTabs(
            options: _periods.keys.toList(),
            selected: _selectedPeriod,
            onSelected: (p) {
              HapticFeedback.selectionClick();
              setState(() => _selectedPeriod = p);
              _loadData();
            },
          ),
        ),
        if (_error != null)
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.only(top: Space.md),
              child: ErrorState(title: 'Reports unavailable', message: _error, onRetry: _loadData),
            ),
          ),

        // 1. OVERVIEW
        _section('Overview'),
        SliverGrid.builder(
          gridDelegate: adaptiveGrid(
            maxTileWidth: context.isWide ? 220 : 240,
            mainAxisExtent: context.isSmallPhone ? 112 : 118,
            spacing: context.gridGap,
          ),
          itemCount: tiles.length,
          itemBuilder: (context, i) => EntranceFade.indexed(i, child: _StatCard(tile: tiles[i])),
        ),

        // 2. ORDERS OVER TIME
        _section('Orders Over Time'),
        SliverToBoxAdapter(
          child: _card(
            Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
              _caption('New vs delivered orders per $unit'),
              TrendLineChart(
                labels: labels,
                series: [
                  ChartSeries('New orders', kSeriesBlue, trend.map((b) => _n(b['created']).toDouble()).toList()),
                  ChartSeries('Delivered', kSeriesOrange, trend.map((b) => _n(b['completed']).toDouble()).toList()),
                ],
                format: (v) => v.round().toString(),
              ),
            ]),
            stagger: 2,
          ),
        ),

        // 4. ORDER STATUS
        _section('Order Status'),
        SliverToBoxAdapter(
          child: _card(
            statusTotal == 0
                ? _emptyNote(Icons.donut_large_rounded, 'No orders in this period')
                : Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
                    _caption('Where this period\'s orders are now'),
                    LayoutBuilder(builder: (context, c) {
                      final donut = (c.maxWidth * 0.42).clamp(110.0, 170.0);
                      final legend = Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          for (final s in slices)
                            Padding(
                              padding: const EdgeInsets.symmetric(vertical: 3),
                              child: _LegendItem(color: s.color, label: '${s.label}  ${s.count} (${s.pct}%)'),
                            ),
                        ],
                      );
                      final chart = SizedBox.square(
                        dimension: donut,
                        child: _Donut(
                          slices: slices,
                          total: statusTotal,
                          center: Column(mainAxisSize: MainAxisSize.min, children: [
                            AnimatedCount(value: statusTotal, style: context.text.headlineSmall),
                            Text('orders', style: context.text.labelSmall?.copyWith(color: cs.onSurfaceVariant)),
                          ]),
                        ),
                      );
                      if (c.maxWidth < 300) {
                        return Column(children: [chart, const SizedBox(height: Space.md), legend]);
                      }
                      return Row(children: [chart, const SizedBox(width: Space.lg), Expanded(child: legend)]);
                    }),
                  ]),
            stagger: 4,
          ),
        ),

        // 5. INVENTORY (owners)
        if (inventory != null) ...[
          _section('Fabric Inventory'),
          SliverToBoxAdapter(child: _card(_inventoryPanel(Map<String, dynamic>.from(inventory)), stagger: 5)),
        ],

        // 6. FABRIC USAGE
        _section('Fabric Usage'),
        SliverToBoxAdapter(
          child: _card(
            Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
              _caption('Meters used per $unit · total ${_m(_n(k['fabric_used_m']))}'),
              TrendLineChart(
                labels: labels,
                height: 150,
                fillFirst: true,
                series: [ChartSeries('Fabric used', kSeriesAqua, trend.map((b) => _n(b['fabric_m']).toDouble()).toList())],
                format: (v) => '${v.toStringAsFixed(v < 10 ? 1 : 0)}m',
              ),
              const SizedBox(height: Space.md),
              if (fabrics.isEmpty)
                Text('No fabric recorded on orders yet.', style: context.text.bodySmall)
              else
                for (final f in fabrics.take(6))
                  _BarRow(
                    label: f['fabric_name'],
                    value: _n(f['meters']).toDouble(),
                    max: _n(fabrics.first['meters']).toDouble(),
                    text: '${_m(_n(f['meters']))} · ${f['orders']} orders',
                    color: kSeriesAqua,
                  ),
            ]),
            stagger: 6,
          ),
        ),

        // 7. GARMENTS
        _section('Garment Performance'),
        SliverToBoxAdapter(
          child: _card(
            garments.isEmpty
                ? _emptyNote(Icons.checkroom_rounded, 'No garment data for this period')
                : Column(children: [
                    for (final g in garments)
                      _BarRow(
                        label: g['garment_type'],
                        value: _n(g['count']).toDouble(),
                        max: _n(garments.first['count']).toDouble(),
                        text: '${g['count']} orders',
                        color: kSeriesBlue,
                      ),
                  ]),
            stagger: 7,
          ),
        ),

        // 8. AI USAGE
        if (methodsTotal > 0) ...[
          _section('Measurement Prediction'),
          SliverToBoxAdapter(
            child: _card(
              Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
                _caption('How measurements were predicted for this period\'s orders'),
                for (final e in methods.entries)
                  _BarRow(
                    label: e.key,
                    value: (e.value as num).toDouble(),
                    max: methodsTotal.toDouble(),
                    text: '${e.value} (${((e.value as num) / methodsTotal * 100).round()}%)',
                    color: kSeriesOrange,
                  ),
              ]),
              stagger: 8,
            ),
          ),
        ],

        // 9. STAFF
        _section('Staff Performance'),
        SliverToBoxAdapter(
          child: _card(
            staff.isEmpty
                ? _emptyNote(Icons.groups_rounded, 'No staff assignments yet')
                : Column(children: [
                    for (final s in staff)
                      Padding(
                        padding: const EdgeInsets.symmetric(vertical: Space.xs),
                        child: _StaffPerformanceRow(
                          name: s['staff_name']?.toString() ?? 'Staff',
                          completed: _n(s['tasks_completed']).toInt(),
                          onTimeRate: _n(s['on_time_completion_rate']).toDouble(),
                          active: _n(s['active_tasks']).toInt(),
                          overdue: _n(s['overdue_tasks']).toInt(),
                        ),
                      ),
                  ]),
            stagger: 9,
          ),
        ),

        // 10. CUSTOMERS
        _section('Top Customers'),
        SliverToBoxAdapter(
          child: _card(
            customers.isEmpty
                ? _emptyNote(Icons.person_outline_rounded, 'No customer data for this period')
                : Column(children: [
                    for (final c in customers)
                      _BarRow(
                        label: c['customer_name'] ?? 'Unknown',
                        value: _n(c['count']).toDouble(),
                        max: _n(customers.first['count']).toDouble(),
                        text: '${c['count']} orders',
                        color: cs.tertiary,
                      ),
                  ]),
            stagger: 10,
          ),
        ),
        const SliverToBoxAdapter(child: SizedBox(height: Space.xl)),
      ],
    );
  }

  Widget _inventoryPanel(Map<String, dynamic> inv) {
    final st = context.status;
    final cs = context.colors;
    final items = ((inv['items'] as List?) ?? const []).map((e) => Map<String, dynamic>.from(e as Map)).toList();
    final tracked = items.where((i) => i['is_tracked'] == true).toList();
    Widget mini(String label, String value, Color color) => Expanded(
          child: Container(
            padding: const EdgeInsets.all(Space.sm),
            decoration: BoxDecoration(color: color.withValues(alpha: 0.08), borderRadius: Radii.brMd),
            child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              Text(value, style: context.text.titleMedium),
              Text(label, style: context.text.labelSmall?.copyWith(color: cs.onSurfaceVariant)),
            ]),
          ),
        );
    return Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
      Row(children: [
        mini('In stock', _m(_n(inv['total_stock_m'])), cs.primary),
        const SizedBox(width: Space.xs),
        mini('Low / out', '${_n(inv['low_count'])}', _n(inv['low_count']) > 0 ? st.danger : st.success),
        const SizedBox(width: Space.xs),
        mini('Used (30 days)', _m(_n(inv['used_30d_m'])), kSeriesAqua),
      ]),
      const SizedBox(height: Space.md),
      if (tracked.isEmpty)
        Text('No fabrics are tracked yet. Set stock amounts in Inventory to see levels here.',
            style: context.text.bodySmall)
      else
        for (final it in tracked.take(6)) _inventoryRow(it),
      Align(
        alignment: Alignment.centerRight,
        child: TextButton.icon(
          onPressed: () => context.push('/inventory'),
          icon: const Icon(Icons.inventory_2_outlined, size: 18),
          label: const Text('Open inventory'),
        ),
      ),
    ]);
  }

  Widget _inventoryRow(Map<String, dynamic> it) {
    final st = context.status;
    final status = it['status'];
    final color = status == 'out' ? st.danger : status == 'low' ? st.warning : st.success;
    final label = status == 'out' ? 'Out' : status == 'low' ? 'Low' : 'OK';
    final days = it['days_left'] as num?;
    final qty = _n(it['quantity_m']);
    final threshold = math.max(1.0, _n(it['low_stock_threshold_m']).toDouble());
    return Padding(
      padding: const EdgeInsets.only(bottom: Space.sm),
      child: Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
        Row(children: [
          Expanded(child: Text(it['fabric_name'], style: context.text.bodyMedium)),
          Text(_m(qty), style: context.text.titleSmall),
          const SizedBox(width: Space.xs),
          StatusPill(label: label, color: color, dense: true),
        ]),
        const SizedBox(height: 4),
        Row(children: [
          Expanded(
            child: ClipRRect(
              borderRadius: Radii.brPill,
              child: LinearProgressIndicator(
                value: (qty / (threshold * 4)).clamp(0.0, 1.0).toDouble(),
                minHeight: 5,
                color: color,
                backgroundColor: context.colors.surfaceContainerHighest,
              ),
            ),
          ),
          const SizedBox(width: Space.sm),
          Text(
            days == null ? 'no recent use' : (days <= 0 ? 'out now' : '~${days.round()} days left'),
            style: context.text.labelSmall?.copyWith(
                color: days != null && days <= 14 ? st.danger : context.colors.onSurfaceVariant),
          ),
        ]),
      ]),
    );
  }
}

class _StatTile {
  final IconData icon;
  final String title;
  final String value;
  final Color color;
  final String? sub;
  _StatTile(this.icon, this.title, this.value, this.color, {this.sub});
}

class _StatCard extends StatelessWidget {
  final _StatTile tile;
  const _StatCard({required this.tile});

  @override
  Widget build(BuildContext context) {
    return TsCard(
      padding: const EdgeInsets.all(Space.md - 2),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Row(children: [
            IconBadge(icon: tile.icon, color: tile.color, size: 32),
            const SizedBox(width: Space.xs),
            Expanded(
              child: Text(tile.title,
                  style: context.text.bodySmall, maxLines: 1, overflow: TextOverflow.ellipsis),
            ),
          ]),
          FittedBox(
            fit: BoxFit.scaleDown,
            alignment: Alignment.centerLeft,
            child: Text(tile.value, style: context.text.headlineSmall),
          ),
          if (tile.sub != null)
            Text(tile.sub!,
                style: context.text.labelSmall?.copyWith(color: context.colors.onSurfaceVariant),
                maxLines: 1,
                overflow: TextOverflow.ellipsis),
        ],
      ),
    );
  }
}

/// Label + proportional bar + value text (used for fabrics, garments, customers, AI usage).
class _BarRow extends StatelessWidget {
  final String label;
  final double value;
  final double max;
  final String text;
  final Color color;
  const _BarRow({required this.label, required this.value, required this.max, required this.text, required this.color});

  @override
  Widget build(BuildContext context) {
    final frac = max <= 0 ? 0.0 : (value / max).clamp(0.0, 1.0).toDouble();
    return Padding(
      padding: const EdgeInsets.only(bottom: Space.sm),
      child: Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
        Row(children: [
          Expanded(child: Text(label, style: context.text.bodyMedium, maxLines: 1, overflow: TextOverflow.ellipsis)),
          Text(text, style: context.text.labelMedium?.copyWith(color: context.colors.onSurface)),
        ]),
        const SizedBox(height: 4),
        LayoutBuilder(
          builder: (context, c) => Align(
            alignment: Alignment.centerLeft,
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 500),
              curve: Curves.easeOutCubic,
              height: 8,
              width: math.max(4.0, c.maxWidth * frac),
              decoration: BoxDecoration(color: color, borderRadius: BorderRadius.circular(4)),
            ),
          ),
        ),
      ]),
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

class _StaffPerformanceRow extends StatelessWidget {
  final String name;
  final int completed;
  final double onTimeRate;
  final int active;
  final int overdue;

  const _StaffPerformanceRow({required this.name, required this.completed, required this.onTimeRate, this.active = 0, this.overdue = 0});

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
                  Flexible(
                    child: Text(
                      '${onTimeRate.toStringAsFixed(0)}% on time · $active active${overdue > 0 ? ' · $overdue overdue' : ''}',
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: context.text.labelSmall?.copyWith(color: overdue > 0 ? context.status.danger : cs.onSurfaceVariant),
                    ),
                  ),
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
