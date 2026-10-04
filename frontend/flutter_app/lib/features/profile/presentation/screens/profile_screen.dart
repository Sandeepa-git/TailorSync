import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:dio/dio.dart';
import '../../../../core/network/providers/api_provider.dart';
import '../../../../core/theme/app_theme.dart';
import '../../../../core/widgets/skeleton_loading.dart';
import '../../../../ui/ui.dart';
import '../../../auth/presentation/screens/privacy_policy_screen.dart';

class ProfileScreen extends ConsumerStatefulWidget {
  const ProfileScreen({super.key});

  @override
  ConsumerState<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends ConsumerState<ProfileScreen> {
  Map<String, dynamic>? _user;
  bool _loading = true;
  @override
  void initState() {
    super.initState();
    _loadProfile();
  }
  Future<void> _loadProfile() async {
    try {
      final api = ref.read(apiClientProvider);
      final resp = await api.getMe();
      if (mounted) {
        setState(() {
          _user = resp.data;
          _loading = false;
        });
      }
    } catch (e) {
      if (mounted) setState(() => _loading = false);
    }
  }
  Future<void> _logout() async {
    final confirm = await showTsDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('Logout'),
        content: Text('Are you sure you want to log out?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: Text('No'),
          ),
          ElevatedButton(
            onPressed: () => Navigator.of(context).pop(true),
            style: ElevatedButton.styleFrom(
              backgroundColor: AppTheme.error,
            ),
            child: Text('Yes'),
          ),
        ],
      ),
    );

    if (confirm == true) {
      final api = ref.read(apiClientProvider);
      api.clearToken();
      await ref.read(secureStorageProvider).delete(key: 'auth_token');
      if (mounted) context.go('/login');
    }
  }

  Widget _buildChecklistItem(String label, bool isSatisfied) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 3.0),
      child: Row(
        children: [
          Icon(
            isSatisfied ? Icons.check_circle_rounded : Icons.radio_button_unchecked,
            size: 16,
            color: isSatisfied ? const Color(0xFF2E7D32) : Theme.of(context).colorScheme.outline,
          ),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              label,
            ),
          ),
        ],
      ),
    );
  }

  void _showChangePasswordDialog() {
    final currentPasswordCtrl = TextEditingController();
    final newPasswordCtrl = TextEditingController();
    final confirmPasswordCtrl = TextEditingController();
    bool obscureCurrent = true;
    bool obscureNew = true;
    bool obscureConfirm = true;
    bool saving = false;

    showTsDialog(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (context, setDialogState) {
          final newPwText = newPasswordCtrl.text;
          bool hasMinLength = newPwText.length >= 8;
          bool hasUppercase = RegExp(r'[A-Z]').hasMatch(newPwText);
          bool hasLowercase = RegExp(r'[a-z]').hasMatch(newPwText);
          bool hasDigit = RegExp(r'[0-9]').hasMatch(newPwText);
          bool hasSpecialChar = RegExp(r'[!@#$%^&*(),.?":{}|<>\_\+\-=\[\]\\/]').hasMatch(newPwText);
          bool isPasswordValid = hasMinLength && hasUppercase && hasLowercase && hasDigit && hasSpecialChar;
          bool passwordsMatch = newPwText.isNotEmpty && newPwText == confirmPasswordCtrl.text;

          return AlertDialog(
            title: Text(
              'Change Password',
            ),
            content: SingleChildScrollView(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  TextField(
                    controller: currentPasswordCtrl,
                    obscureText: obscureCurrent,
                    decoration: InputDecoration(
                      labelText: 'Current Password',
                      suffixIcon: IconButton(
                        icon: Icon(obscureCurrent ? Icons.visibility_off : Icons.visibility),
                        onPressed: () => setDialogState(() => obscureCurrent = !obscureCurrent),
                      ),
                    ),
                  ),
                  const SizedBox(height: 12),
                  TextField(
                    controller: newPasswordCtrl,
                    obscureText: obscureNew,
                    onChanged: (_) => setDialogState(() {}),
                    decoration: InputDecoration(
                      labelText: 'New Password',
                      hintText: 'Min 8 chars (A-Z, a-z, 0-9, special)',
                      suffixIcon: IconButton(
                        icon: Icon(obscureNew ? Icons.visibility_off : Icons.visibility),
                        onPressed: () => setDialogState(() => obscureNew = !obscureNew),
                      ),
                    ),
                  ),
                  const SizedBox(height: 12),
                  Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: Theme.of(context).colorScheme.surfaceContainerHigh,
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(color: Theme.of(context).colorScheme.outlineVariant),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text('Password Requirements:'),
                        const SizedBox(height: 6),
                        _buildChecklistItem('Minimum 8 characters', hasMinLength),
                        _buildChecklistItem('At least one uppercase letter (A-Z)', hasUppercase),
                        _buildChecklistItem('At least one lowercase letter (a-z)', hasLowercase),
                        _buildChecklistItem('At least one number (0-9)', hasDigit),
                        _buildChecklistItem('At least one special character (!@#\$%...)', hasSpecialChar),
                      ],
                    ),
                  ),
                  const SizedBox(height: 12),
                  TextField(
                    controller: confirmPasswordCtrl,
                    obscureText: obscureConfirm,
                    onChanged: (_) => setDialogState(() {}),
                    decoration: InputDecoration(
                      labelText: 'Confirm New Password',
                      suffixIcon: IconButton(
                        icon: Icon(obscureConfirm ? Icons.visibility_off : Icons.visibility),
                        onPressed: () => setDialogState(() => obscureConfirm = !obscureConfirm),
                      ),
                    ),
                  ),
                  if (confirmPasswordCtrl.text.isNotEmpty) ...[
                    const SizedBox(height: 8),
                    Row(
                      children: [
                        Icon(
                          passwordsMatch ? Icons.check_circle : Icons.error,
                          size: 16,
                          color: passwordsMatch ? const Color(0xFF2E7D32) : const Color(0xFFD32F2F),
                        ),
                        const SizedBox(width: 6),
                        Text(
                          passwordsMatch ? 'Passwords match' : 'Passwords do not match',
                        ),
                      ],
                    ),
                  ],
                ],
              ),
            ),
            actions: [
              TextButton(
                onPressed: saving ? null : () => Navigator.pop(ctx),
                child: Text('Cancel'),
              ),
              ElevatedButton(
                onPressed: saving || !isPasswordValid || !passwordsMatch
                    ? null
                    : () async {
                        final currPw = currentPasswordCtrl.text.trim();
                        final newPw = newPasswordCtrl.text.trim();
                        final confPw = confirmPasswordCtrl.text.trim();

                        if (currPw.isEmpty || newPw.isEmpty || confPw.isEmpty) {
                          ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(content: Text('Please fill in all fields'), backgroundColor: AppTheme.error),
                          );
                          return;
                        }
                        if (newPw != confPw) {
                          ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(content: Text('New passwords do not match'), backgroundColor: AppTheme.error),
                          );
                          return;
                        }

                        setDialogState(() => saving = true);
                        try {
                          final api = ref.read(apiClientProvider);
                          await api.changePassword(currPw, newPw);
                          if (context.mounted) {
                            Navigator.pop(ctx);
                            ScaffoldMessenger.of(context).showSnackBar(
                              const SnackBar(content: Text('Password changed successfully!'), backgroundColor: Color(0xFF388E3C)),
                            );
                          }
                        } catch (e) {
                          setDialogState(() => saving = false);
                          String err = 'Failed to change password';
                          if (e is DioException && e.response?.data != null) {
                            final data = e.response!.data;
                            if (data is Map && data.containsKey('detail')) {
                              err = data['detail'].toString();
                            }
                          }
                          if (context.mounted) {
                            ScaffoldMessenger.of(context).showSnackBar(
                              SnackBar(content: Text(err), backgroundColor: AppTheme.error),
                            );
                          }
                        }
                      },
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppTheme.primary,
                  disabledBackgroundColor: Colors.grey[300],
                ),
                child: saving
                    ? const SizedBox(width: 16, height: 16, child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white))
                    : Text('Update Password'),
              ),
            ],
          );
        },
      ),
    );
  }

  void _showEditNameDialog() {
    final nameCtrl = TextEditingController(text: _user?['full_name'] ?? '');
    bool saving = false;

    showTsDialog(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (context, setDialogState) => AlertDialog(
          title: Text('Edit Name'),
          content: TextField(
            controller: nameCtrl,
            decoration: const InputDecoration(labelText: 'Full Name'),
          ),
          actions: [
            TextButton(onPressed: saving ? null : () => Navigator.pop(ctx), child: const Text('Cancel')),
            ElevatedButton(
              onPressed: saving
                  ? null
                  : () async {
                      final newName = nameCtrl.text.trim();
                      if (newName.isEmpty) return;
                      setDialogState(() => saving = true);
                      try {
                        final api = ref.read(apiClientProvider);
                        await api.updateProfile({'full_name': newName});
                        await _loadProfile();
                        if (context.mounted) {
                          Navigator.pop(ctx);
                          ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Name updated successfully'), backgroundColor: Color(0xFF388E3C)));
                        }
                      } catch (e) {
                        setDialogState(() => saving = false);
                      }
                    },
              child: Text('Save'),
            ),
          ],
        ),
      ),
    );
  }

  void _showEditPhoneDialog() {
    final phoneCtrl = TextEditingController(text: _user?['phone'] ?? '');
    bool saving = false;

    showTsDialog(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (context, setDialogState) => AlertDialog(
          title: Text('Edit Phone Number'),
          content: TextField(
            controller: phoneCtrl,
            decoration: const InputDecoration(labelText: 'Phone Number'),
            keyboardType: TextInputType.phone,
          ),
          actions: [
            TextButton(onPressed: saving ? null : () => Navigator.pop(ctx), child: const Text('Cancel')),
            ElevatedButton(
              onPressed: saving
                  ? null
                  : () async {
                      final newPhone = phoneCtrl.text.trim();
                      setDialogState(() => saving = true);
                      try {
                        final api = ref.read(apiClientProvider);
                        await api.updateProfile({'phone': newPhone});
                        await _loadProfile();
                        if (context.mounted) {
                          Navigator.pop(ctx);
                          ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Phone number updated successfully'), backgroundColor: Color(0xFF388E3C)));
                        }
                      } catch (e) {
                        setDialogState(() => saving = false);
                      }
                    },
              child: Text('Save'),
            ),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    if (_loading) {
      return const Scaffold(
        body: SafeArea(child: ProfileSkeleton()),
      );
    }

    final cs = context.colors;
    final st = context.status;
    final isOwnerSide = _user?['role'] != 'staff' && _user?['role'] != 'STAFF';
    final name = (_user?['full_name'] ?? 'User').toString();

    int idx = 0;
    Widget section(Widget child) => EntranceFade(delay: Motion.stagger(idx++), child: child);

    return TsScrollPage(
      title: 'Profile & Settings',
      leading: IconButton(
        tooltip: 'Back',
        icon: const Icon(Icons.arrow_back_rounded),
        onPressed: () => context.go('/home'),
      ),
      slivers: [
        SliverToBoxAdapter(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              section(_ProfileHeader(
                name: name,
                email: _user?['email']?.toString(),
                role: _user?['role']?.toString(),
              )),
              const SectionHeader(title: 'Profile'),
              section(_SettingsGroup(children: [
                _SettingsListTile(
                  leadingIcon: Icons.person_outline_rounded,
                  leadingColor: st.info,
                  title: 'Edit Name',
                  subtitle: _user?['full_name'] ?? 'Update Name',
                  trailingIcon: Icons.chevron_right_rounded,
                  onTap: _showEditNameDialog,
                ),
                _SettingsListTile(
                  leadingIcon: Icons.phone_outlined,
                  leadingColor: st.success,
                  title: 'Edit Phone Number',
                  subtitle: _user?['phone'] ?? 'Update Phone',
                  trailingIcon: Icons.chevron_right_rounded,
                  onTap: _showEditPhoneDialog,
                ),
                _SettingsListTile(
                  leadingIcon: Icons.lock_outline_rounded,
                  leadingColor: cs.tertiary,
                  title: 'Change Password',
                  trailingIcon: Icons.chevron_right_rounded,
                  onTap: _showChangePasswordDialog,
                ),
              ])),

              if (isOwnerSide) ...[
                const SectionHeader(title: 'Business Settings'),
                section(_SettingsGroup(children: [
                  _SettingsListTile(
                    leadingIcon: Icons.storefront_rounded,
                    leadingColor: st.warning,
                    title: 'Business Profile',
                    subtitle: 'Edit business details and settings',
                    trailingIcon: Icons.chevron_right_rounded,
                    onTap: () => context.push('/profile/business'),
                  ),
                  _SettingsListTile(
                    leadingIcon: Icons.straighten_rounded,
                    leadingColor: st.success,
                    title: 'Measurement Templates',
                    subtitle: 'Configure dynamic garmanent measurements',
                    trailingIcon: Icons.chevron_right_rounded,
                    onTap: () => context.push('/profile/templates'),
                  ),
                ])),
                Padding(
                  padding: const EdgeInsets.only(top: Space.lg, bottom: Space.sm),
                  child: Row(
                    children: [
                      Flexible(child: Text('Staff Management', style: context.text.titleMedium)),
                      const SizedBox(width: Space.xs),
                      StatusPill(label: 'Owner Only', color: cs.primary, icon: Icons.verified_user_outlined, dense: true),
                    ],
                  ),
                ),
                section(_SettingsGroup(children: [
                  _SettingsListTile(
                    leadingIcon: Icons.groups_rounded,
                    leadingColor: cs.tertiary,
                    title: 'Manage Staff',
                    subtitle: 'Add or remove employees',
                    trailingIcon: Icons.chevron_right_rounded,
                    onTap: () => context.push('/profile/staff'),
                  ),
                ])),
              ],

              const SectionHeader(title: 'Support'),
              section(_SettingsGroup(children: [
                _SettingsListTile(
                  leadingIcon: Icons.privacy_tip_outlined,
                  leadingColor: cs.onSurfaceVariant,
                  title: 'Privacy Policy',
                  trailingIcon: Icons.chevron_right_rounded,
                  onTap: () => Navigator.of(context).push(
                    MaterialPageRoute(builder: (_) => const PrivacyPolicyScreen()),
                  ),
                ),
                _SettingsListTile(
                  leadingIcon: Icons.headset_mic_outlined,
                  leadingColor: st.success,
                  title: 'Contact Support',
                  trailingIcon: Icons.chevron_right_rounded,
                  onTap: () {
                      showDialog(
                        context: context,
                        builder: (context) => AlertDialog(
                          title: const Text('Contact Support'),
                          content: const Column(
                            mainAxisSize: MainAxisSize.min,
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text('Need Help?'),
                              SizedBox(height: 8),
                              Text('Reach out to us at: agsvwimalasiri@gmail.com'),
                            ],
                          ),
                          actions: [
                            TextButton(onPressed: () => Navigator.pop(context), child: const Text('Close')),
                          ],
                        ),
                      );
                    },
                ),
                _SettingsListTile(
                  leadingIcon: Icons.info_outline_rounded,
                  leadingColor: cs.primary,
                  title: 'About',
                  trailingIcon: Icons.chevron_right_rounded,
                  onTap: () {
                      showDialog(
                        context: context,
                        builder: (context) => AlertDialog(
                          title: const Text('About TailorSync'),
                          content: const Column(
                            mainAxisSize: MainAxisSize.min,
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text('TailorSync is a comprehensive tailoring management solution designed to streamline measurements, orders, and customer relationships.'),
                              SizedBox(height: 16),
                              Text('Developer Details:', style: TextStyle(fontWeight: FontWeight.bold)),
                              SizedBox(height: 8),
                              Text('A.G.S.V. Wimalasiri'),
                              Text('W.A.E.M. Wijayarathna'),
                              Text('N.D.H.A. Madubhashitha'),
                              Text('D.M.J.B. Disanayake'),
                              Text('Manuwendra Rajapaksha'),
                              Text('K.P.N.D. Ashokarathna'),
                              const SizedBox(height: 12),
                              Text('Contact: agsvwimalasiri@gmail.com'),
                            ],
                          ),
                          actions: [
                            TextButton(onPressed: () => Navigator.pop(context), child: const Text('Close')),
                          ],
                        ),
                      );
                    },
                ),
                _SettingsListTile(
                  leadingIcon: Icons.local_offer_outlined,
                  leadingColor: st.warning,
                  title: 'Version',
                  trailingWidget: Text('1.0.0', style: context.text.labelLarge?.copyWith(color: cs.onSurfaceVariant)),
                ),
              ])),
              const SizedBox(height: Space.xl),
              section(TsButton(
                label: 'Logout',
                icon: Icons.logout_rounded,
                variant: TsButtonVariant.secondary,
                onPressed: _logout,
              )),
            ],
          ),
        ),
      ],
    );
  }
}

