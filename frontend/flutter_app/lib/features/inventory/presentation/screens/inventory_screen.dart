import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/network/providers/api_provider.dart';
import '../../../../ui/ui.dart';

/// Fabric inventory for business owners.
/// Fabrics appear automatically (untracked, 0 m) when the AI first recommends
/// them; once the owner sets stock, every new order deducts its estimated meters.
class InventoryScreen extends ConsumerStatefulWidget {
  const InventoryScreen({super.key});

  @override
  ConsumerState<InventoryScreen> createState() => _InventoryScreenState();
}

class _InventoryScreenState extends ConsumerState<InventoryScreen> {
  List<Map<String, dynamic>> _items = [];
  bool _loading = true;
  String? _error;
  String _query = '';

  @override
  void initState() {
    super.initState();
    _load();
  }

  String _err(Object e) {
    if (e is DioException) {
      final d = e.response?.data;
      if (d is Map && d['detail'] != null) return d['detail'].toString();
      return e.message ?? 'Network error';
    }
    return e.toString();
  }

  Future<void> _load() async {
    setState(() {
      _loading = _items.isEmpty;
      _error = null;
    });
    try {
      final resp = await ref.read(apiClientProvider).listInventory();
      if (!mounted) return;
      setState(() {
        _items = List<Map<String, dynamic>>.from((resp.data as List).map((e) => Map<String, dynamic>.from(e)));
        _loading = false;
      });
    } catch (e) {
      if (mounted) {
        setState(() {
          _loading = false;
          _error = _err(e);
        });
      }
    }
  }

  static String fmt(dynamic v) {
    final d = (v as num?)?.toDouble() ?? 0;
    return d.toStringAsFixed(2).replaceFirst(RegExp(r'\.?0+$'), '');
  }

  (Color, String, IconData) _statusStyle(String status) {
    final st = context.status;
    switch (status) {
      case 'out':
        return (st.danger, 'Out of stock', Icons.error_rounded);
      case 'low':
        return (st.warning, 'Low stock', Icons.warning_amber_rounded);
      case 'ok':
        return (st.success, 'In stock', Icons.check_circle_rounded);
      default:
        return (context.colors.onSurfaceVariant, 'Not tracked', Icons.help_outline_rounded);
    }
  }

  // ---------------------------------------------------------------- actions
  Future<void> _addFabric() async {
    final name = TextEditingController();
    final qty = TextEditingController();
    final threshold = TextEditingController(text: '5');
    final ok = await _formSheet(
      title: 'Add fabric',
      fields: [
        _field(name, 'Fabric name', 'e.g. Linen', number: false),
        _field(qty, 'Stock in meters', 'e.g. 25'),
        _field(threshold, 'Warn me when below (meters)', 'e.g. 5'),
      ],
      action: 'Add',
    );
    if (ok != true || name.text.trim().isEmpty) return;
    await _run(() => ref.read(apiClientProvider).createInventoryItem({
          'fabric_name': name.text.trim(),
          'quantity_m': double.tryParse(qty.text) ?? 0,
          'low_stock_threshold_m': double.tryParse(threshold.text) ?? 5,
        }), 'Fabric added');
  }

  Future<void> _restock(Map<String, dynamic> item) async {
    final meters = TextEditingController();
    final note = TextEditingController();
    final ok = await _formSheet(
      title: 'Add stock · ${item['fabric_name']}',
      subtitle: 'Current: ${fmt(item['quantity_m'])} m',
      fields: [
        _field(meters, 'Meters received', 'e.g. 50'),
        _field(note, 'Note (optional)', 'e.g. October delivery', number: false),
      ],
      action: 'Add stock',
    );
    final m = double.tryParse(meters.text);
    if (ok != true || m == null || m <= 0) return;
    await _run(() => ref.read(apiClientProvider).restockInventoryItem(item['id'], m, note: note.text.trim()),
        'Added ${fmt(m)} m of ${item['fabric_name']}');
  }

