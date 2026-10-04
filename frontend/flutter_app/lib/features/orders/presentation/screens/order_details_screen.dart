import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../../models/order.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:share_plus/share_plus.dart';

import '../../../../ui/ui.dart';

class OrderDetailsScreen extends ConsumerWidget {
  final Order order;
  const OrderDetailsScreen({super.key, required this.order});

  void _share() {
    final String orderId = '#ORD-${order.id.toString().padLeft(4, '0')}';
    final String customer = order.customerName ?? 'N/A';
    final String garment = order.garmentType ?? 'N/A';
    final String status = order.status ?? 'N/A';
    final String dueDate = order.dueDate != null ? order.dueDate!.toString().split('T')[0] : 'N/A';

    final String shareText = 'TailorSync Order Details\n\n'
        'Order ID: $orderId\n'
        'Customer: $customer\n'
        'Garment: $garment\n'
        'Status: $status\n'
        'Due Date: $dueDate\n\n'
        'Track your order with TailorSync!';

    Share.share(shareText, subject: 'Order $orderId Details');
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final cs = context.colors;
    final pad = context.pagePadding;
    final statusColor = StageStyle.color(context, order.status);
    final stageIdx = StageStyle.stages.indexOf(order.status ?? '');
    final headerH = context.isShort ? 200.0 : 236.0;

    return Scaffold(
      body: CustomScrollView(
        physics: const BouncingScrollPhysics(parent: AlwaysScrollableScrollPhysics()),
        slivers: [
          SliverAppBar(
            pinned: true,
            stretch: true,
            expandedHeight: headerH,
            backgroundColor: cs.primary,
            foregroundColor: Colors.white,
            leading: IconButton(
              tooltip: 'Back',
              icon: const Icon(Icons.arrow_back_rounded),
              onPressed: () => context.pop(),
            ),
            actions: [
              IconButton(tooltip: 'Share', icon: const Icon(Icons.ios_share_rounded), onPressed: _share),
              SizedBox(width: pad - Space.xs),
            ],
            title: Text('Order #${order.id}', style: context.text.titleMedium?.copyWith(color: Colors.white)),
            flexibleSpace: FlexibleSpaceBar(
              stretchModes: const [StretchMode.zoomBackground, StretchMode.fadeTitle],
              collapseMode: CollapseMode.parallax,
              background: DecoratedBox(
                decoration: BoxDecoration(gradient: Gradients.hero(cs)),
                child: Stack(
                  children: [
                    Positioned(
                      right: -30,
                      top: 30,
                      child: Icon(StageStyle.icon(order.status), size: 180, color: Colors.white.withValues(alpha: 0.06)),
                    ),
                    Positioned(
                      left: pad,
                      right: pad,
                      bottom: Space.lg,
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          StatusPill(
                            label: order.status ?? 'Pending',
                            icon: StageStyle.icon(order.status),
                            color: Colors.white,
                            background: Colors.white.withValues(alpha: 0.18),
                          ),
                          const SizedBox(height: Space.sm),
                          Text(
                            order.garmentType,
                            style: context.text.headlineMedium?.copyWith(color: Colors.white),
                            maxLines: 2,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
          SliverPadding(
            padding: EdgeInsets.fromLTRB(pad, Space.md, pad, 0),
            sliver: SliverToBoxAdapter(
              child: MaxWidthBox(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    EntranceFade(
                      child: TsCard(
                        child: Column(
                          children: [
                            _DetailRow(icon: Icons.person_outline_rounded, label: 'Customer', value: order.customerName ?? 'Customer #${order.customerId}'),
                            const _RowDivider(),
                            _DetailRow(icon: Icons.event_rounded, label: 'Due Date', value: order.dueDate != null ? order.dueDate!.split('T')[0] : 'Not Set'),
                            const _RowDivider(),
                            _DetailRow(
                              icon: Icons.flag_outlined,
                              label: 'Priority',
                              value: order.priority ?? 'Normal',
                              valueColor: StageStyle.priorityColor(context, order.priority),
                            ),
                            if (order.predictionMethod != null) ...[
                              const _RowDivider(),
                              _DetailRow(
                                icon: Icons.auto_awesome_rounded,
                                label: 'Prediction',
                                value: order.predictionMethod == 'FOUNDRY' ? 'AI Foundry' : 'Custom Machine Learning Model',
                              ),
                            ],
                          ],
                        ),
                      ),
                    ),
                    if (stageIdx >= 0) ...[
                      const SectionHeader(title: 'Progress'),
                      EntranceFade(
                        delay: Motion.staggerStep,
                        child: TsCard(child: _StageTimeline(current: stageIdx, color: statusColor)),
                      ),
                    ],

                    if (order.customerInstructions != null && order.customerInstructions!.isNotEmpty) ...[
                      const SectionHeader(title: 'Instructions'),
                      EntranceFade(
                        delay: Motion.staggerStep * 2,
                        child: TsCard(
                          child: Row(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Icon(Icons.format_quote_rounded, color: cs.primary),
                              const SizedBox(width: Space.sm),
                              Expanded(child: Text(order.customerInstructions!, style: context.text.bodyLarge)),
                            ],
                          ),
                        ),
                      ),
                    ],

                    if (order.measurements != null && order.measurements!.isNotEmpty) ...[
                      const SectionHeader(title: 'Measurements'),
                      GridView.builder(
                        shrinkWrap: true,
                        padding: EdgeInsets.zero,
                        physics: const NeverScrollableScrollPhysics(),
                        gridDelegate: adaptiveGrid(maxTileWidth: 200, mainAxisExtent: 76, spacing: context.gridGap),
                        itemCount: order.measurements!.length,
                        itemBuilder: (context, i) {
                          final m = order.measurements![i];
                          return EntranceFade.indexed(
                            i,
                            child: TsCard(
                              shadow: false,
                              padding: const EdgeInsets.symmetric(horizontal: Space.md, vertical: Space.sm),
                              color: cs.surfaceContainerLow,
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  Text(
                                    m['field_name'] ?? 'Unknown',
                                    style: context.text.labelSmall?.copyWith(color: cs.onSurfaceVariant),
                                    maxLines: 1,
                                    overflow: TextOverflow.ellipsis,
                                  ),
                                  const SizedBox(height: 2),
                                  Text(
                                    '${m['value']} ${m['unit'] ?? 'in'}',
                                    style: context.text.titleMedium,
                                    maxLines: 1,
                                    overflow: TextOverflow.ellipsis,
                                  ),
                                ],
                              ),
                            ),
                          );
                        },
                      ),
                    ],
                    const SizedBox(height: Space.lg),
                    TsButton(
                      label: 'Share Order Details',
                      icon: Icons.ios_share_rounded,
                      onPressed: _share,
                    ),
                  ],
                ),
              ),
            ),
          ),
          SliverToBoxAdapter(child: SizedBox(height: MediaQuery.paddingOf(context).bottom + Space.xxl)),
        ],
      ),
    );
  }
}

class _RowDivider extends StatelessWidget {
  const _RowDivider();
  @override
  Widget build(BuildContext context) => const Padding(
        padding: EdgeInsets.symmetric(vertical: Space.xs),
        child: Divider(),
      );
}

class _DetailRow extends StatelessWidget {
  final IconData icon;
  final String label;
  final String value;
  final Color? valueColor;
  const _DetailRow({required this.icon, required this.label, required this.value, this.valueColor});

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        IconBadge(icon: icon, size: 36),
        const SizedBox(width: Space.sm),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(label, style: context.text.labelSmall?.copyWith(color: context.colors.onSurfaceVariant)),
              Text(
                value,
                style: context.text.titleSmall?.copyWith(color: valueColor),
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
              ),
            ],
          ),
        ),
      ],
    );
  }
}

