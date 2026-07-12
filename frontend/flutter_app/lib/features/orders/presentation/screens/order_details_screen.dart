import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../models/order.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

class OrderDetailsScreen extends ConsumerWidget {
  final Order order;
  const OrderDetailsScreen({super.key, required this.order});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
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
          'Order Details',
          style: GoogleFonts.inter(
            fontWeight: FontWeight.bold,
            color: const Color(0xFF1A237E),
          ),
        ),
        centerTitle: true,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Header Info
            Container(
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: const Color(0xFFE8EAF6)),
                boxShadow: [
                  BoxShadow(color: const Color(0xFF1A237E).withOpacity(0.03), blurRadius: 10, offset: const Offset(0, 4)),
                ],
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text('Order #${order.id}', style: GoogleFonts.inter(fontSize: 16, fontWeight: FontWeight.bold, color: const Color(0xFF5C6BC0))),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                        decoration: BoxDecoration(
                          color: const Color(0xFF1A237E).withOpacity(0.1),
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Text(order.status ?? 'Pending', style: const TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: Color(0xFF1A237E))),
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),
                  Text(order.garmentType, style: GoogleFonts.inter(fontSize: 22, fontWeight: FontWeight.bold, color: const Color(0xFF1A237E))),
                  const SizedBox(height: 16),
                  _DetailRow(icon: Icons.person_outline, label: 'Customer', value: order.customerName ?? 'Customer #${order.customerId}'),
                  const SizedBox(height: 8),
                  _DetailRow(icon: Icons.calendar_today, label: 'Due Date', value: order.dueDate != null ? order.dueDate!.split('T')[0] : 'Not Set'),
                  const SizedBox(height: 8),
                  _DetailRow(icon: Icons.priority_high, label: 'Priority', value: order.priority ?? 'Normal'),
                ],
              ),
            ),
            const SizedBox(height: 24),
            
            // Notes
            if (order.customerInstructions != null && order.customerInstructions!.isNotEmpty) ...[
              Text('Instructions', style: GoogleFonts.inter(fontSize: 16, fontWeight: FontWeight.bold, color: const Color(0xFF1A237E))),
              const SizedBox(height: 12),
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: const Color(0xFFE8EAF6)),
                ),
                child: Text(order.customerInstructions!, style: GoogleFonts.inter(fontSize: 14, color: const Color(0xFF5C6BC0))),
              ),
              const SizedBox(height: 24),
            ],

            // Measurements
            if (order.measurements != null && order.measurements!.isNotEmpty) ...[
              Text('Measurements', style: GoogleFonts.inter(fontSize: 16, fontWeight: FontWeight.bold, color: const Color(0xFF1A237E))),
              const SizedBox(height: 12),
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: const Color(0xFFE8EAF6)),
                ),
                child: Wrap(
                  spacing: 12,
                  runSpacing: 12,
                  children: order.measurements!.map((m) {
                    return Container(
                      width: MediaQuery.of(context).size.width / 2 - 44, // Half width minus padding
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: const Color(0xFFF8F9FA),
                        borderRadius: BorderRadius.circular(8),
                        border: Border.all(color: const Color(0xFFE8EAF6)),
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(m['field_name'] ?? 'Unknown', style: GoogleFonts.inter(fontSize: 11, color: const Color(0xFF5C6BC0))),
                          const SizedBox(height: 4),
                          Text('${m['value']} ${m['unit'] ?? 'cm'}', style: GoogleFonts.inter(fontSize: 14, fontWeight: FontWeight.bold, color: const Color(0xFF1A237E))),
                        ],
                      ),
                    );
                  }).toList(),
                ),
              ),
              const SizedBox(height: 24),
            ],
            
            // Actions
            SizedBox(
              width: double.infinity,
              child: ElevatedButton.icon(
                onPressed: () {
                  ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Print invoice coming soon!')));
                },
                icon: const Icon(Icons.print, color: Colors.white),
                label: const Text('Print Receipt / Invoice', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFF1A237E),
                  padding: const EdgeInsets.symmetric(vertical: 16),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _DetailRow extends StatelessWidget {
  final IconData icon;
  final String label;
  final String value;
  const _DetailRow({required this.icon, required this.label, required this.value});

  @override
  Widget build(BuildContext context) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Icon(icon, size: 16, color: const Color(0xFF5C6BC0)),
        const SizedBox(width: 8),
        SizedBox(
          width: 80,
          child: Text(label, style: GoogleFonts.inter(fontSize: 13, color: const Color(0xFF9E9E9E))),
        ),
        Expanded(
          child: Text(value, style: GoogleFonts.inter(fontSize: 14, fontWeight: FontWeight.w600, color: const Color(0xFF1A237E))),
        ),
      ],
    );
  }
}