class _ProfileHeader extends StatelessWidget {
  final String name;
  final String? email;
  final String? role;
  const _ProfileHeader({required this.name, this.email, this.role});

  @override
  Widget build(BuildContext context) {
    final cs = context.colors;
    return TsCard(
      gradient: Gradients.hero(cs),
      padding: const EdgeInsets.all(Space.lg),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(3),
            decoration: BoxDecoration(shape: BoxShape.circle, color: Colors.white.withValues(alpha: 0.25)),
            child: CircleAvatar(
              radius: context.isSmallPhone ? 28 : 34,
              backgroundColor: Colors.white,
              child: Text(
                name.isNotEmpty ? name[0].toUpperCase() : 'U',
                style: context.text.headlineSmall?.copyWith(color: cs.primary),
              ),
            ),
          ),
          const SizedBox(width: Space.md),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(name, style: context.text.titleLarge?.copyWith(color: Colors.white), maxLines: 1, overflow: TextOverflow.ellipsis),
                if (email != null && email!.isNotEmpty)
                  Text(
                    email!,
                    style: context.text.bodySmall?.copyWith(color: Colors.white.withValues(alpha: 0.8)),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                if (role != null) ...[
                  const SizedBox(height: Space.xs),
                  StatusPill(
                    label: role!.toUpperCase(),
                    color: Colors.white,
                    background: Colors.white.withValues(alpha: 0.18),
                    icon: Icons.badge_outlined,
                    dense: true,
                  ),
                ],
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _SettingsGroup extends StatelessWidget {
  final List<Widget> children;
  const _SettingsGroup({required this.children});

  @override
  Widget build(BuildContext context) {
    return TsCard(
      padding: const EdgeInsets.symmetric(vertical: Space.xxs),
      child: Column(
        children: [
          for (var i = 0; i < children.length; i++) ...[
            children[i],
            if (i < children.length - 1) const Divider(indent: 64, endIndent: Space.md),
          ],
        ],
      ),
    );
  }
}

class _SettingsListTile extends StatelessWidget {
  final IconData? leadingIcon;
  final Color? leadingColor;
  final String title;
  final String? subtitle;
  final IconData? trailingIcon;
  final Widget? trailingWidget;
  final VoidCallback? onTap;

  const _SettingsListTile({
    this.leadingIcon,
    this.leadingColor,
    required this.title,
    this.subtitle,
    this.trailingIcon,
    this.trailingWidget,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final cs = context.colors;
    return InkWell(
      onTap: onTap,
      borderRadius: Radii.brLg,
      child: ConstrainedBox(
        constraints: const BoxConstraints(minHeight: 60),
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: Space.md, vertical: Space.sm),
          child: Row(
            children: [
              if (leadingIcon != null) ...[
                IconBadge(icon: leadingIcon!, color: leadingColor ?? cs.primary, size: 36),
                const SizedBox(width: Space.sm + 2),
              ],
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(title, style: context.text.titleSmall),
                    if (subtitle != null) ...[
                      const SizedBox(height: 2),
                      Text(subtitle!, style: context.text.bodySmall, maxLines: 2, overflow: TextOverflow.ellipsis),
                    ],
                  ],
                ),
              ),
              if (trailingWidget != null)
                trailingWidget!
              else if (trailingIcon != null)
                Icon(trailingIcon, color: cs.onSurfaceVariant, size: 22),
            ],
          ),
        ),
      ),
    );
  }
}
