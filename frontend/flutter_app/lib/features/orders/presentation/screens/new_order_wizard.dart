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
          if (_user?['role'] == 'staff' || _user?['role'] == 'STAFF') {
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
    {'name': 'Short Sleeve Shirt', 'icon': Icons.checkroom},
    {'name': 'Long Sleeve Shirt', 'icon': Icons.dry_cleaning},
    {'name': 'Short Trouser', 'icon': Icons.straighten},
    {'name': 'Long Trouser', 'icon': Icons.straighten},
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

  Map<String, dynamic> _getDefaultTemplateForCategory(String cat) {
    switch (cat) {
      case 'Short Sleeve Shirt':
        return {
          'category_name': cat,
          'fields': [
            {'id': 1, 'field_name': 'Shoulder Length', 'unit': 'cm', 'is_required': true, 'placeholder': 'e.g. 44'},
            {'id': 2, 'field_name': 'Height', 'unit': 'cm', 'is_required': true, 'placeholder': 'e.g. 175'},
            {'id': 3, 'field_name': 'Short Sleeve Length', 'unit': 'cm', 'is_required': false, 'placeholder': 'e.g. 24'},
            {'id': 4, 'field_name': 'Chest', 'unit': 'cm', 'is_required': false, 'placeholder': 'e.g. 96'},
            {'id': 5, 'field_name': 'Collar Size', 'unit': 'cm', 'is_required': false, 'placeholder': 'e.g. 39'},
            {'id': 6, 'field_name': 'Sleeve Opening', 'unit': 'cm', 'is_required': false, 'placeholder': 'e.g. 34'},
          ]
        };
      case 'Long Sleeve Shirt':
        return {
          'category_name': cat,
          'fields': [
            {'id': 1, 'field_name': 'Shoulder Length', 'unit': 'cm', 'is_required': true, 'placeholder': 'e.g. 44'},
            {'id': 2, 'field_name': 'Height', 'unit': 'cm', 'is_required': true, 'placeholder': 'e.g. 175'},
            {'id': 3, 'field_name': 'Chest', 'unit': 'cm', 'is_required': false, 'placeholder': 'e.g. 96'},
            {'id': 4, 'field_name': 'Collar Size', 'unit': 'cm', 'is_required': false, 'placeholder': 'e.g. 39'},
            {'id': 5, 'field_name': 'Long Sleeve Length', 'unit': 'cm', 'is_required': false, 'placeholder': 'e.g. 62'},
            {'id': 6, 'field_name': 'Sleeve Opening', 'unit': 'cm', 'is_required': false, 'placeholder': 'e.g. 22'},
          ]
        };
      case 'Short Trouser':
        return {
          'category_name': cat,
          'fields': [
            {'id': 1, 'field_name': 'Height Till Knee', 'unit': 'cm', 'is_required': true, 'placeholder': 'e.g. 52'},
            {'id': 2, 'field_name': 'Waist', 'unit': 'cm', 'is_required': true, 'placeholder': 'e.g. 82'},
            {'id': 3, 'field_name': 'Around Knee', 'unit': 'cm', 'is_required': false, 'placeholder': 'e.g. 40'},
            {'id': 4, 'field_name': 'Seat', 'unit': 'cm', 'is_required': false, 'placeholder': 'e.g. 98'},
            {'id': 5, 'field_name': 'Crotch', 'unit': 'cm', 'is_required': false, 'placeholder': 'e.g. 68'},
            {'id': 6, 'field_name': 'Short Trouser Leg Opening', 'unit': 'cm', 'is_required': false, 'placeholder': 'e.g. 44'},
          ]
        };
      case 'Long Trouser':
        return {
          'category_name': cat,
          'fields': [
            {'id': 1, 'field_name': 'Height Till Knee', 'unit': 'cm', 'is_required': true, 'placeholder': 'e.g. 52'},
            {'id': 2, 'field_name': 'Waist', 'unit': 'cm', 'is_required': true, 'placeholder': 'e.g. 82'},
            {'id': 3, 'field_name': 'Around Knee', 'unit': 'cm', 'is_required': false, 'placeholder': 'e.g. 40'},
            {'id': 4, 'field_name': 'Seat', 'unit': 'cm', 'is_required': false, 'placeholder': 'e.g. 98'},
            {'id': 5, 'field_name': 'Crotch', 'unit': 'cm', 'is_required': false, 'placeholder': 'e.g. 68'},
            {'id': 6, 'field_name': 'Long Trouser Leg Opening', 'unit': 'cm', 'is_required': false, 'placeholder': 'e.g. 38'},
          ]
        };
      default:
        return {
          'category_name': cat,
          'fields': [
            {'id': 1, 'field_name': 'Shoulder Length', 'unit': 'cm', 'is_required': true, 'placeholder': 'e.g. 44'},
            {'id': 2, 'field_name': 'Height', 'unit': 'cm', 'is_required': true, 'placeholder': 'e.g. 175'},
            {'id': 3, 'field_name': 'Chest', 'unit': 'cm', 'is_required': false, 'placeholder': 'e.g. 96'},
            {'id': 4, 'field_name': 'Waist', 'unit': 'cm', 'is_required': false, 'placeholder': 'e.g. 82'},
          ]
        };
    }
  }

  // Step 4: Style & Fabric
  String _occasion = 'Everyday / Casual';
  String _weather = 'Warm';
  final List<String> _fabricPreferences = ['Soft', 'Breathable'];
  String _fit = 'Regular Fit';

  final List<String> _occasionOptions = const [
    'Everyday / Casual',
    'Office / Work',
    'Wedding',
    'Party / Celebration',
    'School',
    'University',
    'Business / Formal Event',
    'Religious / Cultural Event',
    'Travel',
    'Outdoor Activity',
    'Other',
  ];

  final List<String> _weatherOptions = const [
    'Very Hot',
    'Hot',
    'Warm',
    'Mild',
    'Cool',
    'Cold',
    'Very Cold',
    'Humid',
    'Rainy',
    'Windy',
    'Mixed / Changing Weather',
  ];

  final List<String> _fabricFeelOptions = const [
    'Very Soft',
    'Soft',
    'Smooth',
    'Slightly Rough',
    'Rough / Textured',
    'Lightweight / Thin',
    'Medium Weight',
    'Heavy / Thick',
    'Stretchy',
    'Structured / Firm',
    'Breathable',
    'Extra Comfortable',
  ];

  final List<String> _fitOptions = const [
    'Slim Fit',
    'Modern Fit',
    'Regular Fit',
  ];

  // Step 5: Assign & Review
  int? _selectedStaffId = 1; // Default to first staff member for demo
  String _staffSearch = '';
  final Set<int> _invalidFieldIds = {};

  // AI Measurement Prediction state
  List<Map<String, dynamic>> _aiPredictions = [];
  Map<String, String> _confirmedMeasurements = {};
  Map<String, bool> _isAiGenerated = {};
  bool _aiPredictionLoading = false;
  String? _aiPredictionError;

  // Fabric Recommendation state
  List<Map<String, dynamic>> _fabricRecommendations = [];
  int? _selectedFabricIndex;
  bool _fabricRecLoading = false;
  String? _fabricRecError;

  // Fabric Estimation state
  Map<String, dynamic>? _fabricEstimation;
  bool _fabricEstLoading = false;
  String? _fabricEstError;

  Future<void> _nextStep() async {
    final api = ref.read(apiClientProvider);
    if (_currentStep == 0) {
      if (_selectedCustomerId == null) {
        _showSnack('⚠️ Please select a customer before proceeding to the next step');
        return;
      }
    } else if (_currentStep == 1) {
      if (_selectedGarment == null) {
        _showSnack('⚠️ Please select a garment type before proceeding to the next step');
        return;
      }
      // Load template for selected garment
      setState(() => _loadingTemplate = true);
      try {
        final resp = await api.getMeasurementTemplateByCategory(_selectedGarment!);
        _measurementTemplate = resp.data;
      } catch (e) {
        _measurementTemplate = _getDefaultTemplateForCategory(_selectedGarment!);
      }
      _measurementControllers.clear();
      final fields = _measurementTemplate!['fields'] as List;
      for (var f in fields) {
        _measurementControllers[f['id']] = TextEditingController();
      }
      setState(() => _loadingTemplate = false);
    } else if (_currentStep == 2) {
      // Step 2: Measurements -> Step 3: AI Prediction
      final fields = (_measurementTemplate?['fields'] as List? ?? []).cast<Map<String, dynamic>>();
      final priorityFields = fields.where((f) {
        final name = (f['field_name'] ?? '').toString();
        final isReq = f['is_required'] == true;
        return isReq || name == 'Shoulder Length' || name == 'Height' || name == 'Height Till Knee' || name == 'Waist';
      }).toList();

      final missing = <String>[];
      _invalidFieldIds.clear();
      final enteredMeasures = <String, String>{};
      for (var f in priorityFields) {
        final id = f['id'] as int;
        final ctrl = _measurementControllers[id];
        final text = ctrl?.text.trim() ?? '';
        if (text.isEmpty || double.tryParse(text) == null) {
          missing.add(f['field_name'] ?? 'Measurement');
          _invalidFieldIds.add(id);
        }
      }

      if (missing.isNotEmpty) {
        setState(() {});
        _showSnack('⚠️ Please enter valid numerical values for priority measurements: ${missing.join(", ")}');
        return;
      }
      
      for (var f in fields) {
        final id = f['id'] as int;
        final name = f['field_name'] as String;
        final text = _measurementControllers[id]?.text.trim() ?? '';
        if (text.isNotEmpty) {
          enteredMeasures[name] = text;
          _confirmedMeasurements[name] = text;
          _isAiGenerated[name] = false;
        }
      }

      setState(() { _aiPredictionLoading = true; _aiPredictionError = null; _currentStep++; });
      try {
        final resp = await api.predictMeasurements({'garment_type': _selectedGarment, 'measurements': enteredMeasures});
        setState(() {
          _aiPredictions = List<Map<String, dynamic>>.from(resp.data['predictions'] ?? []);
          _aiPredictionLoading = false;
        });
      } catch (e) {
        setState(() {
          _aiPredictionError = "AI prediction unavailable. You can proceed and enter measurements manually.";
          _aiPredictionLoading = false;
        });
      }
      return;
    } else if (_currentStep == 3) {
      // Step 3: AI Prediction -> Step 4: Style & Fabric
      // Ensure all predictions are confirmed/handled
      for (var p in _aiPredictions) {
         final m = p['measurement'] as String;
         if (!_confirmedMeasurements.containsKey(m)) {
            _confirmedMeasurements[m] = p['recommended'].toString();
            _isAiGenerated[m] = true;
         }
      }
    } else if (_currentStep == 4) {
      // Step 4: Style & Fabric -> Step 5: Fabric Recommendation
      if (_occasion.isEmpty || _weather.isEmpty || _fabricPreferences.isEmpty || _fit.isEmpty) {
        _showSnack('⚠️ Please fill all style preferences');
        return;
      }
      setState(() { _fabricRecLoading = true; _fabricRecError = null; _currentStep++; });
      try {
        final resp = await api.recommendFabric({
          'garment_type': _selectedGarment,
          'occasion': _occasion,
          'weather': _weather,
          'fabric_preferences': _fabricPreferences,
          'fit': _fit
        });
        setState(() {
          _fabricRecommendations = List<Map<String, dynamic>>.from(resp.data['recommendations'] ?? []);
          _selectedFabricIndex = null;
          _fabricRecLoading = false;
        });
      } catch (e) {
        setState(() {
          _fabricRecError = "Fabric recommendations unavailable. Please proceed manually.";
          _fabricRecLoading = false;
        });
      }
      return;
    } else if (_currentStep == 5) {
      // Step 5: Fabric Rec -> Step 6: Fabric Estimation
      if (_selectedFabricIndex == null && _fabricRecError == null) {
        _showSnack('⚠️ Please select a fabric recommendation');
        return;
      }
      String selectedFabric = "Manual Fabric";
      if (_selectedFabricIndex != null && _fabricRecommendations.isNotEmpty) {
         selectedFabric = _fabricRecommendations[_selectedFabricIndex!]['fabric_name'];
      }
      
      setState(() { _fabricEstLoading = true; _fabricEstError = null; _currentStep++; });
      try {
        final resp = await api.estimateFabric({
          'garment_type': _selectedGarment,
          'fabric': selectedFabric,
          'measurements': _confirmedMeasurements
        });
        setState(() {
          _fabricEstimation = resp.data;
          _fabricEstLoading = false;
        });
      } catch (e) {
        setState(() {
          _fabricEstError = "Fabric estimation unavailable.";
          _fabricEstLoading = false;
        });
      }
      return;
    }

    setState(() {
      _invalidFieldIds.clear();
      _currentStep++;
    });
  }

  void _prevStep() {
    if (_currentStep > 0) setState(() => _currentStep--);
  }

  void _showSnack(String msg) {
    ScaffoldMessenger.of(context).hideCurrentSnackBar();
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Row(
          children: [
            const Icon(Icons.warning_amber_rounded, color: Colors.white, size: 20),
            const SizedBox(width: 10),
            Expanded(
              child: Text(
                msg,
                style: GoogleFonts.inter(fontWeight: FontWeight.w600, fontSize: 13, color: Colors.white),
              ),
            ),
          ],
        ),
        backgroundColor: const Color(0xFFC62828), // Red warning
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        margin: const EdgeInsets.all(16),
        duration: const Duration(seconds: 4),
      ),
    );
  }

  int _getFieldIdByName(String name) {
    final fields = (_measurementTemplate?['fields'] as List? ?? []).cast<Map<String, dynamic>>();
    for (var f in fields) {
      if (f['field_name'] == name) return f['id'] as int;
    }
    return 0;
  }

  Future<void> _saveOrder() async {
    if (_selectedCustomerId == null) {
      _showSnack('⚠️ Customer missing. Please go back to Step 1 and select a customer');
      return;
    }
    if (_selectedGarment == null) {
      _showSnack('⚠️ Garment missing. Please go back to Step 2 and select a garment');
      return;
    }
    if (_selectedStaffId == null) {
      _showSnack('⚠️ Please select a staff member to assign the order');
      return;
    }

    setState(() => _saving = true);
    try {
      final api = ref.read(apiClientProvider);
      final body = <String, dynamic>{
        'customer_id': _selectedCustomerId,
        'garment_type': _selectedGarment,
        'priority': 'Medium',
        'style_preferences': {
          'occasion': _occasion,
          'weather': _weather,
          'fabric_feel': _fabricPreferences,
          'fit': _fit,
        },
      };
      
      if (_selectedStaffId != null) body['staff_id'] = _selectedStaffId;

      // Measurements
      final mList = <Map<String, dynamic>>[];
      _confirmedMeasurements.forEach((fieldName, value) {
        final val = double.tryParse(value);
        if (val != null) {
          final fieldId = _getFieldIdByName(fieldName);
          if (fieldId > 0) {
            mList.add({
              'field_id': fieldId,
              'value': val,
              'is_ai_generated': _isAiGenerated[fieldName] ?? false,
            });
          }
        }
      });
      if (mList.isNotEmpty) body['measurements'] = mList;

      if (_selectedFabricIndex != null && _fabricRecommendations.isNotEmpty) {
        body['selected_fabric'] = _fabricRecommendations[_selectedFabricIndex!]['fabric_name'];
      }

      if (_fabricEstimation != null) {
        body['fabric_estimation'] = _fabricEstimation;
      }

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
    final stepTitles = ['Customer Selection', 'Select Garment Type', 'Measurements', 'AI Prediction', 'Style & Fabric', 'Fabric Recommendation', 'Fabric Estimation', 'Assign Staff & Review'];
    final currentTitle = stepTitles[_currentStep];

    return Scaffold(
      backgroundColor: const Color(0xFFF8F9FA),
      appBar: AppBar(
        backgroundColor: const Color(0xFFF8F9FA),
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.home, color: Color(0xFF1A237E)),
          onPressed: () => context.go('/home'),
        ),
        title: Text(
          'TailorSync',
          style: GoogleFonts.inter(fontWeight: FontWeight.bold, fontSize: 18, color: const Color(0xFF1A237E)),
        ),
        centerTitle: true,
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
      case 3: return _buildAiPredictionStep();
      case 4: return _buildStyleStep();
      case 5: return _buildFabricRecStep();
      case 6: return _buildFabricEstStep();
      case 7: return _buildAssignReviewStep();
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

    final fields = (_measurementTemplate?['fields'] as List? ?? []).cast<Map<String, dynamic>>();

    final priorityFields = fields.where((f) {
      final name = (f['field_name'] ?? '').toString();
      final isReq = f['is_required'] == true;
      return isReq || name == 'Shoulder Length' || name == 'Height' || name == 'Height Till Knee' || name == 'Waist';
    }).toList();

    final additionalFields = fields.where((f) => !priorityFields.contains(f)).toList();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: const Color(0xFFF1F3FB), // Light indigo background
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: const Color(0xFFE8EAF6)),
          ),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(color: const Color(0xFF1A237E), borderRadius: BorderRadius.circular(8)),
                child: const Icon(Icons.auto_awesome, color: Colors.white, size: 20),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('AI Prediction Ready', style: GoogleFonts.inter(fontWeight: FontWeight.bold, color: const Color(0xFF1A237E))),
                    const SizedBox(height: 4),
                    Text(
                      "Priority / Must-Have measurements (e.g. Height & Shoulder Length) are primary inputs used by AI to accurately predict remaining measurements.",
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
        else ...[
          if (priorityFields.isNotEmpty) ...[
            Container(
              margin: const EdgeInsets.only(bottom: 14),
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
              decoration: BoxDecoration(
                color: const Color(0xFFFFF8E1),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: const Color(0xFFFFE082)),
              ),
              child: Row(
                children: [
                  const Icon(Icons.star_rounded, color: Color(0xFFD97706), size: 20),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      'Priority / Must-Have Measurements',
                      style: GoogleFonts.inter(fontWeight: FontWeight.bold, color: const Color(0xFFB45309), fontSize: 13),
                    ),
                  ),
                ],
              ),
            ),
            ...priorityFields.map((f) {
              final id = f['id'] as int;
              return _MeasureInputRow(
                label: f['field_name'] ?? '',
                controller: _measurementControllers[id]!,
                icon: Icons.straighten,
                hintText: f['placeholder'] ?? 'Enter value',
                unit: f['unit'] ?? 'cm',
                isPriority: true,
                hasError: _invalidFieldIds.contains(id),
              );
            }),
            const SizedBox(height: 12),
          ],

          if (additionalFields.isNotEmpty) ...[
            Container(
              margin: EdgeInsets.only(bottom: 14, top: priorityFields.isNotEmpty ? 8 : 0),
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
              decoration: BoxDecoration(
                color: const Color(0xFFF8F9FA),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: const Color(0xFFE8EAF6)),
              ),
              child: Row(
                children: [
                  const Icon(Icons.straighten, color: Color(0xFF1A237E), size: 18),
                  const SizedBox(width: 8),
                  Text(
                    'Additional Measurements',
                    style: GoogleFonts.inter(fontWeight: FontWeight.bold, color: const Color(0xFF1A237E), fontSize: 13),
                  ),
                ],
              ),
            ),
            ...additionalFields.map((f) {
              final id = f['id'] as int;
              return _MeasureInputRow(
                label: f['field_name'] ?? '',
                controller: _measurementControllers[id]!,
                icon: Icons.straighten,
                hintText: f['placeholder'] ?? 'Enter value',
                unit: f['unit'] ?? 'cm',
                isPriority: false,
                hasError: _invalidFieldIds.contains(id),
              );
            }),
          ],
        ],

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
  // ── Step 3: AI Prediction ──────────────────────────────────────────
  Widget _buildAiPredictionStep() {
    if (_aiPredictionLoading) {
      return const Center(
        child: Padding(
          padding: EdgeInsets.all(48.0),
          child: Column(
            children: [
              CircularProgressIndicator(),
              SizedBox(height: 16),
              Text('Analyzing AI predictions for measurements...'),
            ],
          ),
        ),
      );
    }
    if (_aiPredictionError != null) {
      return Column(
        children: [
          const Icon(Icons.error_outline, color: Colors.red, size: 48),
          const SizedBox(height: 16),
          Text(_aiPredictionError!, textAlign: TextAlign.center),
          const SizedBox(height: 32),
          ElevatedButton(onPressed: _nextStep, child: const Text('Proceed Manually'))
        ],
      );
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text('AI Measurement Review', style: GoogleFonts.inter(fontSize: 18, fontWeight: FontWeight.bold, color: const Color(0xFF1A237E))),
        const SizedBox(height: 8),
        const Text('Review and adjust the AI predicted measurements.'),
        const SizedBox(height: 24),
        if (_aiPredictions.isEmpty)
          const Text('No predictions found. Please proceed.')
        else
          ..._aiPredictions.map((pred) {
            final m = pred['measurement'];
            return Card(
              margin: const EdgeInsets.only(bottom: 16),
              child: Padding(
                padding: const EdgeInsets.all(16.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(m, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
                    const SizedBox(height: 8),
                    Text('AI Reasoning: ${pred['reason']}', style: const TextStyle(color: Colors.grey, fontSize: 12)),
                    const SizedBox(height: 12),
                    Row(
                      children: [
                        Expanded(
                          child: TextFormField(
                            key: ValueKey('${m}_${_confirmedMeasurements[m]}'),
                            initialValue: _confirmedMeasurements[m] ?? pred['recommended'].toString(),
                            onChanged: (val) {
                              _confirmedMeasurements[m] = val;
                              _isAiGenerated[m] = false;
                            },
                            decoration: const InputDecoration(labelText: 'Confirmed Value', border: OutlineInputBorder()),
                          ),
                        ),
                        const SizedBox(width: 16),
                        OutlinedButton(
                          onPressed: () {
                             setState(() {
                                _confirmedMeasurements[m] = pred['recommended'].toString();
                                _isAiGenerated[m] = true;
                             });
                          },
                          child: const Text('Use AI Value'),
                        )
                      ],
                    )
                  ],
                ),
              ),
            );
          }),
        const SizedBox(height: 24),
        SizedBox(width: double.infinity, child: ElevatedButton(onPressed: _nextStep, child: const Text('Confirm & Continue')))
      ],
    );
  }

  // ── Step 5: Fabric Recommendation ──────────────────────────────────
  Widget _buildFabricRecStep() {
    if (_fabricRecLoading) {
      return const Center(child: Padding(padding: EdgeInsets.all(48.0), child: CircularProgressIndicator()));
    }
    if (_fabricRecError != null) {
      return Column(
        children: [
          Text(_fabricRecError!),
          ElevatedButton(onPressed: _nextStep, child: const Text('Proceed Manually'))
        ],
      );
    }
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text('Fabric Recommendations', style: GoogleFonts.inter(fontSize: 18, fontWeight: FontWeight.bold, color: const Color(0xFF1A237E))),
        const SizedBox(height: 16),
        ..._fabricRecommendations.asMap().entries.map((e) {
          final i = e.key;
          final rec = e.value;
          return RadioListTile<int>(
            title: Text('${rec['fabric_name']} (${rec['suitability_percentage']}%)'),
            subtitle: Text(rec['reason']),
            value: i,
            groupValue: _selectedFabricIndex,
            onChanged: (val) => setState(() => _selectedFabricIndex = val),
          );
        }),
        const SizedBox(height: 24),
        SizedBox(width: double.infinity, child: ElevatedButton(onPressed: _nextStep, child: const Text('Continue')))
      ],
    );
  }

  // ── Step 6: Fabric Estimation ──────────────────────────────────────
  Widget _buildFabricEstStep() {
    if (_fabricEstLoading) {
      return const Center(child: Padding(padding: EdgeInsets.all(48.0), child: CircularProgressIndicator()));
    }
    if (_fabricEstError != null) {
      return Column(
        children: [
          Text(_fabricEstError!),
          ElevatedButton(onPressed: _nextStep, child: const Text('Proceed'))
        ],
      );
    }
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text('Fabric Yardage Estimation', style: GoogleFonts.inter(fontSize: 18, fontWeight: FontWeight.bold, color: const Color(0xFF1A237E))),
        const SizedBox(height: 16),
        if (_fabricEstimation != null) ...[
          Text('Recommended: ${_fabricEstimation!['recommended_quantity_meters']} Meters', style: const TextStyle(fontSize: 24, fontWeight: FontWeight.bold)),
          Text('Width: ${_fabricEstimation!['fabric_width_inches']}"'),
          if (_fabricEstimation!['estimated_range'] != null)
             Text('Range: ${_fabricEstimation!['estimated_range']['min']} - ${_fabricEstimation!['estimated_range']['max']} Meters'),
          const SizedBox(height: 12),
          Text('Reason: ${_fabricEstimation!['reason']}'),
        ],
        const SizedBox(height: 24),
        SizedBox(width: double.infinity, child: ElevatedButton(onPressed: _nextStep, child: const Text('Continue')))
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

        // 1. Occasion (Single selection)
        _buildStyleSection(
          title: 'Occasion',
          badgeText: 'Single selection',
          isMulti: false,
          options: _occasionOptions,
          selectedValues: [_occasion],
          onSelect: (val) => setState(() => _occasion = val),
        ),

        // 2. Weather (Single selection)
        _buildStyleSection(
          title: 'Weather',
          badgeText: 'Single selection',
          isMulti: false,
          options: _weatherOptions,
          selectedValues: [_weather],
          onSelect: (val) => setState(() => _weather = val),
        ),

        // 3. Fabric Feel & Preference (Multiple selection)
        _buildStyleSection(
          title: 'Fabric Feel & Preference',
          badgeText: 'Multiple selection',
          isMulti: true,
          options: _fabricFeelOptions,
          selectedValues: _fabricPreferences,
          onSelect: (val) {
            setState(() {
              if (_fabricPreferences.contains(val)) {
                _fabricPreferences.remove(val);
              } else {
                _fabricPreferences.add(val);
              }
            });
          },
        ),

        // 4. Fit (Single selection)
        _buildStyleSection(
          title: 'Fit',
          badgeText: 'Single selection',
          isMulti: false,
          options: _fitOptions,
          selectedValues: [_fit],
          onSelect: (val) => setState(() => _fit = val),
        ),

        // AI Fabric Recommendation Notice Card
        Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: const Color(0xFFF1F3FB),
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: const Color(0xFFE8EAF6)),
          ),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(color: const Color(0xFF1A237E), borderRadius: BorderRadius.circular(8)),
                child: const Icon(Icons.auto_awesome, color: Colors.white, size: 20),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('AI Fabric Recommendation Engine', style: GoogleFonts.inter(fontWeight: FontWeight.bold, color: const Color(0xFF1A237E))),
                    const SizedBox(height: 4),
                    Text(
                      "Your selected occasion, weather, fabric feel preferences, and fit will be passed to the AI system to recommend optimal fabric types!",
                      style: GoogleFonts.inter(fontSize: 12, color: const Color(0xFF5C6BC0)),
                    ),
                  ],
                ),
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

  Widget _buildStyleSection({
    required String title,
    required String badgeText,
    required bool isMulti,
    required List<String> options,
    required List<String> selectedValues,
    required Function(String) onSelect,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Text(title, style: GoogleFonts.inter(fontSize: 14, fontWeight: FontWeight.bold, color: const Color(0xFF1A237E))),
            const SizedBox(width: 8),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
              decoration: BoxDecoration(
                color: isMulti ? const Color(0xFFE8EAF6) : const Color(0xFFF1F3FB),
                borderRadius: BorderRadius.circular(10),
              ),
              child: Text(
                badgeText,
                style: GoogleFonts.inter(
                  fontSize: 10,
                  color: isMulti ? const Color(0xFF1A237E) : const Color(0xFF5C6BC0),
                  fontWeight: isMulti ? FontWeight.bold : FontWeight.w600,
                ),
              ),
            ),
          ],
        ),
        const SizedBox(height: 10),
        Wrap(
          spacing: 8,
          runSpacing: 8,
          children: options.map((opt) {
            final isSelected = selectedValues.contains(opt);
            return _SelectChip(
              label: opt,
              isSelected: isSelected,
              onTap: () => onSelect(opt),
            );
          }).toList(),
        ),
        const SizedBox(height: 24),
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
        if (_user?['role'] != 'staff' && _user?['role'] != 'STAFF') ...[
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
              Text('Garment & Style', style: GoogleFonts.inter(fontSize: 10, color: const Color(0xFF5C6BC0))),
              Text('${_selectedGarment ?? 'Garment'} • $_fit', style: GoogleFonts.inter(fontSize: 14, fontWeight: FontWeight.bold, color: const Color(0xFF1A237E))),
              const SizedBox(height: 2),
              Text('Occasion: $_occasion  •  Weather: $_weather', style: GoogleFonts.inter(fontSize: 11, color: const Color(0xFF5C6BC0))),
              if (_fabricPreferences.isNotEmpty) ...[
                const SizedBox(height: 2),
                Text('Fabric Feel: ${_fabricPreferences.join(", ")}', style: GoogleFonts.inter(fontSize: 11, color: const Color(0xFF1A237E), fontWeight: FontWeight.w500)),
              ],
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
                children: [
                  const Icon(Icons.straighten, size: 16, color: Color(0xFF1A237E)),
                  const SizedBox(width: 8),
                  Text('Key Measurements', style: GoogleFonts.inter(fontSize: 12, fontWeight: FontWeight.bold, color: const Color(0xFF1A237E))),
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
  final bool isPriority;
  final bool hasError;
  final String hintText;
  final String unit;

  const _MeasureInputRow({
    required this.label,
    required this.controller,
    required this.icon,
    this.isPredicted = false,
    this.isPriority = false,
    this.hasError = false,
    this.hintText = '',
    this.unit = 'cm',
  });

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
              Row(
                children: [
                  Text(label, style: GoogleFonts.inter(fontSize: 13, fontWeight: FontWeight.w600, color: hasError ? const Color(0xFFC62828) : const Color(0xFF1A237E))),
                  if (isPriority) ...[
                    const SizedBox(width: 4),
                    Text('*', style: GoogleFonts.inter(fontSize: 14, fontWeight: FontWeight.bold, color: const Color(0xFFD97706))),
                  ],
                ],
              ),
              if (isPriority)
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                  decoration: BoxDecoration(
                    color: const Color(0xFFFFF8E1),
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: const Color(0xFFFFB300), width: 1),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      const Icon(Icons.star_rounded, size: 12, color: Color(0xFFD97706)),
                      const SizedBox(width: 4),
                      Text('Must-Have', style: GoogleFonts.inter(fontSize: 10, fontWeight: FontWeight.bold, color: const Color(0xFFB45309))),
                    ],
                  ),
                )
              else if (isPredicted)
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
              border: Border.all(
                color: hasError ? const Color(0xFFC62828) : (isPriority ? const Color(0xFFFFC107) : (isPredicted ? const Color(0xFF9FA8DA) : const Color(0xFFE8EAF6))),
                width: hasError || isPriority ? 1.5 : 1.0,
              ),
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
                  decoration: BoxDecoration(
                    color: hasError ? const Color(0xFFFFEBEE) : (isPriority ? const Color(0xFFFFF8E1) : const Color(0xFFF8F9FA)),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  margin: const EdgeInsets.only(right: 4),
                  child: Icon(
                    icon,
                    color: hasError ? const Color(0xFFC62828) : (isPriority ? const Color(0xFFD97706) : const Color(0xFF5C6BC0)),
                    size: 18,
                  ),
                ),
              ],
            ),
          ),
          if (hasError) ...[
            const SizedBox(height: 4),
            Text(
              'This numerical measurement is required',
              style: GoogleFonts.inter(fontSize: 11, color: const Color(0xFFC62828), fontWeight: FontWeight.w500),
            ),
          ],
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

class _SelectChip extends StatelessWidget {
  final String label;
  final bool isSelected;
  final VoidCallback onTap;

  const _SelectChip({
    required this.label,
    required this.isSelected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 150),
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 9),
        decoration: BoxDecoration(
          color: isSelected ? const Color(0xFF1A237E) : Colors.white,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(
            color: isSelected ? const Color(0xFF1A237E) : const Color(0xFFE8EAF6),
            width: isSelected ? 1.5 : 1.0,
          ),
          boxShadow: isSelected
              ? [BoxShadow(color: const Color(0xFF1A237E).withValues(alpha: 0.12), blurRadius: 4, offset: const Offset(0, 2))]
              : null,
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            if (isSelected) ...[
              const Icon(Icons.check, color: Colors.white, size: 14),
              const SizedBox(width: 6),
            ],
            Text(
              label,
              style: GoogleFonts.inter(
                fontSize: 12,
                fontWeight: isSelected ? FontWeight.bold : FontWeight.w500,
                color: isSelected ? Colors.white : const Color(0xFF374151),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
