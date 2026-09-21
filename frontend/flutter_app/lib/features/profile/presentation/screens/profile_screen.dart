import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:dio/dio.dart';
import '../../../../core/network/providers/api_provider.dart';
import '../../../../core/theme/app_theme.dart';
import '../../../../core/widgets/skeleton_loading.dart';

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
    final confirm = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('Logout', style: GoogleFonts.outfit(fontWeight: FontWeight.bold, color: AppTheme.primary, letterSpacing: -0.3)),
        content: Text('Are you sure you want to log out?', style: GoogleFonts.inter(color: AppTheme.textCaption)),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: Text('No', style: GoogleFonts.inter(color: AppTheme.textCaption)),
          ),
          ElevatedButton(
            onPressed: () => Navigator.of(context).pop(true),
            style: ElevatedButton.styleFrom(
              backgroundColor: AppTheme.error,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
            ),
            child: Text('Yes', style: GoogleFonts.inter(color: Colors.white, fontWeight: FontWeight.bold)),
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
            color: isSatisfied ? const Color(0xFF2E7D32) : Colors.grey[400],
          ),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              label,
              style: GoogleFonts.inter(
                fontSize: 12.5,
                color: isSatisfied ? const Color(0xFF2E7D32) : Colors.grey[600],
                fontWeight: isSatisfied ? FontWeight.w600 : FontWeight.normal,
              ),
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

    showDialog(
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
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
            title: Text(
              'Change Password',
              style: GoogleFonts.outfit(fontWeight: FontWeight.bold, color: AppTheme.primary, letterSpacing: -0.3),
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
                      color: const Color(0xFFF4F6FB),
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(color: const Color(0xFFE2E6F0)),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text('Password Requirements:', style: GoogleFonts.inter(fontSize: 12, fontWeight: FontWeight.bold, color: const Color(0xFF1A237E))),
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
                          style: GoogleFonts.inter(
                            fontSize: 12,
                            fontWeight: FontWeight.w600,
                            color: passwordsMatch ? const Color(0xFF2E7D32) : const Color(0xFFD32F2F),
                          ),
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
                child: Text('Cancel', style: GoogleFonts.inter(color: Colors.grey)),
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
                    : Text('Update Password', style: GoogleFonts.inter(color: Colors.white, fontWeight: FontWeight.bold)),
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

    showDialog(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (context, setDialogState) => AlertDialog(
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
          title: Text('Edit Name', style: GoogleFonts.outfit(fontWeight: FontWeight.bold, color: AppTheme.primary, letterSpacing: -0.3)),
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
              style: ElevatedButton.styleFrom(backgroundColor: AppTheme.primary),
              child: Text('Save', style: GoogleFonts.inter(color: Colors.white, fontWeight: FontWeight.bold)),
            ),
          ],
        ),
      ),
    );
  }

  void _showEditPhoneDialog() {
    final phoneCtrl = TextEditingController(text: _user?['phone'] ?? '');
    bool saving = false;

    showDialog(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (context, setDialogState) => AlertDialog(
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
          title: Text('Edit Phone Number', style: GoogleFonts.outfit(fontWeight: FontWeight.bold, color: AppTheme.primary, letterSpacing: -0.3)),
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
              style: ElevatedButton.styleFrom(backgroundColor: AppTheme.primary),
              child: Text('Save', style: GoogleFonts.inter(color: Colors.white, fontWeight: FontWeight.bold)),
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
        backgroundColor: AppTheme.scaffoldBg,
        body: SafeArea(child: ProfileSkeleton()),
      );
    }

    return Scaffold(
      backgroundColor: AppTheme.scaffoldBg,
      appBar: AppBar(
        backgroundColor: AppTheme.scaffoldBg,
        elevation: 0,
        centerTitle: true,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: AppTheme.primary),
          onPressed: () => context.go('/home'),
        ),
        title: Text(
          'Profile & Settings',
          style: GoogleFonts.outfit(
            fontWeight: FontWeight.bold,
            color: AppTheme.primary,
            fontSize: 19,
            letterSpacing: -0.3,
          ),
        ),
        actions: [
          Padding(
            padding: const EdgeInsets.only(right: 16),
            child: Container(
              padding: const EdgeInsets.all(2),
              decoration: const BoxDecoration(
                shape: BoxShape.circle,
                gradient: LinearGradient(
                  colors: [AppTheme.primary, AppTheme.secondary],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
              ),
              child: CircleAvatar(
                radius: 15,
                backgroundColor: AppTheme.surface,
                child: Text(
                  (_user?['full_name'] ?? 'U')[0].toUpperCase(),
                  style: GoogleFonts.inter(fontSize: 13, fontWeight: FontWeight.bold, color: AppTheme.primary),
                ),
              ),
            ),
          ),
        ],
      ),
      body: Center(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(20),
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 720),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('Profile', style: GoogleFonts.outfit(fontSize: 15, fontWeight: FontWeight.bold, color: AppTheme.primary, letterSpacing: -0.3)),
                const SizedBox(height: 12),
                Container(
                  decoration: BoxDecoration(
                    color: AppTheme.surface,
                    borderRadius: BorderRadius.circular(18),
                    boxShadow: AppTheme.softShadow,
                  ),
                  child: Column(
                    children: [
                      _SettingsListTile(
                        leadingIcon: Icons.person_outline_rounded,
                        leadingColor: const Color(0xFF1565C0),
                        title: 'Edit Name',
                        subtitle: _user?['full_name'] ?? 'Update Name',
                        trailingIcon: Icons.chevron_right,
                        onTap: _showEditNameDialog,
                      ),
                      Divider(height: 1, color: AppTheme.divider.withValues(alpha: 0.5), indent: 52),
                      _SettingsListTile(
                        leadingIcon: Icons.phone_outlined,
                        leadingColor: const Color(0xFF00695C),
                        title: 'Edit Phone Number',
                        subtitle: _user?['phone'] ?? 'Update Phone',
                        trailingIcon: Icons.chevron_right,
                        onTap: _showEditPhoneDialog,
                      ),
                      Divider(height: 1, color: AppTheme.divider.withValues(alpha: 0.5), indent: 52),
                      _SettingsListTile(
                        leadingIcon: Icons.lock_outline_rounded,
                        leadingColor: const Color(0xFF6A1B9A),
                        title: 'Change Password',
                        trailingIcon: Icons.chevron_right,
                        onTap: _showChangePasswordDialog,
                      ),
                    ],
                  ),
                ),
            const SizedBox(height: 24),

            if (_user?['role'] != 'staff' && _user?['role'] != 'STAFF') ...[
              // Business Settings Section
              Text('Business Settings', style: GoogleFonts.outfit(fontSize: 15, fontWeight: FontWeight.bold, color: AppTheme.primary, letterSpacing: -0.3)),
              const SizedBox(height: 12),
              Container(
                decoration: BoxDecoration(
                  color: AppTheme.surface,
                  borderRadius: BorderRadius.circular(18),
                  boxShadow: AppTheme.softShadow,
                ),
                child: Column(
                  children: [
                    _SettingsListTile(
                      leadingIcon: Icons.store_rounded,
                      leadingColor: const Color(0xFFE65100),
                      title: 'Business Name',
                      subtitle: 'Add Business Name',
                      trailingIcon: Icons.chevron_right,
                      onTap: () => context.push('/profile/business'),
                    ),
                    Divider(height: 1, color: AppTheme.divider.withValues(alpha: 0.5), indent: 52),
                    _SettingsListTile(
                      leadingIcon: Icons.contact_phone_outlined,
                      leadingColor: const Color(0xFF1565C0),
                      title: 'Business Contact Number',
                      subtitle: 'Add Contact',
                      trailingIcon: Icons.chevron_right,
                      onTap: () => context.push('/profile/business'),
                    ),
                    Divider(height: 1, color: AppTheme.divider.withValues(alpha: 0.5), indent: 52),
                    _SettingsListTile(
                      leadingIcon: Icons.straighten_rounded,
                      leadingColor: const Color(0xFF2E7D32),
                      title: 'Measurement Templates',
                      subtitle: 'Configure dynamic garmanent measurements',
                      trailingIcon: Icons.chevron_right,
                      onTap: () => context.push('/profile/templates'),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 24),

              // Staff Management Section
              Row(
                children: [
                  Text('Staff Management', style: GoogleFonts.outfit(fontSize: 15, fontWeight: FontWeight.bold, color: AppTheme.primary, letterSpacing: -0.3)),
                  const SizedBox(width: 8),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                    decoration: BoxDecoration(color: AppTheme.tertiary, borderRadius: BorderRadius.circular(20)),
                    child: Text('Owner Only', style: GoogleFonts.inter(fontSize: 10, color: AppTheme.textCaption, fontWeight: FontWeight.w600)),
                  ),
                ],
              ),
              const SizedBox(height: 12),
              Container(
                decoration: BoxDecoration(
                  color: AppTheme.surface,
                  borderRadius: BorderRadius.circular(18),
                  boxShadow: AppTheme.softShadow,
                ),
                child: _SettingsListTile(
                  leadingIcon: Icons.groups_rounded,
                  leadingColor: const Color(0xFF6A1B9A),
                  title: 'Manage Staff',
                  subtitle: 'Add or remove employees',
                  trailingIcon: Icons.chevron_right,
                  onTap: () => context.push('/profile/staff'),
                ),
              ),
            ],
            const SizedBox(height: 32),

            // Logout
            SizedBox(
              width: double.infinity,
              child: OutlinedButton(
                onPressed: _logout,
                style: OutlinedButton.styleFrom(
                  padding: const EdgeInsets.symmetric(vertical: 16),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                  side: BorderSide(color: AppTheme.error.withValues(alpha: 0.3)),
                  backgroundColor: AppTheme.error.withValues(alpha: 0.04),
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    const Icon(Icons.logout, color: AppTheme.error, size: 18),
                    const SizedBox(width: 8),
                    Text('Logout', style: GoogleFonts.inter(color: AppTheme.error, fontWeight: FontWeight.bold)),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 24),
          ],
        ),
      ),
    ),
  ),
);
}
}

