import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../../../core/network/providers/api_provider.dart';
import '../../../customers/presentation/providers/customers_provider.dart';
import '../../../customers/models/customer.dart';
import '../../presentation/providers/orders_provider.dart';

class NewOrderWizard extends ConsumerStatefulWidget {
  const NewOrderWizard({super.key});

  @override
  ConsumerState<NewOrderWizard> createState() => _NewOrderWizardState();
}

class _NewOrderWizardState extends ConsumerState<NewOrderWizard> {
  int _currentStep = 0;
  bool _saving = false;
  Map<String, dynamic>? _user;
  List<dynamic> _staffList = [];
  bool _loadingInit = true;

  @override
  void initState() {
    super.initState();
    _loadInitData();
  }

  Future<void> _loadInitData() async {
    try {
      final api = ref.read(apiClientProvider);
      final userResp = await api.getMe();
      final staffResp = await api.listStaff();
      if (mounted) {
        setState(() {
          _user = userResp.data;
          _staffList = staffResp.data;
          if (_user?['role'] == 'staff') {
            _selectedStaffId = _user?['id'];
          } else if (_staffList.isNotEmpty) {
            _selectedStaffId = _staffList.first['id'];
          } else {
            _selectedStaffId = _user?['id'];
          }
          _loadingInit = false;
        });
      }
    } catch (e) {
      if (mounted) setState(() => _loadingInit = false);
    }
  }

  // Step 1: Customer
  int? _selectedCustomerId;
  String? _selectedCustomerName;
  String _customerSearch = '';

  // Step 2: Garment
  String? _selectedGarment;
  final List<Map<String, dynamic>> _garmentTypes = [
    {'name': 'Shirts', 'icon': Icons.checkroom},
    {'name': 'Trousers', 'icon': Icons.straighten},
    {'name': 'Dresses', 'icon': Icons.woman},
    {'name': 'Suits', 'icon': Icons.work},
    {'name': 'Jackets', 'icon': Icons.layers},
    {'name': 'Coats', 'icon': Icons.ac_unit},
    {'name': 'School Uniforms', 'icon': Icons.school},
    {'name': 'Office Uniforms', 'icon': Icons.domain},
    {'name': 'Waistcoats', 'icon': Icons.dry_cleaning},
    {'name': 'Traditional', 'icon': Icons.account_balance},
  ];

  // Step 3: Measurements
  Map<String, dynamic>? _measurementTemplate;
  bool _loadingTemplate = false;
  final Map<int, TextEditingController> _measurementControllers = {};

  // Step 4: Style & Fabric
  String _occasion = 'Daily';
  String _climate = 'Hot';

  // Step 5: Assign & Review
  int? _selectedStaffId = 1; // Default to first staff member for demo
  String _staffSearch = '';

  Future<void> _nextStep() async {
    if (_currentStep == 0 && _selectedCustomerId == null) {
      _showSnack('Please select a customer');
      return;
    }
    if (_currentStep == 1) {
      if (_selectedGarment == null) {
        _showSnack('Please select a garment type');
        return;
      }
      // Load template for selected garment
      setState(() => _loadingTemplate = true);
      try {
        final api = ref.read(apiClientProvider);
        final resp = await api.getMeasurementTemplateByCategory(_selectedGarment!);
        _measurementTemplate = resp.data;
        _measurementControllers.clear();
        final fields = _measurementTemplate!['fields'] as List;
        for (var f in fields) {
          _measurementControllers[f['id']] = TextEditingController(text: f['placeholder'] ?? '');
        }
      } catch (e) {
        _showSnack('Failed to load measurement template');
      }
      setState(() => _loadingTemplate = false);
    }
    setState(() => _currentStep++);
  }

  void _prevStep() {
    if (_currentStep > 0) setState(() => _currentStep--);
  }

