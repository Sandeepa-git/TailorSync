import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../core/network/providers/api_provider.dart';
import '../../../../core/widgets/skeleton_loading.dart';
import '../../../../ui/ui.dart';
import 'package:dio/dio.dart';

class StaffManagementScreen extends ConsumerStatefulWidget {
  const StaffManagementScreen({super.key});

  @override
  ConsumerState<StaffManagementScreen> createState() => _StaffManagementScreenState();
}

class _StaffManagementScreenState extends ConsumerState<StaffManagementScreen> {
  bool _loading = true;
  List<dynamic> _staffList = [];
  @override
  void initState() {
    super.initState();
    _loadStaff();
  }
  Future<void> _loadStaff() async {
    try {
      final api = ref.read(apiClientProvider);
      final resp = await api.listStaff();
      if (mounted) {
        setState(() {
          _staffList = resp.data;
          _loading = false;
        });
      }
    } catch (e) {
      if (mounted) setState(() => _loading = false);
    }
  }
  void _deactivateStaff(int id) async {
    final confirm = await showTsDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('Deactivate Staff'),
        content: const Text('Are you sure you want to deactivate this staff member? They will not be able to log in, but their data will be kept.'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context, false), child: const Text('Cancel')),
          ElevatedButton(
            onPressed: () => Navigator.pop(context, true),
                        child: const Text('Deactivate'),
          ),
        ],
      ),
    );

    if (confirm != true) return;

    try {
      final api = ref.read(apiClientProvider);
      await api.deactivateStaff(id);
      _loadStaff();
      if (mounted) ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Staff deactivated')));
    } catch (e) {
      if (mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Error: $e')));
    }
  }

  void _reactivateStaff(int id) async {
    final confirm = await showTsDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('Reactivate Staff'),
        content: const Text('Are you sure you want to reactivate this staff member? They will regain access to their account.'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context, false), child: const Text('Cancel')),
          ElevatedButton(
            onPressed: () => Navigator.pop(context, true),
                        child: const Text('Reactivate'),
          ),
        ],
      ),
    );

    if (confirm != true) return;

    try {
      final api = ref.read(apiClientProvider);
      await api.reactivateStaff(id);
      _loadStaff();
      if (mounted) ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Staff reactivated')));
    } catch (e) {
      if (mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Error: $e')));
    }
  }

  void _removeStaff(int id) async {
    final confirm = await showTsDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('Remove Staff'),
        content: const Text('Are you sure you want to permanently remove this staff member? This will delete their assignments and cannot be undone.'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context, false), child: const Text('Cancel')),
          ElevatedButton(
            onPressed: () => Navigator.pop(context, true),
            style: ElevatedButton.styleFrom(backgroundColor: Colors.red, foregroundColor: Colors.white),
            child: const Text('Remove Permanently'),
          ),
        ],
      ),
    );

    if (confirm != true) return;

    try {
      final api = ref.read(apiClientProvider);
      await api.removeStaff(id);
      _loadStaff();
      if (mounted) ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Staff removed')));
    } catch (e) {
      if (mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Error: $e')));
    }
  }

  void _showAddStaffDialog() {
    final formKey = GlobalKey<FormState>();
    final emailCtrl = TextEditingController();
    final confirmEmailCtrl = TextEditingController();
    final nameCtrl = TextEditingController();
    final phoneCtrl = TextEditingController();
    final passwordCtrl = TextEditingController();
    bool saving = false;
    bool obscurePassword = true;

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      useSafeArea: true,
      showDragHandle: true,
      builder: (context) => StatefulBuilder(
        builder: (context, setModalState) {
          final bottomInset = MediaQuery.of(context).viewInsets.bottom;
          return Container(
            margin: EdgeInsets.only(bottom: bottomInset),
            padding: const EdgeInsets.fromLTRB(24, 0, 24, 24),
            constraints: BoxConstraints(maxHeight: MediaQuery.of(context).size.height * 0.9),
            child: Form(
              key: formKey,
              child: SingleChildScrollView(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('Add New Staff', style: Theme.of(context).textTheme.headlineSmall),
                    const SizedBox(height: 8),
                    Text('Fill in the details below to invite a new staff member.', style: Theme.of(context).textTheme.bodyMedium),
                    const SizedBox(height: 24),

                    TextFormField(
                      controller: nameCtrl,
                      decoration: const InputDecoration(
                        labelText: 'Full Name', 
                        prefixIcon: Icon(Icons.person_outline),
                      ),
                      validator: (v) => v == null || v.trim().isEmpty ? 'Full name is required' : null,
                    ),
                    const SizedBox(height: 16),

                    TextFormField(
                      controller: emailCtrl,
                      keyboardType: TextInputType.emailAddress,
                      decoration: const InputDecoration(
                        labelText: 'Email Address', 
                        prefixIcon: Icon(Icons.email_outlined),
                      ),
                      validator: (v) {
                        if (v == null || v.trim().isEmpty) return 'Email is required';
                        if (!RegExp(r"^[a-zA-Z0-9.a-zA-Z0-9.!#$%&'*+-/=?^_`{|}~]+@[a-zA-Z0-9]+\.[a-zA-Z]+").hasMatch(v.trim())) return 'Enter a valid email';
                        return null;
                      },
                    ),
                    const SizedBox(height: 16),
                    
                    TextFormField(
                      controller: confirmEmailCtrl,
                      keyboardType: TextInputType.emailAddress,
                      decoration: const InputDecoration(
                        labelText: 'Confirm Email Address', 
                        prefixIcon: Icon(Icons.mark_email_read_outlined),
                      ),
                      validator: (v) {
                        if (v == null || v.trim().isEmpty) return 'Please confirm email';
                        if (v.trim() != emailCtrl.text.trim()) return 'Emails do not match';
                        return null;
                      },
                    ),
                    const SizedBox(height: 16),

                    TextFormField(
                      controller: phoneCtrl,
                      keyboardType: TextInputType.phone,
                      decoration: const InputDecoration(
                        labelText: 'Phone Number', 
                        prefixIcon: Icon(Icons.phone_outlined),
                      ),
                      validator: (v) => v == null || v.trim().isEmpty ? 'Phone number is required' : null,
                    ),
                    const SizedBox(height: 16),

                    TextFormField(
                      controller: passwordCtrl,
                      obscureText: obscurePassword,
                      decoration: InputDecoration(
                        labelText: 'Temporary Password', 
                        prefixIcon: const Icon(Icons.lock_outline),
                        suffixIcon: IconButton(
                          icon: Icon(obscurePassword ? Icons.visibility_off_outlined : Icons.visibility_outlined),
                          onPressed: () => setModalState(() => obscurePassword = !obscurePassword),
                        ),
                      ),
                      validator: (v) => v == null || v.length < 6 ? 'Password must be at least 6 characters' : null,
                    ),
                    const SizedBox(height: 32),

                    SizedBox(
                      width: double.infinity,
                      child: ElevatedButton(
                        onPressed: saving
                            ? null
                            : () async {
                                if (!formKey.currentState!.validate()) return;
                                
                                setModalState(() => saving = true);
                                try {
                                  final api = ref.read(apiClientProvider);
                                  await api.createStaff({
                                    'email': emailCtrl.text.trim(),
                                    'full_name': nameCtrl.text.trim(),
                                    'phone': phoneCtrl.text.trim(),
                                    'password': passwordCtrl.text,
                                  });
                                  if (mounted) {
                                    Navigator.pop(context);
                                    ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Staff added successfully & email sent!')));
                                    _loadStaff();
                                  }
                                } on DioException catch (e) {
                                  if (mounted) {
                                    String errorMsg = 'Failed to add staff';
                                    if (e.response?.data != null && e.response!.data is Map && e.response!.data.containsKey('detail')) {
                                      errorMsg = e.response!.data['detail'].toString();
                                    }
                                    ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(errorMsg), backgroundColor: Colors.red));
                                  }
                                } catch (e) {
                                  if (mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Error: $e'), backgroundColor: Colors.red));
                                } finally {
                                  setModalState(() => saving = false);
                                }
                              },
                        child: saving 
                            ? SizedBox(width: 22, height: 22, child: CircularProgressIndicator(strokeWidth: 2.5, color: Theme.of(context).colorScheme.onPrimary)) 
                            : Text('Send Invitation'),
                      ),
                    ),
                    const SizedBox(height: 16),
                    SizedBox(
                      width: double.infinity,
                      child: TextButton(
                        onPressed: () => Navigator.pop(context),
                        child: Text('Cancel'),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          );
        },
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final cs = context.colors;
    final st = context.status;
    return TsScrollPage(
      title: 'Staff Management',
      leading: IconButton(
        tooltip: 'Back',
        icon: const Icon(Icons.arrow_back_rounded),
        onPressed: () => Navigator.pop(context),
      ),
      onRefresh: _loadStaff,
      floatingActionButton: _staffList.isNotEmpty
          ? FloatingActionButton.extended(
              heroTag: 'fab-staff',
              onPressed: _showAddStaffDialog,
              icon: const Icon(Icons.person_add_alt_1_rounded),
              label: const Text('Add Staff'),
            )
          : null,
      slivers: [
        if (_loading)
          const SliverToBoxAdapter(child: CustomersListSkeleton())
        else if (_staffList.isEmpty)
          SliverFillRemaining(
            hasScrollBody: false,
            child: EmptyState(
              icon: Icons.groups_rounded,
              title: 'No staff members yet',
              message: 'Invite your team to assign and track tasks.',
              actionLabel: 'Add Your First Staff Member',
              actionIcon: Icons.add_rounded,
              onAction: _showAddStaffDialog,
            ),
          )
        else
          SliverList.separated(
            itemCount: _staffList.length,
            separatorBuilder: (_, __) => SizedBox(height: context.gridGap),
            itemBuilder: (context, index) {
              final staff = _staffList[index];
              final active = staff['is_active'] != false;
              final name = (staff['full_name'] ?? 'Unknown').toString();
              return EntranceFade.indexed(
                index,
                key: ValueKey(staff['id']),
                child: AnimatedOpacity(
                  duration: Motion.of(context, Motion.medium),
                  opacity: active ? 1 : 0.7,
                  child: TsCard(
                    padding: const EdgeInsets.fromLTRB(Space.md, Space.sm, Space.xxs, Space.sm),
                    child: Row(
                      children: [
                        InitialsAvatar(name: name, size: 46),
                        const SizedBox(width: Space.sm),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Row(
                                children: [
                                  Flexible(
                                    child: Text(name, style: context.text.titleSmall, maxLines: 1, overflow: TextOverflow.ellipsis),
                                  ),
                                  if (!active) ...[
                                    const SizedBox(width: Space.xs),
                                    StatusPill(label: 'Deactivated', color: st.danger, dense: true),
                                  ],
                                ],
                              ),
                              const SizedBox(height: 2),
                              Text(staff['email'] ?? '', style: context.text.bodySmall, maxLines: 1, overflow: TextOverflow.ellipsis),
                            ],
                          ),
                        ),
                        PopupMenuButton<String>(
                          tooltip: 'Staff actions',
                          icon: Icon(Icons.more_vert_rounded, color: cs.onSurfaceVariant),
                          shape: RoundedRectangleBorder(borderRadius: Radii.brMd),
                          onSelected: (value) {
                            if (value == 'deactivate') {
                              _deactivateStaff(staff['id']);
                            } else if (value == 'reactivate') {
                              _reactivateStaff(staff['id']);
                            } else if (value == 'remove') {
                              _removeStaff(staff['id']);
                            }
                          },
                          itemBuilder: (BuildContext context) => <PopupMenuEntry<String>>[
                            if (staff['is_active'] != false)
                              PopupMenuItem<String>(
                                value: 'deactivate',
                                child: ListTile(
                                  leading: Icon(Icons.person_off_outlined, color: st.warning),
                                  title: const Text('Deactivate Access'),
                                  contentPadding: EdgeInsets.zero,
                                ),
                              ),
                            if (staff['is_active'] == false)
                              PopupMenuItem<String>(
                                value: 'reactivate',
                                child: ListTile(
                                  leading: Icon(Icons.person_add_alt_1_outlined, color: st.success),
                                  title: const Text('Reactivate Access'),
                                  contentPadding: EdgeInsets.zero,
                                ),
                              ),
                            const PopupMenuDivider(),
                            PopupMenuItem<String>(
                              value: 'remove',
                              child: ListTile(
                                leading: Icon(Icons.delete_outline_rounded, color: st.danger),
                                title: Text('Remove Permanently', style: TextStyle(color: st.danger)),
                                contentPadding: EdgeInsets.zero,
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                ),
              );
            },
          ),
      ],
    );
  }
}
