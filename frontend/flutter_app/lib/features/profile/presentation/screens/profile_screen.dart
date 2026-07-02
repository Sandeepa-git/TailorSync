import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../../../core/network/providers/api_provider.dart';

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
        title: Text('Logout', style: GoogleFonts.inter(fontWeight: FontWeight.bold, color: const Color(0xFF1A237E))),
        content: Text('Are you sure you want to log out?', style: GoogleFonts.inter(color: const Color(0xFF5C6BC0))),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: Text('No', style: GoogleFonts.inter(color: const Color(0xFF5C6BC0))),
          ),
          ElevatedButton(
            onPressed: () => Navigator.of(context).pop(true),
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFFD32F2F),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
            ),
            child: Text('Yes', style: GoogleFonts.inter(color: Colors.white, fontWeight: FontWeight.bold)),
          ),
        ],
      ),
    );

    if (confirm == true) {
      final api = ref.read(apiClientProvider);
      api.clearToken();
      if (mounted) context.go('/login');
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_loading) {
      return const Scaffold(
        backgroundColor: Color(0xFFF8F9FA),
        body: Center(child: CircularProgressIndicator(color: Color(0xFF1A237E))),
      );
    }

    return Scaffold(
      backgroundColor: const Color(0xFFF8F9FA),
      appBar: AppBar(
        backgroundColor: const Color(0xFFF8F9FA),
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Color(0xFF1A237E)),
          onPressed: () => context.go('/home'),
        ),
        title: Text(
          'Settings',
          style: GoogleFonts.inter(
            fontWeight: FontWeight.bold,
            color: const Color(0xFF1A237E),
          ),
        ),
        actions: [
          Padding(
            padding: const EdgeInsets.only(right: 16),
            child: CircleAvatar(
              radius: 16,
              backgroundColor: const Color(0xFF1A237E),
              child: Text(
                (_user?['full_name'] ?? 'U')[0].toUpperCase(),
                style: GoogleFonts.inter(fontSize: 14, fontWeight: FontWeight.bold, color: Colors.white),
              ),
            ),
          ),
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Profile Section
            Text('Profile', style: GoogleFonts.inter(fontSize: 14, fontWeight: FontWeight.bold, color: const Color(0xFF1A237E))),
            const SizedBox(height: 12),
            Container(
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: const Color(0xFFE8EAF6)),
                boxShadow: [
                  BoxShadow(color: const Color(0xFF1A237E).withValues(alpha: 0.02), blurRadius: 10, offset: const Offset(0, 4)),
                ],
              ),
              child: Column(
                children: [
                  _SettingsListTile(
                    title: 'Edit Name',
                    subtitle: _user?['full_name'] ?? 'Update Name',
                    trailingIcon: Icons.chevron_right,
                    onTap: () => ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Name editing coming soon'))),
                  ),
                  const Divider(height: 1, color: Color(0xFFE8EAF6)),
                  _SettingsListTile(
                    title: 'Edit Phone Number',
                    subtitle: _user?['phone'] ?? 'Update Phone',
                    trailingIcon: Icons.edit,
                    onTap: () => ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Phone editing coming soon'))),
                  ),
                  const Divider(height: 1, color: Color(0xFFE8EAF6)),
                  _SettingsListTile(
                    title: 'Change Password',
                    trailingIcon: Icons.chevron_right,
                    onTap: () => ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Password change coming soon'))),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 24),

            if (_user?['role'] != 'staff') ...[
              // Business Settings Section
              Text('Business Settings', style: GoogleFonts.inter(fontSize: 14, fontWeight: FontWeight.bold, color: const Color(0xFF1A237E))),
              const SizedBox(height: 12),
              Container(
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(color: const Color(0xFFE8EAF6)),
                  boxShadow: [
                    BoxShadow(color: const Color(0xFF1A237E).withValues(alpha: 0.02), blurRadius: 10, offset: const Offset(0, 4)),
                  ],
                ),
                child: Column(
                  children: [
                    _SettingsListTile(
                      title: 'Business Name',
                      subtitle: 'Add Business Name',
                      trailingIcon: Icons.edit,
                      onTap: () => context.push('/profile/business'),
                    ),
                    const Divider(height: 1, color: Color(0xFFE8EAF6)),
                    _SettingsListTile(
                      title: 'Business Contact Number',
                      subtitle: 'Add Contact',
                      trailingIcon: Icons.edit,
                      onTap: () => context.push('/profile/business'),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 24),

              // Staff Management Section
              Row(
                children: [
                  Text('Staff Management', style: GoogleFonts.inter(fontSize: 14, fontWeight: FontWeight.bold, color: const Color(0xFF1A237E))),
                  const SizedBox(width: 8),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                    decoration: BoxDecoration(color: const Color(0xFFE8EAF6), borderRadius: BorderRadius.circular(12)),
                    child: Text('Owner Only', style: GoogleFonts.inter(fontSize: 10, color: const Color(0xFF5C6BC0))),
                  ),
                ],
              ),
              const SizedBox(height: 12),
              Container(
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(color: const Color(0xFFE8EAF6)),
                  boxShadow: [
                    BoxShadow(color: const Color(0xFF1A237E).withValues(alpha: 0.02), blurRadius: 10, offset: const Offset(0, 4)),
                  ],
                ),
                child: _SettingsListTile(
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
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                  side: const BorderSide(color: Color(0xFFFFEBEE)),
                  backgroundColor: Colors.white,
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    const Icon(Icons.logout, color: Color(0xFFD32F2F), size: 18),
                    const SizedBox(width: 8),
                    Text('Logout', style: GoogleFonts.inter(color: const Color(0xFFD32F2F), fontWeight: FontWeight.bold)),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 24),
          ],
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
      borderRadius: BorderRadius.circular(16),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Row(
          children: [
            if (leadingIcon != null) ...[
              Icon(leadingIcon, color: leadingColor ?? const Color(0xFF5C6BC0), size: 20),
              const SizedBox(width: 12),
            ],
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(title, style: GoogleFonts.inter(fontSize: 13, color: titleColor ?? const Color(0xFF1A237E))),
                  if (subtitle != null) ...[
                    const SizedBox(height: 4),
                    Text(subtitle!, style: GoogleFonts.inter(fontSize: 10, color: const Color(0xFF757575))),
                  ],
                ],
              ),
            ),
            Icon(trailingIcon, color: trailingColor ?? const Color(0xFF1A237E), size: 16),
          ],
        ),
      ),
    );
  }
}