  void _showSnack(String msg) {
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(msg), backgroundColor: const Color(0xFFD32F2F)));
  }

  Future<void> _saveOrder() async {
    setState(() => _saving = true);
    try {
      final api = ref.read(apiClientProvider);
      final body = <String, dynamic>{
        'customer_id': _selectedCustomerId,
        'garment_type': _selectedGarment,
        'priority': 'Medium',
      };
      
      if (_selectedStaffId != null) body['staff_id'] = _selectedStaffId;

      // Measurements
      final mList = <Map<String, dynamic>>[];
      _measurementControllers.forEach((fieldId, controller) {
        if (controller.text.isNotEmpty) {
          final val = double.tryParse(controller.text);
          if (val != null) {
            mList.add({
              'field_id': fieldId,
              'value': val
            });
          }
        }
      });
      if (mList.isNotEmpty) body['measurements'] = mList;

      await api.createOrder(body);
      ref.invalidate(ordersProvider);
      if (!mounted) return;

      context.go('/orders');
    } catch (e) {
      _showSnack('Failed to create order: $e');
    }
    if (mounted) setState(() => _saving = false);
  }

  @override
  Widget build(BuildContext context) {
    final stepTitles = ['Customer Selection', 'Select Garment Type', 'Measurements', 'Style & Fabric', 'Assign Staff & Review'];
    final currentTitle = stepTitles[_currentStep];

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
          'TailorSync',
          style: GoogleFonts.inter(fontWeight: FontWeight.bold, fontSize: 18, color: const Color(0xFF1A237E)),
        ),
        centerTitle: true,
        actions: [
          IconButton(
            icon: const Icon(Icons.settings_outlined, color: Color(0xFF1A237E)),
            onPressed: () => context.go('/profile'),
          ),
        ],
      ),
      body: SafeArea(
        child: Column(
          children: [

                    // Step Navigation Header
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          if (_currentStep == 0) ...[
                            Text('New Order', style: GoogleFonts.inter(fontSize: 22, fontWeight: FontWeight.bold, color: const Color(0xFF1A237E))),
                            TextButton(
                              onPressed: () => context.go('/home'),
                              child: Text('Cancel', style: GoogleFonts.inter(color: const Color(0xFF5C6BC0))),
                            )
                          ] else ...[
                            IconButton(
                              icon: const Icon(Icons.arrow_back, color: Color(0xFF1A237E)),
                              onPressed: _prevStep,
                            ),
                            if (_currentStep == stepTitles.length - 1)
                              IconButton(
                                icon: const Icon(Icons.close, color: Color(0xFF1A237E)),
                                onPressed: () => context.pop(),
                              )
                            else
                              const SizedBox(width: 48), // balance back button
                          ],
                        ],
                      ),
                    ),

                    // Progress Bar
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 8),
                      child: Column(
                        children: [
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Text('Step ${_currentStep + 1} of ${stepTitles.length}', style: GoogleFonts.inter(fontSize: 12, fontWeight: FontWeight.bold, color: const Color(0xFF1A237E))),
                              Text(currentTitle, style: GoogleFonts.inter(fontSize: 12, color: const Color(0xFF5C6BC0))),
                            ],
                          ),
                          const SizedBox(height: 8),
                          Stack(
                            children: [
                              Container(height: 6, decoration: BoxDecoration(color: const Color(0xFFE8EAF6), borderRadius: BorderRadius.circular(3))),
                              FractionallySizedBox(
                                widthFactor: (_currentStep + 1) / stepTitles.length,
                                child: Container(height: 6, decoration: BoxDecoration(color: const Color(0xFF1A237E), borderRadius: BorderRadius.circular(3))),
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),

                    // Body
                    Expanded(
                      child: SingleChildScrollView(
                        padding: const EdgeInsets.all(24),
                        child: _buildStepContent(),
                      ),
                    ),
          ],
        ),
      ),
    );
  }

  Widget _buildStepContent() {
    switch (_currentStep) {
      case 0: return _buildCustomerStep();
      case 1: return _buildGarmentStep();
      case 2: return _buildMeasurementsStep();
      case 3: return _buildStyleStep();
      case 4: return _buildAssignReviewStep();
      default: return const SizedBox.shrink();
    }
  }

  // ── Step 1: Customer Selection ────────────────────────────────────
  Widget _buildCustomerStep() {
    return Column(
      children: [
        _BigActionCard(
          icon: Icons.search,
          title: 'Select Existing Customer',
          subtitle: 'Search by name, phone, or email',
          isActive: true,
          onTap: () => ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Use the search bar below to find a customer'))),
        ),
        const SizedBox(height: 16),
        _BigActionCard(
          icon: Icons.person_add_alt_1,
          title: 'Create New Customer',
          subtitle: 'Add a new profile to the system',
          isActive: false,
          onTap: () => context.push('/customers/new'),
        ),
        const SizedBox(height: 32),
        TextField(
          onChanged: (v) => setState(() => _customerSearch = v),
          decoration: InputDecoration(
            hintText: 'Search name or phone',
            prefixIcon: const Icon(Icons.search, color: Color(0xFF5C6BC0)),
            contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
            border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: const BorderSide(color: Color(0xFFE8EAF6))),
            enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: const BorderSide(color: Color(0xFFE8EAF6))),
          ),
        ),
        const SizedBox(height: 16),
        
        Consumer(builder: (ctx, ref, child) {
          final customersAsync = ref.watch(customersProvider);
          return customersAsync.when(
            data: (customers) {
              final filtered = customers.where((c) => c.name.toLowerCase().contains(_customerSearch.toLowerCase()) || (c.phone ?? '').contains(_customerSearch)).toList();
              return Column(
                children: filtered.map((c) {
                  final isSelected = _selectedCustomerId == c.id;
                  return GestureDetector(
                    onTap: () => setState(() {
                      _selectedCustomerId = c.id;
                      _selectedCustomerName = c.name;
                    }),
                    child: Container(
                      margin: const EdgeInsets.only(bottom: 8),
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(color: isSelected ? const Color(0xFF1A237E) : const Color(0xFFE8EAF6), width: isSelected ? 2 : 1),
                      ),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(c.name, style: GoogleFonts.inter(fontWeight: FontWeight.bold, color: const Color(0xFF1A237E))),
                              const SizedBox(height: 4),
                              Text(c.phone ?? 'No phone', style: GoogleFonts.inter(fontSize: 12, color: const Color(0xFF5C6BC0))),
                            ],
                          ),
                          Icon(isSelected ? Icons.check_circle : Icons.chevron_right, color: isSelected ? const Color(0xFF1A237E) : const Color(0xFF5C6BC0)),
                        ],
                      ),
                    ),
                  );
                }).toList(),
              );
            },
            loading: () => const Center(child: CircularProgressIndicator()),
            error: (e, _) => const Text('Error loading customers'),
          );
        }),

        const SizedBox(height: 24),
        if (_selectedCustomerId != null)
          SizedBox(
            width: double.infinity,
            child: ElevatedButton(
              onPressed: _nextStep,
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFF0F175A), // Navy
                padding: const EdgeInsets.symmetric(vertical: 16),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
              ),
              child: const Text('Continue to Garment Type', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
            ),
          ),
      ],
    );
  }

  // ── Step 2: Garment Type ──────────────────────────────────────────
  Widget _buildGarmentStep() {
    return Column(
      children: [
        GridView.count(
          crossAxisCount: 2,
          mainAxisSpacing: 12,
          crossAxisSpacing: 12,
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          childAspectRatio: 1.2,
          children: _garmentTypes.map((g) {
            final isSelected = _selectedGarment == g['name'];
            return GestureDetector(
              onTap: () => setState(() => _selectedGarment = g['name']),
              child: Container(
                decoration: BoxDecoration(
                  color: isSelected ? Colors.white : const Color(0xFFF8F9FA),
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(color: isSelected ? const Color(0xFF1A237E) : const Color(0xFFE8EAF6), width: isSelected ? 2 : 1),
                  boxShadow: isSelected ? [BoxShadow(color: const Color(0xFF1A237E).withOpacity(0.1), blurRadius: 8, offset: const Offset(0, 4))] : null,
                ),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(g['icon'], color: isSelected ? const Color(0xFF1A237E) : const Color(0xFF495057), size: 28),
                    const SizedBox(height: 12),
                    Text(g['name'], style: GoogleFonts.inter(color: isSelected ? const Color(0xFF1A237E) : const Color(0xFF495057), fontWeight: isSelected ? FontWeight.bold : FontWeight.normal)),
                  ],
                ),
              ),
            );
          }).toList(),
        ),
        const SizedBox(height: 32),
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            TextButton(
              onPressed: () => context.pop(),
              child: Text('Cancel', style: GoogleFonts.inter(color: const Color(0xFF5C6BC0))),
            ),
            ElevatedButton(
              onPressed: _selectedGarment == null ? null : _nextStep,
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFF0F175A),
                padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(30)),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text('Continue to Measurements', style: GoogleFonts.inter(color: Colors.white, fontWeight: FontWeight.bold)),
                  const SizedBox(width: 8),
                  const Icon(Icons.arrow_forward, color: Colors.white, size: 16),
                ],
              ),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildMeasurementsStep() {
    if (_loadingTemplate) {
      return const Center(child: Padding(
        padding: EdgeInsets.all(40.0),
        child: CircularProgressIndicator(color: Color(0xFF1A237E)),
      ));
    }

    final fields = _measurementTemplate?['fields'] as List? ?? [];

    return Column(
      children: [
        Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: const Color(0xFFF1F3FB), // Light indigo background
            borderRadius: BorderRadius.circular(16),
          ),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(color: const Color(0xFF1A237E), borderRadius: BorderRadius.circular(8)),
                child: const Icon(Icons.info_outline, color: Colors.white, size: 20),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('Notice', style: GoogleFonts.inter(fontWeight: FontWeight.bold, color: const Color(0xFF1A237E))),
                    const SizedBox(height: 4),
                    Text(
                      "AI measurement predictions and suggestions will be available soon! Please enter all measurements manually for now.",
                      style: GoogleFonts.inter(fontSize: 12, color: const Color(0xFF5C6BC0)),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 24),

        if (fields.isEmpty)
          const Padding(
            padding: EdgeInsets.all(20.0),
            child: Text('No measurement fields required for this garment type.', style: TextStyle(color: Colors.grey)),
          )
        else
          ...fields.map((f) {
            return _MeasureInputRow(
              label: f['field_name'] + (f['is_required'] == true ? ' *' : ''),
              controller: _measurementControllers[f['id']]!,
              icon: Icons.straighten,
              hintText: f['placeholder'] ?? 'Enter value',
              unit: f['unit'] ?? 'cm',
            );
          }),

        const SizedBox(height: 32),
        Row(
          mainAxisAlignment: MainAxisAlignment.end,
          children: [
            ElevatedButton(
              onPressed: _nextStep,
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFF0F175A),
                padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(30)),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text('Continue to Style', style: GoogleFonts.inter(color: Colors.white, fontWeight: FontWeight.bold)),
                  const SizedBox(width: 8),
                  const Icon(Icons.arrow_forward, color: Colors.white, size: 16),
                ],
              ),
            ),
          ],
        ),
      ],
    );
  }

  // ── Step 4: Style & Fabric ────────────────────────────────────────
  Widget _buildStyleStep() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text('UP NEXT: STEP 5 OF 5', style: GoogleFonts.inter(fontSize: 10, fontWeight: FontWeight.bold, color: const Color(0xFF5C6BC0), letterSpacing: 1)),
        const SizedBox(height: 4),
        Text('Style & Fabric', style: GoogleFonts.inter(fontSize: 22, fontWeight: FontWeight.bold, color: const Color(0xFF1A237E))),
        const SizedBox(height: 24),

        Text('Occasion', style: GoogleFonts.inter(fontSize: 12, color: const Color(0xFF5C6BC0))),
        const SizedBox(height: 8),
        Row(
          children: ['Daily', 'Office', 'Formal'].map((e) {
            final isSelected = _occasion == e;
            return Padding(
              padding: const EdgeInsets.only(right: 8),
              child: ChoiceChip(
                label: Text(e),
                selected: isSelected,
                onSelected: (v) => setState(() => _occasion = e),
                selectedColor: const Color(0xFF1A237E),
                backgroundColor: Colors.white,
                labelStyle: TextStyle(color: isSelected ? Colors.white : const Color(0xFF5C6BC0)),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20), side: const BorderSide(color: Color(0xFFE8EAF6))),
              ),
            );
          }).toList(),
        ),
        const SizedBox(height: 20),

        Text('Climate', style: GoogleFonts.inter(fontSize: 12, color: const Color(0xFF5C6BC0))),
        const SizedBox(height: 8),
        Row(
          children: ['Hot', 'Warm', 'Cool'].map((e) {
            final isSelected = _climate == e;
            return Padding(
              padding: const EdgeInsets.only(right: 8),
              child: ChoiceChip(
                label: Text(e),
                selected: isSelected,
                onSelected: (v) => setState(() => _climate = e),
                selectedColor: const Color(0xFF1A237E),
                backgroundColor: Colors.white,
                labelStyle: TextStyle(color: isSelected ? Colors.white : const Color(0xFF5C6BC0)),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20), side: const BorderSide(color: Color(0xFFE8EAF6))),
              ),
            );
          }).toList(),
        ),
        const SizedBox(height: 32),

        // AI Fabric Intelligence Card - Disabled Notice
        Container(
          padding: const EdgeInsets.all(20),
          decoration: BoxDecoration(
            color: const Color(0xFFF1F3FB), 
            borderRadius: BorderRadius.circular(16),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  const Icon(Icons.info_outline, color: Color(0xFF1A237E), size: 20),
                  const SizedBox(width: 8),
                  Text('Notice', style: GoogleFonts.inter(fontSize: 16, fontWeight: FontWeight.bold, color: const Color(0xFF1A237E))),
                ],
              ),
              const SizedBox(height: 12),
              Text(
                "AI Fabric Estimation and Recommendations will be available soon!",
                style: GoogleFonts.inter(fontSize: 13, color: const Color(0xFF5C6BC0)),
              ),
            ],
          ),
        ),

        const SizedBox(height: 32),
        Row(
          mainAxisAlignment: MainAxisAlignment.end,
          children: [
            ElevatedButton(
              onPressed: _nextStep,
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFF0F175A),
                padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(30)),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text('Continue to Review', style: GoogleFonts.inter(color: Colors.white, fontWeight: FontWeight.bold)),
                  const SizedBox(width: 8),
                  const Icon(Icons.arrow_forward, color: Colors.white, size: 16),
                ],
              ),
            ),
          ],
        ),
      ],
    );
  }

  // ── Step 5: Assign Staff & Review ─────────────────────────────────
  Widget _buildAssignReviewStep() {
    final filteredStaff = _staffList.where((s) {
      final name = s['full_name']?.toString().toLowerCase() ?? '';
      return name.contains(_staffSearch.toLowerCase());
    }).toList();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        if (_user?['role'] != 'staff') ...[
          Text('Assign Staff', style: GoogleFonts.inter(fontSize: 18, fontWeight: FontWeight.bold, color: const Color(0xFF1A237E))),
          const SizedBox(height: 4),
          Text('Select a staff member to lead the production of this garment.', style: GoogleFonts.inter(fontSize: 12, color: const Color(0xFF5C6BC0))),
          const SizedBox(height: 16),
          TextField(
            onChanged: (v) => setState(() => _staffSearch = v),
            decoration: InputDecoration(
              hintText: 'Search staff by name...',
              hintStyle: const TextStyle(fontSize: 13),
              prefixIcon: const Icon(Icons.search, color: Color(0xFF5C6BC0)),
              contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
              border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: const BorderSide(color: Color(0xFFE8EAF6))),
              enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: const BorderSide(color: Color(0xFFE8EAF6))),
            ),
          ),
          const SizedBox(height: 16),
          Text('AVAILABLE STAFF', style: GoogleFonts.inter(fontSize: 10, fontWeight: FontWeight.bold, color: const Color(0xFF5C6BC0), letterSpacing: 1)),
          const SizedBox(height: 8),
          if (filteredStaff.isEmpty)
            const Text('No staff found')
          else
            ...filteredStaff.map((s) => Padding(
              padding: const EdgeInsets.only(bottom: 8.0),
              child: _StaffCard(
                id: s['id'], 
                name: s['full_name'] ?? 'Unknown', 
                role: 'Staff', 
                badge: 'Available', 
                isSelected: _selectedStaffId == s['id'], 
                onTap: () => setState(() => _selectedStaffId = s['id'])
              ),
            )),
          const SizedBox(height: 32),
        ],

        Text('Review Order', style: GoogleFonts.inter(fontSize: 18, fontWeight: FontWeight.bold, color: const Color(0xFF1A237E))),
        const SizedBox(height: 4),
        Text('Review the final details before committing to production.', style: GoogleFonts.inter(fontSize: 12, color: const Color(0xFF5C6BC0))),
        const SizedBox(height: 16),

        // Review Summary Block
        Container(
          decoration: BoxDecoration(
            color: const Color(0xFFF8F9FA),
            borderRadius: BorderRadius.circular(16),
          ),
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  const Icon(Icons.person, size: 16, color: Color(0xFF1A237E)),
                  const SizedBox(width: 8),
                  Text('Customer Profile', style: GoogleFonts.inter(fontSize: 12, fontWeight: FontWeight.bold, color: const Color(0xFF1A237E))),
                ],
              ),
              const SizedBox(height: 8),
              Text(_selectedCustomerName ?? 'Unknown', style: GoogleFonts.inter(fontSize: 16, fontWeight: FontWeight.bold, color: const Color(0xFF1A237E))),
              Text('VIP Client • Ref: #JD-092', style: GoogleFonts.inter(fontSize: 11, color: const Color(0xFF5C6BC0))),
              const SizedBox(height: 12),
              Text('Garment Type', style: GoogleFonts.inter(fontSize: 10, color: const Color(0xFF5C6BC0))),
              Text('${_selectedGarment ?? 'Unknown'} • $_occasion • $_climate', style: GoogleFonts.inter(fontSize: 13, color: const Color(0xFF1A237E))),
            ],
          ),
        ),
        const SizedBox(height: 16),

        Container(
          decoration: BoxDecoration(
            color: const Color(0xFFF8F9FA),
            borderRadius: BorderRadius.circular(16),
          ),
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  const Icon(Icons.texture, size: 16, color: Color(0xFF1A237E)),
                  const SizedBox(width: 8),
                  Text('Selected Material', style: GoogleFonts.inter(fontSize: 12, fontWeight: FontWeight.bold, color: const Color(0xFF1A237E))),
                ],
              ),
              const SizedBox(height: 8),
              Text('Egyptian Cotton', style: GoogleFonts.inter(fontSize: 16, fontWeight: FontWeight.bold, color: const Color(0xFF1A237E))),
              Text('White • Oxford Weave', style: GoogleFonts.inter(fontSize: 11, color: const Color(0xFF5C6BC0))),
              const SizedBox(height: 12),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text('Required Length', style: GoogleFonts.inter(fontSize: 10, color: const Color(0xFF5C6BC0))),
                      Text('2.5 Meters', style: GoogleFonts.inter(fontSize: 13, color: const Color(0xFF1A237E))),
                    ],
                  ),
                  Container(width: 24, height: 24, decoration: const BoxDecoration(color: Color(0xFFE0E0E0), shape: BoxShape.circle)),
                ],
              )
            ],
          ),
        ),
        const SizedBox(height: 16),

        Container(
          decoration: BoxDecoration(
            color: const Color(0xFFF8F9FA),
            borderRadius: BorderRadius.circular(16),
          ),
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Row(
                    children: [
                      const Icon(Icons.straighten, size: 16, color: Color(0xFF1A237E)),
                      const SizedBox(width: 8),
                      Text('Key Measurements', style: GoogleFonts.inter(fontSize: 12, fontWeight: FontWeight.bold, color: const Color(0xFF1A237E))),
                    ],
                  ),
                  Text('Edit', style: GoogleFonts.inter(fontSize: 11, fontWeight: FontWeight.bold, color: const Color(0xFF5C6BC0))),
                ],
              ),
              const SizedBox(height: 12),
              Wrap(
                spacing: 8,
                runSpacing: 8,
                children: _measurementControllers.entries.map((e) {
                  final fieldId = e.key;
                  final fieldData = (_measurementTemplate?['fields'] as List?)?.firstWhere((f) => f['id'] == fieldId, orElse: () => null);
                  if (fieldData == null) return const SizedBox.shrink();
                  final val = e.value.text;
                  if (val.isEmpty) return const SizedBox.shrink();
                  return SizedBox(
                    width: MediaQuery.of(context).size.width / 2 - 36,
                    child: _ReviewMeasureBox(label: fieldData['field_name'], value: '$val ${fieldData['unit'] ?? 'cm'}'),
                  );
                }).toList(),
              ),
            ],
          ),
        ),
        const SizedBox(height: 16),

        Container(
          decoration: BoxDecoration(
            color: const Color(0xFFF8F9FA),
            borderRadius: BorderRadius.circular(16),
          ),
          padding: const EdgeInsets.all(16),
          child: Row(
            children: [
              CircleAvatar(
                radius: 16,
                backgroundColor: const Color(0xFF5C6BC0),
                child: Text(
                  _user?['full_name'] != null && _user!['full_name'].isNotEmpty 
                    ? _user!['full_name'][0].toUpperCase() 
                    : 'M',
                  style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 14),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('Assigned To', style: GoogleFonts.inter(fontSize: 10, color: const Color(0xFF5C6BC0))),
                    Text(
                      _selectedStaffId == _user?['id'] 
                        ? (_user?['full_name'] ?? 'Master Tailor') 
                        : 'Staff #$_selectedStaffId', 
                      style: GoogleFonts.inter(fontSize: 13, fontWeight: FontWeight.bold, color: const Color(0xFF1A237E))
                    ),
                  ],
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(12), border: Border.all(color: const Color(0xFFE8EAF6))),
                child: Text('Master Tailor', style: GoogleFonts.inter(fontSize: 10, color: const Color(0xFF5C6BC0))),
              ),
            ],
          ),
        ),

        const SizedBox(height: 32),
        SizedBox(
          width: double.infinity,
          child: OutlinedButton(
            onPressed: _prevStep,
            style: OutlinedButton.styleFrom(
              padding: const EdgeInsets.symmetric(vertical: 16),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
              side: const BorderSide(color: Color(0xFFE8EAF6)),
            ),
            child: Text('Back', style: GoogleFonts.inter(color: const Color(0xFF1A237E), fontWeight: FontWeight.bold)),
          ),
        ),
        const SizedBox(height: 12),
        SizedBox(
          width: double.infinity,
          child: ElevatedButton(
            onPressed: _saving ? null : _saveOrder,
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFF0F175A),
              padding: const EdgeInsets.symmetric(vertical: 16),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
            ),
            child: _saving
                ? const SizedBox(height: 20, width: 20, child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white))
                : Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      const Icon(Icons.check_circle, color: Colors.white, size: 18),
                      const SizedBox(width: 8),
                      Text('Save Order', style: GoogleFonts.inter(color: Colors.white, fontWeight: FontWeight.bold)),
                    ],
                  ),
          ),
        ),
      ],
    );
  }
}

