import 'dart:ui';

import 'package:flutter/material.dart';

import '../theme/app_theme.dart';
import '../theme/responsive.dart';
import '../theme/tokens.dart';

/// Standard scrolling page: collapsing large title that shrinks into a
/// frosted app bar, pull-to-refresh, responsive gutters, a centred max
/// width on wide screens, and bottom space that clears the floating nav.
class TsScrollPage extends StatelessWidget {
  final String title;
  final String? subtitle;
  final List<Widget>? actions;
  final Widget? leading;
  final bool automaticallyImplyLeading;
  final List<Widget> slivers;
  final Future<void> Function()? onRefresh;
  final ScrollController? controller;
  final Widget? floatingActionButton;
  final Widget? headerBottom; // e.g. search field / tabs pinned under title
  final double headerBottomHeight;
  final double maxWidth;
  final bool padSlivers;

  const TsScrollPage({
    super.key,
    required this.title,
    required this.slivers,
    this.subtitle,
    this.actions,
    this.leading,
    this.automaticallyImplyLeading = true,
    this.onRefresh,
    this.controller,
    this.floatingActionButton,
    this.headerBottom,
    this.headerBottomHeight = 64,
    this.maxWidth = MaxWidth.content,
    this.padSlivers = true,
  });

  @override
  Widget build(BuildContext context) {
    final cs = context.colors;
    final pad = context.pagePadding;
    final bottomInset = MediaQuery.paddingOf(context).bottom;

    final appBar = SliverAppBar(
      pinned: true,
      floating: true,
      leading: leading,
      automaticallyImplyLeading: automaticallyImplyLeading,
      title: Text(
        title,
        maxLines: 1,
        overflow: TextOverflow.ellipsis,
        style: context.text.titleLarge?.copyWith(
          color: cs.onSurface,
          fontWeight: FontWeight.bold,
        ),
      ),
      actions: [...?actions, SizedBox(width: pad - Space.xs)],
      backgroundColor: cs.surface.withValues(alpha: 0.86),
      surfaceTintColor: Colors.transparent,
      flexibleSpace: ClipRect(
        child: BackdropFilter(
          filter: ImageFilter.blur(sigmaX: 16, sigmaY: 16),
          child: const SizedBox.expand(),
        ),
      ),
      bottom: headerBottom == null
          ? null
          : PreferredSize(
              preferredSize: Size.fromHeight(headerBottomHeight),
              child: Padding(
                padding: EdgeInsets.fromLTRB(pad, 0, pad, Space.xs),
                child: headerBottom,
              ),
            ),
    );

    final body = <Widget>[
      appBar,
      if (subtitle != null)
        SliverPadding(
          padding: EdgeInsets.fromLTRB(pad, 0, pad, Space.xs),
          sliver: SliverToBoxAdapter(
            child: Text(subtitle!, style: context.text.bodyMedium),
          ),
        ),
      for (final s in slivers) padSlivers ? SliverPadding(padding: EdgeInsets.symmetric(horizontal: pad), sliver: s) : s,
      SliverToBoxAdapter(child: SizedBox(height: bottomInset + Space.xxl + Space.lg)),
    ];

    Widget scroll = CustomScrollView(
      controller: controller,
      physics: const AlwaysScrollableScrollPhysics(parent: BouncingScrollPhysics()),
      slivers: body,
    );
    if (onRefresh != null) {
      scroll = RefreshIndicator(
        onRefresh: onRefresh!,
        edgeOffset: 120,
        displacement: 32,
        color: cs.primary,
        backgroundColor: cs.surfaceContainerHighest,
        child: scroll,
      );
    }

    return Scaffold(
      backgroundColor: cs.surface,
      floatingActionButton: floatingActionButton,
      body: MaxWidthBox(maxWidth: maxWidth, child: scroll),
    );
  }
}

/// Simple non-sliver page body: scrolls, keyboard-safe, max width, gutters,
/// tap outside to dismiss the keyboard.
class TsFormBody extends StatelessWidget {
  final List<Widget> children;
  final double maxWidth;
  final EdgeInsetsGeometry? padding;
  final CrossAxisAlignment crossAxisAlignment;

  const TsFormBody({
    super.key,
    required this.children,
    this.maxWidth = MaxWidth.form,
    this.padding,
    this.crossAxisAlignment = CrossAxisAlignment.stretch,
  });

  @override
  Widget build(BuildContext context) {
    final pad = context.pagePadding;
    return GestureDetector(
      behavior: HitTestBehavior.translucent,
      onTap: () => FocusScope.of(context).unfocus(),
      child: SingleChildScrollView(
        keyboardDismissBehavior: ScrollViewKeyboardDismissBehavior.onDrag,
        padding: padding ??
            EdgeInsets.fromLTRB(pad, Space.md, pad, MediaQuery.paddingOf(context).bottom + Space.xxl),
        child: MaxWidthBox(
          maxWidth: maxWidth,
          child: Column(crossAxisAlignment: crossAxisAlignment, children: children),
        ),
      ),
    );
  }
}
