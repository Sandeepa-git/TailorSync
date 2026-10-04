import 'package:flutter/material.dart';

import '../../../ui/ui.dart';

part 'garment_blueprints_data.dart';

/// One instruction label on a blueprint image (e.g. "Waist / 4"), stored as
/// fractions of the image size so it scales with any screen width.
class BlueprintLabel {
  final String id;
  final String caption;
  final double left, top, right, bottom;
  final int quarterTurns; // 0 = horizontal, 3 = reads bottom-to-top, 1 = top-to-bottom
  const BlueprintLabel(this.id, this.caption, this.left, this.top, this.right, this.bottom, {this.quarterTurns = 0});
}

class BlueprintPanel {
  final String title;
  final String asset;
  final double aspectRatio; // width / height
  final List<BlueprintLabel> labels;
  const BlueprintPanel(this.title, this.asset, this.aspectRatio, this.labels);
}

/// Blueprints available for a garment (null = none for this garment type).
List<BlueprintPanel>? blueprintsForGarment(String? garment) {
  final g = (garment ?? '').toLowerCase();
  if (g.contains('trouser')) {
    return g.contains('short') ? _shortTrouserPanels : _longTrouserPanels;
  }
  if (g.contains('shirt')) return _shirtPanels;
  return null;
}

/// Canonical measurements (inches) pulled from whatever names the order uses
/// (template fields, ML keys like `round_end`, or AI names like "Around Knee").
class GarmentMeasurements {
  final bool longSleeve;
  final Map<String, double> _v;
  GarmentMeasurements._(this._v, this.longSleeve);

  static const _aliases = <String, List<String>>{
    // shared
    'height': ['height', 'shirtlength', 'trouserlength', 'length', 'outseam'],
    // trousers
    'waist': ['waist'],
    'seat': ['seat', 'hip', 'hips'],
    'htk': ['heighttillknee', 'heighttoknee', 'kneeheight'],
    'knee': ['aroundknee', 'roundknee', 'knee', 'kneeround'],
    'end': ['roundend', 'legopening', 'longtrouserlegopening', 'shorttrouserlegopening', 'trouserlegopening', 'bottom', 'hem'],
    'crotch': ['crotch', 'rise'],
    // shirts
    'shoulder': ['shoulder', 'shoulderlength', 'shoulderwidth'],
    'chest': ['chest', 'bust'],
    'collar': ['collarsize', 'collar', 'neck'],
    'sleeveopen': ['sleeveopen', 'sleeveopening', 'cuff'],
    'longsleeve': ['longsleevelength'],
    'shortsleeve': ['shortsleevelength'],
    'sleeve': ['sleevelength', 'sleeve'],
  };

  factory GarmentMeasurements.from(Map<String, String> raw, {required String garment}) {
    final norm = <String, double>{};
    raw.forEach((k, v) {
      final key = k.toLowerCase().replaceAll(RegExp(r'[^a-z]'), '');
      final val = double.tryParse(v.trim());
      if (val != null && val > 0) norm[key] = val;
    });
    final out = <String, double>{};
    _aliases.forEach((canon, names) {
      for (final a in names) {
        if (norm.containsKey(a)) {
          out[canon] = norm[a]!;
          break;
        }
      }
    });
    final g = garment.toLowerCase();
    return GarmentMeasurements._(out, g.contains('long') && g.contains('shirt'));
  }

  double? _g(String k) => _v[k];
  double? _f(String k, double Function(double) fn) => _v[k] == null ? null : fn(_v[k]!);

  /// Cutting value for a blueprint label id (null = needed measurement missing).
  double? valueFor(String id) {
    switch (id) {
      // trousers
      case 'waist':
        return _g('waist');
      case 'waist4':
        return _f('waist', (x) => x / 4);
      case 'waist4p3':
        return _f('waist', (x) => x / 4 + 3);
      case 'seat':
        return _g('seat');
      case 'seat4':
        return _f('seat', (x) => x / 4);
      case 'seat4p25':
        return _f('seat', (x) => x / 4 + 2.5);
      case 'height':
        return _g('height');
      case 'h175':
        return _f('height', (x) => x + 1.75);
      case 'htk15':
        final h = _g('htk') ?? _g('height');
        return h == null ? null : h + 1.5;
      case 'knee':
        return _g('knee');
      case 'end2':
        return _f('end', (x) => x / 2);
      case 'crotch':
        return _g('crotch');
      case 'fork':
        final h = _g('height'), c = _g('crotch');
        return (h == null || c == null) ? null : h - c;
      // shirts
      case 'shoulder':
        return _g('shoulder');
      case 'chest4p2':
        return _f('chest', (x) => x / 4 + 2);
      case 'chestp05':
        return _f('chest', (x) => x + 0.5);
      case 'chest2':
        return _f('chest', (x) => x / 2);
      case 'c15':
        return 1.5; // "One and a half inch" button-stand allowance
      case 'sleevelen':
        return (longSleeve ? _g('longsleeve') : _g('shortsleeve')) ?? _g('sleeve');
      case 'sleeveopen':
        return _g('sleeveopen');
      case 'collar':
        return _g('collar');
    }
    return null;
  }
}

/// 8.5 -> 8.5", 8.333 -> 8.25" (tailors work in quarter inches).
String formatInches(double v) {
  final q = (v * 4).round() / 4;
  var s = q.toStringAsFixed(2);
  s = s.replaceFirst(RegExp(r'\.?0+$'), '');
  return '$s"';
}

