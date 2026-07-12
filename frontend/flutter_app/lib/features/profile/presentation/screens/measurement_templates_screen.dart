import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../../../core/network/providers/api_provider.dart';

class MeasurementTemplatesScreen extends ConsumerStatefulWidget {
  const MeasurementTemplatesScreen({super.key});

  @override
  ConsumerState<MeasurementTemplatesScreen> createState() => _MeasurementTemplatesScreenState();
}

class _MeasurementTemplatesScreenState extends ConsumerState<MeasurementTemplatesScreen> {
  bool _loading = true;
  List<dynamic> _templates = [];

  @override
  void initState() {
    super.initState();
    _loadTemplates();
  }

  Future<void> _loadTemplates() async {
    try {
      final api = ref.read(apiClientProvider);
      final resp = await api.getMeasurementTemplates();
      if (mounted) {
        setState(() {
          _templates = resp.data;
          _loading = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() => _loading = false);
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Failed to load templates')),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF8F9FA),
      appBar: AppBar(
        backgroundColor: const Color(0xFFF8F9FA),
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Color(0xFF1A237E)),
          onPressed: () => context.pop(),
        ),
        title: Text(
          'Measurement Templates',
          style: GoogleFonts.inter(fontWeight: FontWeight.bold, color: const Color(0xFF1A237E)),
        ),
        centerTitle: true,
      ),
      body: _loading
          ? const Center(child: CircularProgressIndicator(color: Color(0xFF1A237E)))
          : _templates.isEmpty
              ? const Center(child: Text('No templates found.'))
              : ListView.builder(
                  padding: const EdgeInsets.all(20),
                  itemCount: _templates.length,
                  itemBuilder: (context, index) {
                    final t = _templates[index];
                    final fields = t['fields'] as List? ?? [];
                    return Container(
                      margin: const EdgeInsets.only(bottom: 16),
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(color: const Color(0xFFE8EAF6)),
                        boxShadow: [
                          BoxShadow(color: const Color(0xFF1A237E).withValues(alpha: 0.03), blurRadius: 10, offset: const Offset(0, 4)),
                        ],
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(t['category_name'], style: GoogleFonts.inter(fontSize: 16, fontWeight: FontWeight.bold, color: const Color(0xFF1A237E))),
                          const SizedBox(height: 12),
                          Wrap(
                            spacing: 8,
                            runSpacing: 8,
                            children: fields.map((f) {
                              return Container(
                                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                                decoration: BoxDecoration(
                                  color: const Color(0xFFF1F3FB),
                                  borderRadius: BorderRadius.circular(20),
                                ),
                                child: Text(
                                  f['field_name'],
                                  style: GoogleFonts.inter(fontSize: 12, color: const Color(0xFF5C6BC0)),
                                ),
                              );
                            }).toList(),
                          ),
                        ],
                      ),
                    );
                  },
                ),
      floatingActionButton: FloatingActionButton(
        onPressed: () {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Custom templates coming soon!')),
          );
        },
        backgroundColor: const Color(0xFF1A237E),
        child: const Icon(Icons.add, color: Colors.white),
      ),
    );
  }
}