  Future<void> _edit(Map<String, dynamic> item) async {
    final qty = TextEditingController(text: item['is_tracked'] == true ? fmt(item['quantity_m']) : '');
    final threshold = TextEditingController(text: fmt(item['low_stock_threshold_m']));
    final name = TextEditingController(text: item['fabric_name']);
    final ok = await _formSheet(
      title: 'Edit ${item['fabric_name']}',
      subtitle: 'Setting the stock count starts tracking this fabric.',
      fields: [
        _field(name, 'Fabric name', '', number: false),
        _field(qty, 'Exact stock count (meters)', 'e.g. 18.5'),
        _field(threshold, 'Warn me when below (meters)', 'e.g. 5'),
      ],
      action: 'Save',
    );
    if (ok != true) return;
    final payload = <String, dynamic>{
      if (name.text.trim().isNotEmpty && name.text.trim() != item['fabric_name']) 'fabric_name': name.text.trim(),
      if (double.tryParse(qty.text) != null) 'quantity_m': double.parse(qty.text),
      if (double.tryParse(threshold.text) != null) 'low_stock_threshold_m': double.parse(threshold.text),
    };
    if (payload.isEmpty) return;
    await _run(() => ref.read(apiClientProvider).updateInventoryItem(item['id'], payload), 'Saved');
  }

  Future<void> _addSamples() async {
    final yes = await confirmDialog(
      context,
      title: 'Add sample fabrics?',
      message: 'Adds 18 common fabrics (cotton, linen, poplin, silk…) with starting stock. '
          'Fabrics you already have are not changed.',
      confirmLabel: 'Add',
    );
    if (!yes) return;
    try {
      final r = await ref.read(apiClientProvider).addSampleFabrics();
      final n = (r.data is Map ? r.data['added_count'] : 0) ?? 0;
      if (mounted) {
        showToast(context, n == 0 ? 'All sample fabrics are already in your inventory' : 'Added $n sample fabrics',
            type: ToastType.success);
      }
      await _load();
    } catch (e) {
      if (mounted) showToast(context, _err(e), type: ToastType.error);
    }
  }

  Future<void> _delete(Map<String, dynamic> item) async {
    final yes = await confirmDialog(
      context,
      title: 'Remove ${item['fabric_name']}?',
      message: 'Its stock history will be deleted. It will be re-added (untracked) if the AI recommends it again.',
      confirmLabel: 'Remove',
      destructive: true,
    );
    if (!yes) return;
    await _run(() => ref.read(apiClientProvider).deleteInventoryItem(item['id']), 'Removed');
  }

  Future<void> _run(Future<Response> Function() call, String okMsg) async {
    try {
      await call();
      if (mounted) showToast(context, okMsg, type: ToastType.success);
      await _load();
    } catch (e) {
      if (mounted) showToast(context, _err(e), type: ToastType.error);
    }
  }

  Widget _field(TextEditingController c, String label, String hint, {bool number = true}) {
    return Padding(
      padding: const EdgeInsets.only(bottom: Space.sm),
      child: TextField(
        controller: c,
        keyboardType: number ? const TextInputType.numberWithOptions(decimal: true) : TextInputType.text,
        textCapitalization: number ? TextCapitalization.none : TextCapitalization.words,
        inputFormatters: number ? [FilteringTextInputFormatter.allow(RegExp(r'^\d*\.?\d*'))] : null,
        decoration: InputDecoration(labelText: label, hintText: hint),
      ),
    );
  }