// ── Shared Widgets ──────────────────────────────────────────────────

class _BigActionCard extends StatelessWidget {
  final IconData icon;
  final String title;
  final String subtitle;
  final bool isActive;
  final VoidCallback onTap;

  const _BigActionCard({required this.icon, required this.title, required this.subtitle, required this.isActive, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: double.infinity,
        padding: const EdgeInsets.all(24),
        decoration: BoxDecoration(
          color: isActive ? const Color(0xFFF8F9FA) : Colors.white, // In screenshot, top card is light grey, bottom is white
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: isActive ? const Color(0xFF1A237E) : const Color(0xFFE8EAF6), width: isActive ? 2 : 1),
        ),
        child: Column(
          children: [
            Container(
              width: 56,
              height: 56,
              decoration: BoxDecoration(
                color: isActive ? const Color(0xFF1A237E) : const Color(0xFFE8EAF6),
                shape: BoxShape.circle,
              ),
              child: Icon(icon, color: isActive ? Colors.white : const Color(0xFF5C6BC0), size: 28),
            ),
            const SizedBox(height: 16),
            Text(title, style: GoogleFonts.inter(fontSize: 16, fontWeight: FontWeight.bold, color: const Color(0xFF1A237E))),
            const SizedBox(height: 4),
            Text(subtitle, style: GoogleFonts.inter(fontSize: 12, color: const Color(0xFF5C6BC0))),
          ],
        ),
      ),
    );
  }
}

