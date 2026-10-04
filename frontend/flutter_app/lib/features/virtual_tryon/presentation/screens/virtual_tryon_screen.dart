import 'dart:convert';
import 'dart:io';
import 'dart:typed_data';

import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:image_picker/image_picker.dart' show CameraDevice, ImagePicker, ImageSource;
import 'package:path_provider/path_provider.dart';
import 'package:share_plus/share_plus.dart' show SharePlus, ShareParams, XFile;

import '../../../../core/network/providers/api_provider.dart';
import '../../../../ui/ui.dart';

/// Virtual Try-On: take a customer photo, describe a dress, and let the AI
/// (Cloudflare Workers AI · FLUX.2 klein, via our backend) re-dress them.
class VirtualTryOnScreen extends ConsumerStatefulWidget {
  const VirtualTryOnScreen({super.key});

  @override
  ConsumerState<VirtualTryOnScreen> createState() => _VirtualTryOnScreenState();
}

class _ColorOption {
  final String name;
  final Color swatch;
  const _ColorOption(this.name, this.swatch);
}

const _garments = [
  // Sri Lankan traditional & occasion wear
  'Saree',
  'Kandyan saree (Osariya)',
  'Bridal saree',
  'Half saree',
  'Lama saree',
  'Redda and hatte',
  'Kandyan bridal (Nilame)',
  'National dress',
  'Sarong and shirt',
  'Batik sarong',
  'Batik dress',
  'Long frock',
  'Frock',
  // South Asian
  'Lehenga',
  'Kurta',
  'Kurta pyjama',
  'Shalwar kameez',
  'Churidar',
  'Anarkali',
  // Western, office & everyday
  'Evening gown',
  'Office blouse and skirt',
  'Blouse and skirt',
  'Business suit',
  'Shirt and trousers',
  'Linen shirt',
  'School uniform',
];

/// What the image model is actually told for local garment names.
const _garmentPrompts = {
  'Kandyan saree (Osariya)':
      'Kandyan saree (osariya), Sri Lankan style saree with a frilled peplum at the waist and the pallu draped over the left shoulder',
  'Bridal saree': 'Sri Lankan bridal saree with heavy embroidery and a long veil-like pallu',
  'Half saree': 'half saree (langa voni) with a long skirt, blouse and draped dupatta',
  'Lama saree': 'young girl\'s Sri Lankan lama saree, short simple draped saree',
  'Redda and hatte': 'traditional Sri Lankan redda and hatte, wrap cloth skirt with a fitted short-sleeve jacket blouse',
  'Kandyan bridal (Nilame)':
      'traditional Kandyan groom outfit (Nilame attire) with embroidered jacket, wrapped cloth and decorated four-cornered hat',
  'National dress': 'Sri Lankan men\'s national dress, long-sleeve white collarless kurtha top with a white wrapped sarong',
  'Sarong and shirt': 'Sri Lankan sarong with a casual shirt',
  'Batik sarong': 'Sri Lankan hand-dyed batik sarong with a plain shirt',
  'Batik dress': 'Sri Lankan batik print dress',
  'Long frock': 'long ankle-length frock',
  'Kurta pyjama': 'kurta with matching pyjama trousers',
  'Churidar': 'churidar suit with fitted leggings and long top with dupatta',
  'Anarkali': 'flared floor-length anarkali dress with dupatta',
  'Office blouse and skirt': 'smart office blouse with a knee-length pencil skirt',
  'School uniform': 'Sri Lankan school uniform, white frock with a tie for girls or white shirt and shorts for boys',
};