  Future<bool?> _formSheet({required String title, String? subtitle, required List<Widget> fields, required String action}) {
    return showModalBottomSheet<bool>(
      context: context,
      isScrollControlled: true,
      useSafeArea: true,
      showDragHandle: true,
      builder: (ctx) => Padding(
        padding: EdgeInsets.fromLTRB(Space.lg, 0, Space.lg, MediaQuery.of(ctx).viewInsets.bottom + Space.lg),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Text(title, style: ctx.text.titleLarge),
            if (subtitle != null) ...[
              const SizedBox(height: Space.xxs),
              Text(subtitle, style: ctx.text.bodySmall),
            ],
            const SizedBox(height: Space.md),
            ...fields,
            const SizedBox(height: Space.xs),
            TsButton(label: action, onPressed: () => Navigator.pop(ctx, true)),
          ],
        ),
      ),
    );
  }

  Future<void> _showDetails(Map<String, dynamic> item) async {
    final (color, label, icon) = _statusStyle(item['status'] ?? 'untracked');
    List<dynamic> history = [];
    try {
      history = (await ref.read(apiClientProvider).inventoryHistory(item['id'])).data as List;
    } catch (_) {}
    if (!mounted) return;
    await showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      useSafeArea: true,
      showDragHandle: true,
      builder: (ctx) => DraggableScrollableSheet(
        expand: false,
        initialChildSize: 0.7,
        maxChildSize: 0.92,
        builder: (ctx, scroll) => ListView(
          controller: scroll,
          padding: const EdgeInsets.fromLTRB(Space.lg, 0, Space.lg, Space.xl),
          children: [
            Row(
              children: [
                Expanded(child: Text(item['fabric_name'], style: ctx.text.titleLarge)),
                const SizedBox(width: Space.xs),
                StatusPill(label: label, icon: icon, color: color),
              ],
            ),
            const SizedBox(height: Space.xs),
            Text(
              item['is_tracked'] == true
                  ? '${fmt(item['quantity_m'])} m in stock · warning below ${fmt(item['low_stock_threshold_m'])} m'
                  : 'Not tracked yet: orders won\'t deduct stock until you set an amount.',
              style: ctx.text.bodyMedium,
            ),
            const SizedBox(height: Space.md),
            Row(
              children: [
                Expanded(
                  child: TsButton(
                    label: 'Add stock',
                    icon: Icons.add_rounded,
                    onPressed: () {
                      Navigator.pop(ctx);
                      _restock(item);
                    },
                  ),
                ),
                const SizedBox(width: Space.sm),
                Expanded(
                  child: TsButton.secondary(
                    label: 'Edit',
                    icon: Icons.edit_rounded,
                    onPressed: () {
                      Navigator.pop(ctx);
                      _edit(item);
                    },
                  ),
                ),
              ],
            ),
            const SizedBox(height: Space.lg),
            Text('History', style: ctx.text.titleSmall),
            const SizedBox(height: Space.xs),
            if (history.isEmpty) Text('No stock changes yet.', style: ctx.text.bodySmall),
            for (final h in history)
              ListTile(
                contentPadding: EdgeInsets.zero,
                dense: true,
                leading: Icon(
                  (h['change_m'] as num) >= 0 ? Icons.south_west_rounded : Icons.north_east_rounded,
                  color: (h['change_m'] as num) >= 0 ? ctx.status.success : ctx.status.danger,
                ),
                title: Text('${(h['change_m'] as num) >= 0 ? '+' : ''}${fmt(h['change_m'])} m · ${_kind(h['kind'])}'),
                subtitle: Text('${h['note'] ?? ''}${h['note'] != null ? ' · ' : ''}${(h['created_at'] ?? '').toString().split('T').first}'),
                trailing: Text('${fmt(h['balance_after_m'])} m', style: ctx.text.labelLarge),
              ),
            const SizedBox(height: Space.md),
            TsButton.text(
              label: 'Remove fabric',
              icon: Icons.delete_outline_rounded,
              onPressed: () {
                Navigator.pop(ctx);
                _delete(item);
              },
            ),
          ],
        ),
      ),
    );
  }

  String _kind(dynamic k) => switch (k) {
        'RESTOCK' => 'Restock',
        'ORDER' => 'Order',
        'REVERSAL' => 'Order removed',
        'ADJUST' => 'Count corrected',
        _ => k.toString(),
      };

  // ---------------------------------------------------------------- UI
  @override
  Widget build(BuildContext context) {
    final cs = context.colors;
    final filtered = _items
        .where((i) => _query.isEmpty || (i['fabric_name'] as String).toLowerCase().contains(_query.toLowerCase()))
        .toList();
    final low = _items.where((i) => i['status'] == 'low' || i['status'] == 'out').length;
    final tracked = _items.where((i) => i['is_tracked'] == true).length;
    final untracked = _items.length - tracked;

    return Scaffold(
      appBar: AppBar(
        leading: IconButton(
          tooltip: 'Back',
          icon: const Icon(Icons.arrow_back_rounded),
          onPressed: () => context.canPop() ? context.pop() : context.go('/home'),
        ),
        title: const Text('Fabric Inventory'),
        actions: [
          IconButton(
            tooltip: 'Add sample fabrics',
            icon: const Icon(Icons.playlist_add_rounded),
            onPressed: _addSamples,
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: _addFabric,
        icon: const Icon(Icons.add_rounded),
        label: const Text('Add fabric'),
      ),
      body: _loading
          ? const Center(child: ScissorLoader())
          : _error != null
              ? ErrorState(title: 'Couldn\'t load inventory', message: _error, onRetry: _load)
              : RefreshIndicator(
                  onRefresh: _load,
                  child: ListView(
                    padding: EdgeInsets.fromLTRB(context.pagePadding, Space.sm, context.pagePadding, 96),
                    children: [
                      Row(
                        children: [
                          Expanded(child: _stat('Fabrics', '${_items.length}', Icons.inventory_2_outlined, cs.primary)),
                          const SizedBox(width: Space.sm),
                          Expanded(child: _stat('Low / out', '$low', Icons.warning_amber_rounded,
                              low > 0 ? context.status.warning : context.status.success)),
                          const SizedBox(width: Space.sm),
                          Expanded(child: _stat('Not tracked', '$untracked', Icons.help_outline_rounded, cs.onSurfaceVariant)),
                        ],
                      ),
                      if (untracked > 0) ...[
                        const SizedBox(height: Space.sm),
                        Text('New fabrics recommended by the AI appear here as "Not tracked". '
                            'Set their stock to start deducting them from orders.',
                            style: context.text.bodySmall),
                      ],
                      const SizedBox(height: Space.md),
                      TextField(
                        onChanged: (v) => setState(() => _query = v),
                        decoration: const InputDecoration(prefixIcon: Icon(Icons.search_rounded), hintText: 'Search fabrics'),
                      ),
                      const SizedBox(height: Space.md),
                      if (_items.isEmpty)
                        EmptyState(
                          icon: Icons.inventory_2_outlined,
                          title: 'No fabrics yet',
                          message: 'Fabrics are added automatically when the AI recommends them, or add one yourself.',
                          actionLabel: 'Add sample fabrics',
                          actionIcon: Icons.playlist_add_rounded,
                          onAction: _addSamples,
                        ),
                      for (final it in filtered) _itemTile(it),
                    ],
                  ),
                ),
    );
  }

  Widget _stat(String label, String value, IconData icon, Color color) => TsCard(
        shadow: false,
        padding: const EdgeInsets.all(Space.sm),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Icon(icon, color: color, size: 20),
            const SizedBox(height: Space.xxs),
            Text(value, style: context.text.titleLarge),
            Text(label, style: context.text.bodySmall, maxLines: 1, overflow: TextOverflow.ellipsis),
          ],
        ),
      );

  Widget _itemTile(Map<String, dynamic> it) {
    final (color, label, icon) = _statusStyle(it['status'] ?? 'untracked');
    final tracked = it['is_tracked'] == true;
    final qty = (it['quantity_m'] as num?)?.toDouble() ?? 0;
    final threshold = (it['low_stock_threshold_m'] as num?)?.toDouble() ?? 5;
    final double ratio = tracked ? (qty / (threshold * 4).clamp(1, double.infinity)).clamp(0.0, 1.0).toDouble() : 0.0;
    return Padding(
      padding: const EdgeInsets.only(bottom: Space.sm),
      child: TsCard(
        onTap: () => _showDetails(it),
        padding: const EdgeInsets.all(Space.md - 2),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Row(
              children: [
                IconBadge(icon: Icons.texture_rounded, color: color, size: 40),
                const SizedBox(width: Space.sm),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(it['fabric_name'], style: context.text.titleSmall, maxLines: 1, overflow: TextOverflow.ellipsis),
                      Text(tracked ? '${fmt(qty)} m' : 'Tap to set stock',
                          style: context.text.bodyMedium?.copyWith(fontWeight: tracked ? FontWeight.w700 : null)),
                    ],
                  ),
                ),
                StatusPill(label: label, icon: icon, color: color, dense: true),
                IconButton(
                  tooltip: 'Add stock',
                  icon: const Icon(Icons.add_circle_outline_rounded),
                  onPressed: () => _restock(it),
                ),
              ],
            ),
            if (tracked) ...[
              const SizedBox(height: Space.xs),
              ClipRRect(
                borderRadius: Radii.brPill,
                child: LinearProgressIndicator(
                  value: ratio,
                  minHeight: 5,
                  color: color,
                  backgroundColor: context.colors.surfaceContainerHighest,
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }
}