class _MeasureInputRow extends StatelessWidget {
  final String label;
  final TextEditingController controller;
  final IconData icon;
  final bool isPredicted;
  final String hintText;
  final String unit;

  const _MeasureInputRow({required this.label, required this.controller, required this.icon, this.isPredicted = false, this.hintText = '', this.unit = 'cm'});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(label, style: GoogleFonts.inter(fontSize: 12, fontWeight: FontWeight.w600, color: const Color(0xFF1A237E))),
              if (isPredicted)
                Row(
                  children: [
                    const Icon(Icons.auto_awesome, size: 12, color: Color(0xFF5C6BC0)),
                    const SizedBox(width: 4),
                    Text('Predicted', style: GoogleFonts.inter(fontSize: 10, color: const Color(0xFF5C6BC0), fontWeight: FontWeight.bold)),
                  ],
                ),
            ],
          ),
          const SizedBox(height: 8),
          Container(
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: isPredicted ? const Color(0xFF9FA8DA) : const Color(0xFFE8EAF6)),
            ),
            child: Row(
              children: [
                Expanded(
                  child: TextField(
                    controller: controller,
                    keyboardType: TextInputType.number,
                    decoration: InputDecoration(
                      hintText: hintText,
                      border: InputBorder.none,
                      contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
                    ),
                  ),
                ),
                Text(unit, style: GoogleFonts.inter(color: const Color(0xFF5C6BC0), fontSize: 13)),
                const SizedBox(width: 16),
                Container(
                  padding: const EdgeInsets.all(10),
                  decoration: BoxDecoration(color: const Color(0xFFF8F9FA), borderRadius: BorderRadius.circular(8)),
                  margin: const EdgeInsets.only(right: 4),
                  child: Icon(icon, color: const Color(0xFF5C6BC0), size: 18),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _StaffCard extends StatelessWidget {
  final int id;
  final String name;
  final String role;
  final String badge;
  final bool isSelected;
  final VoidCallback onTap;
  final Color badgeColor;

  const _StaffCard({required this.id, required this.name, required this.role, required this.badge, required this.isSelected, required this.onTap, this.badgeColor = const Color(0xFF1A237E)});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: isSelected ? const Color(0xFFF8F9FA) : Colors.white,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: isSelected ? const Color(0xFF1A237E) : const Color(0xFFE8EAF6)),
        ),
        child: Row(
          children: [
            CircleAvatar(
              radius: 16, 
              backgroundColor: isSelected ? const Color(0xFF1A237E) : const Color(0xFF5C6BC0),
              child: Text(
                name.isNotEmpty ? name[0].toUpperCase() : '?',
                style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 14),
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(name, style: GoogleFonts.inter(fontSize: 13, fontWeight: FontWeight.bold, color: const Color(0xFF1A237E))),
                  Text(role, style: GoogleFonts.inter(fontSize: 11, color: const Color(0xFF5C6BC0))),
                ],
              ),
            ),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: badgeColor.withOpacity(0.5)),
              ),
              child: Text(badge, style: GoogleFonts.inter(fontSize: 10, color: badgeColor, fontWeight: FontWeight.w600)),
            ),
          ],
        ),
      ),
    );
  }
}

class _ReviewMeasureBox extends StatelessWidget {
  final String label;
  final String value;
  final bool isAi;

  const _ReviewMeasureBox({required this.label, required this.value, this.isAi = false});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(8), border: Border.all(color: const Color(0xFFE8EAF6))),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(label, style: GoogleFonts.inter(fontSize: 10, color: const Color(0xFF5C6BC0))),
              if (isAi)
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 2),
                  decoration: BoxDecoration(color: const Color(0xFFE8EAF6), borderRadius: BorderRadius.circular(4)),
                  child: Row(
                    children: [
                      const Icon(Icons.auto_awesome, size: 8, color: Color(0xFF1A237E)),
                      const SizedBox(width: 2),
                      Text('AI', style: GoogleFonts.inter(fontSize: 8, fontWeight: FontWeight.bold, color: const Color(0xFF1A237E))),
                    ],
                  ),
                ),
            ],
          ),
          const SizedBox(height: 4),
          Text(value, style: GoogleFonts.inter(fontSize: 13, fontWeight: FontWeight.bold, color: const Color(0xFF1A237E))),
        ],
      ),
    );
  }
}
