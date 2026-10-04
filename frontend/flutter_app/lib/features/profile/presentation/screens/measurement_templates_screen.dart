import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../../core/network/providers/api_provider.dart';
import '../../../../core/widgets/skeleton_loading.dart';
import '../../../../ui/ui.dart';

class MeasurementTemplatesScreen extends ConsumerStatefulWidget {
  const MeasurementTemplatesScreen({super.key});

  @override
  ConsumerState<MeasurementTemplatesScreen> createState() => _MeasurementTemplatesScreenState();
}

class _MeasurementTemplatesScreenState extends ConsumerState<MeasurementTemplatesScreen> {
  bool _loading = true;
  List<dynamic> _templates = [];
  @override
  void initState() {
    super.initState();
    _loadTemplates();
  }
  Future<void> _loadTemplates() async {
    try {
      final api = ref.read(apiClientProvider);
      final resp = await api.getMeasurementTemplates();
      if (mounted) {
        setState(() {
          _templates = resp.data;
          _loading = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() => _loading = false);
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Failed to load templates')),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final cs = context.colors;
    return TsScrollPage(
      title: 'Measurement Templates',
      leading: IconButton(
        tooltip: 'Back',
        icon: const Icon(Icons.arrow_back_rounded),
        onPressed: () => context.pop(),
      ),
      floatingActionButton: FloatingActionButton(
        heroTag: 'fab-templates',
        tooltip: 'Add template',
        onPressed: () {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Custom templates coming soon!')),
          );
        },
        child: const Icon(Icons.add_rounded),
      ),
      slivers: [
        if (_loading)
          const SliverToBoxAdapter(child: Shimmer(child: Column(children: [
            SkeletonContainer(height: 120, borderRadius: Radii.lg),
            SizedBox(height: Space.sm),
            SkeletonContainer(height: 120, borderRadius: Radii.lg),
            SizedBox(height: Space.sm),
            SkeletonContainer(height: 120, borderRadius: Radii.lg),
          ])))
        else if (_templates.isEmpty)
          const SliverFillRemaining(
            hasScrollBody: false,
            child: EmptyState(icon: Icons.straighten_rounded, title: 'No templates found.'),
          )
        else
          SliverList.separated(
            itemCount: _templates.length,
            separatorBuilder: (_, __) => SizedBox(height: context.gridGap),
            itemBuilder: (context, index) {
              final t = _templates[index];
              final fields = t['fields'] as List? ?? [];
              return EntranceFade.indexed(
                index,
                child: _TemplateCard(
                  title: t['category_name'],
                  fields: [for (final f in fields) f['field_name'].toString()],
                  color: cs.primary,
                ),
              );
            },
          ),
      ],
    );
  }
}

/// Expandable template card with field chips.
class _TemplateCard extends StatefulWidget {
  final String title;
  final List<String> fields;
  final Color color;
  const _TemplateCard({required this.title, required this.fields, required this.color});

  @override
  State<_TemplateCard> createState() => _TemplateCardState();
}

class _TemplateCardState extends State<_TemplateCard> {
  bool _open = true;

  @override
  Widget build(BuildContext context) {
    final cs = context.colors;
    return TsCard(
      padding: EdgeInsets.zero,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          InkWell(
            borderRadius: Radii.brLg,
            onTap: () => setState(() => _open = !_open),
            child: Padding(
              padding: const EdgeInsets.fromLTRB(Space.md, Space.sm, Space.xs, Space.sm),
              child: Row(
                children: [
                  IconBadge(icon: Icons.checkroom_rounded, color: widget.color, size: 40),
                  const SizedBox(width: Space.sm),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(widget.title, style: context.text.titleMedium, maxLines: 1, overflow: TextOverflow.ellipsis),
                        Text('${widget.fields.length} measurements', style: context.text.bodySmall),
                      ],
                    ),
                  ),
                  AnimatedRotation(
                    turns: _open ? 0.5 : 0,
                    duration: Motion.of(context, Motion.short),
                    child: const Padding(
                      padding: EdgeInsets.all(Space.sm),
                      child: Icon(Icons.keyboard_arrow_down_rounded),
                    ),
                  ),
                ],
              ),
            ),
          ),
          AnimatedSize(
            duration: Motion.of(context, Motion.medium),
            curve: Motion.emphasized,
            alignment: Alignment.topCenter,
            child: _open
                ? Padding(
                    padding: const EdgeInsets.fromLTRB(Space.md, 0, Space.md, Space.md),
                    child: Wrap(
                      spacing: Space.xs,
                      runSpacing: Space.xs,
                      children: [
                        for (final f in widget.fields)
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                            decoration: BoxDecoration(
                              color: cs.primaryContainer.withValues(alpha: context.isDark ? 0.5 : 0.6),
                              borderRadius: Radii.brPill,
                            ),
                            child: Text(f, style: context.text.labelMedium?.copyWith(color: cs.onPrimaryContainer)),
                          ),
                      ],
                    ),
                  )
                : const SizedBox(width: double.infinity),
          ),
        ],
      ),
    );
  }
}