const _colors = [
  _ColorOption('White', Color(0xFFF7F5F0)),
  _ColorOption('Cream', Color(0xFFF1E6C8)),
  _ColorOption('Gold', Color(0xFFD4A537)),
  _ColorOption('Mustard', Color(0xFFD9A21B)),
  _ColorOption('Orange', Color(0xFFE8711C)),
  _ColorOption('Peach', Color(0xFFF4A98A)),
  _ColorOption('Red', Color(0xFFC62828)),
  _ColorOption('Maroon', Color(0xFF6D1B2B)),
  _ColorOption('Pink', Color(0xFFEC6FA0)),
  _ColorOption('Magenta', Color(0xFFB0186F)),
  _ColorOption('Lavender', Color(0xFFB39DDB)),
  _ColorOption('Purple', Color(0xFF6A3BA8)),
  _ColorOption('Royal blue', Color(0xFF1E4DD8)),
  _ColorOption('Sky blue', Color(0xFF6EC1F0)),
  _ColorOption('Navy', Color(0xFF1A2550)),
  _ColorOption('Teal', Color(0xFF0F7C80)),
  _ColorOption('Emerald green', Color(0xFF0E8A5F)),
  _ColorOption('Olive', Color(0xFF7A7A2E)),
  _ColorOption('Brown', Color(0xFF6B4226)),
  _ColorOption('Grey', Color(0xFF8A8F98)),
  _ColorOption('Black', Color(0xFF151515)),
];

const _fabrics = [
  'Silk', 'Cotton', 'Linen', 'Batik', 'Handloom', 'Chiffon', 'Georgette',
  'Satin', 'Organza', 'Brocade', 'Velvet', 'Lace', 'Denim',
];

class _VirtualTryOnScreenState extends ConsumerState<VirtualTryOnScreen> {
  final _picker = ImagePicker();
  final _detailsCtrl = TextEditingController();

  Uint8List? _photo;
  String _photoName = 'photo.jpg';
  String? _garment = 'Saree';
  String? _color = 'Royal blue';
  String? _fabric = 'Silk';
  bool _consent = false;

  bool _generating = false;
  Uint8List? _result;
  bool _showOriginal = false;
  String? _error;

  Map<String, dynamic>? _usage;
  bool _usageLoading = true;

  @override
  void initState() {
    super.initState();
    _loadUsage();
  }

  Future<void> _loadUsage() async {
    setState(() => _usageLoading = true);
    try {
      final resp = await ref.read(apiClientProvider).getTryOnUsage();
      if (mounted) setState(() => _usage = Map<String, dynamic>.from(resp.data as Map));
    } catch (_) {
      // Counter is optional — never block the feature if it fails.
    } finally {
      if (mounted) setState(() => _usageLoading = false);
    }
  }

  int? get _remaining => (_usage?['remaining_generations'] as num?)?.toInt();

  @override
  void dispose() {
    _detailsCtrl.dispose();
    super.dispose();
  }

  String get _description {
    final main = [
      if (_color != null) _color!.toLowerCase(),
      if (_fabric != null) _fabric!.toLowerCase(),
      if (_garment != null) _garmentPrompts[_garment] ?? _garment!.toLowerCase(),
    ].join(' ');
    final details = _detailsCtrl.text.trim();
    if (main.isEmpty) return details;
    final withArticle = 'a $main';
    return details.isEmpty ? withArticle : '$withArticle, $details';
  }

  bool get _canGenerate =>
      _photo != null && _description.isNotEmpty && _consent && !_generating && (_remaining == null || _remaining! > 0);

  Future<void> _pick(ImageSource source) async {
    try {
      final picked = await _picker.pickImage(
        source: source,
        maxWidth: 1280,
        maxHeight: 1280,
        imageQuality: 88,
        preferredCameraDevice: CameraDevice.rear,
      );
      if (picked == null) return;
      final bytes = await picked.readAsBytes();
      setState(() {
        _photo = bytes;
        _photoName = picked.name.isNotEmpty ? picked.name : 'photo.jpg';
        _result = null;
        _error = null;
        _showOriginal = false;
      });
    } catch (e) {
      if (mounted) showToast(context, 'Could not open the image: $e', type: ToastType.error);
    }
  }

  Future<void> _generate() async {
    if (!_canGenerate) return;
    FocusScope.of(context).unfocus();
    setState(() {
      _generating = true;
      _error = null;
    });
    try {
      final api = ref.read(apiClientProvider);
      final resp = await api.virtualTryOn(_photo!, _photoName, _description);
      final data = resp.data as Map;
      final b64 = data['image_base64'] as String;
      if (!mounted) return;
      setState(() {
        _result = base64Decode(b64);
        if (data['usage'] is Map) _usage = Map<String, dynamic>.from(data['usage'] as Map);
        _showOriginal = false;
      });
    } catch (e) {
      String msg = 'Something went wrong. Please try again.';
      if (e is DioException) {
        final data = e.response?.data;
        if (e.response?.statusCode == 404) {
          msg = 'The try-on service is not available on the server yet. Please make sure the latest backend is deployed.';
        } else if (data is Map && data['detail'] != null) {
          msg = data['detail'].toString();
        } else if (e.type == DioExceptionType.receiveTimeout || e.type == DioExceptionType.connectionTimeout) {
          msg = 'The AI took too long to respond. Please try again.';
        } else if (e.response?.statusCode == 429) {
          msg = 'Too many try-ons. Please wait a bit and try again.';
        }
      }
      if (mounted) setState(() => _error = msg);
      _loadUsage();
    } finally {
      if (mounted) setState(() => _generating = false);
    }
  }