class _SettingsListTile extends StatelessWidget {
  final IconData? leadingIcon;
  final Color? leadingColor;
  final String title;
  final Color? titleColor;
  final String? subtitle;
  final IconData trailingIcon;
  final Color? trailingColor;
  final VoidCallback onTap;

  const _SettingsListTile({
    this.leadingIcon,
    this.leadingColor,
    required this.title,
    this.titleColor,
    this.subtitle,
    required this.trailingIcon,
    this.trailingColor,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(18),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Row(
          children: [
            if (leadingIcon != null) ...[
              Container(
                width: 36,
                height: 36,
                decoration: BoxDecoration(
                  color: (leadingColor ?? AppTheme.secondary).withValues(alpha: 0.10),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Icon(leadingIcon, color: leadingColor ?? AppTheme.secondary, size: 18),
              ),
              const SizedBox(width: 14),
            ],
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(title, style: GoogleFonts.inter(fontSize: 14, fontWeight: FontWeight.w600, color: titleColor ?? AppTheme.primary)),
                  if (subtitle != null) ...[
                    const SizedBox(height: 3),
                    Text(subtitle!, style: GoogleFonts.inter(fontSize: 11, color: const Color(0xFF757575))),
                  ],
                ],
              ),
            ),
            Container(
              width: 28,
              height: 28,
              decoration: BoxDecoration(
                color: AppTheme.divider.withValues(alpha: 0.5),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Icon(trailingIcon, color: trailingColor ?? AppTheme.primary, size: 16),
            ),
          ],
        ),
      ),
    );
  }
}
