import 'package:flutter/material.dart';

import '../theme/app_theme.dart';
import '../theme/motion.dart';
import '../theme/tokens.dart';

/// Rounded search field with an animated clear button and focus glow.
class TsSearchField extends StatefulWidget {
  final TextEditingController controller;
  final String hint;
  final VoidCallback onClear;
  final ValueChanged<String>? onChanged;

  const TsSearchField({
    super.key,
    required this.controller,
    required this.hint,
    required this.onClear,
    this.onChanged,
  });

  @override
  State<TsSearchField> createState() => _TsSearchFieldState();
}

class _TsSearchFieldState extends State<TsSearchField> {
  final _focus = FocusNode();

  @override
  void initState() {
    super.initState();
    widget.controller.addListener(_rebuild);
    _focus.addListener(_rebuild);
  }

  void _rebuild() {
    if (mounted) setState(() {});
  }

  @override
  void dispose() {
    widget.controller.removeListener(_rebuild);
    _focus.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final cs = context.colors;
    final focused = _focus.hasFocus;
    final hasText = widget.controller.text.isNotEmpty;
    return AnimatedContainer(
      duration: Motion.of(context, Motion.short),
      curve: Motion.standard,
      height: 52,
      decoration: BoxDecoration(
        color: context.isDark ? cs.surfaceContainerHigh : cs.surfaceContainerLowest,
        borderRadius: Radii.brPill,
        border: Border.all(color: focused ? cs.primary : cs.outlineVariant.withValues(alpha: 0.6), width: focused ? 1.6 : 1),
        boxShadow: focused
            ? [BoxShadow(color: cs.primary.withValues(alpha: 0.12), blurRadius: 16, spreadRadius: 1)]
            : Shadows.soft(cs),
      ),
      child: Row(
        children: [
          const SizedBox(width: Space.md),
          AnimatedSwitcher(
            duration: Motion.of(context, Motion.short),
            child: Icon(
              Icons.search_rounded,
              key: ValueKey(focused),
              size: 22,
              color: focused ? cs.primary : cs.onSurfaceVariant,
            ),
          ),
          const SizedBox(width: Space.xs),
          Expanded(
            child: TextField(
              controller: widget.controller,
              focusNode: _focus,
              onChanged: widget.onChanged,
              textInputAction: TextInputAction.search,
              style: context.text.bodyLarge,
              decoration: InputDecoration(
                hintText: widget.hint,
                filled: false,
                isDense: true,
                border: InputBorder.none,
                enabledBorder: InputBorder.none,
                focusedBorder: InputBorder.none,
                contentPadding: EdgeInsets.zero,
              ),
            ),
          ),
          AnimatedScale(
            scale: hasText ? 1 : 0,
            duration: Motion.of(context, Motion.short),
            curve: Motion.spring,
            child: IconButton(
              tooltip: 'Clear search',
              icon: const Icon(Icons.close_rounded, size: 20),
              onPressed: hasText ? widget.onClear : null,
            ),
          ),
          const SizedBox(width: Space.xxs),
        ],
      ),
    );
  }
}

/// Horizontally scrolling animated filter chips.
class FilterChipsRow extends StatelessWidget {
  final List<String> options;
  final String selected;
  final ValueChanged<String> onSelected;
  final EdgeInsetsGeometry padding;
  final String Function(String)? labelOf;

  const FilterChipsRow({
    super.key,
    required this.options,
    required this.selected,
    required this.onSelected,
    this.padding = EdgeInsets.zero,
    this.labelOf,
  });

  @override
  Widget build(BuildContext context) {
    final cs = context.colors;
    return SizedBox(
      height: 48,
      child: ListView.separated(
        scrollDirection: Axis.horizontal,
        padding: padding,
        itemCount: options.length,
        separatorBuilder: (_, __) => const SizedBox(width: Space.xs),
        itemBuilder: (context, i) {
          final f = options[i];
          final isSel = f == selected;
          return Center(
            child: AnimatedContainer(
              duration: Motion.of(context, Motion.short),
              curve: Motion.standard,
              decoration: BoxDecoration(
                color: isSel ? cs.primary : (context.isDark ? cs.surfaceContainerHigh : cs.surfaceContainerLowest),
                borderRadius: Radii.brPill,
                border: Border.all(color: isSel ? cs.primary : cs.outlineVariant.withValues(alpha: 0.7)),
                boxShadow: isSel ? [BoxShadow(color: cs.primary.withValues(alpha: 0.25), blurRadius: 10, offset: const Offset(0, 4))] : null,
              ),
              child: Material(
                type: MaterialType.transparency,
                child: InkWell(
                  borderRadius: Radii.brPill,
                  onTap: () => onSelected(f),
                  child: ConstrainedBox(
                    constraints: const BoxConstraints(minHeight: 40),
                    child: Padding(
                      padding: const EdgeInsets.symmetric(horizontal: Space.md, vertical: Space.xs),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          AnimatedSize(
                            duration: Motion.of(context, Motion.short),
                            child: isSel
                                ? Padding(
                                    padding: const EdgeInsets.only(right: 4),
                                    child: Icon(Icons.check_rounded, size: 16, color: cs.onPrimary),
                                  )
                                : const SizedBox.shrink(),
                          ),
                          Text(
                            labelOf?.call(f) ?? f,
                            style: context.text.labelMedium?.copyWith(
                              color: isSel ? cs.onPrimary : cs.onSurfaceVariant,
                              fontWeight: isSel ? FontWeight.w700 : FontWeight.w500,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              ),
            ),
          );
        },
      ),
    );
  }
}