  Future<void> _share() async {
    if (_result == null) return;
    try {
      final dir = await getTemporaryDirectory();
      final file = File('${dir.path}/tailorsync_tryon_${DateTime.now().millisecondsSinceEpoch}.png');
      await file.writeAsBytes(_result!);
      await SharePlus.instance.share(ShareParams(files: [XFile(file.path, mimeType: 'image/png')], text: 'Virtual try-on by TailorSync'));
    } catch (e) {
      if (mounted) showToast(context, 'Could not share image: $e', type: ToastType.error);
    }
  }

  @override
  Widget build(BuildContext context) {
    final cs = context.colors;
    return Scaffold(
      appBar: AppBar(
        leading: IconButton(
          tooltip: 'Back',
          icon: const Icon(Icons.arrow_back_rounded),
          onPressed: () {
            if (context.canPop()) {
              context.pop();
            } else {
              context.go('/home');
            }
          },
        ),
        title: const Text('Virtual Try-On'),
        actions: [
          if (_photo != null)
            IconButton(
              tooltip: 'Start over',
              icon: const Icon(Icons.restart_alt_rounded),
              onPressed: _generating
                  ? null
                  : () => setState(() {
                        _photo = null;
                        _result = null;
                        _error = null;
                      }),
            ),
        ],
      ),
      body: TsFormBody(
        children: [
          _IntroBanner(),
          const SizedBox(height: Space.sm),
          _UsageCounter(usage: _usage, loading: _usageLoading, onRefresh: _loadUsage),
          const SectionHeader(title: '1. Customer photo'),
          _buildPhotoArea(cs),
          const SizedBox(height: Space.sm),
          Row(
            children: [
              Expanded(
                child: TsButton.secondary(
                  label: 'Camera',
                  icon: Icons.photo_camera_outlined,
                  onPressed: _generating ? null : () => _pick(ImageSource.camera),
                ),
              ),
              const SizedBox(width: Space.sm),
              Expanded(
                child: TsButton.secondary(
                  label: 'Gallery',
                  icon: Icons.photo_library_outlined,
                  onPressed: _generating ? null : () => _pick(ImageSource.gallery),
                ),
              ),
            ],
          ),
          const SizedBox(height: Space.xs),
          Text('Tip: a well-lit, full-body or half-body photo facing the camera works best.',
              style: context.text.bodySmall),
          const SectionHeader(title: '2. Choose the dress'),
          _label('Garment'),
          _chips(_garments, _garment, (v) => setState(() => _garment = v)),
          const SizedBox(height: Space.md),
          _label('Colour'),
          Wrap(
            spacing: Space.xs,
            runSpacing: Space.xs,
            children: [
              for (final c in _colors)
                ChoiceChip(
                  avatar: CircleAvatar(
                    radius: 9,
                    backgroundColor: c.swatch,
                    child: c.name == 'White'
                        ? DecoratedBox(
                            decoration: BoxDecoration(
                              shape: BoxShape.circle,
                              border: Border.all(color: cs.outlineVariant),
                            ),
                            child: const SizedBox.expand(),
                          )
                        : null,
                  ),
                  label: Text(c.name),
                  selected: _color == c.name,
                  onSelected: (_) => setState(() => _color = _color == c.name ? null : c.name),
                ),
            ],
          ),
          const SizedBox(height: Space.md),
          _label('Fabric'),
          _chips(_fabrics, _fabric, (v) => setState(() => _fabric = v)),
          const SizedBox(height: Space.md),
          _label('Extra details (optional)'),
          TextField(
            controller: _detailsCtrl,
            maxLines: 2,
            minLines: 1,
            textCapitalization: TextCapitalization.sentences,
            onChanged: (_) => setState(() {}),
            decoration: const InputDecoration(
              hintText: 'e.g. gold zari border, puff sleeves, floral embroidery',
            ),
          ),
          const SizedBox(height: Space.sm),
          if (_description.isNotEmpty)
            TsCard(
              shadow: false,
              padding: const EdgeInsets.all(Space.sm),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Icon(Icons.auto_awesome_rounded, size: 18, color: cs.primary),
                  const SizedBox(width: Space.xs),
                  Expanded(
                    child: Text('Dress them in $_description', style: context.text.bodyMedium),
                  ),
                ],
              ),
            ),
          const SizedBox(height: Space.sm),
          CheckboxListTile(
            contentPadding: EdgeInsets.zero,
            controlAffinity: ListTileControlAffinity.leading,
            value: _consent,
            onChanged: _generating ? null : (v) => setState(() => _consent = v ?? false),
            title: Text(
              'The customer agrees to their photo being processed by an AI image service.',
              style: context.text.bodySmall,
            ),
          ),
          const SizedBox(height: Space.sm),
          TsButton(
            label: _result == null ? 'Generate Try-On' : 'Generate Again',
            icon: Icons.auto_awesome_rounded,
            loading: _generating,
            onPressed: _canGenerate ? _generate : null,
          ),
          if (_error != null) ...[
            const SizedBox(height: Space.sm),
            TsCard(
              shadow: false,
              color: context.status.danger.withValues(alpha: 0.08),
              padding: const EdgeInsets.all(Space.sm),
              child: Row(
                children: [
                  Icon(Icons.error_outline_rounded, color: context.status.danger),
                  const SizedBox(width: Space.xs),
                  Expanded(child: Text(_error!, style: context.text.bodyMedium)),
                ],
              ),
            ),
          ],
        ],
      ),
    );
  }

  Widget _label(String text) => Padding(
        padding: const EdgeInsets.only(bottom: Space.xs),
        child: Text(text, style: context.text.titleSmall),
      );

  Widget _chips(List<String> options, String? selected, ValueChanged<String?> onChanged) {
    return Wrap(
      spacing: Space.xs,
      runSpacing: Space.xs,
      children: [
        for (final o in options)
          ChoiceChip(
            label: Text(o),
            selected: selected == o,
            onSelected: (_) => onChanged(selected == o ? null : o),
          ),
      ],
    );
  }

  Widget _buildPhotoArea(ColorScheme cs) {
    final hasResult = _result != null;
    final shown = hasResult && !_showOriginal ? _result : _photo;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        ClipRRect(
          borderRadius: Radii.brLg,
          child: AspectRatio(
            aspectRatio: 3 / 4,
            child: Stack(
              fit: StackFit.expand,
              children: [
                if (shown == null)
                  InkWell(
                    onTap: () => _pick(ImageSource.gallery),
                    child: Container(
                      color: cs.surfaceContainerHighest.withValues(alpha: 0.5),
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(Icons.person_outline_rounded, size: 64, color: cs.onSurfaceVariant),
                          const SizedBox(height: Space.xs),
                          Text('Add a customer photo', style: context.text.titleSmall),
                        ],
                      ),
                    ),
                  )
                else
                  AnimatedSwitcher(
                    duration: Motion.of(context, Motion.medium),
                    child: Image.memory(shown, key: ValueKey(identityHashCode(shown)), fit: BoxFit.cover),
                  ),
                if (_generating)
                  Container(
                    color: Colors.black.withValues(alpha: 0.45),
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        const StitchLoader(color: Colors.white),
                        const SizedBox(height: Space.md),
                        Text('Tailoring the new look…',
                            style: context.text.titleSmall?.copyWith(color: Colors.white)),
                        const SizedBox(height: 2),
                        Text('This usually takes 5–20 seconds',
                            style: context.text.bodySmall?.copyWith(color: Colors.white70)),
                      ],
                    ),
                  ),
                if (hasResult && !_generating)
                  Positioned(
                    left: Space.sm,
                    top: Space.sm,
                    child: StatusPill(
                      label: _showOriginal ? 'Original' : 'AI try-on',
                      icon: _showOriginal ? Icons.person_rounded : Icons.auto_awesome_rounded,
                      color: Colors.white,
                      background: Colors.black.withValues(alpha: 0.55),
                    ),
                  ),
              ],
            ),
          ),
        ),
        if (hasResult && !_generating) ...[
          const SizedBox(height: Space.sm),
          SegmentedButton<bool>(
            segments: const [
              ButtonSegment(value: false, label: Text('Try-on'), icon: Icon(Icons.auto_awesome_rounded)),
              ButtonSegment(value: true, label: Text('Original'), icon: Icon(Icons.person_rounded)),
            ],
            selected: {_showOriginal},
            onSelectionChanged: (s) => setState(() => _showOriginal = s.first),
          ),
          const SizedBox(height: Space.sm),
          TsButton.tonal(label: 'Share Image', icon: Icons.ios_share_rounded, onPressed: _share),
        ],
      ],
    );
  }
}