/// Horizontal stepper showing the order's current stage.
class _StageTimeline extends StatelessWidget {
  final int current;
  final Color color;
  const _StageTimeline({required this.current, required this.color});

  @override
  Widget build(BuildContext context) {
    final cs = context.colors;
    const stages = StageStyle.stages;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Row(
          children: [
            Expanded(child: Text(stages[current], style: context.text.titleSmall?.copyWith(color: color))),
            Text('${current + 1} of ${stages.length}', style: context.text.labelMedium?.copyWith(color: cs.onSurfaceVariant)),
          ],
        ),
        const SizedBox(height: Space.sm),
        Row(
          children: [
            for (var i = 0; i < stages.length; i++) ...[
              Expanded(
                child: Tooltip(
                  message: stages[i],
                  child: TweenAnimationBuilder<double>(
                    tween: Tween(begin: 0, end: i <= current ? 1 : 0),
                    duration: Motion.of(context, Duration(milliseconds: 300 + i * 80)),
                    curve: Motion.emphasizedDecelerate,
                    builder: (context, v, _) => Container(
                      height: 8,
                      decoration: BoxDecoration(
                        borderRadius: Radii.brPill,
                        color: Color.lerp(cs.surfaceContainerHighest, color, v),
                      ),
                    ),
                  ),
                ),
              ),
              if (i < stages.length - 1) const SizedBox(width: 4),
            ],
          ],
        ),
        const SizedBox(height: Space.sm),
        Row(
          children: [
            Icon(StageStyle.icon(stages.first), size: 16, color: cs.onSurfaceVariant),
            const Spacer(),
            Icon(StageStyle.icon(stages.last), size: 16, color: cs.onSurfaceVariant),
          ],
        ),
      ],
    );
  }
}