/// Blueprint image with the formula labels covered by boxes showing the real
/// cutting measurements for this order.
class BlueprintView extends StatelessWidget {
  final BlueprintPanel panel;
  final GarmentMeasurements measurements;
  const BlueprintView({super.key, required this.panel, required this.measurements});

  @override
  Widget build(BuildContext context) {
    return AspectRatio(
      aspectRatio: panel.aspectRatio,
      child: LayoutBuilder(builder: (context, c) {
        final w = c.maxWidth, h = c.maxHeight;
        return Stack(
          children: [
            Positioned.fill(child: Image.asset(panel.asset, fit: BoxFit.fill)),
            for (final l in panel.labels)
              Positioned(
                left: l.left * w,
                top: l.top * h,
                width: (l.right - l.left) * w,
                height: (l.bottom - l.top) * h,
                child: _ValueBox(label: l, value: measurements.valueFor(l.id)),
              ),
          ],
        );
      }),
    );
  }
}

class _ValueBox extends StatelessWidget {
  final BlueprintLabel label;
  final double? value;
  const _ValueBox({required this.label, required this.value});

  @override
  Widget build(BuildContext context) {
    final isBlank = label.caption.isEmpty;
    final missing = !isBlank && value == null;
    final bg = isBlank ? const Color(0xFFFDFDFB) : (missing ? const Color(0xFFFFEBEE) : const Color(0xFFFFF4CC));
    final border = isBlank ? Colors.transparent : (missing ? const Color(0xFFD32F2F) : const Color(0xFFB7791F));

    final box = Container(
        decoration: BoxDecoration(
          color: bg,
          border: Border.all(color: border, width: 1.2),
          borderRadius: BorderRadius.circular(3),
        ),
        padding: const EdgeInsets.all(1.5),
        child: isBlank
            ? null
            : RotatedBox(
                quarterTurns: label.quarterTurns,
                child: FittedBox(
                  fit: BoxFit.contain,
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(label.caption,
                          style: const TextStyle(fontSize: 9, color: Color(0xFF6B4E16), fontWeight: FontWeight.w600)),
                      Text(
                        value != null ? formatInches(value!) : '—',
                        style: TextStyle(
                          fontSize: 20,
                          fontWeight: FontWeight.w800,
                          color: missing ? const Color(0xFFD32F2F) : const Color(0xFF1A237E),
                          height: 1.05,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
    );
    if (isBlank) return box;
    return Tooltip(
      message: '${label.caption}${value != null ? ' = ${formatInches(value!)}' : ' (measurement missing)'}',
      child: box,
    );
  }
}

/// Full-screen, zoomable view of one blueprint panel.
void showBlueprintFullScreen(BuildContext context, BlueprintPanel panel, GarmentMeasurements m, String garment) {
  Navigator.of(context).push(MaterialPageRoute(
    fullscreenDialog: true,
    builder: (ctx) => Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(title: Text('$garment · ${panel.title}')),
      body: SafeArea(
        child: InteractiveViewer(
          minScale: 1,
          maxScale: 6,
          child: Center(child: BlueprintView(panel: panel, measurements: m)),
        ),
      ),
    ),
  ));
}

/// The "Cutting blueprint" section for the order summary.
class GarmentBlueprintSection extends StatelessWidget {
  final String garment;
  final Map<String, String> measurements;
  const GarmentBlueprintSection({super.key, required this.garment, required this.measurements});

  @override
  Widget build(BuildContext context) {
    final cs = context.colors;
    final panels = blueprintsForGarment(garment);
    if (panels == null) {
      return TsCard(
        shadow: false,
        child: Row(
          children: [
            Icon(Icons.architecture_rounded, color: cs.onSurfaceVariant),
            const SizedBox(width: Space.sm),
            Expanded(
              child: Text('Cutting blueprints are available for long/short sleeve shirts and long/short trousers.',
                  style: context.text.bodySmall),
            ),
          ],
        ),
      );
    }
    final m = GarmentMeasurements.from(measurements, garment: garment);
    final anyMissing = panels.any((p) => p.labels.any((l) => l.caption.isNotEmpty && m.valueFor(l.id) == null));

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Text('Values are calculated from this order\'s measurements (inches, rounded to ¼"). Tap a panel to zoom.',
            style: context.text.bodySmall),
        if (anyMissing) ...[
          const SizedBox(height: Space.xxs),
          Text('Red boxes need a measurement that is missing from this order.',
              style: context.text.bodySmall?.copyWith(color: context.status.danger)),
        ],
        const SizedBox(height: Space.sm),
        for (final p in panels) ...[
          TsCard(
            padding: const EdgeInsets.all(Space.sm),
            onTap: () => showBlueprintFullScreen(context, p, m, garment),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Row(
                  children: [
                    Expanded(child: Text(p.title, style: context.text.titleSmall)),
                    Icon(Icons.zoom_out_map_rounded, size: 18, color: cs.onSurfaceVariant),
                  ],
                ),
                const SizedBox(height: Space.xs),
                ClipRRect(
                  borderRadius: Radii.brSm,
                  child: BlueprintView(panel: p, measurements: m),
                ),
              ],
            ),
          ),
          const SizedBox(height: Space.sm),
        ],
      ],
    );
  }
}
