import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../core/network/providers/api_provider.dart';
import '../../../../core/widgets/skeleton_loading.dart';
import '../../../../core/widgets/tailorsync_text_field.dart';
import '../../../../ui/ui.dart';
import 'package:go_router/go_router.dart';
import 'package:dio/dio.dart';

class BusinessProfileScreen extends ConsumerStatefulWidget {
  const BusinessProfileScreen({super.key});

  @override
  ConsumerState<BusinessProfileScreen> createState() => _BusinessProfileScreenState();
}

class _BusinessProfileScreenState extends ConsumerState<BusinessProfileScreen> {
  bool _loading = true;
  bool _saving = false;
  Map<String, dynamic>? _business;
  final _nameCtrl = TextEditingController();
  final _contactCtrl = TextEditingController();
  final _addressCtrl = TextEditingController();
  @override
  void initState() {
    super.initState();
    _loadBusiness();
  }
  Future<void> _loadBusiness() async {
    try {
      final api = ref.read(apiClientProvider);
      final resp = await api.getBusiness();
      if (mounted) {
        setState(() {
          _business = resp.data;
          _nameCtrl.text = _business?['name'] ?? '';
          _contactCtrl.text = _business?['phone'] ?? '';
          _addressCtrl.text = _business?['address'] ?? '';
          _loading = false;
        });
      }
    } catch (e) {
      if (mounted) setState(() => _loading = false);
    }
  }
  Future<void> _saveBusiness() async {
    setState(() => _saving = true);
    try {
      final api = ref.read(apiClientProvider);
      await api.updateBusiness({
        'business_name': _nameCtrl.text.trim(),
        'contact_number': _contactCtrl.text.trim(),
        'address': _addressCtrl.text.trim(),
      });
      if (mounted) ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Business Profile updated')));
    } catch (e) {
      if (mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Error: $e')));
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }
  Future<void> _deleteAccount() async {
    final passwordCtrl = TextEditingController();
    bool obscurePassword = true;

    final confirm = await showTsDialog<bool>(
      context: context,
      builder: (context) => StatefulBuilder(
        builder: (context, setDialogState) => AlertDialog(
          icon: Icon(Icons.delete_forever_rounded, color: Theme.of(context).colorScheme.error, size: 32),
          title: const Text('Delete Account', textAlign: TextAlign.center),
          content: SingleChildScrollView(
            child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Text('This will permanently delete your admin account, your business, and ALL associated data (staff, customers, orders). This action CANNOT be undone.'),
              const SizedBox(height: 16),
              const Text('Please enter your password to confirm:'),
              const SizedBox(height: 8),
              TextField(
                controller: passwordCtrl,
                obscureText: obscurePassword,
                decoration: InputDecoration(
                  labelText: 'Current Password',
                  suffixIcon: IconButton(
                    icon: Icon(obscurePassword ? Icons.visibility_off : Icons.visibility),
                    onPressed: () => setDialogState(() => obscurePassword = !obscurePassword),
                  ),
                ),
              ),
            ],
          ),
          ),
          actions: [
            TextButton(onPressed: () => Navigator.pop(context, false), child: const Text('Cancel')),
            ElevatedButton(
              onPressed: () => Navigator.pop(context, true),
              style: ElevatedButton.styleFrom(backgroundColor: Colors.red, foregroundColor: Colors.white),
              child: const Text('Delete Permanently'),
            ),
          ],
        ),
      ),
    );

    if (confirm != true || passwordCtrl.text.isEmpty) return;

    try {
      final api = ref.read(apiClientProvider);
      await api.deleteMyAccount(passwordCtrl.text);
      if (mounted) {
        // Log out immediately
        api.clearToken();
        ref.read(secureStorageProvider).delete(key: 'auth_token');
        context.go('/login');
      }
    } on DioException catch (e) {
      if (mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Error: ${e.response?.data['detail'] ?? 'Failed to delete account'}'), backgroundColor: Colors.red));
    } catch (e) {
      if (mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Error: $e'), backgroundColor: Colors.red));
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_loading) {
      return const Scaffold(
        body: SafeArea(child: ProfileSkeleton()),
      );
    }

    final cs = context.colors;
    return Scaffold(
      appBar: AppBar(
        leading: IconButton(
          tooltip: 'Back',
          icon: const Icon(Icons.arrow_back_rounded),
          onPressed: () => Navigator.pop(context),
        ),
        title: const Text('Business Profile'),
      ),
      body: TsFormBody(
        children: [
          EntranceFade(
            child: TsCard(
              gradient: Gradients.hero(cs),
              padding: const EdgeInsets.all(Space.lg),
              child: Row(
                children: [
                  Container(
                    width: 52,
                    height: 52,
                    decoration: BoxDecoration(color: Colors.white.withValues(alpha: 0.16), borderRadius: Radii.brMd),
                    child: const Icon(Icons.storefront_rounded, color: Colors.white, size: 28),
                  ),
                  const SizedBox(width: Space.md),
                  Expanded(
                    child: ValueListenableBuilder<TextEditingValue>(
                      valueListenable: _nameCtrl,
                      builder: (context, v, _) => Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            v.text.isEmpty ? 'Your business' : v.text,
                            style: context.text.titleLarge?.copyWith(color: Colors.white),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                          Text(
                            'Shown on orders and receipts',
                            style: context.text.bodySmall?.copyWith(color: Colors.white.withValues(alpha: 0.8)),
                          ),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: Space.lg),
          EntranceFade(
            delay: Motion.staggerStep,
            child: TsCard(
              padding: const EdgeInsets.all(Space.lg),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  TailorSyncTextField(
                    label: 'Business Name',
                    controller: _nameCtrl,
                    icon: Icons.storefront_outlined,
                    textCapitalization: TextCapitalization.words,
                  ),
                  const SizedBox(height: Space.md),
                  TailorSyncTextField(
                    label: 'Business Contact Number',
                    controller: _contactCtrl,
                    icon: Icons.phone_outlined,
                    keyboardType: TextInputType.phone,
                  ),
                  const SizedBox(height: Space.md),
                  TailorSyncTextField(
                    label: 'Business Address',
                    controller: _addressCtrl,
                    icon: Icons.location_on_outlined,
                    maxLines: 3,
                    keyboardType: TextInputType.multiline,
                  ),
                  const SizedBox(height: Space.xl),
                  TsButton(
                    label: 'Save Changes',
                    icon: Icons.check_rounded,
                    loading: _saving,
                    onPressed: _saving ? null : _saveBusiness,
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: Space.xl),
          EntranceFade(
            delay: Motion.staggerStep * 2,
            child: Container(
              padding: const EdgeInsets.all(Space.md),
              decoration: BoxDecoration(
                color: context.status.dangerContainer.withValues(alpha: context.isDark ? 0.35 : 0.5),
                borderRadius: Radii.brLg,
                border: Border.all(color: cs.error.withValues(alpha: 0.35)),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Row(
                    children: [
                      Icon(Icons.warning_amber_rounded, color: cs.error),
                      const SizedBox(width: Space.xs),
                      Text('Danger zone', style: context.text.titleSmall?.copyWith(color: cs.error)),
                    ],
                  ),
                  const SizedBox(height: Space.xs),
                  Text(
                    'Deleting your admin account removes your business and all associated data.',
                    style: context.text.bodySmall,
                  ),
                  const SizedBox(height: Space.md),
                  TsButton(
                    label: 'Delete Admin Account',
                    icon: Icons.delete_forever_rounded,
                    variant: TsButtonVariant.danger,
                    onPressed: _deleteAccount,
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}