class _IntroBanner extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    final cs = context.colors;
    return TsCard(
      shadow: false,
      padding: const EdgeInsets.all(Space.md),
      child: Row(
        children: [
          IconBadge(icon: Icons.checkroom_rounded, color: cs.tertiary, size: 44),
          const SizedBox(width: Space.sm),
          Expanded(
            child: Text(
              'Show customers how a design will look on them before you start cutting fabric.',
              style: context.text.bodyMedium,
            ),
          ),
        ],
      ),
    );
  }
}

/// Shows the estimated number of free AI try-ons left today.
class _UsageCounter extends StatelessWidget {
  final Map<String, dynamic>? usage;
  final bool loading;
  final VoidCallback onRefresh;
  const _UsageCounter({required this.usage, required this.loading, required this.onRefresh});

  @override
  Widget build(BuildContext context) {
    final cs = context.colors;
    final st = context.status;

    if (usage == null) {
      if (!loading) return const SizedBox.shrink();
      return const LinearProgressIndicator(minHeight: 2);
    }

    final remaining = (usage!['remaining_generations'] as num?)?.toInt() ?? 0;
    final max = (usage!['max_generations_per_day'] as num?)?.toInt() ?? 1;
    final usedToday = (usage!['generations_today'] as num?)?.toInt() ?? 0;
    final ratio = max <= 0 ? 0.0 : (remaining / max).clamp(0.0, 1.0);
    final color = remaining == 0
        ? st.danger
        : ratio < 0.2
            ? st.warning
            : st.success;

    String resetText = '';
    final resetsAt = DateTime.tryParse(usage!['resets_at']?.toString() ?? '');
    if (resetsAt != null) {
      final diff = resetsAt.difference(DateTime.now().toUtc());
      final h = diff.inHours;
      final m = diff.inMinutes.remainder(60);
      final local = resetsAt.toLocal();
      final hh = local.hour % 12 == 0 ? 12 : local.hour % 12;
      final ampm = local.hour < 12 ? 'AM' : 'PM';
      resetText = 'Resets at $hh:${local.minute.toString().padLeft(2, '0')} $ampm (in ${h}h ${m}m)';
    }

    return TsCard(
      shadow: false,
      padding: const EdgeInsets.all(Space.sm + 2),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
            children: [
              IconBadge(icon: Icons.bolt_rounded, color: color, size: 36),
              const SizedBox(width: Space.sm),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      remaining == 0 ? 'No free try-ons left today' : '~$remaining free try-ons left today',
                      style: context.text.titleSmall,
                    ),
                    Text(
                      '$usedToday used today${resetText.isEmpty ? '' : ' · $resetText'}',
                      style: context.text.bodySmall,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ],
                ),
              ),
              IconButton(
                tooltip: 'Refresh',
                visualDensity: VisualDensity.compact,
                icon: loading
                    ? SizedBox(width: 16, height: 16, child: CircularProgressIndicator(strokeWidth: 2, color: cs.primary))
                    : const Icon(Icons.refresh_rounded, size: 20),
                onPressed: loading ? null : onRefresh,
              ),
            ],
          ),
          const SizedBox(height: Space.xs),
          ClipRRect(
            borderRadius: Radii.brPill,
            child: LinearProgressIndicator(
              value: ratio,
              minHeight: 6,
              color: color,
              backgroundColor: cs.surfaceContainerHighest,
            ),
          ),
        ],
      ),
    );
  }
}
