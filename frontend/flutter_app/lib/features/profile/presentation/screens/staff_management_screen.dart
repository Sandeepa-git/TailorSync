import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../../../core/network/providers/api_provider.dart';

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

  Future<void> _deactivateStaff(int id) async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Deactivate Staff'),
        content: const Text('Are you sure you want to deactivate this staff member?'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context, false), child: const Text('Cancel')),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text('Deactivate', style: TextStyle(color: Colors.red)),
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

  void _showAddStaffDialog() {
    final emailCtrl = TextEditingController();
    final nameCtrl = TextEditingController();
    final phoneCtrl = TextEditingController();
    final passwordCtrl = TextEditingController();
    bool saving = false;

    showDialog(
      context: context,
      builder: (context) => StatefulBuilder(
        builder: (context, setDialogState) {
          return AlertDialog(
            title: const Text('Add New Staff'),
            content: SingleChildScrollView(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  TextField(controller: nameCtrl, decoration: const InputDecoration(labelText: 'Full Name')),
                  TextField(controller: emailCtrl, decoration: const InputDecoration(labelText: 'Email Address')),
                  TextField(controller: phoneCtrl, decoration: const InputDecoration(labelText: 'Phone Number')),
                  TextField(controller: passwordCtrl, decoration: const InputDecoration(labelText: 'Temporary Password'), obscureText: true),
                ],
              ),
            ),
            actions: [
              TextButton(onPressed: () => Navigator.pop(context), child: const Text('Cancel')),
              ElevatedButton(
                onPressed: saving
                    ? null
                    : () async {
                        setDialogState(() => saving = true);
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
                            _loadStaff();
                          }
                        } catch (e) {
                          if (mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Error: $e')));
                        } finally {
                          setDialogState(() => saving = false);
                        }
                      },
                child: saving ? const SizedBox(width: 16, height: 16, child: CircularProgressIndicator(strokeWidth: 2)) : const Text('Add Staff'),
              ),
            ],
          );
        },
      ),
    );
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
          onPressed: () => Navigator.pop(context),
        ),
        title: Text(
          'Staff Management',
          style: GoogleFonts.inter(fontWeight: FontWeight.bold, color: const Color(0xFF1A237E)),
        ),
      ),
      body: _staffList.isEmpty
          ? Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Icon(Icons.people_outline, size: 64, color: Color(0xFF9FA8DA)),
                  const SizedBox(height: 16),
                  Text('No staff members yet', style: GoogleFonts.inter(fontSize: 16, color: const Color(0xFF5C6BC0))),
                  const SizedBox(height: 24),
                  ElevatedButton.icon(
                    onPressed: _showAddStaffDialog,
                    icon: const Icon(Icons.add),
                    label: const Text('Add Your First Staff Member'),
                    style: ElevatedButton.styleFrom(backgroundColor: const Color(0xFF1A237E), foregroundColor: Colors.white),
                  ),
                ],
              ),
            )
          : ListView.builder(
              padding: const EdgeInsets.all(20),
              itemCount: _staffList.length,
              itemBuilder: (context, index) {
                final staff = _staffList[index];
                return Container(
                  margin: const EdgeInsets.only(bottom: 12),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(color: const Color(0xFFE8EAF6)),
                    boxShadow: [
                      BoxShadow(color: const Color(0xFF1A237E).withValues(alpha: 0.02), blurRadius: 10, offset: const Offset(0, 4)),
                    ],
                  ),
                  child: ListTile(
                    contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                    leading: CircleAvatar(
                      backgroundColor: const Color(0xFF5C6BC0),
                      child: Text((staff['full_name'] ?? 'S')[0].toUpperCase(), style: const TextStyle(color: Colors.white)),
                    ),
                    title: Text(staff['full_name'] ?? 'Unknown', style: GoogleFonts.inter(fontWeight: FontWeight.bold, color: const Color(0xFF1A237E))),
                    subtitle: Text(staff['email'] ?? '', style: GoogleFonts.inter(fontSize: 12, color: const Color(0xFF757575))),
                    trailing: IconButton(
                      icon: const Icon(Icons.person_off_outlined, color: Color(0xFFD32F2F)),
                      onPressed: () => _deactivateStaff(staff['id']),
                      tooltip: 'Deactivate Staff',
                    ),
                  ),
                );
              },
            ),
      floatingActionButton: _staffList.isNotEmpty
          ? FloatingActionButton(
              onPressed: _showAddStaffDialog,
              backgroundColor: const Color(0xFF1A237E),
              child: const Icon(Icons.add, color: Colors.white),
            )
          : null,
    );
  }
}
